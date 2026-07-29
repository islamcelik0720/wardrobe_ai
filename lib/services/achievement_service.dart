import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/clothing_item.dart';
import '../models/outfit_plan.dart';

class AchievementService {
  List<Achievement> generateAchievements({
    required List<ClothingItem> clothes,
    required List<OutfitPlan> outfitPlans,
  }) {
    final int totalClothes = clothes.length;

    final int favoriteCount = clothes.where((item) => item.favorite).length;

    final int totalUsage = clothes.fold(0, (sum, item) => sum + item.timesUsed);

    final int plannedOutfits = outfitPlans.length;

    return [
      Achievement(
        title: "İlk Adım",
        description: "İlk kıyafetini ekle",
        icon: Icons.checkroom,
        currentValue: totalClothes,
        targetValue: 1,
        isUnlocked: totalClothes >= 1,
      ),

      Achievement(
        title: "Koleksiyoncu",
        description: "10 kıyafet ekle",
        icon: Icons.inventory_2,
        currentValue: totalClothes,
        targetValue: 10,
        isUnlocked: totalClothes >= 10,
      ),

      Achievement(
        title: "Favori Ustası",
        description: "5 favori kıyafet ekle",
        icon: Icons.star,
        currentValue: favoriteCount,
        targetValue: 5,
        isUnlocked: favoriteCount >= 5,
      ),

      Achievement(
        title: "Aktif Kullanıcı",
        description: "20 kez kıyafet giy",
        icon: Icons.local_fire_department,
        currentValue: totalUsage,
        targetValue: 20,
        isUnlocked: totalUsage >= 20,
      ),

      Achievement(
        title: "Planlayıcı",
        description: "7 kombin planla",
        icon: Icons.calendar_month,
        currentValue: plannedOutfits,
        targetValue: 7,
        isUnlocked: plannedOutfits >= 7,
      ),
    ];
  }
}
