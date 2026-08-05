import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import '../../models/clothing_analysis_result.dart';
import '../../models/clothing_item.dart';

import '../../widgets/clothing_analysis_card.dart';

class AddClothingScreen extends StatefulWidget {
  final ClothingItem? clothing;

  const AddClothingScreen({super.key, this.clothing});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirestoreService _firestoreService = FirestoreService();
  final GeminiService _geminiService = GeminiService();

  final TextEditingController brandController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  File? _selectedImage;

  String? selectedCategory;
  String? selectedColor;
  String? selectedFabric;
  String? selectedSeason;

  bool isFavorite = false;
  bool _isSaving = false;
  bool _isAnalyzingImage = false;

  ClothingAnalysisResult? _analysisResult;
  final Set<String> _editedAiFields = {};

  bool get isEditMode => widget.clothing != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      selectedCategory = widget.clothing!.category;
      selectedColor = widget.clothing!.color;
      selectedFabric = widget.clothing!.fabric;
      selectedSeason = widget.clothing!.season;
      isFavorite = widget.clothing!.favorite;

      brandController.text = widget.clothing!.brand ?? "";
      notesController.text = widget.clothing!.notes ?? "";
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    if (_isSaving) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
                const Text(
                  "Fotoğraf Ekle",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Kıyafet fotoğrafını kamerayla çekebilir "
                  "veya galeriden seçebilirsin.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF6A11CB),
                  ),
                  title: const Text(
                    "Kamerayla Çek",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF6A11CB),
                  ),
                  title: const Text(
                    "Galeriden Seç",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = null;
        _editedAiFields.clear();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          content: const Text(
            "Fotoğraf seçilemedi.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  String _getFriendlyImageAnalysisError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('503') ||
        message.contains('high demand') ||
        message.contains('unavailable') ||
        message.contains('overloaded')) {
      return "AI servisi şu anda yoğun. "
          "Lütfen birkaç saniye sonra tekrar dene.";
    }

    if (message.contains('429') ||
        message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit')) {
      return "AI kullanım sınırına ulaşıldı. "
          "Bir süre bekledikten sonra tekrar deneyebilirsin.";
    }

    if (message.contains('timeout') || message.contains('timed out')) {
      return "Fotoğraf analizi beklenenden uzun sürdü. "
          "Lütfen tekrar dene.";
    }

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection')) {
      return "İnternet bağlantısı kurulamadı. "
          "Bağlantını kontrol edip tekrar dene.";
    }

    if (message.contains('401') ||
        message.contains('403') ||
        message.contains('api key') ||
        message.contains('permission')) {
      return "AI servisine erişilemedi. "
          "API anahtarı ve proje ayarları kontrol edilmeli.";
    }

    if (message.contains('404') || message.contains('model_not_found')) {
      return "Kullanılan AI modeli bulunamadı. "
          "Model ayarları kontrol edilmeli.";
    }

    return "Fotoğraf şu anda analiz edilemedi. "
        "Lütfen kısa bir süre sonra tekrar dene.";
  }

  Future<void> _analyzeSelectedImage() async {
    if (_isAnalyzingImage || _isSaving) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI analizi için önce fotoğraf seç veya çek."),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzingImage = true;
    });

    try {
      final ClothingAnalysisResult result = await _geminiService
          .analyzeClothingImage(_selectedImage!);

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _editedAiFields.clear();

        selectedCategory = result.category;
        selectedColor = result.color;
        selectedFabric = result.fabric;
        selectedSeason = result.season;

        if (result.hasBrand) {
          brandController.text = result.brand!;
        }

        if (result.description.isNotEmpty) {
          notesController.text = result.description;
        }
      });

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
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "AI analizi tamamlandı. Tahminleri kontrol edip değiştirebilirsin.",
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

      final friendlyMessage = _getFriendlyImageAnalysisError(e);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    friendlyMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: "Tekrar Dene",
              textColor: Colors.white,
              onPressed: () {
                _analyzeSelectedImage();
              },
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });
      }
    }
  }

  Future<void> _saveClothing() async {
    if (_isSaving) return;

    if (selectedCategory == null ||
        selectedColor == null ||
        selectedFabric == null ||
        selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm zorunlu alanları doldur.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı oturumu bulunamadı.")),
      );
      return;
    }

    /*
      Yeni kıyafet eklerken fotoğraf zorunlu.
      Düzenleme modunda eski fotoğraf kullanılabilir.
    */
    final existingImageUrl = widget.clothing?.imageUrl.trim() ?? "";

    if (!isEditMode && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen kıyafet fotoğrafını seç veya çek."),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String imageUrl = existingImageUrl;

      /*
        Yeni bir fotoğraf seçildiyse Cloudinary'ye yüklenir.
        Cloudinary'nin döndürdüğü secure_url alınır.
      */
      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      }

      if (imageUrl.isEmpty) {
        throw Exception("Kıyafet fotoğraf adresi oluşturulamadı.");
      }

      final clothingItem = ClothingItem(
        id: isEditMode ? widget.clothing!.id : "",
        uid: user.uid,
        imageUrl: imageUrl,
        category: selectedCategory!,
        color: selectedColor!,
        fabric: selectedFabric!,
        season: selectedSeason!,
        favorite: isFavorite,
        brand: brandController.text.trim(),
        notes: notesController.text.trim(),
        timesUsed: isEditMode ? widget.clothing!.timesUsed : 0,
        createdAt: isEditMode ? widget.clothing!.createdAt : DateTime.now(),
      );

      if (isEditMode) {
        await _firestoreService.updateClothing(clothingItem);
      } else {
        await _firestoreService.addClothing(clothingItem);
      }

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
                    isEditMode
                        ? "Kıyafet ve fotoğraf başarıyla güncellendi."
                        : "Kıyafet ve fotoğraf başarıyla kaydedildi.",
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

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Kıyafet kaydedilemedi.\n$e",
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
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildImageArea() {
    final existingImageUrl = widget.clothing?.imageUrl.trim() ?? "";

    Widget imageContent;

    if (_selectedImage != null) {
      imageContent = Image.file(
        _selectedImage!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (existingImageUrl.isNotEmpty) {
      imageContent = Image.network(
        existingImageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, size: 55, color: Colors.grey),
                SizedBox(height: 10),
                Text("Fotoğraf yüklenemedi"),
              ],
            ),
          );
        },
      );
    } else {
      imageContent = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 70, color: Color(0xFF6A11CB)),
          SizedBox(height: 15),
          Text(
            "Fotoğraf Ekle",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Kamerayla çek veya galeriden seç",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: imageContent,
            ),
            if (_selectedImage != null || existingImageUrl.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: const Color(0xFF6A11CB),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showImageSourceSheet,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 19),
                          SizedBox(width: 7),
                          Text(
                            "Değiştir",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Kıyafeti Düzenle" : "Kıyafet Ekle"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageArea(),

            const SizedBox(height: 14),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed:
                    _isSaving || _isAnalyzingImage || _selectedImage == null
                    ? null
                    : _analyzeSelectedImage,
                icon: _isAnalyzingImage
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _isAnalyzingImage
                      ? "AI kıyafeti analiz ediyor..."
                      : "AI ile Analiz Et",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "AI tahminleri yardımcı amaçlıdır. "
              "Kategori, renk, kumaş ve mevsim alanlarını değiştirebilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            if (_analysisResult != null) ...[
              const SizedBox(height: 18),

              ClothingAnalysisCard(
                result: _analysisResult!,
                editedFields: _editedAiFields,
                currentCategory: selectedCategory,
                currentColor: selectedColor,
                currentFabric: selectedFabric,
                currentSeason: selectedSeason,
                currentBrand: brandController.text.trim(),
              ),
            ],

            const SizedBox(height: 25),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Pantolon", child: Text("Pantolon")),
                DropdownMenuItem(value: "Tişört", child: Text("Tişört")),
                DropdownMenuItem(value: "Gömlek", child: Text("Gömlek")),
                DropdownMenuItem(value: "Kazak", child: Text("Kazak")),
                DropdownMenuItem(
                  value: "Sweatshirt",
                  child: Text("Sweatshirt"),
                ),
                DropdownMenuItem(value: "Ceket", child: Text("Ceket")),
                DropdownMenuItem(value: "Mont", child: Text("Mont")),
                DropdownMenuItem(value: "Şort", child: Text("Şort")),
                DropdownMenuItem(value: "Etek", child: Text("Etek")),
                DropdownMenuItem(value: "Elbise", child: Text("Elbise")),
                DropdownMenuItem(value: "Ayakkabı", child: Text("Ayakkabı")),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selectedCategory = value;

                        if (_analysisResult != null) {
                          _editedAiFields.add("category");
                        }
                      });
                    },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: const InputDecoration(
                labelText: "Renk",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Siyah", child: Text("Siyah")),
                DropdownMenuItem(value: "Beyaz", child: Text("Beyaz")),
                DropdownMenuItem(value: "Krem", child: Text("Krem")),
                DropdownMenuItem(value: "Bej", child: Text("Bej")),
                DropdownMenuItem(value: "Gri", child: Text("Gri")),
                DropdownMenuItem(value: "Mavi", child: Text("Mavi")),
                DropdownMenuItem(value: "Lacivert", child: Text("Lacivert")),
                DropdownMenuItem(value: "Yeşil", child: Text("Yeşil")),
                DropdownMenuItem(value: "Kırmızı", child: Text("Kırmızı")),
                DropdownMenuItem(value: "Pembe", child: Text("Pembe")),
                DropdownMenuItem(value: "Mor", child: Text("Mor")),
                DropdownMenuItem(value: "Sarı", child: Text("Sarı")),
                DropdownMenuItem(
                  value: "Kahverengi",
                  child: Text("Kahverengi"),
                ),
                DropdownMenuItem(value: "Turuncu", child: Text("Turuncu")),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selectedColor = value;

                        if (_analysisResult != null) {
                          _editedAiFields.add("color");
                        }
                      });
                    },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedFabric,
              decoration: const InputDecoration(
                labelText: "Kumaş",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Pamuk", child: Text("Pamuk")),
                DropdownMenuItem(value: "Denim", child: Text("Denim")),
                DropdownMenuItem(value: "Keten", child: Text("Keten")),
                DropdownMenuItem(value: "Yün", child: Text("Yün")),
                DropdownMenuItem(value: "Polyester", child: Text("Polyester")),
                DropdownMenuItem(value: "Deri", child: Text("Deri")),
                DropdownMenuItem(value: "Kadife", child: Text("Kadife")),
                DropdownMenuItem(value: "Viskon", child: Text("Viskon")),
                DropdownMenuItem(value: "İpek", child: Text("İpek")),
                DropdownMenuItem(value: "Triko", child: Text("Triko")),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selectedFabric = value;

                        if (_analysisResult != null) {
                          _editedAiFields.add("fabric");
                        }
                      });
                    },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedSeason,
              decoration: const InputDecoration(
                labelText: "Mevsim",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "İlkbahar", child: Text("İlkbahar")),
                DropdownMenuItem(value: "Yaz", child: Text("Yaz")),
                DropdownMenuItem(value: "Sonbahar", child: Text("Sonbahar")),
                DropdownMenuItem(value: "Kış", child: Text("Kış")),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selectedSeason = value;

                        if (_analysisResult != null) {
                          _editedAiFields.add("season");
                        }
                      });
                    },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: brandController,
              enabled: !_isSaving,
              onChanged: (value) {
                if (_analysisResult == null) return;

                setState(() {
                  _editedAiFields.add("brand");
                });
              },
              decoration: const InputDecoration(
                labelText: "Marka (İsteğe Bağlı)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: notesController,
              enabled: !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Not (İsteğe Bağlı)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SwitchListTile(
              value: isFavorite,
              title: const Text("Favorilere Ekle"),
              secondary: const Icon(Icons.star),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        isFavorite = value;
                      });
                    },
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveClothing,
                icon: _isSaving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? "Fotoğraf yükleniyor ve kaydediliyor..."
                      : isEditMode
                      ? "Değişiklikleri Kaydet"
                      : "Kaydet",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
