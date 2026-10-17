import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/services/notification_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';

class GroupController extends GetxController {
  final _storage = GetStorage();
  final _authController = Get.find<AuthController>();

  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGroupsFromStorage();
  }

  void _loadGroupsFromStorage() {
    final raw = _storage.read<List>(AppConstants.keyGroups);
    if (raw != null) {
      groups.value = raw
          .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  }

  void _saveGroupsToStorage() {
    _storage.write(
        AppConstants.keyGroups, groups.map((g) => g.toJson()).toList());
  }

  /// Create a new group
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

      groups.add(group);
      _saveGroupsToStorage();

      // Schedule notifications for this group
      await _scheduleGroupNotifications(group);

      Get.back();
      Get.snackbar(
        '✅ Group Created',
        '"$name" — Invite code: ${group.inviteCode}',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      errorMessage.value = 'Failed to create group.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Join a group via invite code
  Future<void> joinGroup(String inviteCode) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // TODO: Fetch group from Firestore by inviteCode
      // For now, search local storage
      final existing = groups.firstWhereOrNull(
        (g) => g.inviteCode.toUpperCase() == inviteCode.toUpperCase(),
      );

      if (existing == null) {
        errorMessage.value = 'Invalid invite code. Group not found.';
        return;
      }

      final user = _authController.currentUser.value!;
      if (existing.isMember(user.uid)) {
        errorMessage.value = 'You are already a member of this group.';
        return;
      }

      final newMember = GroupMember(
        uid: user.uid,
        name: user.name,
        email: user.email,
        role: 'member',
      );

      final updatedGroup = existing.copyWith(
        members: [...existing.members, newMember],
      );

      final index = groups.indexOf(existing);
      groups[index] = updatedGroup;
      _saveGroupsToStorage();

      await _scheduleGroupNotifications(updatedGroup);
      Get.back();
    } catch (e) {
      errorMessage.value = 'Failed to join group.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notification settings for a group
  Future<void> updateNotificationSettings(
    String groupId,
    GroupNotificationSettings settings,
  ) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    final updated = groups[index].copyWith(notificationSettings: settings);
    groups[index] = updated;
    _saveGroupsToStorage();

    // Reschedule notifications
    await _scheduleGroupNotifications(updated);
  }

  /// Schedule local notifications for a group based on its settings
  Future<void> _scheduleGroupNotifications(GroupModel group) async {
    // Fetch prayer times for this group's city
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
      final namazName = entry.key;
      final timeStr = entry.value;

      if (enabledMap[namazName] == true) {
        final prayerDateTime = prayerTimes.toDateTime(timeStr);
        await NotificationService.scheduleNamazNotification(
          id: notifId++,
          namazName: namazName,
          prayerTime: prayerDateTime,
          offsetMinutes: settings.offsetMinutes,
        );
      }
    }
  }

  GroupModel? getGroupById(String id) {
    return groups.firstWhereOrNull((g) => g.id == id);
  }

  List<GroupModel> get myGroups {
    final uid = _authController.currentUser.value?.uid;
    if (uid == null) return [];
    return groups.where((g) => g.isMember(uid)).toList();
  }
}
