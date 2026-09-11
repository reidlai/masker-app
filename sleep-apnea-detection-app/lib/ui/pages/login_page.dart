import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc/auth/auth_bloc.dart';
import '../../core/bloc/auth/auth_event.dart';
import '../../core/bloc/auth/auth_state.dart';
import '../../core/config/passkey_simulator_config.dart';
import '../../core/theme/app_theme.dart';
import '../organisms/brand_header_organism.dart';
import '../organisms/passkey_auth_card_organism.dart';
import '../organisms/security_badge_organism.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  /// Test seams for the developer-row gate, left null in production. `main`
  /// builds this page without them, so the gate resolves to
  /// `kDebugMode || DEV_MODE`. These mirror `SettingsPage.debuggingEnabled` /
  /// `SettingsPage.developerEnabled` exactly, so the same overrides hide/show
  /// the control on both screens identically.
  final bool? debuggingEnabled;
  final bool? developerEnabled;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    this.debuggingEnabled,
    this.developerEnabled,
  });

  /// Same disjunction `SettingsPage._showDeveloper` uses, so the login-screen
  /// control and the Settings → Developer row appear and disappear together.
  bool get _showDev =>
      (debuggingEnabled ?? kDebugMode) ||
      (developerEnabled ??
          const bool.fromEnvironment('DEV_MODE', defaultValue: false));

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          onLoginSuccess();
        }
      },
      builder: (context, state) {
        final isAuthenticating = state is AuthInProgress;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 0,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          // Brand Header Organism
                          const BrandHeaderOrganism(),
                          const Spacer(),
                          // Passkey Auth Card Organism
                          PasskeyAuthCardOrganism(
                            isAuthenticating: isAuthenticating,
                            onAuthenticate: () {
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthPasskeySubmitted());
                            },
                          ),
                          // Non-success outcomes surface directly under the
                          // button. AuthUnavailable = "not wired up yet" (amber,
                          // not a fault); AuthFailure = a real authenticator
                          // error (red).
                          if (state is AuthUnavailable ||
                              state is AuthFailure) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                state is AuthUnavailable
                                    ? state.message
                                    : (state as AuthFailure).errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: state is AuthUnavailable
                                      ? AppColors.warningAmber
                                      : AppColors.dangerRed,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // Developer-only: same gate as Settings → Developer.
                          // Bound to the shared PasskeySimulatorConfig singleton
                          // so this switch and the Settings row stay in sync.
                          if (_showDev) ...[
                            ListenableBuilder(
                              listenable: PasskeySimulatorConfig.instance,
                              builder: (context, _) {
                                final on =
                                    PasskeySimulatorConfig.instance.isEnabled;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _DevPasskeySimRow(
                                      value: on,
                                      onChanged: isAuthenticating
                                          ? null
                                          : PasskeySimulatorConfig
                                              .instance.setEnabled,
                                    ),
                                    if (on)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: Text(
                                          "Simulated authentication — not real FIDO2",
                                          key: Key('passkey-sim-caption'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.warningAmber,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Security Badge Organism
                          const SecurityBadgeOrganism(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Developer "Passkey Simulator" row shown on the sign-in screen under a
/// `kDebugMode || DEV_MODE` gate. A bordered, teal-outlined frame marks it as a
/// developer control rather than a production setting. `onChanged: null` (passed
/// while authenticating) renders the switch disabled.
///
/// The `Icons.developer_mode` glyph (not the biometric fingerprint used in the
/// auth card above) signals this is a dev toggle. `MergeSemantics` folds the
/// label, the "developer only" marker, and the switch state into one node so a
/// screen reader announces "Passkey Simulator" once, not twice.
class _DevPasskeySimRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _DevPasskeySimRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 14, right: 6, top: 2, bottom: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.developer_mode,
                color: AppColors.accentGreen, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Passkey Simulator",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Semantics(
              label: "Developer only",
              child: Switch(
                key: const Key('passkey-simulator-switch-login'),
                value: value,
                activeThumbColor: AppColors.accentGreen,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
