import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingItem {
  final String id;
  final String uid;
  final String imageUrl;
  final String category;
  final String color;
  final String fabric;
  final String season;
  final bool favorite;
  final String? brand;
  final String? notes;
  final int timesUsed;
  final DateTime createdAt;
  final DateTime? lastWornAt;

  ClothingItem({
    required this.id,
    required this.uid,
    required this.imageUrl,
    required this.category,
    required this.color,
    required this.fabric,
    required this.season,
    required this.favorite,
    this.brand,
    this.notes,
    required this.timesUsed,
    required this.createdAt,
    this.lastWornAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "imageUrl": imageUrl,
      "category": category,
      "color": color,
      "fabric": fabric,
      "season": season,
      "favorite": favorite,
      "brand": brand ?? "",
      "notes": notes ?? "",
      "timesUsed": timesUsed,
      "createdAt": createdAt,
      "lastWornAt": lastWornAt == null ? null : Timestamp.fromDate(lastWornAt!),
    };
  }

  factory ClothingItem.fromMap(Map<String, dynamic> map, String documentId) {
    return ClothingItem(
      id: documentId,
      uid: map["uid"] ?? "",
      imageUrl: map["imageUrl"] ?? "",
      category: map["category"] ?? "",
      color: map["color"] ?? "",
      fabric: map["fabric"] ?? "",
      season: map["season"] ?? "",
      favorite: map["favorite"] ?? false,
      brand: map["brand"],
      notes: map["notes"],
      timesUsed: map["timesUsed"] ?? 0,
      createdAt: map["createdAt"].toDate(),
      lastWornAt: map["lastWornAt"] == null
          ? null
          : _dateFromValue(map["lastWornAt"]),
    );
  }
  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
