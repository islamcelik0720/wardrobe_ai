import 'package:flutter/material.dart';

import '../../models/wardrobe_analysis.dart';
import '../../models/clothing_item.dart';
import '../../models/wardrobe_gap_analysis_result.dart';
import '../../models/donation_candidate.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/donation_candidate_service.dart';

class WardrobeAnalysisScreen extends StatelessWidget {
  final WardrobeAnalysis analysis;
  final WardrobeGapAnalysisResult? aiAnalysis;
  final List<ClothingItem> clothes;

  WardrobeAnalysisScreen({
    super.key,
    required this.analysis,
    required this.aiAnalysis,
    required this.clothes,
  });

  final DonationCandidateService _donationCandidateService =
      DonationCandidateService();
  final FirestoreService _firestoreService = FirestoreService();

  Color _scoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(analysis.wardrobeScore);

    final List<DonationCandidate> donationCandidates = _donationCandidateService
        .findCandidates(clothes);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detaylı Dolap Analizi"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildScoreCard(context, scoreColor),

              const SizedBox(height: 18),

              _buildStatisticsGrid(context),

              const SizedBox(height: 18),

              _buildUsageMemorySection(context),

              const SizedBox(height: 18),

              _buildFavoritesSection(context),

              const SizedBox(height: 18),

              _buildUnusedSection(context),

              const SizedBox(height: 18),

              _buildDistributionCard(
                context: context,
                title: "Kategori Dağılımı",
                icon: Icons.category_outlined,
                distribution: analysis.categoryDistribution,
              ),

              const SizedBox(height: 18),

              _buildDistributionCard(
                context: context,
                title: "Renk Dağılımı",
                icon: Icons.palette_outlined,
                distribution: analysis.colorDistribution,
              ),

              const SizedBox(height: 18),

              _buildDistributionCard(
                context: context,
                title: "Mevsim Dağılımı",
                icon: Icons.wb_sunny_outlined,
                distribution: analysis.seasonDistribution,
              ),

              const SizedBox(height: 18),

              _buildMessageSection(
                context: context,
                title: "Güçlü Yönler",
                icon: Icons.check_circle_outline_rounded,
                items: analysis.strengths,
                emptyText: "Henüz güçlü yön belirlenemedi.",
              ),

              const SizedBox(height: 18),

              _buildMessageSection(
                context: context,
                title: "Dikkat Edilmesi Gerekenler",
                icon: Icons.warning_amber_rounded,
                items: analysis.warnings,
                emptyText: "Belirgin bir uyarı bulunmuyor.",
              ),

              const SizedBox(height: 18),

              _buildMessageSection(
                context: context,
                title: "Öneriler",
                icon: Icons.lightbulb_outline_rounded,
                items: analysis.recommendations,
                emptyText: "Şu anda ek bir öneri bulunmuyor.",
              ),
              const SizedBox(height: 18),

              _buildLongUnusedSection(context),
              const SizedBox(height: 18),

              _buildDonationCandidatesSection(context, donationCandidates),

