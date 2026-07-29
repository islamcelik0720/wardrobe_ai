import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'screens/auth/auth_wrapper.dart';
import 'core/settings/notification_controller.dart';
import 'services/local_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await themeController.loadThemeMode();

  await notificationController.loadNotificationSetting();

  await LocalNotificationService.instance.initialize();

  runApp(const WardrobeAIApp());
}

class WardrobeAIApp extends StatefulWidget {
  const WardrobeAIApp({super.key});

  @override
  State<WardrobeAIApp> createState() => _WardrobeAIAppState();
}

class _WardrobeAIAppState extends State<WardrobeAIApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WardrobeAI',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}
