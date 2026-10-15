import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../widgets/high_contrast_card.dart';
import '../widgets/voice_waveform.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCameraForMode(BuildContext context, VisionMode mode) {
    Navigator.pushNamed(
      context,
      '/camera',
      arguments: mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SightController>(context);
    final lm = controller.languageManager;
    final gemini = controller.geminiService;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.textInverse, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              lm.getText('appName'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryYellow,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Settings button',
            hint: 'Double tap to open settings and accessibility options',
            child: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.settings_rounded, color: AppColors.primaryYellow),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Real-Time Connection Status Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: gemini.isProxyConnected ? AppColors.accentGreen.withOpacity(0.12) : AppColors.surfaceElevated,
                border: Border(
                  bottom: BorderSide(
                    color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.surfaceBorder,
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.alertRed,
                      boxShadow: [
                        BoxShadow(
                          color: (gemini.isProxyConnected ? AppColors.accentGreen : AppColors.alertRed).withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    gemini.isProxyConnected
                        ? '🟢 Real-Time AI Server Connected (.env API Key Active)'
                        : '⚠️ AI Server Disconnected (Ensure node server.js is running)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.alertRed,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      controller.geminiService.checkProxyHealth();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.refresh_rounded, size: 18, color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.primaryYellow),
                    ),
                  )
                ],
              ),
            ),

            // Hero Voice Microphone Control Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder, width: 2),
                ),
              ),
              child: Center(
                child: VoiceWaveform(
                  isListening: controller.speechService.isListening,
                  label: controller.speechService.isListening
                      ? lm.getText('listening')
                      : lm.getText('tapToSpeak'),
                  onTap: () {
                    if (controller.speechService.isListening) {
                      controller.stopVoiceListening();
                    } else {
                      controller.startVoiceListening();
                    }
                  },
                ),
              ),
            ),

            // Live recognized words or status feedback bar
            if (controller.speechService.lastRecognizedWords.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: AppColors.surfaceElevated,
                child: Text(
                  'Heard: "${controller.speechService.lastRecognizedWords}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryCyan,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 5 High Contrast Accessible Feature Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                children: [
                  // 1. Describe Surroundings
                  HighContrastCard(
                    title: lm.getText('btnSurroundings'),
                    description: 'Understand objects, people & scene context in real-time',
                    icon: Icons.remove_red_eye_rounded,
                    accentColor: AppColors.sceneSurroundings,
                    onTap: () => _openCameraForMode(context, VisionMode.sceneUnderstanding),
                    voiceHint: 'Say: "Describe surroundings"',
                  ),
                  const SizedBox(height: 16),

                  // 2. Read Text
                  HighContrastCard(
                    title: lm.getText('btnReadText'),
                    description: 'Books, signboards, notices & bus numbers',
                    icon: Icons.menu_book_rounded,
                    accentColor: AppColors.readText,
                    onTap: () => _openCameraForMode(context, VisionMode.ocrReading),
                    voiceHint: 'Say: "Read text"',
                  ),
                  const SizedBox(height: 16),

                  // 3. Identify Medicine
                  HighContrastCard(
                    title: lm.getText('btnMedicine'),
                    description: 'Medicine name, dosage & expiry date verification',
                    icon: Icons.medication_rounded,
                    accentColor: AppColors.medicine,
                    onTap: () => _openCameraForMode(context, VisionMode.medicineAssistance),
                    voiceHint: 'Say: "Identify medicine"',
                  ),
                  const SizedBox(height: 16),

                  // 4. Recognize Currency
                  HighContrastCard(
                    title: lm.getText('btnCurrency'),
                    description: 'Indian Rupee notes & coin denominations',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.currency,
                    onTap: () => _openCameraForMode(context, VisionMode.currencyRecognition),
                    voiceHint: 'Say: "Recognize currency"',
                  ),
                  const SizedBox(height: 16),

                  // 5. Detect Obstacles / Hazards
                  HighContrastCard(
                    title: lm.getText('btnHazards'),
                    description: 'Directional alerts for stairs, curbs & vehicles',
                    icon: Icons.warning_rounded,
                    accentColor: AppColors.hazards,
                    onTap: () => _openCameraForMode(context, VisionMode.hazardDetection),
                    voiceHint: 'Say: "Detect obstacles"',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
