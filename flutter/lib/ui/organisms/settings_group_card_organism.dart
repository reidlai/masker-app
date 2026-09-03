import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsGroupCardOrganism extends StatelessWidget {
  final List<Widget> children;
  final String? sectionHeader;

  const SettingsGroupCardOrganism({
    super.key,
    required this.children,
    this.sectionHeader,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: children,
      ),
    );

    if (sectionHeader != null && sectionHeader!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
            child: Text(
              sectionHeader!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          cardWidget,
        ],
      );
    }

    return cardWidget;
  }
}
