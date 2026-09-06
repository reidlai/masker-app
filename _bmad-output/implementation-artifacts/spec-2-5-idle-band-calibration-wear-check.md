---
title: 'Epic 2 Story 2.5: IDLE Band Calibration & Wear Check'
type: 'refactor'
created: '2026-09-06'
status: 'done'
review_loop_iteration: 2
baseline_commit: 8c3fb007487e29b077d1957f80e04eac43f5fd5f
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The calibration code (`spec-2-1`, marked `done`) implements the retired 2-stage thermal model — `N_idle` noise floor, `V_pp` active-breath baseline, a `0.10 × V_pp` apnea threshold, and a `ΔV < 1.5 × N_idle` wear guardrail. PRD v2.5.0 / `AD-04` replace this with a single-stage **IDLE Band**: the running min/max of a worn ~10 s idle sample, with apnea and breath detection defined directly against that band in raw signal units.

**Approach:** Add an `IdleBand` value type and a `BreathExcursionDetector` (the reusable valid-breath / in-band predicate). Rework the `IBLESensorDriver` calibration surface and all four implementations to produce an `IdleBand` instead of a threshold. Replace the calibration wizard organism with a two-step IDLE Band wizard (idle sample → wear check). Rewire `MeasurementPage` and the developer simulator bar. Adapt `ApneaEvaluator` minimally to consume the band so the app stays green; the deeper Epic 3 evaluator rework is out of scope.

## Boundaries & Constraints

**Always:**
- All code and commands run from the `flutter/` directory.
- Work in raw signal units end to end. No thermal-to-volumetric (L/s) conversion, no `V_pp`, no `0.10 × V_pp` threshold anywhere.
- IDLE Band = running `min`/`max` of the idle window; it only widens within the window, never narrows, no margin applied.
- A **valid breath** requires the signal to reach/exceed `upper` (inhale) **and** reach/fall below `lower` (exhale) within one cycle. A phase that crosses only one bound does not count.
- A **stop-breathing sample** is any sample with `lower <= value <= upper`.
- Idle-sample window default **10 s**; wear-check window default **15 s** (both `[ASSUMPTION]`, expose as named constants).
- The wear check blocks "Start Sleep Monitoring" until **≥ 2 valid breath-excursion cycles** are observed within the check window; on failure show the toast `"Sensor not detecting breathing — check the fit."` with a **Retry** — never auto-advance, never silently retry.
- Calibration and the wear check consume the one unified `signalStream` (`AD-12`); no new BLE subscription, no second queue.
- `flutter analyze` stays at 0 errors; keep the existing 5 info-level lints or fewer.
- Keep `IBLESensorDriver` the single abstraction: every driver (`BLESensorDriver`, `BleSimulatorDriver`, `BleReceiverService`, `FlutterBlueSensorDriver`) implements the new surface identically.

**Ask First:**
- Introducing a persistence dependency (Hive / SQLCipher / drift) — there is none in the project today.
- Changing `ApneaEvaluator`'s public escalation surface (`ApneaState.caregiverEscalated`, the Tier-2 countdown timer) — that is Epic 3 territory.

**Never:**
- Do not persist the IDLE Band to a `SleepSession` record — no model or persistence layer exists; deferred (see Spec Change Log / deferred-work).
- Do not rewrite `ApneaEvaluator`'s ≥10 s windowing / auto-silence structure or remove the escalation path.
- Do not touch BLE discovery, pairing, or cloud-binding logic (that half of `spec-2-1` stays).
- Do not build the `MOB_SLEEP_MONITOR` pre-session "Start" state (Epic 3 Story 3.1).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Idle sample | ~10 s of resting-signal samples on `signalStream` | `IdleBand(lower = min, upper = max)`; band readout updates live; advances to wear check | If the window elapses with **no** samples received (stream silent), band is invalid → hold at step 1, show "No signal from your D-BAND — check the connection", offer Retry |
| Wear check — pass | Patient breathes; ≥ 2 cycles each cross above `upper` and below `lower` | "Calibration Complete — Ready for Sleep ✓"; "Start Sleep Monitoring" enabled; wizard emits the `IdleBand` | — |
| Wear check — timeout | Check window elapses with < 2 valid cycles (e.g. only one-sided excursions) | Gate held; toast `"Sensor not detecting breathing — check the fit."`; **Retry** re-runs the wear check (not the idle sample) | — |
| Degenerate band | `lower == upper` after the idle sample | Every non-equal sample is an excursion on both sides simultaneously → wear check can still pass; do not divide by band width anywhere | — |
| Apnea eval, monitoring | Live `signalStream` with a ≥ 10 s stretch of stop-breathing samples (no valid cycle completes) | `ApneaEvaluator` reaches `breachAlert` exactly as before (≥ 100 ticks) | — |
| Recovery, monitoring | ≥ 5 s of resumed valid excursions after a breach | Auto-silence path fires exactly as before (≥ 50 ticks) | — |

