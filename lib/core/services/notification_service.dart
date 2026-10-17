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

    // Create notification channels
    await _createChannels();
  }

  static Future<void> _createChannels() async {
    const namazChannel = AndroidNotificationChannel(
      AppConstants.namazChannelId,
      AppConstants.namazChannelName,
      description: 'Notifications for upcoming namaz times',
      importance: Importance.high,
      playSound: true,
    );

    const hadithChannel = AndroidNotificationChannel(
      AppConstants.hadithChannelId,
      AppConstants.hadithChannelName,
      description: 'Daily hadith and group broadcast notifications',
      importance: Importance.defaultImportance,
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
    final notifyAt = prayerTime.subtract(Duration(minutes: offsetMinutes));
    if (notifyAt.isBefore(DateTime.now())) return;

    final body = hadithText != null
        ? '⏰ $offsetMinutes min left\n📖 $hadithText'
        : '⏰ $offsetMinutes minutes until $namazName prayer';

    await _plugin.zonedSchedule(
      id,
      '🕌 $namazName — $offsetMinutes min remaining',
      body,
      tz.TZDateTime.from(notifyAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.namazChannelId,
          AppConstants.namazChannelName,
          channelDescription: 'Namaz time notification',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
          color: const Color(0xFF1B5E20),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'namaz',
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Send an immediate Hadith notification (from group broadcast)
  static Future<void> showHadithNotification({
    required String groupName,
    required String hadithText,
    required String narrator,
  }) async {
    const id = 9999;
    const title = '📖 Hadith from your group';
    final body = '"$hadithText"\n— $narrator';

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.hadithChannelId,
          AppConstants.hadithChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
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


