import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LanguageRegionPage extends StatefulWidget {
  const LanguageRegionPage({super.key});

  @override
  State<LanguageRegionPage> createState() => _LanguageRegionPageState();
}

class _LanguageRegionPageState extends State<LanguageRegionPage> {
  String _selectedLanguage = "English (US)";
  String _selectedRegion = "United States";
  String _selectedUnits = "Metric (kg, cm)";

  final List<String> _languages = const [
    "English (US)",
    "English (UK)",
    "Spanish (Español)",
    "German (Deutsch)",
    "French (Français)",
  ];

  final List<String> _regions = const [
    "United States",
    "United Kingdom",
    "European Union",
    "Canada",
    "Australia",
  ];

  final List<String> _units = const [
    "Metric (kg, cm)",
    "Imperial (lb, in)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Language & Region"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("APPLICATION LANGUAGE"),
              _buildGroupedCard(_languages, _selectedLanguage, (val) {
                setState(() => _selectedLanguage = val);
              }),
              const SizedBox(height: 24),
              _buildSectionTitle("REGION & LOCALIZATION"),
              _buildGroupedCard(_regions, _selectedRegion, (val) {
                setState(() => _selectedRegion = val);
              }),
              const SizedBox(height: 24),
              _buildSectionTitle("MEASUREMENT UNITS"),
              _buildGroupedCard(_units, _selectedUnits, (val) {
                setState(() => _selectedUnits = val);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.04,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<String> options, String selectedValue, ValueChanged<String> onSelect) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = option == selectedValue;
            final isLast = index == options.length - 1;

            return Column(
              children: [
                ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.accentGreen, size: 20)
                      : null,
                  onTap: () => onSelect(option),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.cardBorder),
              ],
            );
          }),
        ),
      ),
    );
  }
}
