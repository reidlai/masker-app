# Epic 2 Context: BLE Sensor Discovery, Pairing & IDLE Band Calibration

<!-- Compiled from planning artifacts (PRD v2.5.0, ARCHITECTURE-SPINE.md v21.0.0, EXPERIENCE.md/DESIGN.md v1.3.0, epics.md). Edit freely. Regenerate with compile-epic-context if planning docs change. -->

> **Renumbering note (2026-09-06):** the epic breakdown was rebuilt this round. The old specs on disk use the *previous* numbering; this epic now maps as:
> - old Story 2.5 (BLE permission priming) → **new 2.1** — shipped as `spec-2-5-bluetooth-background-access-priming-permission-recovery.md` (`done`)
> - old Story 2.4 (app-boot receiver) → **new 2.2** — shipped as `spec-2-4-app-boot-background-ble-receiver-rxdart-reactive-streaming-q.md` (`done`)
> - old Story 2.1 (BLE discovery + pairing + **2-stage thermal calibration**) → split into **new 2.3** (discovery/pairing/binding) + **new 2.5** (calibration) — shipped as `spec-2-1-ble-sensor-discovery-calibration.md` (`done`), whose *calibration half* is now superseded and is the rework target for new Story 2.5.
> - **new 2.4** (offline binding queue) is new work.

## Goal

