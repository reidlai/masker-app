---
title: 'BLoC + RxDart + SOLID Standardization'
type: 'refactor'
created: '2026-09-07'
status: 'done'
review_loop_iteration: 0
baseline_commit: b0d498a4c24c65455f1964d6ae8bd0dd651a95f9
context:
  - '{project-root}/_bmad-output/architecture/ARCHITECTURE-SPINE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The BLoC layer stops at `AuthBloc`/`BleBloc`. The rest of `flutter/lib/` (11 `StatefulWidget` pages, 43 `setState` sites) carries domain logic in widget `State`, `BleReceiverService` (the AD-12 unified `BehaviorSubject<double>`) has zero consumers, `BleBloc` and `MeasurementPage` each `new` their own concrete driver (breaking AD-11/AD-12), and `SimulatorCubit` is the lone `Cubit` in an otherwise `Bloc`+event+state codebase with three hand-rolled equality idioms.

**Approach:** A **pure structural refactor** — identical runtime behavior, only where state lives changes. Four sequenced goals: **G1** standardize the BLoC idiom (`equatable`, `SimulatorCubit`→`SimulatorBloc`+events, value equality on all state/event classes); **G2** make every bio-signal consumer read the single `BleReceiverService` stream via `IBLESensorDriver` DI, deleting per-widget driver construction and `as BleSimulatorDriver` downcasts; **G3** extract `SleepMonitoringBloc`, `CalibrationBloc`, `AppFlowBloc`, `ProfileBloc`, `HistoryBloc`, `LanguageRegionBloc` so those pages become `BlocBuilder`-only; **G4** add `bloc_test` coverage per bloc plus one AD-12 invariant test.

## Boundaries & Constraints

**Always:**
- Preserve observable runtime behavior exactly. Every existing test passes unchanged except for mechanical rename edits (`SimulatorCubit`→`SimulatorBloc`) and tests that assert widget-internal state now assert bloc state.
- New blocs live under `flutter/lib/core/bloc/<feature>/` as the `<feature>_bloc.dart` + `<feature>_event.dart` + `<feature>_state.dart` triad. No `Cubit` anywhere after G1.
- All `*State` and `*Event` classes extend `Equatable` with complete `props`.
- Bio-signal consumers (`BleBloc`, `SleepMonitoringBloc`, `CalibrationBloc`) obtain their `IBLESensorDriver` by constructor injection sourced from the single `BleReceiverService` instance (AD-11/AD-12). No widget or bloc calls `BleSimulatorDriver()` / `FlutterBlueSensorDriver()` directly.
- Simulator↔hardware driver swap goes through `BleReceiverService.setActiveDriver(...)`, driven by `SimulatorBloc`.
- Widgets in scope dispatch events and read state only — no domain math, no seed/mock literals, no `StreamSubscription`, no `setState` (ephemeral pure-view state noted under Never is exempt).

**Ask First:**
- Any change that alters a user-visible behavior, timing, copy, or navigation.
- Adding a bloc, event, or state field not enumerated in Tasks.
- Touching `HomePage`, `BillingPage`, `ExportDoctorPage`, `PaymentMethodPage`, or backend/service code.
- Making `BleBloc`'s `.distinct()` change emission counts by more than dropping exact consecutive-duplicate signal values (see Design Notes).

