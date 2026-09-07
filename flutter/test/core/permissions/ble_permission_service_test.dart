import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/permissions/ble_permission_service.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// Fake `permission_handler` platform implementation used to drive
/// [BlePermissionService] through every OS-reported status without touching
/// real native permission channels — the "test platform override" the spec
/// calls for.
class _FakePermissionHandlerPlatform extends PermissionHandlerPlatform {
  Map<Permission, PermissionStatus> statuses = {};
  Map<Permission, PermissionStatus>? requestResult;
  bool openSettingsCalled = false;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return statuses[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    final result = requestResult ?? statuses;
    return {for (final p in permissions) p: result[p] ?? PermissionStatus.denied};
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(Permission permission) async => false;

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async => ServiceStatus.enabled;
}

void main() {
  late _FakePermissionHandlerPlatform fakePlatform;
  late BlePermissionService service;

  setUp(() {
    fakePlatform = _FakePermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = fakePlatform;
    service = const BlePermissionService();
  });

  group('BlePermissionService on Android', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('checkPermission is granted when scan + connect both granted', () async {
      fakePlatform.statuses = {
        Permission.bluetoothScan: PermissionStatus.granted,
        Permission.bluetoothConnect: PermissionStatus.granted,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.granted);
      expect(status.isGranted, isTrue);
      expect(status.missingPermissionNames, isEmpty);
    });

    test('checkPermission is denied when scan + connect both denied', () async {
      fakePlatform.statuses = {
        Permission.bluetoothScan: PermissionStatus.denied,
        Permission.bluetoothConnect: PermissionStatus.denied,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.denied);
      expect(status.isGranted, isFalse);
      expect(status.missingPermissionNames, containsAll(['Bluetooth Scan', 'Bluetooth Connect']));
    });

    test('checkPermission is partial when only one of scan/connect granted', () async {
      fakePlatform.statuses = {
        Permission.bluetoothScan: PermissionStatus.granted,
        Permission.bluetoothConnect: PermissionStatus.denied,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.partial);
      expect(status.missingPermissionNames, ['Bluetooth Connect']);
    });

    test('checkPermission treats permanentlyDenied as not granted', () async {
      fakePlatform.statuses = {
        Permission.bluetoothScan: PermissionStatus.permanentlyDenied,
        Permission.bluetoothConnect: PermissionStatus.permanentlyDenied,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.denied);
      expect(status.isGranted, isFalse);
    });

    test('requestPermission reflects the platform request outcome', () async {
      fakePlatform.requestResult = {
        Permission.bluetoothScan: PermissionStatus.granted,
        Permission.bluetoothConnect: PermissionStatus.denied,
      };

      final status = await service.requestPermission();

      expect(status.result, BlePermissionResult.partial);
      expect(status.missingPermissionNames, ['Bluetooth Connect']);
    });

    test('openSettings delegates to the platform openAppSettings', () async {
      final opened = await service.openSettings();

      expect(opened, isTrue);
      expect(fakePlatform.openSettingsCalled, isTrue);
    });
  });

  group('BlePermissionService on iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('checkPermission checks only Permission.bluetooth', () async {
      fakePlatform.statuses = {
        Permission.bluetooth: PermissionStatus.granted,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.granted);
    });

    test('checkPermission denied names Bluetooth as missing', () async {
      fakePlatform.statuses = {
        Permission.bluetooth: PermissionStatus.denied,
      };

      final status = await service.checkPermission();

      expect(status.result, BlePermissionResult.denied);
      expect(status.missingPermissionNames, ['Bluetooth']);
    });
  });
}
