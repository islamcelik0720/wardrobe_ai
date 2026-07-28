import 'package:cloud_firestore/cloud_firestore.dart';

class OutfitPlan {
  final String id;
  final String uid;
  final String day;
  final List<String> clothingIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  OutfitPlan({
    required this.id,
    required this.uid,
    required this.day,
    required this.clothingIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "day": day,
      "clothingIds": clothingIds,
      "createdAt": Timestamp.fromDate(createdAt),
      "updatedAt": Timestamp.fromDate(updatedAt),
    };
  }

  factory OutfitPlan.fromMap(Map<String, dynamic> map, String documentId) {
    return OutfitPlan(
      id: documentId,
      uid: map["uid"] ?? "",
      day: map["day"] ?? "",
      clothingIds: List<String>.from(map["clothingIds"] ?? []),
      createdAt: _dateFromValue(map["createdAt"]),
      updatedAt: _dateFromValue(map["updatedAt"]),
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}
