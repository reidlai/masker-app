import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ShadBadgeVariant {
  normal,
  moderate,
  severe,
  active,
  amberAlert,
  outline,
}

class ShadBadge extends StatelessWidget {
  final String label;
  final ShadBadgeVariant variant;
  final Widget? icon;

  const ShadBadge({
    super.key,
    required this.label,
    this.variant = ShadBadgeVariant.normal,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case ShadBadgeVariant.normal:
      case ShadBadgeVariant.active:
        bgColor = AppColors.accentGreen.withValues(alpha: 0.12);
        textColor = AppColors.accentGreen;
        break;
      case ShadBadgeVariant.moderate:
      case ShadBadgeVariant.amberAlert:
        bgColor = AppColors.warningAmber.withValues(alpha: 0.14);
        textColor = AppColors.warningAmber;
        break;
      case ShadBadgeVariant.severe:
        bgColor = AppColors.dangerRed.withValues(alpha: 0.14);
        textColor = AppColors.dangerRed;
        break;
      case ShadBadgeVariant.outline:
        bgColor = Colors.transparent;
        textColor = AppColors.textSecondary;
        borderSide = const BorderSide(color: AppColors.cardBorder, width: 1.0);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }
}
