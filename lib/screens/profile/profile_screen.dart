import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../models/clothing_item.dart';
import '../../models/outfit_plan.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/welcome_screen.dart';
import '../../models/achievement.dart';
import '../../services/achievement_service.dart';
import '../../core/settings/notification_controller.dart';
import '../../services/local_notification_service.dart';
import '../../services/gemini_service.dart';

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

  Future<void> _testGemini(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 18),
              Expanded(child: Text("Gemini yanıtı hazırlanıyor...")),
            ],
          ),
        );
      },
    );

    try {
      final response = await GeminiService().generateTestResponse();

      if (!context.mounted) return;

      Navigator.pop(context);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF6A11CB)),
                SizedBox(width: 10),
                Expanded(child: Text("Gemini Yanıtı")),
              ],
            ),
            content: Text(
              response,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text("Kapat"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);

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
                  "Gemini bağlantısı başarısız:\n$e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
    final achievementService = AchievementService();

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

                            final achievements = achievementService
                                .generateAchievements(
                                  clothes: clothes,
                                  outfitPlans: plans,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
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
                                ),

                                const SizedBox(height: 28),

                                const Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 27,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Başarımlar",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                ...achievements.map(
                                  (achievement) => _buildAchievementCard(
                                    context: context,
                                    achievement: achievement,
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
                    AnimatedBuilder(
                      animation: notificationController,
                      builder: (context, child) {
                        final enabled =
                            notificationController.notificationsEnabled;

                        return _buildSettingsCard(
                          context: context,
                          icon: enabled
                              ? Icons.notifications_active
                              : Icons.notifications_outlined,
                          title: "Bildirimler",
                          subtitle: enabled
                              ? "Kombin hatırlatıcıları açık"
                              : "Kombin hatırlatıcıları kapalı",
                          trailing: Switch(
                            value: enabled,
                            onChanged: (value) async {
                              await notificationController
                                  .setNotificationsEnabled(value);

                              if (value) {
                                final granted = await LocalNotificationService
                                    .instance
                                    .requestPermission();

                                if (granted) {
                                  await LocalNotificationService.instance
                                      .showTestNotification();
                                }
                              }

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: value
                                      ? Colors.green.shade600
                                      : Colors.grey.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Row(
                                    children: [
                                      Icon(
                                        value
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          value
                                              ? "Kombin hatırlatıcıları açıldı."
                                              : "Kombin hatırlatıcıları kapatıldı.",
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
                            },
                          ),
                          onTap: null,
                        );
                      },
                    ),

                    _buildSettingsCard(
                      context: context,
                      icon: Icons.auto_awesome,
                      title: "Gemini AI Testi",
                      subtitle: "Yapay zekâ bağlantısını kontrol et",
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _testGemini(context);
                      },
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

  Widget _buildAchievementCard({
    required BuildContext context,
    required Achievement achievement,
  }) {
    final Color achievementColor = achievement.isUnlocked
        ? Colors.amber.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? Colors.amber.withValues(alpha: 0.10)
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: achievement.isUnlocked
                ? Colors.amber.shade400
                : Theme.of(context).dividerColor,
            width: achievement.isUnlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: achievementColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievementColor,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  achievement.isUnlocked
                      ? Icons.check_circle
                      : Icons.lock_outline,
                  color: achievement.isUnlocked
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),

            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: achievement.progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 9,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achievement.isUnlocked
                          ? Colors.amber.shade700
                          : Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  achievement.isUnlocked ? "Tamamlandı" : "Devam ediyor",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: achievement.isUnlocked
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "${achievement.currentValue.clamp(0, achievement.targetValue)}"
                  " / ${achievement.targetValue}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
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
