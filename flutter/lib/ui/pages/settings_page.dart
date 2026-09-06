import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../molecules/settings_menu_row.dart';
import '../molecules/settings_section_header.dart';
import 'billing_page.dart';
import 'developer_options_page.dart';
import 'language_region_page.dart';
import 'payment_method_page.dart';
import 'profile_page.dart';

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
      appBar: AppBar(
        title: const Text("Settings"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1 — Account Section
              const SettingsSectionHeader(title: "Account", isFirst: true),
              _buildMenuCard(
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

              // 2 — Preferences Section
              const SettingsSectionHeader(title: "Preferences"),
              _buildMenuCard(
                children: [
                  SettingsMenuRow(
                    leadingIcon: Icons.language,
                    label: "Language & Region",
                    valueText: "English",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageRegionPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 3 — Subscription Section
              const SettingsSectionHeader(title: "Subscription"),
              _buildMenuCard(
                children: [
                  SettingsMenuRow(
                    leadingIcon: Icons.receipt_long_outlined,
                    label: "Billing & subscription",
                    valueText: "Premium",
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BillingPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  SettingsMenuRow(
                    leadingIcon: Icons.credit_card_outlined,
                    label: "Payment method",
                    valueText: "Visa ·· 4242",
                    hasStatusDot: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentMethodPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 4 — Advanced Section (Conditional)
              if (_showAdvanced) ...[
                const SettingsSectionHeader(title: "Advanced"),
                _buildMenuCard(
                  children: [
                    if (_debug)
                      const SettingsMenuRow(
                        leadingIcon: Icons.bug_report_outlined,
                        label: "Debugging",
                        showChevron: false,
                      ),
                    if (_debug && _dev)
                      const Divider(height: 1, color: AppColors.cardBorder),
                    if (_dev)
                      SettingsMenuRow(
                        leadingIcon: Icons.code,
                        label: "Developer",
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DeveloperOptionsPage(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(children: children),
    );
  }
}
