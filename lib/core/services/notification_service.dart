import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:namaz_alert/core/constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request Android 13+ Notification & Exact Alarm permissions
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (_) {}

    // Create notification channels
    await _createChannels();
  }

  static Future<void> _createChannels() async {
    const namazChannel = AndroidNotificationChannel(
      AppConstants.namazChannelId,
      AppConstants.namazChannelName,
      description: 'Notifications for upcoming namaz times',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const hadithChannel = AndroidNotificationChannel(
      AppConstants.hadithChannelId,
      AppConstants.hadithChannelName,
      description: 'Daily hadith and group broadcast notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(namazChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(hadithChannel);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
  }

  /// Schedule a namaz notification at [scheduledTime] minus [offsetMinutes]
  static Future<void> scheduleNamazNotification({
    required int id,
    required String namazName,
    required DateTime prayerTime,
    required int offsetMinutes,
    String? hadithText,
  }) async {
    final now = DateTime.now();
    var notifyAt = prayerTime.subtract(Duration(minutes: offsetMinutes));

    final title = '🕌 $namazName — $offsetMinutes min remaining';
    final body = hadithText != null
        ? '⏰ $offsetMinutes min left until $namazName\n\n📖 হাদিস:\n$hadithText'
        : '⏰ $offsetMinutes minutes until $namazName prayer';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.namazChannelId,
        AppConstants.namazChannelName,
        channelDescription: 'Namaz time notification',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'নামাজের সময় সতর্কতা',
        ),
        color: const Color(0xFF1B5E20),
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'namaz',
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );

    // If prayer is today in the future, but offset time (e.g. 10m before) already passed:
    // (e.g. user set prayer for 2:00 PM at 1:55 PM, so 1:50 PM was 5m ago)
    // Alert immediately so they get alerted in 3 seconds instead of waiting for tomorrow!
    if (prayerTime.isAfter(now) && notifyAt.isBefore(now)) {
      final remainingMin = prayerTime.difference(now).inMinutes;
      final quickTitle = '🕌 $namazName — আর মাত্র $remainingMin মিনিট বাকি!';
      final quickBody = hadithText != null
          ? '⏰ $namazName এর জামায়াত শুরু হতে $remainingMin মিনিট বাকি।\n\n📖 হাদিস:\n$hadithText'
          : '⏰ আর $remainingMin মিনিট পর $namazName এর জামায়াত শুরু হবে।';

      try {
        await _plugin.zonedSchedule(
          id + 500,
          quickTitle,
          quickBody,
          tz.TZDateTime.from(now.add(const Duration(seconds: 3)), tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _plugin.show(id + 500, quickTitle, quickBody, details);
      }
      notifyAt = notifyAt.add(const Duration(days: 1));
    } else if (notifyAt.isBefore(now)) {
      // If today's alarm time has already passed, schedule for tomorrow at the same time
      notifyAt = notifyAt.add(const Duration(days: 1));
    }

    tz.TZDateTime scheduledDate;
    try {
      scheduledDate = tz.TZDateTime.from(notifyAt, tz.local);
    } catch (_) {
      try {
        scheduledDate =
            tz.TZDateTime.from(notifyAt, tz.getLocation('Asia/Dhaka'));
      } catch (_) {
        scheduledDate = tz.TZDateTime.from(notifyAt, tz.UTC);
      }
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Fallback to inexact if exact alarm permission is not granted on this device
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        // ignore: avoid_print
        print('zonedSchedule error: $e');
      }
    }
  }

  /// Schedule a quick test notification in [seconds] seconds
  static Future<void> scheduleTestNotification({int seconds = 5}) async {
    final notifyAt = DateTime.now().add(Duration(seconds: seconds));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.namazChannelId,
        AppConstants.namazChannelName,
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Color(0xFF1B5E20),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    tz.TZDateTime scheduledDate;
    try {
      scheduledDate = tz.TZDateTime.from(notifyAt, tz.local);
    } catch (_) {
      scheduledDate = tz.TZDateTime.from(notifyAt, tz.UTC);
    }

    try {
      await _plugin.zonedSchedule(
        8888,
        '🔔 টেস্ট অ্যালার্ট: নামাজ অ্যালার্ট কাজ করছে!',
        'এইমাত্র আপনার ফোনে টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে।',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.show(
        8888,
        '🔔 টেস্ট অ্যালার্ট: নামাজ অ্যালার্ট কাজ করছে!',
        'এইমাত্র আপনার ফোনে টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে।',
        details,
      );
    }
  }

  /// Send an immediate Hadith notification (from group broadcast)
  static Future<void> showHadithNotification({
    required String groupName,
    required String hadithText,
    required String narrator,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final title = groupName.isNotEmpty
        ? '📖 হাদিস সতর্কতা ($groupName)'
        : '📖 হাদিস সতর্কতা';
    final body = narrator.isNotEmpty
        ? '$hadithText\n\n— $narrator'
        : hadithText;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.hadithChannelId,
          AppConstants.hadithChannelName,
          channelDescription: 'Daily hadith and group broadcast notifications',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: groupName.isNotEmpty ? groupName : 'NamazAlert',
          ),
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1B5E20),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification by id
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}


