import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../controllers/sight_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/haptic_feedback_helper.dart';
import '../widgets/accessible_button.dart';
import '../widgets/accessible_header.dart';

class CameraScreen extends StatefulWidget {
  final VisionMode mode;

  const CameraScreen({super.key, required this.mode});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCameraReady = false;
  bool _autoDetect = false;
  Timer? _autoDetectTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _autoDetectTimer?.cancel();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final controller = Provider.of<SightController>(context, listen: false);
    final success = await controller.cameraService.initializeCamera();

    if (mounted) {
      setState(() => _isCameraReady = success);
      if (success) {
        await HapticFeedbackHelper.lightTap();
        final camType = controller.cameraService.isFrontCamera ? 'Front laptop webcam' : 'Camera';
        await controller.speakCurrentLanguage(
          '$camType ready. Tap the yellow Capture button or double-tap the screen to detect objects.'
        );
      } else {
        await controller.speakCurrentLanguage(
          'Unable to open camera. Please allow camera permissions in your browser or Settings.'
        );
      }
    }
  }

  void _toggleAutoDetect() {
    setState(() {
      _autoDetect = !_autoDetect;
    });

    final controller = Provider.of<SightController>(context, listen: false);
    if (_autoDetect) {
      controller.speakCurrentLanguage('Live auto-detection turned on. Holding steady for continuous scanning.');
      _autoDetectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && _isCameraReady && !controller.isProcessing) {
          _performAutoCapture();
        }
      });
      // Trigger first immediately
      _performAutoCapture();
    } else {
      _autoDetectTimer?.cancel();
      controller.speakCurrentLanguage('Auto-detection paused.');
    }
  }

  Future<void> _performAutoCapture() async {
    final controller = Provider.of<SightController>(context, listen: false);
    if (controller.isProcessing) return;
    await controller.executeVisionAction(widget.mode);
  }

  Future<void> _captureAndAnalyze() async {
    final controller = Provider.of<SightController>(context, listen: false);
    if (controller.isProcessing) return;

    await HapticFeedbackHelper.mediumTap();
    await controller.speakCurrentLanguage(
      controller.languageManager.getText('imageCaptured')
    );

    await controller.executeVisionAction(widget.mode);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/result');
    }
  }

  String _getModeTitle(SightController controller) {
    switch (widget.mode) {
      case VisionMode.sceneUnderstanding:
        return controller.languageManager.getText('btnSurroundings');
      case VisionMode.ocrReading:
        return controller.languageManager.getText('btnReadText');
      case VisionMode.medicineAssistance:
        return controller.languageManager.getText('btnMedicine');
      case VisionMode.currencyRecognition:
        return controller.languageManager.getText('btnCurrency');
      case VisionMode.hazardDetection:
        return controller.languageManager.getText('btnHazards');
      case VisionMode.none:
        return 'Camera View';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SightController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AccessibleHeader(
              title: _getModeTitle(controller),
              onBack: () => Navigator.pop(context),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: controller.cameraService.isFrontCamera
                        ? 'Front camera active. Tap to switch camera'
                        : 'Tap to switch camera',
                    child: IconButton(
                      iconSize: 30,
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: AppColors.secondaryCyan),
                      onPressed: () async {
                        await controller.cameraService.switchCamera();
                        setState(() {
                          _isCameraReady = controller.cameraService.isInitialized;
                        });
                        final camType = controller.cameraService.isFrontCamera ? 'Front webcam' : 'Back camera';
                        await controller.speakCurrentLanguage('$camType ready');
                      },
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: controller.cameraService.isFlashOn ? 'Turn torch off' : 'Turn torch on',
                    child: IconButton(
                      iconSize: 30,
                      icon: Icon(
                        controller.cameraService.isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: controller.cameraService.isFlashOn ? AppColors.primaryYellow : AppColors.textMuted,
                      ),
                      onPressed: () => controller.cameraService.toggleFlash(),
                    ),
                  ),
                ],
              ),
            ),

            // Notice Banner if API Key is missing
            if (!controller.geminiService.hasApiKey)
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.warningOrange.withValues(alpha: 0.2),
                  child: const Row(
                    children: [
                      Icon(Icons.vpn_key_rounded, color: AppColors.warningOrange, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No Gemini API Key set. Tap here to add your free key in Settings.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.warningOrange, size: 16),
                    ],
                  ),
                ),
              ),

            // Camera Viewfinder
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: _captureAndAnalyze,
                child: Semantics(
                  label: 'Camera viewfinder. Tap the yellow button below or double tap anywhere on screen to detect objects.',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isCameraReady && controller.cameraService.controller != null)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.cameraService.controller!.value.previewSize?.height ?? 1,
                              height: controller.cameraService.controller!.value.previewSize?.width ?? 1,
                              child: CameraPreview(controller.cameraService.controller!),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(AppColors.primaryYellow),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _isCameraReady ? 'Preparing Viewfinder...' : 'Connecting to Camera...',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Corner Aiming Guides
                      Positioned(top: 20, left: 20, child: _cornerIndicator(true, true)),
                      Positioned(top: 20, right: 20, child: _cornerIndicator(true, false)),
                      Positioned(bottom: 20, left: 20, child: _cornerIndicator(false, true)),
                      Positioned(bottom: 20, right: 20, child: _cornerIndicator(false, false)),

                      // Live Speech / Result bubble in Auto-Detect mode
                      if (_autoDetect && controller.resultContent.isNotEmpty)
                        Positioned(
                          top: 24,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.secondaryCyan, width: 2),
                            ),
                            child: Text(
                              controller.resultContent,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),

                      // Processing loading overlay
                      if (controller.isProcessing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.85),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 5.5,
                                    valueColor: AlwaysStoppedAnimation(AppColors.secondaryCyan),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  controller.statusMessage.isNotEmpty
                                      ? controller.statusMessage
                                      : 'Analyzing visual input...',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto-Detect live toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _autoDetect ? Icons.autorenew_rounded : Icons.pause_circle_outline_rounded,
                            color: _autoDetect ? AppColors.accentGreen : AppColors.textMuted,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _autoDetect ? 'Live Auto-Scanning: ON' : 'Live Auto-Scanning: OFF',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _autoDetect ? AppColors.accentGreen : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _autoDetect,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: (_) => _toggleAutoDetect(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Big Capture Button
                  AccessibleButton(
                    label: controller.isProcessing ? 'Analyzing Object...' : 'Capture & Identify Object',
                    icon: Icons.camera_alt_rounded,
                    onPressed: _captureAndAnalyze,
                    backgroundColor: AppColors.primaryYellow,
                    textColor: AppColors.textInverse,
                    minHeight: 74,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerIndicator(bool isTop, bool isLeft) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.primaryYellow, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.primaryYellow, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.primaryYellow, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.primaryYellow, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
