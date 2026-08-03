class AiOutfitResult {
  final String suggestion;
  final List<String> selectedClothingIds;

  const AiOutfitResult({
    required this.suggestion,
    required this.selectedClothingIds,
  });

  factory AiOutfitResult.fromMap(Map<String, dynamic> map) {
    return AiOutfitResult(
      suggestion: map['suggestion']?.toString().trim() ?? '',
      selectedClothingIds: List<String>.from(map['selectedClothingIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suggestion': suggestion,
      'selectedClothingIds': selectedClothingIds,
    };
  }
}
