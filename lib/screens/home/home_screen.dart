import 'package:flutter/material.dart';
import 'dart:async';

import '../wardrobe/add_clothing_screen.dart';
import '../wardrobe/clothing_detail_screen.dart';

import '../../widgets/ai_wardrobe_card.dart';
import '../../widgets/ai_outfit_result_sheet.dart';

import '../../models/clothing_item.dart';
import '../../models/ai_outfit_result.dart';
import '../../models/outfit_plan.dart';
import '../../models/weather_info.dart';

import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';

import '../mannequin/mannequin_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  final TextEditingController _searchController = TextEditingController();

  bool _isWardrobeAiLoading = false;

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

  String _getFriendlyAiErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (error is TimeoutException ||
        message.contains('timeout') ||
        message.contains('zamanında yanıt vermedi')) {
      return "AI yanıtı beklenenden uzun sürdü. "
          "İnternet bağlantını kontrol edip tekrar dene.";
    }

    if (message.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('resource_exhausted') ||
        message.contains('429')) {
      return "Ücretsiz AI kullanım sınırına ulaşıldı. "
          "Bir süre bekledikten sonra tekrar deneyebilirsin.";
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection')) {
      return "İnternet bağlantısı kurulamadı. "
          "Bağlantını kontrol edip tekrar dene.";
    }

    if (message.contains('api key') ||
        message.contains('unauthorized') ||
        message.contains('permission') ||
        message.contains('401') ||
        message.contains('403')) {
      return "AI servisine erişim sağlanamadı. "
          "API anahtarı veya servis ayarları kontrol edilmeli.";
    }

    if (message.contains('404') ||
        message.contains('model') && message.contains('not found')) {
      return "Kullanılan AI modeli şu anda erişilebilir değil.";
    }

    return "AI kombini şu anda oluşturulamadı. "
        "Lütfen kısa bir süre sonra tekrar dene.";
  }

  Future<String?> _selectOutfitOccasion() async {
    const occasions = ["Günlük", "Okul", "İş", "Spor", "Şık / Davet"];

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF6A11CB),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Kombin Amacını Seç",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  "Gemini seçtiğin ortama uygun parçaları belirleyecek.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 18),

                ...occasions.map((occasion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        _getOccasionIcon(occasion),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        occasion,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext, occasion);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getOccasionIcon(String occasion) {
    switch (occasion) {
      case "Okul":
        return Icons.school_outlined;
      case "İş":
        return Icons.work_outline;
      case "Spor":
        return Icons.fitness_center;
      case "Şık / Davet":
        return Icons.celebration_outlined;
      case "Günlük":
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Future<void> _generateWardrobeOutfit(List<ClothingItem> clothes) async {
    if (_isWardrobeAiLoading) return;

    if (clothes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Kombin oluşturmak için önce kıyafet eklemelisin.",
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

    final String? selectedOccasion = await _selectOutfitOccasion();

    if (selectedOccasion == null) {
      return;
    }

    setState(() {
      _isWardrobeAiLoading = true;
    });

    try {
      final WeatherInfo? weather = await _getWeatherForAi();

      final AiOutfitResult result = await _geminiService
          .generateStructuredWardrobeOutfit(
            clothes,
            occasion: selectedOccasion,
            weather: weather,
          );

      final List<ClothingItem> selectedClothes = clothes.where((item) {
        return result.selectedClothingIds.contains(item.id);
      }).toList();

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return AiOutfitResultSheet(
            suggestion: result.suggestion,
            occasion: selectedOccasion,
            selectedClothes: selectedClothes,
            onPreviewOnMannequin: () {
              Navigator.pop(sheetContext);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MannequinPreviewScreen(selectedClothes: selectedClothes),
                ),
              );
            },
            onAddToPlanner: () {
              Navigator.pop(sheetContext);

              Future.microtask(() {
                _addAiOutfitToPlanner(selectedClothes);
              });
            },

            onRegenerate: () {
              Navigator.pop(sheetContext);

              Future.microtask(() {
                _generateWardrobeOutfit(clothes);
              });
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 7),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI kombini oluşturulamadı.\n$e",
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
    } finally {
      if (mounted) {
        setState(() {
          _isWardrobeAiLoading = false;
        });
      }
    }
  }

  Future<void> _addAiOutfitToPlanner(List<ClothingItem> selectedClothes) async {
    if (selectedClothes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Planlayıcıya aktarılabilecek kıyafet bulunamadı.",
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

    const days = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];

    final String? selectedDay = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 46,
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
                    Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF6A11CB),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Kombin Gününü Seç",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  "${selectedClothes.length} kıyafet seçilen güne kaydedilecek.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 18),

                ...days.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 21,
                        ),
                      ),
                      title: Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext, day);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedDay == null || !mounted) return;

    final user = AuthService().currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")),
      );
      return;
    }

    try {
      final now = DateTime.now();

      final plan = OutfitPlan(
        id: "",
        uid: user.uid,
        day: selectedDay,
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
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "$selectedDay kombini başarıyla planlayıcıya kaydedildi.",
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI kombini planlayıcıya kaydedilemedi.",
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
    }
  }

  void _showAiSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<WeatherInfo?> _getWeatherForAi() async {
    try {
      final position = await _locationService.getCurrentPosition().timeout(
        const Duration(seconds: 20),
      );

      return await _weatherService
          .getCurrentWeather(
            latitude: position.latitude,
            longitude: position.longitude,
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: const Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Hava durumu alınamadı. Kombin hava bilgisi olmadan hazırlanacak.",
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

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 95,
        titleSpacing: 20,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: user == null
                ? Future.value(null)
                : _firestoreService.getUserData(user.uid),
            builder: (context, snapshot) {
              final userData = snapshot.data;

              final String fullName =
                  userData?["fullName"]?.toString().trim().isNotEmpty == true
                  ? userData!["fullName"].toString()
                  : "WardrobeAI Kullanıcısı";

              final String firstName = fullName.split(" ").first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "👋 Hoş geldin,",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    firstName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
                        itemCount: filteredClothes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return AiWardrobeCard(
                              clothes: allClothes,
                              isLoading: _isWardrobeAiLoading,
                              onGenerate: _generateWardrobeOutfit,
                            );
                          }

                          final item = filteredClothes[index - 1];

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
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child:
                                                item.imageUrl.trim().isNotEmpty
                                                ? Image.network(
                                                    item.imageUrl,
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder:
                                                        (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child;
                                                          }

                                                          return const Center(
                                                            child: SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2.5,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            size: 34,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          );
                                                        },
                                                  )
                                                : Icon(
                                                    Icons.checkroom,
                                                    size: 38,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
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