</frozen-after-approval>

## Code Map

> **Loop-1 invariant (see Spec Change Log):** once `scanAndConnect` succeeds, every driver keeps `signalStream` emitting continuously at ~10 Hz until `disconnect`. `sampleIdleBand` *observes* that stream; `startMonitoringSession` *replaces the shaping*, not *starts emission from silence*. The wizard's wear check (step 2) subscribes to that already-live stream between the idle sample and monitoring start.
>
> **Loop-2 invariant (see Spec Change Log — wear-check emission shape):** on a synthetic/mock driver (`BLESensorDriver`, `BleSimulatorDriver`, `FlutterBlueSensorDriver` synthetic fallback) the wear check can only pass if the emitted signal *strictly exceeds the returned band on both sides*. Therefore: `sampleIdleBand` captures the running min/max from a **resting** shape during its `window`, and **on return re-shapes the same continuous emitter to a band-spanning "breathing" wave** (the shape `startMonitoringSession` would use) so wizard step 2 observes real excursions. The band is fixed at the moment the window closes; widening the emission afterward does not change the returned `IdleBand`. A driver fed by a real characteristic needs no synthetic shaping — the patient's own breath supplies the excursions. This is the same class of defect as the Loop-1 fix (wear check unreachable, suite green), one layer deeper: emission stayed live but in a shape that can never satisfy the excursion predicate.

