import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/services/hadith_service.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupController _groupCtrl = Get.find();
  final AuthController _authCtrl = Get.find();
  late String _groupId;
  bool _sendingHadith = false;

  @override
  void initState() {
    super.initState();
    _groupId = Get.arguments as String;
  }

  GroupModel? get _group => _groupCtrl.getGroupById(_groupId);

  Future<void> _sendHadith() async {
    setState(() => _sendingHadith = true);
    try {
      final hadith = await HadithService.fetchRandom();
      if (hadith == null) {
        Get.snackbar('Error', 'Could not fetch hadith. Try again.');
        return;
      }

      // Broadcast via FCM to all group members
      await _groupCtrl.broadcastHadith(
        groupId: _groupId,
        hadithText: hadith.shortText,
        narrator: hadith.bookDisplayName,
      );

      Get.snackbar(
        '📖 Hadith Broadcast!',
        'Sent to all group members via notification',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      setState(() => _sendingHadith = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = _group;
      if (group == null) {
        return const Scaffold(body: Center(child: Text('Group not found')));
      }

      final isAdmin =
          group.isAdmin(_authCtrl.currentUser.value?.uid ?? '');
      final settings = group.notificationSettings;

      return Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Get.toNamed(
                  '/group-settings',
                  arguments: group.id,
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group Info Card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 30,
                          child: Text(
                            group.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('📍 ${group.city}, ${group.country}',
                                  style: const TextStyle(
                                      color: AppColors.textGrey)),
                              Text('👥 ${group.memberCount} members',
                                  style: const TextStyle(
                                      color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                      ]),
                      const Divider(height: 20),
                      Row(children: [
                        const Icon(Icons.notifications_active,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Notify ${settings.offsetMinutes} min before each prayer',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Send Hadith (Admin only)
              if (isAdmin)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📖 Broadcast Hadith',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a random hadith notification to all group members right now.',
                          style:
                              TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _sendingHadith ? null : _sendHadith,
                          icon: _sendingHadith
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send),
                          label: const Text('Send Hadith Now'),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Members List
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👥 Members (${group.memberCount})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      ...group.members.map((m) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryLight.withOpacity(0.2),
                              child: Text(
                                m.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(m.name),
                            subtitle: Text(m.email),
                            trailing: m.isAdmin
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Admin',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
