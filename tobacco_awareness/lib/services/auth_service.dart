import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'hive_helper.dart';
import 'backend_service.dart';

final authServiceProvider = ChangeNotifierProvider<AuthService>(
  (ref) => AuthService(),
);

class AuthService extends ChangeNotifier {
  // Web/server client ID from google-services.json — required to get idToken on Android
  static const _serverClientId =
      '82683276860-44b2sfnhnk66pq72blrlc4mesj841bu1.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId,
  );

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialSessionChecked = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get initialSessionChecked => _initialSessionChecked;

  AuthService() {
    _restoreSession();
  }

  // ─── SESSION MANAGEMENT ───
  Future<void> _loadCachedProfile(String userId) async {
    try {
      final cachedProfileJson = await HiveHelper().getSetting(
        'cached_user_profile_$userId',
      );
      if (cachedProfileJson != null && cachedProfileJson.isNotEmpty) {
        final data = jsonDecode(cachedProfileJson);
        if (data is Map<String, dynamic>) {
          final quitDateVal = data['quit_date'];
          _currentUser = UserModel(
            uid: userId,
            email: data['email'],
            displayName: data['display_name'],
            photoUrl: data['photo_url'],
            educationalInfo: data['educational_info'],
            planDuration: data['plan_duration'],
            quitDate: quitDateVal != null ? DateTime.tryParse(quitDateVal.toString()) : null,
            aiQuitPlan: data['ai_quit_plan'],
            age: data['age'],
            gender: data['gender'],
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading cached profile: $e");
    }
  }

  Future<void> _restoreSession() async {
    try {
      final token = await HiveHelper().getSetting('auth_access_token');
      final userId = await HiveHelper().getSetting('auth_user_id');
      if (token != null && userId != null) {
        BackendService.setAuth(token, userId);
        await _loadCachedProfile(userId);
        await _fetchAndSetProfile();
      }
    } catch (e) {
      debugPrint("Error restoring session: $e");
    } finally {
      _initialSessionChecked = true;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, String userId) async {
    BackendService.setAuth(token, userId);
    await HiveHelper().saveSetting('auth_access_token', token);
    await HiveHelper().saveSetting('auth_user_id', userId);
  }

  Future<void> _clearSession() async {
    final uid = BackendService.userId;
    if (uid != null) {
      await HiveHelper().removeSetting('cached_user_profile_$uid');
    }
    BackendService.setAuth(null, null);
    _currentUser = null;
    await HiveHelper().removeSetting('auth_access_token');
    await HiveHelper().removeSetting('auth_user_id');
  }

  // ─── PROFILE FETCHING ───
  Future<void> _fetchAndSetProfile() async {
    if (BackendService.token == null || BackendService.userId == null) return;
    try {
      final response = await http
          .get(
            Uri.parse('${BackendService.baseUrl}/api/profile'),
            headers: BackendService.headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final rawBody = response.body;
        if (rawBody == 'null' || rawBody == '{}' || rawBody.isEmpty) {
          debugPrint(
            "Profile empty or user deleted on backend. Clearing session.",
          );
          await _clearSession();
          return;
        }
        final data = jsonDecode(rawBody);
        if (data == null ||
            data is! Map ||
            data.isEmpty ||
            data['id'] == null) {
          debugPrint("Profile data invalid or user deleted. Clearing session.");
          await _clearSession();
          return;
        }

        await HiveHelper().saveSetting(
          'cached_user_profile_${BackendService.userId}',
          rawBody,
        );

        final quitDateVal = data['quit_date'];
        if (quitDateVal != null) {
          await HiveHelper().saveSetting(
            'user_quit_date_${BackendService.userId}',
            quitDateVal,
          );
        } else {
          await HiveHelper().removeSetting(
            'user_quit_date_${BackendService.userId}',
          );
        }
        _currentUser = UserModel(
          uid: BackendService.userId!,
          email: data['email'],
          displayName: data['display_name'],
          photoUrl: data['photo_url'],
          educationalInfo: data['educational_info'],
          planDuration: data['plan_duration'],
          quitDate: quitDateVal != null ? DateTime.tryParse(quitDateVal.toString()) : null,
          aiQuitPlan: data['ai_quit_plan'],
          age: data['age'],
          gender: data['gender'],
        );
        await _setupNotificationsAndWelcome();
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        debugPrint(
          "Auth or user not found error in _fetchAndSetProfile. Clearing session.",
        );
        await _clearSession();
      }
    } catch (e) {
      debugPrint("Error fetching profile from backend: $e");
    }
  }

  Future<void> _setupNotificationsAndWelcome() async {
    try {
      final permission = await NotificationService().requestPermission();
      if (permission) {
        await NotificationService().scheduleAllDailyNotifications(
          quitDate: _currentUser?.quitDate,
        );
        final uid = BackendService.userId;
        final hasShownWelcomeStr = await HiveHelper().getSetting(
          'welcome_notification_shown_$uid',
        );
        final hasShownWelcome = hasShownWelcomeStr == 'true';
        if (!hasShownWelcome && _currentUser?.displayName != null) {
          await NotificationService().showWelcomeNotification(
            _currentUser!.displayName!.split(' ').first,
          );
          await HiveHelper().saveSetting(
            'welcome_notification_shown_$uid',
            'true',
          );
        }
      }
    } catch (e) {
      debugPrint("Error in _setupNotificationsAndWelcome: $e");
    }
  }

  // ─── PUBLIC API ───

  /// Call this after onboarding to persist all profile fields.
  Future<void> updateUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    notifyListeners();
    try {
      if (BackendService.token != null && BackendService.userId != null) {
        if (updatedUser.quitDate != null) {
          await HiveHelper().saveSetting(
            'user_quit_date_${BackendService.userId}',
            updatedUser.quitDate!.toIso8601String(),
          );
        } else {
          await HiveHelper().removeSetting(
            'user_quit_date_${BackendService.userId}',
          );
        }
        final body = {
          'id': BackendService.userId,
          'email': updatedUser.email,
          'display_name': updatedUser.displayName,
          'photo_url': updatedUser.photoUrl,
          'educational_info': updatedUser.educationalInfo,
          'plan_duration': updatedUser.planDuration,
          'quit_date': updatedUser.quitDate?.toIso8601String(),
          'ai_quit_plan': updatedUser.aiQuitPlan,
          'age': updatedUser.age,
          'gender': updatedUser.gender,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await HiveHelper().saveSetting(
          'cached_user_profile_${BackendService.userId}',
          jsonEncode(body),
        );
        await http
            .post(
              Uri.parse('${BackendService.baseUrl}/api/profile'),
              headers: BackendService.headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      debugPrint("Error syncing user data with backend: $e");
    }
  }

  /// Refresh profile from backend.
  Future<void> refreshProfile() async {
    if (BackendService.token != null) {
      await _fetchAndSetProfile();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/auth/signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userId =
            (data['user'] as Map<String, dynamic>?)?['id'] as String?;
        if (token != null && userId != null) {
          await _saveSession(token, userId);
          await _fetchAndSetProfile();
        }
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        _isLoading = false;
        notifyListeners();
        final err = jsonDecode(response.body);
        throw err is Map ? err['detail'] ?? err.toString() : err.toString();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userId =
            (data['user'] as Map<String, dynamic>?)?['id'] as String?;
        if (token != null && userId != null) {
          await _saveSession(token, userId);
          await _fetchAndSetProfile();
        }
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        _isLoading = false;
        notifyListeners();
        final err = jsonDecode(response.body);
        throw err is Map ? err['detail'] ?? err.toString() : err.toString();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error registering with email: $e");
      rethrow;
    }
  }

  /// Upload photo to backend and update profile.
  Future<void> updateProfilePhoto(String photoUrl) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (BackendService.token != null && BackendService.userId != null) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
        } else {
          _currentUser = UserModel(
            uid: BackendService.userId!,
            photoUrl: photoUrl,
          );
        }
        final body = {
          'id': BackendService.userId,
          'email': _currentUser?.email,
          'display_name': _currentUser?.displayName,
          'photo_url': photoUrl,
          'educational_info': _currentUser?.educationalInfo,
          'plan_duration': _currentUser?.planDuration,
          'quit_date': _currentUser?.quitDate?.toIso8601String(),
          'ai_quit_plan': _currentUser?.aiQuitPlan,
          'age': _currentUser?.age,
          'gender': _currentUser?.gender,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await HiveHelper().saveSetting(
          'cached_user_profile_${BackendService.userId}',
          jsonEncode(body),
        );
        await http
            .post(
              Uri.parse('${BackendService.baseUrl}/api/profile'),
              headers: BackendService.headers(),
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error updating profile photo: $e");
      rethrow;
    }
  }

  /// Upload an image File to the backend and return the secure URL.
  Future<String?> uploadProfilePhoto(File file) async {
    if (BackendService.token == null) return null;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BackendService.baseUrl}/api/upload'),
      );
      request.headers['Authorization'] = 'Bearer ${BackendService.token}';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseData = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['secure_url'] as String?;
      }
      debugPrint('Upload failed: ${streamed.statusCode} $responseData');
      return null;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final body = <String, String>{'idToken': idToken};
      if (accessToken != null) body['accessToken'] = accessToken;

      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/auth/signin-google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final userMap = data['user'] as Map<String, dynamic>?;
        final userId = userMap?['id'] as String?;

        // Extract email from multiple sources (Google > backend user object)
        final googleEmail = googleUser.email;
        final backendEmail = userMap?['email'] as String?;
        final resolvedEmail = googleEmail.isNotEmpty
            ? googleEmail
            : backendEmail;
        // Note: googleName and googlePhoto intentionally NOT used —
        // name comes from profile assessment, photo from profile screen.

        if (token != null && userId != null) {
          await _saveSession(token, userId);
          await _fetchAndSetProfile();

          // Only persist email from Google if it is missing in the profile.
          // Name and photo are NOT taken from Google — user sets them themselves
          // via profile assessment (name) and profile screen (photo).
          if (_currentUser != null) {
            final needsEmailUpdate =
                (_currentUser!.email == null || _currentUser!.email!.isEmpty);
            if (needsEmailUpdate) {
              final updated = _currentUser!.copyWith(email: resolvedEmail);
              _currentUser = updated;
              final body2 = {
                'id': userId,
                'email': resolvedEmail,
                'updated_at': DateTime.now().toIso8601String(),
              };
              await HiveHelper().saveSetting(
                'cached_user_profile_$userId',
                jsonEncode(body2),
              );
              try {
                await http
                    .post(
                      Uri.parse('${BackendService.baseUrl}/api/profile'),
                      headers: BackendService.headers(),
                      body: jsonEncode(body2),
                    )
                    .timeout(const Duration(seconds: 10));
              } catch (e) {
                debugPrint("Error saving email to backend: $e");
              }
            }
          } else {
            // New user — create profile model for current session
            _currentUser = UserModel(uid: userId, email: resolvedEmail);
          }
        }
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        _isLoading = false;
        notifyListeners();
        final err = jsonDecode(response.body);
        throw err is Map ? err['detail'] ?? err.toString() : err.toString();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint("Google disconnect error: $e");
      }
      await _googleSignIn.signOut();
      await _clearSession();
      NotificationService().cancelDailyNotifications().catchError((e) {
        debugPrint("Error cancelling notifications: $e");
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error signing out: $e");
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();
      if (BackendService.token != null) {
        try {
          final response = await http
              .delete(
                Uri.parse(
                  '${BackendService.baseUrl}/api/profile/delete-account',
                ),
                headers: BackendService.headers(),
              )
              .timeout(const Duration(seconds: 10));
          debugPrint("Delete account response: ${response.statusCode}");
        } catch (e) {
          debugPrint("Backend delete request error: $e");
        }
      }
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint("Google disconnect error: $e");
      }
      await _googleSignIn.signOut();
      await _clearSession();
      NotificationService().cancelDailyNotifications().catchError((e) {
        debugPrint("Error cancelling notifications: $e");
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }
}
