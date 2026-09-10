---
title: 'Fix: BLE Simulator toggle cannot be turned off in DEV_MODE'
type: 'bugfix'
created: '2026-09-10'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'bdb9c4e84122335ba6c45419df31fa2a260241c1'
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** In a `--dart-define=DEV_MODE=true` build the Settings → Developer "BLE Simulator" switch springs straight back on after you tap it off. Root cause: `BleReceiverService` boots bound to `BleSimulatorDriver` in DEV_MODE, so `SimulatorBloc._fallbackDriver` (snapshotted from `receiver.activeDriver` at construction) **is the simulator itself**. On disable, `_setEnabled(false)` calls `_receiver.setActiveDriver(_fallbackDriver)` — a no-op swap — so the receiver never leaves the simulator. The always-alive `MeasurementPage` → `SleepMonitoringBloc` then reacts to the toggle, runs its connect flow, and calls `receiver.scanAndConnect()`, which routes to the still-bound `BleSimulatorDriver.scanAndConnect()` → `_isSimulatorSubject.add(true)`. `SimulatorBloc` mirrors that stream straight back into `state.isSimulatorActive`, so the switch flips on again.

**Approach:** Two changes to `SimulatorBloc`, both scoped to that one bloc:
1. **Real restore target.** When the captured fallback is `null` or a `BleSimulatorDriver`, disable rebinds the receiver to a lazily-built hardware driver from an injectable factory (default `FlutterBlueSensorDriver.new`) instead. "Simulator off" then genuinely leaves the simulator; a later `scanAndConnect()` reaches the hardware driver, not the simulator.
2. **Intent latch.** Track the last explicit enable/disable (`_intendedEnabled`). `_onDriverStateChanged` only applies an `isSimulatorActive` value from the driver stream when it **agrees** with `_intendedEnabled` — a spurious `true` from any residual `scanAndConnect` / `startSimulationScenario` / `emitSignal` on the singleton can no longer override the user's choice.

No change to `BleSimulatorDriver`, `SleepMonitoringBloc`, `BleReceiverService`, or `main.dart`. In a plain (non-DEV_MODE) build the captured fallback is already `FlutterBlueSensorDriver`, so change 1 is a no-op there and today's behavior is preserved.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- The restore target is resolved once and reused (`_hardwareFallback ??= _hardwareDriverFactory()`) — never a fresh driver per disable.
- `_hardwareDriverFactory` is a constructor param `IBLESensorDriver Function()?`, default `FlutterBlueSensorDriver.new`; tests inject a fake so no `flutter_blue_plus` platform contact.
- `_intendedEnabled` is seeded from the same initial driver state the constructor already reads for `super(SimulatorState(isSimulatorActive: ...))`, and is written by `_setEnabled` (covers both `SimulatorEnabledSet` and `SimulatorToggled`).
- `_onDriverStateChanged` still applies `currentScenario` updates unconditionally — only the `isSimulatorActive` branch is gated on `== _intendedEnabled`.
- Enable path unchanged: `_setEnabled(true)` still `setActiveDriver(_driver)` (the simulator) then `setSimulatorEnabled(true)`.
- `_receiver == null` (the bare fallback `SimulatorBloc()` in `settings_page.dart`): no `setActiveDriver` call and no hardware driver is built.

**Ask First:**
- Touching `BleSimulatorDriver`'s `_isSimulatorSubject` semantics (the `scanAndConnect`/`startSimulationScenario` force-`true` writes).
- Making `MeasurementPage` lazy, or narrowing the Developer-row visibility gate.
- Any `SleepMonitoringBloc` change.