- `lib/core/monitoring/idle_band.dart` — **NEW.** `IdleBand` (immutable `lower`, `upper`; **`const` ctor asserts `lower <= upper`**; `IdleBand.fromSamples(Iterable<double>)` throws on empty; `isInBand(double)` inclusive of both bounds). `IdleBandAccumulator` (feed samples during the idle window; ignores non-finite samples; `.band` nullable). `BreathExcursionDetector` — feed samples, tracks per-cycle "reached **above** `upper`" (strict `>`) + "reached **below** `lower`" (strict `<`); a cycle completes (increments `validCycleCount`) when both are true, then resets the flags; `isStopBreathingSample(double)` uses inclusive `isInBand`. Pure Dart, no Flutter import.
- `lib/core/ble/i_ble_sensor_driver.dart` — remove `startIdleCalibration`, `stopIdleCalibration`, `calibrateStage1NoiseFloor`, `calibrateStage1NoiseCeiling`, `startTrainingCalibration`, `stopTrainingCalibration`, `signalThreshold`. Add `Future<IdleBand> sampleIdleBand({Duration window = const Duration(seconds: 10)})` — **doc it: streams live samples for `window` and returns their running min/max; throws `StateError` if no sample arrives.** Enum `SensorMonitoringPhase`: `calibratingIdle` → `calibratingIdleBand`; `calibratingTraining` → `wearCheck` **only if a driver actually emits it** — otherwise drop the value (no dead case / doc).
- `lib/core/ble/ble_sensor_driver.dart` — delete `_ambientNoiseFloor`, `_breathBaselineVpp`, `_signalThreshold` + getters + all Stage-1/2 methods. **Start a single continuous ~10 Hz emitter on `scanAndConnect` and stop it only on `disconnect`.** `sampleIdleBand` shapes that emission to a narrow resting signal (~`0.30`) **for its window only**, captures the running min/max, and **before returning re-shapes the emitter to the band-spanning "breathing" wave** (e.g. `0.30 + 0.25*sin`, `_EmitShape.breathing`) so the wizard's wear check observes strict excursions on both sides of the returned band — do **not** leave the emitter in the resting shape on return. `startMonitoringSession` keeps that same breathing shape. `sampleIdleBand` throws `StateError` on an empty accumulator.
- `lib/core/ble/ble_simulator_driver.dart` — same surface changes. `SimulatorScenario`: `idleNoise` → `idleBandSample`, `activeBreath` removed, `apneaAlert` → `inBandNoExcursion`; keep `normalRespiration`, `recovery`, `none`. Signal shapes internally consistent with a band from `idleBandSample` (~`0.25–0.35`): `idleBandSample` ≈ `0.3 + 0.05*sin`; `normalRespiration` ≈ `0.275 + 0.2*sin` (crosses both bounds — comment must match the formula); `inBandNoExcursion` flat `0.30`; **`recovery` must also cross both bounds** (resumed breathing) — not park above. `sampleIdleBand` runs `idleBandSample` for the window, then **before returning switches the running scenario to `normalRespiration`** so the wear check observes strict excursions against the just-returned band (do not leave `idleBandSample` running — its range is exactly the learned band and yields zero valid cycles). It throws `StateError` on an empty accumulator (no hardcoded fallback band). When accumulating from `_signalSubject` (a `BehaviorSubject`), **skip the replayed current value** (`.skip(1)` or re-seed at window start) so a stale sample from a prior scenario cannot widen the band. `stopMonitoringSession()` must **not** call `stopSimulation()` — per `AD-12` the emitter runs until `disconnect()`; revert it to a resting scenario instead (mirror `BLESensorDriver.stopMonitoringSession`, which only re-shapes).
- `lib/core/ble/flutter_blue_sensor_driver.dart` — same surface changes; `sampleIdleBand` accumulates min/max from the real `_telemetryCharacteristic` over `window` and **keeps `setNotifyValue(true)` + a persistent notify subscription piping into `_signalStreamController` after it returns** (so the wear check and monitoring both read a live stream). The **synthetic fallback** likewise keeps emitting after the window **and must set `_spanningWave = true` before `sampleIdleBand` returns** — otherwise the fallback (CI / simulator-on-device) emits `0.30 + 0.02*sin` forever, exactly the learned band, and the wear check can never accrue a cycle. A real characteristic needs no such shaping (real breath crosses the band). Delete `stopTrainingCalibration`, the `netSample = sample - _ambientNoiseFloor` subtraction, `_signalThreshold`. Throw `StateError` on empty.
- `lib/core/ble/ble_receiver_service.dart` — drop the Stage-1/2 delegation + `signalThreshold`; add `sampleIdleBand` delegating to `_activeDriver`. Replace the "V_pp centered at 5.0 L/s" seed-rationale comment with a neutral one. Seed value: `0.0` **only if `LiveWaveformChart` + `MeasurementPage` are verified to render `0.0` without divide/render artifacts** (the removed comment claimed otherwise); else seed a small positive resting value (e.g. `0.3`).
- `lib/core/monitoring/apnea_evaluator.dart` — constructor `ApneaEvaluator({required IdleBand idleBand})` (was `{required double threshold}`); hold a `BreathExcursionDetector`. `evaluateSignal`: **guard `!signalValue.isFinite` → return.** A "stop-breathing tick" = `isStopBreathingSample(v)` AND no cycle completed this tick; a completed cycle resets `_consecutiveBelowThresholdCount` and feeds the recovery counter. Keep the ≥100 / ≥50 tick thresholds, `breachAlert`, `patientSafe`, escalation timer untouched. Rename `_consecutiveBelowThresholdCount` → `_consecutiveStopBreathingTicks` and fix the stale "resumed excursions" comment.
- `lib/ui/organisms/idle_band_calibration_wizard.dart` — **NEW** (replaces `thermal_calibration_wizard.dart`, deleted). `IdleBandCalibrationWizard({required IBLESensorDriver bleDriver, required void Function(IdleBand) onCalibrationComplete})`. Two-step `_WizardStep` state machine, STEP 1/2 badges, live band readout, idle-error + wear-check-failed copy, SnackBar + inline Retry — **keep as built.** Changes:
  - The wear-check window timeout must be a **stored `Timer`**, cancelled at the start of each `_runWearCheck` run and in `dispose()`, and its callback guarded by a per-run token so a stale run can't fail an active retry. Step 2 subscribes to `bleDriver.signalStream` (now guaranteed live *and band-spanning* per the Loop-2 invariant).
  - `_startIdleSample` must catch **any** error from `sampleIdleBand`, not only `on StateError` — a real BLE failure (`PlatformException`, disconnection) currently escapes the un-awaited future and leaves `_sampling == true` (spinner hangs forever). Add a generic `catch (_)` (or `finally`) that clears `_sampling` and shows the idle-error copy.
  - The wear-check `signalStream` subscription must handle `onError` / `onDone` — if the stream closes or errors mid-check (BLE drop / `disconnect()` closing the controller) resolve the run as failed immediately with a connection-loss message instead of silently waiting out the full `kWearCheckWindow`.
- `lib/ui/pages/measurement_page.dart` — use `IdleBandCalibrationWizard`; store the emitted `IdleBand` in `_idleBand`; drop the `BLESensorDriver` cast hack (pass `_bleDriver`). `_startSleepMonitoring`: **`if (_idleBand == null) return;`** then `ApneaEvaluator(idleBand: _idleBand!)`. Gate the Start button on `_idleBand != null` (not just `_isCalibrationComplete`). On BLE disconnect / a fresh `_connectBle`, clear `_idleBand` and `_isCalibrationComplete`. Header "Bedtime Sensor Calibration" → "IDLE Band Calibration". Additional fixes:
  - The Start button's `onPressed` for the not-ready state must be **`null`** (disabled), not an empty `() {}` closure — an empty closure makes a non-functional button look tappable.
  - `_apneaEvaluator!.countdownStream.listen(...)` must be **assigned to a `StreamSubscription` field and cancelled** in `_stopSleepMonitoring` and `dispose()` — today its return value is discarded and a subscription leaks on every monitoring start.
  - Give `IdleBandCalibrationWizard` a `ValueKey` that changes on each `_connectBle` (e.g. a monotonically bumped `int _connectGeneration`) so a reconnect remounts the wizard — otherwise clearing `_idleBand`/`_isCalibrationComplete` on the page leaves the wizard still showing "Calibration Complete" with no way to re-run.
  - The secondary `_serviceTelemetrySub` feed from `_telemetryService` (`BleSimulatorDriver` singleton) must never let a tick reach `evaluateSignal` twice: keep the `!identical(_telemetryService, _bleDriver)` guard **and** only subscribe when `_isDevMode` is false is *not* correct either (the singleton is idle in production). Simplest safe form: drop `_serviceTelemetrySub` entirely (the one unified `signalStream` from `_bleDriver` is the AD-12 queue), or, if kept, add a one-line comment stating why a second source is needed and keep the `identical` guard. Do not feed the evaluator from two live sources.