Patients must reliably connect their D-BAND thermal sensor and establish a per-session detection reference before any monitoring can begin. This epic covers the full pre-monitoring journey: priming the patient for the OS Bluetooth permission dialog (with recovery if denied), auto-discovering and pairing the D-BAND over encrypted BLE, binding the device to the cloud (with an offline retry queue), running a **single-stage IDLE Band calibration** (a worn ~10-second idle sample that learns the resting signal's running min/max, followed by a wear check), and starting a boot-time background BLE receiver that funnels every incoming sample — physical or simulated — into one reactive stream every later consumer relies on. Getting this right matters because every downstream feature (Epic 3's overnight monitoring, Epic 4's morning analytics) depends on a valid IDLE Band and an uninterrupted bio-signal feed; a bad pairing or a band learned from a mis-worn sensor silently produces false alarms or missed apnea events.

## Stories

- Story 2.1: Bluetooth Background-Access Priming & Permission Recovery *(shipped, old spec-2-5)*
- Story 2.2: App-Boot BLE Receiver Service & Unified RxDart Queue *(shipped, old spec-2-4)*
- Story 2.3: Encrypted BLE Discovery, Pairing & Cloud Device Binding *(shipped in part, old spec-2-1)*
- Story 2.4: Offline Device-Binding Queue
- Story 2.5: IDLE Band Calibration & Wear Check *(rework of old spec-2-1's calibration half)*

## Requirements & Constraints

- The app auto-scans, identifies, and pairs with the D-BAND over BLE 4.0/4.1/4.2/5.0+ using AES-128 link security (GATT service `0x180D`, characteristic `0x2A37`, 10 Hz sample rate).
- On successful pairing the app calls the Cloud Device Binding API with an encrypted payload (`user_profile_id`, `device_hardware_id`, `ble_mac_address`, `binding_timestamp`); when offline, the payload is queued in a local encrypted buffer and retried on network restoration (a duplicate bind must be idempotent). Pairing is not blocked on the bind call.
- **Calibration is a single worn stage.** With the D-BAND worn and the patient still, the app samples the raw bio-signal for ~10 s (`[ASSUMPTION]` window, tunable 5–30 s) and tracks the **running minimum and maximum** of the stream. Those two values are the session **IDLE Band** — `lower_bound` and `upper_bound`. Each sample only widens the band within the window; it is never narrowed and no margin is applied. There is **no** active-breath training step, **no** thermal-to-volumetric (L/s) transform, **no** `V_pp` peak-to-peak baseline, and **no** `0.10 × V_pp` threshold. The client works in raw signal units end to end.
- A **valid breath** is a cycle in which the raw signal rises to/above `upper_bound` (inhale) **and** falls to/below `lower_bound` (exhale). A **"stop-breathing" sample** is any sample where the signal lies within `[lower_bound, upper_bound]`. (Epic 3 consumes these definitions for apnea evaluation; this epic only produces the band and proves excursions are detectable.)
- **Wear check (replaces the old `ΔV < 1.5 × N_idle` guardrail):** immediately after the idle sample, the patient breathes normally and "Start Sleep Monitoring" stays blocked until the app observes **≥ 2 valid IDLE-Band breath-excursion cycles** within a bounded window (~15 s `[ASSUMPTION]`). On failure it surfaces `"Sensor not detecting breathing — check the fit."` with a retry — never silently retried, never auto-advanced.
- The IDLE Band is persisted per session as `idle_band_lower` / `idle_band_upper` on `SleepSession` (Level 1 PHI, AES-256 at rest), written at calibration, and reused on later sessions only until stale/invalid (re-run on the first session or when the stored band is stale).
- Calibration and the wear check consume the **one** unified bio-signal stream (Story 2.2 / AD-12) — no separate BLE subscription, no second queue.
- BLE auto-reconnects within 3.0 s of signal loss.
- Air-freight/customs constraints on the hardware/radio (UN 38.3, <2.7 Wh cap, ISO 10993, FCC/CE BLE cert) are informational unless this epic touches device metadata.

## Technical Decisions

- **`AD-04` (IDLE Band Calibration & Signal Model)** is the binding invariant: it fixes band construction (running min/max), the valid-breath predicate (inhale ≥ upper AND exhale ≤ lower), the stop-breathing predicate (in-band), raw signal units, and the ban on any L/s transform or `V_pp` threshold. The calibration wizard, the on-device evaluator, the wear check, the developer simulator, and the waveform renderer must all agree with it.
- **`AD-05`** is the wear check (≥ 2 valid band-excursion cycles).
- **`AD-12` / `AD-11`** — a single process-wide `BehaviorSubject<double>` (`ValueStream<double>`) started at app boot by the BLE background receiver service, fed by exactly one `IBLESensorDriver` bound via constructor DI. Physical driver (`FlutterBlueSensorDriver`), mock (`BLESensorDriver`), and simulator (`BleTelemetryService`) are interchangeable behind `IBLESensorDriver`; the driver exposes `signalStream`. Consumers subscribe to the queue, never to a driver or GATT channel directly. Queue identity is stable across a driver swap; the queue survives `EndSession`.
- **`AD-15`** — `SleepSession` (1:1, Level 1 PHI) is the source of truth for per-session data including the IDLE Band; the device keeps a local last-N (N ≥ 7) `SessionSummary` cache for the dashboard.
- Component architecture: `flutter_shadcn` / `shadcn_ui` atoms → molecules → logic organisms → page templates. State: unidirectional BLoC + RxDart (`BehaviorSubject`, `debounceTime`, `distinctUntilChanged`, `switchMap`, `catchError`); UI-facing BLoCs decimate the 10 Hz signal to ≤ 5 FPS.
- Encryption: AES-128 BLE link, TLS 1.3 in transit with cert pinning, AES-256 SQLCipher at rest.
- The developer simulator scenario chips are `IDLE Band Sample`, `Normal 16 bpm`, `In-Band (no excursion) >10s`, `Recovery 5s` — these feed `BleTelemetryService` and must exercise the calibration + wear-check + evaluator paths without hardware.

## UX & Interaction Patterns

- **`MOB_CALIBRATION`** — one screen, `IdleBandCalibrationWizardOrganism`, two sequential steps:
  1. **Idle sample** (`State_CalibratingIdleBand`) — copy: *"Put on your D-BAND, sit still, and breathe gently for 10 seconds."* Circular progress ring counts the ~10 s window; a live trace shows the band forming (running `lower_bound` / `upper_bound` readout).
  2. **Wear check** (`State_WearCheck`) — copy: *"Now take a few normal breaths so we can check the fit."* The trace shows crossings of both band lines. On ≥ 2 valid cycles: *"Calibration Complete — Ready for Sleep ✓"* and the primary action becomes **"Start Sleep Monitoring"**. On failure: toast *"Sensor not detecting breathing — check the fit."* + a **Retry** button; the gate is held, not auto-advanced.
- `CalibrationStepHeader` shows a "STEP 1 OF 2" pill, step title, instruction body, and an animated progress bar.
- No litres-per-second axis anywhere. The waveform is the raw signal with the two IDLE Band bounds drawn as horizontal reference lines.
- Nav model: `MOB_CALIBRATION` is part of the first-run onboarding chain (`… → MOB_DEVICE_PAIRING → MOB_CALIBRATION → MOB_SLEEP_MONITOR`); it is not a tab root and carries no bottom nav.
- Voice & tone: calibration instructions are unambiguous and direct; the wear-check failure toast is a plain factual instruction, not an alarm.

## Cross-Story Dependencies

- **Story 2.5 depends on Story 2.2** (the unified queue must exist and be streaming) and **Story 2.3** (a paired device / a live `signalStream`). Both are shipped.
- **Story 2.5 supersedes the calibration half of old `spec-2-1`** (`CalibrationBloc`, the calibration page/wizard, any `N_idle` / `V_pp` / `0.10 × V_pp` / thermal-to-volumetric logic, and the old `ΔV < 1.5 × N_idle` wear guardrail). The rework rips those out and replaces them with the IDLE Band model. The BLE-discovery/pairing half of old `spec-2-1` stays.
- **Epic 3** (Story 3.3 evaluator, Story 3.4 auto-silence) consumes the IDLE Band and the valid-breath / stop-breathing predicates this epic defines. Keep those predicate helpers reusable, not private to the wizard.
- `HealthBaseline` loses `idle_noise_floor` / `vpp_breath_baseline`; `SleepSession` gains `idle_band_lower` / `idle_band_upper`. Any migration or model change to those two entities is in scope for Story 2.5.
