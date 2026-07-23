import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Firebase kontrol edilirken yükleniyor ekranı
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı giriş yaptıysa
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Giriş yapılmadıysa
        return const WelcomeScreen();
      },
    );
  }
}
