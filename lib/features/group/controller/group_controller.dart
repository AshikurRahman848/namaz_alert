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
import 'package:namaz_alert/features/prayer/controller/prayer_controller.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class GroupController extends GetxController {
  final _firestore = AppFirestore.instance;
  final _authController = Get.find<AuthController>();

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxList<GroupModel> pendingGroups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToGroups();
    ever(_authController.currentUser, (_) {
      _listenToGroups();
      syncPrayerNotifications();
    });
  }

  /// Real-time Firestore listener for user's groups and pending requests
  void _listenToGroups() {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) {
      syncPrayerNotifications();
      return;
    }

    // Listen to groups where user is an active member
    _firestore
        .collection('groups')
        .where('memberUids', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      groups.assignAll(
          snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList());
      syncPrayerNotifications();
    }, onError: (e) {
      // ignore: avoid_print
      print('Listen to groups error: $e');
    });

    // Listen to groups where user has sent a pending join request
    _firestore
        .collection('groups')
        .where('pendingRequestUids', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      pendingGroups.assignAll(
          snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList());
    }, onError: (e) {
      // ignore: avoid_print
      print('Listen to pending groups error: $e');
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
        'groupName': group.name,
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

  /// Search groups by invite code or group name
  /// Non-members can only see the group name and send join request.
  Future<List<Map<String, dynamic>>> searchGroups(String query) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final q = query.trim();
      if (q.isEmpty) {
        errorMessage.value = 'অনুগ্রহ করে ইনভাইট কোড বা গ্রুপের নাম লিখুন।';
        return [];
      }

      final Map<String, Map<String, dynamic>> resultsMap = {};
      final currentUser = _authController.currentUser.value;
      final currentUid = currentUser?.uid ?? '';

      void addGroupDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
        if (!doc.exists || doc.data() == null) return;
        final data = doc.data()!;
        final gId = doc.id;
        final gName = (data['name'] as String?)?.trim() ?? 'Namaz Group';
        final invCode = (data['inviteCode'] as String?)?.trim() ?? '';
        final city = (data['city'] as String?)?.trim() ?? '';
        final memberUids =
            List<String>.from(data['memberUids'] as List<dynamic>? ?? []);
        final pendingUids = List<String>.from(
            data['pendingRequestUids'] as List<dynamic>? ?? []);

        resultsMap[gId] = {
          'groupId': gId,
          'groupName': gName,
          'inviteCode': invCode,
          'city': city,
          'isAlreadyMember': memberUids.contains(currentUid),
          'isPending': pendingUids.contains(currentUid),
        };
      }

      // 1. Check invite code format: e.g. "ABCD" -> "NAM-ABCD"
      String upperCode = q.toUpperCase();
      if (!upperCode.startsWith('NAM-') && upperCode.length == 4) {
        upperCode = 'NAM-$upperCode';
      }

      // 1a. Try lookup in groupInvites
      final inviteDoc =
          await _firestore.collection('groupInvites').doc(upperCode).get();
      if (inviteDoc.exists && inviteDoc.data() != null) {
        final gId = inviteDoc.data()!['groupId'] as String?;
        if (gId != null && gId.isNotEmpty) {
          final gDoc = await _firestore.collection('groups').doc(gId).get();
          addGroupDoc(gDoc);
        }
      }

      // 1b. Direct query in groups by inviteCode
      final codeQuery = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: upperCode)
          .limit(5)
          .get();
      for (final doc in codeQuery.docs) {
        addGroupDoc(doc);
      }

      if (upperCode != q.toUpperCase()) {
        final rawCodeQuery = await _firestore
            .collection('groups')
            .where('inviteCode', isEqualTo: q.toUpperCase())
            .limit(5)
            .get();
        for (final doc in rawCodeQuery.docs) {
          addGroupDoc(doc);
        }
      }

      // 2. Search by group name (case-insensitive substring)
      final allGroupsQuery =
          await _firestore.collection('groups').limit(50).get();
      final lowerQ = q.toLowerCase();
      for (final doc in allGroupsQuery.docs) {
        final data = doc.data();
        final name = (data['name'] as String? ?? '').toLowerCase();
        final code = (data['inviteCode'] as String? ?? '').toLowerCase();
        if (name.contains(lowerQ) || code.contains(lowerQ)) {
          addGroupDoc(doc);
        }
      }

      if (resultsMap.isEmpty) {
        errorMessage.value =
            'কোনো গ্রুপ পাওয়া যায়নি। সঠিক কোড বা নাম দিয়ে আবার চেষ্টা করুন।';
      }

      return resultsMap.values.toList();
    } catch (e) {
      // ignore: avoid_print
      print('Search groups error: $e');
      errorMessage.value = 'গ্রুপ খুঁজতে ত্রুটি হয়েছে: $e';
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Look up group by invite code and return ONLY public summary (name & status)
  /// Non-members can only see the group name.
  Future<Map<String, dynamic>?> lookupGroupByCode(String inviteCode) async {
    final list = await searchGroups(inviteCode);
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  /// Send a join request to the group admin
  Future<bool> sendJoinRequest(String groupId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      var user = _authController.currentUser.value;
      user ??= await _authController.ensureUserLoaded();

      if (user == null) {
        errorMessage.value = 'Please log in first.';
        return false;
      }

      final request = GroupJoinRequest(
        uid: user.uid,
        name: user.name.isNotEmpty
            ? user.name
            : (user.email.isNotEmpty ? user.email.split('@').first : 'User'),
        email: user.email,
        requestedAt: DateTime.now(),
      );

      await _firestore.collection('groups').doc(groupId).update({
        'joinRequests': FieldValue.arrayUnion([request.toJson()]),
        'pendingRequestUids': FieldValue.arrayUnion([user.uid]),
      });

      Get.snackbar(
        '✅ অনুরোধ পাঠানো হয়েছে!',
        'গ্রুপের অ্যাডমিন আপনার রিকোয়েস্ট অনুমোদন (Approve) করলে আপনি গ্রুপে যুক্ত হবেন।',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Send join request error: $e');
      errorMessage.value = 'Failed to send request: $e';
      Get.snackbar(
        'Error',
        e.toString(),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve a pending join request (Admin only)
  Future<void> approveJoinRequest({
    required String groupId,
    required GroupJoinRequest request,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final newMember = GroupMember(
        uid: request.uid,
        name: request.name,
        email: request.email,
        role: 'member',
      );

      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([newMember.toJson()]),
        'memberUids': FieldValue.arrayUnion([request.uid]),
        'joinRequests': FieldValue.arrayRemove([request.toJson()]),
        'pendingRequestUids': FieldValue.arrayRemove([request.uid]),
      });

      // Update approved user's groupIds in Firestore
      await _firestore.collection('users').doc(request.uid).set({
        'groupIds': FieldValue.arrayUnion([groupId]),
      }, SetOptions(merge: true));

      Get.snackbar(
        '✅ অনুমোদন সফল!',
        '${request.name} কে গ্রুপে মেম্বার হিসেবে যুক্ত করা হয়েছে।',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Approve request error: $e');
      Get.snackbar(
        'Error',
        'অনুমোদন ব্যর্থ হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject a pending join request (Admin only)
  Future<void> rejectJoinRequest({
    required String groupId,
    required GroupJoinRequest request,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _firestore.collection('groups').doc(groupId).update({
        'joinRequests': FieldValue.arrayRemove([request.toJson()]),
        'pendingRequestUids': FieldValue.arrayRemove([request.uid]),
      });

      Get.snackbar(
        'অনুরোধ বাতিল',
        '${request.name} এর যোগদানের অনুরোধ বাতিল করা হয়েছে।',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Reject request error: $e');
      Get.snackbar(
        'Error',
        'বাতিল করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Promote a member to Admin role (Admin only)
  Future<bool> promoteMemberToAdmin({
    required String groupId,
    required String memberUid,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final docRef = _firestore.collection('groups').doc(groupId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        errorMessage.value = 'Group not found.';
        return false;
      }

      final data = doc.data()!;
      final membersList = (data['members'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      bool found = false;
      String memberName = '';
      for (final m in membersList) {
        if (m['uid'] == memberUid) {
          m['role'] = 'admin';
          memberName = m['name'] as String? ?? 'Member';
          found = true;
          break;
        }
      }

      if (!found) {
        errorMessage.value = 'Member not found in group.';
        return false;
      }

      await docRef.update({
        'members': membersList,
      });

      Get.snackbar(
        '👑 অ্যাডমিন যুক্ত করা হয়েছে',
        '$memberName এখন এই গ্রুপের অ্যাডমিন।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Promote member to admin error: $e');
      errorMessage.value = 'Failed to make admin: $e';
      Get.snackbar(
        'Error',
        'অ্যাডমিন করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Demote an admin back to regular member (Admin only)
  Future<bool> demoteAdminToMember({
    required String groupId,
    required String memberUid,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final docRef = _firestore.collection('groups').doc(groupId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        errorMessage.value = 'Group not found.';
        return false;
      }

      final data = doc.data()!;
      final adminUid = data['adminUid'] as String? ?? '';
      if (memberUid == adminUid) {
        Get.snackbar(
          'সতর্কতা',
          'মূল গ্রুপের প্রধান ক্রিয়েটরকে মেম্বার করা সম্ভব নয়।',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
        return false;
      }

      final membersList = (data['members'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      bool found = false;
      String memberName = '';
      for (final m in membersList) {
        if (m['uid'] == memberUid) {
          m['role'] = 'member';
          memberName = m['name'] as String? ?? 'Member';
          found = true;
          break;
        }
      }

      if (!found) {
        errorMessage.value = 'Member not found in group.';
        return false;
      }

      await docRef.update({
        'members': membersList,
      });

      Get.snackbar(
        'পদবী পরিবর্তন',
        '$memberName কে সাধারণ মেম্বার করা হয়েছে।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Demote admin to member error: $e');
      errorMessage.value = 'Failed to demote admin: $e';
      Get.snackbar(
        'Error',
        'পরিবর্তন ব্যর্থ হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Transfer primary group ownership (Creator only)
  Future<bool> transferGroupOwnership({
    required String groupId,
    required String newAdminUid,
  }) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final docRef = _firestore.collection('groups').doc(groupId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        errorMessage.value = 'Group not found.';
        return false;
      }

      final data = doc.data()!;
      final membersList = (data['members'] as List<dynamic>? ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      for (final m in membersList) {
        if (m['uid'] == newAdminUid) {
          m['role'] = 'admin';
        }
      }

      await docRef.update({
        'adminUid': newAdminUid,
        'members': membersList,
      });

      Get.snackbar(
        '👑 ওনারশিপ ট্রান্সফার সম্পন্ন',
        'নতুন প্রধান অ্যাডমিন নির্ধারণ করা হয়েছে।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Transfer ownership error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notification settings for a group (admin only)
  Future<void> updateNotificationSettings(
    String groupId,
    GroupNotificationSettings settings,
  ) async {
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return;
    }

    try {
      final groupIdx = groups.indexWhere((g) => g.id == groupId);
      if (groupIdx != -1) {
        groups[groupIdx] = groups[groupIdx].copyWith(
          notificationSettings: settings,
        );
      }

      await _firestore.collection('groups').doc(groupId).update({
        'notificationSettings': settings.toJson(),
      });

      // Reschedule notifications
      await syncPrayerNotifications();

      Get.snackbar(
        '✅ Saved',
        'Notification settings updated',
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update settings: $e');
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
    final user = _authController.currentUser.value;
    if (user == null) {
      Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
      return;
    }

    try {
      final groupIdx = groups.indexWhere((g) => g.id == groupId);
      if (groupIdx != -1) {
        groups[groupIdx] = groups[groupIdx].copyWith(
          customPrayerTimes: prayerTimes,
        );
      }

      await _firestore.collection('groups').doc(groupId).set({
        'customPrayerTimes': prayerTimes,
      }, SetOptions(merge: true));

      // Reschedule notifications with new custom times safely
      await syncPrayerNotifications();

      Get.snackbar(
        '✅ নামাজের সময় সংরক্ষিত!',
        'গ্রুপের নামাজের সময়সূচি ও আজানের অ্যালার্ট সফলভাবে আপডেট হয়েছে',
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
        'নামাজের সময় আপডেট করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Centralized notification sync:
  /// - If user has joined a group (myGroups.isNotEmpty):
  ///   Cancel any prior notifications, and schedule strictly from the active group's times.
  /// - If user has NOT joined any group (myGroups.isEmpty):
  ///   Cancel any prior notifications, and schedule strictly from the API prayer times.
  Future<void> syncPrayerNotifications() async {
    try {
      // 1. Cancel all previous notifications first to prevent duplicates/ghost alarms
      await NotificationService.cancelAll();

      final activeGroups = myGroups;

      if (activeGroups.isNotEmpty) {
        // ── USER IS IN A GROUP ──
        // Schedule strictly based on the group's prayer settings
        final group = activeGroups.first;
        await _scheduleGroupNotifications(group);
        debugPrint('🔔 [Sync] Scheduled strictly for group: "${group.name}"');
      } else {
        // ── USER HAS NO GROUP ──
        // Schedule strictly based on the API prayer times
        PrayerTimeModel? prayers;
        if (Get.isRegistered<PrayerController>()) {
          prayers = Get.find<PrayerController>().todayPrayers.value;
        }
        prayers ??= await PrayerService.fetchByCity(
          city: AppConstants.defaultCity,
          country: AppConstants.defaultCountry,
        );
        if (prayers != null) {
          await _scheduleApiPrayerNotifications(prayers);
          debugPrint(
              '🔔 [Sync] User has no group. Scheduled strictly from API prayer times.');
        }
      }
    } catch (e) {
      debugPrint('Sync prayer notifications error: $e');
    }
  }

  /// Schedule notifications strictly from API prayer times (when user has no group)
  Future<void> _scheduleApiPrayerNotifications(PrayerTimeModel prayers) async {
    final now = DateTime.now();
    int notifId = 100;

    for (final name in AppConstants.namazNames) {
      final timeStr = prayers.allPrayers[name];
      if (timeStr == null || timeStr.isEmpty) continue;

      final cleanTime = timeStr.split(' ').first.trim();
      final parts = cleanTime.split(':');
      if (parts.isEmpty) continue;

      int rawHour = int.tryParse(parts[0]) ?? 0;
      final int rawMinute =
          int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

      // Smart AM/PM correction:
      // Dhuhr, Asr, Maghrib, Isha are PM prayers
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
        offsetMinutes: AppConstants.defaultOffsetMinutes,
        hadithText: hadithForNotification,
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
    int notifId = 200;

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
          if (settings.hadithEnabled) {
            try {
              final hadith = await HadithService.fetchRandom();
              hadithForNotification =
                  '${hadith.fullText}\n— ${hadith.bookDisplayName}';
            } catch (_) {}
          }

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

  /// Leave a group
  Future<bool> leaveGroup({
    required String groupId,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _authController.currentUser.value;
      if (user == null) {
        Get.snackbar('ত্রুটি', 'অনুগ্রহ করে লগইন করুন।');
        return false;
      }

      final docRef = _firestore.collection('groups').doc(groupId);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        errorMessage.value = 'গ্রুপটি খুঁজে পাওয়া যায়নি।';
        return false;
      }

      final group = GroupModel.fromJson(doc.data()!);
      final memberIndex = group.members.indexWhere((m) => m.uid == user.uid);
      if (memberIndex == -1) {
        errorMessage.value = 'আপনি এই গ্রুপের মেম্বার নন।';
        return false;
      }

      final leavingMember = group.members[memberIndex];
      final remainingMembers =
          group.members.where((m) => m.uid != user.uid).toList();

      if (remainingMembers.isEmpty) {
        // If user is the ONLY member, delete the group entirely
        await docRef.delete();
        try {
          await _firestore
              .collection('groupInvites')
              .doc(group.inviteCode)
              .delete();
        } catch (_) {}
      } else {
        // There are other members left
        String newAdminUid = group.adminUid;
        // If the primary admin is leaving, transfer primary admin to another admin or next member
        if (group.adminUid == user.uid) {
          final nextAdmin = remainingMembers.firstWhere(
            (m) => m.isAdmin,
            orElse: () => remainingMembers.first,
          );
          newAdminUid = nextAdmin.uid;

          // Ensure the new primary admin has role 'admin' in members list
          final updatedMembers = remainingMembers.map((m) {
            if (m.uid == newAdminUid) {
              return GroupMember(
                uid: m.uid,
                name: m.name,
                email: m.email,
                role: 'admin',
              );
            }
            return m;
          }).toList();

          await docRef.update({
            'adminUid': newAdminUid,
            'members': updatedMembers.map((m) => m.toJson()).toList(),
            'memberUids': FieldValue.arrayRemove([user.uid]),
          });
        } else {
          // Regular member or secondary admin is leaving
          await docRef.update({
            'members': FieldValue.arrayRemove([leavingMember.toJson()]),
            'memberUids': FieldValue.arrayRemove([user.uid]),
          });
        }
      }

      // 2. Remove group from user's groupIds in Firestore & local user model
      await _firestore.collection('users').doc(user.uid).set({
        'groupIds': FieldValue.arrayRemove([groupId]),
      }, SetOptions(merge: true));

      final updatedGroupIds = List<String>.from(user.groupIds)..remove(groupId);
      final updatedUser = user.copyWith(groupIds: updatedGroupIds);
      _authController.currentUser.value = updatedUser;
      await _authController.saveUserToStorage(updatedUser);

      // 3. Resync prayer notifications
      // If user has no more groups, this automatically falls back to API prayer notifications!
      await syncPrayerNotifications();

      Get.snackbar(
        'গ্রুপ ত্যাগ সম্পন্ন',
        'আপনি সফলভাবে "${group.name}" গ্রুপ থেকে বের হয়ে গেছেন।',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Leave group error: $e');
      errorMessage.value = 'গ্রুপ ত্যাগ করতে সমস্যা হয়েছে: $e';
      Get.snackbar(
        'Error',
        'গ্রুপ ত্যাগ করতে সমস্যা হয়েছে: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
