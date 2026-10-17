import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/core/routes/app_routes.dart';
import 'package:namaz_alert/features/auth/controller/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D3B1A),
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative rotating star pattern
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _rotateCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _rotateCtrl.value * 2 * pi,
                  child: child,
                ),
                child: Opacity(
                  opacity: 0.06,
                  child: _StarPattern(size: 300),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: AnimatedBuilder(
                animation: _rotateCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: -_rotateCtrl.value * 2 * pi,
                  child: child,
                ),
                child: Opacity(
                  opacity: 0.04,
                  child: _StarPattern(size: 260),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container with glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🕌', style: TextStyle(fontSize: 60)),
                    ),
                  )
                      .animate()
                      .scale(
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5))
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // App name
                  Text(
                    'NamazAlert',
                    style: GoogleFonts.nunito(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate(delay: 300.ms)
                      .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Never miss a prayer ✨',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 16),

                  // Arabic text
                  Text(
                    'الصلاة خير من النوم',
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 60),

                  // Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      )
                          .animate(
                            onPlay: (ctrl) => ctrl.repeat(),
                            delay: Duration(milliseconds: i * 150),
                          )
                          .scaleXY(
                            begin: 0.6,
                            end: 1.0,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scaleXY(
                            begin: 1.0,
                            end: 0.6,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          );
                    }),
                  ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Bottom text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 800.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPattern extends StatelessWidget {
  final double size;
  const _StarPattern({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IslamicPatternPainter(),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final x1 = center.dx + radius * 0.3 * cos(angle);
      final y1 = center.dy + radius * 0.3 * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    canvas.drawCircle(center, radius * 0.3, paint);
    canvas.drawCircle(center, radius * 0.6, paint);
    canvas.drawCircle(center, radius * 0.9, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
