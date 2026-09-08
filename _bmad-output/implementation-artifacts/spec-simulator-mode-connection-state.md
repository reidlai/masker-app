---
title: 'Simulator Mode Drives BLE Connection State'
type: 'bugfix'
created: '2026-09-08'
status: 'done'
review_loop_iteration: 0
baseline_commit: fd560d38f251b0b58f282ae2f1efc656a226ae81
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** After the `fd560d3` BLoC refactor, `SleepMonitoringBloc` never reacts to `SimulatorBloc`. `_isDevMode` is read once in `MeasurementPage.initState` and passed by value into the bloc; `MeasurementPage` is a `const` `IndexedStack` child built once at tab-shell entry with the simulator off. So toggling the Simulator on in Settings never re-runs the connect flow — the setup screen shows *"Scanning for D-BAND (BLE 5.0+)…"* (`isBleConnected == false`) forever even though simulator mode is enabled.

**Approach:** Feed `SimulatorBloc.isSimulatorActive` changes into `SleepMonitoringBloc` as a stream (mirroring the existing `scenarioResetStream` wiring). On a change: if not in an active session, re-run the start/connect flow (dev mode bypasses the permission gate and `scanAndConnect()` returns `true` synchronously → `isBleConnected: true`; simulator-off re-runs the real gate → `false`). If a session is running, keep it running on the swapped driver and just flip dev-mode so the developer UI hides — never tear the session down.

## Boundaries & Constraints

**Always:**
- The contract: simulator ON ⟹ `SleepMonitoringState.isBleConnected == true` and `status == setup` (permission gate bypassed); simulator OFF ⟹ re-run the real permission gate, `isBleConnected` reflects the real driver (`false` with no hardware).
- The `DeveloperSimulatorBarOrganism` toolbar renders only when `status == monitoring` AND `SimulatorBloc.isSimulatorActive` — gated directly on `SimulatorBloc`, not on `SleepMonitoringState` rebuild cadence.
- Reuse the `scenarioResetStream` pattern: an optional `Stream<bool>` ctor param on `SleepMonitoringBloc`, subscribed internally, cancelled in `close()`, pumped through one new internal event. No `BlocProvider`/topology changes.
- `SimulatorBloc._setEnabled` already swaps `BleReceiverService.setActiveDriver(...)`; the unified queue keeps its identity across the swap (AD-12), so the bloc's existing `_signalSub` stays valid — do not re-subscribe it.

**Ask First:**
- Any change to `SimulatorBloc`, `BleReceiverService`, `BleSensorStatusOrganism`, `home_page.dart`, or the `IndexedStack` in `main_container_page.dart`.
- Making a simulator toggle stop or restart an active monitoring session (decided: it must NOT — session survives, only the dev UI hides).

