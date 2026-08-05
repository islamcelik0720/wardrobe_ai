import 'package:flutter/material.dart';

import '../models/clothing_analysis_result.dart';

class ClothingAnalysisCard extends StatelessWidget {
  final ClothingAnalysisResult result;
  final Set<String> editedFields;
  final String? currentCategory;
  final String? currentColor;
  final String? currentFabric;
  final String? currentSeason;
  final String? currentBrand;

  const ClothingAnalysisCard({
    super.key,
    required this.result,
    required this.editedFields,
    required this.currentCategory,
    required this.currentColor,
    required this.currentFabric,
    required this.currentSeason,
    required this.currentBrand,
  });

  Color _confidenceColor(int value) {
    if (value >= 85) {
      return Colors.green;
    }

    if (value >= 60) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String _confidenceText(int value) {
    if (value >= 85) {
      return "Yüksek güven";
    }

    if (value >= 60) {
      return "Orta güven";
    }

    return "Düşük güven";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Analiz Sonucu",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Tahminleri kontrol edip değiştirebilirsin.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildResultRow(
            context: context,
            fieldKey: "category",
            icon: Icons.category_outlined,
            title: "Kategori",
            value: currentCategory ?? result.category,
            confidence: result.categoryConfidence,
          ),

          _buildResultRow(
            context: context,
            fieldKey: "color",
            icon: Icons.palette_outlined,
            title: "Renk",
            value: currentColor ?? result.color,
            confidence: result.colorConfidence,
          ),

          _buildResultRow(
            context: context,
            fieldKey: "fabric",
            icon: Icons.texture_outlined,
            title: "Kumaş",
            value: currentFabric ?? result.fabric,
            confidence: result.fabricConfidence,
          ),

          _buildResultRow(
            context: context,
            fieldKey: "season",
            icon: Icons.wb_sunny_outlined,
            title: "Mevsim",
            value: currentSeason ?? result.season,
            confidence: result.seasonConfidence,
          ),

          if (result.hasBrand)
            _buildResultRow(
              context: context,
              fieldKey: "brand",
              icon: Icons.sell_outlined,
              title: "Marka",
              value: currentBrand?.trim().isNotEmpty == true
                  ? currentBrand!
                  : result.brand!,
              confidence: result.brandConfidence,
            ),

          if (result.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.description,
                      style: const TextStyle(
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          Text(
            "Genel AI güveni: %${result.averageConfidence}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _confidenceColor(result.averageConfidence),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required BuildContext context,
    required String fieldKey,
    required IconData icon,
    required String title,
    required String value,
    required int confidence,
  }) {
    final bool isEdited = editedFields.contains(fieldKey);

    final Color color = isEdited
        ? Theme.of(context).colorScheme.primary
        : _confidenceColor(confidence);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            isEdited
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Kullanıcı düzenledi",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "%$confidence",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _confidenceText(confidence),
                        style: TextStyle(color: color, fontSize: 10),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
