import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: '');
  final _cityCtrl = TextEditingController(text: 'Dhaka');
  final _countryCtrl = TextEditingController(text: 'Bangladesh');
  int _offsetMinutes = 10;
  final _nameFocus = FocusNode();

  final GroupController _groupCtrl = Get.find();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _groupCtrl.createGroup(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        offsetMinutes: _offsetMinutes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3B1A), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 28,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Create Group',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Center(
                    child: Text('👥', style: TextStyle(fontSize: 36)),
                  ),
                )
                    .animate()
                    .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.5, 0.5))
                    .fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'Setup your office namaz group',
                  style: GoogleFonts.nunito(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ).animate(delay: 200.ms).fadeIn(),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Group name
                    _FormSection(
                      title: 'Group Name',
                      child: TextFormField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'e.g. ABC Office Namaz Group',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.group,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter group name' : null,
                      ),
                    ).animate(delay: 100.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 16),

                    // Location
                    _FormSection(
                      title: 'Prayer Location',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cityCtrl,
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'City',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.location_city,
                                    color: AppColors.primary, size: 18),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter city'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _countryCtrl,
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Country',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.flag_outlined,
                                    color: AppColors.primary, size: 18),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter country'
                                : null,
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 16),

                    // Notification offset
                    _FormSection(
                      title: '🔔 Notify Before Namaz',
                      subtitle: 'How many minutes before prayer?',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [5, 10, 15, 20, 30].map((min) {
                          final selected = _offsetMinutes == min;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _offsetMinutes = min),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              width: 56,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF1B5E20),
                                          Color(0xFF4CAF50)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: selected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 6,
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$min',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'min',
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.textGrey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 16),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('💡',
                                style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'An invite code will be generated automatically. Share it with your team!',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: const Color(0xFF5D4037),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 400.ms).fadeIn(),

                    const SizedBox(height: 28),

                    // Create button
                    // Error message if any
                    Obx(() {
                      if (_groupCtrl.errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _groupCtrl.errorMessage.value,
                                style: GoogleFonts.nunito(
                                  color: Colors.red.shade800,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    Obx(() => GestureDetector(
                          onTap: _groupCtrl.isLoading.value ? null : _submit,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient:
                                  _groupCtrl.isLoading.value
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF1B5E20),
                                            Color(0xFF4CAF50)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                              color: _groupCtrl.isLoading.value
                                  ? Colors.grey.shade300
                                  : null,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _groupCtrl.isLoading.value
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _groupCtrl.isLoading.value
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_circle_outline,
                                            color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create Group',
                                          style: GoogleFonts.nunito(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        )).animate(delay: 500.ms).slideY(begin: 0.2).fadeIn(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 12),
              child: Text(
                subtitle!,
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppColors.textGrey),
              ),
            )
          else
            const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
