# Epic 2 Context: BLE Bluetooth Sensor Discovery, Pairing & Thermal Calibration

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Patients must reliably connect their D-BAND thermal sensor and establish a personalized apnea-detection baseline before any monitoring can begin. This epic covers the full pre-monitoring journey: priming the patient for the OS Bluetooth permission dialog (with recovery if denied), auto-discovering and pairing the D-BAND over encrypted BLE, running a 2-stage thermal calibration (idle room noise, then active breathing) to compute a personalized zero-airflow apnea threshold, verifying the sensor is actually worn before allowing recording to start, and starting a boot-time background BLE receiver that funnels all incoming samples — physical or simulated — into one reactive stream every later consumer relies on. Getting this right matters because every downstream feature (Epic 3's overnight monitoring, Epic 4's morning analytics) depends on a correctly calibrated threshold and an uninterrupted bio-signal feed; a bad pairing or calibration silently produces false alarms or missed apnea events.

## Stories

- Story 2.1: Encrypted BLE Sensor Auto-Discovery & Cloud Device Binding
- Story 2.2: 2-Stage Thermal Sensor Baseline Calibration
- Story 2.3: Airflow Volumetric Transformation & Wear Guardrails
- Story 2.4: App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue
- Story 2.5: Bluetooth Background-Access Priming & Permission Recovery

## Requirements & Constraints

- The app must automatically scan for, identify, and pair with the D-BAND sensor over BLE 4.0/4.1/4.2/5.0+ using AES-128 link security (GATT service `0x180D`, characteristic `0x2A37`, 10Hz sample rate).
- On successful pairing, the app must call the Cloud Device Binding API with an encrypted payload (`user_profile_id`, `device_hardware_id`, `ble_mac_address`, `binding_timestamp`); if offline, the binding payload must be queued locally in an encrypted buffer and retried on network restoration.
- Calibration is a mandatory 2-stage flow: Stage 1 samples 5–10s of idle ambient thermal noise to compute a noise floor ($N_{idle}$); Stage 2 samples 10–20s of active breathing to compute inhale/exhale thermal deviation and derive a personalized peak-to-peak volumetric baseline ($V_{pp}$, clinically centered at 5.0 L/s, normal range 4.0–6.0 L/s).
- Thermal deviation must be transformed into volumetric airflow, and the session's zero-airflow apnea threshold must be dynamically set to $0.10 \times V_{pp}$ (initialized at 0.5 L/s).
- Sleep recording must be blocked if active breathing signal $\Delta V < 1.5 \times N_{idle}$ — this is the wear-verification guardrail, and the failure must be surfaced to the patient (not silently retried).
- BLE must auto-reconnect within 3.0 seconds of signal loss.
- BLE sensor hardware and BLE 4.0/4.1/4.2/5.0+ radio must meet air-freight/customs constraints: UN 38.3 battery cert, <2.7 Wh battery cap, ISO 10993 biocompatibility, FCC/CE BLE certification — relevant if this epic's work touches hardware-facing configuration or device metadata, otherwise informational only.
- All BLE driver implementations (physical, mock, simulator) must be interchangeable behind one abstraction with no consumer-side special-casing (see Technical Decisions).
- On app launch, a background BLE receiver must start automatically (Android Foreground Service / iOS `bluetooth-central`) and push every incoming sample — from real hardware or the developer simulator — into one reactive stream that Stage-1, Stage-2, and the 8+ hour monitoring loop all read from without opening separate connections.

## Technical Decisions