- `lib/ui/organisms/developer_simulator_bar_organism.dart` — chip set → `IDLE Band Sample` (`idleBandSample`), `Normal 16 bpm` (`normalRespiration`), `In-Band >10s` (`inBandNoExcursion`), `Recovery 5s` (`recovery`). Remove the `Active Baseline` chip.
- `lib/ui/organisms/ble_simulator_organism.dart` — check for `SimulatorScenario` refs; update to the renamed values if present.
- Tests — update: `test/core/apnea_evaluator_test.dart` (`threshold:` → `idleBand:`, add band-based cases), `test/ui/measurement_page_test.dart` (fake driver: replace the removed methods with `sampleIdleBand`), `test/core/ble_sensor_driver_test.dart` (drop Stage-1/2 tests, add `sampleIdleBand` min/max test), `test/core/ble/ble_receiver_service_test.dart`, `test/ui/ble_simulator_organism_test.dart`, `test/ui/developer_simulator_bar_organism_test.dart` (chip labels). **NEW:** `test/core/monitoring/idle_band_test.dart`.

## Tasks & Acceptance

**Execution:** *(all reset to `[ ]` for the loop-2 re-derivation — code reverted to `baseline_commit`)*
- [x] `lib/core/monitoring/idle_band.dart` — create `IdleBand`, `IdleBandAccumulator`, `BreathExcursionDetector` per Code Map.
- [x] `lib/core/ble/i_ble_sensor_driver.dart` — swap the calibration surface for `sampleIdleBand`; rename the two `SensorMonitoringPhase` values.
- [x] `lib/core/ble/ble_sensor_driver.dart` — remove threshold/`V_pp`/`N_idle`; implement `sampleIdleBand` (re-shapes emitter to breathing on return).
- [x] `lib/core/ble/ble_simulator_driver.dart` — rename scenarios, fix signal shapes, implement `sampleIdleBand` (switches to `normalRespiration` on return; `.skip(1)` the replayed value; `stopMonitoringSession` keeps the emitter live).
- [x] `lib/core/ble/flutter_blue_sensor_driver.dart` — same surface changes over the real characteristic + synthetic fallback (fallback sets `_spanningWave = true` on `sampleIdleBand` return).
- [x] `lib/core/ble/ble_receiver_service.dart` — delegate `sampleIdleBand`; drop removed methods; neutralize the seed comment/value.
- [x] `lib/core/monitoring/apnea_evaluator.dart` — constructor takes `IdleBand`; route detection through `BreathExcursionDetector`.
- [x] `lib/ui/organisms/idle_band_calibration_wizard.dart` — new two-step wizard (generic error catch in `_startIdleSample`; `onError`/`onDone` on the wear-check sub); delete `thermal_calibration_wizard.dart`.
- [x] `lib/ui/pages/measurement_page.dart` — wire the new wizard + `IdleBand` + `ApneaEvaluator`; drop the cast hack; update copy; Start `onPressed: null` when not ready; store + cancel the `countdownStream` sub; `ValueKey` on the wizard per connect; no double-feed to `evaluateSignal`.
- [x] `lib/ui/organisms/developer_simulator_bar_organism.dart` — new chip set.
- [x] `lib/ui/organisms/ble_simulator_organism.dart` — align any `SimulatorScenario` refs.
- [x] `test/core/monitoring/idle_band_test.dart` — unit-test the I/O matrix rows for band + detector (min/max accumulation, both-bounds-required, one-sided rejected, `lower == upper`, in-band predicate).
- [x] `test/**` — update the six existing tests that reference the removed surface so `flutter test` passes.
- [x] `test/ui/measurement_page_test.dart` — **NEW end-to-end case, driven by a REAL `IBLESensorDriver` implementation (`BLESensorDriver`), not a bespoke cooperating fake.** Granted permission; drive the wizard through the idle sample, then through ≥ 2 wear-check excursion cycles produced by the driver's own post-`sampleIdleBand` emission (no manual scenario/chip switching), tap "Start Sleep Monitoring", assert `startMonitoringSession` fired and no exception. A fake is allowed *only* if its `sampleIdleBand` returns the true running min/max of the same stream it keeps emitting (not a hand-picked narrower band). This is the case that must catch a wear check that is unreachable because the emitter shape equals the learned band.
- [x] `test/core/ble_sensor_driver_test.dart` — **NEW:** after `await sampleIdleBand()` on a connected `BLESensorDriver`, feed the still-live `signalStream` into a `BreathExcursionDetector(returnedBand)` and assert it reaches ≥ 2 valid cycles within `kWearCheckWindow` — i.e. the post-idle emission actually spans the band the same call returned. Mirror for `BleSimulatorDriver` and the `FlutterBlueSensorDriver` synthetic fallback (add `test/core/ble/flutter_blue_sensor_driver_test.dart` if absent).
- [x] `test/core/ble/ble_simulator_driver_test.dart` — **NEW:** `BleSimulatorDriver().sampleIdleBand()` → `ApneaEvaluator(idleBand: band)` → feed `inBandNoExcursion` samples, assert `breachAlert` after ~100 ticks; feed `normalRespiration`, assert state stays `normal`; assert the stream still emits after `sampleIdleBand` returns; assert `stopMonitoringSession()` does not stop emission (stream still live afterward).
- [x] `test/ui/idle_band_calibration_wizard_test.dart` — **NEW (Matrix row "Wear check — timeout"):** an in-band-only driver → wizard reaches step 2, `< kRequiredValidCycles` accrue, `kWearCheckWindow` elapses → gate held, `"Sensor not detecting breathing — check the fit."` + Retry surface, `onCalibrationComplete` never fires; Retry re-runs the wear check (`sampleIdleBand` call count unchanged) and can time out again while still gated.

