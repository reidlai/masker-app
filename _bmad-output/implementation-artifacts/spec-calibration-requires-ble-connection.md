---
title: 'Calibration Wizard Requires a Connected Sensor'
type: 'bugfix'
created: '2026-09-08'
status: 'done'
review_loop_iteration: 0
baseline_commit: 33c7c94bec7c3520ad187d4ee1df219f3dae7784
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On an AVD (or any device with no D-BAND) with the simulator off, `scanAndConnect()` fails so `SleepMonitoringState.isBleConnected` is `false` and the setup screen shows *"Scanning for D-BAND (BLE 5.0+)…"* — yet **"Start Noise Floor Sampling" is fully enabled**. `IdleBandCalibrationWizard` has no connection input; its `AppButton.onPressed` is never null. Tapping it burns the ~10 s `kIdleSampleWindow` on a spinner, then `sampleIdleBand` throws and shows *"No signal from your D-BAND"*. The sibling "Step 3: Start Nocturnal Sleep Monitoring" button on the same screen is already correctly gated (`state.canStartMonitoring`).

**Approach:** Thread the connection fact the screen already has (`state.isBleConnected`) into `IdleBandCalibrationWizard` as a required `isConnected` flag. When disconnected: the idle-sample **Start** and **Retry** buttons and the wear-check **"I'm Ready"** button are disabled (`onPressed: null`), and the idle-sample body copy is replaced with a "connect your D-BAND first" line. Dev/simulator mode is unaffected — `isBleConnected` is already `true` there, so the wizard stays fully functional.

## Boundaries & Constraints

**Always:**
- `IdleBandCalibrationWizard` gains a required `bool isConnected`; `MeasurementPage._buildSetup` passes `state.isBleConnected`.
- Gate strictly on the passed `isConnected` — never a driver-type check, never a new "is dev mode" derivation. In dev/simulator mode `state.isBleConnected` is `true`, so nothing changes there.
- Disabled buttons use `AppButton(onPressed: null)` (its existing disabled treatment); the wizard rebuilds when `isConnected` flips because `_buildSetup` rebuilds on every `SleepMonitoringState` change.
- Buttons gated: idle-sample "Start Noise Floor Sampling" (`:167`), idle-sample "Retry" in the `idleError` branch (`:161`), wear-check "I'm Ready — Start Breathing Check" (`:194`).
- When `!isConnected` on the idle-sample step, the body text is "Connect your D-BAND to begin noise-floor sampling." instead of the "Put on your D-BAND…" copy.

**Ask First:**
- Adding a mid-sample / mid-wear-check "connection lost" state path to `CalibrationBloc` (a bigger change — the button gate + the existing `StateError → idleError` path cover the reported bug).
- Changing `CalibrationBloc`, its events/state, `SleepMonitoringBloc`, or how the wizard's `CalibrationBloc` is constructed.
- Dimming / disabling the whole calibration `Container` (beyond the button + copy changes).

**Never:**
- Touch the scenario / detection copy, the wear-check running/failed UI, the `_bandReadout`, or the AD-04/AD-05 sampling logic.
- Make `IdleBandCalibrationWizard` read `SleepMonitoringState` or any bloc other than its own `CalibrationBloc`.
- Change `AppButton`, `BleSensorStatusOrganism`, or the "Step 3" gate.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Setup screen, sensor NOT connected | `state.isBleConnected == false`, `CalibrationStep.idleSample` | "Start Noise Floor Sampling" is **disabled**; body reads "Connect your D-BAND to begin noise-floor sampling." | N/A |
| Setup screen, sensor connected (incl. simulator on) | `state.isBleConnected == true` | "Start Noise Floor Sampling" **enabled**; original copy; tap dispatches `CalibrationIdleSampleStarted` — unchanged | N/A |
| Connection established while viewing the idle-sample step | `isBleConnected` flips `false → true` | `_buildSetup` rebuilds → button enables, copy reverts to the standard instruction | N/A |
| `idleError` branch, sensor NOT connected | `state.idleError == true`, `isConnected == false` | "Retry" is **disabled** | N/A |
| Wear-check step, sensor NOT connected | `CalibrationStep.wearCheck`, `!wearCheckRunning`, `isConnected == false` | "I'm Ready — Start Breathing Check" is **disabled** | N/A |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/organisms/idle_band_calibration_wizard.dart` — `final IBLESensorDriver bleDriver;` at `:23`; constructor at `:26-30` — **add** `final bool isConnected;` + `required this.isConnected`. `_buildIdleSample` (`:126-173`): the "Start Noise Floor Sampling" `AppButton` at `:166-170` and the `idleError`-branch "Retry" `AppButton` at `:160-164` → `onPressed: widget.isConnected ? () => _bloc.add(const CalibrationIdleSampleStarted()) : null`. The body `Text` at `:136-139` → conditional: `widget.isConnected ? <existing copy> : "Connect your D-BAND to begin noise-floor sampling."`. `_buildWearCheck` (`:175-256`): the "I'm Ready — Start Breathing Check" `AppButton` at `:192-197` → `onPressed: widget.isConnected ? () => _bloc.add(const CalibrationWearCheckStarted()) : null`. Leave the wear-check `Retry` (`:204-208`), `wearCheckRunning` UI, `_onStateChanged`, `_bandReadout`, and the `CalibrationBloc` wiring untouched.
- `flutter/lib/ui/pages/measurement_page.dart` — `_buildSetup`: the `IdleBandCalibrationWizard(...)` instantiation at `~:492` — add `isConnected: state.isBleConnected`. Nothing else in `_buildSetup` changes (the "Step 3" gate at `state.canStartMonitoring` already exists).
- Read-only: `flutter/lib/core/bloc/monitoring/sleep_monitoring_state.dart:22` (`isBleConnected`); `flutter/lib/ui/atoms/app_button.dart` (`onPressed: null` ⟹ disabled — `:64`).
- `flutter/test/ui/idle_band_calibration_wizard_test.dart` (117 lines) — every case builds the wizard; a `_FakeDriver.scanAndConnect() => true`. Add `isConnected:` to those constructions and a new not-connected case.
- `flutter/test/ui/measurement_page_test.dart:414` — the `_ToggleableFakeDriver()..connectResult = false` test already renders the disconnected setup screen; add button-state assertions there.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/ui/organisms/idle_band_calibration_wizard.dart` -- add required `bool isConnected`; gate the idle-sample Start + Retry and the wear-check "I'm Ready" `AppButton.onPressed` on it; swap the idle-sample body copy when `!isConnected` -- the fix.
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- pass `isConnected: state.isBleConnected` to `IdleBandCalibrationWizard` in `_buildSetup` -- wire the existing single source of truth.
- [x] `flutter/test/ui/idle_band_calibration_wizard_test.dart` -- thread `isConnected: true` through existing constructions; add a case that builds with `isConnected: false` and asserts the Start button's `onPressed` is null and the "Connect your D-BAND…" copy shows.
- [x] `flutter/test/ui/measurement_page_test.dart` -- in the `connectResult = false` setup-screen test, assert the "Start Noise Floor Sampling" `ElevatedButton.onPressed` is null while disconnected and non-null after the connection is established.