**Never:**
- Add a broad state machine to `SimulatorBloc` — the two targeted changes above are the whole fix.
- Change the enable path or the scenario-stream handling.
- Wire `hardwareDriverFactory` from `main.dart` — the default covers production.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Disable, DEV_MODE (fallback IS simulator) | `SimulatorEnabledSet(false)`, `receiver.activeDriver` is a `BleSimulatorDriver` | `receiver.activeDriver` becomes the hardware-factory driver; `state.isSimulatorActive == false` |
| Disable, production (fallback is hardware) | `SimulatorEnabledSet(false)`, captured fallback is `FlutterBlueSensorDriver` | `receiver.activeDriver` restored to that captured driver (unchanged behavior) |
| Spurious re-assert after disable | after disable, driver `isSimulatorStream` emits `true` | `state.isSimulatorActive` stays `false`; no emit |
| Re-enable after disable | `SimulatorEnabledSet(true)` following a disable | `receiver.activeDriver` is the simulator again; `state.isSimulatorActive == true` |
| Toggle (not Set) | `SimulatorToggled` from an active state | same as `SimulatorEnabledSet(false)` — `_intendedEnabled` updated, restore target applied |
| Disable with no receiver | bare `SimulatorBloc()` (`_receiver == null`), `SimulatorEnabledSet(false)` | no `setActiveDriver`, no hardware driver built; `state.isSimulatorActive == false` |
| Scenario update after disable | driver `scenarioStream` emits while `_intendedEnabled == false` | `state.currentScenario` still updates (only the active flag is gated) |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/bloc/simulator/simulator_bloc.dart` — the whole fix.
  - Constructor (l.33–64): add `IBLESensorDriver Function()? hardwareDriverFactory`; store `_hardwareDriverFactory = hardwareDriverFactory ?? FlutterBlueSensorDriver.new`. Add `bool _intendedEnabled = (driver ?? BleSimulatorDriver.instance).isSimulatorActive;` (mirrors the value already passed to `super(...)`).
  - New: `IBLESensorDriver? _hardwareFallback;` and `IBLESensorDriver _restoreTarget()` — `final c = _fallbackDriver; if (c != null && c is! BleSimulatorDriver) return c; return _hardwareFallback ??= _hardwareDriverFactory();`.
  - `_setEnabled` (l.74–89): set `_intendedEnabled = enabled;` first. Disable branch becomes `if (_receiver != null) _receiver!.setActiveDriver(_restoreTarget());` (drops the `_fallbackDriver != null` check — `_restoreTarget()` always yields one).
  - `_onDriverStateChanged` (l.108–122): guard the active-flag branch with `&& event.isSimulatorActive == _intendedEnabled`. Scenario branch untouched.
  - Import `../../ble/flutter_blue_sensor_driver.dart` for the default factory tear-off.
- `flutter/test/core/bloc/simulator_bloc_test.dart` — add cases:
  - fallback IS simulator (`BleReceiverService.withDriver(BleSimulatorDriver())`, inject `hardwareDriverFactory: () => _FakeHardwareDriver()`) → `SimulatorEnabledSet(false)` → `receiver.activeDriver` is `_FakeHardwareDriver`, state inactive.
  - after disable, `isSim.add(true)` (the mock's stream subject) → state stays inactive, no emit.
  - re-enable after that → `receiver.activeDriver` is the simulator, state active.
  - scenario update while disabled still lands in state.
  - Existing test at l.191 (fallback is `_FakeHardwareDriver`) must still pass unchanged.
- `flutter/test/ui/settings_page_test.dart` — a widget test: provide a `SimulatorBloc` whose receiver is simulator-bound (+ injected fake hardware factory), tap `Key('ble-simulator-switch')` off, `pump`, assert the `Switch.value` is `false` and stays `false` after another `pump`.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/bloc/simulator/simulator_bloc.dart` — `hardwareDriverFactory` param + `_restoreTarget()` + `_intendedEnabled` latch; disable branch uses `_restoreTarget()`; `_onDriverStateChanged` gates the active flag on `== _intendedEnabled`.
- [x] `flutter/test/core/bloc/simulator_bloc_test.dart` — the fallback-is-simulator, spurious-reassert, re-enable, and scenario-while-disabled cases.
- [x] `flutter/test/ui/settings_page_test.dart` — toggle-off-stays-off widget test.

