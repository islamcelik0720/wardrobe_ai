import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'clothing_detail_screen.dart';

class DonationListScreen extends StatefulWidget {
  const DonationListScreen({super.key});

  @override
  State<DonationListScreen> createState() => _DonationListScreenState();
}

class _DonationListScreenState extends State<DonationListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = "all";

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Bağış Listem"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ClothingItem>>(
              stream: _firestoreService.getClothes(user.uid),
              builder: (context, clothesSnapshot) {
                if (clothesSnapshot.hasError) {
                  return Center(
                    child: Text(
                      "Kıyafetler yüklenemedi.\n"
                      "${clothesSnapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (clothesSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clothes = clothesSnapshot.data ?? [];

                final clothesById = {for (final item in clothes) item.id: item};

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getDonationItems(user.uid),
                  builder: (context, donationSnapshot) {
                    if (donationSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            "Bağış listesi yüklenemedi.\n"
                            "${donationSnapshot.error}",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (donationSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allItems = donationSnapshot.data ?? [];

                    final filteredItems = allItems.where((item) {
                      final status = item["status"]?.toString() ?? "planned";

                      if (_selectedFilter == "planned") {
                        return status == "planned";
                      }

                      if (_selectedFilter == "donated") {
                        return status == "donated";
                      }

                      return true;
                    }).toList();

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(label: "Tümü", value: "all"),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "Bağış Bekliyor",
                                  value: "planned",
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: "Bağışlandı",
                                  value: "donated",
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: filteredItems.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    100,
                                  ),
                                  itemCount: filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final donationItem = filteredItems[index];

                                    final clothingId =
                                        donationItem["clothingId"]
                                            ?.toString() ??
                                        "";

                                    final clothing = clothesById[clothingId];

                                    final status =
                                        donationItem["status"]?.toString() ??
                                        "planned";

                                    final isDonated = status == "donated";

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: clothing == null
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ClothingDetailScreen(
                                                          clothing: clothing,
                                                        ),
                                                  ),
                                                );
                                              },
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 70,
                                                    height: 70,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      child:
                                                          (donationItem["imageUrl"]
                                                                  ?.toString()
                                                                  .trim()
                                                                  .isNotEmpty ??
                                                              false)
                                                          ? Image.network(
                                                              donationItem["imageUrl"]
                                                                  .toString(),
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    error,
                                                                    stackTrace,
                                                                  ) {
                                                                    return const Icon(
                                                                      Icons
                                                                          .broken_image_outlined,
                                                                    );
                                                                  },
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .checkroom_rounded,
                                                            ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 14),

                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          donationItem["category"]
                                                                  ?.toString() ??
                                                              "Kıyafet",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          donationItem["color"]
                                                                  ?.toString() ??
                                                              "",
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          isDonated
                                                              ? "Bağışlandı"
                                                              : "Bağış bekliyor",
                                                          style: TextStyle(
                                                            color: isDonated
                                                                ? Colors.green
                                                                : Colors.orange,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  if (clothing != null)
                                                    const Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                    ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              if (!isDonated)
                                                SizedBox(
                                                  height: 46,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final shouldComplete = await showDialog<bool>(
                                                        context: context,
                                                        builder: (dialogContext) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    18,
                                                                  ),
                                                            ),
                                                            title: const Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .volunteer_activism_outlined,
                                                                  color: Color(
                                                                    0xFF6A11CB,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    "Bağış Tamamlansın mı?",
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            content: const Text(
                                                              "Bu kıyafeti bağışlandı olarak onayladığında "
                                                              "ürün gardırobundan ve bağış listesinden tamamen silinecek.\n\n"
                                                              "Bu işlem geri alınamaz. Devam etmek istiyor musun?",
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                    dialogContext,
                                                                    false,
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      "Vazgeç",
                                                                    ),
                                                              ),
                                                              ElevatedButton.icon(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red
                                                                          .shade600,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                    dialogContext,
                                                                    true,
                                                                  );
                                                                },
                                                                icon: const Icon(
                                                                  Icons
                                                                      .check_circle_outline,
                                                                ),
                                                                label: const Text(
                                                                  "Evet, Bağışlandı",
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );

                                                      if (shouldComplete !=
                                                          true) {
                                                        return;
                                                      }

                                                      try {
                                                        await _firestoreService
                                                            .markDonationAsCompleted(
                                                              clothingId,
                                                            );

                                                        if (!context.mounted) {
                                                          return;
                                                        }

                                                        ScaffoldMessenger.of(
                                                            context,
                                                          )
                                                          ..hideCurrentSnackBar()
                                                          ..showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "Kıyafet bağışlandı ve gardıroptan kaldırıldı.",
                                                              ),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                      } catch (e) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }

                                                        ScaffoldMessenger.of(
                                                            context,
                                                          )
                                                          ..hideCurrentSnackBar()
                                                          ..showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                "Bağış işlemi tamamlanamadı.",
                                                              ),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                    ),
                                                    label: const Text(
                                                      "Bağışlandı Olarak İşaretle",
                                                    ),
                                                  ),
                                                ),

                                              if (!isDonated)
                                                const SizedBox(height: 8),

                                              SizedBox(
                                                height: 44,
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    _confirmRemove(clothingId);
                                                  },
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                  label: const Text(
                                                    "Listeden Çıkar",
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final selected = _selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    String message = "Bağış listen henüz boş.";

    if (_selectedFilter == "planned") {
      message = "Bağış bekleyen kıyafet bulunmuyor.";
    }

    if (_selectedFilter == "donated") {
      message = "Henüz bağışlandı olarak işaretlenen kıyafet yok.";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 78,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(String clothingId) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Bağış Listesinden Çıkar"),
          content: const Text(
            "Bu kıyafeti bağış listesinden çıkarmak "
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
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Çıkar"),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) {
      return;
    }

    try {
      await _firestoreService.removeFromDonationList(clothingId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Kıyafet bağış listesinden çıkarıldı."),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Kıyafet listeden çıkarılamadı."),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
