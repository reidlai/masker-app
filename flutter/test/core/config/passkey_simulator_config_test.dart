import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/config/passkey_simulator_config.dart';

void main() {
  setUp(() => PasskeySimulatorConfig.instance.reset());

  group('PasskeySimulatorConfig', () {
    test('defaults to enabled', () {
      expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);
    });

    test('setEnabled notifies listeners only on an actual change', () {
      var notifications = 0;
      void listener() => notifications++;
      PasskeySimulatorConfig.instance.addListener(listener);
      addTearDown(
          () => PasskeySimulatorConfig.instance.removeListener(listener));

      PasskeySimulatorConfig.instance.setEnabled(true); // no-op
      expect(notifications, 0);

      PasskeySimulatorConfig.instance.setEnabled(false);
      expect(notifications, 1);

      PasskeySimulatorConfig.instance.setEnabled(false); // no-op
      expect(notifications, 1);
    });

    test('reset restores the enabled default', () {
      PasskeySimulatorConfig.instance.setEnabled(false);
      PasskeySimulatorConfig.instance.reset();
      expect(PasskeySimulatorConfig.instance.isEnabled, isTrue);
    });
  });

  group('passkeySimulatorActive gate', () {
    test('is always false outside DEV_MODE, regardless of the stored flag', () {
      expect(passkeySimulatorActive(devMode: false), isFalse);

      PasskeySimulatorConfig.instance.setEnabled(true);
      expect(passkeySimulatorActive(devMode: false), isFalse);

      PasskeySimulatorConfig.instance.setEnabled(false);
      expect(passkeySimulatorActive(devMode: false), isFalse);
    });

    test('under DEV_MODE, mirrors the stored flag', () {
      expect(passkeySimulatorActive(devMode: true), isTrue); // default enabled

      PasskeySimulatorConfig.instance.setEnabled(false);
      expect(passkeySimulatorActive(devMode: true), isFalse);

      PasskeySimulatorConfig.instance.setEnabled(true);
      expect(passkeySimulatorActive(devMode: true), isTrue);
    });
  });
}
