---
title: 'Fix: Monitor tab shows "D-BAND Sensor Connected" after BLE Simulator is turned off'
type: 'bugfix'
created: '2026-09-11'
status: 'done'
review_loop_iteration: 1
baseline_commit: '1c2f51d017610d075f21f8b06e7200a0cfab3feb'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Turning "BLE Simulator" off in Settings does not update the Monitor tab's connection banner or calibration UI — "D-BAND Sensor Connected ✓" keeps showing (with synthetic data) even on an AVD with no real BLE hardware. **Corrected root cause** (revised in review — see Spec Change Log): `main.dart` *does* provide one shared `BlocProvider<SimulatorBloc>` reaching `MeasurementPage` as an `IndexedStack` sibling of Home/Settings, so ancestor visibility was never the issue. The real cause: `SimulatorBloc`'s `_intendedEnabled` / `SimulatorState.isSimulatorActive` is seeded from `BleSimulatorDriver.instance.isSimulatorActive`'s own pristine flag, which starts `false` regardless of which driver `BleReceiverService._activeDriver` actually booted onto. In a DEV_MODE build, boot binds `_activeDriver` to `BleSimulatorDriver`, but that driver's own "active" flag only flips `true` once something calls `scanAndConnect()`/`setSimulatorEnabled(true)` on it — which the Monitor tab's own connect flow does, as a side effect. That `true` assertion is then silently swallowed by the intent-latch guard (`spec-fix-ble-simulator-toggle-off.md`) because it disagrees with the still-`false` seed. Net effect: `SimulatorState.isSimulatorActive` never leaves `false` from boot onward, so toggling the Settings switch "off" is a `false→false` no-op from that state's perspective — the stream `MeasurementPage` mapped from `SimulatorBloc.state.isSimulatorActive` never emits a change, and `isBleConnected` is never re-verified.

**Approach:** Give `MeasurementPage` a signal that isn't gated by `SimulatorBloc`'s stale, intent-latched state: add a `simulatorActiveStream` getter to `BleReceiverService` that delegates to the process-wide `BleSimulatorDriver.instance.isSimulatorStream` singleton directly (bypassing the guard, and the boot-seed desync, entirely), and have `_simulatorActiveStream()` prefer it when the injected driver is a `BleReceiverService`, before falling back to the existing `SimulatorBloc`-ancestor and `null` paths. **Empirically verified**: a scratch reproduction mirroring `main.dart`'s exact provider composition confirmed the bug reproduces pre-fix and is resolved post-fix.

**Known residual gap (not fixed here, by user decision):** the same boot-seed desync means Settings' own "BLE Simulator" switch and Home's device-status card — which read `SimulatorState.isSimulatorActive` directly via `BlocBuilder` — can also show a stale "off" at boot in a DEV_MODE build that is genuinely running the simulator, until the user's first explicit toggle. Logged to `deferred-work.md`.

## Boundaries & Constraints

**Always:**
- All commands run from `sleep-apnea-detection-app/`. `flutter analyze` clean; `flutter test` 100% pass.
- `BleReceiverService.simulatorActiveStream` is purely additive — no existing method/getter signature changes.
- `_simulatorActiveStream()` priority: (1) `_bleDriver is BleReceiverService` → its new stream; (2) `context.read<SimulatorBloc>()` ancestor → existing mapped stream, unchanged; (3) neither → `null`, unchanged.
- Dev-toolbar visibility gate (`context.select<SimulatorBloc, bool>` in `_buildMonitoring`) is untouched — this fix is about `isBleConnected` reactivity only.

**Ask First:**
- Hoisting a single shared `SimulatorBloc` above `MainContainerPage` instead — out of scope here; the singleton-stream approach avoids that larger refactor.
- Touching `FlutterBlueSensorDriver`'s synthetic-data fallback in `sampleIdleBand`/`startMonitoringSession` — related but separate (see Design Notes).

