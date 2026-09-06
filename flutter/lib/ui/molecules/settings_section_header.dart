import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final bool isFirst;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 4.0 : 24.0,
        bottom: 8.0,
        left: 4.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.04,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
