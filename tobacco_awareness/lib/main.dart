import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/chat_provider.dart';
import 'providers/money_saver_provider.dart';
import 'providers/check_in_provider.dart';
import 'providers/quit_plan_provider.dart';
import 'providers/gamification_provider.dart';
import 'screens/splash_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (still needed for any remaining frontend env vars)
  await dotenv.load(fileName: ".env");

  // Initialize Supabase Flutter SDK for Realtime Chat
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://gdfirpgmaielvfxghwif.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_GL6JCFsNsPDJMP0QX6Sj-A_vnycYMjd';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('⚡ Supabase Realtime initialized successfully');
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Initialize notification service (background notifications)
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => MoneySaverProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => QuitPlanProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: const TamakmuktoJibonApp(),
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
