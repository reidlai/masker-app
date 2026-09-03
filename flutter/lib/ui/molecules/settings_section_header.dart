import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Section label within the Settings list (e.g. "Advanced").
///
/// Rendered by the caller only when the section below it has at least one row.
class SettingsSectionHeader extends StatelessWidget {
  final String label;

  const SettingsSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
