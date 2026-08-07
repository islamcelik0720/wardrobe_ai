class WardrobeMemory {
  final String uid;

  final List<String> favoriteClothingIds;
  final List<String> frequentlyUsedClothingIds;
  final List<String> rarelyUsedClothingIds;

  final String mostUsedColor;
  final String mostUsedCategory;

  final int totalClothes;
  final int totalUsage;
  final List<String> longUnusedClothingIds;

  final DateTime updatedAt;

  const WardrobeMemory({
    required this.uid,
    required this.favoriteClothingIds,
    required this.frequentlyUsedClothingIds,
    required this.rarelyUsedClothingIds,
    required this.mostUsedColor,
    required this.mostUsedCategory,
    required this.totalClothes,
    required this.totalUsage,
    required this.updatedAt,
    required this.longUnusedClothingIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'favoriteClothingIds': favoriteClothingIds,
      'frequentlyUsedClothingIds': frequentlyUsedClothingIds,
      'rarelyUsedClothingIds': rarelyUsedClothingIds,
      'mostUsedColor': mostUsedColor,
      'mostUsedCategory': mostUsedCategory,
      'totalClothes': totalClothes,
      'totalUsage': totalUsage,
      'updatedAt': updatedAt.toIso8601String(),
      'longUnusedClothingIds': longUnusedClothingIds,
    };
  }

  factory WardrobeMemory.fromMap(Map<String, dynamic> map) {
    return WardrobeMemory(
      uid: map['uid']?.toString() ?? '',
      favoriteClothingIds: map['favoriteClothingIds'] is List
          ? List<String>.from(
              (map['favoriteClothingIds'] as List).map(
                (item) => item.toString(),
              ),
            )
          : [],
      frequentlyUsedClothingIds: map['frequentlyUsedClothingIds'] is List
          ? List<String>.from(
              (map['frequentlyUsedClothingIds'] as List).map(
                (item) => item.toString(),
              ),
            )
          : [],
      longUnusedClothingIds: map['longUnusedClothingIds'] is List
          ? List<String>.from(
              (map['longUnusedClothingIds'] as List).map(
                (item) => item.toString(),
              ),
            )
          : [],
      rarelyUsedClothingIds: map['rarelyUsedClothingIds'] is List
          ? List<String>.from(
              (map['rarelyUsedClothingIds'] as List).map(
                (item) => item.toString(),
              ),
            )
          : [],
      mostUsedColor: map['mostUsedColor']?.toString() ?? 'Veri yok',
      mostUsedCategory: map['mostUsedCategory']?.toString() ?? 'Veri yok',
      totalClothes: map['totalClothes'] is num
          ? (map['totalClothes'] as num).toInt()
          : 0,
      totalUsage: map['totalUsage'] is num
          ? (map['totalUsage'] as num).toInt()
          : 0,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
