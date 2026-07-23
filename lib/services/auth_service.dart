import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kayıt Ol
  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await FirestoreService().saveUser(
      uid: credential.user!.uid,
      fullName: fullName,
      email: email,
    );

    return credential;
  }

  // Giriş Yap
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Çıkış Yap
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Aktif kullanıcı
  User? get currentUser => _auth.currentUser;

  // Oturum değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
