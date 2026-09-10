import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WeeklyCalendarOrganism extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDaySelected;

  const WeeklyCalendarOrganism({
    super.key,
    this.selectedIndex = 5,
    this.onDaySelected,
  });

  @override
  State<WeeklyCalendarOrganism> createState() => _WeeklyCalendarOrganismState();
}

class _WeeklyCalendarOrganismState extends State<WeeklyCalendarOrganism> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
    final dates = [7, 8, 9, 10, 11, 12, 13];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Weekly",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "< Monthly >",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = index == _currentIndex;
              return InkWell(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (widget.onDaySelected != null) {
                    widget.onDaySelected!(index);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${dates[index]}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