**Acceptance Criteria:**
- Given a paired sensor, when the patient runs `MOB_CALIBRATION`, then step 1 produces an `IdleBand` from the running min/max of the idle window and step 2 requires ≥ 2 valid breath-excursion cycles before "Start Sleep Monitoring" is enabled; a wear-check timeout holds the gate with the retry toast.
- Given monitoring is started with the calibrated `IdleBand`, when the signal stays inside `[lower, upper]` for ≥ 10 s with no valid cycle completing, then `ApneaEvaluator` reaches `breachAlert`; when valid excursions resume for ≥ 5 s, auto-silence fires.
- Given `DEV_MODE=true`, when a developer taps the `In-Band >10s` chip during monitoring, then an apnea breach is produced without hardware; the `IDLE Band Sample` chip yields a band-forming resting signal and `Normal 16 bpm` crosses both band lines.
- Given the full change set, when `cd flutter && flutter analyze && flutter test` runs, then analyze reports 0 errors (≤ 5 info) and all tests pass.

## Spec Change Log

### 2026-09-06 — loop 2 (bad_spec)

**Triggering finding:** The loop-1 fix kept `signalStream` live through the wear check, but on `BLESensorDriver`, `BleSimulatorDriver`, and the `FlutterBlueSensorDriver` synthetic fallback `sampleIdleBand` returns with the emitter *still producing the exact resting shape the `IdleBand` was learned from*. `BreathExcursionDetector` requires strict `v > upper` **and** `v < lower`; a signal whose own min/max *is* the band never strictly leaves it, so the wear check accrues zero valid cycles, times out after `kWearCheckWindow`, shows "Sensor not detecting breathing — check the fit.", and Retry loops forever. In `DEV_MODE` (the default; `_bleDriver` is `BleSimulatorDriver`) the patient/demo user can never reach "Start Sleep Monitoring" unless they happen to tap the "Normal 16 bpm" dev chip mid-check. On real hardware the patient's breath crosses the band, so the ship path "works" — but every automated test and every dev/demo build is deadlocked. The loop-1 end-to-end test missed it because `_FakeSensorDriver` runs a fixed 0.5/0.1 band-crossing emitter through *both* phases and returns a hardcoded `IdleBand(0.2, 0.4)` narrower than its own emission — a shape no real driver produces.

**Amended (non-frozen sections only):** (1) **Loop-2 invariant** added to the Code Map — on a synthetic/mock driver `sampleIdleBand` captures min/max from a resting shape *during* its window and, **before returning, re-shapes the same continuous emitter to a band-spanning "breathing" wave** so wizard step 2 sees real excursions; the returned band is frozen at window close. Per-driver: `BLESensorDriver` → `_EmitShape.breathing`; `BleSimulatorDriver` → switch running scenario to `normalRespiration`; `FlutterBlueSensorDriver` synthetic fallback → `_spanningWave = true`. Real-characteristic drivers do no shaping. (2) The end-to-end test must run against a **real `IBLESensorDriver` implementation** (`BLESensorDriver`), with no manual scenario/chip switching; a fake is allowed only if its `sampleIdleBand` returns the true running min/max of the same stream it keeps emitting. (3) New driver tests: after `sampleIdleBand`, the still-live stream fed into `BreathExcursionDetector(returnedBand)` reaches ≥ 2 cycles within `kWearCheckWindow`, for each synthetic driver. (4) Folded-in patch-class fixes: `BleSimulatorDriver.sampleIdleBand` skips the `BehaviorSubject` replayed value (`.skip(1)`); `BleSimulatorDriver.stopMonitoringSession()` no longer calls `stopSimulation()` (AD-12 — emitter runs until `disconnect`); wizard `_startIdleSample` catches **any** error from `sampleIdleBand`, not only `StateError` (spinner-hang fix); wizard wear-check sub handles `onError`/`onDone` (fail fast on mid-check disconnect); `measurement_page` Start button `onPressed: null` when not ready (not an empty closure); `measurement_page` stores + cancels the `countdownStream` subscription; `IdleBandCalibrationWizard` gets a per-connect `ValueKey` so a reconnect remounts it; the evaluator is never fed from two live sources.

