import 'package:flutter/material.dart';

import '../../models/wardrobe_analysis.dart';

class WardrobeAnalysisScreen extends StatelessWidget {
  final WardrobeAnalysis analysis;

  const WardrobeAnalysisScreen({super.key, required this.analysis});

  Color _scoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(analysis.wardrobeScore);

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