**Never:**
- Add a "simulator ⟹ connected" shortcut that skips `_connect` / `scanAndConnect` — re-running the existing dev-mode start flow already satisfies the contract.
- Persist simulator state, or read it from anywhere other than the injected `SimulatorBloc` stream.
- Touch the AD-04 evaluator math, calibration algorithm, or existing permission-gate copy/branches.
- Add the toolbar to the setup screen (it is developer-only and stays monitoring-only).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Enable simulator, not in a session | `status ∈ {checkingPermission, permissionBlocked, permissionCheckFailed, setup}` | `_runStartFlow` re-runs in dev mode → `status: setup`, `permissionStatus: _devGrantedStub`, `isBleConnected: true`; `BleSensorStatusOrganism` shows "D-BAND Sensor Connected ✓" (green) | N/A |
| Disable simulator, not in a session | not `monitoring` | `_runStartFlow` re-runs non-dev → real `checkPermission()`; on grant `isBleConnected` = real `scanAndConnect()` (`false`, no hardware) → card shows "Scanning for D-BAND (BLE 5.0+)…" (amber) | `checkPermission()` throws → `status: permissionCheckFailed` (unchanged) |
| Toggle simulator during a session | `status == monitoring` | session continues (`status` stays `monitoring`); dev-mode flag flips; `DeveloperSimulatorBarOrganism` + dev stage panel hide (off) / show (on) on the next frame; no calibration reset, no teardown | N/A |
| Rapid on/off/on, not in a session | `status: setup` | each toggle re-runs `_runStartFlow`; calibration (`idleBand`, `connectGeneration`) resets each time — each toggle is a genuine driver swap | N/A |
| Toolbar visibility | any | visible iff `status == monitoring` AND `SimulatorBloc.isSimulatorActive`; hidden on the setup screen always | N/A |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart` — ctor `:36-57` (add optional `Stream<bool>? simulatorActiveStream`, subscribe → `add(SleepMonitoringDevModeChanged(active))`); `_isDevMode` field `:43` (final → mutable); `on<...>` registrations `:46-56` (register the new event); new handler `_onDevModeChanged`: set `_isDevMode`; if `state.status == SleepMonitoringStatus.monitoring` → `emit(state.copyWith())`-equivalent no-op that still forces a rebuild (or emit a trivially-changed field) so the view re-evaluates the toolbar, else `await _runStartFlow(emit)`; `close()` `:283-291` (cancel the new sub). `_runStartFlow` `:77-109` and `_connect` `:143-154` are reused unchanged.
- `flutter/lib/core/bloc/monitoring/sleep_monitoring_event.dart` — after `:56` "internal (stream-fed)" section, add `class SleepMonitoringDevModeChanged extends SleepMonitoringEvent { final bool active; const SleepMonitoringDevModeChanged(this.active); @override List<Object?> get props => [active]; }`.
- `flutter/lib/ui/pages/measurement_page.dart` — `initState` `:87-92` (pass `simulatorActiveStream:` built like `_scenarioResetStream()` `:65-76` — `context.read<SimulatorBloc>().stream.map((s) => s.isSimulatorActive).distinct()`, wrapped in the same try/catch → `null`); `_isDevMode` fallback `:57-60` (bug — checks `widget.sensorDriver`; change to check the resolved injected driver: `final d = widget.sensorDriver ?? _injectedDriver(); return d is BleReceiverService && d.isSimulatorActive;`); `_buildMonitoring` `:231-232` (wrap `DeveloperSimulatorBarOrganism()` and the dev stage panel in their own `BlocBuilder<SimulatorBloc, SimulatorState>` gated on `state.isSimulatorActive`, so hide/show is bound directly to `SimulatorBloc`).
- Read-only references (do not edit): `simulator_bloc.dart` `_setEnabled:74-89` (swap + emit already correct); `ble_receiver_service.dart` `setActiveDriver:57-61` (keeps the same `_thermalSubject` → the bloc's `_signalSub` survives a swap); `ble_sensor_status_organism.dart` (pure `isConnected` prop, correct); `home_page.dart:82` (`DeviceStatusCard` already `= SimulatorBloc.isSimulatorActive` — out of scope, will agree).
- `flutter/test/core/bloc/sleep_monitoring_bloc_test.dart` / `flutter/test/ui/measurement_page_test.dart` — extend (see Tasks).

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/bloc/monitoring/sleep_monitoring_event.dart` -- add `SleepMonitoringDevModeChanged(bool active)` in the internal-events section -- carries the simulator-active transition.
- [x] `flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart` -- add `simulatorActiveStream` ctor param + `_simulatorActiveSub`; make `_isDevMode` mutable; register + implement `_onDevModeChanged` (monitoring → flip flag + force a rebuild, no teardown/reset; otherwise → `_runStartFlow`); cancel the sub in `close()` -- the whole fix.
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- wire `simulatorActiveStream` in `initState` (guarded like `_scenarioResetStream()`); fix the `_isDevMode` fallback to check the resolved driver; wrap the monitoring-screen dev toolbar + stage panel in a `BlocBuilder<SimulatorBloc, SimulatorState>` -- reactive gate + fallback correctness.
- [x] `flutter/test/core/bloc/sleep_monitoring_bloc_test.dart` -- add cases for every I/O Matrix row: enable-not-in-session → `isBleConnected true` + `status setup`; disable-not-in-session → real gate + `isBleConnected false`; toggle during `monitoring` → `status` stays `monitoring`, no calibration reset; rapid on/off/on → calibration resets each time.
- [x] `flutter/test/ui/measurement_page_test.dart` -- widget test under a real `SimulatorBloc`: toggle on → `BleSensorStatusOrganism` shows "D-BAND Sensor Connected ✓"; toggle off → "Scanning for D-BAND"; toolbar `findsNothing` while not `monitoring` and while simulator off.

**Acceptance Criteria:**
- Given the running app with the Simulator toggle off, when the user enables it in Settings and opens the Monitor tab, then the BLE status card reads "D-BAND Sensor Connected ✓" in green (`isBleConnected == true`), with no permission prompt.
- Given the Simulator is on and the Monitor tab shows "Connected ✓", when the user disables the Simulator, then the card returns to "Scanning for D-BAND (BLE 5.0+)…" in amber.
- Given an active monitoring session (`status == monitoring`), when the user toggles the Simulator either way, then the session stays on the night-mode screen (no return to setup, no calibration loss) and only the developer toolbar/stage panel appear or disappear.
- Given `flutter analyze` and `flutter test`, when run after the change, then no new analyzer issues and the full suite (incl. the new cases) passes.

