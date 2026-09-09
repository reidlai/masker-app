import 'package:flutter/foundation.dart';

/// Runtime holder for the developer "Passkey Simulator" flag.
///
/// When enabled, [AuthBloc] takes the simulated passkey path (a brief delay
/// that always authenticates). When disabled, [AuthBloc] routes to the real
/// FIDO2/WebAuthn authenticator once one is wired.
///
/// In-memory only — there is no persistence, so the flag resets to its default
/// (`true`) on every app launch, mirroring [BleSimulatorDriver] / [SimulatorBloc].
/// The flag is only meaningful under `DEV_MODE`; outside it the row is hidden
/// and [main] forces the effective value off.
class PasskeySimulatorConfig extends ChangeNotifier {
  PasskeySimulatorConfig._();

  static final PasskeySimulatorConfig instance = PasskeySimulatorConfig._();

  bool _enabled = true;

  /// Whether the passkey simulator is currently enabled. Defaults to `true`.
  bool get isEnabled => _enabled;

  /// Set the flag and notify listeners when the value actually changes.
  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  /// Restore the default (`true`). For test isolation.
  void reset() => setEnabled(true);
}

/// Whether the simulated passkey path should actually be taken, given the
/// build's `DEV_MODE`. Always `false` outside `DEV_MODE` so a release build can
/// never bypass real authentication, whatever the stored flag says. This is the
/// single gate [main] wires into [AuthBloc]; keep the `DEV_MODE` conjunct.
bool passkeySimulatorActive({required bool devMode}) =>
    devMode && PasskeySimulatorConfig.instance.isEnabled;
