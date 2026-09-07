# Deferred Work

Findings surfaced during build reviews that were intentionally not addressed in their originating story. Append-only.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Inert Settings rows (Debugging / Developer) are not announced to assistive tech as disabled / not-actionable.
  evidence: EXPERIENCE.md v1.1.0 Accessibility Floor requires inert rows be "announced with a dimmed, not-actionable state rather than being silently unfocusable." `SettingsMenuRow`'s inert variant renders a plain `Row` with no `Semantics(enabled: false)`. The whole app currently has zero `Semantics` usage, so this is an app-wide accessibility gap, not a regression from this change — worth a focused a11y pass.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Row dividers in the Settings list are handled ad hoc in `settings_page.dart`, not by the `SettingsMenuRow` component.
  evidence: DESIGN.md §6 specifies a "1px #334155 divider between rows (never after the last)." This build only has the single Profile row plus a manual `Divider` between Debugging/Developer, so it is not yet a defect. When the planned rows (Notifications, Account, Sign out, About, Caregiver contacts) land, divider handling should move into the component or a shared list wrapper.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: BleReceiverForegroundNotification / BleNotProtectedNotification (persistent Android Foreground Service notifications confirming BLE receiver status) and the Night Mode accessible label on MeasurementPage's monitoring state.
  evidence: Story 2.5's acceptance criteria cover this, but the codebase has zero existing notification/foreground-service infrastructure (no `flutter_local_notifications`, no `flutter_background_service`, no native Android Foreground Service code, no platform channel). Building it is a meaningfully separate native-platform undertaking from the permission-priming screen and OS permission hand-off, which spec-2-5 covers instead. Split approved by Reid during spec planning, 2026-09-05.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Android 10/11 (API 29-30, below the API 31 threshold where `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` exist) have no legacy Bluetooth permission fallback declared — no `android.permission.BLUETOOTH`/`BLUETOOTH_ADMIN` (maxSdkVersion 30) or `ACCESS_FINE_LOCATION` (maxSdkVersion 30, required for BLE scanning pre-API-31).
  evidence: The UX Foundation states the target as "iOS 15+ & Android 10+," so Android 10-11 are explicitly in scope, but `permission_handler`'s `bluetoothScan`/`bluetoothConnect` map to nothing meaningful below API 31 — real BLE scanning on those OS versions needs the legacy permission model instead. Not a regression (zero permissions were requested at all before this story), but incomplete for the full stated OS range. Surfaced by the blind-hunter review lens during step-04; classified as defer rather than a blocking gap since nothing is made worse, but it needs a dedicated follow-up (either add the legacy fallback, or make an explicit product call to raise the minimum supported Android version for this feature to 12+).

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Missing `<uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>` in `AndroidManifest.xml`.
  evidence: Commonly declared alongside BLE permissions to filter the app to BLE-capable devices on the Play Store; absent here. Low risk, cheap to add whenever `AndroidManifest.xml` is next touched.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Bluetooth radio/adapter power state (as opposed to OS permission grant) is never checked or messaged — a user with permission granted but Bluetooth switched off gets no dedicated UI, just a silent `scanAndConnect()` failure.
  evidence: `permission_handler`'s `checkServiceStatus` API exists for exactly this but is unused by `BlePermissionService`. Out of this story's stated Problem (permission, not radio state), but a real adjacent gap.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: iOS `restricted` permission status (MDM/parental-control managed devices) is treated identically to plain `denied` — the blocked state always offers "Open Settings," which may be a dead end since a restricted permission generally cannot be granted from Settings by the user at all.
  evidence: Narrow edge case (managed/parental-control iOS devices) for this patient population; real but low-frequency. Worth distinguishing in copy in a future pass.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Permission revocation *during* an active nocturnal monitoring session (not just during the pre-monitoring pairing/blocked state) is never detected or handled — `build()`'s permission-blocked branch is only reached when not monitoring and not showing the alert overlay.
  evidence: A patient's monitoring session could be silently compromised if the OS revokes Bluetooth permission mid-night. Real safety-relevant gap, but squarely Epic 3's concern (nocturnal monitoring resilience), not Story 2.5's (pairing/calibration, before monitoring begins) — this story never claimed to cover in-session revocation.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: `denied` and `permanentlyDenied` are collapsed into one blocked-state treatment on `MeasurementPage` (always "Open Settings," never an in-app "Try Again" for a merely-denied, not-yet-permanent case).
  evidence: Matches the frozen spec's I/O matrix exactly as written (one row, one behavior, regardless of denial type) — not a defect against this story's contract, but a defensible future UX refinement to offer a lighter-weight retry when the OS could still show its own dialog again.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Potential interaction between `permission_handler`'s explicit permission request and `flutter_blue_plus`'s own internal platform-level Bluetooth prompts during `scanAndConnect()` is unverified either way.
  evidence: `FlutterBlueSensorDriver` (unmodified by this story) may itself trigger platform Bluetooth behavior when `startScan` is called; whether this collides or double-prompts on any OS version wasn't investigated. Worth a dedicated check before relying on this in production.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: In-foreground permission revocation via OS quick-settings (without the app losing focus/backgrounding) is not caught — the live recheck only fires on `initState` and `AppLifecycleState.resumed`.
  evidence: Possible on some Android versions/OEM skins where toggling a quick-settings tile doesn't trigger a lifecycle transition. Narrow timing window, not addressed by this story's matrix.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: IDLE Band apnea model treats "signal parked below `lower_bound`" as breathing, not apnea — a real baseline drift / sensor cooldown could suppress a Tier-1 alarm and even auto-silence an active one.
  evidence: `ApneaEvaluator.evaluateSignal` (post-refactor) flags a stop-breathing tick only when the sample is inside `[lower, upper]` (`AD-04`'s literal definition). The retired `signal <= threshold` model caught low signal as apnea; that safety property is gone. Spec 2-5 explicitly kept `ApneaEvaluator` a minimal adaptation ("deeper Epic 3 evaluator rework is out of scope"), so this belongs to Epic 3 Story 3.3 — or an `AD-04` refinement that also treats a sustained below-`lower` hold as stop-breathing.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: Apnea detection has no debounce / N-of-M smoothing — a single out-of-band noise sample resets the ≥10 s breach counter, and `BreathExcursionDetector` cycles have no time bound so a stale half-excursion can complete a "valid cycle" minutes later and mask an apnea onset.
  evidence: `ApneaEvaluator`'s `else` branch zeroes `_consecutiveBelowThresholdCount` on any non-stop tick (same fragility the old threshold model had); `BreathExcursionDetector.add` latches `_sawInhale`/`_sawExhale` indefinitely (matches spec-2-5 Design Notes). Robustness (debounce, per-cycle time bound, motion-artifact rejection) is Epic 3 Story 3.3 territory.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: No developer-simulator affordance to reach the new wear-check-failed or idle-sample-error wizard states for manual QA.
  evidence: The refactor dropped the "Active Baseline" chip and added `IDLE Band Sample` / `In-Band >10s`, but nothing drives a one-sided-only excursion (wear-check fail) or a silent stream (idle error). Both new UI states are only reachable via automated widget tests. A follow-up dev-tooling pass should add scenarios for them.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: On the real-characteristic path `FlutterBlueSensorDriver.sampleIdleBand` learns the band from the same live breath signal the wear check must then strictly exceed — no resting/breathing separation on the driver side, and `AD-04` mandates no margin — so a contaminated idle sample (patient not still, breathing normally instead of gently, a motion artifact) produces a band as wide as normal breathing, and the wear check can then only time out. The frozen "Wear check — timeout" row makes Retry re-run the wear check (not the idle sample), so the only recovery is a full BLE reconnect.
  evidence: Loop-2 review (blind-hunter + edge-case + verification-gap all independently). The synthetic/mock drivers were fixed by re-shaping the emitter after `sampleIdleBand`; the real path relies entirely on the patient following the "sit still, breathe gently" copy and on the physical sensor's rest-vs-breathing response. Robustness (a wear-check-only excursion tolerance/shrink factor, an in-wizard "re-sample IDLE Band" path, or revisiting the frozen "no margin" decision with the product owner) is Epic 3 calibration hardening, not a Story 2.5 minimal-adaptation concern.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: `FlutterBlueSensorDriver._signalStreamController` is a `final` broadcast controller created at field init and `.close()`d in `disconnect()`, so the instance cannot be reused after a disconnect — a second `scanAndConnect()` returns a permanently-closed `signalStream` and every subsequent sample is silently dropped. `BLESensorDriver` and `BleSimulatorDriver` both recreate their controllers; only the production hardware driver cannot.
  evidence: Loop-2 review. Not reachable through the current `MeasurementPage` (`_bleDriver` is `late final`, `_connectBle` re-runs only while `!_isBleConnected`, which never flips back to false after a first success; `disconnect()` happens only in `dispose()`), so it is latent — but it violates the `AD-12` "queue survives / re-liveness" spirit and will bite any future reconnect control. Fix is to make the controller non-final and lazily recreate it when closed, matching the other two drivers.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: `ApneaEvaluator._stopStreakBeforeRecoveryReset` (10 ticks ≈ 1 s, `[ASSUMPTION]`) is the only guard on the post-breach auto-silence recovery counter. A slow breather (~8 bpm) dwells inside the band for >1 s between breaths, so every breath resets the recovery counter and `autoSilenceRecovery()` can fail to ever fire after a breach even while the patient is breathing normally. There is no test for a 10 ≤ in-band-stretch < 100 tick sequence.
  evidence: Loop-2 review (blind-hunter + verification-gap). The constant was introduced in the loop-2 re-derivation to make the frozen "Recovery" acceptance row satisfiable against a realistic breathing wave; it errs safe (auto-silence harder, not easier) but is untuned. Evaluator recovery/debounce tuning is explicitly Epic 3 Story 3.3.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: A wear-check failure caused by the signal stream closing/erroring mid-check (`connectionLost`) surfaces a Retry button that re-subscribes to the now-closed `signalStream`, whose `onDone` fires again immediately — the Retry is guaranteed to fail, and the wizard has no in-widget path to trigger the page-level BLE reconnect.
  evidence: Loop-2 review. The `onError`/`onDone` fast-fail added in loop 2 is still an improvement over the prior silent 15 s wait + misleading "check the fit" message, but a real recovery needs either a reconnect affordance in the wizard (a new callback on the `{bleDriver, onCalibrationComplete}` surface) or the page to observe the failure and reconnect. Follow-up story.

- source_spec: `spec-2-5-idle-band-calibration-wear-check.md`
  summary: No test exercises `FlutterBlueSensorDriver`'s real-GATT `sampleIdleBand` / persistent `_notifySub` branch (every case in `flutter_blue_sensor_driver_test.dart` is the synthetic fallback), and `BleReceiverService.sampleIdleBand` delegation has no test and no production consumer. The production driver `MeasurementPage` instantiates when `DEV_MODE=false` is only covered indirectly.
  evidence: Loop-2 verification-gap review. `flutter_blue_plus` needs a platform mock/fake to test the real path; the end-to-end wizard test drives `BLESensorDriver`, a pure-synthetic class `MeasurementPage` never instantiates. Add real-path coverage when a `flutter_blue_plus` fake is introduced.

- source_spec: `_bmad-output/implementation-artifacts/spec-bloc-rxdart-solid-standardization.md`
  summary: Adding `bloc_test`/`mocktail` dev-deps downgraded `package_config` 3.0.0 -> 2.2.0 in pubspec.lock and pulled a large transitive test tree (analyzer 13.3.0, test, shelf*, coverage, ...).
  evidence: Flagged by step-04 blind-hunter review of the BLoC standardization diff; `flutter analyze`/`flutter test` stay green so it is not blocking, but a core-tooling lockfile downgrade in a dev-dep bump warrants a deliberate look (pin or accept).

- source_spec: `_bmad-output/implementation-artifacts/spec-bloc-rxdart-solid-standardization.md`
  summary: MeasurementPage no longer reacts to the BLE simulator being toggled ON/OFF while the monitoring page is already open — the old `_simulatorSub` re-ran the permission gate + `connectGeneration++` (calibration reset) on `isSimulatorActive` change; the refactored `SleepMonitoringBloc` only subscribes to scenario changes, and its `_isDevMode` is frozen at construction.
  evidence: step-04 edge-case + blind-hunter review of the BLoC standardization diff, confirmed by the patch pass. Left unfixed on purpose — a faithful restore needs a new bloc param + internal event + mutable dev-mode threaded through `_runStartFlow`/`_onAppResumed` + a reactive `build()` gate, which expands the bloc's public surface (spec "Ask First"), and a naive re-dispatch visibly drops the user out of 0-FPS night mode on a mid-session toggle. Needs a product decision: should a mid-session simulator toggle (a) do nothing, (b) re-run the permission/connect gate without leaving night mode, or (c) fully restart the flow? Note: G2's centralized `BleReceiverService.setActiveDriver` already rebinds the shared signal queue on toggle, so the residual gap is only the permission-gate re-run + calibration-generation bump, and it is dev/QA-only.

- source_spec: `_bmad-output/implementation-artifacts/spec-simulator-mode-connection-state.md`
  summary: An accidental double-tap or round-trip (off→on→off) of the Simulator switch on the calibration/setup screen wipes a COMPLETED IDLE band and re-keys the wizard, because `_connect` unconditionally clears `idleBand`/`isCalibrationComplete` and bumps `connectGeneration` on every toggle-driven `_runStartFlow`.
  evidence: step-04 blind-hunter + edge-case reviews of the simulator-connection fix. The spec's Design Note deliberately specced "calibration resets on every toggle — each is a genuine driver swap", and a test asserts it, so this was left as-is. Reviewers argue a toggle that lands on the same effective gate result should be a no-op. Needs a product call: keep reset-every-toggle, or add a "skip reset when the net driver/gate state is unchanged (and calibration was complete)" guard.