              if (aiAnalysis != null) ...[
                const SizedBox(height: 18),

                _buildAiSummaryCard(context, aiAnalysis!),

                const SizedBox(height: 18),

                _buildMessageSection(
                  context: context,
                  title: "AI Güçlü Yönler",
                  icon: Icons.auto_awesome_rounded,
                  items: aiAnalysis!.strengths,
                  emptyText: "AI tarafından ek güçlü yön bulunamadı.",
                ),

                const SizedBox(height: 18),

                _buildMessageSection(
                  context: context,
                  title: "Eksik Kategoriler",
                  icon: Icons.category_outlined,
                  items: aiAnalysis!.missingCategories,
                  emptyText: "Belirgin bir kategori eksiği bulunmuyor.",
                ),

                const SizedBox(height: 18),

                _buildMessageSection(
                  context: context,
                  title: "Eksik Renkler",
                  icon: Icons.palette_outlined,
                  items: aiAnalysis!.missingColors,
                  emptyText: "Belirgin bir renk eksiği bulunmuyor.",
                ),

                const SizedBox(height: 18),

                _buildMessageSection(
                  context: context,
                  title: "Fazla Tekrar Edenler",
                  icon: Icons.repeat_rounded,
                  items: aiAnalysis!.overrepresentedItems,
                  emptyText: "Fazla tekrar eden bir parça grubu bulunmuyor.",
                ),

                const SizedBox(height: 18),

                _buildMessageSection(
                  context: context,
                  title: "AI Önerileri",
                  icon: Icons.lightbulb_outline_rounded,
                  items: aiAnalysis!.recommendations,
                  emptyText: "AI tarafından ek öneri bulunmuyor.",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, Color scoreColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Dolap Puanın",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${analysis.wardrobeScore}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "/ 100",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            analysis.scoreLabel,
            style: TextStyle(
              color: scoreColor,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Puan; kategori, renk, mevsim çeşitliliği ve kullanım durumuna göre hesaplanır.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    final items = [
      ("Toplam", "${analysis.totalClothes}", Icons.checkroom_outlined),
      ("Favoriler", "${analysis.favoriteCount}", Icons.star_outline_rounded),
      (
        "Kullanılmamış",
        "${analysis.unusedClothesCount}",
        Icons.history_toggle_off_rounded,
      ),
      ("En Sık Renk", analysis.mostCommonColor, Icons.palette_outlined),
      ("En Sık Kategori", analysis.mostCommonCategory, Icons.category_outlined),
      ("En Sık Mevsim", analysis.mostCommonSeason, Icons.wb_sunny_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.$3,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageMemorySection(BuildContext context) {
    final frequentlyUsed = List<ClothingItem>.from(clothes)
      ..sort((a, b) => b.timesUsed.compareTo(a.timesUsed));

    final visibleItems = frequentlyUsed
        .where((item) => item.timesUsed > 0)
        .take(5)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "En Sık Kullanılanlar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (visibleItems.isEmpty)
              Text(
                "Henüz kullanım geçmişi oluşmadı.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...visibleItems.map((item) {
                return _buildClothingMemoryRow(
                  context: context,
                  item: item,
                  subtitle: "${item.timesUsed} kez kullanıldı",
                  icon: Icons.repeat_rounded,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(BuildContext context) {
    final favoriteClothes = clothes
        .where((item) => item.favorite)
        .take(6)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "Favori Parçalar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "${analysis.favoriteCount}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (favoriteClothes.isEmpty)
              Text(
                "Henüz favori kıyafet bulunmuyor.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...favoriteClothes.map((item) {
                return _buildClothingMemoryRow(
                  context: context,
                  item: item,
                  subtitle: "${item.color} • ${item.timesUsed} kez kullanıldı",
                  icon: Icons.star_outline_rounded,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildUnusedSection(BuildContext context) {
    final unusedClothes = clothes
        .where((item) => item.timesUsed == 0)
        .take(8)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "Henüz Kullanılmayanlar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "${analysis.unusedClothesCount}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (unusedClothes.isEmpty)
              Text(
                "Gardırobundaki tüm kıyafetler en az bir kez kullanılmış.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...unusedClothes.map((item) {
                return _buildClothingMemoryRow(
                  context: context,
                  item: item,
                  subtitle: "${item.color} • Henüz kullanılmadı",
                  icon: Icons.new_releases_outlined,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildClothingMemoryRow({
    required BuildContext context,
    required ClothingItem item,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: item.imageUrl.trim().isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    )
                  : Icon(
                      Icons.checkroom_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Icon(icon, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildDistributionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Map<String, int> distribution,
  }) {
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);

    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const Text("Gösterilecek veri bulunmuyor.")
            else
              ...entries.map((entry) {
                final ratio = total == 0 ? 0.0 : entry.value / total;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "${entry.value} • %${(ratio * 100).round()}",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 9,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLongUnusedSection(BuildContext context) {
    final now = DateTime.now();

    final longUnusedClothes =
        clothes.where((item) {
          final lastWornAt = item.lastWornAt;

          if (lastWornAt == null) {
            return false;
          }

          final days = now.difference(lastWornAt).inDays;

          return days >= 30;
        }).toList()..sort((a, b) {
          final aDate = a.lastWornAt!;
          final bDate = b.lastWornAt!;

          return aDate.compareTo(bDate);
        });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "Uzun Süredir Giyilmeyenler",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (longUnusedClothes.isEmpty)
              Text(
                "30 günden uzun süredir giyilmeyen kıyafet bulunmuyor.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...longUnusedClothes.take(8).map((item) {
                final days = now.difference(item.lastWornAt!).inDays;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl.trim().isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.broken_image_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.checkroom_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${item.color} • $days gündür giyilmedi",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCandidatesSection(
    BuildContext context,
    List<DonationCandidate> candidates,
  ) {
    final clothesById = {for (final item in clothes) item.id: item};

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    "Bağış Adayları",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Uzun süredir kullanılmayan ve kullanım sıklığı düşük "
              "parçalar burada öneri olarak gösterilir.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            if (candidates.isEmpty)
              Text(
                "Şu anda bağış için önerilen bir kıyafet bulunmuyor.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...candidates.map((candidate) {
                final item = clothesById[candidate.clothingId];

                if (item == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl.trim().isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.broken_image_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.checkroom_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              "${item.color} • "
                              "${candidate.daysSinceLastWorn} gündür giyilmedi",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              candidate.reason,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final user = AuthService().currentUser;

                                  if (user == null) {
                                    return;
                                  }

                                  try {
                                    await _firestoreService.addToDonationList(
                                      uid: user.uid,
                                      item: item,
                                    );

                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Kıyafet bağış listesine eklendi.",
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  } catch (e) {
                                    if (!context.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Kıyafet bağış listesine eklenemedi.",
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                  }
                                },
                                icon: const Icon(
                                  Icons.volunteer_activism_outlined,
                                ),
                                label: const Text(
                                  "Bağış Listesine Ekle",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryCard(
    BuildContext context,
    WardrobeGapAnalysisResult result,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  "AI Değerlendirmesi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            result.summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Ana gardırop puanı yerel analizle hesaplanır; "
            "bu bölüm Gemini'nin kişiselleştirilmiş değerlendirmesidir.",
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<String> items,
    required String emptyText,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text(
                emptyText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
