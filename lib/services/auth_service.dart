import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kayıt Ol
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Giriş Yap
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Çıkış Yap
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Aktif kullanıcı
  User? get currentUser => _auth.currentUser;
}
