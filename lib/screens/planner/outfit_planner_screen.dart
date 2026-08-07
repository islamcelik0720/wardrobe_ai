import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../models/outfit_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'select_clothes_screen.dart';

class OutfitPlannerScreen extends StatefulWidget {
  const OutfitPlannerScreen({super.key});

  @override
  State<OutfitPlannerScreen> createState() => _OutfitPlannerScreenState();
}

class _OutfitPlannerScreenState extends State<OutfitPlannerScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final Set<String> _savingDays = {};
  final Set<String> _deletingDays = {};
  final Set<String> _wearingDays = {};

  final List<String> days = const [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

  /// Firestore'daki day alanı:
  /// - "Pazartesi" gibi bir gün adı olabilir.
  /// - "2026-08-06" gibi bir tarih olabilir.
  ///
  /// Bu metot her iki formatı da planlayıcının kullandığı
  /// Türkçe gün adına dönüştürür.
  String _normalizePlanDay(String dayValue) {
    final trimmedValue = dayValue.trim();

    if (days.contains(trimmedValue)) {
      return trimmedValue;
    }

    final parsedDate = DateTime.tryParse(trimmedValue);

    if (parsedDate != null) {
      return _getTurkishDayName(parsedDate);
    }

    return trimmedValue;
  }

  String _getTurkishDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return "Pazartesi";
      case DateTime.tuesday:
        return "Salı";
      case DateTime.wednesday:
        return "Çarşamba";
      case DateTime.thursday:
        return "Perşembe";
      case DateTime.friday:
        return "Cuma";
      case DateTime.saturday:
        return "Cumartesi";
      case DateTime.sunday:
        return "Pazar";
      default:
        return "";
    }
  }

  Future<void> _selectAndSaveOutfit({
    required String day,
    required String uid,
  }) async {
    final selectedClothes = await Navigator.push<List<ClothingItem>>(
      context,
      MaterialPageRoute(builder: (_) => SelectClothesScreen(day: day)),
    );

    if (selectedClothes == null || selectedClothes.isEmpty) {
      return;
    }

    setState(() {
      _savingDays.add(day);
    });

    try {
      final now = DateTime.now();

      final plan = OutfitPlan(
        id: "",
        uid: uid,
        day: day,
        clothingIds: selectedClothes.map((item) => item.id).toList(),
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.saveOutfitPlan(plan);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "$day kombini başarıyla kaydedildi.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin planı kaydedilemedi.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingDays.remove(day);
        });
      }
    }
  }

  Future<void> _markPlanAsWorn({
    required String day,
    required OutfitPlan plan,
  }) async {
    if (plan.isWorn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu kombin zaten giyildi olarak işaretlenmiş."),
        ),
      );
      return;
    }
    if (_wearingDays.contains(day)) {
      return;
    }

    if (plan.clothingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu planda kullanılacak kıyafet bulunmuyor."),
        ),
      );
      return;
    }

    setState(() {
      _wearingDays.add(day);
    });

    try {
      await _firestoreService.incrementUsageForClothes(plan.clothingIds);
      await _firestoreService.markOutfitPlanAsWorn(plan.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin bugün giyildi olarak kaydedildi.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

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
              "Kullanım bilgisi güncellenemedi.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _wearingDays.remove(day);
        });
      }
    }
  }

  Future<void> _deletePlan(OutfitPlan plan) async {
    final displayedDay = _normalizePlanDay(plan.day);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 10),
              Text("Kombini Sil"),
            ],
          ),
          content: Text(
            "$displayedDay günü için oluşturulan kombini "
            "silmek istediğine emin misin?",
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

    setState(() {
      _deletingDays.add(displayedDay);
    });

    try {
      await _firestoreService.deleteOutfitPlan(plan.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin planı silindi.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kombin planı silinemedi.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _deletingDays.remove(displayedDay);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Kombin Planlayıcı"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ClothingItem>>(
              stream: _firestoreService.getClothes(user.uid),
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

                return StreamBuilder<List<OutfitPlan>>(
                  stream: _firestoreService.getOutfitPlans(user.uid),
                  builder: (context, plansSnapshot) {
                    if (plansSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Kombin planları yüklenemedi.\n"
                            "${plansSnapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (plansSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final plans = plansSnapshot.data ?? [];

                    /*
                     Firestore'dan gelen planları haftanın
                     Türkçe günlerine göre eşleştiriyoruz.

                     day değeri:
                     - "Pazartesi"
                     - "2026-08-06"

                     biçimlerinden biri olabilir.
                    */
                    final Map<String, OutfitPlan> plansByDay = {};

                    for (final plan in plans) {
                      final normalizedDay = _normalizePlanDay(plan.day);

                      if (!days.contains(normalizedDay)) {
                        continue;
                      }

                      final existingPlan = plansByDay[normalizedDay];

                      /*
                       Aynı güne denk gelen birden fazla
                       belge varsa en son güncelleneni göster.
                      */
                      if (existingPlan == null ||
                          plan.updatedAt.isAfter(existingPlan.updatedAt)) {
                        plansByDay[normalizedDay] = plan;
                      }
                    }

                    final Map<String, ClothingItem> clothesById = {
                      for (final item in clothes) item.id: item,
                    };

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final plan = plansByDay[day];

                        final plannedClothes = plan == null
                            ? <ClothingItem>[]
                            : plan.clothingIds
                                  .map((id) => clothesById[id])
                                  .whereType<ClothingItem>()
                                  .toList();

                        final isSaving = _savingDays.contains(day);
                        final isDeleting = _deletingDays.contains(day);
                        final isWearing = _wearingDays.contains(day);

                        final isBusy = isSaving || isDeleting || isWearing;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (plan != null)
                                      IconButton(
                                        tooltip: "Kombini sil",
                                        onPressed: isBusy
                                            ? null
                                            : () {
                                                _deletePlan(plan);
                                              },
                                        icon: isDeleting
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                if (plannedClothes.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.checkroom_outlined,
                                          size: 42,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Henüz kombin planlanmadı.",
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    children: plannedClothes.map((item) {
                                      return Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 54,
                                              height: 54,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child:
                                                    item.imageUrl
                                                        .trim()
                                                        .isNotEmpty
                                                    ? Image.network(
                                                        item.imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Icon(
                                                                Icons
                                                                    .broken_image_outlined,
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.primary,
                                                              );
                                                            },
                                                      )
                                                    : Icon(
                                                        Icons.checkroom,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.category,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    "${item.color} • "
                                                    "${item.fabric}",
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (item.favorite)
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                const SizedBox(height: 14),

                                if (plan != null &&
                                    plannedClothes.isNotEmpty) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: isBusy || plan.isWorn
                                          ? null
                                          : () {
                                              _markPlanAsWorn(
                                                day: day,
                                                plan: plan,
                                              );
                                            },
                                      icon: isWearing
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              plan.isWorn
                                                  ? Icons.check_circle_rounded
                                                  : Icons.checkroom_rounded,
                                            ),
                                      label: Text(
                                        plan.isWorn
                                            ? "Bugün Giyildi"
                                            : isWearing
                                            ? "Kaydediliyor..."
                                            : "Bugün Giydim",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),
                                ],

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            _selectAndSaveOutfit(
                                              day: day,
                                              uid: user.uid,
                                            );
                                          },
                                    icon: isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Icon(
                                            plannedClothes.isEmpty
                                                ? Icons.add
                                                : Icons.edit,
                                          ),
                                    label: Text(
                                      isSaving
                                          ? "Kaydediliyor..."
                                          : plannedClothes.isEmpty
                                          ? "Kombin Oluştur"
                                          : "Kombini Değiştir",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
