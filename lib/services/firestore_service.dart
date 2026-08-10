import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/clothing_item.dart';
import '../models/outfit_plan.dart';
import '../models/saved_outfit.dart';
import '../models/style_chat_session.dart';
import '../models/wardrobe_gap_analysis_result.dart';

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

  Future<void> incrementUsageForClothes(List<String> clothingIds) async {
    if (clothingIds.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final clothingId in clothingIds) {
      final id = clothingId.trim();

      if (id.isEmpty) {
        continue;
      }

      final reference = _firestore.collection("clothes").doc(id);

      batch.update(reference, {
        "timesUsed": FieldValue.increment(1),
        "lastWornAt": FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> markOutfitPlanAsWorn(String planId) async {
    await _firestore.collection("outfitPlans").doc(planId).update({
      "isWorn": true,
      "wornAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveWardrobeAnalysis({
    required String uid,
    required WardrobeGapAnalysisResult result,
  }) async {
    await _firestore.collection("wardrobeAnalyses").doc(uid).set({
      "uid": uid,
      ...result.toMap(),
      "updatedAt": FieldValue.serverTimestamp(),
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

  Future<String> saveOutfit(SavedOutfit outfit) async {
    final document = await _firestore
        .collection("savedOutfits")
        .add(outfit.toMap());

    return document.id;
  }

  Stream<List<SavedOutfit>> getSavedOutfits(String uid) {
    return _firestore
        .collection("savedOutfits")
        .where("uid", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return SavedOutfit.fromMap(document.data(), document.id);
          }).toList();
        });
  }

  Future<void> deleteSavedOutfit(String documentId) async {
    await _firestore.collection("savedOutfits").doc(documentId).delete();
  }

  Future<String> createStyleChatSession(StyleChatSession session) async {
    final document = await _firestore
        .collection("styleChatSessions")
        .add(session.toMap());

    return document.id;
  }

  Future<void> updateStyleChatSession(StyleChatSession session) async {
    if (session.id.trim().isEmpty) {
      throw Exception("Güncellenecek sohbet oturumunun ID değeri boş olamaz.");
    }

    await _firestore.collection("styleChatSessions").doc(session.id).update({
      "title": session.title,
      "messages": session.messages.map((message) => message.toMap()).toList(),
      "updatedAt": Timestamp.fromDate(session.updatedAt),
    });
  }

  Stream<List<StyleChatSession>> getStyleChatSessions(String uid) {
    return _firestore
        .collection("styleChatSessions")
        .where("uid", isEqualTo: uid)
        .orderBy("updatedAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return StyleChatSession.fromMap(document.data(), document.id);
          }).toList();
        });
  }

  Future<void> deleteStyleChatSession(String documentId) async {
    await _firestore.collection("styleChatSessions").doc(documentId).delete();
  }

  Future<WardrobeGapAnalysisResult?> getWardrobeAnalysis(String uid) async {
    final document = await _firestore
        .collection("wardrobeAnalyses")
        .doc(uid)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return WardrobeGapAnalysisResult.fromMap(data);
  }

  Future<void> addToDonationList({
    required String uid,
    required ClothingItem item,
  }) async {
    await _firestore.collection("donationItems").doc(item.id).set({
      "uid": uid,
      "clothingId": item.id,
      "category": item.category,
      "color": item.color,
      "imageUrl": item.imageUrl,
      "timesUsed": item.timesUsed,
      "lastWornAt": item.lastWornAt == null
          ? null
          : Timestamp.fromDate(item.lastWornAt!),
      "status": "planned",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getDonationItems(String uid) {
    return _firestore
        .collection("donationItems")
        .where("uid", isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((document) {
            return {"id": document.id, ...document.data()};
          }).toList();
        });
  }

  Future<void> markDonationAsCompleted(String clothingId) async {
    final batch = _firestore.batch();

    final clothingRef = _firestore.collection("clothes").doc(clothingId);

    final donationRef = _firestore.collection("donationItems").doc(clothingId);

    batch.delete(clothingRef);
    batch.delete(donationRef);

    await batch.commit();
  }

  Future<void> removeFromDonationList(String clothingId) async {
    await _firestore.collection("donationItems").doc(clothingId).delete();
  }

  Future<bool> isInDonationList(String clothingId) async {
    final document = await _firestore
        .collection("donationItems")
        .doc(clothingId)
        .get();

    return document.exists;
  }
}
