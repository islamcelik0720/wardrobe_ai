import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'add_clothing_screen.dart';
import '../../models/clothing_item.dart';
import '../../services/firestore_service.dart';
import '../../services/outfit_suggestion_service.dart';

class ClothingDetailScreen extends StatefulWidget {
  final ClothingItem clothing;

  const ClothingDetailScreen({super.key, required this.clothing});

  @override
  State<ClothingDetailScreen> createState() => _ClothingDetailScreenState();
}

class _ClothingDetailScreenState extends State<ClothingDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  final OutfitSuggestionService _outfitSuggestionService =
      OutfitSuggestionService();

  bool isFavorite = false;
  int _timesUsed = 0;
  bool _isFavoriteUpdating = false;
  bool _isUsageUpdating = false;
  String _outfitSuggestion = "";

  @override
  void initState() {
    super.initState();

    isFavorite = widget.clothing.favorite;
    _timesUsed = widget.clothing.timesUsed;

    _outfitSuggestion = _outfitSuggestionService.generateSuggestion(
      widget.clothing,
    );
  }

  Future<void> _toggleFavorite(bool value) async {
    if (_isFavoriteUpdating) return;

    final previousValue = isFavorite;

    setState(() {
      isFavorite = value;
      _isFavoriteUpdating = true;
    });

    if (value) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.selectionClick();
    }

    try {
      await _firestoreService.toggleFavorite(widget.clothing.id, value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: value ? Colors.amber.shade700 : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(value ? Icons.star : Icons.star_border, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value
                      ? "Kıyafet favorilere eklendi."
                      : "Kıyafet favorilerden çıkarıldı.",
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

      setState(() {
        isFavorite = previousValue;
      });

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
                  "Favori durumu güncellenemedi.",
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
          _isFavoriteUpdating = false;
        });
      }
    }
  }

  Future<void> _incrementUsage() async {
    if (_isUsageUpdating) return;

    setState(() {
      _isUsageUpdating = true;
    });

    try {
      await _firestoreService.incrementUsage(widget.clothing.id);

      if (!mounted) return;

      setState(() {
        _timesUsed++;
      });

      await HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
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
                  "Kullanım sayısı artırıldı.",
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
                  "Kullanım sayısı artırılamadı.",
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
          _isUsageUpdating = false;
        });
      }
    }
  }

  void _generateNewSuggestion() {
    HapticFeedback.selectionClick();

    setState(() {
      _outfitSuggestion = _outfitSuggestionService.generateSuggestion(
        widget.clothing,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF6A11CB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Yeni kombin önerisi oluşturuldu.",
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

  int _calculateStyleScore() {
    int score = 60;

    if (isFavorite) {
      score += 10;
    }

    if (widget.clothing.brand?.trim().isNotEmpty ?? false) {
      score += 5;
    }

    if (widget.clothing.notes?.trim().isNotEmpty ?? false) {
      score += 5;
    }

    if (widget.clothing.color.trim().isNotEmpty) {
      score += 5;
    }

    if (widget.clothing.fabric.trim().isNotEmpty) {
      score += 5;
    }

    if (widget.clothing.season.trim().isNotEmpty) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final int styleScore = _calculateStyleScore();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clothing.category),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddClothingScreen(clothing: widget.clothing),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final bool? result = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Kıyafeti Sil"),
                      ],
                    ),
                    content: const Text(
                      "Bu kıyafeti silmek istediğinize emin misiniz?",
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Vazgeç"),
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Sil"),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ],
                  );
                },
              );

              if (result == true) {
                await _firestoreService.deleteClothing(widget.clothing.id);

                if (context.mounted) {
                  Navigator.pop(context);

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
                          Text(
                            "Kıyafet silindi.",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.checkroom,
                size: 150,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            _buildInfoCard(
              icon: Icons.category,
              title: "Kategori",
              value: widget.clothing.category,
            ),

            _buildInfoCard(
              icon: Icons.palette,
              title: "Renk",
              value: widget.clothing.color,
            ),

            _buildInfoCard(
              icon: Icons.style,
              title: "Kumaş",
              value: widget.clothing.fabric,
            ),

            _buildInfoCard(
              icon: Icons.wb_sunny,
              title: "Mevsim",
              value: widget.clothing.season,
            ),

            _buildInfoCard(
              icon: Icons.sell,
              title: "Marka",
              value: (widget.clothing.brand?.isNotEmpty ?? false)
                  ? widget.clothing.brand!
                  : "Belirtilmedi",
            ),

            _buildInfoCard(
              icon: Icons.note,
              title: "Not",
              value: (widget.clothing.notes?.isNotEmpty ?? false)
                  ? widget.clothing.notes!
                  : "Not bulunmuyor",
            ),

            const SizedBox(height: 16),

            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isFavorite
                    ? Colors.amber.withValues(alpha: 0.12)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFavorite
                      ? Colors.amber.shade400
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFavorite
                        ? Colors.amber.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: isFavorite ? 16 : 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: AnimatedScale(
                  scale: isFavorite ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      key: ValueKey(isFavorite),
                      color: isFavorite ? Colors.amber.shade700 : Colors.grey,
                      size: 34,
                    ),
                  ),
                ),
                title: Text(
                  isFavorite ? "Favorilerde" : "Favorilere Ekle",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isFavorite
                      ? "Bu kıyafet favorilerinde öne çıkarılıyor."
                      : "Bu kıyafeti favorilerinde göster.",
                ),
                trailing: _isFavoriteUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Switch(
                        value: isFavorite,
                        activeThumbColor: Colors.amber,
                        activeTrackColor: Colors.amberAccent,
                        onChanged: _toggleFavorite,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "AI Kombin Skoru",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$styleScore",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 7),
                        child: Text(
                          " / 100",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: styleScore / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    styleScore >= 85
                        ? "Bu kıyafet kombin oluşturmak için oldukça uygun."
                        : styleScore >= 70
                        ? "Bu kıyafet birçok farklı parçayla eşleştirilebilir."
                        : "Daha fazla kıyafet bilgisi ekleyerek önerileri geliştirebilirsin.",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Şimdilik yerel kurallarla hesaplanan demo skorudur.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          color: Color(0xFF6A11CB),
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Kullanım Sayısı",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_timesUsed kez kullanıldı",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isUsageUpdating ? null : _incrementUsage,
                        icon: _isUsageUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.checkroom),
                        label: Text(
                          _isUsageUpdating ? "Kaydediliyor..." : "Bugün Giydim",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6A11CB).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          "Kombin Önerisi",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _outfitSuggestion,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A11CB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF6A11CB),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Bu öneri şimdilik kategori, renk ve mevsim "
                            "bilgilerine göre yerel olarak oluşturuluyor.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6A11CB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _generateNewSuggestion,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Yeni Öneri Oluştur",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.repeat, color: Color(0xFF6A11CB)),
                title: const Text("Kullanım Sayısı"),
                subtitle: Text("${widget.clothing.timesUsed} kez kullanıldı"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF6A11CB)),
          title: Text(title),
          subtitle: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
