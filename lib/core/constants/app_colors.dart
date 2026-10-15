import 'package:flutter/material.dart';

/// Accessibility-first WCAG AAA compliant color palette for visually impaired users.
/// Utilizes high luminance contrast ratios (> 7:1) with vibrant primary accents.
class AppColors {
  // Pure / Deep Contrast Backgrounds
  static const Color background = Color(0xFF08090C);
  static const Color surface = Color(0xFF121620);
  static const Color surfaceElevated = Color(0xFF1B202D);
  static const Color surfaceBorder = Color(0xFF2E364A);
  static const Color surfaceGlass = Color(0xFF181E2C);

  // High Luminance Accent Colors (Peak human eye sensitivity)
  static const Color primaryYellow = Color(0xFFFFD600); // Standard high-vis yellow
  static const Color secondaryCyan = Color(0xFF00E5FF); // Electric contrast cyan
  static const Color accentGreen = Color(0xFF00E676);   // Safe confirmation green
  static const Color warningOrange = Color(0xFFFF9100); // Caution / obstacle
  static const Color alertRed = Color(0xFFFF1744);      // High hazard / danger

  // Text Contrast Tokens
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textInverse = Color(0xFF000000);
  static const Color textMuted = Color(0xFF94A3B8);

  // Feature Categorization Colors
  static const Color sceneSurroundings = Color(0xFF00E5FF); // Cyan
  static const Color readText = Color(0xFFFFD600);          // Bright Yellow
  static const Color medicine = Color(0xFF76FF03);          // Lime Green
  static const Color currency = Color(0xFFFFAB00);          // Warm Amber
  static const Color hazards = Color(0xFFFF3D00);           // Deep Orange-Red

  // State Overlays
  static const Color focusRing = Color(0xFFFFD600);
  static const Color disabledBackground = Color(0xFF1E2430);
  static const Color disabledText = Color(0xFF64748B);

  // Glow Shadow Generators for Premium Accessibility Visuals
  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.35, double blur = 16}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
