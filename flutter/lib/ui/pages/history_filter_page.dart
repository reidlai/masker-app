import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/shad_badge.dart';
import 'summary_screen_page.dart';

class HistoryFilterPage extends StatefulWidget {
  const HistoryFilterPage({super.key});

  @override
  State<HistoryFilterPage> createState() => _HistoryFilterPageState();
}

class _HistoryFilterPageState extends State<HistoryFilterPage> {
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _allSessions = const [
    {"date": "Sep 5, 2026", "duration": "7h 45m", "ai": 3.2, "events": 2, "status": "Normal"},
    {"date": "Sep 4, 2026", "duration": "8h 10m", "ai": 3.8, "events": 3, "status": "Normal"},
    {"date": "Sep 3, 2026", "duration": "6h 50m", "ai": 4.0, "events": 3, "status": "Normal"},
    {"date": "Sep 1, 2026", "duration": "7h 15m", "ai": 3.5, "events": 2, "status": "Normal"},
    {"date": "Aug 31, 2026", "duration": "7h 30m", "ai": 16.4, "events": 14, "status": "Moderate"},
    {"date": "Aug 30, 2026", "duration": "8h 05m", "ai": 2.9, "events": 2, "status": "Normal"},
  ];

  List<Map<String, dynamic>> get _filteredSessions {
    if (_selectedFilterIndex == 1) {
      return _allSessions.where((s) => (s['ai'] as double) < 5.0).toList();
    } else if (_selectedFilterIndex == 2) {
      return _allSessions.where((s) => (s['ai'] as double) >= 5.0 && (s['ai'] as double) < 30.0).toList();
    } else if (_selectedFilterIndex == 3) {
      return _allSessions.where((s) => (s['ai'] as double) >= 30.0).toList();
    }
    return _allSessions;
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("All", 0),
                    _buildFilterChip("Normal (<5)", 1),
                    _buildFilterChip("Moderate (5–29)", 2),
                    _buildFilterChip("Severe (≥30)", 3),
                  ],
                ),
              ),
            ),
            // Session List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _filteredSessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = _filteredSessions[index];
                  final double ai = session['ai'];
                  final String date = session['date'];
                  final String duration = session['duration'];
                  final int events = session['events'];

                  ShadBadgeVariant badgeVariant = ShadBadgeVariant.normal;
                  if (ai >= 30.0) {
                    badgeVariant = ShadBadgeVariant.severe;
                  } else if (ai >= 5.0) {
                    badgeVariant = ShadBadgeVariant.moderate;
                  }

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
                        border: Border.all(color: AppColors.cardBorder, width: 1),
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
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
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
        onSelected: (_) {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
      ),
    );
  }
}
