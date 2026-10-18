import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/services/adhan_audio_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'stop_sound') {
    AdhanAudioService.stopAdhan();
    NotificationService.muteNotification(
      id: notificationResponse.id ?? 8888,
      payload: notificationResponse.payload,
    );
  }
}

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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Delete older cached channels so Android OS updates sound and importance
    await androidImpl?.deleteNotificationChannel('namaz_adhan_channel_v1');
    await androidImpl?.deleteNotificationChannel('namaz_channel_v4');
    await androidImpl?.deleteNotificationChannel('namaz_channel_v3');
    await androidImpl?.deleteNotificationChannel('namaz_channel_v2');
    await androidImpl?.deleteNotificationChannel('namaz_channel');

    const adhanSound = RawResourceAndroidNotificationSound('adhan');

    const namazChannel = AndroidNotificationChannel(
      AppConstants.namazChannelId,
      AppConstants.namazChannelName,
      description: 'Notifications for upcoming namaz times with Adhan alarm sound',
      importance: Importance.max,
      playSound: true,
      sound: adhanSound,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const hadithChannel = AndroidNotificationChannel(
      AppConstants.hadithChannelId,
      AppConstants.hadithChannelName,
      description: 'Daily hadith and group broadcast notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const silentChannel = AndroidNotificationChannel(
      'namaz_silent_channel',
      'Namaz Silent Alerts',
      description: 'Notifications for namaz times after mute',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await androidImpl?.createNotificationChannel(namazChannel);
    await androidImpl?.createNotificationChannel(hadithChannel);
    await androidImpl?.createNotificationChannel(silentChannel);
  }

  static Future<void> _onNotificationTap(NotificationResponse response) async {
    if (response.actionId == 'stop_sound') {
      await AdhanAudioService.stopAdhan();
      await muteNotification(
        id: response.id ?? 8888,
        payload: response.payload,
      );
    }
  }

  /// Mute the audio and update the active notification to stay silently without the button
  static Future<void> muteNotification({
    required int id,
    String? payload,
    String? title,
    String? body,
  }) async {
    await AdhanAudioService.stopAdhan();

    String displayTitle = title ?? '🕌 নামাজের সময় সতর্কতা';
    String displayBody = body ?? '🔕 আজান মিউট করা হয়েছে। নামাজের সময় নিকটবর্তী।';

    if (payload != null && payload.contains('|')) {
      final parts = payload.split('|');
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        displayTitle = parts[0];
      }
      if (parts.length > 1 && parts[1].isNotEmpty) {
        displayBody = '${parts[1]}\n\n(🔕 আজান মিউট করা হয়েছে)';
      }
    }

    final silentDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'namaz_silent_channel',
        'Namaz Silent Alerts',
        channelDescription: 'Notifications for namaz times after mute',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        silent: true,
        enableVibration: false,
        styleInformation: BigTextStyleInformation(
          displayBody,
          contentTitle: displayTitle,
          summaryText: 'নামাজ সতর্কতা (মিউট)',
        ),
        color: const Color(0xFF1B5E20),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      ),
    );

    await _plugin.show(
      id,
      displayTitle,
      displayBody,
      silentDetails,
      payload: payload,
    );
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
        channelDescription: 'Namaz time notification with Adhan alarm sound',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_sound',
            '🔕 আজান বন্ধ করুন',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
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
        payload: '$title|$body',
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
          payload: '$title|$body',
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
        channelDescription: 'Test notification with Adhan sound',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: [
          AndroidNotificationAction(
            'stop_sound',
            '🔕 আজান বন্ধ করুন',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
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

    const testPayload =
        '🔔 টেস্ট অ্যালার্ট: আজান ও নামাজ অ্যালার্ট!|টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে।';

    try {
      await _plugin.zonedSchedule(
        8888,
        '🔔 টেস্ট অ্যালার্ট: আজান ও নামাজ অ্যালার্ট!',
        'টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে। আজানের ধ্বনি শোনা যাচ্ছে।',
        scheduledDate,
        details,
        payload: testPayload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          8888,
          '🔔 টেস্ট অ্যালার্ট: আজান ও নামাজ অ্যালার্ট!',
          'টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে।',
          scheduledDate,
          details,
          payload: testPayload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _plugin.show(
          8888,
          '🔔 টেস্ট অ্যালার্ট: আজান ও নামাজ অ্যালার্ট!',
          'টেস্ট নোটিফিকেশন সফলভাবে ট্রিগার হয়েছে।',
          details,
          payload: testPayload,
        );
      }
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


