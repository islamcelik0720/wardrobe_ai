import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../models/clothing_item.dart';
import '../../models/outfit_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _showThemeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: themeController,
          builder: (context, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.brightness_6, color: Color(0xFF6A11CB)),
                  SizedBox(width: 10),
                  Text("Tema Seçimi"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeController.themeMode,
                    title: const Text("Sistem Teması"),
                    subtitle: const Text("Telefonun tema ayarını kullanır"),
                    secondary: const Icon(Icons.phone_android),
                    onChanged: (value) async {
                      if (value == null) return;

                      await themeController.setThemeMode(value);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeController.themeMode,
                    title: const Text("Açık Tema"),
                    subtitle: const Text("Uygulamayı açık temada kullanır"),
                    secondary: const Icon(Icons.light_mode),
                    onChanged: (value) async {
                      if (value == null) return;

                      await themeController.setThemeMode(value);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeController.themeMode,
                    title: const Text("Koyu Tema"),
                    subtitle: const Text("Uygulamayı koyu temada kullanır"),
                    secondary: const Icon(Icons.dark_mode),
                    onChanged: (value) async {
                      if (value == null) return;

                      await themeController.setThemeMode(value);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text("Çıkış Yap"),
            ],
          ),
          content: const Text("Hesabından çıkış yapmak istediğine emin misin?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Vazgeç"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Çıkış Yap"),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Profil & Ayarlar"), centerTitle: true),
      body: user == null
          ? const Center(child: Text("Kullanıcı oturumu bulunamadı."))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profil bilgileri
                    FutureBuilder<Map<String, dynamic>?>(
                      future: firestoreService.getUserData(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        final userData = snapshot.data;

                        final String fullName =
                            userData?["fullName"]
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true
                            ? userData!["fullName"].toString()
                            : "WardrobeAI Kullanıcısı";

                        final String email =
                            userData?["email"]?.toString().trim().isNotEmpty ==
                                true
                            ? userData!["email"].toString()
                            : user.email ?? "E-posta bulunamadı";

                        return Container(
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
                              const CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  size: 58,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                email,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Kullanıcı istatistikleri
                    const Text(
                      "Gardırop Özeti",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    StreamBuilder<List<ClothingItem>>(
                      stream: firestoreService.getClothes(user.uid),
                      builder: (context, clothesSnapshot) {
                        if (clothesSnapshot.hasError) {
                          return _buildErrorCard(
                            context,
                            "Kıyafet istatistikleri yüklenemedi.",
                          );
                        }

                        if (clothesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final clothes = clothesSnapshot.data ?? [];

                        final int totalClothes = clothes.length;
                        final int favoriteCount = clothes
                            .where((item) => item.favorite)
                            .length;

                        return StreamBuilder<List<OutfitPlan>>(
                          stream: firestoreService.getOutfitPlans(user.uid),
                          builder: (context, plansSnapshot) {
                            if (plansSnapshot.hasError) {
                              return _buildErrorCard(
                                context,
                                "Kombin istatistikleri yüklenemedi.",
                              );
                            }

                            if (plansSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final plans = plansSnapshot.data ?? [];
                            final int plannedOutfits = plans.length;

                            return Row(
                              children: [
                                Expanded(
                                  child: _buildStatisticCard(
                                    context: context,
                                    icon: Icons.checkroom,
                                    value: "$totalClothes",
                                    title: "Kıyafet",
                                    iconColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatisticCard(
                                    context: context,
                                    icon: Icons.star,
                                    value: "$favoriteCount",
                                    title: "Favori",
                                    iconColor: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildStatisticCard(
                                    context: context,
                                    icon: Icons.calendar_month,
                                    value: "$plannedOutfits",
                                    title: "Plan",
                                    iconColor: Colors.green,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Ayarlar",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tema ayarı
                    AnimatedBuilder(
                      animation: themeController,
                      builder: (context, child) {
                        String themeText;

                        switch (themeController.themeMode) {
                          case ThemeMode.light:
                            themeText = "Açık tema kullanılıyor";
                            break;
                          case ThemeMode.dark:
                            themeText = "Koyu tema kullanılıyor";
                            break;
                          case ThemeMode.system:
                            themeText = "Sistem teması kullanılıyor";
                            break;
                        }

                        return _buildSettingsCard(
                          context: context,
                          icon: themeController.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : themeController.themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_6,
                          title: "Tema",
                          subtitle: themeText,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showThemeDialog(context);
                          },
                        );
                      },
                    ),

                    // Bildirim ayarı şimdilik pasif
                    _buildSettingsCard(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: "Bildirimler",
                      subtitle: "Yakında kullanıma sunulacak",
                      trailing: const Switch(value: false, onChanged: null),
                      onTap: null,
                    ),

                    _buildSettingsCard(
                      context: context,
                      icon: Icons.info_outline,
                      title: "Uygulama Sürümü",
                      subtitle: "1.0.0",
                      trailing: null,
                      onTap: null,
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _logout(context);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Çıkış Yap",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String title,
    required Color iconColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: trailing,
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
