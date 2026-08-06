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
import '../../models/wardrobe_analysis.dart';

import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../services/wardrobe_analysis_service.dart';

import '../analysis/wardrobe_analysis_screen.dart';

import '../style_assistant/style_assistant_screen.dart';

import '../mannequin/mannequin_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenWardrobe;

  const HomeScreen({super.key, this.onOpenWardrobe});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final WardrobeAnalysisService _wardrobeAnalysisService =
      WardrobeAnalysisService();

  bool _isWardrobeAiLoading = false;

  String _normalizeText(String value) {
    return value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().trim();
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

  Widget _buildWardrobeAnalysisCard(
    BuildContext context,
    WardrobeAnalysis analysis,
  ) {
    final Color scoreColor;

    if (analysis.wardrobeScore >= 85) {
      scoreColor = Colors.green;
    } else if (analysis.wardrobeScore >= 70) {
      scoreColor = Colors.blue;
    } else if (analysis.wardrobeScore >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Dolap Analizi",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome, color: Colors.white70),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${analysis.wardrobeScore}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "/ 100",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.scoreLabel,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${analysis.totalClothes} kıyafet • "
                      "${analysis.unusedClothesCount} kullanılmamış",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "En sık renk: ${analysis.mostCommonColor}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (analysis.strengths.isNotEmpty)
            _buildAnalysisMessage(
              icon: Icons.check_circle_outline,
              text: analysis.strengths.first,
            ),

          if (analysis.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildAnalysisMessage(
              icon: Icons.warning_amber_rounded,
              text: analysis.warnings.first,
            ),
          ],

          if (analysis.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildAnalysisMessage(
              icon: Icons.lightbulb_outline_rounded,
              text: analysis.recommendations.first,
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A11CB),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WardrobeAnalysisScreen(analysis: analysis),
                  ),
                );
              },
              icon: const Icon(Icons.insights_outlined),
              label: const Text(
                "Detaylı Analizi Gör",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisMessage({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAssistantCard(
    BuildContext context,
    List<ClothingItem> clothes,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
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
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Stil Asistanı",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Etkinliğini yaz, gardırobundan uygun kombin bul.",
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StyleAssistantScreen(clothes: clothes),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                "Stil Asistanını Aç",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
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

                      final WardrobeAnalysis wardrobeAnalysis =
                          _wardrobeAnalysisService.analyze(allClothes);

                      if (allClothes.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz kıyafet eklenmedi.',
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }

                      final recentClothes = allClothes.take(3).toList();

                      return ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        children: [
                          _buildWardrobeAnalysisCard(context, wardrobeAnalysis),

                          const SizedBox(height: 4),

                          AiWardrobeCard(
                            clothes: allClothes,
                            isLoading: _isWardrobeAiLoading,
                            onGenerate: _generateWardrobeOutfit,
                          ),

                          const SizedBox(height: 14),

                          _buildStyleAssistantCard(context, allClothes),

                          const SizedBox(height: 22),

                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Son Eklenen Kıyafetler",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: widget.onOpenWardrobe,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text("Tümünü Gör"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          ...recentClothes.map((item) {
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
                                elevation: 5,
                                margin: const EdgeInsets.only(bottom: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 82,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: item.imageUrl.trim().isNotEmpty
                                              ? Image.network(
                                                  item.imageUrl,
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
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        );
                                                      },
                                                )
                                              : Icon(
                                                  Icons.checkroom_rounded,
                                                  size: 38,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
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
                                            const SizedBox(height: 6),
                                            Text(
                                              "${item.color} • ${item.fabric}",
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.season,
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.favorite)
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                        ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
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
