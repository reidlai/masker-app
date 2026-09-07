import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/language_region/language_region_bloc.dart';
import '../../core/bloc/language_region/language_region_event.dart';
import '../../core/bloc/language_region/language_region_state.dart';
import '../../core/theme/app_theme.dart';

class LanguageRegionPage extends StatelessWidget {
  const LanguageRegionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LanguageRegionBloc>(
      create: (_) => LanguageRegionBloc(),
      child: const _LanguageRegionView(),
    );
  }
}

class _LanguageRegionView extends StatelessWidget {
  const _LanguageRegionView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageRegionBloc, LanguageRegionState>(
      builder: (context, state) {
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
                  _buildGroupedCard(
                      state.languages, state.selectedLanguage, (val) {
                    context
                        .read<LanguageRegionBloc>()
                        .add(LanguageRegionLanguageSelected(val));
                  }),
                  const SizedBox(height: 24),
                  _buildSectionTitle("REGION & LOCALIZATION"),
                  _buildGroupedCard(state.regions, state.selectedRegion, (val) {
                    context
                        .read<LanguageRegionBloc>()
                        .add(LanguageRegionRegionSelected(val));
                  }),
                  const SizedBox(height: 24),
                  _buildSectionTitle("MEASUREMENT UNITS"),
                  _buildGroupedCard(state.units, state.selectedUnits, (val) {
                    context
                        .read<LanguageRegionBloc>()
                        .add(LanguageRegionUnitsSelected(val));
                  }),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildGroupedCard(List<String> options, String selectedValue,
      ValueChanged<String> onSelect) {
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
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppColors.accentGreen, size: 20)
                      : null,
                  onTap: () => onSelect(option),
                ),
                if (!isLast)
                  const Divider(height: 1, color: AppColors.cardBorder),
              ],
            );
          }),
        ),
      ),
    );
  }
}
