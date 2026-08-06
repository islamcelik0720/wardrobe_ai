import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../models/saved_outfit.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../wardrobe/clothing_detail_screen.dart';
import '../../models/outfit_plan.dart';

class SavedOutfitsScreen extends StatelessWidget {
  const SavedOutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Kombinlerim"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ClothingItem>>(
              stream: firestoreService.getClothes(user.uid),
              builder: (context, clothesSnapshot) {
                if (clothesSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Kıyafetler yüklenemedi.\n"
                        "${clothesSnapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (clothesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clothes = clothesSnapshot.data ?? [];

                return StreamBuilder<List<SavedOutfit>>(
                  stream: firestoreService.getSavedOutfits(user.uid),
                  builder: (context, outfitsSnapshot) {
                    if (outfitsSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Kombinler yüklenemedi.\n"
                            "${outfitsSnapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (outfitsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final outfits = outfitsSnapshot.data ?? [];

                    if (outfits.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: outfits.length,
                      itemBuilder: (context, index) {
                        final outfit = outfits[index];

                        final selectedClothes = clothes.where((item) {
                          return outfit.clothingIds.contains(item.id);
                        }).toList();

                        return _buildOutfitCard(
                          context: context,
                          firestoreService: firestoreService,
                          outfit: outfit,
                          selectedClothes: selectedClothes,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildOutfitCard({
    required BuildContext context,
    required FirestoreService firestoreService,
    required SavedOutfit outfit,
    required List<ClothingItem> selectedClothes,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  child: Center(
                    child: Text(
                      "${outfit.outfitScore}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kaydedilmiş Kombin",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(outfit.createdAt),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Kombini sil",
                  onPressed: () {
                    _confirmDelete(
                      context: context,
                      firestoreService: firestoreService,
                      outfit: outfit,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              outfit.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 14),

            if (selectedClothes.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Bu kombindeki bazı kıyafetler silinmiş veya bulunamıyor.",
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 145,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedClothes.length,
                  separatorBuilder: (_, __) {
                    return const SizedBox(width: 10);
                  },
                  itemBuilder: (context, index) {
                    final item = selectedClothes[index];

                    return _buildClothingPreview(context, item);
                  },
                ),
              ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.checkroom_outlined, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    "${selectedClothes.length} kıyafet",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  "${outfit.outfitScore} / 100",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: outfit.clothingIds.isEmpty
                    ? null
                    : () {
                        _addOutfitToPlanner(
                          context: context,
                          firestoreService: firestoreService,
                          outfit: outfit,
                        );
                      },
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text(
                  "Planlayıcıya Ekle",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClothingPreview(BuildContext context, ClothingItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClothingDetailScreen(clothing: item),
          ),
        );
      },
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: item.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.3,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.broken_image_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      )
                    : Icon(
                        Icons.checkroom_rounded,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              item.color,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addOutfitToPlanner({
    required BuildContext context,
    required FirestoreService firestoreService,
    required SavedOutfit outfit,
  }) async {
    final user = AuthService().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Planlayıcıya eklemek için oturum açmalısın."),
        ),
      );
      return;
    }

    final DateTime? selectedDay = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Kombin gününü seç",
      cancelText: "Vazgeç",
      confirmText: "Seç",
    );

    if (selectedDay == null) {
      return;
    }

    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    final String dayKey =
        "${normalizedDay.year.toString().padLeft(4, '0')}-"
        "${normalizedDay.month.toString().padLeft(2, '0')}-"
        "${normalizedDay.day.toString().padLeft(2, '0')}";

    final plan = OutfitPlan(
      id: "",
      uid: user.uid,
      day: dayKey,
      clothingIds: outfit.clothingIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await firestoreService.saveOutfitPlan(plan);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              "Kombin ${_formatDate(normalizedDay)} tarihine eklendi.",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Text(
              "Kombin planlayıcıya eklenemedi.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    }
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required FirestoreService firestoreService,
    required SavedOutfit outfit,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Kombini Sil"),
          content: const Text(
            "Bu kayıtlı kombini silmek istediğine emin misin?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Vazgeç"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await firestoreService.deleteSavedOutfit(outfit.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            "Kombin silindi.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            "Kombin silinemedi.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 82,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              "Henüz kayıtlı kombin yok",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "AI Stil Asistanı tarafından oluşturulan kombinleri "
              "kaydederek burada görüntüleyebilirsin.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, "0");
    final month = dateTime.month.toString().padLeft(2, "0");
    final year = dateTime.year.toString();

    return "$day.$month.$year";
  }
}
