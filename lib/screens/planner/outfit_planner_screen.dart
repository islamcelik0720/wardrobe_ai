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

  final List<String> days = const [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

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

      ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _deletePlan(OutfitPlan plan) async {
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
            "${plan.day} günü için oluşturulan kombini silmek "
            "istediğine emin misin?",
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
      _deletingDays.add(plan.day);
    });

    try {
      await _firestoreService.deleteOutfitPlan(plan.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
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
          _deletingDays.remove(plan.day);
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
                    child: Text(
                      "Kıyafetler yüklenemedi.\n${clothesSnapshot.error}",
                      textAlign: TextAlign.center,
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

                    final Map<String, OutfitPlan> plansByDay = {
                      for (final plan in plans) plan.day: plan,
                    };

                    final Map<String, ClothingItem> clothesById = {
                      for (final item in clothes) item.id: item,
                    };

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                        final isBusy = isSaving || isDeleting;

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

                                plannedClothes.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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
                                            SizedBox(height: 8),
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
                                    : Column(
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.checkroom,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item.category,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
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
