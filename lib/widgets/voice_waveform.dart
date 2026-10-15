import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class VoiceWaveform extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final String label;

  const VoiceWaveform({
    super.key,
    required this.isListening,
    required this.onTap,
    this.label = 'Tap to speak',
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.1, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isListening ? AppColors.secondaryCyan : AppColors.primaryYellow;

    return Semantics(
      button: true,
      label: widget.isListening ? 'Listening to voice command. Tap to stop.' : 'Microphone: ${widget.label}',
      hint: 'Double tap anywhere to toggle microphone',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = widget.isListening ? _scaleAnimation.value : 1.0;
            final outerPulse = widget.isListening ? _pulseAnimation.value : 1.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring when listening
                    if (widget.isListening) ...[
                      Container(
                        width: 155 * outerPulse,
                        height: 155 * outerPulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryCyan.withOpacity(0.12),
                          border: Border.all(
                            color: AppColors.secondaryCyan.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 130 * scale,
                        height: 130 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryCyan.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.secondaryCyan,
                            width: 3.5,
                          ),
                        ),
                      ),
                    ],
                    // Central mic button
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor,
                        boxShadow: AppColors.glowShadow(themeColor, opacity: 0.5, blur: 24),
                      ),
                      child: Icon(
                        widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                        size: 56,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: themeColor, width: 2.5),
                    boxShadow: AppColors.glowShadow(themeColor, opacity: 0.15, blur: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isListening ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                        color: themeColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: themeColor,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
