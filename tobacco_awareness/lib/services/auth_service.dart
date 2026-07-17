import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthService() {
    _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(AuthState data) async {
    final user = data.session?.user;
    if (user == null) {
      _currentUser = null;
      // Cancel notifications when user logs out
      await NotificationService().cancelDailyNotifications();
    } else {
      await _fetchAndSetProfile(user);
      // Schedule daily notifications when user logs in
      final permission = await NotificationService().requestPermission();
      if (permission) {
        await NotificationService().scheduleAllDailyNotifications(
          quitDate: _currentUser?.quitDate,
        );
        // Show welcome notification
        if (_currentUser?.displayName != null) {
          await NotificationService().showWelcomeNotification(
            _currentUser!.displayName!.split(' ').first,
          );
        }
      }
    }
    notifyListeners();
  }

  Future<void> _fetchAndSetProfile(User user) async {
    try {
      final profileData = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData != null) {
        _currentUser = UserModel(
          uid: user.id,
          email: user.email,
          displayName: profileData['display_name'] ?? user.userMetadata?['full_name'],
          photoUrl: profileData['photo_url'] ?? user.userMetadata?['avatar_url'],
          educationalInfo: profileData['educational_info'],
          planDuration: profileData['plan_duration'],
          quitDate: profileData['quit_date'] != null
              ? DateTime.parse(profileData['quit_date'])
              : null,
          aiQuitPlan: profileData['ai_quit_plan'],
          age: profileData['age'],
          gender: profileData['gender'],
        );
      } else {
        _currentUser = UserModel(
          uid: user.id,
          email: user.email,
          displayName: user.userMetadata?['full_name'],
          photoUrl: user.userMetadata?['avatar_url'],
        );
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      _currentUser = UserModel(
        uid: user.id,
        email: user.email,
        displayName: user.userMetadata?['full_name'],
        photoUrl: user.userMetadata?['avatar_url'],
      );
    }
  }

  /// Call this after onboarding to persist all profile fields.
  Future<void> updateUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    notifyListeners();
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('user_profiles').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': updatedUser.displayName,
          'photo_url': updatedUser.photoUrl,
          'educational_info': updatedUser.educationalInfo,
          'plan_duration': updatedUser.planDuration,
          'quit_date': updatedUser.quitDate?.toIso8601String(),
          'ai_quit_plan': updatedUser.aiQuitPlan,
          'age': updatedUser.age,
          'gender': updatedUser.gender,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint("Error syncing user data with Supabase: $e");
    }
  }

  /// Refresh profile from database (call this after login if needed).
  Future<void> refreshProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _fetchAndSetProfile(user);
      notifyListeners();
    }
  }

  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }

  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error registering with email: $e");
      rethrow;
    }
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    try {
      _isLoading = true;
      notifyListeners();
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('user_profiles').upsert({
          'id': user.id,
          'email': user.email,
          'photo_url': photoUrl,
          'display_name': _currentUser?.displayName ?? user.userMetadata?['full_name'],
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(photoUrl: photoUrl);
        } else {
          _currentUser = UserModel(
            uid: user.id,
            email: user.email,
            photoUrl: photoUrl,
            displayName: user.userMetadata?['full_name'],
          );
        }
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

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      const webClientId =
          '810251320156-fnfum4mtk2f6j6egrek5mkii956ip9gi.apps.googleusercontent.com';
      const iosClientId =
          '810251320156-1rhkm4oapfp85jf92df6qk2425ldno68.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        throw 'No Access Token or ID Token found.';
      }
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      _isLoading = false;
      notifyListeners();
      return response;
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
      await _supabase.auth.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Error signing out: $e");
    }
  }
}
