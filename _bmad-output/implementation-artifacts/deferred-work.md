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

- source_spec: `_bmad-output/implementation-artifacts/spec-dev-simulator-toolbar-self-gate.md`
  summary: `DeveloperSimulatorBarOrganism`'s no-`SimulatorBloc`-ancestor branch still constructs a full `SimulatorBloc` (two RxDart stream subscriptions in its ctor) before the self-gate renders `SizedBox.shrink()` for an inactive simulator; and `ble_simulator_organism.dart` uses the same `try context.read / else BlocProvider(create: SimulatorBloc())` fallback idiom, now drifted from the toolbar organism.
  evidence: step-04 blind-hunter review. Both prod-unreachable (prod always has the app-root SimulatorBloc). A unified self-gating dev-only section widget (also addresses the "4 places compute isSimulatorActive" duplication flagged in the earlier /bmad-review as AD6/AD7) is the proper fix; out of scope for this bugfix (Ask First: SimulatorBloc provider topology).

- source_spec: `_bmad-output/implementation-artifacts/spec-calibration-requires-ble-connection.md`
  summary: `SleepMonitoringState.isBleConnected` is set only once, at `_connect()` success in `sleep_monitoring_bloc.dart`, and is never reset to `false`. So "connected" really means "the last connect attempt succeeded" — a mid-session BLE drop leaves it `true`, which re-enables every calibration button the connection gate just added. The reported bug (AVD, never connected) is fixed; a *later* drop is not.
  evidence: step-04 blind-hunter review of the calibration connection-gate fix. Fixing it is `SleepMonitoringBloc` work (out of the frozen scope of this bugfix) — it needs live connectivity tracking (e.g. from the driver's phase/connection stream), which also unblocks a proper mid-sample "connection lost" state.

- source_spec: `_bmad-output/implementation-artifacts/spec-calibration-requires-ble-connection.md`
  summary: `IdleBandCalibrationWizard` gates the button callbacks on `isConnected` but has no `didUpdateWidget` teardown, and `CalibrationBloc` has no connection precondition of its own. If `isConnected` flips to `false` while `state.sampling` / `state.wearCheckRunning` is in flight, the bloc's sample/subscription/timer keeps running under a "Connect your D-BAND" message.
  evidence: step-04 blind-hunter + edge-case review. Not reachable through `MeasurementPage` today (every connection change bumps `state.connectGeneration`, and the wizard's `ValueKey(connectGeneration)` remounts it fresh at step 1) — but it is a gap in the organism's own contract and would surface on reuse or if a non-remounting disconnect path is added. Both a `didUpdateWidget` cancel and a `CalibrationBloc`-level guard were Ask-First scoped out of this bugfix.

- source_spec: `_bmad-output/implementation-artifacts/spec-calibration-requires-ble-connection.md`
  summary: Minor polish flagged in step-04 review, out of the frozen scope: (1) the `wearCheckFailed` inline red text hardcodes "Sensor not detecting breathing — check the fit and try again." even when `wearCheckConnectionLost == true` (only the snackbar differentiates the cause); (2) the newly-disabled buttons carry no `Semantics` hint / tooltip explaining *why* they are disabled, and the "Connect your D-BAND…" copy is an unrelated node.
  evidence: step-04 blind-hunter review. The frozen spec's "Never touch the wear-check running/failed UI" and the a11y scope put both outside this fix.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-apnea-index-labeling-and-severity-bands.md`
  summary: Three follow-ups intentionally out of scope for the labeling/severity-band fix: (a) severity-driven ring/badge colour on `SleepScoreOrganism` for non-Normal sessions (it keeps a hard-green ring/badge regardless of the Apnea Index); (b) the alarm-fired "demote AI band to a clinical caption" behaviour on `home_summary_card` (the amber `alarm_fired` treatment stays layered on top of the band logic, not replacing it); (c) a real signed FHIR/PDF exporter with a correct apnea-only code system — `export_doctor_page` still only shows a toast and the FHIR payload lives solely in a mock test fixture.
  evidence: Called out under "Deferred" in the spec's Design Notes. (a) and (b) are also listed under the spec's "Never" boundary; (c) needs a production exporter that does not exist yet.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-apnea-index-labeling-and-severity-bands.md`
  summary: The Morning Sleep Summary caveat swap replaced a footnote that also *defined* the metric ("scores apnea events per hour recorded by D-BAND thermal sensor") with the canonical apnea-only caveat only. The per-hour definition and the sensor provenance no longer appear on `MOB_SLEEP_SUMMARY`; consider restoring a one-line metric descriptor alongside the caveat.
  evidence: step-04 blind-hunter + verification-gap review. Spec's frozen "Always" mandated the verbatim caveat but did not require preserving the descriptor; treated as a copy enhancement for the user to word.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-apnea-index-labeling-and-severity-bands.md`
  summary: `HistorySeverity` and `HistoryState.severityFor` live in `flutter/lib/core/bloc/history/history_state.dart`, so `home_summary_card` (a generic molecule) and any other consumer must import the history bloc's state class to band an Apnea Index. Move the enum + `severityFor` (and a shared `HistorySeverity -> ShadBadgeVariant` mapping) to a neutral `core/domain` location.
  evidence: step-04 blind-hunter + verification-gap review. `home_summary_card`'s new dependency on `history_state.dart` made the mis-layering visible; out of scope for the labeling/band fix.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-apnea-index-labeling-and-severity-bands.md`
  summary: The History filter now shows 5 chips ("All", "Normal (<5)", "Mild (5–15)", "Moderate (15–30)", "Severe (≥30)") in a horizontal scroll row — on a ~375pt phone the "Severe" chip is off-screen until scrolled, and the "(5–15)" / "(15–30)" range labels both print the shared boundary (15) with no inclusive/exclusive marker. Consider shorter, non-overlapping chip labels or a wrap layout.
  evidence: step-04 blind-hunter + edge-case-hunter review. The widget test needed `ensureVisible` before tapping "Moderate"; a UX-copy/layout decision left for the user.

- source_spec: none
  summary: Surface "Unbind BLE Device" and "Unregister User Account" directly in the Settings page Developer section (not only via the Developer Options sub-page).
  evidence: Split from the "BLE Simulator rename + Passkey Simulator toggle" intent (2026-09-09) via multi-goal check [S]. These actions already exist on flutter/lib/ui/pages/developer_options_page.dart ("Onboarding & Reset Tools" card, shipped in commit 0353630 / PR #8) and are specced in _bmad-output/implementation-artifacts/spec-dev-unbind-device-unregister-account.md. The user believes there is no DeveloperOptionsPage and asked for these on the Settings page itself — whoever picks this up must reconcile the two surfaces (reuse a shared helper vs relocate vs duplicate) and review the existing implementation first.
  RESOLVED 2026-09-09: implemented on branch feature/dev-passkey-simulator-toggle — shared helper `flutter/lib/ui/developer/developer_reset_actions.dart` used by both `settings_page.dart` (new rows in the Developer section) and `developer_options_page.dart` (refactored to it). See spec Change Log "#3".

- source_spec: `_bmad-output/implementation-artifacts/spec-dev-passkey-simulator-toggle.md`
  summary: Pre-existing `flutter analyze` warnings in flutter/.
  evidence: verification-gap review of spec-dev-passkey-simulator-toggle. RESOLVED 2026-09-09 on branch feature/dev-passkey-simulator-toggle: `use_build_context_synchronously` fixed by the reset-helper refactor (#3); `developer_options_page_test.dart` unused import removed with the file (#4); `google_fonts` (main.dart) and `ble_simulator_driver` (settings_page.dart) dead imports removed (#4). `flutter analyze` now reports "No issues found!".

- source_spec: `_bmad-output/implementation-artifacts/spec-dev-passkey-simulator-toggle.md`
  summary: BLE Signal Simulator scenario-trigger UI was removed with `developer_options_page.dart` (Change Log #4). Story 1.5's deliverable no longer has a UI, though `SimulatorBloc` / `BleSimulatorDriver` still implement and unit-test the scenarios. `flutter/README.md:129` still describes the old "Advanced section → Developer menu row" flow (stale — section is "Developer", nav row deleted).
  evidence: Human-directed deletion 2026-09-09. If QA needs no-hardware apnea/calibration scenario triggers again, restore `ble_simulator_organism.dart` from git and mount it in the Settings Developer section. README doc pass also pending.

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-stores-reset-seam.md`
  summary: G2 — Rework ProfilePage/ProfileBloc to consume UserProfileService (RxDart BehaviorSubject) instead of the hardcoded 'David Miller' demo data in ProfileState; add empty/loading UI states and a (simulated) fetch-on-login populate path.
  evidence: Multi-goal split 2026-09-09 [S] of the "profile stores + reset seam + logout" request. The first slice (G1a+G1b) only wires clear-on-reset; the load/populate path and the ProfilePage consumer change are their own effort.

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-stores-reset-seam.md`
  summary: G3 — Build the multi-phase onboarding flow (registration -> medical profile -> passkey enrollment -> bedtime-ready), per Epic 0 / Epic 1. The G1b logout currently routes to the existing LoginPage as an interim; once G3 exists, logout should trigger the full onboarding flow.
  evidence: Multi-goal split 2026-09-09 [S]. User asked to "build the multi-phase onboarding too" but it is epic-sized (new screens + state machine) and independent of the reset/logout seam.

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-stores-reset-seam.md`
  summary: SettingsActions.logOut clears the profile stores + auth + app-flow, but does NOT stop an active nocturnal monitoring session or tear down the always-on BLE foreground service. A logged-out user can still have a live BLE receiver running.
  evidence: step-04 blind-hunter review of spec-profile-stores-reset-seam. Out of scope for that slice (spec scoped logout to stores/auth/app-flow only). Belongs with the multi-phase onboarding work (deferred G3) or a dedicated session-teardown-on-logout follow-up; unbindBleDevice already does the BLE reset, logOut should likely call the same path.

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-store-wiring.md`
  summary: G3 — the multi-phase onboarding flow (Task_PatientRegister → Task_CreateUserProfile → Task_RegisterPasskey → bedtime-ready). Route to epic/story planning, NOT a single bmad-build spec — it is Epic-1-sized ("Mobile App Foundation, Settings & Biometric Passkey Onboarding") with existing planning in epics.md §Epic 1, ARCHITECTURE-SPINE §Epic 0/1, and the UX design docs (State_HomeEmpty / onboarding wizard chain / MOB_DEVICE_PAIRING).
  evidence: Multi-goal split 2026-09-09 [S]. User confirmed "G2 as a bmad-build spec now; G3 → epic/story planning". Until G3 exists, logout / unregister route to the existing single-screen passkey LoginPage as the interim.
  RESOLVED 2026-09-09: broken into epics.md Epic 1 stories 1.9 (onboarding wizard + fresh-user routing), 1.10 (account registration), 1.11 (medical profile first-run mode), 1.12 (passkey enrollment). sprint-status.yaml epic-1 reopened to in-progress; 1-9..1-12 = backlog. Build each via /bmad-build in order (1.10/1.12 first, then 1.9 wires them, then 1.11).

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-store-wiring.md`
  summary: ProfilePage "Save & Continue" / check-icon buttons still only show a snackbar — edits are not written back to UserProfileService or the repository, so reopening ProfilePage discards them. Also ProfileState.fromProfile shows BMI 0.0 when a fetched profile carries weight/height but no computedBmi (recompute on load).
  evidence: step-04 blind-hunter review of spec-profile-store-wiring. Out of scope for that slice (spec only hydrated the existing read form; edit/save is "Ask First"). Belongs with a profile-edit-persistence spec, likely alongside the real ProfileRepository write path.

- source_spec: `_bmad-output/implementation-artifacts/spec-profile-edit-save.md`
  summary: ProfilePage has no unsaved-changes guard — editing fields then tapping the back arrow (or navigating away) silently discards the edits. Also no client-side validation (required fields, RFC-5322 email, phone format) on save, and _save() falls back to a hard-coded 'demo-user' userId when saving from an empty store.
  evidence: step-04 blind-hunter review of spec-profile-edit-save. All listed "Ask First" in that spec (out of scope for the save-persistence slice). Belongs with a profile-validation / onboarding spec; the userId fallback resolves when a real ProfileRepository write path assigns IDs.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-9-onboarding-wizard-fresh-user-routing.md`
  summary: OnboardingWizardPage (the AppFlowStage.onboarding root) has no back-press / PopScope handling — Android hardware/gesture back backgrounds or exits the app mid-onboarding instead of stepping back or confirming. Also no cross-relaunch resumability (needs the persistence layer). Both belong with the real step screens in Stories 1.10–1.12.
  evidence: step-04 blind-hunter review of spec-1-9-onboarding-wizard-fresh-user-routing. Out of scope for the wizard-shell slice (placeholder steps have no entered data to protect).

- source_spec: none
  summary: Returning to the Medical Profile onboarding step via "Back" (from Passkey Enrollment) re-reads UserProfileService.instance.current and rebuilds the form's controllers — any entered-but-unsaved edits are lost, violating Story 1.9's "Back returns to the previous step without losing entered data" AC.
  evidence: Split from Story 1.11 clarification (/bmad-build). 1.11 covers wiring the form into the wizard + save/advance + validation; preserving unsaved draft state across step changes needs the step widget's State kept alive (or the draft hoisted into the store/bloc) and is consistent with Story 1.10's already-deferred step-level resume.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-11-medical-profile-first-run-mode.md`
  summary: ProfileForm validation only runs on save — a field's inline error stays visible while the user is correcting it and only clears on the next save press; there is no per-field revalidation on change. The shared single `onChanged` on HealthDemographicsOrganism/EmergencyContactOrganism needs per-field plumbing to fix cleanly.
  evidence: step-04 blind-hunter review of Story 1.11. The spec deliberately scoped "validation runs on save"; live error-clearing is UX polish that needs its own small design (per-field onChanged wiring through the organisms).

- source_spec: `_bmad-output/implementation-artifacts/spec-1-11-medical-profile-first-run-mode.md`
  summary: profile_validators positiveNumberError has no upper/plausible-range bound — weight/height accept any value > 0 (e.g. height "0.5" cm or weight "9999" kg), yielding nonsense BMI. Age is bounded 1–149 but weight/height are not.
  evidence: step-04 blind-hunter review of Story 1.11. The spec scoped weight/height to "positive numerics" only; clinical plausible-range checks (and unit-aware bounds once kg/lb, cm/ft-in land) are a follow-up.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-12-passkey-enrollment-step.md`
  summary: On onboarding completion, verify the user profile exists via ProfileRepository.fetchUserProfile() (API sanity check) and auto-bind a simulated D-BAND when fetchDeviceProfile() is empty, so a fresh user does not land on the Dashboard with no bound device. Needs a new SimulatedProfileRepository bind path + DeviceProfileService wiring at the AppFlowStage.ready transition.
  evidence: Split from Story 1.12 (/bmad-build multi-goal check). Goal A (the Passkey Enrollment step) is what epics.md scopes 1.12 to; this device-provisioning concern hooks the ready-transition (which Goal A does not touch) and crosses into Epic 2 device-binding territory.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-ble-simulator-toggle-off.md`
  summary: BLE Simulator design smells surfaced by the toggle-off review but out of scope for the fix — (1) MeasurementPage + its SleepMonitoringBloc are eager in the MainContainerPage IndexedStack, so they auto-drive the simulator just from being logged in; (2) the Developer-row visibility gate (kDebugMode || DEV_MODE) is broader than the gate that makes the row meaningful (DEV_MODE); (3) BleSimulatorDriver._isSimulatorSubject conflates "simulator is the selected driver" with "simulator is currently emitting" — scanAndConnect/startSimulationScenario/emitSignal/sampleIdleBand all force it true; SimulatorBloc._intendedEnabled seeds from that transient value at construction.
  evidence: step-04 review of spec-fix-ble-simulator-toggle-off + the /bmad-review adversarial pass. The fix (SimulatorBloc restore-target + intent latch) makes the toggle stick without touching any of these; they are the deeper cleanup the user deferred.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-ble-simulator-toggle-off.md`
  summary: No integration test exercises the real toggle-off loop end to end — SimulatorBloc state → MeasurementPage._simulatorActiveStream → SleepMonitoringBloc(DevModeChanged) → _connect → receiver.scanAndConnect(). The fix's widget test uses emitSignal(isSimulator:true) as a proxy for the reconnect; the receiver-swap half is only bloc-tested. A regression that re-couples them could slip past.
  evidence: step-04 verification-gap lens on spec-fix-ble-simulator-toggle-off.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-ble-real-driver-synthetic-connected-status.md`
  summary: SimulatorBloc's `_intendedEnabled` / `SimulatorState.isSimulatorActive` is seeded from `BleSimulatorDriver.instance.isSimulatorActive`'s own pristine flag, which desyncs from whichever driver `BleReceiverService._activeDriver` actually booted onto in a DEV_MODE build — so Settings' "BLE Simulator" switch and Home's device-status card (both reading `SimulatorState.isSimulatorActive` directly via `BlocBuilder`) can show a stale "off" at boot even when the app is genuinely running on the simulator, until the user's first explicit toggle.
  evidence: Verification-gap review of spec-fix-ble-real-driver-synthetic-connected-status (2026-09-11), confirmed via a scratch widget test reproducing main.dart's exact provider composition. User decision: fix MeasurementPage's symptom only for now (verified working); defer the deeper SimulatorBloc boot-seeding fix.

- source_spec: `_bmad-output/implementation-artifacts/spec-fix-ble-real-driver-synthetic-connected-status.md`
  summary: No test exercises `_simulatorActiveStream()`'s priority ordering when BOTH a `BleReceiverService` driver and a `SimulatorBloc` ancestor are present together (confirms branch 1 wins, branch 2 doesn't double-subscribe), or the round-trip (off→on) transition through the new BleReceiverService-sourced path in the actual widget (only the service-level unit test covers the round-trip).
  evidence: blind-hunter + edge-case-hunter review of spec-fix-ble-real-driver-synthetic-connected-status (2026-09-11).

- source_spec: `_bmad-output/implementation-artifacts/spec-passkey-signin-unavailable-when-simulator-off.md`
  summary: `AuthBloc`'s `_passkeyAuthenticator` is `Future<void> Function()?` — success/failure is signalled only by return-vs-throw. When real FIDO2/WebAuthn is implemented, an authenticator that *returns* on a declined/aborted ceremony (rather than throwing) would mint an authenticated session. The contract should become explicit (e.g. `Future<bool>` or a result type) before a real authenticator is wired.
  evidence: step-04 edge-case lens on this spec. Pre-existing `void` signature; not exploitable today (no authenticator is wired), but a latent hazard for the FIDO epic.

- source_spec: `_bmad-output/implementation-artifacts/spec-passkey-signin-unavailable-when-simulator-off.md`
  summary: The `developerBuild` expression `kDebugMode || const bool.fromEnvironment('DEV_MODE', defaultValue: false)` is inlined in at least three places (`main.dart`'s `AuthBloc` wiring, `onboarding_wizard_page.dart`'s `_simulated` getter, and `settings_page.dart`). Consolidate into a single `developerBuild` helper (or a zero-arg `passkeySimulatorActive()`).
  evidence: step-04 blind-hunter lens. Pre-existing duplication (the `_simulated` getter predates this change); cheap to unify next time that area is touched.

- source_spec: `_bmad-output/implementation-artifacts/spec-passkey-simulator-toggle-on-login.md`
  summary: Now that the "Passkey Simulator" auth-bypass toggle is reachable pre-auth on the sign-in screen (not just the post-login Settings tab), the DEV_MODE build story needs a hardening pass — a warning treatment louder than the amber caption, an audit-trail entry when the flag is flipped, and an explicit decision on whether `--dart-define=DEV_MODE=true` release APKs should still ship to QA with a one-tap sign-in bypass on the first screen.
  evidence: step-04 blind-hunter lens. Pre-existing concern (the Settings-tab toggle already bypasses auth in DEV_MODE builds and has no audit trail); this change surfaces it earlier in the flow. Out of scope for a UI-placement story; the app has no audit-logging or analytics infrastructure today.

- source_spec: none (split from the boot-resolve intent, 2026-09-10)
  summary: Reorder the onboarding wizard to passkey-first (Create Passkey → Profile, with the Profile step skipped when a profile is already cached), and relocate the HIPAA §164.312 consent gate accordingly. Amends Epic 1 Stories 1.9 / 1.10 / 1.12 (currently `review`), whose ACs pin the order as Register+consent → Medical Profile → Passkey Enrollment and route onboarding *after* a passkey sign-in.
  evidence: User-requested boot/onboarding flow (2026-09-10). Split from Goal A because it is a wizard redesign that changes in-review epic stories and the `AppFlowBloc` step machine (linear `_steps` walk → conditional/branching). Needs `bmad-correct-course` on Stories 1.9/1.10/1.12 first, or an explicit renegotiation.

- source_spec: none (split from the boot-resolve intent, 2026-09-10)
  summary: Replace the "onboarding complete" boolean flag (Goal A) with a real "is a FIDO2 passkey present on THIS device" check via the platform credential store (iOS Keychain / Android Credential Manager, WebAuthn). This is what the user actually asked for ("check if passkey exists in device cache"); Goal A approximates it with a local flag because no real FIDO2 authenticator or credential store exists yet (`// TODO(FIDO)`).
  evidence: User-requested boot/onboarding flow (2026-09-10). Depends on the FIDO2 epic (no `webauthn`/`passkeys` package, no backend ceremony). Split from Goal A because Goal A must not block on FIDO.

- source_spec: none (split from the boot-resolve intent, 2026-09-10)
  summary: Security verification gate — when the device has no passkey/onboarding flag but an account/profile already exists server-side (reinstall, cleared credential), require identity verification before re-enrolling a passkey and reaching the dashboard. As-is, the flow lets anyone holding the device re-enroll against the existing account and read the patient's PHI.
  evidence: step-04-style review of the user-requested flow (2026-09-10). Depends on the onboarding reorder (Goal B) and the real device-passkey check (Goal C); latent PHI-access-takeover vector for a HIPAA app.

- source_spec: `_bmad-output/implementation-artifacts/spec-boot-resolve-skip-login-for-new-users.md`
  summary: With the "Sign in with Passkey" screen removed for fresh installs (Goal A), a fresh install now lands directly in the onboarding wizard — but in a build where the Passkey Simulator is off and real FIDO2 is unwired, the "Create Passkey" step (3/3) blocks and there is no logout / back-past-step-1 / sign-in fallback, so the app cannot reach `ready`. Goal A removes the front door before Goal B/C make the wizard completable. Also: wizard progress is not persisted (boot always resolves to `onboardingStep: register`), so a force-quit mid-wizard re-runs `registerUser()` / `enrollPasskey()` on the next launch. Both are closed by Goals B/C/D.
  evidence: step-04 blind-hunter + edge-case lenses on Goal A. Not a Goal-A regression in dev builds (simulator defaults on); a real gap for release / simulator-off builds, tracked with Goals B/C/D.
