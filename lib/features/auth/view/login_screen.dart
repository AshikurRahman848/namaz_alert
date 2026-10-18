import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  final AuthController _auth = Get.find();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _auth.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          // ── Curved gradient header ──────────────────────────
          const _GradientHeader(),

          // ── Form ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  Text(
                    'Welcome Back 👋',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ).animate().slideX(begin: -0.2, duration: 500.ms).fadeIn(),

                  const SizedBox(height: 4),

                  Text(
                    'Sign in to your NamazAlert account',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .slideX(begin: -0.2, duration: 500.ms)
                      .fadeIn(),

                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        _PremiumTextField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your email';
                            }
                            if (!GetUtils.isEmail(v)) return 'Invalid email';
                            return null;
                          },
                        ).animate(delay: 200.ms).slideY(begin: 0.2).fadeIn(),

                        const SizedBox(height: 16),

                        // Password field
                        _PremiumTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscure,
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        ).animate(delay: 300.ms).slideY(begin: 0.2).fadeIn(),

                        const SizedBox(height: 8),

                        // Error
                        Obx(() {
                          final err = _auth.errorMessage.value;
                          if (err.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(err,
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ).animate().shake();
                        }),

                        const SizedBox(height: 28),

                        // Sign in button
                        Obx(() => _GradientButton(
                              onPressed:
                                  _auth.isLoading.value ? null : _submit,
                              isLoading: _auth.isLoading.value,
                              label: 'Sign In',
                            )).animate(delay: 400.ms).slideY(begin: 0.2).fadeIn(),

                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: GoogleFonts.nunito(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ).animate(delay: 450.ms).fadeIn(),

                        const SizedBox(height: 20),

                        // Google Sign-In button
                        Obx(() => _GoogleSignInButton(
                              onPressed: _auth.isLoading.value
                                  ? null
                                  : _auth.signInWithGoogle,
                              isLoading: _auth.isLoading.value,
                            )).animate(delay: 500.ms).slideY(begin: 0.2).fadeIn(),

                        const SizedBox(height: 24),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.nunito(
                                  color: AppColors.textGrey),
                            ),
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.register),
                              child: Text(
                                'Register',
                                style: GoogleFonts.nunito(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ).animate(delay: 550.ms).fadeIn(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Register Screen ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  final AuthController _auth = Get.find();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _auth.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Column(
        children: [
          const _GradientHeader(
            title: 'Join NamazAlert',
            subtitle: 'Namaz reminders for your office team',
            emoji: '👤',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _PremiumTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your name'
                              : null,
                        ).animate().slideY(begin: 0.2, delay: 100.ms).fadeIn(),
                        const SizedBox(height: 16),
                        _PremiumTextField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your email';
                            }
                            if (!GetUtils.isEmail(v)) return 'Invalid email';
                            return null;
                          },
                        )
                            .animate()
                            .slideY(begin: 0.2, delay: 200.ms)
                            .fadeIn(),
                        const SizedBox(height: 16),
                        _PremiumTextField(
                          controller: _passCtrl,
                          label: 'Password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscure,
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Minimum 6 characters'
                              : null,
                        )
                            .animate()
                            .slideY(begin: 0.2, delay: 300.ms)
                            .fadeIn(),
                        const SizedBox(height: 16),
                        _PremiumTextField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          icon: Icons.lock_outlined,
                          obscureText: _obscure,
                          validator: (v) => v != _passCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        )
                            .animate()
                            .slideY(begin: 0.2, delay: 400.ms)
                            .fadeIn(),
                        const SizedBox(height: 8),
                        Obx(() {
                          final err = _auth.errorMessage.value;
                          if (err.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(err,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13)),
                          );
                        }),
                        const SizedBox(height: 28),
                        Obx(() => _GradientButton(
                              onPressed:
                                  _auth.isLoading.value ? null : _submit,
                              isLoading: _auth.isLoading.value,
                              label: 'Create Account',
                            ))
                            .animate()
                            .slideY(begin: 0.2, delay: 500.ms)
                            .fadeIn(),

                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: GoogleFonts.nunito(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ).animate(delay: 550.ms).fadeIn(),

                        const SizedBox(height: 20),

                        // Google Sign-In button
                        Obx(() => _GoogleSignInButton(
                              onPressed: _auth.isLoading.value
                                  ? null
                                  : _auth.signInWithGoogle,
                              isLoading: _auth.isLoading.value,
                            )).animate(delay: 600.ms).slideY(begin: 0.2).fadeIn(),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: GoogleFonts.nunito(
                                    color: AppColors.textGrey)),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Text('Sign In',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ),
                          ],
                        ).animate(delay: 650.ms).fadeIn(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;

  const _GradientHeader({
    this.title = 'NamazAlert',
    this.subtitle = 'Never miss a prayer',
    this.emoji = '🕌',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D3B1A), Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        bottom: 40,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 40)),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(
          color: AppColors.textGrey,
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onPressed == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: onPressed == null ? Colors.grey : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4285F4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

