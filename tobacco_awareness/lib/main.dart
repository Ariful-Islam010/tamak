import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/hive_helper.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveHelper().init();

  // Load environment variables (still needed for any remaining frontend env vars)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (required for Google Sign-In idToken generation)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase Flutter SDK for Realtime Chat
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://gdfirpgmaielvfxghwif.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_GL6JCFsNsPDJMP0QX6Sj-A_vnycYMjd';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
    debugPrint('⚡ Supabase Realtime initialized successfully');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Initialize notification service (background notifications)
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: TamakmuktoJibonApp(),
    ),
  );
}

class TamakmuktoJibonApp extends StatelessWidget {
  const TamakmuktoJibonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'তামাকমুক্ত জীবন',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
