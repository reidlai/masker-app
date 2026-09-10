import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/ble_receiver_service.dart';
import '../../core/bloc/app_flow/app_flow_bloc.dart';
import '../../core/bloc/app_flow/app_flow_event.dart';
import '../../core/bloc/auth/auth_bloc.dart';
import '../../core/bloc/auth/auth_event.dart';
import '../../core/data/profile_repository.dart';
import '../../core/profile/device_profile_service.dart';
import '../../core/profile/user_profile_service.dart';
import '../../core/theme/app_theme.dart';

/// Confirm-and-run account / device flows for the Settings page: the two
/// developer reset rows and the (non-developer) Log out row.
///
/// Each flow shows a confirmation `AlertDialog`; the reset flows call
/// [ProfileRepository] first and abort with an error `SnackBar` if it throws,
/// otherwise perform the local work, empty the matching profile store, and show
/// a success `SnackBar`. Guarded by `context.mounted` across every async gap.
class SettingsActions {
  const SettingsActions._();

  static Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = "Confirm Reset",
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  /// Unbind the paired BLE sensor: server unbind → drop the active stream and
  /// reset the receiver's telemetry queue → empty the device-profile store.
  static Future<void> unbindBleDevice(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: "Unbind BLE Sensor?",
      content:
          "Resets paired device address, clears noise floor envelope, and returns to initial scanning state.",
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ProfileRepository.instance.unbindDevice();
    } catch (_) {
      if (context.mounted) {
        _snack(context, "Couldn't unbind device — try again.", Colors.redAccent);
      }
      return;
    }
    if (!context.mounted) return;

    BleReceiverService().disconnect();
    BleReceiverService().resetForTest();
    DeviceProfileService.instance.clear();

    _snack(context, "BLE Sensor Device unbound successfully.",
        AppColors.accentGreen);
  }

  /// Unregister the local user account: server unregister → empty **both**
  /// profile stores → clear auth and drive the app flow back to the login
  /// screen. No `Navigator` work — the root `BlocBuilder<AppFlowBloc>` swaps
  /// `home` on the `loggedOut` stage.
  static Future<void> unregisterAccount(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: "Unregister User Account?",
      content:
          "Deletes local Passkey credentials, clears patient profile, and returns to sign-in.",
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ProfileRepository.instance.unregisterUser();
    } catch (_) {
      if (context.mounted) {
        _snack(context, "Couldn't unregister account — try again.",
            Colors.redAccent);
      }
      return;
    }
    if (!context.mounted) return;

    UserProfileService.instance.clear();
    DeviceProfileService.instance.clear();
    context.read<AuthBloc>().add(const AuthUnregisterRequested());
    context.read<AppFlowBloc>().add(const AppFlowLogoutRequested());
  }

  /// Log out: empty both profile stores, clear auth, and drive the app flow
  /// back to the login screen. No `Navigator` work — the root
  /// `BlocBuilder<AppFlowBloc>` swaps `home` on the `loggedOut` stage.
  static Future<void> logOut(BuildContext context) async {
    final confirm = await _confirm(
      context,
      title: "Log out?",
      content: "You'll need to sign in with your passkey again.",
      confirmLabel: "Log out",
    );
    if (confirm != true || !context.mounted) return;

    UserProfileService.instance.clear();
    DeviceProfileService.instance.clear();
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    context.read<AppFlowBloc>().add(const AppFlowLogoutRequested());
  }
}
