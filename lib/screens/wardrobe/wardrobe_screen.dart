import 'package:flutter/material.dart';

import 'add_clothing_screen.dart';
import '../outfits/saved_outfits_screen.dart';
import 'clothing_detail_screen.dart';

import '../../models/clothing_item.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  String? _selectedCategoryFilter;
  String? _selectedColorFilter;
  String? _selectedSeasonFilter;
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(ClothingItem item) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    return item.category.toLowerCase().contains(query) ||
        item.color.toLowerCase().contains(query) ||
        item.fabric.toLowerCase().contains(query) ||
        item.season.toLowerCase().contains(query) ||
        (item.brand?.toLowerCase().contains(query) ?? false) ||
        (item.notes?.toLowerCase().contains(query) ?? false);
  }

  bool _matchesFilters(ClothingItem item) {
    final matchesCategory =
        _selectedCategoryFilter == null ||
        item.category == _selectedCategoryFilter;

    final matchesColor =
        _selectedColorFilter == null || item.color == _selectedColorFilter;

    final matchesSeason =
        _selectedSeasonFilter == null || item.season == _selectedSeasonFilter;

    final matchesFavorite = !_showFavoritesOnly || item.favorite;

    return matchesCategory && matchesColor && matchesSeason && matchesFavorite;
  }

  bool get _hasActiveFilters {
    return _selectedCategoryFilter != null ||
        _selectedColorFilter != null ||
        _selectedSeasonFilter != null ||
        _showFavoritesOnly;
  }

  Future<void> _showFilterSheet() async {
    String? tempCategory = _selectedCategoryFilter;
    String? tempColor = _selectedColorFilter;
    String? tempSeason = _selectedSeasonFilter;
    bool tempFavoritesOnly = _showFavoritesOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFF6A11CB)),
                          SizedBox(width: 10),
                          Text(
                            "Kıyafetleri Filtrele",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        initialValue: tempCategory,
                        decoration: const InputDecoration(
                          labelText: "Kategori",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Pantolon",
                            child: Text("Pantolon"),
                          ),
                          DropdownMenuItem(
                            value: "Tişört",
                            child: Text("Tişört"),
                          ),
                          DropdownMenuItem(
                            value: "Gömlek",
                            child: Text("Gömlek"),
                          ),
                          DropdownMenuItem(
                            value: "Kazak",
                            child: Text("Kazak"),
                          ),
                          DropdownMenuItem(
                            value: "Sweatshirt",
                            child: Text("Sweatshirt"),
                          ),
                          DropdownMenuItem(
                            value: "Ceket",
                            child: Text("Ceket"),
                          ),
                          DropdownMenuItem(value: "Mont", child: Text("Mont")),
                          DropdownMenuItem(value: "Şort", child: Text("Şort")),
                          DropdownMenuItem(value: "Etek", child: Text("Etek")),
                          DropdownMenuItem(
                            value: "Elbise",
                            child: Text("Elbise"),
                          ),
                          DropdownMenuItem(
                            value: "Ayakkabı",
                            child: Text("Ayakkabı"),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            tempCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: tempColor,
                        decoration: const InputDecoration(
                          labelText: "Renk",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Siyah",
                            child: Text("Siyah"),
                          ),
                          DropdownMenuItem(
                            value: "Beyaz",
                            child: Text("Beyaz"),
                          ),
                          DropdownMenuItem(value: "Krem", child: Text("Krem")),
                          DropdownMenuItem(value: "Bej", child: Text("Bej")),
                          DropdownMenuItem(value: "Gri", child: Text("Gri")),
                          DropdownMenuItem(value: "Mavi", child: Text("Mavi")),
                          DropdownMenuItem(
                            value: "Lacivert",
                            child: Text("Lacivert"),
                          ),
                          DropdownMenuItem(
                            value: "Yeşil",
                            child: Text("Yeşil"),
                          ),
                          DropdownMenuItem(
                            value: "Kırmızı",
                            child: Text("Kırmızı"),
                          ),
                          DropdownMenuItem(
                            value: "Pembe",
                            child: Text("Pembe"),
                          ),
                          DropdownMenuItem(value: "Mor", child: Text("Mor")),
                          DropdownMenuItem(value: "Sarı", child: Text("Sarı")),
                          DropdownMenuItem(
                            value: "Kahverengi",
                            child: Text("Kahverengi"),
                          ),
                          DropdownMenuItem(
                            value: "Turuncu",
                            child: Text("Turuncu"),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            tempColor = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: tempSeason,
                        decoration: const InputDecoration(
                          labelText: "Mevsim",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "İlkbahar",
                            child: Text("İlkbahar"),
                          ),
                          DropdownMenuItem(value: "Yaz", child: Text("Yaz")),
                          DropdownMenuItem(
                            value: "Sonbahar",
                            child: Text("Sonbahar"),
                          ),
                          DropdownMenuItem(value: "Kış", child: Text("Kış")),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            tempSeason = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Sadece favorileri göster"),
                        secondary: const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                        ),
                        value: tempFavoritesOnly,
                        onChanged: (value) {
                          setModalState(() {
                            tempFavoritesOnly = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempCategory = null;
                                  tempColor = null;
                                  tempSeason = null;
                                  tempFavoritesOnly = false;
                                });
                              },
                              child: const Text("Temizle"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategoryFilter = tempCategory;
                                  _selectedColorFilter = tempColor;
                                  _selectedSeasonFilter = tempSeason;
                                  _showFavoritesOnly = tempFavoritesOnly;
                                });

                                Navigator.pop(sheetContext);
                              },
                              child: const Text("Uygula"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gardırobum"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Kombinlerim",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedOutfitsScreen()),
              );
            },
            icon: const Icon(Icons.favorite_rounded),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Kıyafet ara...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: "Aramayı temizle",
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = "";
                                });

                                FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF6A11CB),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: Icon(
                        _hasActiveFilters
                            ? Icons.filter_alt_rounded
                            : Icons.tune_rounded,
                      ),
                      label: Text(
                        _hasActiveFilters ? "Filtreler Uygulandı" : "Filtrele",
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ClothingItem>>(
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

                      final allClothes = snapshot.data ?? [];

                      final filteredClothes = allClothes.where((item) {
                        return _matchesSearch(item) && _matchesFilters(item);
                      }).toList();

                      if (allClothes.isEmpty) {
                        return _buildEmptyWardrobe(context);
                      }

                      if (filteredClothes.isEmpty) {
                        return _buildEmptySearch(context);
                      }

                      return ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filteredClothes.length,
                        itemBuilder: (context, index) {
                          final item = filteredClothes[index];

                          return _buildClothingCard(context, item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClothingScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Kıyafet Ekle"),
      ),
    );
  }

  Widget _buildClothingCard(BuildContext context, ClothingItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClothingDetailScreen(clothing: item),
          ),
        );
      },
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 92,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          },
                        )
                      : Icon(
                          Icons.checkroom_rounded,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (item.favorite)
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 26,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text("${item.color} • ${item.fabric}"),
                    const SizedBox(height: 4),
                    Text(
                      item.season,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.brand?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.brand!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${item.timesUsed} kez kullanıldı",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWardrobe(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 82,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              "Gardırobun henüz boş",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "İlk kıyafetini ekleyerek kişisel gardırobunu oluşturmaya başla.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClothingScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("İlk Kıyafetimi Ekle"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 76,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              "Eşleşen kıyafet bulunamadı",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Arama metnini veya filtrelerini değiştirerek tekrar deneyebilirsin.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
