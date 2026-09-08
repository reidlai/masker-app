<!-- bmad:context -->
<!-- Verified 2026-09-08 against c085354. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## masker-app

Cross-platform Flutter/Dart application for at-home nocturnal sleep apnea monitoring, real-time AASM breathing event detection, thermal BLE sensor calibration, and WebAuthn/Passkey authentication. Stack: `flutter_bloc: ^8.1.3`, `rxdart: ^0.28.0`, `flutter_blue_plus`. Planning specs live in `_bmad-output/` and `docs/`.

## Policy

- Never push directly to `main`; work on feature/fix branches and submit Pull Requests.
- Use relative repository paths for file links in `README.md` and documentation files.
- Preserve atomic design system hierarchy (`lib/ui/atoms`, `lib/ui/molecules`, `lib/ui/organisms`, `lib/ui/pages`).

## Where things are

- BLE hardware driver & simulation: [`flutter/lib/core/ble/`](flutter/lib/core/ble/) (`flutter_blue_sensor_driver.dart`, `ble_simulator_driver.dart`, `mock_ble_sensor_driver.dart`)
- Sleep monitoring & signal processing: [`flutter/lib/core/bloc/monitoring/`](flutter/lib/core/bloc/monitoring/), [`flutter/lib/core/monitoring/`](flutter/lib/core/monitoring/)
- Project specifications & planning docs: [`_bmad-output/`](_bmad-output/) and [`docs/`](docs/)

## Running and verifying

- Execute `flutter test` from the `flutter/` directory to run all 181 unit & widget tests across BLoCs, UI organisms, and drivers.
- Enable developer mode in Flutter via `--dart-define=DEV_MODE=true`.

## Conventions that differ from defaults

- Use `MockBLESensorDriver` (`mock_ble_sensor_driver.dart`) for pure unit testing; use `BleSimulatorDriver` for dev/QA simulator scenarios; use `FlutterBlueSensorDriver` for physical hardware.
- High-frequency 10 Hz BLE telemetry is throttled to 5 FPS (200 ms) in `BleBloc` using RxDart `sampleTime` and `distinct` for battery optimization.

## Known pitfalls

- Never invoke blocking thread calls on main UI loops.
- `BleReceiverService` initializes `BehaviorSubject<double>` with a resting seed (`0.3`) to prevent null rendering artifacts before the first hardware sample arrives.

<!-- /bmad:context -->
