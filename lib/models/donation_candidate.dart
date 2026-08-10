class DonationCandidate {
  final String clothingId;
  final int daysSinceLastWorn;
  final int timesUsed;
  final String reason;

  const DonationCandidate({
    required this.clothingId,
    required this.daysSinceLastWorn,
    required this.timesUsed,
    required this.reason,
  });
}
