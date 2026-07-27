import 'package:flutter/material.dart';

import '../../models/clothing_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class WardrobeStatisticsScreen extends StatelessWidget {
  const WardrobeStatisticsScreen({super.key});

  String _findMostCommon(List<String> values) {
    if (values.isEmpty) {
      return "Veri yok";
    }

    final Map<String, int> counts = {};

    for (final value in values) {
      if (value.trim().isEmpty) continue;

      counts[value] = (counts[value] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return "Veri yok";
    }

    return counts.entries.reduce((current, next) {
      return current.value >= next.value ? current : next;
    }).key;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gardırop İstatistikleri"),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : StreamBuilder<List<ClothingItem>>(
              stream: firestoreService.getClothes(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "İstatistikler yüklenemedi.\n${snapshot.error}",
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
                      "İstatistik oluşturmak için önce kıyafet eklemelisin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final int totalClothes = clothes.length;

                final int favoriteCount = clothes
                    .where((item) => item.favorite)
                    .length;

                final int totalUsage = clothes.fold<int>(
                  0,
                  (total, item) => total + item.timesUsed,
                );

                final String mostCommonCategory = _findMostCommon(
                  clothes.map((item) => item.category).toList(),
                );

                final String mostCommonColor = _findMostCommon(
                  clothes.map((item) => item.color).toList(),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6A11CB,
                              ).withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Gardırop Özeti",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$totalClothes kıyafet kayıtlı",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatisticCard(
                              icon: Icons.checkroom,
                              title: "Toplam",
                              value: "$totalClothes",
                              subtitle: "Kıyafet",
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatisticCard(
                              icon: Icons.star,
                              title: "Favoriler",
                              value: "$favoriteCount",
                              subtitle: "Kıyafet",
                              iconColor: Colors.amber,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildInformationCard(
                        icon: Icons.repeat,
                        title: "Toplam Kullanım",
                        value: "$totalUsage kez kullanıldı",
                      ),

                      _buildInformationCard(
                        icon: Icons.category,
                        title: "En Çok Bulunan Kategori",
                        value: mostCommonCategory,
                      ),

                      _buildInformationCard(
                        icon: Icons.palette,
                        title: "En Çok Tercih Edilen Renk",
                        value: mostCommonColor,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    Color iconColor = const Color(0xFF6A11CB),
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          children: [
            Icon(icon, size: 38, color: iconColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6A11CB).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF6A11CB)),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
