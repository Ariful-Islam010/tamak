import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/chat_provider.dart';
import 'providers/money_saver_provider.dart';
import 'providers/check_in_provider.dart';
import 'providers/quit_plan_provider.dart';
import 'providers/gamification_provider.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/profile_assessment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize notification service (background notifications)
  await NotificationService().initialize();

  // Force logout existing users to clear old state (runs once)
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('has_forced_logout_v2') != true) {
    await Supabase.instance.client.auth.signOut();
    await prefs.setBool('has_forced_logout_v2', true);
  }

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
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          final session = Supabase.instance.client.auth.currentSession;

          // No session → show auth screen (no loading spinner)
          if (session == null) {
            return const AuthScreen();
          }

          final user = authService.currentUser;

          // User data still loading → show auth screen instead of spinner
          // AuthService will notify when user data is ready
          if (user == null) {
            return const AuthScreen();
          }

          // MANDATORY onboarding: User MUST fill all required fields
          if (user.planDuration == null ||
              user.age == null ||
              user.gender == null ||
              user.quitDate == null) {
            return const ProfileAssessmentScreen();
          }

          return const HomeDashboardScreen();
        },
      ),
    );
  }
}
