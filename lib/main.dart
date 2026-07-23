import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const WardrobeAIApp());
}

class WardrobeAIApp extends StatelessWidget {
  const WardrobeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WardrobeAI',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}
