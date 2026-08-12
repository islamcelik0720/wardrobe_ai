import 'package:flutter/material.dart';

import '../../models/shopping_list_item.dart';

import '../wardrobe/add_clothing_screen.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedFilter = "all";

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Alışveriş Listem"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ShoppingListItem>>(
              stream: _firestoreService.getShoppingListItems(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Alışveriş listesi yüklenemedi.\n"
                        "${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = snapshot.data ?? [];

                final filteredItems = allItems.where((item) {
                  if (_selectedFilter == "pending") {
                    return !item.completed;
                  }

                  if (_selectedFilter == "completed") {
                    return item.completed;
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
                              label: "Alınacaklar",
                              value: "pending",
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: "Satın Alındı",
                              value: "completed",
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
                                final item = filteredItems[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 54,
                                              height: 54,
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                item.completed
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .shopping_bag_outlined,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: item.completed
                                                          ? TextDecoration
                                                                .lineThrough
                                                          : null,
                                                    ),
                                                  ),

                                                  const SizedBox(height: 5),

                                                  Text(
                                                    "${item.category} • "
                                                    "${item.suggestedColor}",
                                                  ),

                                                  const SizedBox(height: 7),

                                                  Text(
                                                    item.reason,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Chip(
                                              avatar: const Icon(
                                                Icons.priority_high_rounded,
                                                size: 17,
                                              ),
                                              label: Text(
                                                _priorityText(item.priority),
                                              ),
                                            ),

                                            Chip(
                                              avatar: Icon(
                                                item.completed
                                                    ? Icons.check_circle_outline
                                                    : Icons.pending_outlined,
                                                size: 17,
                                              ),
                                              label: Text(
                                                item.completed
                                                    ? "Satın Alındı"
                                                    : "Alınacak",
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        SizedBox(
                                          height: 46,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await _firestoreService
                                                  .markShoppingItemCompleted(
                                                    itemId: item.id,
                                                    completed: !item.completed,
                                                  );
                                            },
                                            icon: Icon(
                                              item.completed
                                                  ? Icons.undo_rounded
                                                  : Icons.check_circle_outline,
                                            ),
                                            label: Text(
                                              item.completed
                                                  ? "Alınacaklara Geri Taşı"
                                                  : "Satın Aldım",
                                            ),
                                          ),
                                        ),

                                        if (item.completed) ...[
                                          const SizedBox(height: 8),

                                          SizedBox(
                                            height: 46,
                                            child: OutlinedButton.icon(
                                              onPressed: () async {
                                                final added =
                                                    await Navigator.push<bool>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            AddClothingScreen(
                                                              initialCategory:
                                                                  item.category,
                                                              initialColor: item
                                                                  .suggestedColor,
                                                            ),
                                                      ),
                                                    );

                                                if (added == true) {
                                                  await _firestoreService
                                                      .removeShoppingListItem(
                                                        item.id,
                                                      );

                                                  if (!context.mounted) {
                                                    return;
                                                  }

                                                  ScaffoldMessenger.of(context)
                                                    ..hideCurrentSnackBar()
                                                    ..showSnackBar(
                                                      const SnackBar(
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: Text(
                                                          "Ürün gardıroba eklendi ve alışveriş listesinden kaldırıldı.",
                                                        ),
                                                      ),
                                                    );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.checkroom_rounded,
                                              ),
                                              label: const Text(
                                                "Gardıroba Ekle",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 8),

                                        SizedBox(
                                          height: 44,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              _confirmDelete(item);
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: const Text("Listeden Sil"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    String message = "Alışveriş listen henüz boş.";

    if (_selectedFilter == "pending") {
      message = "Alınmayı bekleyen ürün bulunmuyor.";
    }

    if (_selectedFilter == "completed") {
      message = "Henüz satın alınan ürün bulunmuyor.";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
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

  String _priorityText(String priority) {
    switch (priority.toLowerCase().trim()) {
      case "high":
        return "Yüksek Öncelik";
      case "medium":
        return "Orta Öncelik";
      default:
        return "Düşük Öncelik";
    }
  }

  Future<void> _confirmDelete(ShoppingListItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text("Listeden Sil"),
          content: Text("${item.title} alışveriş listesinden silinsin mi?"),
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
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _firestoreService.removeShoppingListItem(item.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Ürün alışveriş listesinden silindi."),
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
            behavior: SnackBarBehavior.floating,
            content: Text("Ürün listeden silinemedi."),
          ),
        );
    }
  }
}
