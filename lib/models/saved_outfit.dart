import 'package:cloud_firestore/cloud_firestore.dart';

class SavedOutfit {
  final String id;
  final String uid;
  final List<String> clothingIds;
  final String description;
  final int outfitScore;
  final DateTime createdAt;

  const SavedOutfit({
    required this.id,
    required this.uid,
    required this.clothingIds,
    required this.description,
    required this.outfitScore,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'clothingIds': clothingIds,
      'description': description,
      'outfitScore': outfitScore,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SavedOutfit.fromMap(Map<String, dynamic> map, String documentId) {
    final createdAtValue = map['createdAt'];

    return SavedOutfit(
      id: documentId,
      uid: map['uid']?.toString() ?? '',
      clothingIds: map['clothingIds'] is List
          ? List<String>.from(
              (map['clothingIds'] as List).map((item) => item.toString()),
            )
          : [],
      description: map['description']?.toString().trim() ?? '',
      outfitScore: map['outfitScore'] is num
          ? (map['outfitScore'] as num).toInt()
          : int.tryParse(map['outfitScore']?.toString() ?? '') ?? 0,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }
}
