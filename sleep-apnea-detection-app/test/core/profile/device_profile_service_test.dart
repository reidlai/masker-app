import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/profile/device_profile.dart';
import 'package:masker_app/core/profile/device_profile_service.dart';

void main() {
  setUp(DeviceProfileService.instance.reset);

  test('starts empty: current is null and stream replays null', () async {
    final svc = DeviceProfileService.instance;
    expect(svc.current, isNull);
    expect(await svc.stream.first, isNull);
  });

  test('set then clear: stream emits the device then null', () async {
    final svc = DeviceProfileService.instance;
    const device = DeviceProfile(bindingId: 'b1', deviceHardwareId: 'DBAND-1');

    expectLater(svc.stream, emitsInOrder([isNull, device, isNull]));

    svc.set(device);
    expect(svc.current, device);
    svc.clear();
    expect(svc.current, isNull);
  });
}
