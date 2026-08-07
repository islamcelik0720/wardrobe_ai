import '../models/clothing_item.dart';
import '../models/wardrobe_memory.dart';

class WardrobeMemoryService {
  WardrobeMemory buildMemory({
    required String uid,
    required List<ClothingItem> clothes,
  }) {
    if (clothes.isEmpty) {
      return WardrobeMemory(
        uid: uid,
        favoriteClothingIds: const [],
        frequentlyUsedClothingIds: const [],
        rarelyUsedClothingIds: const [],
        longUnusedClothingIds: const [],
        mostUsedColor: "Veri yok",
        mostUsedCategory: "Veri yok",
        totalClothes: 0,
        totalUsage: 0,
        updatedAt: DateTime.now(),
      );
    }

    final favoriteIds = clothes
        .where((item) => item.favorite)
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    final totalUsage = clothes.fold<int>(
      0,
      (sum, item) => sum + item.timesUsed,
    );

    final sortedByUsage = List<ClothingItem>.from(clothes)
      ..sort((a, b) => b.timesUsed.compareTo(a.timesUsed));

    final frequentlyUsedIds = sortedByUsage
        .where((item) => item.timesUsed > 0)
        .take(5)
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    final rarelyUsedIds = clothes
        .where((item) => item.timesUsed == 0)
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .take(5)
        .toList();
    final now = DateTime.now();

    final longUnusedIds = clothes
        .where((item) {
          final lastWornAt = item.lastWornAt;

          if (lastWornAt == null) {
            return false;
          }

          final daysSinceLastWorn = now.difference(lastWornAt).inDays;

          return daysSinceLastWorn >= 30;
        })
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .take(10)
        .toList();

    final colorUsage = <String, int>{};
    final categoryUsage = <String, int>{};

    for (final item in clothes) {
      final weight = item.timesUsed > 0 ? item.timesUsed : 1;

      final color = item.color.trim();

      if (color.isNotEmpty) {
        colorUsage.update(
          color,
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }

      final category = item.category.trim();

      if (category.isNotEmpty) {
        categoryUsage.update(
          category,
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }
    }

    return WardrobeMemory(
      uid: uid,
      favoriteClothingIds: favoriteIds,
      frequentlyUsedClothingIds: frequentlyUsedIds,
      rarelyUsedClothingIds: rarelyUsedIds,
      longUnusedClothingIds: longUnusedIds,
      mostUsedColor: _mostUsedValue(colorUsage),
      mostUsedCategory: _mostUsedValue(categoryUsage),
      totalClothes: clothes.length,
      totalUsage: totalUsage,
      updatedAt: DateTime.now(),
    );
  }

  String buildWardrobeSignature(List<ClothingItem> clothes) {
    final sortedClothes = List<ClothingItem>.from(clothes)
      ..sort((a, b) => a.id.compareTo(b.id));

    return sortedClothes
        .map((item) {
          return [
            item.id,
            item.category,
            item.color,
            item.fabric,
            item.season,
            item.brand ?? '',
            item.notes ?? '',
            item.favorite.toString(),
            item.timesUsed.toString(),
            item.lastWornAt?.toIso8601String() ?? '',
          ].join('|');
        })
        .join('||');
  }

  String _mostUsedValue(Map<String, int> values) {
    if (values.isEmpty) {
      return "Veri yok";
    }

    return values.entries.reduce((current, next) {
      return current.value >= next.value ? current : next;
    }).key;
  }
}
