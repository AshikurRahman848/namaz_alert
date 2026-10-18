import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/firebase/firestore_instance.dart';
import 'package:namaz_alert/core/services/fcm_service.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';

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
      groups.value =
          snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList();
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
      if (user == null) {
        // Fallback to active firebase auth user
        user = await _authController.ensureUserLoaded();
      }

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
      if (user == null) {
        user = await _authController.ensureUserLoaded();
      }

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

  /// Schedule local notifications based on group prayer settings
  Future<void> _scheduleGroupNotifications(GroupModel group) async {
    final prayerTimes = await PrayerService.fetchByCity(
      city: group.city,
      country: group.country,
      method: group.calculationMethod,
    );

    if (prayerTimes == null) return;

    final settings = group.notificationSettings;
    final enabledMap = settings.enabledMap;
    final prayers = prayerTimes.allPrayers;
    int notifId = group.id.hashCode.abs() % 1000;

    for (final entry in prayers.entries) {
      if (enabledMap[entry.key] == true) {
        final prayerDateTime = prayerTimes.toDateTime(entry.value);
        await NotificationService.scheduleNamazNotification(
          id: notifId++,
          namazName: entry.key,
          prayerTime: prayerDateTime,
          offsetMinutes: settings.offsetMinutes,
        );
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
