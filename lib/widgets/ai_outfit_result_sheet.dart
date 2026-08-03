import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

class AiOutfitResultSheet extends StatelessWidget {
  final String suggestion;
  final String occasion;
  final List<ClothingItem> selectedClothes;
  final VoidCallback onRegenerate;
  final VoidCallback onAddToPlanner;

  const AiOutfitResultSheet({
    super.key,
    required this.suggestion,
    required this.occasion,
    required this.selectedClothes,
    required this.onRegenerate,
    required this.onAddToPlanner,
  });

  List<String> _parseSuggestionItems() {
    return suggestion
        .split('\n')
        .map((item) {
          return item.replaceFirst(RegExp(r'^[•\-\*\d\.\)\s]+'), '').trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  IconData _getItemIcon(String item) {
    final text = item.toLowerCase();

    if (text.contains('tişört') ||
        text.contains('gömlek') ||
        text.contains('kazak') ||
        text.contains('sweatshirt') ||
        text.contains('üst')) {
      return Icons.checkroom;
    }

    if (text.contains('pantolon') ||
        text.contains('jean') ||
        text.contains('chino') ||
        text.contains('alt')) {
      return Icons.style;
    }

    if (text.contains('ayakkabı') ||
        text.contains('sneaker') ||
        text.contains('bot') ||
        text.contains('loafer')) {
      return Icons.directions_walk;
    }

    if (text.contains('ceket') ||
        text.contains('mont') ||
        text.contains('hırka') ||
        text.contains('dış giyim')) {
      return Icons.layers;
    }

    if (text.contains('renk') ||
        text.contains('ton') ||
        text.contains('uyum')) {
      return Icons.palette_outlined;
    }

    if (text.contains('saat') ||
        text.contains('kemer') ||
        text.contains('aksesuar') ||
        text.contains('bileklik')) {
      return Icons.watch_outlined;
    }

    return Icons.auto_awesome;
  }

  @override
  Widget build(BuildContext context) {
    final suggestionItems = _parseSuggestionItems();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Gardırobundan AI Kombini",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kullanım amacı: $occasion",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: "Kapat",
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (selectedClothes.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.checkroom_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Seçilen Parçalar",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedClothes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = selectedClothes[index];

                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.checkroom,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.color,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  children: suggestionItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getItemIcon(item),
                              color: Theme.of(context).colorScheme.primary,
                              size: 23,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Öneri ${index + 1}",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onAddToPlanner,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text(
                  "Planlayıcıya Ekle",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  "Yeni Kombin Oluştur",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "AI önerileri stil tavsiyesidir. "
              "Son kararı kendi zevkine göre verebilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
