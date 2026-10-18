import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/services/fcm_service.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';

class GroupController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _authController = Get.find<AuthController>();

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToGroups();
  }

  /// Real-time Firestore listener for user's groups
  void _listenToGroups() {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return;

    _firestore
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      groups.value = snapshot.docs
          .map((doc) => GroupModel.fromJson(doc.data()))
          .toList();
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
      final user = _authController.currentUser.value!;
      final group = GroupModel.create(
        name: name,
        adminUid: user.uid,
        adminName: user.name,
        adminEmail: user.email,
        city: city,
        country: country,
        offsetMinutes: offsetMinutes,
      );

      // Save to Firestore
      await _firestore.collection('groups').doc(group.id).set({
        ...group.toJson(),
        // Store member UIDs separately for Firestore array-contains queries
        'memberUids': [user.uid],
      });

      // Update user's groupIds in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'groupIds': FieldValue.arrayUnion([group.id]),
      });

      // Subscribe to FCM topic for group broadcasts
      await FcmService.subscribeToGroup(group.id);

      // Schedule prayer notifications
      await _scheduleGroupNotifications(group);

      // Re-listen so new group appears
      _listenToGroups();

      Get.back();
      Get.snackbar(
        '✅ Group Created!',
        'Invite code: ${group.inviteCode} — share with your team',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      errorMessage.value = 'Failed to create group. Check internet.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Join a group by invite code (looks up Firestore)
  Future<void> joinGroup(String inviteCode) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Search Firestore for group with this invite code
      final query = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        errorMessage.value = 'Invalid invite code. Group not found.';
        return;
      }

      final group = GroupModel.fromJson(query.docs.first.data());
      final user = _authController.currentUser.value!;

      if (group.isMember(user.uid)) {
        errorMessage.value = 'You are already in this group.';
        return;
      }

      final newMember = GroupMember(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: 'member',
      );

      // Add member to Firestore group doc
      await _firestore.collection('groups').doc(group.id).update({
        'members': FieldValue.arrayUnion([newMember.toJson()]),
        'memberUids': FieldValue.arrayUnion([user.uid]),
      });

      // Update user's groupIds
      await _firestore.collection('users').doc(user.uid).update({
        'groupIds': FieldValue.arrayUnion([group.id]),
      });

      // Subscribe to FCM topic
      await FcmService.subscribeToGroup(group.id);

      // Schedule prayer notifications
      await _scheduleGroupNotifications(group);

      Get.back();
      Get.snackbar(
        '🎉 Joined!',
        'You joined "${group.name}"',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      errorMessage.value = 'Failed to join group.';
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
