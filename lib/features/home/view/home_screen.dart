import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/prayer/controller/prayer_controller.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prayerCtrl = Get.put(PrayerController());
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NamazAlert 🕌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () => Get.toNamed(AppRoutes.groups),
            tooltip: 'My Groups',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authCtrl.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => prayerCtrl.fetchTodayPrayers(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting
              Obx(() => Text(
                    'আস-সালামু আলাইকুম, ${authCtrl.currentUser.value?.name ?? ''} 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
              const SizedBox(height: 16),

              // Next Prayer Banner
              Obx(() {
                final name = prayerCtrl.nextPrayerName.value;
                final time = prayerCtrl.nextPrayerTime.value;
                final cd = prayerCtrl.countdown.value;

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Prayer',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.isEmpty ? '...' : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cd,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Prayer Times List
              Obx(() {
                if (prayerCtrl.isLoadingPrayers.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final prayers = prayerCtrl.todayPrayers.value;
                if (prayers == null) {
                  return Center(
                    child: Column(
                      children: [
                        const Text('Could not load prayer times'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: prayerCtrl.fetchTodayPrayers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return _PrayerTimesCard(prayers: prayers);
              }),

              const SizedBox(height: 20),

              // Hadith Card
              Obx(() {
                final hadith = prayerCtrl.todayHadith.value;
                if (prayerCtrl.isLoadingHadith.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (hadith == null) return const SizedBox.shrink();
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📖', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              "Today's Hadith",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hadith.textBengali.isNotEmpty
                              ? hadith.textBengali
                              : hadith.text,
                          style: const TextStyle(fontSize: 14, height: 1.6),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '— ${hadith.bookDisplayName} #${hadith.number}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.groups),
        icon: const Icon(Icons.group_add),
        label: const Text('Groups'),
      ),
    );
  }
}

class _PrayerTimesCard extends StatelessWidget {
  final PrayerTimeModel prayers;
  const _PrayerTimesCard({required this.prayers});

  static const _icons = {
    'Fajr': '🌙',
    'Dhuhr': '☀️',
    'Asr': '🌤️',
    'Maghrib': '🌅',
    'Isha': '🌑',
  };

  static const _colors = {
    'Fajr': AppColors.fajrColor,
    'Dhuhr': AppColors.dhuhrColor,
    'Asr': AppColors.asrColor,
    'Maghrib': AppColors.maghribColor,
    'Isha': AppColors.ishaColor,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🕐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  "Today's Prayer Times",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  prayers.hijriDate,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...prayers.allPrayers.entries.map((entry) {
              final color = _colors[entry.key] ?? AppColors.primary;
              final icon = _icons[entry.key] ?? '🕌';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