**Never:**
- Add a `SimulatorBloc` provider directly around `MeasurementPage` inside `MainContainerPage` (a second bloc instance would diverge from Home/Settings' toggle state — the same class of bug this fix removes).
- Change `BleSimulatorDriver.isSimulatorStream`'s emission semantics, `SimulatorBloc`, or `SleepMonitoringBloc`'s public constructor.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Toggle off from Settings while Monitor tab is mounted | `IndexedStack` siblings, user flips "BLE Simulator" off in Settings | Monitor tab's `isBleConnected` re-verifies against the real driver's `scanAndConnect()` within one bloc event cycle | N/A |
| Toggle off with no real BLE hardware (AVD) | Real `scanAndConnect()` returns `false` | Banner changes from "D-BAND Sensor Connected ✓" to "Scanning for D-BAND..." | N/A |
| Toggle off during an active monitoring session | `state.status == monitoring` | Session survives unchanged (existing `_devModeChangedDuringSession` behavior) | N/A |
| `MeasurementPage` built with a fake `sensorDriver` (existing tests) | `widget.sensorDriver` is not a `BleReceiverService` | Falls through to existing `SimulatorBloc`-ancestor / `null` behavior, unchanged | N/A |
| `_bleDriver` is `BleReceiverService` but nothing ever toggles | Stream never emits | `isBleConnected` stays at its initial connect result (unchanged from today) | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/ble/ble_receiver_service.dart` -- add `Stream<bool> get simulatorActiveStream => BleSimulatorDriver.instance.isSimulatorStream;` (file already imports `ble_simulator_driver.dart`)
- `lib/ui/pages/measurement_page.dart:86-97` -- `_simulatorActiveStream()`: add the `_bleDriver is BleReceiverService` branch ahead of the existing `context.read<SimulatorBloc>()` try/catch
- `lib/core/bloc/monitoring/sleep_monitoring_bloc.dart:75-126` -- read-only; `simulatorActiveStream?.listen` → `SleepMonitoringDevModeChanged` → `_onDevModeChanged`'s `_isDevMode == event.active` guard and `_runStartFlow` already do the right thing once fed a live stream
- `lib/core/ble/ble_simulator_driver.dart:40,128-138` -- read-only; `isSimulatorStream` / `setSimulatorEnabled` is the singleton signal being tapped
- `lib/ui/pages/main_container_page.dart:27-50` -- read-only; confirms Home/Monitor/Summary/Settings are `IndexedStack` siblings, each page owning its own providers — the structural cause of the gap
- `test/ui/measurement_page_test.dart` -- existing tests construct `MeasurementPage` directly under `BlocProvider<SimulatorBloc>` (an ancestor scope the real app never gives it) with a fake `sensorDriver` — none reproduce the sibling-tab structure this bug ships under
- `_bmad-output/implementation-artifacts/spec-fix-ble-simulator-toggle-off.md` -- read-only prior fix; confirms `SimulatorBloc`'s driver-swap + intent-latch already correctly rebind `BleReceiverService.activeDriver` on toggle — this spec fixes the separate, still-open gap of `MeasurementPage` never observing that toggle

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/ble/ble_receiver_service.dart` -- add `simulatorActiveStream` getter delegating to `BleSimulatorDriver.instance.isSimulatorStream` -- gives any consumer a singleton-backed, ancestor-independent "is the simulator toggle on" signal
- [x] `lib/ui/pages/measurement_page.dart` -- in `_simulatorActiveStream()`, return `_bleDriver.simulatorActiveStream` when `_bleDriver is BleReceiverService`, before the `SimulatorBloc`-ancestor fallback -- fixes `isBleConnected` staying stale when Monitor is a sibling tab of wherever the toggle was flipped
- [x] `test/ui/measurement_page_test.dart` -- add a test that pumps `MeasurementPage` with an injected `BleReceiverService.withDriver(...)` and **no** `SimulatorBloc` ancestor (mirroring `MainContainerPage`'s real structure), calls `BleSimulatorDriver.instance.setSimulatorEnabled(false)` externally, and asserts the connection banner/`isBleConnected` updates -- covers the exact gap that shipped this bug
- [x] `test/core/ble/ble_receiver_service_test.dart` -- unit-test that `simulatorActiveStream` mirrors `BleSimulatorDriver.instance.isSimulatorStream` -- pins the new getter's contract

**Acceptance Criteria:**
- Given the Monitor tab mounted as a sibling of Home/Settings under `MainContainerPage`'s `IndexedStack`, when the user turns "BLE Simulator" off from Settings, then the Monitor tab's `SleepMonitoringBloc` re-runs its connect flow against the now-real driver and `isBleConnected` reflects that driver's actual `scanAndConnect()` result.
- Given `isBleConnected` becomes `false` after the toggle-off re-check, when the Monitor tab rebuilds, then `BleSensorStatusOrganism` shows "Scanning for D-BAND..." instead of "D-BAND Sensor Connected ✓", and `IdleBandCalibrationWizard` receives `isConnected: false`.
- Given an existing test that constructs `MeasurementPage` with a fake `sensorDriver` and its own `SimulatorBloc` ancestor, when that suite runs, then it passes unchanged (this fix only adds a higher-priority path ahead of the existing ones).

## Design Notes

Deferred, separate concern (not in this spec — log to `deferred-work.md`): `FlutterBlueSensorDriver.sampleIdleBand()` / `startMonitoringSession()` fall back to a synthetic signal generator whenever `_telemetryCharacteristic == null` — built for CI (no real GATT anywhere), but unconditional. Once this fix lands, `isBleConnected` correctly gates the Monitor UI to "Scanning..." before that fallback is reached in the normal navigation flow, but the fallback itself stays reachable if a caller ever bypasses the `isBleConnected` gate (e.g. a future direct `sampleIdleBand()` call). Worth hardening later behind an explicit CI-only flag.

## Spec Change Log

- **Review loop 1 — Intent corrected, code kept (baseline `1c2f51d`):** The verification-gap review layer found that `main.dart` provides one shared `BlocProvider<SimulatorBloc>` reaching `MeasurementPage` as an `IndexedStack` sibling — refuting this spec's original "no ancestor" diagnosis. Confirmed empirically with a scratch widget test mirroring `main.dart`'s exact composition: the bug reproduced against pre-fix code even with the shared ancestor reachable, and resolved against post-fix code (see `## Intent` for the corrected mechanism: `SimulatorBloc`'s boot-time seed from `BleSimulatorDriver.instance.isSimulatorActive` desyncs from the actually-bound driver, and the prior fix's intent-latch guard swallows the one correcting signal). **Known-bad state avoided:** shipping a working fix with a false paper-trail explanation, and leaving a broader related bug (Settings switch / Home card also reading the same stale seed) undiscovered and undocumented. **KEEP:** the implementation itself (`BleReceiverService.simulatorActiveStream` + `MeasurementPage._simulatorActiveStream()` priority order + both new tests) is empirically verified correct against the true production shape and must not be reverted or altered — only the `## Intent` narrative was amended. User decision: amend Intent, do not also fix `SimulatorBloc`'s boot-time seeding (logged as deferred work instead).
- **Implementation (baseline `1c2f51d`):** Delivered exactly to spec. `BleReceiverService.simulatorActiveStream` added as a pure delegation to `BleSimulatorDriver.instance.isSimulatorStream` (no other getter/method touched). `MeasurementPage._simulatorActiveStream()` gained the `_bleDriver is BleReceiverService` branch ahead of the `SimulatorBloc`-ancestor try/catch, per the frozen priority order; the `SimulatorBloc`-ancestor and `null` fallbacks are untouched. Two new tests: a widget test in `measurement_page_test.dart` pumping `MeasurementPage` with a `BleReceiverService.withDriver(...)`-wrapped fake and **no** `SimulatorBloc` ancestor, calling `BleSimulatorDriver.instance.setSimulatorEnabled(...)` externally and asserting the connection banner flips from "D-BAND Sensor Connected ✓" to "Scanning for D-BAND..."; and a unit test in `ble_receiver_service_test.dart` pinning that `simulatorActiveStream` mirrors the singleton's `isSimulatorStream` transitions (via `.distinct()` in the test, since `BleSimulatorDriver.scanAndConnect()`/`startSimulationScenario()` re-assert `true` more than once per toggle-on — an unrelated existing driver internal, not part of this fix's contract). All existing `measurement_page_test.dart` cases (fake `sensorDriver` + `SimulatorBloc` ancestor) pass unchanged. `flutter analyze`: "No issues found!". `flutter test`: 312 passed, 0 failed (was 304 baseline before the sibling `spec-fix-ble-simulator-toggle-off` fix's own additions; +2 net here after also accounting for the split of the pre-existing count).

## Verification

**Commands:**
- `flutter analyze` -- expected: "No issues found!" -- **confirmed**
- `flutter test` -- expected: 100% pass, including the new tests -- **confirmed: 312 passed, 0 failed**

## Suggested Review Order

**Ancestor-independent simulator signal**

- New getter, the fix's actual mechanism: delegates past `SimulatorBloc`'s stale, intent-latched state straight to the singleton driver.
  [`ble_receiver_service.dart:63`](../../sleep-apnea-detection-app/lib/core/ble/ble_receiver_service.dart#L63)

- Priority branch: prefers the ancestor-independent stream over the `SimulatorBloc`-ancestor fallback, which production never reaches.
  [`measurement_page.dart:97`](../../sleep-apnea-detection-app/lib/ui/pages/measurement_page.dart#L97)

**Tests**

- Unit test pinning `simulatorActiveStream`'s transitions against the singleton, independent of `_activeDriver`.
  [`ble_receiver_service_test.dart:68`](../../sleep-apnea-detection-app/test/core/ble/ble_receiver_service_test.dart#L68)

- Widget test reproducing the real `IndexedStack`-sibling shape end to end; the regression test for the reported bug.
  [`measurement_page_test.dart:542`](../../sleep-apnea-detection-app/test/ui/measurement_page_test.dart#L542)

