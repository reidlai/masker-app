import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/bloc/simulator/simulator_bloc.dart';
import '../../core/bloc/simulator/simulator_event.dart';
import '../../core/bloc/simulator/simulator_state.dart';
import '../../core/config/passkey_simulator_config.dart';
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
  bool get _showDeveloper => _debug || _dev;

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

              // 4 — Developer Section (Conditional)
              if (_showDeveloper) ...[
                const SettingsSectionHeader(title: "Developer"),
                _buildMenuCard(
                  children: [
                    Builder(
                      builder: (context) {
                        bool hasProvider = false;
                        try {
                          context.read<SimulatorBloc>();
                          hasProvider = true;
                        } catch (_) {}

                        Widget rowContent(BuildContext ctx) {
                          return BlocBuilder<SimulatorBloc, SimulatorState>(
                            builder: (bContext, state) {
                              final isSimActive = state.isSimulatorActive;
                              return SettingsMenuRow(
                                leadingIcon: Icons.developer_board,
                                label: "BLE Simulator",
                                showChevron: false,
                                onTap: () {
                                  bContext.read<SimulatorBloc>().add(const SimulatorToggled());
                                },
                                trailingWidget: Switch(
                                  key: const Key('ble-simulator-switch'),
                                  value: isSimActive,
                                  activeThumbColor: AppColors.accentGreen,
                                  onChanged: (val) {
                                    bContext.read<SimulatorBloc>().add(SimulatorEnabledSet(val));
                                  },
                                ),
                              );
                            },
                          );
                        }

                        if (hasProvider) {
                          return rowContent(context);
                        } else {
                          return BlocProvider<SimulatorBloc>(
                            create: (_) => SimulatorBloc(),
                            child: Builder(builder: (bCtx) => rowContent(bCtx)),
                          );
                        }
                      },
                    ),
                    if (_dev) ...[
                      const Divider(height: 1, color: AppColors.cardBorder),
                      ListenableBuilder(
                        listenable: PasskeySimulatorConfig.instance,
                        builder: (context, _) {
                          final enabled = PasskeySimulatorConfig.instance.isEnabled;
                          return SettingsMenuRow(
                            leadingIcon: Icons.fingerprint,
                            label: "Passkey Simulator",
                            showChevron: false,
                            onTap: () =>
                                PasskeySimulatorConfig.instance.setEnabled(!enabled),
                            trailingWidget: Switch(
                              key: const Key('passkey-simulator-switch'),
                              value: enabled,
                              activeThumbColor: AppColors.accentGreen,
                              onChanged: PasskeySimulatorConfig.instance.setEnabled,
                            ),
                          );
                        },
                      ),
                    ],
                    if (_debug) ...[
                      const Divider(height: 1, color: AppColors.cardBorder),
                      const SettingsMenuRow(
                        leadingIcon: Icons.bug_report_outlined,
                        label: "Debugging",
                        showChevron: false,
                      ),
                    ],
                    if (_dev) ...[
                      const Divider(height: 1, color: AppColors.cardBorder),
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
