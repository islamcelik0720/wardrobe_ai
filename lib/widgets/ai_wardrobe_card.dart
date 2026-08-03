import 'package:flutter/material.dart';

import '../../../models/clothing_item.dart';

class AiWardrobeCard extends StatelessWidget {
  final List<ClothingItem> clothes;
  final bool isLoading;
  final Future<void> Function(List<ClothingItem> clothes) onGenerate;

  const AiWardrobeCard({
    super.key,
    required this.clothes,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A11CB).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Dolabımdan Kombin Oluştur",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "${clothes.length} kıyafetin Gemini tarafından incelenerek "
              "sana özel bir kombin oluşturulsun.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A11CB),
                  disabledBackgroundColor: Colors.white70,
                  disabledForegroundColor: const Color(0xFF6A11CB),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        await onGenerate(clothes);
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF6A11CB),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  isLoading ? "AI kombin hazırlıyor..." : "AI Kombini Oluştur",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
