import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/settings_menu_row.dart';
import '../organisms/settings_group_card_organism.dart';
import 'profile_page.dart';

/// App-level settings. Rendered inline as bottom-nav tab 4.
///
/// [debuggingEnabled] / [developerEnabled] override the build-flag gates for
/// the Advanced rows; when null they fall back to [kDebugMode] and the
/// `DEV_MODE` compile-time environment flag respectively.
class SettingsPage extends StatelessWidget {
  final bool? debuggingEnabled;
  final bool? developerEnabled;

  const SettingsPage({
    super.key,
    this.debuggingEnabled,
    this.developerEnabled,
  });

  bool get _debug => debuggingEnabled ?? kDebugMode;
  bool get _dev =>
      developerEnabled ?? const bool.fromEnvironment('DEV_MODE', defaultValue: false);
  bool get _showAdvanced => _debug || _dev;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Profile Section Card Organism
              SettingsGroupCardOrganism(
                children: [
                  SettingsMenuRow(
                    leadingIcon: Icons.person_outline,
                    label: "Profile",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_showAdvanced)
                // Advanced Settings Group Card Organism
                SettingsGroupCardOrganism(
                  sectionHeader: "Advanced",
                  children: [
                    if (_debug)
                      const SettingsMenuRow(
                        leadingIcon: Icons.bug_report_outlined,
                        label: "Debugging",
                      ),
                    if (_debug && _dev)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.cardBorder,
                      ),
                    if (_dev)
                      const SettingsMenuRow(
                        leadingIcon: Icons.code,
                        label: "Developer",
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
