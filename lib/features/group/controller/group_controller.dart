import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/firebase/firestore_instance.dart';
import 'package:namaz_alert/core/services/fcm_service.dart';
import 'package:namaz_alert/core/services/hadith_service.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class GroupController extends GetxController {
  final _firestore = AppFirestore.instance;
  final _authController = Get.find<AuthController>();

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToGroups();
    ever(_authController.currentUser, (_) => _listenToGroups());
  }

  /// Real-time Firestore listener for user's groups
  void _listenToGroups() {
    final uid = _authController.currentUser.value?.uid ??
        _authController.currentUser.value?.uid;
    if (uid == null) return;

    _firestore
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      groups.assignAll(
          snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList());
      for (final g in groups) {
        _scheduleGroupNotifications(g);
      }
    }, onError: (e) {
      // ignore: avoid_print
      print('Listen to groups error: $e');
    });
  }

  /// Create a new group and save to Firestore
  Future<void> createGroup({
    required String name,
    required String city,
    required String country,
    int offsetMinutes = 10,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      var user = _authController.currentUser.value;
      user ??= await _authController.ensureUserLoaded();

      if (user == null) {
        errorMessage.value = 'User not logged in. Please restart app.';
        Get.snackbar(
          'Authentication Required',
          'User session not found. Please re-login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      final group = GroupModel.create(
        name: name,
        adminUid: user.uid,
        adminName: user.name,
        adminEmail: user.email,
        city: city,
        country: country,
        offsetMinutes: offsetMinutes,
      );

      // 1. Save group to Firestore
      await _firestore.collection('groups').doc(group.id).set({
        ...group.toJson(),
        // Store member UIDs separately for Firestore array-contains queries
        'memberUids': [user.uid],
      });

      // 2. Keep invite-code lookup separate
      await _firestore.collection('groupInvites').doc(group.inviteCode).set({
        'groupId': group.id,
      });

      // 3. Update user's groupIds in Firestore (using merge: true so it creates or updates safely)
      await _firestore.collection('users').doc(user.uid).set({
        'groupIds': FieldValue.arrayUnion([group.id]),
      }, SetOptions(merge: true));

      // 4. Subscribe to FCM topic for group broadcasts
      try {
        await FcmService.subscribeToGroup(group.id);
      } catch (e) {
        // ignore: avoid_print
        print('FCM subscribe error (non-fatal): $e');
      }

      // 5. Schedule prayer notifications
      try {
        await _scheduleGroupNotifications(group);
      } catch (e) {
        // ignore: avoid_print
        print('Schedule notifications error (non-fatal): $e');
      }

      // Re-listen so new group appears immediately
      _listenToGroups();

      Get.back();
      Get.snackbar(
        '✅ Group Created!',
        'Invite code: ${group.inviteCode} — share with your team',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Group create error: $e');
      errorMessage.value = 'Failed to create group: $e';
      Get.snackbar(
        'Error Creating Group',
        e.toString(),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Join a group by invite code (looks up Firestore)
  Future<void> joinGroup(String inviteCode) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final invite = await _firestore
          .collection('groupInvites')
          .doc(inviteCode.toUpperCase())
          .get();

      if (!invite.exists || invite.data() == null) {
        errorMessage.value = 'Invalid invite code. Group not found.';
        Get.snackbar(
          'Code Not Found',
          'No active group found for this code.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      final groupId = invite.data()!['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) {
        errorMessage.value = 'Invalid invite code. Group not found.';
        return;
      }

      var user = _authController.currentUser.value;
      user ??= await _authController.ensureUserLoaded();

      if (user == null) {
        errorMessage.value = 'Please log in first.';
        return;
      }

      final newMember = GroupMember(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: 'member',
      );

      // Add member to Firestore group doc
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([newMember.toJson()]),
        'memberUids': FieldValue.arrayUnion([user.uid]),
      });

      // Update user's groupIds safely
      await _firestore.collection('users').doc(user.uid).set({
        'groupIds': FieldValue.arrayUnion([groupId]),
      }, SetOptions(merge: true));

      // Subscribe to FCM topic
      try {
        await FcmService.subscribeToGroup(groupId);
      } catch (_) {}

      // The user is now a member and can read the group details.
      final joinedGroupSnapshot =
          await _firestore.collection('groups').doc(groupId).get();
      if (joinedGroupSnapshot.exists && joinedGroupSnapshot.data() != null) {
        final joinedGroup = GroupModel.fromJson(joinedGroupSnapshot.data()!);
        try {
          await _scheduleGroupNotifications(joinedGroup);
        } catch (_) {}
      }

      _listenToGroups();

      Get.back();
      Get.snackbar(
        '🎉 Joined!',
        'You successfully joined the group',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Group join error: $e');
      errorMessage.value = 'Failed to join group: $e';
      Get.snackbar(
        'Error Joining Group',
        e.toString(),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notification settings for a group (admin only)
  Future<void> updateNotificationSettings(
    String groupId,
    GroupNotificationSettings settings,
  ) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'notificationSettings': settings.toJson(),
      });

      // Reschedule notifications
      final group = getGroupById(groupId);
      if (group != null) {
        final updated = group.copyWith(notificationSettings: settings);
        await _scheduleGroupNotifications(updated);
      }

      Get.snackbar(
        '✅ Saved',
        'Notification settings updated',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update settings.');
    }
  }

  /// Broadcast hadith to group members via FCM
  Future<void> broadcastHadith({
    required String groupId,
    required String hadithText,
    required String narrator,
  }) async {
    final group = getGroupById(groupId);
    if (group == null) return;

    await FcmService.broadcastHadithToGroup(
      groupId: groupId,
      hadithText: hadithText,
      narrator: narrator,
      groupName: group.name,
    );
  }

  /// Update custom prayer times for a group (admin only)
  Future<void> updateCustomPrayerTimes(
    String groupId,
    Map<String, String> prayerTimes,
  ) async {
    try {
      await _firestore.collection('groups').doc(groupId).set({
        'customPrayerTimes': prayerTimes,
      }, SetOptions(merge: true));

      // Reschedule notifications with new custom times safely
      try {
        final group = getGroupById(groupId);
        if (group != null) {
          final updated = group.copyWith(customPrayerTimes: prayerTimes);
          await _scheduleGroupNotifications(updated);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Reschedule notifications error (non-fatal): $e');
      }

      Get.snackbar(
        '✅ নামাজের সময় সংরক্ষিত!',
        'গ্রুপের নামাজের সময়সূচি সফলভাবে আপডেট হয়েছে',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'ত্রুটি',
        'নামাজের সময় আপডেট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Schedule local notifications based on group prayer settings (supports custom times)
  Future<void> _scheduleGroupNotifications(GroupModel group) async {
    PrayerTimeModel? prayerTimes;
    try {
      prayerTimes = await PrayerService.fetchByCity(
        city: group.city,
        country: group.country,
        method: group.calculationMethod,
      );
    } catch (_) {}

    final settings = group.notificationSettings;
    final enabledMap = settings.enabledMap;
    int notifId = group.id.hashCode.abs() % 1000;

    for (final name in AppConstants.namazNames) {
      if (enabledMap[name] == true) {
        // Prefer custom prayer time if set by group admin, else fallback to API
        String? timeStr = group.customPrayerTimes[name];
        timeStr ??= prayerTimes?.allPrayers[name];

        if (timeStr != null && timeStr.isNotEmpty) {
          final cleanTime = timeStr.split(' ').first.trim();
          final parts = cleanTime.split(':');
          final now = DateTime.now();

          int rawHour = int.tryParse(parts[0]) ?? 0;
          final int rawMinute =
              int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

          // Smart AM/PM correction:
          // Dhuhr, Asr, Maghrib, Isha are PM prayers. If user picked 1:00 for Dhuhr, it's 13:00 (1:00 PM)!
          if (name == 'Dhuhr' && rawHour < 11) rawHour += 12;
          if (name == 'Asr' && rawHour < 12) rawHour += 12;
          if (name == 'Maghrib' && rawHour < 12) rawHour += 12;
          if (name == 'Isha' && rawHour < 12) rawHour += 12;
          if (name == 'Fajr' && rawHour >= 12) rawHour -= 12;

          final prayerDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            rawHour.clamp(0, 23),
            rawMinute.clamp(0, 59),
          );

          // Attach a curated/API Hadith to the scheduled notification
          String? hadithForNotification;
          try {
            final hadith = await HadithService.fetchRandom();
            hadithForNotification =
                '${hadith.fullText}\n— ${hadith.bookDisplayName}';
          } catch (_) {}

          await NotificationService.scheduleNamazNotification(
            id: notifId++,
            namazName: name,
            prayerTime: prayerDateTime,
            offsetMinutes: settings.offsetMinutes,
            hadithText: hadithForNotification,
          );
        }
      }
    }
  }

  GroupModel? getGroupById(String id) =>
      groups.firstWhereOrNull((g) => g.id == id);

  List<GroupModel> get myGroups {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return [];
    return groups.where((g) => g.isMember(uid)).toList();
  }
}