**Never:**
- Wire a real passkey authenticator or remove `AuthBloc`'s `Future.delayed` stub (acknowledged in scope conceptually; **not implemented in this spec** — follow-up).
- Create `HomeDashboardBloc` / `BillingBloc` (their data sources are MVP2 backend services; pages stay mock + `setState` for now).
- Convert ephemeral pure-view state: `MainContainerPage._currentIndex`, `BlePermissionPrimerPage._isRequesting`/`_headlineFocusNode`, `WeeklyCalendarOrganism` month cursor, `ExportDoctorPage._selectedFormatIndex`, `PaymentMethodPage._hasCard`, `TextEditingController` instances (controllers stay in widgets; their *values* flow through blocs).
- Change `IBLESensorDriver`'s method set, the AD-04 evaluator math, the simulator signal shapes, or `pubspec` versions of existing deps.
- Add cross-cutting behavior fixes for review items E1/E3/E4/E8 (separate specs).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Simulator toggle on | tap Switch in Settings / Dev Options | `SimulatorBloc` emits `isSimulatorActive: true`; `BleReceiverService` active driver becomes simulator; same rows/cards update as today | N/A |
| Scenario chip tap | simulator active, tap "Normal Breathing" | `SimulatorBloc` state `currentScenario` updates; waveform + status text change identically to pre-refactor | N/A |
| Calibration idle sample | worn, still ~10s | `CalibrationBloc` transitions `idleSample`→`wearCheck` with the same live-band readout and same `IdleBand` result | on no samples in window: same error state + retry, no hung spinner |
| Wear check pass/timeout | ≥2 excursion cycles / window elapses | `CalibrationBloc` emits `complete` / `wearCheckFailed`; "Start Monitoring" gate unlocks/holds identically | connection lost → same failed state |
| Apnea breach during monitoring | signal in-band ≥100 ticks | `SleepMonitoringBloc` emits alert state; overlay + countdown render as today | evaluator error → unchanged |
| Permission denied at login | `checkPermission()` → not granted | `AppFlowBloc` → `needsPrimer` → primer → `ready`; same screens in same order | `checkPermission()` throws → `permissionCheckFailed` + Retry |
| BMI recompute | edit Weight field on Profile | `ProfileBloc` emits new `computedBmi`; displayed value identical to `_calculateBmi()` output | non-numeric input → unchanged (last valid BMI) |
| History filter | tap "Moderate (5–29)" chip | `HistoryBloc` emits filtered list + badge variants identical to `_filteredSessions` | N/A |
| Duplicate BLE sample | two identical consecutive `double` values on the stream | `BleBloc` now drops the second (intended by existing `.distinct()` comment) — only observable in the dev telemetry readout | N/A |

</frozen-after-approval>

## Code Map

**G1 — idiom**
- `flutter/pubspec.yaml` — add `equatable: ^2.0.6` to `dependencies`; add `bloc_test`, `mocktail` to `dev_dependencies` (G4).
- `flutter/lib/core/bloc/simulator/simulator_cubit.dart` — **rename** to `simulator_bloc.dart`; `SimulatorCubit extends Cubit<SimulatorState>` (:8) → `SimulatorBloc extends Bloc<SimulatorEvent, SimulatorState>`; public methods `toggleSimulator`/`setSimulatorEnabled`/`startSimulationScenario`/`stopSimulation` (:33-56) → `on<...>` handlers; ctor `emit`-from-`listen` (:20-30) → `add(_DriverStateChanged(...))` on an internal event; three `BleSimulatorDriver()` calls in ctor (:14-17) → one injected `IBLESensorDriver` (G2).
- `flutter/lib/core/bloc/simulator/simulator_event.dart` — **new**: `SimulatorEvent` (Equatable) + `SimulatorToggled`, `SimulatorEnabledSet(bool)`, `SimulatorScenarioStarted(SimulatorScenario)`, `SimulatorStopped`, internal `_DriverStateChanged`.
- `flutter/lib/core/bloc/simulator/simulator_state.dart` — hand-rolled `==`/`hashCode` (:22-31) → `extends Equatable`, `props => [isSimulatorActive, currentScenario]`.
- `flutter/lib/core/bloc/auth/auth_state.dart` — all 4 classes → `Equatable`; `AuthFailure` (:17-20) gets `props => [errorMessage]`.
- `flutter/lib/core/bloc/auth/auth_event.dart` — 2 classes → `Equatable`.
- `flutter/lib/core/bloc/ble/ble_state.dart` — `BleTelemetryActiveState` hand-rolled `==` (:20-33) → `Equatable`; other 2 → `Equatable`.
- `flutter/lib/core/bloc/ble/ble_event.dart` — 3 classes → `Equatable`; `BleSignalSampleReceived` (:9-12) `props => [signal]` (this makes `ble_bloc.dart:20` `.distinct()` effective — see Design Notes).
- **Rename call sites** (`SimulatorCubit`→`SimulatorBloc`, `.method()`→`.add(Event())`, `BlocBuilder/BlocProvider<SimulatorCubit>`→`<SimulatorBloc>`): `flutter/lib/main.dart:6,151`; `flutter/lib/ui/organisms/ble_simulator_organism.dart:4,41,78,109,133,150,167,185,189`; `flutter/lib/ui/organisms/developer_simulator_bar_organism.dart:4,17,22,98-99,131,133`; `flutter/lib/ui/pages/developer_options_page.dart:3,37,77,133,137`; `flutter/lib/ui/pages/home_page.dart:3,75,80,98-99`; `flutter/lib/ui/pages/settings_page.dart:5,124,129,137,143,154-155`; `flutter/lib/ui/pages/measurement_page.dart:8,75,91-92`.

