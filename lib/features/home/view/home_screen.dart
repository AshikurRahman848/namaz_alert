import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF0F4F0),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: prayerCtrl.fetchTodayPrayers,
        child: CustomScrollView(
          slivers: [
            // ── Premium App Bar ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('🕌', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NamazAlert',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'আস-সালামু আলাইকুম, ${authCtrl.currentUser.value?.name.split(' ').first ?? ''} 👋',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.groups),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                ),
                IconButton(
                  onPressed: authCtrl.logout,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout,
                        color: Colors.redAccent, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // ── Next Prayer Hero Card ─────────────────────────
                    _NextPrayerCard(prayerCtrl: prayerCtrl)
                        .animate()
                        .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut)
                        .fadeIn(),

                    const SizedBox(height: 20),

                    // ── Section Title ────────────────────────────────
                    Row(
                      children: [
                        Text(
                          "Today's Prayers",
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        Obx(() {
                          final p = prayerCtrl.todayPrayers.value;
                          if (p == null) return const SizedBox.shrink();
                          return Text(
                            p.date,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                      ],
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 12),

                    // ── Prayer Times Grid ────────────────────────────
                    Obx(() {
                      if (prayerCtrl.isLoadingPrayers.value) {
                        return _PrayerTimesShimmer();
                      }
                      final prayers = prayerCtrl.todayPrayers.value;
                      if (prayers == null) {
                        return _ErrorCard(
                            onRetry: prayerCtrl.fetchTodayPrayers);
                      }
                      return _PrayerTimesGrid(
                        prayers: prayers,
                        nextPrayerName: prayerCtrl.nextPrayerName.value,
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Hadith Card ──────────────────────────────────
                    Row(
                      children: [
                        Text(
                          "Today's Hadith",
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.accent,
                                Color(0xFFFFF176)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Daily',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ).animate(delay: 400.ms).fadeIn(),

                    const SizedBox(height: 12),

                    Obx(() {
                      if (prayerCtrl.isLoadingHadith.value) {
                        return _HadithShimmer();
                      }
                      final hadith = prayerCtrl.todayHadith.value;
                      if (hadith == null) return const SizedBox.shrink();
                      return _HadithCard(
                        text: hadith.textBengali.isNotEmpty
                            ? hadith.textBengali
                            : hadith.text,
                        arabicText: hadith.text,
                        source: '${hadith.bookDisplayName} #${hadith.number}',
                      );
                    }).animate(delay: 500.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.groups),
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: Text(
          'My Groups',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ).animate(delay: 600.ms).scale(curve: Curves.elasticOut),
    );
  }
}

// ── Next Prayer Hero Card ─────────────────────────────────────────────────────

class _NextPrayerCard extends StatelessWidget {
  final PrayerController prayerCtrl;

  const _NextPrayerCard({required this.prayerCtrl});

  static const _namazEmojis = {
    'Fajr': '🌙',
    'Dhuhr': '☀️',
    'Asr': '🌤️',
    'Maghrib': '🌅',
    'Isha': '🌑',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B1A), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hijri date badge
                Obx(() {
                  final hijri = prayerCtrl.todayPrayers.value?.hijriDate ?? '';
                  if (hijri.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hijri,
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Prayer',
                            style: GoogleFonts.nunito(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Obx(() {
                                final name = prayerCtrl.nextPrayerName.value;
                                return Text(
                                  _namazEmojis[name] ?? '🕌',
                                  style: const TextStyle(fontSize: 28),
                                );
                              }),
                              const SizedBox(width: 8),
                              Obx(() {
                                final name = prayerCtrl.nextPrayerName.value;
                                return Text(
                                  name.isEmpty ? '...' : name,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Obx(() => Text(
                                prayerCtrl.nextPrayerTime.value,
                                style: GoogleFonts.nunito(
                                  color: AppColors.accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              )),
                        ],
                      ),
                    ),

                    // Countdown pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Colors.white, size: 18),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                                prayerCtrl.countdown.value.isNotEmpty
                                    ? prayerCtrl.countdown.value
                                    : '--:--',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prayer Times Grid ─────────────────────────────────────────────────────────

class _PrayerTimesGrid extends StatelessWidget {
  final PrayerTimeModel prayers;
  final String nextPrayerName;

  const _PrayerTimesGrid({
    required this.prayers,
    required this.nextPrayerName,
  });

  static const _config = {
    'Fajr': {
      'emoji': '🌙',
      'gradient': [Color(0xFF1565C0), Color(0xFF42A5F5)],
      'label': 'ফজর',
    },
    'Dhuhr': {
      'emoji': '☀️',
      'gradient': [Color(0xFFE65100), Color(0xFFFF9800)],
      'label': 'যোহর',
    },
    'Asr': {
      'emoji': '🌤️',
      'gradient': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      'label': 'আসর',
    },
    'Maghrib': {
      'emoji': '🌅',
      'gradient': [Color(0xFF4A148C), Color(0xFFAB47BC)],
      'label': 'মাগরিব',
    },
    'Isha': {
      'emoji': '🌑',
      'gradient': [Color(0xFF212121), Color(0xFF546E7A)],
      'label': 'ইশা',
    },
  };

  @override
  Widget build(BuildContext context) {
    final entries = prayers.allPrayers.entries.toList();

    return Column(
      children: [
        // First row: Fajr, Dhuhr
        Row(
          children: [
            Expanded(
                child: _PrayerCard(
                    name: entries[0].key,
                    time: entries[0].value,
                    config: _config[entries[0].key]!,
                    isNext: nextPrayerName == entries[0].key,
                    delay: 0)),
            const SizedBox(width: 12),
            Expanded(
                child: _PrayerCard(
                    name: entries[1].key,
                    time: entries[1].value,
                    config: _config[entries[1].key]!,
                    isNext: nextPrayerName == entries[1].key,
                    delay: 80)),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Asr, Maghrib
        Row(
          children: [
            Expanded(
                child: _PrayerCard(
                    name: entries[2].key,
                    time: entries[2].value,
                    config: _config[entries[2].key]!,
                    isNext: nextPrayerName == entries[2].key,
                    delay: 160)),
            const SizedBox(width: 12),
            Expanded(
                child: _PrayerCard(
                    name: entries[3].key,
                    time: entries[3].value,
                    config: _config[entries[3].key]!,
                    isNext: nextPrayerName == entries[3].key,
                    delay: 240)),
          ],
        ),
        const SizedBox(height: 12),
        // Full width Isha
        _PrayerCard(
          name: entries[4].key,
          time: entries[4].value,
          config: _config[entries[4].key]!,
          isNext: nextPrayerName == entries[4].key,
          delay: 320,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String name;
  final String time;
  final Map<String, Object> config;
  final bool isNext;
  final int delay;
  final bool fullWidth;

  const _PrayerCard({
    required this.name,
    required this.time,
    required this.config,
    required this.isNext,
    required this.delay,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = config['gradient'] as List;
    final emoji = config['emoji'] as String;
    final label = config['label'] as String;

    return Container(
      decoration: BoxDecoration(
        gradient: isNext
            ? LinearGradient(
                colors: gradients.cast<Color>(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isNext ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isNext
            ? null
            : Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: (gradients.first as Color).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: EdgeInsets.all(fullWidth ? 18 : 16),
      child: fullWidth
          ? Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: isNext
                            ? Colors.white70
                            : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isNext ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isNext ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji,
                        style: const TextStyle(fontSize: 24)),
                    const Spacer(),
                    if (isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🔔',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isNext ? Colors.white70 : AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isNext ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isNext ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn();
  }
}

// ── Hadith Card ───────────────────────────────────────────────────────────────

class _HadithCard extends StatefulWidget {
  final String text;
  final String arabicText;
  final String source;

  const _HadithCard({
    required this.text,
    required this.arabicText,
    required this.source,
  });

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _isExpanded = false;

  void _copyHadith() {
    final buffer = StringBuffer();
    if (widget.arabicText.isNotEmpty) {
      buffer.writeln(widget.arabicText);
      buffer.writeln();
    }
    buffer.writeln(widget.text);
    if (widget.source.isNotEmpty) {
      buffer.writeln('\n— ${widget.source}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    Get.snackbar(
      'অনুলিপি সম্পন্ন',
      'হাদিসটি ক্লিপবোর্ডে কপি করা হয়েছে',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
    );
  }

  void _showFullHadithSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "আজকের হাদিস",
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            widget.source,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.primary, size: 20),
                      tooltip: 'কপি করুন',
                      onPressed: _copyHadith,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    if (widget.arabicText.isNotEmpty) ...[
                      Text(
                        widget.arabicText,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          color: AppColors.primary,
                          height: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      widget.text,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: const Color(0xFF2D3748),
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.source,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLongText = widget.text.length > 130;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B1A), Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  "Today's Hadith",
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.source,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _copyHadith,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arabic text
          if (widget.arabicText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                widget.arabicText,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: AppColors.primary,
                  height: 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey.shade100, height: 1),
          ),

          // Translation text
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              isLongText ? 6 : 20,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF424242),
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: _isExpanded ? null : 4,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ),

          // Read More / Show Less & Modal Action Buttons
          if (isLongText)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _isExpanded ? 'সংক্ষেপ করুন' : 'সম্পূর্ণ পড়ুন (Read More)',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _showFullHadithSheet,
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      size: 18,
                      color: AppColors.accentDark,
                    ),
                    label: Text(
                      'পূর্ণ স্ক্রিন',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shimmer Loaders ───────────────────────────────────────────────────────────

class _PrayerTimesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 130, radius: 20)),
            SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 130, radius: 20)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ShimmerBox(height: 130, radius: 20)),
            SizedBox(width: 12),
            Expanded(child: _ShimmerBox(height: 130, radius: 20)),
          ],
        ),
        SizedBox(height: 12),
        _ShimmerBox(height: 80, radius: 20),
      ],
    );
  }
}

class _HadithShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _ShimmerBox(height: 200, radius: 24);
  }
}

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;

  const _ShimmerBox({required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🌐', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Could not load prayer times',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
