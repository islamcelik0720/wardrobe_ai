import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Giriş başarılı!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Snackbar'ın görünmesi için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
          break;

        case 'wrong-password':
          message = "Şifre hatalı.";
          break;

        case 'invalid-email':
          message = "Geçersiz e-posta adresi.";
          break;

        case 'invalid-credential':
          message = "E-posta veya şifre hatalı.";
          break;

        case 'too-many-requests':
          message =
              "Çok fazla giriş denemesi yapıldı. Lütfen daha sonra tekrar deneyin.";
          break;

        case 'network-request-failed':
          message = "İnternet bağlantınızı kontrol edin.";
          break;

        default:
          message = e.message ?? "Giriş yapılamadı.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            "Beklenmeyen bir hata oluştu.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                const Icon(Icons.lock_open, size: 90, color: Color(0xFF6A11CB)),

                const SizedBox(height: 20),

                const Text(
                  "Tekrar Hoş Geldin",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Hesabına giriş yap",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  controller: emailController,
                  hintText: "E-posta",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "E-posta boş bırakılamaz";
                    }

                    if (!value.contains("@")) {
                      return "Geçerli bir e-posta giriniz";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  controller: passwordController,
                  hintText: "Şifre",
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Şifre boş bırakılamaz";
                    }

                    if (value.length < 6) {
                      return "Şifre en az 6 karakter olmalıdır";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 35),

                PrimaryButton(
                  text: "Giriş Yap",
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
