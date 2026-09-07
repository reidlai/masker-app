import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:permission_handler/permission_handler.dart';

/// Coarse outcome of a Bluetooth permission check/request.
///
/// Never persisted — every call re-derives this from the live OS permission
/// status so a later revocation (e.g. via system Settings) is always caught
/// on the next check.
enum BlePermissionResult { granted, denied, partial }

/// Result of a permission check/request, naming whichever platform
/// permission(s) are not currently granted so the UI can render specific
/// blocked-state copy (e.g. "Bluetooth Connect permission is required").
class BlePermissionStatus {
  final BlePermissionResult result;
  final List<String> missingPermissionNames;

  const BlePermissionStatus(this.result, this.missingPermissionNames);

  bool get isGranted => result == BlePermissionResult.granted;
}

/// Thin seam over `permission_handler` for the BLE background-access
/// permission(s) the app needs to run its BLE receiver:
/// - Android: `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`, requested together.
/// - iOS: `NSBluetoothAlwaysUsageDescription` (`Permission.bluetooth`).
///
/// Every method reads live OS status — no `shared_preferences` or other
/// persistence is used, so gating a screen on this service always reflects
/// current reality, never a stale "seen it" flag.
class BlePermissionService {
  const BlePermissionService();

  static final Map<Permission, String> _permissionNames = {
    Permission.bluetoothScan: 'Bluetooth Scan',
    Permission.bluetoothConnect: 'Bluetooth Connect',
    Permission.bluetooth: 'Bluetooth',
  };

  List<Permission> get _requiredPermissions => defaultTargetPlatform == TargetPlatform.iOS
      ? const [Permission.bluetooth]
      : const [Permission.bluetoothScan, Permission.bluetoothConnect];

  /// Checks the current live status of every required permission without
  /// prompting the user.
  Future<BlePermissionStatus> checkPermission() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in _requiredPermissions) {
      statuses[permission] = await permission.status;
    }
    return _resolve(statuses);
  }

  /// Requests every required permission from the OS (showing its native
  /// dialog(s) if not already resolved) and returns the resulting status.
  Future<BlePermissionStatus> requestPermission() async {
    final statuses = await _requiredPermissions.request();
    return _resolve(statuses);
  }

  /// Opens the OS app-settings screen so the user can grant a permission the
  /// app can no longer prompt for natively (permanently denied / one-shot
  /// iOS dialog already consumed).
  Future<bool> openSettings() => openAppSettings();

  BlePermissionStatus _resolve(Map<Permission, PermissionStatus> statuses) {
    var grantedCount = 0;
    final missing = <String>[];

    for (final entry in statuses.entries) {
      if (entry.value.isGranted) {
        grantedCount++;
      } else {
        missing.add(_permissionNames[entry.key] ?? entry.key.toString());
      }
    }

    final BlePermissionResult result;
    if (grantedCount == statuses.length) {
      result = BlePermissionResult.granted;
    } else if (grantedCount == 0) {
      result = BlePermissionResult.denied;
    } else {
      result = BlePermissionResult.partial;
    }

    return BlePermissionStatus(result, missing);
  }
}
