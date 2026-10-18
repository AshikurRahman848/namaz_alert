import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/services/hadith_service.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/services/adhan_audio_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupController _groupCtrl = Get.find();
  final AuthController _authCtrl = Get.find();

  late String _groupId;
  final TextEditingController _hadithTextCtrl = TextEditingController();
  final TextEditingController _narratorCtrl =
      TextEditingController(text: 'সহীহ বুখারী');

  bool _sendingHadith = false;
  bool _loadingHadithApi = false;
  PrayerTimeModel? _cityPrayerTimes;

  static const _namazIcons = {
    'Fajr': {'icon': Icons.nightlight_round, 'emoji': '🌙', 'bn': 'ফজর'},
    'Dhuhr': {'icon': Icons.wb_sunny_rounded, 'emoji': '☀️', 'bn': 'যোহর'},
    'Asr': {'icon': Icons.wb_twilight_rounded, 'emoji': '🌤️', 'bn': 'আসর'},
    'Maghrib': {'icon': Icons.wb_twilight, 'emoji': '🌅', 'bn': 'মাগরিব'},
    'Isha': {'icon': Icons.bedtime_rounded, 'emoji': '🌑', 'bn': 'ইশা'},
  };

  @override
  void initState() {
    super.initState();
    _groupId = Get.arguments as String;
    _loadCityPrayerTimes();
  }

  @override
  void dispose() {
    AdhanAudioService.stopAdhan();
    _hadithTextCtrl.dispose();
    _narratorCtrl.dispose();
    super.dispose();
  }

  GroupModel? get _group => _groupCtrl.getGroupById(_groupId);

  Future<void> _loadCityPrayerTimes() async {
    final group = _group;
    if (group == null) return;
    final times = await PrayerService.fetchByCity(
      city: group.city,
      country: group.country,
      method: group.calculationMethod,
    );
    if (mounted) {
      setState(() => _cityPrayerTimes = times);
    }
  }

  /// Load random hadith from API into text controller for admin to inspect/edit
  Future<void> _loadHadithFromApi() async {
    setState(() => _loadingHadithApi = true);
    try {
      final hadith = await HadithService.fetchRandom();
      _hadithTextCtrl.text = hadith.fullText;
      _narratorCtrl.text = '${hadith.bookDisplayName} #${hadith.number}';

      Get.snackbar(
        '📖 হাদিস লোড হয়েছে',
        'নিচে এডিট করে বা সরাসরি ব্রডকাস্ট করতে পারেন',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('ত্রুটি', 'হাদিস লোড করতে সমস্যা হয়েছে: $e');
    } finally {
      setState(() => _loadingHadithApi = false);
    }
  }

  /// Broadcast either custom typed hadith or API loaded hadith
  Future<void> _broadcastHadith() async {
    final text = _hadithTextCtrl.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        'হাদিস লিখুন',
        'অনুগ্রহ করে হাদিস বা বার্তা লিখুন অথবা এপিআই বাটন দিয়ে লোড করুন',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _sendingHadith = true);
    try {
      final narrator = _narratorCtrl.text.trim().isNotEmpty
          ? _narratorCtrl.text.trim()
          : 'অফিস এডমিন';

      await _groupCtrl.broadcastHadith(
        groupId: _groupId,
        hadithText: text,
        narrator: narrator,
      );

      Get.snackbar(
        '📢 ব্রডকাস্ট সম্পন্ন!',
        'হাদিসটি সকল মেম্বারদের কাছে নোটিফিকেশন আকারে পৌঁছে গেছে',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'হাদিস পাঠাতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _sendingHadith = false);
    }
  }

  /// Pick manual office prayer time for a prayer (e.g. Dhuhr at 1:30 PM)
  Future<void> _pickPrayerTime(
      BuildContext context, String prayerName, String? currentTime) async {
    try {
      final initial = _stringToTimeOfDay(currentTime);

      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initial,
        helpText: '$prayerName জামায়াত/নামাজের সময় নির্ধারণ করুন',
      );

      if (picked != null) {
        final group = _group;
        if (group == null) return;

        int h = picked.hour;
        final m = picked.minute;

        // Auto-correct PM for afternoon/evening prayers
        if (prayerName == 'Dhuhr' && h < 11) h += 12;
        if (prayerName == 'Asr' && h < 12) h += 12;
        if (prayerName == 'Maghrib' && h < 12) h += 12;
        if (prayerName == 'Isha' && h < 12) h += 12;
        if (prayerName == 'Fajr' && h >= 12) h -= 12;

        final corrected = TimeOfDay(hour: h, minute: m);
        final updated = Map<String, String>.from(group.customPrayerTimes);
        final timeStr = _timeOfDayToString(corrected);
        updated[prayerName] = timeStr;

        await _groupCtrl.updateCustomPrayerTimes(group.id, updated);
        if (mounted) setState(() {});
      }
    } catch (e) {
      // ignore: avoid_print
      print('Pick prayer time error: $e');
      Get.snackbar(
        'ত্রুটি',
        'সময় নির্ধারণে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Reset a prayer's time back to default city time
  Future<void> _resetPrayerTime(String prayerName) async {
    try {
      final group = _group;
      if (group == null) return;

      final updated = Map<String, String>.from(group.customPrayerTimes);
      updated.remove(prayerName);

      await _groupCtrl.updateCustomPrayerTimes(group.id, updated);
      if (mounted) setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print('Reset prayer time error: $e');
    }
  }

  String _formatTimeStr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    final clean = timeStr.split(' ').first.trim();
    final parts = clean.split(':');
    if (parts.length < 2) return clean;
    final hour = int.tryParse(parts[0]) ?? 0;
    final min = int.tryParse(parts[1]) ?? 0;
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = min.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  TimeOfDay _stringToTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) {
      return const TimeOfDay(hour: 12, minute: 0);
    }
    try {
      final clean = timeStr.split(' ').first.trim();
      final parts = clean.split(':');
      final rawH = int.tryParse(parts[0]) ?? 12;
      final rawM = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final h = rawH.clamp(0, 23);
      final m = rawM.clamp(0, 59);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  String _timeOfDayToString(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = _group;
      if (group == null) {
        return const Scaffold(
          body: Center(child: Text('গ্রুপটি পাওয়া যায়নি')),
        );
      }

      final isAdmin = group.isAdmin(_authCtrl.currentUser.value?.uid ?? '');
      final settings = group.notificationSettings;

      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F0),
        appBar: AppBar(
          title: Text(
            group.name,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Group Header Card ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D3B1A), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          radius: 26,
                          child: Text(
                            group.name.isNotEmpty
                                ? group.name.substring(0, 1).toUpperCase()
                                : 'G',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '📍 ${group.city}, ${group.country} • 👥 ${group.memberCount} জন মেম্বার',
                                style: GoogleFonts.nunito(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'এডমিন',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Invite code with 1-tap copy
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: group.inviteCode));
                            Get.snackbar(
                              '📋 কপি হয়েছে!',
                              'ইনভাইট কোড ${group.inviteCode} কপি হয়েছে। সহকর্মীদের সাথে শেয়ার করুন।',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black87,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'কোড: ${group.inviteCode}',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy,
                                    color: Colors.white70, size: 14),
                              ],
                            ),
                          ),
                        ),
                        // Offset pill
                        Row(
                          children: [
                            const Icon(Icons.alarm,
                                color: AppColors.accent, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${settings.offsetMinutes} মিনিট আগে অ্যালার্ট',
                              style: GoogleFonts.nunito(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. Office Prayer Times Section ───────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.access_time_filled,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🕌 অফিস জামায়াত ও নামাজের সময়সূচি',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                isAdmin
                                    ? 'ঘড়ির আইকনে ট্যাপ করে অফিসের জামায়াতের সময় ম্যানুয়ালি সেট করুন'
                                    : 'অফিস এডমিন কর্তৃক নির্ধারিত জামায়াতের সময়সূচি',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...AppConstants.namazNames.map((prayer) {
                      final info = _namazIcons[prayer] ??
                          {'icon': Icons.access_time, 'emoji': '🕌', 'bn': prayer};
                      final isCustom =
                          group.customPrayerTimes.containsKey(prayer);

                      // Time logic: use group custom time if set, otherwise city API default
                      final timeRaw = isCustom
                          ? group.customPrayerTimes[prayer]
                          : _cityPrayerTimes?.allPrayers[prayer];
                      final displayTime = _formatTimeStr(timeRaw);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCustom
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCustom
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(info['emoji'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${info['bn']} ($prayer)',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isCustom
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isCustom
                                        ? '🏢 অফিস জামায়াত'
                                        : '📍 শহরের সময়',
                                    style: GoogleFonts.nunito(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isCustom
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              displayTime,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isCustom
                                    ? AppColors.primary
                                    : AppColors.textDark,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.edit_calendar_rounded,
                                    color: AppColors.primary, size: 20),
                                tooltip: 'সময় পরিবর্তন করুন',
                                onPressed: () => _pickPrayerTime(
                                    context, prayer, timeRaw),
                              ),
                              if (isCustom)
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  icon: const Icon(Icons.restart_alt_rounded,
                                      color: Colors.redAccent, size: 18),
                                  tooltip: 'রিসেট (শহরের সময়)',
                                  onPressed: () => _resetPrayerTime(prayer),
                                ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await NotificationService.scheduleTestNotification(
                              seconds: 5);
                          Get.snackbar(
                            '🔔 টেস্ট নোটিফিকেশন শিডিউল হয়েছে',
                            'ঠিক ৫ সেকেন্ড পর আপনার ফোনে নোটিফিকেশন ও সাউন্ড বাজবে! (অ্যাপ মিনিমাইজ বা লক করতে পারেন)',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF1B5E20),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                        },
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 18),
                        label: Text(
                          'নোটিফিকেশন অ্যালার্ট টেস্ট করুন (৫ সেকেন্ড পর)',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<bool>(
                      valueListenable: AdhanAudioService.isPlayingNotifier,
                      builder: (context, isPlaying, _) {
                        if (isPlaying) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await AdhanAudioService.stopAdhan();
                                await NotificationService.muteNotification(
                                  id: 8888,
                                );
                              },
                              icon: const Icon(Icons.stop_circle_rounded,
                                  size: 19),
                              label: Text(
                                '🛑 আজান বন্ধ করুন (Stop Sound)',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              AdhanAudioService.playAdhan();
                            },
                            icon: const Icon(Icons.volume_up_rounded, size: 18),
                            label: Text(
                              'আজান সাউন্ড শুনুন / চেক করুন (অডিও টেস্ট)',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. Broadcast Hadith Section (Admin Only) ───────────────
              if (isAdmin)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF0D9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                color: Color(0xFFB8860B), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📖 হাদিস ও ইসলামিক বার্তা ব্রডকাস্ট',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'নিজে লিখুন অথবা এপিআই থেকে সরাসরি লোড করে মেম্বারদের পাঠান',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Multiline input field for custom Hadith / Message
                      TextFormField(
                        controller: _hadithTextCtrl,
                        maxLines: 4,
                        minLines: 3,
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText:
                              'হাদিস বা ইসলামিক রিমাইন্ডার এখানে লিখুন (অথবা নিচের বাটন চেপে এপিআই থেকে লোড করুন)...',
                          hintStyle: GoogleFonts.nunito(
                              fontSize: 13, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF9FBF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Narrator / Reference input
                      TextFormField(
                        controller: _narratorCtrl,
                        style: GoogleFonts.nunito(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          labelText: 'বর্ণনাকারী / রেফারেন্স',
                          hintText: 'যেমন: সহীহ বুখারী বা অফিস এডমিন',
                          isDense: true,
                          prefixIcon: const Icon(Icons.bookmark_border,
                              color: AppColors.primary, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF9FBF9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Buttons
                      Row(
                        children: [
                          // Button 1: Load from API
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _loadingHadithApi
                                  ? null
                                  : _loadHadithFromApi,
                              icon: _loadingHadithApi
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.auto_stories_rounded,
                                      size: 16),
                              label: Text(
                                _loadingHadithApi ? 'লোড হচ্ছে...' : 'এপিআই থেকে আনুন',
                                style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Button 2: Broadcast to group
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendingHadith
                                  ? null
                                  : _broadcastHadith,
                              icon: _sendingHadith
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 16),
                              label: Text(
                                _sendingHadith ? 'পাঠানো হচ্ছে...' : 'মেম্বারদের পাঠান',
                                style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── 4. Members List ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👥 মেম্বার তালিকা (${group.memberCount} জন)',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...group.members.map((m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              m.name.isNotEmpty
                                  ? m.name.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: GoogleFonts.nunito(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          title: Text(
                            m.name,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            m.email,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          trailing: m.isAdmin
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'এডমিন',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                )
                              : null,
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }
}