## Design Notes

**Reuse, don't reinvent.** In dev mode `_runStartFlow` already yields the target state (`status: setup`, `_devGrantedStub`, then `_connect` → `BleSimulatorDriver.scanAndConnect()` returns `true` synchronously → `isBleConnected: true`). The bug is only that nothing invokes it after `initState`. So `_onDevModeChanged` just calls `_runStartFlow` when not in a session.

**Calibration reset on toggle is intentional** — every toggle is a real `setActiveDriver` swap and the noise-floor band is per-driver; do not guard against it.

**Mid-session toggle (decided: keep session).** `status == monitoring` is preserved; the session keeps consuming the same unified `BehaviorSubject` (identity stable across `setActiveDriver`). Simulator-off + no hardware ⟹ the real driver emits nothing and the waveform stalls — acceptable for this dev-only path. `_onDevModeChanged` in `monitoring` only updates `_isDevMode` for a later flow re-run; the toolbar/stage panel hide via their own `SimulatorBloc` `BlocBuilder`, so no bloc emit is required for that.

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: no new issues (2 pre-existing unused-import warnings only).
- `cd flutter && flutter test` -- expected: full suite green, including the new bloc + widget cases.

**Manual checks:**
- Launch the app (`DEV_MODE` unset). Settings → Developer → toggle **Simulator** on. Switch to the **Monitor** tab: the status card must read "D-BAND Sensor Connected ✓" (green, `bluetooth_connected` icon). Toggle Simulator off: card returns to "Scanning for D-BAND (BLE 5.0+)…" (amber).

## Suggested Review Order

**The wiring — SimulatorBloc → SleepMonitoringBloc**

- The one new input: `SimulatorBloc.isSimulatorActive` changes are pumped in as `SleepMonitoringDevModeChanged` (mirrors the `scenarioResetStream` pattern; `onError` swallowed for parity).
  [`sleep_monitoring_bloc.dart:80`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L80)
- The event itself.
  [`sleep_monitoring_event.dart:91`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_event.dart#L91)
- `initState` wires the stream — returns `null` when a test forces `developerEnabled` so the override always wins.
  [`measurement_page.dart:82`](../../flutter/lib/ui/pages/measurement_page.dart#L82)

**The reconnect flow (most of the logic + all the review patches)**

- `_onDevModeChanged`: not in a session → re-run the gate; in a session → keep it, flag for post-session reconcile. No interim `checkingPermission` emit (was a spinner flash on rapid toggles).
  [`sleep_monitoring_bloc.dart:106`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L106)
- `_runStartFlow` is now a serialising wrapper (`_startFlowInProgress` + re-run-once-if-`_isDevMode`-moved) around the unchanged `_runStartFlowOnce` — stops a toggle racing an in-flight `_onStarted`/`_onAppResumed` from double-connecting.
  [`sleep_monitoring_bloc.dart:131`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L131)
- `_onSessionStopped` (now async): if the simulator was toggled during the session, re-run the gate so the setup screen's BLE status / permission reflect reality, not the stale dev stub.
  [`sleep_monitoring_bloc.dart:299`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L299)

**The reactive UI gate**

- The monitoring-screen dev toolbar + stage panel are gated on `context.select<SimulatorBloc, bool>` — hide/show the instant the simulator is toggled, not on the next signal-tick rebuild. Nested `Column` kept center-aligned to preserve the prior layout.
  [`measurement_page.dart:306`](../../flutter/lib/ui/pages/measurement_page.dart#L306)
- `_isDevMode` fallback fix: check the resolved injected driver, not the (usually null) `widget.sensorDriver`.
  [`measurement_page.dart:58`](../../flutter/lib/ui/pages/measurement_page.dart#L58)

**Tests (peripherals)**

- Bloc: enable/disable-not-in-session, toggle-during-session, rapid on/off/on, redundant same-value no-op, post-stop reconciliation.
  [`sleep_monitoring_bloc_test.dart:299`](../../flutter/test/core/bloc/sleep_monitoring_bloc_test.dart#L299)
- Widget: toggle on the setup screen drives the BLE status card; and the monitoring-screen toolbar/panel vanish on a mid-session toggle-off while the session stays live.
  [`measurement_page_test.dart:357`](../../flutter/test/ui/measurement_page_test.dart#L357)
