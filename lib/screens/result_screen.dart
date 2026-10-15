import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../widgets/accessible_button.dart';
import '../widgets/accessible_header.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SightController>(context);
    final lm = controller.languageManager;
    final gemini = controller.geminiService;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AccessibleHeader(
              title: controller.resultTitle.isNotEmpty
                  ? controller.resultTitle
                  : lm.getText('resultTitle'),
              onBack: () => Navigator.pushReplacementNamed(context, '/home'),
            ),

            // Main Result Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Category Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryYellow, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.psychology_rounded, color: AppColors.primaryYellow, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                gemini.isProxyConnected ? 'Real-Time AI Response' : 'AI Analysis Result',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Result text box with high-contrast glowing neon border
                    Semantics(
                      label: 'Analysis result: ${controller.resultContent}',
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.primaryYellow,
                            width: 3.5,
                          ),
                          boxShadow: AppColors.glowShadow(AppColors.primaryYellow, opacity: 0.25, blur: 18),
                        ),
                        child: Text(
                          controller.resultContent.isNotEmpty
                              ? controller.resultContent
                              : 'No result available. Please capture another image.',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. Replay Speech Button (Cyan)
                    AccessibleButton(
                      label: lm.getText('replayAudio'),
                      icon: Icons.volume_up_rounded,
                      backgroundColor: AppColors.secondaryCyan,
                      textColor: AppColors.textInverse,
                      onPressed: () {
                        controller.ttsService.replay();
                      },
                      semanticHint: 'Double tap to hear the result again',
                    ),
                    const SizedBox(height: 16),

                    // 2. Retry / Take Another Picture Button (Yellow)
                    AccessibleButton(
                      label: lm.getText('retake'),
                      icon: Icons.refresh_rounded,
                      backgroundColor: AppColors.primaryYellow,
                      textColor: AppColors.textInverse,
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/camera',
                          arguments: controller.currentMode,
                        );
                      },
                      semanticHint: 'Double tap to take another picture',
                    ),
                    const SizedBox(height: 16),

                    // 3. Back to Home Button
                    AccessibleButton(
                      label: lm.getText('backToHome'),
                      icon: Icons.home_rounded,
                      backgroundColor: AppColors.surfaceElevated,
                      textColor: AppColors.textPrimary,
                      borderColor: AppColors.surfaceBorder,
                      onPressed: () {
                        controller.ttsService.stop();
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      semanticHint: 'Double tap to return to the home screen',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