**Acceptance Criteria:**
- Given the setup screen with `state.isBleConnected == false`, when the calibration wizard renders, then "Start Noise Floor Sampling" is disabled and the body reads "Connect your D-BAND to begin noise-floor sampling."
- Given `state.isBleConnected == true` (real sensor or simulator on), when the wizard renders, then "Start Noise Floor Sampling" is enabled and tapping it dispatches `CalibrationIdleSampleStarted` exactly as before.
- Given the wizard is on the idle-sample step while disconnected, when `isBleConnected` becomes `true`, then the button enables without a manual refresh.
- Given `flutter analyze` and `flutter test`, then no new analyzer issues and the full suite (incl. the new cases) passes.

## Spec Change Log

- **Trigger:** step-04 review (3 reviewers) — the Code Map said "leave the wear-check `Retry` untouched", which contradicts the frozen **Always** rule ("every 'start sampling' action is disabled" when `!isConnected`). The `wearCheckFailed`-branch "Retry Breathing Check" button dispatches the *same* `CalibrationWearCheckStarted` event as the gated "I'm Ready" button.
- **Amended:** gated "Retry Breathing Check" on `isConnected` too; extracted a single `_whenConnected(CalibrationEvent)` helper used by all four gated buttons (the copy-paste is what let the miss through); made the wear-check body copy conditional on `isConnected` like the idle-sample step; un-hyphenated "noise floor sampling"; corrected the stale class doc (`BlocConsumer`, not `BlocBuilder`). Added a "Retry Breathing Check disabled on connection loss" test + a `false→true` re-enable assertion.
- **Known-bad state avoided:** one enabled button that starts a sampling run with no sensor while its two siblings are correctly disabled.
- **KEEP:** the gate is strictly `widget.isConnected` (fed from `state.isBleConnected`); never a driver-type or dev-mode check. Simulator mode stays fully functional.
- **Deferred (see deferred-work.md):** live connectivity tracking (`isBleConnected` never returns to `false` on a mid-session drop); `didUpdateWidget` / `CalibrationBloc` teardown for an in-flight disconnect; `wearCheckConnectionLost` inline-text attribution; a11y hints on disabled buttons.

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: no new issues (2 pre-existing unused-import warnings only).
- `cd flutter && flutter test` -- expected: full suite green, including the new not-connected wizard cases.

**Manual check:**
- Run on an AVD with the simulator off and no paired D-BAND: the setup screen shows "Scanning for D-BAND…" and "Start Noise Floor Sampling" is greyed out / non-tappable. Enable the Simulator: the button becomes enabled.

## Suggested Review Order

**The gate**

- The new required flag + its contract (`false` ⟹ every start-sampling action disabled; simulator reports `true`).
  [`idle_band_calibration_wizard.dart:30`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L30)
- One helper for all four gated buttons — `null` when disconnected — so they disable together (the copy-paste is what let the wear-check "Retry" slip in review).
  [`idle_band_calibration_wizard.dart:61`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L61)
- "Retry Breathing Check" now uses it too — it dispatches the same `CalibrationWearCheckStarted` as the gated "I'm Ready".
  [`idle_band_calibration_wizard.dart:221`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L221)

**Copy**

- Both calibration steps swap to a "Connect your D-BAND…" body when disconnected.
  [`idle_band_calibration_wizard.dart:151`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L151) · [`:202`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L202)

**The wiring — one line**

- `_buildSetup` feeds the connection fact the screen already has.
  [`measurement_page.dart:481`](../../flutter/lib/ui/pages/measurement_page.dart#L481)

**Tests**

- Wizard: not-connected Start disabled + copy + `false→true` re-enable; `idleError` Retry and both wear-check buttons disabled on connection loss.
  [`idle_band_calibration_wizard_test.dart:156`](../../flutter/test/ui/idle_band_calibration_wizard_test.dart#L156)
- `MeasurementPage`: "Start Noise Floor Sampling" `onPressed` null while "Scanning for D-BAND…", non-null once connected, null again after disconnect.
  [`measurement_page_test.dart:440`](../../flutter/test/ui/measurement_page_test.dart#L440)
