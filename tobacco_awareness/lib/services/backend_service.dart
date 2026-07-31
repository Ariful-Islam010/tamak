import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central backend service configuration and in-memory auth state.
/// AuthService sets the token after login/logout.
class BackendService {
  /// Reads BACKEND_URL from .env file.
  /// - During local development: set BACKEND_URL=http://192.168.x.x:8000
  /// - For production APK:       set BACKEND_URL=https://your-app.onrender.com
  static String get baseUrl {
    final url = dotenv.env['BACKEND_URL'] ?? '';
    if (url.isEmpty) {
      throw Exception(
        'BACKEND_URL is not set in .env file!\n'
        'Add: BACKEND_URL=https://your-app.onrender.com',
      );
    }
    return url;
  }

  // In-memory auth state (set by AuthService after login/restore)
  static String? _token;
  static String? _userId;

  static String? get token => _token;
  static String? get userId => _userId;

  static void setAuth(String? token, String? userId) {
    _token = token;
    _userId = userId;
    debugPrint('BackendService auth set: userId=$userId, hasToken=${token != null}');
  }

  static Map<String, String> headers({String? token}) {
    final t = token ?? _token;
    final h = <String, String>{'Content-Type': 'application/json'};
    if (t != null) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}
