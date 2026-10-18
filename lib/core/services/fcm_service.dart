import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/services/notification_service.dart';

/// Background FCM message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final text = message.data['hadithText'] ?? message.notification?.body ?? '';
  if (text.isNotEmpty) {
    await NotificationService.showHadithNotification(
      groupName: message.data['groupName'] ?? '',
      hadithText: text,
      narrator: message.data['narrator'] ?? '',
    );
  }
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _storage = GetStorage();

  /// Initialize FCM — request permission, get token, setup handlers
  static Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        _saveToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background message handler
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    }
  }

  static void _saveToken(String token) {
    _storage.write(AppConstants.keyFcmToken, token);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'NamazAlert';
    final body = message.notification?.body ?? '';
    final data = message.data;
    final text = data['hadithText'] ?? body;

    if (text.isNotEmpty) {
      await NotificationService.showHadithNotification(
        groupName: data['groupName'] ?? (data['type'] == 'hadith' ? '' : title),
        hadithText: text,
        narrator: data['narrator'] ?? '',
      );
    }
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    // Navigate based on notification type
    final type = message.data['type'];
    if (type == 'group') {
      final groupId = message.data['groupId'];
      if (groupId != null) {
        Get.toNamed('/group-detail', arguments: groupId);
      }
    }
  }

  /// Get current saved FCM token
  static String? get currentToken =>
      _storage.read<String>(AppConstants.keyFcmToken);

  /// Subscribe to a group topic (for group broadcasts)
  static Future<void> subscribeToGroup(String groupId) async {
    await _messaging.subscribeToTopic('group_$groupId');
  }

  /// Unsubscribe from a group topic
  static Future<void> unsubscribeFromGroup(String groupId) async {
    await _messaging.unsubscribeFromTopic('group_$groupId');
  }

  /// Send a Hadith broadcast to group (admin only)
  /// In production: call your Cloud Function or backend API
  static Future<void> broadcastHadithToGroup({
    required String groupId,
    required String hadithText,
    required String narrator,
    required String groupName,
  }) async {
    // TODO: Replace with your Cloud Function HTTP call
    // Example with Dio:
    // await Dio().post(
    //   'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/sendGroupHadith',
    //   data: {
    //     'groupId': groupId,
    //     'hadithText': hadithText,
    //     'narrator': narrator,
    //     'groupName': groupName,
    //   },
    // );

    // For now: show local notification only (demo mode)
    await NotificationService.showHadithNotification(
      groupName: groupName,
      hadithText: hadithText,
      narrator: narrator,
    );
  }
}
