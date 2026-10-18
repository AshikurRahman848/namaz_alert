import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groupCtrl = Get.put(GroupController());
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: CustomScrollView(
        slivers: [
          // Premium sliver app bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D3B1A), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: -20,
                      top: -20,
                      child: Opacity(
                        opacity: 0.08,
                        child: Icon(Icons.group,
                            size: 160,
                            color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'My Groups 👥',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Namaz alerts with your team',
                            style: GoogleFonts.nunito(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.login_rounded, color: Colors.white),
                tooltip: 'Join with Code',
                onPressed: () => _showJoinDialog(context, groupCtrl),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Obx(() {
              final myGroups = groupCtrl.myGroups;

              if (myGroups.isEmpty) {
                return _EmptyGroupsView(groupCtrl: groupCtrl);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    ...myGroups.asMap().entries.map((entry) {
                      final i = entry.key;
                      final group = entry.value;
                      final isAdmin = group.isAdmin(
                          authCtrl.currentUser.value?.uid ?? '');
                      return _GroupCard(
                        group: group,
                        isAdmin: isAdmin,
                        onTap: () => Get.toNamed(
                          AppRoutes.groupDetail,
                          arguments: group.id,
                        ),
                      ).animate(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.3).fadeIn();
                    }),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createGroup),
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Group',
          style: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ).animate(delay: 400.ms).scale(curve: Curves.elasticOut),
    );
  }

  void _showJoinDialog(BuildContext context, GroupController ctrl) {
    final codeCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('🔑', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Join a Group',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the invite code from your group admin',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: 'NAM-XXXX',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: Colors.grey.shade300,
                  ),
                  filled: true,
                  fillColor: AppColors.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              Obx(() {
                final err = ctrl.errorMessage.value;
                if (err.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(err,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                );
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.nunito(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: ctrl.isLoading.value
                                ? null
                                : () => ctrl.joinGroup(codeCtrl.text.trim()),
                            child: ctrl.isLoading.value
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    'Join',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyGroupsView extends StatelessWidget {
  final GroupController groupCtrl;

  const _EmptyGroupsView({required this.groupCtrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('👥', style: TextStyle(fontSize: 56)),
            ),
          ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),

          const SizedBox(height: 24),

          Text(
            'No Groups Yet',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 8),

          Text(
            'Create a group for your office\nor join with an invite code',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  emoji: '➕',
                  label: 'Create\nGroup',
                  onTap: () => Get.toNamed(AppRoutes.createGroup),
                ).animate(delay: 400.ms).slideX(begin: -0.3).fadeIn(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  emoji: '🔑',
                  label: 'Join with\nCode',
                  onTap: () => Get.back(),
                ).animate(delay: 500.ms).slideX(begin: 0.3).fadeIn(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group Card ─────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isAdmin;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.isAdmin,
    required this.onTap,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFF0D47A1), Color(0xFF1976D2)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    [Color(0xFFBF360C), Color(0xFFE64A19)],
    [Color(0xFF006064), Color(0xFF00838F)],
  ];

  @override
  Widget build(BuildContext context) {
    final gradIdx = group.name.hashCode.abs() % _gradients.length;
    final gradient = _gradients[gradIdx];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            group.name.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '👑 Admin',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${group.city}, ${group.country}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textGrey,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        label: '${group.memberCount} members',
                        color: gradient.first,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.notifications_outlined,
                        label: '${group.notificationSettings.offsetMinutes}m before',
                        color: gradient.first,
                      ),
                      const Spacer(),
                      // Invite code chip
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: group.inviteCode));
                          Get.snackbar(
                            '✅ Copied!',
                            'Invite code copied to clipboard',
                            duration: const Duration(seconds: 2),
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient
                                  .map((c) => c.withValues(alpha: 0.1))
                                  .toList(),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: gradient.first.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_outlined,
                                  size: 12, color: gradient.first),
                              const SizedBox(width: 4),
                              Text(
                                group.inviteCode,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: gradient.first,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
