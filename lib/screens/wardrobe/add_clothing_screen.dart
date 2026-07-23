import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/clothing_item.dart';
import '../../services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import 'package:flutter/material.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  final StorageService _storageService = StorageService();

  final FirestoreService _firestoreService = FirestoreService();

  String? selectedCategory;
  String? selectedColor;
  String? selectedFabric;
  String? selectedSeason;

  bool isFavorite = false;

  final TextEditingController brandController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  Future<void> _uploadImage() async {
    debugPrint("Kaydet butonuna basıldı");
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce bir fotoğraf seçiniz.")),
      );
      return;
    }

    try {
      final imageUrl = await _storageService.uploadImage(_selectedImage!);

      debugPrint("Yüklenen Fotoğraf URL:");
      debugPrint(imageUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fotoğraf başarıyla yüklendi.")),
      );
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fotoğraf yüklenemedi.")));
    }
  }

  Future<void> _saveClothing() async {
    if (selectedCategory == null ||
        selectedColor == null ||
        selectedFabric == null ||
        selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm zorunlu alanları doldurunuz."),
        ),
      );
      return;
    }

    try {
      final clothingItem = ClothingItem(
        id: "",
        uid: FirebaseAuth.instance.currentUser!.uid,
        imageUrl: "",
        category: selectedCategory!,
        color: selectedColor!,
        fabric: selectedFabric!,
        season: selectedSeason!,
        favorite: isFavorite,
        brand: brandController.text.trim(),
        notes: notesController.text.trim(),
        timesUsed: 0,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addClothing(clothingItem);

      if (!mounted) return;

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
              Text(
                "Kıyafet başarıyla kaydedildi.",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Hata: $e",
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
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kıyafet Ekle"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 70,
                            color: Color(0xFF6A11CB),
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Fotoğraf Seç",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Pantolon", child: Text("Pantolon")),
                DropdownMenuItem(value: "Tişört", child: Text("Tişört")),
                DropdownMenuItem(value: "Gömlek", child: Text("Gömlek")),
                DropdownMenuItem(value: "Ceket", child: Text("Ceket")),
                DropdownMenuItem(value: "Ayakkabı", child: Text("Ayakkabı")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Renk",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Siyah", child: Text("Siyah")),
                DropdownMenuItem(value: "Beyaz", child: Text("Beyaz")),
                DropdownMenuItem(value: "Mavi", child: Text("Mavi")),
                DropdownMenuItem(value: "Kırmızı", child: Text("Kırmızı")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedColor = value;
                });
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Kumaş",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Pamuk", child: Text("Pamuk")),
                DropdownMenuItem(value: "Denim", child: Text("Denim")),
                DropdownMenuItem(value: "Keten", child: Text("Keten")),
                DropdownMenuItem(value: "Yün", child: Text("Yün")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFabric = value;
                });
              },
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
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
              onChanged: (value) {
                setState(() {
                  selectedSeason = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: brandController,
              decoration: const InputDecoration(
                labelText: "Marka (İsteğe Bağlı)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: notesController,
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
              onChanged: (value) {
                setState(() {
                  isFavorite = value;
                });
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _saveClothing,
                child: const Text("Kaydet", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
