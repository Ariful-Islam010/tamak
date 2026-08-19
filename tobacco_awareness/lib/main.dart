import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/hive_helper.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'services/hive_migration_manager.dart';
import 'services/durable_sync_queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter UI error catching
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('⚡ [Global FlutterError]: ${details.exceptionAsString()}');
  };

  // Global Unhandled Async Platform Error Catching
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('⚡ [Global PlatformDispatcher Error]: $error');
    return true; // Handled, prevents app force close / crash
  };

  // Initialize Hive
  await HiveHelper().init();

  // Run Cache Schema Migration if needed
  await HiveMigrationManager.checkAndMigrate();

  // Process Durable Offline Queue
  await DurableSyncQueue().processQueue();

  // Initialize Offline Auto-Sync Service
  await SyncService().init();

  // Load environment variables (still needed for any remaining frontend env vars)
  await dotenv.load(fileName: ".env");

  // Initialize Firebase (required for Google Sign-In idToken generation)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      title: 'QuitMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
