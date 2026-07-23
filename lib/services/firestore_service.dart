import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clothing_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addClothing(ClothingItem clothingItem) async {
    await _firestore.collection("clothes").add(clothingItem.toMap());
  }
}