**G2 — AD-11 / AD-12**
- `flutter/lib/core/ble/ble_receiver_service.dart` — already a singleton `implements IBLESensorDriver` with `reactiveStream` (:79) and `setActiveDriver` (:46). Becomes the one injected driver. Confirm `_isDevMode` seed vs `SimulatorBloc`-driven swap is consistent.
- `flutter/lib/main.dart` — `BleReceiverService()` (:25, side-effect) → provide it (e.g. `RepositoryProvider<IBLESensorDriver>.value` or pass into blocs); `AuthBloc()`/`SimulatorBloc()` providers (:150-151) get the injected driver.
- `flutter/lib/core/bloc/ble/ble_bloc.dart` — field `BleSimulatorDriver _telemetryService` (:9) → `IBLESensorDriver`; drop `?? BleSimulatorDriver()` (:13) → required; `_telemetryService.signalStream.listen` (:26) reads `BleReceiverService` stream.
- `flutter/lib/ui/pages/measurement_page.dart` — `_bleDriver = ... BleSimulatorDriver()/FlutterBlueSensorDriver()` (:87-88,95,106) → injected `IBLESensorDriver` (widget already has `sensorDriver` param; default it to the provided `BleReceiverService`); remove the `SimulatorCubit`-listen driver-swap block (:90-113); `(_bleDriver as BleSimulatorDriver).scenarioStream` (:234) → react to `SimulatorBloc` state (moves to `SleepMonitoringBloc` in G3).
- `flutter/lib/ui/organisms/idle_band_calibration_wizard.dart` — `widget.bleDriver` (:17,70,80,119) fed from the injected driver via `MeasurementPage`, not a fresh instance.
- `flutter/lib/core/ble/ble_simulator_driver.dart` — no API change; `isSimulatorStream`/`scenarioStream` (:34-35) consumed only inside `SimulatorBloc` after this goal.