**Known-bad state avoided:** a build where the wear check is unreachable on every non-hardware driver (all tests, all dev/demo runs) because the post-idle emission shape equals the learned band — with a green suite because the only end-to-end test uses a fake that returns a hand-narrowed band.

**KEEP (must survive re-derivation):**
- Everything in the loop-1 KEEP list below still holds.
- The loop-1 continuous-emitter architecture — one emitter started in `scanAndConnect`, stopped only in `disconnect`; `sampleIdleBand`/`startMonitoringSession` re-shape, never start/stop it. Loop 2 only adds: `sampleIdleBand` returns with the emitter already in the breathing/spanning shape (not resting).
- The `idle_band.dart` structure, the two-step wizard UX, `ApneaEvaluator({required IdleBand idleBand})` + `BreathExcursionDetector` routing, the `SimulatorScenario` rename set and dev-bar chip labels, the stored per-run wear-check `Timer` + `_wearCheckRunId` token, `flutter analyze` 0 errors / ≤ 5 info, all tests green.
- `IdleBand.fromSamples` stays as the documented public constructor even though production accumulation uses `IdleBandAccumulator` — it is intentionally tested surface for Epic 3 reuse, not dead code.

**Loop-2 re-derivation outcome (step-04 re-run):** re-implemented from this amended spec; `flutter analyze` 0 errors / 2 info, `flutter test` 99 pass. The three blind/edge-case/verification reviewers confirmed the wear-check reachability defect is closed on the synthetic drivers and covered by a real-`BLESensorDriver` end-to-end test plus per-driver "emission spans the returned band" tests; a `test/ui/idle_band_calibration_wizard_test.dart` case now covers the frozen "Wear check — timeout" matrix row. No surviving `bad_spec`/`intent_gap`. Four patch-class fixes applied post-review: `ble_receiver_service.resetForTest()` seed `5.0`→`0.3`; `FlutterBlueSensorDriver._startRealNotify` made idempotent (no GATT-subscription churn at `startMonitoringSession`); synthetic-fallback emitter cancelled on the `sampleIdleBand` `StateError` path; `ApneaEvaluator._consecutiveNormalCount` renamed `_recoveryTicks` + comments corrected (behaviour unchanged). Five items routed to `deferred-work.md`: real-path idle-sample contamination vs frozen "no margin"; `FlutterBlueSensorDriver` non-reusable `final` stream controller; `_stopStreakBeforeRecoveryReset` slow-breather tuning; `connectionLost` Retry dead-end; missing real-GATT / `BleReceiverService.sampleIdleBand` test coverage.

### 2026-09-06 — loop 1 (bad_spec)

**Triggering finding:** On every real `IBLESensorDriver` implementation the wear check (wizard step 2) receives **no `signalStream` samples**, so it always times out and "Start Sleep Monitoring" never unlocks — the patient can never begin monitoring. Root cause: `sampleIdleBand` stops emitting when it returns (`BLESensorDriver` cancels its emitter timer; `BleSimulatorDriver` calls `stopSimulation()`; `FlutterBlueSensorDriver` cancels its temp subscription), and nothing feeds `signalStream` again until `startMonitoringSession`. The first spec did not require the stream to stay live between the idle sample and monitoring start, and did not require an end-to-end driver test through the wizard, so the regression shipped green (the wizard widget test uses a cooperating fake driver).

**Amended:** Code Map + Design Notes + Tasks + Verification below now require: (1) each driver keeps `signalStream` continuously live from a successful `scanAndConnect` until `disconnect` (per `AD-12`) — `sampleIdleBand` and `startMonitoringSession` observe/replace that one continuous emission rather than starting it from silence; (2) `SensorMonitoringPhase.wearCheck` is either emitted by the driver during the wear check or removed from the enum (no dead value / misleading doc); (3) a consistent `sampleIdleBand` no-signal contract across all four impls (throw `StateError`; no silent hardcoded fallback); (4) `IdleBand` constructor asserts `lower <= upper`; strict `>`/`<` on excursion comparisons vs inclusive `isInBand`; non-finite guards in `IdleBandAccumulator.add` and `ApneaEvaluator.evaluateSignal`; (5) the wizard's wear-check timeout uses a stored, per-run, `dispose()`-cancelled `Timer`; (6) `BLESensorDriver.startMonitoringSession`'s synthetic wave spans the band its own `sampleIdleBand` produces; (7) `measurement_page` guards `_idleBand` and clears it + `_isCalibrationComplete` on disconnect; (8) `BleSimulatorDriver` scenario comments match their formulas and `recovery` crosses both bounds; (9) new end-to-end test: `MeasurementPage` + a realistic driver → wizard → Start → monitoring, and a `BleSimulatorDriver` `sampleIdleBand` → `ApneaEvaluator` scenario-consistency test.

