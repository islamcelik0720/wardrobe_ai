class SelectedClothingReason {
  final String clothingId;
  final String reason;

  const SelectedClothingReason({
    required this.clothingId,
    required this.reason,
  });

  factory SelectedClothingReason.fromMap(Map<String, dynamic> map) {
    return SelectedClothingReason(
      clothingId: map['clothingId']?.toString().trim() ?? '',
      reason: map['reason']?.toString().trim() ?? '',
    );
  }
}
