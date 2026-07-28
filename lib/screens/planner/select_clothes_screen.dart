import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SelectClothesScreen extends StatefulWidget {
  final String day;

  const SelectClothesScreen({super.key, required this.day});

  @override
  State<SelectClothesScreen> createState() => _SelectClothesScreenState();
}

class _SelectClothesScreenState extends State<SelectClothesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final Set<String> _selectedIds = {};

  String _getCategoryGroup(String category) {
    switch (category) {
      case "Tişört":
      case "Gömlek":
        return "Üst Giyim";

      case "Pantolon":
        return "Alt Giyim";

      case "Ceket":
        return "Dış Giyim";

      case "Ayakkabı":
        return "Ayakkabı";

      default:
        return category;
    }
  }

  void _toggleSelection(
    ClothingItem selectedItem,
    List<ClothingItem> allClothes,
  ) {
    setState(() {
      if (_selectedIds.contains(selectedItem.id)) {
        _selectedIds.remove(selectedItem.id);
        return;
      }

      final selectedGroup = _getCategoryGroup(selectedItem.category);

      final sameGroupItems = allClothes.where((item) {
        return _getCategoryGroup(item.category) == selectedGroup;
      });

      for (final item in sameGroupItems) {
        _selectedIds.remove(item.id);
      }

      _selectedIds.add(selectedItem.id);
    });
  }

  void _completeSelection(List<ClothingItem> clothes) {
    final selectedClothes = clothes
        .where((item) => _selectedIds.contains(item.id))
        .toList();

    if (selectedClothes.isEmpty) {
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
                  "Lütfen en az bir kıyafet seçiniz.",
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
      return;
    }

    Navigator.pop(context, selectedClothes);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.day} Kombini"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ClothingItem>>(
              stream: _firestoreService.getClothes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Kıyafetler yüklenemedi.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clothes = snapshot.data ?? [];

                if (clothes.isEmpty) {
                  return const Center(
                    child: Text(
                      "Kombin oluşturmak için önce kıyafet eklemelisin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: clothes.length,
                        itemBuilder: (context, index) {
                          final item = clothes[index];
                          final isSelected = _selectedIds.contains(item.id);

                          return Card(
                            elevation: isSelected ? 6 : 3,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF6A11CB)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                _toggleSelection(item, clothes);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(
                                        Icons.checkroom,
                                        color: Color(0xFF6A11CB),
                                        size: 34,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.category,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${item.color} • ${item.fabric} • ${item.season}",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          if (item.brand?.trim().isNotEmpty ==
                                              true) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item.brand!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        key: ValueKey(isSelected),
                                        color: isSelected
                                            ? const Color(0xFF6A11CB)
                                            : Colors.grey,
                                        size: 30,
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
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _completeSelection(clothes);
                            },
                            icon: const Icon(Icons.check),
                            label: Text(
                              _selectedIds.isEmpty
                                  ? "Kombini Tamamla"
                                  : "${_selectedIds.length} Kıyafet Seçildi",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
