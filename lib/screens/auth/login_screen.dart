import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WardrobeAI"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom, size: 100),

            const SizedBox(height: 20),

            const Text(
              "WardrobeAI",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Yapay Zekâ Destekli Kombin Asistanı",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Giriş Yap"),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Kayıt Ol"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
