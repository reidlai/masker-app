import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A single row in the Settings list.
///
/// Navigable variant (`onTap` provided): tappable with a pressed highlight,
/// full-contrast label, and a trailing chevron.
/// Inert variant (`onTap` omitted): not tappable, muted label, no chevron.
class SettingsMenuRow extends StatelessWidget {
  final IconData leadingIcon;
  final String label;
  final VoidCallback? onTap;

  const SettingsMenuRow({
    super.key,
    required this.leadingIcon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool navigable = onTap != null;
    final Color contentColor =
        navigable ? AppColors.textPrimary : AppColors.textSecondary;

    final Widget row = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(leadingIcon, size: 20, color: contentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: contentColor,
              ),
            ),
          ),
          if (navigable)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (!navigable) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.pressedSurface,
        splashColor: AppColors.pressedSurface,
        child: row,
      ),
    );
  }
}
