import '../models/clothing_item.dart';
import '../models/donation_candidate.dart';

class DonationCandidateService {
  List<DonationCandidate> findCandidates(List<ClothingItem> clothes) {
    final now = DateTime.now();

    final candidates = clothes
        .where((item) {
          final lastWornAt = item.lastWornAt;

          if (lastWornAt == null) {
            return false;
          }

          final daysSinceLastWorn = now.difference(lastWornAt).inDays;

          final isLongUnused = daysSinceLastWorn >= 90;

          final isLowUsage = item.timesUsed <= 2;

          final isNotFavorite = !item.favorite;

          return isLongUnused && isLowUsage && isNotFavorite;
        })
        .map((item) {
          final daysSinceLastWorn = now.difference(item.lastWornAt!).inDays;

          return DonationCandidate(
            clothingId: item.id,
            daysSinceLastWorn: daysSinceLastWorn,
            timesUsed: item.timesUsed,
            reason:
                "Bu parça yaklaşık $daysSinceLastWorn gündür "
                "giyilmedi ve toplam ${item.timesUsed} kez kullanıldı.",
          );
        })
        .toList();

    candidates.sort(
      (a, b) => b.daysSinceLastWorn.compareTo(a.daysSinceLastWorn),
    );

    return candidates;
  }
}
