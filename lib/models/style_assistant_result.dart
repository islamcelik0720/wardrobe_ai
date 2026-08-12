import 'selected_clothing_reason.dart';

class StyleAssistantResult {
  final String response;
  final int outfitScore;
  final int colorScore;
  final int weatherScore;
  final int occasionScore;
  final List<String> strengths;
  final List<String> warnings;
  final bool shouldShowScore;
  final List<String> selectedClothingIds;
  final List<SelectedClothingReason> selectedClothingReasons;
  final String memoryNote;
  final String weatherPriority;
  final String occasionPriority;
  final String memoryPriority;
  final String diversityPriority;
  final List<String> validationWarnings;

  const StyleAssistantResult({
    required this.response,
    required this.outfitScore,
    required this.colorScore,
    required this.weatherScore,
    required this.occasionScore,
    required this.strengths,
    required this.warnings,
    required this.shouldShowScore,
    required this.selectedClothingIds,
    required this.selectedClothingReasons,
    required this.memoryNote,
    required this.weatherPriority,
    required this.occasionPriority,
    required this.memoryPriority,
    required this.diversityPriority,
    required this.validationWarnings,
  });

  Map<String, dynamic> toMap() {
    return {
      'response': response,
      'shouldShowScore': shouldShowScore,
      'outfitScore': outfitScore,
      'colorScore': colorScore,
      'weatherScore': weatherScore,
      'occasionScore': occasionScore,
      'strengths': strengths,
      'warnings': warnings,
      'selectedClothingIds': selectedClothingIds,
      'selectedClothingReasons': selectedClothingReasons
          .map((item) => item.toMap())
          .toList(),
      'memoryNote': memoryNote,
      'weatherPriority': weatherPriority,
      'occasionPriority': occasionPriority,
      'memoryPriority': memoryPriority,
      'diversityPriority': diversityPriority,
      'validationWarnings': validationWarnings,
    };
  }

  factory StyleAssistantResult.fromMap(Map<String, dynamic> map) {
    return StyleAssistantResult(
      response: map['response']?.toString().trim() ?? '',
      outfitScore: _score(map['outfitScore']),
      colorScore: _score(map['colorScore']),
      weatherScore: _score(map['weatherScore']),
      occasionScore: _score(map['occasionScore']),
      strengths: _stringList(map['strengths']),
      warnings: _stringList(map['warnings']),
      selectedClothingIds: _stringList(map['selectedClothingIds']),
      shouldShowScore: map['shouldShowScore'] == true,
      selectedClothingReasons: _reasonList(map['selectedClothingReasons']),
      memoryNote: map['memoryNote']?.toString().trim() ?? '',
      weatherPriority: map['weatherPriority']?.toString().trim() ?? 'low',

      occasionPriority: map['occasionPriority']?.toString().trim() ?? 'low',

      memoryPriority: map['memoryPriority']?.toString().trim() ?? 'low',

      diversityPriority: map['diversityPriority']?.toString().trim() ?? 'low',
      validationWarnings: map['validationWarnings'] is List
          ? List<String>.from(
              (map['validationWarnings'] as List).map(
                (item) => item.toString(),
              ),
            )
          : [],
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

  static List<SelectedClothingReason> _reasonList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) {
          return SelectedClothingReason.fromMap(
            Map<String, dynamic>.from(item),
          );
        })
        .where((item) {
          return item.clothingId.isNotEmpty && item.reason.isNotEmpty;
        })
        .toList();
  }
}
