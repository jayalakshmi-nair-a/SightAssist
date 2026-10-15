import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../widgets/accessible_button.dart';
import '../widgets/accessible_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _proxyUrlController;
  bool _isTestingProxy = false;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<SightController>(context, listen: false);
    _proxyUrlController = TextEditingController(
      text: controller.settings.proxyServerUrl.isNotEmpty
          ? controller.settings.proxyServerUrl
          : controller.geminiService.activeProxyUrl,
    );
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    super.dispose();
  }

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
              title: lm.getText('settingsTitle'),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                children: [
                  // 1. Language Selection Section
                  _buildSectionHeader(lm.getText('languageSetting'), Icons.language_rounded),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder, width: 2),
                      boxShadow: AppColors.glowShadow(AppColors.primaryYellow, opacity: 0.1, blur: 10),
                    ),
                    child: Column(
                      children: AppLanguage.values.map((lang) {
                        final isSelected = controller.currentLanguage == lang;
                        return Semantics(
                          selected: isSelected,
                          label: '${lang.displayName}. ${isSelected ? "Selected" : "Not selected"}.',
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(
                              lang.displayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected ? AppColors.primaryYellow : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryYellow, size: 28)
                                : null,
                            onTap: () {
                              controller.setLanguage(lang);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Real-Time API Server Connection (.env Secured)
                  _buildSectionHeader('Real-Time Server (.env Secured API)', Icons.cloud_done_rounded),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.secondaryCyan,
                        width: 2.5,
                      ),
                      boxShadow: AppColors.glowShadow(
                        gemini.isProxyConnected ? AppColors.accentGreen : AppColors.secondaryCyan,
                        opacity: 0.2,
                        blur: 12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: gemini.isProxyConnected
                                ? AppColors.accentGreen.withOpacity(0.18)
                                : AppColors.warningOrange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.warningOrange,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gemini.isProxyConnected ? Icons.check_circle_rounded : Icons.info_rounded,
                                color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.warningOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                gemini.isProxyConnected
                                    ? 'Status: Connected to Real-Time AI Server'
                                    : 'Status: Offline / Server Disconnected',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: gemini.isProxyConnected ? AppColors.accentGreen : AppColors.warningOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '🔒 API key is securely loaded from .env on the server. The client application connects directly to the backend for real-time vision processing without storing keys.',
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _proxyUrlController,
                          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            labelText: 'Server Endpoint URL',
                            labelStyle: const TextStyle(color: AppColors.secondaryCyan),
                            hintText: 'http://localhost:5000',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.dns_rounded, color: AppColors.secondaryCyan),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.secondaryCyan, width: 2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AccessibleButton(
                          label: _isTestingProxy ? 'Testing Server...' : 'Check Server Connection',
                          icon: Icons.electrical_services_rounded,
                          minHeight: 52,
                          backgroundColor: AppColors.secondaryCyan,
                          textColor: AppColors.textInverse,
                          onPressed: () async {
                            setState(() => _isTestingProxy = true);
                            final newUrl = _proxyUrlController.text.trim();
                            await controller.updateProxyUrl(newUrl);
                            final connected = await gemini.checkProxyHealth(newUrl);
                            setState(() => _isTestingProxy = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  connected
                                      ? '✅ Connected to real-time server at $newUrl'
                                      : '⚠️ Server unreachable at $newUrl. Ensure "node server.js" is running.',
                                ),
                                backgroundColor: connected ? AppColors.accentGreen : AppColors.warningOrange,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. Speech Rate & Pitch Controls
                  _buildSectionHeader('Speech Engine Settings', Icons.record_voice_over_rounded),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speech Speed: ${(controller.settings.speechRate * 2).toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Slider(
                          value: controller.settings.speechRate,
                          min: 0.2,
                          max: 1.0,
                          divisions: 8,
                          activeColor: AppColors.primaryYellow,
                          inactiveColor: AppColors.surfaceBorder,
                          onChanged: (val) {
                            controller.updateSpeechRate(val);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Speech Pitch: ${controller.settings.speechPitch.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Slider(
                          value: controller.settings.speechPitch,
                          min: 0.6,
                          max: 1.6,
                          divisions: 10,
                          activeColor: AppColors.secondaryCyan,
                          inactiveColor: AppColors.surfaceBorder,
                          onChanged: (val) {
                            controller.updateSpeechPitch(val);
                          },
                        ),
                        const SizedBox(height: 14),
                        AccessibleButton(
                          label: 'Test Voice Output',
                          minHeight: 52,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: AppColors.secondaryCyan,
                          borderColor: AppColors.secondaryCyan,
                          onPressed: () {
                            controller.speakCurrentLanguage(
                              'This is a speech speed and pitch demonstration for SightAssist.'
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 4. Privacy & Safe Computing Policy
                  _buildSectionHeader('Privacy & Data Security', Icons.security_rounded),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder, width: 2),
                    ),
                    child: const Text(
                      'SightAssist respects your privacy:\n\n'
                      '• API key is kept secure inside .env on the server.\n'
                      '• Camera images are processed in-memory and immediately purged after analysis.\n'
                      '• Speech commands are processed locally on device.\n'
                      '• No private visual data is permanently stored or sold.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryYellow, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryYellow,
            ),
          ),
        ),
      ],
    );
  }
}