- **`IBLESensorDriver` polymorphism (AD-11):** `BLESensorDriver` (mock), `FlutterBlueSensorDriver` (physical hardware), and `BleTelemetryService`/simulator equivalent must all implement one abstract interface. `ApneaEvaluator`, `BleBloc`, and `MeasurementPage` depend only on that interface, injected via constructor DI — never instantiate a concrete driver directly.
- **App-boot unified reactive queue (AD-12):** Exactly one `IBLESensorDriver` is bound at bootstrap (`main()`, before the first route pushes). Every inbound sample (physical GATT notification or simulator tick) is pushed via RxDart `.add()` into a single process-wide, seeded `BehaviorSubject<double>` (a `ValueStream<double>`) exposed as `thermalStream`/`signalStream`. Calibration Stage 1, Stage 2, and nocturnal monitoring all subscribe to this same stream — none may open a second BLE subscription or queue. The queue's identity is stable across a driver swap. The receiver service and queue start at boot and persist for the process lifetime; `EndSession` only calls `stopTelemetryLogging()`, it does not tear down the receiver or queue. The physical radio link itself (`scanAndConnect`) may be established lazily rather than at boot, to preserve the <8% / 8h battery budget (AD-06).
- **OS background-execution grants:** Android needs `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE` (API 34+), `POST_NOTIFICATIONS` (API 33+), and `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` (API 31+), with `foregroundServiceType="connectedDevice|dataSync"`; the `BLUETOOTH_SCAN` manifest declaration must carry the `neverForLocation` flag so the OS dialog doesn't fold in unrelated location-permission language. iOS needs `UIBackgroundModes = bluetooth-central` plus `NSBluetoothAlwaysUsageDescription`, with state-preservation/restoration keyed to a single central manager instance (no background scanning for unbound devices — only reconnect-on-advertisement for the already-bound D-BAND).
- **Simulator parity (AD-08):** In `DEV_MODE`, the DI-bound driver is the simulator, which needs no OS background grant — it feeds the same unified queue via an in-process `Timer`, so calibration/monitoring code paths are identical between production and simulated runs.
- **Encryption (AD-09):** BLE link uses AES-128; device binding and any network calls use HTTPS/TLS 1.3.
- **Wear guardrail (AD-05) / calibration (AD-04):** These are architecture-level invariants, not just FRs — the $1.5\times N_{idle}$ block and the 2-stage $N_{idle}$/$V_{pp}$ sequence must be enforced exactly as specified, since Epic 3's apnea detection accuracy depends on it.
- **Battery budget interaction:** The always-resident receiver service is signal-plumbing only (no FFT, no rendering) — FFT/detection work stays on separate isolates, preserving the <8% / 8h Night Mode battery budget that Epic 3 depends on.

## UX & Interaction Patterns

- Screen flow: `MOB_BLE_PERMISSION_PRIMER` (first run only) → `MOB_DEVICE_PAIRING` → `MOB_CALIBRATION_STAGE1` → `MOB_CALIBRATION_STAGE2` → sleep monitor.
- `MOB_BLE_PERMISSION_PRIMER` is a single-path screen (no skip/decline) with reassuring rationale copy and one primary CTA ("Allow Bluetooth Access"); it hands off to the native OS dialogs (Android: sequential `BLUETOOTH_SCAN` then `BLUETOOTH_CONNECT`; iOS: the `bluetooth-central` disclosure). It appears once, gated on permission state at boot, not a "seen it" flag — a later revocation re-triggers it.
- If a prior denial means the OS won't reissue its own dialog (iOS one-shot behavior, Android "Don't ask again"), the CTA must route straight to an "Open Settings" deep-link instead of re-tapping a dead dialog.
- On denial or partial grant (Android: one of `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` granted, the other denied), `MOB_DEVICE_PAIRING` renders a blocked state naming the missing permission, with an "Open Settings" CTA in place of scan UI, rather than a broken/stuck pairing screen.
- Two persistent, mutually-exclusive OS notifications confirm protection state (never inferred from absence): `BleReceiverForegroundNotification` ("Sleep Monitoring Ready — D-BAND connection active, you're covered tonight") when the receiver is running, and `BleNotProtectedNotification` ("Bluetooth Permission Needed — Sleep monitoring can't start until Bluetooth access is granted. Tap to fix.") when it isn't. Neither notification may initiate sound, heads-up interruption, or auto-open — only user-initiated tap-to-open.
- During active monitoring (Night Mode, 0-FPS black screen), the screen's root semantics node must carry a persistent accessible label ("Sleep monitoring active — D-BAND connected") so a screen-reader user gets confirmation without backgrounding the app.
- `ThermalCalibrationWizardOrganism` guides Stage 1/Stage 2 and shows a warning toast ("Sensor not detected — Please attach D-BAND and retry") when the wear guardrail blocks progression.
- The primer's CTA must meet the ≥48dp touch target minimum, and initial accessibility focus is set programmatically to the rationale text (not left to tree order) so VoiceOver/TalkBack users hear the rationale before the CTA regardless of where they first touch.

## Cross-Story Dependencies

- Story 2.5 (permission priming) must complete — full grant — before Story 2.4's Foreground Service is eligible to start, since Android 12+ requires `BLUETOOTH_CONNECT` already granted for a `connectedDevice`-type foreground service. Story 2.4 runs on every boot thereafter; Story 2.5 runs at most once (unless permission is later revoked).
- Story 2.2 (calibration) and Story 2.3 (wear guardrail) both subscribe to the same unified `BehaviorSubject<double>` queue that Story 2.4 establishes at boot — they must not open their own BLE subscriptions.
- Epic 1's `DeveloperOptionsPage`/`BleSimulatorOrganism` (Story 1.5) is the source of simulated ticks that Story 2.4's receiver ingests in `DEV_MODE`; production and simulated paths must stay behaviorally identical because both implement `IBLESensorDriver`.
- Epic 3 (nocturnal monitoring) consumes this epic's calibrated threshold and continues reading from the same unified queue Story 2.4 establishes — it does not open a new connection or recalibrate.
