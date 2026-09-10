import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsMenuRow extends StatelessWidget {
  final IconData leadingIcon;
  final String label;
  final String? valueText;
  final bool hasStatusDot;
  final bool showChevron;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const SettingsMenuRow({
    super.key,
    required this.leadingIcon,
    required this.label,
    this.valueText,
    this.hasStatusDot = false,
    this.showChevron = true,
    this.trailingWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNavigable = onTap != null;

    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(
            leadingIcon,
            size: 22,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isNavigable || valueText != null || trailingWidget != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (trailingWidget != null) ...[
            trailingWidget!,
          ] else ...[
            if (hasStatusDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.warningAmber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (valueText != null) ...[
              Text(
                valueText!,
                style: AppTheme.tabularTextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ],
      ),
    );

    if (isNavigable) {
      return InkWell(
        onTap: onTap,
        highlightColor: AppColors.pressedSurface,
        splashColor: AppColors.pressedSurface,
        child: content,
      );
    }

    return content;
  }
}
