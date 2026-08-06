class WardrobeAnalysis {
  final int totalClothes;
  final int favoriteCount;
  final int unusedClothesCount;

  final String mostCommonCategory;
  final String leastCommonCategory;

  final String mostCommonColor;
  final String leastCommonColor;

  final String mostCommonSeason;
  final String leastCommonSeason;

  final int wardrobeScore;

  final Map<String, int> categoryDistribution;
  final Map<String, int> colorDistribution;
  final Map<String, int> seasonDistribution;

  final List<String> strengths;
  final List<String> warnings;
  final List<String> recommendations;

  const WardrobeAnalysis({
    required this.totalClothes,
    required this.favoriteCount,
    required this.unusedClothesCount,
    required this.mostCommonCategory,
    required this.leastCommonCategory,
    required this.mostCommonColor,
    required this.leastCommonColor,
    required this.mostCommonSeason,
    required this.leastCommonSeason,
    required this.wardrobeScore,
    required this.categoryDistribution,
    required this.colorDistribution,
    required this.seasonDistribution,
    required this.strengths,
    required this.warnings,
    required this.recommendations,
  });

  double get favoritePercentage {
    if (totalClothes == 0) {
      return 0;
    }

    return (favoriteCount / totalClothes) * 100;
  }

  double get unusedPercentage {
    if (totalClothes == 0) {
      return 0;
    }

    return (unusedClothesCount / totalClothes) * 100;
  }

  bool get isEmpty {
    return totalClothes == 0;
  }

  String get scoreLabel {
    if (wardrobeScore >= 85) {
      return "Çok iyi";
    }

    if (wardrobeScore >= 70) {
      return "İyi";
    }

    if (wardrobeScore >= 50) {
      return "Geliştirilebilir";
    }

    return "Dengesiz";
  }
}
