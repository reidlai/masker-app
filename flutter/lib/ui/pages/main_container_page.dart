import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'history_filter_page.dart';
import 'home_page.dart';
import 'measurement_page.dart';
import 'summary_screen_page.dart';
import 'settings_page.dart';

class MainContainerPage extends StatefulWidget {
  const MainContainerPage({super.key});

  @override
  State<MainContainerPage> createState() => _MainContainerPageState();
}

class _MainContainerPageState extends State<MainContainerPage> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onOpenSummary: () => _navigateToTab(2),
        onOpenHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HistoryFilterPage(),
            ),
          );
        },
      ),
      const MeasurementPage(),
      SummaryScreenPage(
        onOpenHistory: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HistoryFilterPage(),
            ),
          );
        },
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.house_outlined, size: 24),
              activeIcon: Icon(Icons.house, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.nightlight_outlined, size: 24),
              activeIcon: Icon(Icons.nightlight_round, size: 24),
              label: 'Monitor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined, size: 24),
              activeIcon: Icon(Icons.bar_chart, size: 24),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 24),
              activeIcon: Icon(Icons.settings, size: 24),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
