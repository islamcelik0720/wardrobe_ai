class ClothingAnalysisResult {
  final String category;
  final String color;
  final String fabric;
  final String season;
  final String? brand;
  final String description;

  final int categoryConfidence;
  final int colorConfidence;
  final int fabricConfidence;
  final int seasonConfidence;
  final int brandConfidence;

  const ClothingAnalysisResult({
    required this.category,
    required this.color,
    required this.fabric,
    required this.season,
    required this.brand,
    required this.description,
    required this.categoryConfidence,
    required this.colorConfidence,
    required this.fabricConfidence,
    required this.seasonConfidence,
    required this.brandConfidence,
  });

  factory ClothingAnalysisResult.fromMap(Map<String, dynamic> map) {
    return ClothingAnalysisResult(
      category: map['category']?.toString().trim() ?? '',
      color: map['color']?.toString().trim() ?? '',
      fabric: map['fabric']?.toString().trim() ?? '',
      season: map['season']?.toString().trim() ?? '',
      brand: _nullableText(map['brand']),
      description: map['description']?.toString().trim() ?? '',
      categoryConfidence: _confidence(map['categoryConfidence']),
      colorConfidence: _confidence(map['colorConfidence']),
      fabricConfidence: _confidence(map['fabricConfidence']),
      seasonConfidence: _confidence(map['seasonConfidence']),
      brandConfidence: _confidence(map['brandConfidence']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'color': color,
      'fabric': fabric,
      'season': season,
      'brand': brand,
      'description': description,
      'categoryConfidence': categoryConfidence,
      'colorConfidence': colorConfidence,
      'fabricConfidence': fabricConfidence,
      'seasonConfidence': seasonConfidence,
      'brandConfidence': brandConfidence,
    };
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'bilinmiyor' ||
        text.toLowerCase() == 'belirsiz') {
      return null;
    }

    return text;
  }

  static int _confidence(dynamic value) {
    final parsedValue = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    return (parsedValue ?? 0).clamp(0, 100);
  }

  int get averageConfidence {
    final values = [
      categoryConfidence,
      colorConfidence,
      fabricConfidence,
      seasonConfidence,
    ];

    final total = values.reduce((a, b) => a + b);

    return (total / values.length).round();
  }

  bool get hasBrand {
    return brand != null && brand!.trim().isNotEmpty;
  }
}