**Known-bad state avoided:** a build where the wear check is unreachable on real hardware but the whole test suite is green.

**KEEP (must survive re-derivation):**
- `lib/core/monitoring/idle_band.dart` structure — `IdleBand` / `IdleBandAccumulator` / `BreathExcursionDetector` split, the both-bounds-required cycle logic in Design Notes, `test/core/monitoring/idle_band_test.dart`.
- The two-step wizard UX exactly as built (`_WizardStep` state machine, the STEP 1/2 badges, the idle-error and wear-check-failed copy, the live band readout, the SnackBar + inline Retry). Only its timeout-timer handling changes.
- `ApneaEvaluator({required IdleBand idleBand})` + `BreathExcursionDetector`-routed detection; the untouched `>=100` / `>=50` tick structure and escalation surface.
- `SimulatorScenario` rename set (`idleBandSample` / `normalRespiration` / `inBandNoExcursion` / `recovery` / `none`) and the dev-bar chip labels.
- The seed-value change to `0.0` **only if** `LiveWaveformChart` / `MeasurementPage` are confirmed to render `0.0` without artifacts; otherwise seed a small positive resting value.
- `flutter analyze` at 0 errors / ≤ 5 info; all existing + new tests green.

## Design Notes

`BreathExcursionDetector` cycle logic (the subtle part):

```dart
// feed each sample; a cycle completes when the signal has been BOTH
// strictly above upper AND strictly below lower since the last completion.
// Strict comparisons: a sample resting exactly on a bound is in-band
// (stop-breathing), not an excursion — so a signal whose own min/max IS the
// band produces zero cycles (this is why the emitter must widen for the
// wear check — see the Loop-2 invariant).
void add(double v) {
  if (v > band.upper) _sawInhale = true;
  if (v < band.lower) _sawExhale = true;
  if (_sawInhale && _sawExhale) {
    validCycleCount++;
    _sawInhale = false;
    _sawExhale = false;
  }
}
bool isStopBreathingSample(double v) => v >= band.lower && v <= band.upper;
```

`ApneaEvaluator.evaluateSignal`: feed the detector every tick. `stopTick = detector.isStopBreathingSample(v) && !cycleCompletedThisTick`. Count consecutive `stopTick`s toward the existing `>= 100` breach threshold; a completed cycle resets that counter and advances the normal-recovery counter toward `>= 50`.

`SimulatorScenario` signal shapes must be internally consistent: a band learned from `idleBandSample` (~`0.25–0.35`) must be exceeded by `normalRespiration` on both sides and never exceeded by `inBandNoExcursion`.

**Wear-check emission (Loop-2, load-bearing):** the wear check's excursion predicate is strict (`v > upper` AND `v < lower`). If the emitter keeps producing the *same* shape the band was learned from, `v` never strictly leaves the band and the check can never accrue a cycle — an infinite "Sensor not detecting breathing" loop that blocks the patient from ever starting monitoring. So on a synthetic/mock driver `sampleIdleBand` must, before returning, widen the still-running emitter to a shape that strictly overshoots the just-returned band on both sides (`BLESensorDriver` → `_EmitShape.breathing`; `BleSimulatorDriver` → `normalRespiration` scenario; `FlutterBlueSensorDriver` synthetic fallback → `_spanningWave = true`). A real-characteristic driver leaves shaping alone — the patient's breath supplies the excursions. Tests must prove this against a *real* `IBLESensorDriver` implementation, not a fake that returns a hand-narrowed band.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: 0 errors, ≤ 5 info issues.
- `cd flutter && flutter test` — expected: all tests pass, including `idle_band_test.dart`, the new `measurement_page` end-to-end wizard→Start case (driven by a real `BLESensorDriver`), the new post-`sampleIdleBand` "emission spans the returned band" driver tests, and the new `ble_simulator_driver` sampleIdleBand→ApneaEvaluator case.
- `cd flutter && flutter test test/ui/measurement_page_test.dart test/core/ble_sensor_driver_test.dart test/core/ble/ble_simulator_driver_test.dart` — the cases that specifically prove the wear check is reachable end to end on a real driver (emitter overshoots the learned band), and the simulator "In-Band" scenario still trips a breach against a learned band.

