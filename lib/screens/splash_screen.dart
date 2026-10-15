import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/haptic_feedback_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final controller = Provider.of<SightController>(context, listen: false);
    await controller.initialize();

    // Haptic greeting
    await HapticFeedbackHelper.successPattern();

    // Spoken welcome
    await controller.speakCurrentLanguage(
      'Welcome to SightAssist. AI Eyes for the Visually Impaired. Double tap the screen to begin, or speak a command.'
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Semantics(
          label: 'SightAssist splash screen. AI eyes for the visually impaired. Loading application.',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated High-Contrast Eye Logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryYellow, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryYellow.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 6,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        size: 76,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // App Name
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryYellow,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  const Text(
                    AppStrings.appTagline,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Progress indicator
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 4.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryCyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
