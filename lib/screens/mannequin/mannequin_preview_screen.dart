import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';

class MannequinPreviewScreen extends StatelessWidget {
  final List<ClothingItem> selectedClothes;

  const MannequinPreviewScreen({super.key, required this.selectedClothes});

  ClothingItem? _findClothing(List<String> categories) {
    for (final item in selectedClothes) {
      final category = item.category.toLowerCase();

      if (categories.any(category.contains)) {
        return item;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final top = _findClothing(['tişört', 'gömlek', 'kazak', 'sweatshirt']);

    final bottom = _findClothing(['pantolon', 'jean', 'şort', 'etek']);

    final outerwear = _findClothing(['ceket', 'mont', 'hırka']);

    final shoes = _findClothing(['ayakkabı', 'sneaker', 'bot']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('2D Manken Ön İzleme'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AspectRatio(
                  aspectRatio: 0.60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildMannequin(context),

                      if (bottom != null)
                        Positioned(
                          top: 250,
                          child: _buildClothingLayer(
                            context: context,
                            item: bottom,
                            width: 150,
                            height: 165,
                            icon: Icons.style,
                          ),
                        ),

                      if (top != null)
                        Positioned(
                          top: 130,
                          child: _buildClothingLayer(
                            context: context,
                            item: top,
                            width: 170,
                            height: 140,
                            icon: Icons.checkroom,
                          ),
                        ),

                      if (outerwear != null)
                        Positioned(
                          top: 115,
                          child: _buildClothingLayer(
                            context: context,
                            item: outerwear,
                            width: 190,
                            height: 165,
                            icon: Icons.layers,
                            transparent: true,
                          ),
                        ),

                      if (shoes != null)
                        Positioned(
                          bottom: 20,
                          child: _buildClothingLayer(
                            context: context,
                            item: shoes,
                            width: 150,
                            height: 65,
                            icon: Icons.directions_walk,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildSelectedItemsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMannequin(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 118,
          height: 205,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(55),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 180,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(width: 18),
            Container(
              width: 44,
              height: 180,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClothingLayer({
    required BuildContext context,
    required ClothingItem item,
    required double width,
    required double height,
    required IconData icon,
    bool transparent = false,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: transparent ? 0.16 : 0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary.withValues(alpha: 0.60), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primary, size: 30),
          const SizedBox(height: 6),
          Text(
            item.category,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            item.color,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.checkroom, color: Color(0xFF6A11CB)),
                SizedBox(width: 10),
                Text(
                  'Mankende Gösterilen Parçalar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...selectedClothes.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  item.category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${item.color} • ${item.fabric}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
