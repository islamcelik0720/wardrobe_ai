import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile) async {
    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final String uid = FirebaseAuth.instance.currentUser!.uid;

    final Reference ref = _storage
        .ref()
        .child("clothes")
        .child(uid)
        .child("$fileName.jpg");

    await ref.putFile(imageFile);

    final String downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }
}
