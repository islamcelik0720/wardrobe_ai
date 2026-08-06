import '../models/clothing_item.dart';
import '../models/wardrobe_analysis.dart';

class WardrobeAnalysisService {
  WardrobeAnalysis analyze(List<ClothingItem> clothes) {
    if (clothes.isEmpty) {
      return const WardrobeAnalysis(
        totalClothes: 0,
        favoriteCount: 0,
        unusedClothesCount: 0,
        mostCommonCategory: "Veri yok",
        leastCommonCategory: "Veri yok",
        mostCommonColor: "Veri yok",
        leastCommonColor: "Veri yok",
        mostCommonSeason: "Veri yok",
        leastCommonSeason: "Veri yok",
        wardrobeScore: 0,
        categoryDistribution: {},
        colorDistribution: {},
        seasonDistribution: {},
        strengths: [],
        warnings: ["Dolap analizi için henüz kıyafet bulunmuyor."],
        recommendations: [
          "Analiz oluşturabilmek için gardırobuna kıyafet ekle.",
        ],
      );
    }

    final categoryDistribution = _buildDistribution(
      clothes.map((item) => item.category),
    );

    final colorDistribution = _buildDistribution(
      clothes.map((item) => item.color),
    );

    final seasonDistribution = _buildDistribution(
      clothes.map((item) => item.season),
    );

    final favoriteCount = clothes.where((item) {
      return item.favorite;
    }).length;

    final unusedClothesCount = clothes.where((item) {
      return item.timesUsed == 0;
    }).length;

    final mostCommonCategory = _mostCommon(categoryDistribution);

    final leastCommonCategory = _leastCommon(categoryDistribution);

    final mostCommonColor = _mostCommon(colorDistribution);

    final leastCommonColor = _leastCommon(colorDistribution);

    final mostCommonSeason = _mostCommon(seasonDistribution);

    final leastCommonSeason = _leastCommon(seasonDistribution);

    final strengths = _buildStrengths(
      clothes: clothes,
      categoryDistribution: categoryDistribution,
      colorDistribution: colorDistribution,
      seasonDistribution: seasonDistribution,
      favoriteCount: favoriteCount,
      unusedClothesCount: unusedClothesCount,
    );

    final warnings = _buildWarnings(
      clothes: clothes,
      categoryDistribution: categoryDistribution,
      colorDistribution: colorDistribution,
      seasonDistribution: seasonDistribution,
      unusedClothesCount: unusedClothesCount,
    );

    final recommendations = _buildRecommendations(
      clothes: clothes,
      categoryDistribution: categoryDistribution,
      colorDistribution: colorDistribution,
      seasonDistribution: seasonDistribution,
      unusedClothesCount: unusedClothesCount,
    );

    final wardrobeScore = _calculateScore(
      clothes: clothes,
      categoryDistribution: categoryDistribution,
      colorDistribution: colorDistribution,
      seasonDistribution: seasonDistribution,
      unusedClothesCount: unusedClothesCount,
    );

    return WardrobeAnalysis(
      totalClothes: clothes.length,
      favoriteCount: favoriteCount,
      unusedClothesCount: unusedClothesCount,
      mostCommonCategory: mostCommonCategory,
      leastCommonCategory: leastCommonCategory,
      mostCommonColor: mostCommonColor,
      leastCommonColor: leastCommonColor,
      mostCommonSeason: mostCommonSeason,
      leastCommonSeason: leastCommonSeason,
      wardrobeScore: wardrobeScore,
      categoryDistribution: categoryDistribution,
      colorDistribution: colorDistribution,
      seasonDistribution: seasonDistribution,
      strengths: strengths,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  Map<String, int> _buildDistribution(Iterable<String> values) {
    final Map<String, int> distribution = {};

    for (final value in values) {
      final normalizedValue = value.trim();

      if (normalizedValue.isEmpty) {
        continue;
      }

      distribution.update(
        normalizedValue,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return distribution;
  }

  String _mostCommon(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return "Veri yok";
    }

    return distribution.entries.reduce((current, next) {
      return current.value >= next.value ? current : next;
    }).key;
  }

  String _leastCommon(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return "Veri yok";
    }

    return distribution.entries.reduce((current, next) {
      return current.value <= next.value ? current : next;
    }).key;
  }

  List<String> _buildStrengths({
    required List<ClothingItem> clothes,
    required Map<String, int> categoryDistribution,
    required Map<String, int> colorDistribution,
    required Map<String, int> seasonDistribution,
    required int favoriteCount,
    required int unusedClothesCount,
  }) {
    final List<String> strengths = [];

    if (categoryDistribution.length >= 5) {
      strengths.add("Kategori çeşitliliğin oldukça iyi.");
    }

    if (colorDistribution.length >= 6) {
      strengths.add("Dolabında farklı renk seçenekleri bulunuyor.");
    }

    if (seasonDistribution.length == 4) {
      strengths.add("Dört mevsime uygun kıyafetlerin bulunuyor.");
    }

    if (favoriteCount >= 5) {
      strengths.add("Favori kıyafetlerini düzenli olarak belirliyorsun.");
    }

    final unusedRatio = unusedClothesCount / clothes.length;

    if (unusedRatio <= 0.20) {
      strengths.add(
        "Dolabındaki kıyafetlerin büyük bölümünü aktif kullanıyorsun.",
      );
    }

    if (strengths.isEmpty) {
      strengths.add("Dolabını geliştirmek için iyi bir başlangıç yaptın.");
    }

    return strengths;
  }

  List<String> _buildWarnings({
    required List<ClothingItem> clothes,
    required Map<String, int> categoryDistribution,
    required Map<String, int> colorDistribution,
    required Map<String, int> seasonDistribution,
    required int unusedClothesCount,
  }) {
    final List<String> warnings = [];

    final mostCommonColorEntry = _mostCommonEntry(colorDistribution);

    if (mostCommonColorEntry != null) {
      final colorRatio = mostCommonColorEntry.value / clothes.length;

      if (colorRatio >= 0.50) {
        warnings.add(
          "Dolabındaki kıyafetlerin büyük bölümü "
          "${mostCommonColorEntry.key} renkte.",
        );
      }
    }

    final mostCommonCategoryEntry = _mostCommonEntry(categoryDistribution);

    if (mostCommonCategoryEntry != null) {
      final categoryRatio = mostCommonCategoryEntry.value / clothes.length;

      if (categoryRatio >= 0.45) {
        warnings.add(
          "${mostCommonCategoryEntry.key} kategorisi dolabında "
          "diğer kategorilere göre fazla.",
        );
      }
    }

    final unusedRatio = unusedClothesCount / clothes.length;

    if (unusedRatio >= 0.30) {
      warnings.add("$unusedClothesCount kıyafetin henüz hiç kullanılmamış.");
    }

    if (seasonDistribution.length < 3) {
      warnings.add("Mevsim çeşitliliğin düşük görünüyor.");
    }

    if (categoryDistribution.length < 4) {
      warnings.add("Kategori çeşitliliğin geliştirilebilir.");
    }

    if (warnings.isEmpty) {
      warnings.add("Dolabında belirgin bir dengesizlik görünmüyor.");
    }

    return warnings;
  }

  List<String> _buildRecommendations({
    required List<ClothingItem> clothes,
    required Map<String, int> categoryDistribution,
    required Map<String, int> colorDistribution,
    required Map<String, int> seasonDistribution,
    required int unusedClothesCount,
  }) {
    final List<String> recommendations = [];

    if (!colorDistribution.containsKey("Beyaz") &&
        !colorDistribution.containsKey("Krem") &&
        !colorDistribution.containsKey("Bej")) {
      recommendations.add(
        "Açık renk bir üst giyim eklemek kombin çeşitliliğini artırabilir.",
      );
    }

    if (!categoryDistribution.containsKey("Ayakkabı")) {
      recommendations.add(
        "Dolabına farklı kombinlerle uyum sağlayacak bir ayakkabı ekleyebilirsin.",
      );
    }

    if (!categoryDistribution.containsKey("Ceket") &&
        !categoryDistribution.containsKey("Mont")) {
      recommendations.add(
        "Dış giyim seçeneği eklemek katmanlı kombinlerini güçlendirebilir.",
      );
    }

    if (!categoryDistribution.containsKey("Pantolon")) {
      recommendations.add(
        "Alt giyim seçeneği olarak bir pantolon ekleyebilirsin.",
      );
    }

    if (!seasonDistribution.containsKey("Yaz")) {
      recommendations.add(
        "Yaz için ince ve nefes alan kıyafetler ekleyebilirsin.",
      );
    }

    if (!seasonDistribution.containsKey("Kış")) {
      recommendations.add(
        "Kış için sıcak tutan kıyafet seçeneklerini artırabilirsin.",
      );
    }

    if (unusedClothesCount > 0) {
      recommendations.add(
        "Hiç kullanmadığın kıyafetleri yeni kombinlerde değerlendirebilirsin.",
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        "Dolabın dengeli görünüyor; mevcut parçalarını farklı kombinlerle değerlendirebilirsin.",
      );
    }

    return recommendations;
  }

  int _calculateScore({
    required List<ClothingItem> clothes,
    required Map<String, int> categoryDistribution,
    required Map<String, int> colorDistribution,
    required Map<String, int> seasonDistribution,
    required int unusedClothesCount,
  }) {
    double score = 35;

    score += _limitedScore(categoryDistribution.length * 6, maximum: 25);

    score += _limitedScore(colorDistribution.length * 3, maximum: 20);

    score += _limitedScore(seasonDistribution.length * 5, maximum: 20);

    final unusedRatio = unusedClothesCount / clothes.length;

    if (unusedRatio <= 0.10) {
      score += 15;
    } else if (unusedRatio <= 0.25) {
      score += 10;
    } else if (unusedRatio <= 0.40) {
      score += 5;
    }

    final mostCommonColorEntry = _mostCommonEntry(colorDistribution);

    if (mostCommonColorEntry != null) {
      final ratio = mostCommonColorEntry.value / clothes.length;

      if (ratio >= 0.60) {
        score -= 10;
      } else if (ratio >= 0.45) {
        score -= 5;
      }
    }

    return score.round().clamp(0, 100);
  }

  double _limitedScore(num value, {required double maximum}) {
    return value > maximum ? maximum : value.toDouble();
  }

  MapEntry<String, int>? _mostCommonEntry(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return null;
    }

    return distribution.entries.reduce((current, next) {
      return current.value >= next.value ? current : next;
    });
  }
}
