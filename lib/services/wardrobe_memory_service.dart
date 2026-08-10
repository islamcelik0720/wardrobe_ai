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
        preferredColors: const [],
        preferredCategories: const [],
        avoidOverusingClothingIds: const [],
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

    final usedClothes = clothes.where((item) => item.timesUsed > 0).toList();

    final double averageUsage = usedClothes.isEmpty
        ? 0
        : usedClothes.fold<int>(0, (sum, item) => sum + item.timesUsed) /
              usedClothes.length;

    final avoidOverusingClothingIds = sortedByUsage
        .where((item) {
          if (item.timesUsed < 3) {
            return false;
          }

          return item.timesUsed >= averageUsage * 1.5;
        })
        .take(5)
        .map((item) => item.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

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

    final sortedColors = colorUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedCategories = categoryUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final preferredColors = sortedColors
        .where((entry) => entry.value > 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();

    final preferredCategories = sortedCategories
        .where((entry) => entry.value > 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();

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
      preferredColors: preferredColors,
      preferredCategories: preferredCategories,
      avoidOverusingClothingIds: avoidOverusingClothingIds,
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
