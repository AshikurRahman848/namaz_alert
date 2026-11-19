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
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                tooltip: 'Search & Join Group',
                onPressed: () => showJoinDialog(context, groupCtrl),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Obx(() {
              final myGroups = groupCtrl.myGroups;
              final pending = groupCtrl.pendingGroups;

              if (myGroups.isEmpty && pending.isEmpty) {
                return _EmptyGroupsView(groupCtrl: groupCtrl);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search / Join group banner
                    InkWell(
                      onTap: () => showJoinDialog(context, groupCtrl),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'গ্রুপের নাম বা কোড দিয়ে খুঁজুন...',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Search',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (pending.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hourglass_top_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'অপেক্ষমাণ যোগদানের অনুরোধ (${pending.length})',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...pending.map((pg) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          size: 5, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          pg.name,
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Colors.brown.shade900,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Pending',
                                          style: GoogleFonts.nunito(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.brown.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
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
                        onLeave: () => _confirmLeaveGroup(context, group),
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

  static void showJoinDialog(BuildContext context, GroupController ctrl) {
    Get.dialog(
      _JoinGroupDialog(ctrl: ctrl),
    );
  }

  static void _confirmLeaveGroup(BuildContext context, GroupModel group) {
    final authCtrl = Get.find<AuthController>();
    final groupCtrl = Get.find<GroupController>();
    final currentUid = authCtrl.currentUser.value?.uid ?? '';
    final isSoleMember = group.members.length <= 1;
    final isPrimaryAdmin = group.isPrimaryAdmin(currentUid);

    String dialogMessage;
    if (isSoleMember) {
      dialogMessage =
          '⚠️ আপনি এই গ্রুপের একমাত্র মেম্বার। আপনি গ্রুপ ত্যাগ করলে এই গ্রুপটি চিরতরে মুছে যাবে।\n\nআপনি কি নিশ্চিতভাবে গ্রুপ ত্যাগ করতে চান?';
    } else if (isPrimaryAdmin) {
      dialogMessage =
          '⚠️ আপনি এই গ্রুপের প্রধান অ্যাডমিন। আপনি গ্রুপ ত্যাগ করলে অন্য একজন মেম্বারকে স্বয়ংক্রিয়ভাবে প্রধান অ্যাডমিন করা হবে।\n\nআপনি কি নিশ্চিতভাবে "${group.name}" গ্রুপ থেকে বের হয়ে যেতে চান?';
    } else {
      dialogMessage =
          'আপনি কি নিশ্চিতভাবে "${group.name}" গ্রুপ ত্যাগ করতে চান?\n\nবের হয়ে গেলে আপনি এই গ্রুপের জামায়াতের সময় ও অ্যালার্ট আর পাবেন না এবং সাধারণ নামাজের সময় অনুযায়ী নোটিফিকেশন চালু হবে।';
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app_rounded,
                color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'গ্রুপ ত্যাগ নিশ্চিতকরণ',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.red.shade900,
              ),
            ),
          ],
        ),
        content: Text(
          dialogMessage,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'বাতিল',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Get.back(); // close dialog
              await groupCtrl.leaveGroup(groupId: group.id);
            },
            child: Text(
              'হ্যাঁ, বের হয়ে যান',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinGroupDialog extends StatefulWidget {
  final GroupController ctrl;
  const _JoinGroupDialog({required this.ctrl});

  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  final Map<String, bool> _sendingMap = {};
  bool _isSearching = false;
  String? _error;

  Future<void> _handleSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    final res = await widget.ctrl.searchGroups(query);
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      if (res.isEmpty) {
        _error = widget.ctrl.errorMessage.value.isNotEmpty
            ? widget.ctrl.errorMessage.value
            : 'কোনো গ্রুপ খুঁজে পাওয়া যায়নি। কোড বা নাম চেক করে পুনরায় চেষ্টা করুন।';
      } else {
        _results = res;
      }
    });
  }

  Future<void> _handleSendRequest(Map<String, dynamic> item) async {
    final groupId = item['groupId'] as String;
    setState(() {
      _sendingMap[groupId] = true;
    });

    final success = await widget.ctrl.sendJoinRequest(groupId);
    if (!mounted) return;

    setState(() {
      _sendingMap[groupId] = false;
      if (success) {
        item['isPending'] = true;
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🔍', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Search & Join Group',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ইনভাইট কোড (যেমন: NAM-XXXX) বা গ্রুপের নাম দিয়ে খুঁজুন',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSearch(),
                      decoration: InputDecoration(
                        hintText: 'NAM-XXXX বা গ্রুপের নাম...',
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.primary.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: _isSearching ? null : _handleSearch,
                      child: _isSearching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded, size: 22),
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),

              // Search results list
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._results.map((item) {
                        final isSending =
                            _sendingMap[item['groupId'] as String] ?? false;
                        final isMember = item['isAlreadyMember'] == true;
                        final isPending = item['isPending'] == true;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🕌',
                                      style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['groupName'] as String? ?? '',
                                          style: GoogleFonts.nunito(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if ((item['city'] as String? ?? '')
                                            .isNotEmpty)
                                          Text(
                                            '📍 ${item['city']}',
                                            style: GoogleFonts.nunito(
                                              fontSize: 11,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline_rounded,
                                      size: 13, color: AppColors.textGrey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'নন-মেম্বারদের জন্য নামাজের সময় গোপন। অ্যাডমিন অনুমোদন করলে সব দেখা যাবে।',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isMember)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '✅ আপনি ইতিমধ্যেই এই গ্রুপের মেম্বার',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                )
                              else if (isPending)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '⏳ অনুরোধ পাঠানো হয়েছে (অপেক্ষমাণ)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.brown.shade800,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: isSending
                                        ? null
                                        : () => _handleSendRequest(item),
                                    icon: isSending
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send_rounded,
                                            size: 15),
                                    label: Text(
                                      isSending
                                          ? 'অনুরোধ পাঠানো হচ্ছে...'
                                          : 'যোগদানের অনুরোধ পাঠান (Join Request)',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.nunito(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                  emoji: '🔍',
                  label: 'Search &\nJoin Group',
                  onTap: () => GroupsScreen.showJoinDialog(context, groupCtrl),
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
  final VoidCallback? onLeave;

  const _GroupCard({
    required this.group,
    required this.isAdmin,
    required this.onTap,
    this.onLeave,
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

                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'details') {
                            onTap();
                          } else if (val == 'leave') {
                            onLeave?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text('বিস্তারিত দেখুন',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'leave',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('গ্রুপ ত্যাগ করুন',
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
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
