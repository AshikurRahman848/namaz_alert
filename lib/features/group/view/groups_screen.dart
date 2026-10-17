import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupCtrl = Get.put(GroupController());
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Join Group',
            onPressed: () => _showJoinDialog(context, groupCtrl),
          ),
        ],
      ),
      body: Obx(() {
        final myGroups = groupCtrl.myGroups;
        if (myGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👥', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'No groups yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a group for your office team\nor join with an invite code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.createGroup),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Group'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myGroups.length,
          itemBuilder: (ctx, i) {
            final group = myGroups[i];
            final isAdmin = group.isAdmin(authCtrl.currentUser.value?.uid ?? '');
            return _GroupCard(
              group: group,
              isAdmin: isAdmin,
              onTap: () => Get.toNamed(
                AppRoutes.groupDetail,
                arguments: group.id,
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createGroup),
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, GroupController ctrl) {
    final codeCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Join a Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the invite code shared by your group admin:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Invite Code (e.g. NAM-4X7K)',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            Obx(() {
              final err = ctrl.errorMessage.value;
              if (err.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: ctrl.isLoading.value
                    ? null
                    : () => ctrl.joinGroup(codeCtrl.text.trim()),
                child: ctrl.isLoading.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join'),
              )),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 26,
          child: Text(
            group.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (isAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📍 ${group.city}, ${group.country}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('👥 ${group.memberCount} members'),
                const SizedBox(width: 12),
                Text(
                    '🔔 ${group.notificationSettings.offsetMinutes} min before'),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                Get.snackbar('Copied!', 'Invite code copied to clipboard',
                    duration: const Duration(seconds: 2));
              },
              child: Text(
                '🔑 ${group.inviteCode}  (tap to copy)',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
