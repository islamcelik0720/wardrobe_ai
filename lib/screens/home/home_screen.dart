import 'package:flutter/material.dart';

import '../wardrobe/wardrobe_statistics_screen.dart';
import '../../models/clothing_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../wardrobe/add_clothing_screen.dart';
import '../wardrobe/clothing_detail_screen.dart';
import '../planner/outfit_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String? _selectedCategoryFilter;
  String? _selectedColorFilter;
  String? _selectedSeasonFilter;
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeText(String value) {
    return value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();
  }

  bool _matchesSearch(ClothingItem item) {
    final query = _normalizeText(_searchQuery);

    if (query.isEmpty) {
      return true;
    }

    final searchableText = _normalizeText(
      [
        item.category,
        item.color,
        item.fabric,
        item.season,
        item.brand ?? '',
        item.notes ?? '',
      ].join(' '),
    );

    return searchableText.contains(query);
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

  Future<void> _showFilterSheet() async {
    String? tempCategory = _selectedCategoryFilter;
    String? tempColor = _selectedColorFilter;
    String? tempSeason = _selectedSeasonFilter;
    bool tempFavoritesOnly = _showFavoritesOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                        Icon(Icons.tune, color: Color(0xFF6A11CB)),
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
                        DropdownMenuItem(value: "Ceket", child: Text("Ceket")),
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
                        DropdownMenuItem(value: "Siyah", child: Text("Siyah")),
                        DropdownMenuItem(value: "Beyaz", child: Text("Beyaz")),
                        DropdownMenuItem(value: "Mavi", child: Text("Mavi")),
                        DropdownMenuItem(
                          value: "Kırmızı",
                          child: Text("Kırmızı"),
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
                      secondary: const Icon(Icons.star, color: Colors.amber),
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
        title: const Text('WardrobeAI'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: "Kombin Planlayıcı",
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OutfitPlannerScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Gardırop İstatistikleri',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WardrobeStatisticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Kullanıcı oturumu bulunamadı.'))
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
                      hintText: 'Kıyafet ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Aramayı temizle',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _searchQuery = '';
                                });

                                FocusScope.of(context).unfocus();
                              },
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
                      icon: const Icon(Icons.tune),
                      label: const Text("Filtrele"),
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
                              'Kıyafetler yüklenemedi.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allClothes = snapshot.data ?? [];

                      if (allClothes.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz kıyafet eklenmedi.',
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      final filteredClothes = allClothes.where((item) {
                        return _matchesSearch(item) && _matchesFilters(item);
                      }).toList();

                      if (filteredClothes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 70,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '"$_searchQuery" aramasıyla eşleşen '
                                  'kıyafet bulunamadı.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: filteredClothes.length,
                        itemBuilder: (context, index) {
                          final item = filteredClothes[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ClothingDetailScreen(clothing: item),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 6,
                              shadowColor: Colors.black26,
                              margin: const EdgeInsets.only(bottom: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.checkroom,
                                            size: 38,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.category,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(item.color),
                                              Text(item.fabric),
                                              Text(item.season),
                                              if (item.brand
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.brand!,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (item.favorite)
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 28,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.repeat,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.timesUsed} kez kullanıldı',
                                          style: const TextStyle(
                                            color: Colors.grey,
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
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClothingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
