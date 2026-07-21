import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const WardrobeAIApp());
}

class WardrobeAIApp extends StatelessWidget {
  const WardrobeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