**Acceptance Criteria:**
- Given a DEV_MODE-style setup where `receiver.activeDriver` is a `BleSimulatorDriver`, when `SimulatorEnabledSet(false)` (or `SimulatorToggled` from active) is dispatched, then `receiver.activeDriver` is no longer a `BleSimulatorDriver` and `state.isSimulatorActive` is `false`.
- Given the simulator has been disabled, when the driver's `isSimulatorStream` subsequently emits `true`, then `state.isSimulatorActive` remains `false`.
- Given a non-DEV_MODE setup (captured fallback is a real hardware driver), when the simulator is disabled, then that exact captured driver is restored — no new instance — matching pre-fix behavior.
- Given `cd flutter && flutter analyze && flutter test`, then both pass clean.

## Spec Change Log

- **Implementation (baseline `bdb9c4e`):** Delivered to spec — `SimulatorBloc` only. `_restoreTarget()` returns the captured fallback unless it is absent or a `BleSimulatorDriver`, in which case it lazily builds (and reuses) a driver from `_hardwareDriverFactory` (default `FlutterBlueSensorDriver.new`). `_setEnabled` sets `_intendedEnabled` first and, on disable with a receiver, binds `_restoreTarget()`. `_onDriverStateChanged` applies a driver-stream `isSimulatorActive` only when it equals `_intendedEnabled`. One existing bloc test (`driver stream pushes…`) was split — its `isSim.add(true)`-flips-state assertion was the exact bug, so it became `scenario-stream pushes…` (unconditional) plus a new "contradicting active-flag push is ignored" test. `main.dart` unchanged: production's captured fallback is already `FlutterBlueSensorDriver`, so `_restoreTarget` returns it and the lazy factory is never invoked there. Suite 304 → 310, `flutter analyze` clean.
- **Review pass (3 lenses inline vs `bdb9c4e`) — no loopback.** Patch: tightened the `_fallbackDriver` doc comment (it over-claimed for the bare/test construction paths). With the latch, `_onDriverStateChanged`'s active-flag branch is now only a guarded confirmation — `_setEnabled` is the sole writer of `isSimulatorActive`; kept as a guard per the frozen approach rather than removed. Deferred (logged): the eager `MeasurementPage`/`SleepMonitoringBloc` auto-drive, the over-broad Developer-row gate, the `_isSimulatorSubject` selected-vs-emitting conflation (which `_intendedEnabled` seeds from at construction), and a real `SimulatorBloc`↔`SleepMonitoringBloc` loop integration test.

## Suggested Review Order

**The fix**

- `_restoreTarget()` — the core: never hand the receiver back a `BleSimulatorDriver` on disable.
  [`simulator_bloc.dart:101`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L101)
- `_setEnabled` — sets `_intendedEnabled`, then binds `_restoreTarget()` on disable (was: the captured fallback, which was the simulator).
  [`simulator_bloc.dart:107`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L107)
- `_onDriverStateChanged` — the intent latch: a driver-stream active flag is honoured only when it agrees with the last explicit toggle.
  [`simulator_bloc.dart:148`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L148)
- Constructor — `hardwareDriverFactory` param (default `FlutterBlueSensorDriver.new`) + `_intendedEnabled` seed.
  [`simulator_bloc.dart:50`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L50)

**Tests**

- Bloc: fallback-is-simulator → hardware-factory driver; spurious re-assert ignored; re-enable rebinds; `SimulatorToggled` path; factory built once.
  [`simulator_bloc_test.dart:233`](../../flutter/test/core/bloc/simulator_bloc_test.dart#L233)
- Bloc: the split of the old "driver stream pushes" test.
  [`simulator_bloc_test.dart:171`](../../flutter/test/core/bloc/simulator_bloc_test.dart#L171)
- Widget: switch stays off after a stray driver re-assert.
  [`settings_page_test.dart:147`](../../flutter/test/ui/settings_page_test.dart#L147)

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. the new `simulator_bloc_test.dart` and `settings_page_test.dart` cases.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: Settings → Developer → tap "BLE Simulator" off. The switch stays off; the dev simulator toolbar disappears; the Measurement tab shows no simulated signal (real-BLE path, which won't connect on an emulator — expected). Tap it back on → simulated telemetry resumes.