**Manual checks:**
- Run with `--dart-define=DEV_MODE=true`; on `MeasurementPage` confirm the two-step IDLE Band wizard, the live band readout, the wear-check gate + retry toast, and that the `In-Band >10s` chip drives a breach.

## Suggested Review Order

**The signal model (start here)**

- The whole contract in one file: immutable band, running-min/max accumulator, strict-excursion vs inclusive-in-band predicate.
  [`idle_band.dart:25`](../../flutter/lib/core/monitoring/idle_band.dart#L25)
- Both-bounds-required cycle logic — the subtle part; strict `>`/`<` is why the emitter must widen for the wear check.
  [`idle_band.dart:115`](../../flutter/lib/core/monitoring/idle_band.dart#L115)
- The driver surface swap: one `sampleIdleBand` replaces every Stage-1/2 method; enum renamed, no dead `wearCheck` value.
  [`i_ble_sensor_driver.dart:46`](../../flutter/lib/core/ble/i_ble_sensor_driver.dart#L46)

**Continuous emitter + Loop-2 wear-check re-shape (highest risk)**

- Mock driver: one emitter from `scanAndConnect` to `disconnect`; `sampleIdleBand` learns from `resting` then flips to `breathing` before returning.
  [`ble_sensor_driver.dart:85`](../../flutter/lib/core/ble/ble_sensor_driver.dart#L85)
- Simulator: same shape, via a scenario switch to `normalRespiration` on return; `.skip(1)` drops the replayed value; `stopMonitoringSession` keeps the emitter live.
  [`ble_simulator_driver.dart:64`](../../flutter/lib/core/ble/ble_simulator_driver.dart#L64)
- Real hardware: persistent notify subscription from `scanAndConnect`; `_startRealNotify` is idempotent so monitoring start doesn't churn it; synthetic fallback flips `_spanningWave` and is cancelled on the error path.
  [`flutter_blue_sensor_driver.dart:134`](../../flutter/lib/core/ble/flutter_blue_sensor_driver.dart#L134)
- Receiver: pure delegation + the `V_pp`-centred seed neutralised to `0.3` everywhere (field, stream init, `resetForTest`).
  [`ble_receiver_service.dart:99`](../../flutter/lib/core/ble/ble_receiver_service.dart#L99)

**Apnea evaluation (minimal band adaptation)**

- Constructor takes `IdleBand`; detection routed through `BreathExcursionDetector`; `stopTick` = in-band AND no cycle this tick; `≥100`/`≥50` structure + escalation untouched.
  [`apnea_evaluator.dart:43`](../../flutter/lib/core/monitoring/apnea_evaluator.dart#L43)
- `_recoveryTicks` (was `_consecutiveNormalCount`) — only a sustained in-band streak zeroes it; the `[ASSUMPTION]` constant is deferred for tuning.
  [`apnea_evaluator.dart:22`](../../flutter/lib/core/monitoring/apnea_evaluator.dart#L22)

**Calibration wizard + page wiring**

- Two-step `_WizardStep` machine; `_startIdleSample` catches any error (no spinner hang); wear check uses a stored per-run `Timer` + `_wearCheckRunId` token.
  [`idle_band_calibration_wizard.dart:61`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L61)
- Wear-check `onError`/`onDone` fail fast on a mid-check disconnect instead of waiting out the window.
  [`idle_band_calibration_wizard.dart:130`](../../flutter/lib/ui/organisms/idle_band_calibration_wizard.dart#L130)
- Page: `ValueKey(_connectGeneration)` remounts the wizard on every (re)connect; Start `onPressed` is `null` until `_idleBand` is set; single evaluator feed.
  [`measurement_page.dart:414`](../../flutter/lib/ui/pages/measurement_page.dart#L414)

**Peripherals**

- Dev simulator chips realigned to the new scenarios; "Active Baseline" removed.
  [`developer_simulator_bar_organism.dart:78`](../../flutter/lib/ui/organisms/developer_simulator_bar_organism.dart#L78)
- Matrix row "Wear check — timeout": in-band-only driver → gate held, toast + Retry, Retry re-runs the wear check only.
  [`idle_band_calibration_wizard_test.dart:50`](../../flutter/test/ui/idle_band_calibration_wizard_test.dart#L50)
- End-to-end against a real `BLESensorDriver` (no fake, no chip switching) → wizard → ≥2 real cycles → Start reaches monitoring.
  [`measurement_page_test.dart:193`](../../flutter/test/ui/measurement_page_test.dart#L193)
- Per-driver "post-`sampleIdleBand` emission strictly spans the returned band ≥2 cycles within `kWearCheckWindow`".
  [`ble_simulator_driver_test.dart:1`](../../flutter/test/core/ble/ble_simulator_driver_test.dart#L1)
- Band + detector I/O-matrix unit tests.
  [`idle_band_test.dart:1`](../../flutter/test/core/monitoring/idle_band_test.dart#L1)
