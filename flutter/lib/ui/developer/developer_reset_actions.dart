import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_receiver_service.dart';
import '../../core/bloc/auth/auth_bloc.dart';
import '../../core/bloc/auth/auth_event.dart';
import '../../core/theme/app_theme.dart';

/// Confirm-and-reset developer flows used by the Settings → Developer section.
///
/// Each flow shows a two-step confirmation `AlertDialog`; on confirm it performs
/// the reset and shows a success `SnackBar`. Guarded by `context.mounted` across
/// every async gap.
class DeveloperResetActions {
  const DeveloperResetActions._();

  static Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content:
            Text(content, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirm Reset"),
          ),
        ],
      ),
    );
  }

  /// Unbind the paired BLE sensor: drop the active stream and reset the
  /// receiver's telemetry queue / noise-floor state to the initial scan state.
  static Future<void> unbindBleDevice(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: "Unbind BLE Sensor?",
      content:
          "Resets paired device address, clears noise floor envelope, and returns to initial scanning state.",
    );
    if (confirm != true || !context.mounted) return;

    BleReceiverService().disconnect();
    BleReceiverService().resetForTest();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("BLE Sensor Device unbound successfully."),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  /// Unregister the local user account: dispatch [AuthUnregisterRequested],
  /// clearing local credentials/profile, and pop back to Phase 1 onboarding.
  static Future<void> unregisterAccount(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: "Unregister User Account?",
      content:
          "Deletes local Passkey credentials, clears patient profile, and restarts Phase 1 Onboarding.",
    );
    if (confirm != true || !context.mounted) return;

    try {
      context.read<AuthBloc>().add(const AuthUnregisterRequested());
    } catch (_) {
      // No AuthBloc in scope (e.g. isolated widget tests) — reset is a no-op.
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("User Account unregistered. Navigating to Onboarding..."),
        backgroundColor: AppColors.accentGreen,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
