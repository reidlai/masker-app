import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/history/history_bloc.dart';
import '../../core/bloc/history/history_event.dart';
import '../../core/bloc/history/history_state.dart';
import '../../core/constants/apnea_copy.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_badge.dart';
import 'summary_screen_page.dart';

class HistoryFilterPage extends StatelessWidget {
  const HistoryFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (_) => HistoryBloc(),
      child: const _HistoryFilterView(),
    );
  }
}

class _HistoryFilterView extends StatelessWidget {
  const _HistoryFilterView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final filteredSessions = state.filteredSessions;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text("Session History"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Filter Chips Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                            context, "All", 0, state.selectedFilterIndex),
                        _buildFilterChip(context, "Normal (<5)", 1,
                            state.selectedFilterIndex),
                        _buildFilterChip(context, "Mild (5–15)", 2,
                            state.selectedFilterIndex),
                        _buildFilterChip(context, "Moderate (15–30)", 3,
                            state.selectedFilterIndex),
                        _buildFilterChip(context, "Severe (≥30)", 4,
                            state.selectedFilterIndex),
                      ],
                    ),
                  ),
                ),
                // Apnea-only caveat — shown once for the whole list, not per row.
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    kApneaOnlyCaveat,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Session List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: filteredSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      final double ai = session['ai'];
                      final String date = session['date'];
                      final String duration = session['duration'];
                      final int events = session['events'];

                      final ShadBadgeVariant badgeVariant =
                          switch (HistoryState.severityFor(ai)) {
                        HistorySeverity.severe => ShadBadgeVariant.severe,
                        HistorySeverity.moderate => ShadBadgeVariant.moderate,
                        HistorySeverity.mild => ShadBadgeVariant.moderate,
                        HistorySeverity.normal => ShadBadgeVariant.normal,
                      };

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SummaryScreenPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.cardBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "· $duration",
                                          style: AppTheme.tabularTextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "$events apnea events recorded",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              ShadBadge(
                                label: "AI ${ai.toStringAsFixed(1)}",
                                variant: badgeVariant,
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.background : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.accentGreen,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
        onSelected: (_) =>
            context.read<HistoryBloc>().add(HistoryFilterSelected(index)),
      ),
    );
  }
}
