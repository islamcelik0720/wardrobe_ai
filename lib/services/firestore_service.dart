import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/clothing_item.dart';
import '../models/outfit_plan.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcıyı Kaydet
  Future<void> saveUser({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    await _firestore.collection("users").doc(uid).set({
      "fullName": fullName,
      "email": email,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final document = await _firestore.collection("users").doc(uid).get();

    return document.data();
  }

  // Yeni Kıyafet Ekle
  Future<void> addClothing(ClothingItem clothingItem) async {
    await _firestore.collection("clothes").add(clothingItem.toMap());
  }

  // Kullanıcının Kıyafetlerini Getir
  Stream<List<ClothingItem>> getClothes(String uid) {
    return _firestore
        .collection("clothes")
        .where("uid", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ClothingItem.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Kıyafeti Güncelle
  Future<void> updateClothing(ClothingItem clothingItem) async {
    await _firestore
        .collection("clothes")
        .doc(clothingItem.id)
        .update(clothingItem.toMap());
  }

  Future<void> toggleFavorite(String documentId, bool favorite) async {
    await _firestore.collection("clothes").doc(documentId).update({
      "favorite": favorite,
    });
  }

  Future<void> incrementUsage(String documentId) async {
    await _firestore.collection("clothes").doc(documentId).update({
      "timesUsed": FieldValue.increment(1),
    });
  }

  // Kıyafeti Sil
  Future<void> deleteClothing(String documentId) async {
    await _firestore.collection("clothes").doc(documentId).delete();
  }

  Future<void> saveOutfitPlan(OutfitPlan plan) async {
    final querySnapshot = await _firestore
        .collection("outfitPlans")
        .where("uid", isEqualTo: plan.uid)
        .where("day", isEqualTo: plan.day)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      await _firestore.collection("outfitPlans").add(plan.toMap());
    } else {
      final documentId = querySnapshot.docs.first.id;

      await _firestore.collection("outfitPlans").doc(documentId).update({
        "clothingIds": plan.clothingIds,
        "updatedAt": Timestamp.fromDate(plan.updatedAt),
      });
    }
  }

  Stream<List<OutfitPlan>> getOutfitPlans(String uid) {
    return _firestore
        .collection("outfitPlans")
        .where("uid", isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OutfitPlan.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> deleteOutfitPlan(String documentId) async {
    await _firestore.collection("outfitPlans").doc(documentId).delete();
  }
}
