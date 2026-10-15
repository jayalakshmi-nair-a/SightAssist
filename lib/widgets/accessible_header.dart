import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/haptic_feedback_helper.dart';

class AccessibleHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AccessibleHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onBack != null) ...[
              Semantics(
                button: true,
                label: 'Back button',
                hint: 'Double tap to go back',
                child: IconButton(
                  iconSize: 34,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryYellow),
                  onPressed: () {
                    HapticFeedbackHelper.lightTap();
                    onBack!();
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
