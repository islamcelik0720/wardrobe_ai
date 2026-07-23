import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user != null) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
