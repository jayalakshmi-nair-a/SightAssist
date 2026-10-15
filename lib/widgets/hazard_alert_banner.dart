import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/hazard_info.dart';

class HazardAlertBanner extends StatelessWidget {
  final String alertText;
  final HazardUrgency urgency;

  const HazardAlertBanner({
    super.key,
    required this.alertText,
    this.urgency = HazardUrgency.warning,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    IconData icon;

    switch (urgency) {
      case HazardUrgency.critical:
        bg = AppColors.alertRed.withValues(alpha: 0.25);
        border = AppColors.alertRed;
        icon = Icons.warning_amber_rounded;
        break;
      case HazardUrgency.warning:
        bg = AppColors.warningOrange.withValues(alpha: 0.25);
        border = AppColors.warningOrange;
        icon = Icons.error_outline_rounded;
        break;
      case HazardUrgency.advisory:
        bg = AppColors.accentGreen.withValues(alpha: 0.25);
        border = AppColors.accentGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              alertText,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