**G3 — feature blocs**
- `flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `measurement_page.dart:37-305`: `_apneaEvaluator` lifecycle (`ApneaEvaluator`, `flutter/lib/core/monitoring/apnea_evaluator.dart`), `_showAlertOverlay`/`_alertCountdown`/`_isMonitoringActive`/`_latestSignalValue`/`_recentSignalBuffer`, scenario-reset reaction. Consumes `BleReceiverService.reactiveStream`.
- `flutter/lib/core/bloc/calibration/calibration_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `idle_band_calibration_wizard.dart:33-145`: `BreathExcursionDetector`/`IdleBandAccumulator` (`flutter/lib/core/monitoring/drift_and_noise_floor_envelope.dart`), `Timer`, `_wearCheckRunId` guard, `_step`/`_validCycles`/error flags.
- `flutter/lib/core/bloc/app_flow/app_flow_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `main.dart:35,46-93`: `_AppFlowState` enum + `BlePermissionService` (`flutter/lib/core/permissions/ble_permission_service.dart`) orchestration. Events `LoginSucceeded`/`PermissionRetryRequested`/`PrimerCompleted`.
- `flutter/lib/core/bloc/profile/profile_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `profile_page.dart:16-36`: field values + `_calculateBmi()`. Seed values → initial state.
- `flutter/lib/core/bloc/history/history_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `history_filter_page.dart:14-34,78-83`: `_selectedFilterIndex`, `_allSessions` seed, `_filteredSessions` + AI-severity banding.
- `flutter/lib/core/bloc/language_region/language_region_bloc.dart|_event.dart|_state.dart` — **new**. Absorbs `language_region_page.dart:11-35`.
- Widgets → `BlocBuilder`/`BlocListener`, `BlocProvider` wiring: `flutter/lib/ui/pages/measurement_page.dart`, `flutter/lib/ui/organisms/idle_band_calibration_wizard.dart`, `flutter/lib/main.dart` (`_MaskerAppState`), `flutter/lib/ui/pages/profile_page.dart`, `flutter/lib/ui/pages/history_filter_page.dart`, `flutter/lib/ui/pages/language_region_page.dart`.

**G4 — tests**
- `flutter/test/core/bloc/` — **new** `blocTest` files: `simulator_bloc_test.dart`, `sleep_monitoring_bloc_test.dart`, `calibration_bloc_test.dart`, `app_flow_bloc_test.dart`, `profile_bloc_test.dart`, `history_bloc_test.dart`, `language_region_bloc_test.dart`; extend `test/core/auth_bloc_test.dart`, `test/core/ble_bloc_test.dart` with transformer-timing cases.
- `flutter/test/core/ble/ad12_single_queue_test.dart` — **new**: asserts `BleBloc` + `SleepMonitoringBloc` + `CalibrationBloc` share the one `BleReceiverService` stream; no second `BehaviorSubject<double>`.
- Existing tests needing mechanical edits: any under `flutter/test/ui/` and `flutter/test/core/` referencing `SimulatorCubit` or asserting widget-internal state converted to bloc state (`measurement_page_test.dart`, `idle_band_calibration_wizard_test.dart`, `profile_page_test.dart`, `history_filter_page_test.dart`, `language_region_page_test.dart`, `main_container_page_test.dart`, `settings_page_test.dart`, `developer_options_page_test.dart`, `ble_simulator_organism_test.dart`, `developer_simulator_bar_organism_test.dart`, `home_page_test.dart`, `app_flow_test.dart`, `widget_test.dart`).

## Tasks & Acceptance

**Execution:**

*G1 — idiom*
- [x] `flutter/pubspec.yaml` -- add `equatable: ^2.0.6` (deps), `bloc_test`, `mocktail` (dev) -- prerequisite for value equality + G4.
- [x] `flutter/lib/core/bloc/auth/auth_state.dart`, `auth_event.dart` -- all classes `extends Equatable` with `props` -- fixes `AuthFailure` re-fire; standard idiom.
- [x] `flutter/lib/core/bloc/ble/ble_state.dart`, `ble_event.dart` -- replace hand-rolled `==`/`hashCode` with `Equatable`; `BleSignalSampleReceived.props => [signal]` -- one idiom; makes `.distinct()` effective (Design Notes).
- [x] `flutter/lib/core/bloc/simulator/simulator_state.dart` -- `Equatable` -- replace hand-rolled equality.
- [x] `flutter/lib/core/bloc/simulator/simulator_event.dart` -- new event triad + internal `_DriverStateChanged` -- event-driven idiom.
- [x] `flutter/lib/core/bloc/simulator/simulator_bloc.dart` (renamed from `simulator_cubit.dart`) -- `Bloc<SimulatorEvent,SimulatorState>`; methods→handlers; ctor `emit`→`add`; keep `_driver.isSimulatorStream`/`scenarioStream` piping via internal event -- kills the lone `Cubit`.
- [x] Rename all `SimulatorCubit` call sites (7 UI/entrypoint files listed in Code Map) -- `.add(Event())` + `<SimulatorBloc>` generics -- compile-clean cutover.

*G2 — AD-11 / AD-12*
- [x] `flutter/lib/main.dart` -- provide the single `BleReceiverService` as `IBLESensorDriver`; inject into `BleBloc`, `SimulatorBloc` -- one composition root.
- [x] `flutter/lib/core/bloc/ble/ble_bloc.dart` -- field → `IBLESensorDriver` (required); consume `BleReceiverService` stream; drop concrete default -- AD-11/AD-12.
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- driver from injection not `new`; delete the simulator-listen swap block; drop `as BleSimulatorDriver` -- AD-11/AD-12 (full extraction in G3).
- [x] `flutter/lib/ui/organisms/idle_band_calibration_wizard.dart` -- `bleDriver` from the injected instance -- AD-12.
- [x] `flutter/lib/core/bloc/simulator/simulator_bloc.dart` -- enable/disable calls `BleReceiverService.setActiveDriver(...)` -- centralize the swap.

*G3 — feature blocs (one task per new triad + its widget)*
- [x] `core/bloc/monitoring/sleep_monitoring_bloc*` + `ui/pages/measurement_page.dart` -- extract monitoring orchestration; page → `BlocBuilder`/`BlocListener`, zero `setState`/`StreamSubscription` -- "UI reads bloc".
- [x] `core/bloc/calibration/calibration_bloc*` + `ui/organisms/idle_band_calibration_wizard.dart` -- extract idle-sample + wear-check loop; wizard → `BlocBuilder` -- AD-04/AD-05 as a bloc.
- [x] `core/bloc/app_flow/app_flow_bloc*` + `lib/main.dart` -- extract `_AppFlowState` machine + permission orchestration; `_MaskerAppState` → `BlocBuilder` over `_buildHome()` -- single source of "user is in".
- [x] `core/bloc/profile/profile_bloc*` + `ui/pages/profile_page.dart` -- move field values + `_calculateBmi()`; controllers stay, values dispatch `ProfileFieldChanged` -- domain math out of widget.
- [x] `core/bloc/history/history_bloc*` + `ui/pages/history_filter_page.dart` -- move filter + AI banding + seed list -- domain logic out of widget.
- [x] `core/bloc/language_region/language_region_bloc*` + `ui/pages/language_region_page.dart` -- move selections + option lists -- consistency.

*G4 — tests*
- [x] `flutter/test/core/bloc/*_bloc_test.dart` -- `blocTest` per bloc incl. emission sequences; `auth`/`ble` transformer-timing under `bloc_test` `wait`/`fake_async` -- Rx-operator regression net.
- [x] `flutter/test/core/ble/ad12_single_queue_test.dart` -- assert one shared stream across bio-signal consumers -- AD-12 invariant.
- [x] `flutter/test/**` -- mechanical fixes for renamed symbols + widget-state→bloc-state assertions -- green suite.

**Acceptance Criteria:**
- Given the full app, when built and run through the existing manual flows (simulator toggle, calibration, monitoring alarm, login→permission gate, profile BMI edit, history filter), then behavior, copy, timing, and navigation are indistinguishable from `HEAD` before this spec.
- Given `grep -rn "extends Cubit" flutter/lib`, when run after G1, then zero matches.
- Given `grep -rn "BleSimulatorDriver()\|FlutterBlueSensorDriver()" flutter/lib/ui flutter/lib/core/bloc`, when run after G2, then zero matches (construction only in `BleReceiverService` and the composition root).
- Given `grep -rn "setState(" flutter/lib/ui/pages/measurement_page.dart flutter/lib/ui/pages/profile_page.dart flutter/lib/ui/pages/history_filter_page.dart flutter/lib/ui/pages/language_region_page.dart flutter/lib/ui/organisms/idle_band_calibration_wizard.dart`, when run after G3, then zero matches.
- Given `flutter analyze`, when run after each goal, then no new warnings.
- Given `flutter test`, when run after G4, then all pass, including new `blocTest` and the AD-12 invariant test.

## Design Notes

**`BleBloc.distinct()` (the one intentional runtime delta).** `ble_bloc.dart:20` already calls `.distinct()` on the event stream; it is currently a no-op because `BleSignalSampleReceived` has no value equality. Adding `props => [signal]` (required by the "all events are `Equatable`" rule) makes it work as its own comment intends — consecutive *exactly-equal* `double` samples collapse. At 10 Hz from a live sensor or the `sin()`-based simulator, exact consecutive equality is rare, and the only surface that shows raw per-tick values is the dev telemetry readout. Treated as acceptable within "pure structural"; flagged here so a reviewer isn't surprised. If undesired, drop `.distinct()` from the transformer in the same task.

**Internal bloc events.** Stream-fed state (simulator driver streams, signal samples, evaluator state, countdown ticks, wear-check timeout) is pumped via private `_XxxReceived` events added from `StreamSubscription`s owned by the bloc and cancelled in `close()` — never `emit` from a constructor or a raw listener. Mirrors `BleBloc:24-29`.

**Controllers stay in the View.** `TextEditingController`s on `ProfilePage` are view objects; the bloc owns field *values* and `computedBmi`. The widget wires `controller.addListener`/`onChanged` → `add(ProfileFieldChanged(...))` and reads BMI from state.

**Goal independence.** G1 compiles and ships alone. G2 rebases on G1. G3 depends on G2's clean driver injection. G4 lands last. If CHECKPOINT splits this, G1 is the standalone main goal.

## Verification

**Commands:**
- `cd flutter && flutter pub get` -- expected: resolves with `equatable`, `bloc_test`, `mocktail`.
- `cd flutter && flutter analyze` -- expected: no new issues after each goal.
- `cd flutter && flutter test` -- expected: full suite green after G4; existing suite green (minus mechanical edits) after G1.
- `grep -rn "extends Cubit" flutter/lib` -- expected: no output after G1.
- `grep -rn "BleSimulatorDriver()\|FlutterBlueSensorDriver()" flutter/lib/ui flutter/lib/core/bloc` -- expected: no output after G2.
- `grep -rn "setState(" flutter/lib/ui/pages/{measurement,profile,history_filter,language_region}_page.dart flutter/lib/ui/organisms/idle_band_calibration_wizard.dart` -- expected: no output after G3.

## Suggested Review Order

**Entry point — the new idiom**

- Cubit is gone; every bloc is `Bloc<Event,State>`. Start here to see the event-driven shape.
  [`simulator_bloc.dart:16`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L16)
- The event triad that replaced the old public methods (`toggle`/`setEnabled`/`startScenario`/`stop`).
  [`simulator_event.dart:7`](../../flutter/lib/core/bloc/simulator/simulator_event.dart#L7)
- All state/event classes now `Equatable` with `props` — one equality idiom across `auth`/`ble`/`simulator`.
  [`auth_state.dart:3`](../../flutter/lib/core/bloc/auth/auth_state.dart#L3)

**AD-11 / AD-12 — one queue, injected**

- Composition root: the single `BleReceiverService` provided as `IBLESensorDriver` for every bio-signal bloc.
  [`main.dart:118`](../../flutter/lib/main.dart#L118)
- Production now binds the real `FlutterBlueSensorDriver` (was the synthetic `BLESensorDriver`) — review-patch, restores pre-refactor prod.
  [`ble_receiver_service.dart:37`](../../flutter/lib/core/ble/ble_receiver_service.dart#L37)
- Simulator↔hardware swap is centralised here (`setActiveDriver`), replacing MeasurementPage's deleted per-widget swap.
  [`simulator_bloc.dart:21`](../../flutter/lib/core/bloc/simulator/simulator_bloc.dart#L21)
- `BleBloc` field is `IBLESensorDriver` (required, injected); `.distinct()` is now live because the event is `Equatable`.
  [`ble_bloc.dart:11`](../../flutter/lib/core/bloc/ble/ble_bloc.dart#L11)

**Monitoring orchestration (the big one)**

- `SleepMonitoringBloc` absorbs the whole former `_MeasurementPageState`: permission gate, connect, evaluator lifecycle, alert overlay, countdown, signal buffer.
  [`sleep_monitoring_bloc.dart:17`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L17)
- `close()` cancels subs + disposes the evaluator but must NOT `disconnect()` the shared queue (review-patch, AD-12).
  [`sleep_monitoring_bloc.dart:284`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_bloc.dart#L284)
- Composite state; `props` uses `recentSignalBuffer.length` (not the list) so per-100 ms equality is O(1) (review-patch).
  [`sleep_monitoring_state.dart:87`](../../flutter/lib/core/bloc/monitoring/sleep_monitoring_state.dart#L87)
- The page is now `BlocConsumer`-only — no `setState`, no `StreamSubscription`.
  [`measurement_page.dart:473`](../../flutter/lib/ui/pages/measurement_page.dart#L473)

**Calibration extraction**

- `CalibrationBloc` owns the idle-sample + wear-check loop, the `Timer`, and the run-id race guard.
  [`calibration_bloc.dart:14`](../../flutter/lib/core/bloc/calibration/calibration_bloc.dart#L14)
- Wizard is a `BlocConsumer`; snackbars stay in the view via `BlocListener`.
  [`idle_band_calibration_wizard.dart:20`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L20)

**App-flow extraction**

- `AppFlowBloc` owns the `loggedOut→checkingPermission→needsPrimer/permissionCheckFailed→ready` machine + permission orchestration.
  [`app_flow_bloc.dart:9`](../../flutter/lib/core/bloc/app_flow/app_flow_bloc.dart#L9)
- `_MaskerAppState` is now a `BlocBuilder` over `_buildHome(state)`.
  [`main.dart:140`](../../flutter/lib/main.dart#L140)

**Value-state blocs (no streams — plain request→compute→emit)**

- `ProfileBloc` owns the field values + `_calculateBmi()`; controllers stay in the widget and dispatch `ProfileFieldChanged`.
  [`profile_bloc.dart:6`](../../flutter/lib/core/bloc/profile/profile_bloc.dart#L6)
- `HistoryBloc` owns the seed list, the filter predicate, and `severityFor()` AI banding.
  [`history_bloc.dart:5`](../../flutter/lib/core/bloc/history/history_bloc.dart#L5)
- `LanguageRegionBloc` owns the three selections + option lists.
  [`language_region_bloc.dart:7`](../../flutter/lib/core/bloc/language_region/language_region_bloc.dart#L7)
- The three pages, now `BlocBuilder`-only.
  [`profile_page.dart:69`](../../flutter/lib/ui/pages/profile_page.dart#L69)

**Tests & config (peripherals)**

- The AD-12 invariant: one shared queue across `BleBloc` + `SleepMonitoringBloc` + `CalibrationBloc`.
  [`ad12_single_queue_test.dart:22`](../../flutter/test/core/ble/ad12_single_queue_test.dart#L22)
- Per-bloc `blocTest` suites (8 new files) + transformer-timing cases added to `auth`/`ble`.
  [`simulator_bloc_test.dart:1`](../../flutter/test/core/bloc/simulator_bloc_test.dart#L1)
- `equatable` (dep) + `bloc_test`/`mocktail` (dev-dep). Lockfile churn noted in `deferred-work.md`.
  [`pubspec.yaml:17`](../../flutter/pubspec.yaml#L17)
