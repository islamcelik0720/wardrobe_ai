class WardrobeGapAnalysisResult {
  final int wardrobeScore;

  final List<String> strengths;
  final List<String> missingCategories;
  final List<String> missingColors;
  final List<String> overrepresentedItems;
  final List<String> recommendations;

  final String summary;
  final String wardrobeSignature;

  const WardrobeGapAnalysisResult({
    required this.wardrobeScore,
    required this.strengths,
    required this.missingCategories,
    required this.missingColors,
    required this.overrepresentedItems,
    required this.recommendations,
    required this.summary,
    required this.wardrobeSignature,
  });

  Map<String, dynamic> toMap() {
    return {
      'wardrobeScore': wardrobeScore,
      'strengths': strengths,
      'missingCategories': missingCategories,
      'missingColors': missingColors,
      'overrepresentedItems': overrepresentedItems,
      'recommendations': recommendations,
      'summary': summary,
      'wardrobeSignature': wardrobeSignature,
    };
  }

  factory WardrobeGapAnalysisResult.fromMap(Map<String, dynamic> map) {
    return WardrobeGapAnalysisResult(
      wardrobeScore: _score(map['wardrobeScore']),
      strengths: _stringList(map['strengths']),
      missingCategories: _stringList(map['missingCategories']),
      missingColors: _stringList(map['missingColors']),
      overrepresentedItems: _stringList(map['overrepresentedItems']),
      recommendations: _stringList(map['recommendations']),
      summary: map['summary']?.toString().trim() ?? '',
      wardrobeSignature: map['wardrobeSignature']?.toString() ?? '',
    );
  }

  static int _score(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');

    return (parsed ?? 0).clamp(0, 100);
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
