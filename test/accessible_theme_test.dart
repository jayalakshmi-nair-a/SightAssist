import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sightassist/core/constants/app_colors.dart';
import 'package:sightassist/core/theme/accessible_theme.dart';

void main() {
  group('AccessibleTheme & AppColors Tests', () {
    test('Theme is dark high-contrast', () {
      final theme = AccessibleTheme.highContrastDarkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
      expect(theme.primaryColor, equals(AppColors.primaryYellow));
    });

    test('High contrast color definitions exist', () {
      expect(AppColors.primaryYellow, isA<Color>());
      expect(AppColors.secondaryCyan, isA<Color>());
      expect(AppColors.warningOrange, isA<Color>());
      expect(AppColors.alertRed, isA<Color>());
    });
  });
}
