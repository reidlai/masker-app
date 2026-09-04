# Epic 2 Context: BLE Bluetooth Sensor Discovery, Pairing & Thermal Calibration

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable high-risk sleep apnea patients to turn on their D-BAND thermal sensor array, automatically discover and pair via encrypted BLE, execute 2-stage thermal calibration (ambient room noise $N_{\text{idle}}$ and active breath training $V_{pp}$), convert thermal deviation into volumetric airflow rates, enforce wear verification guardrails, and continuously publish bio-signals through a unified RxDart background stream queue.

## Stories

- Story 2.1: Encrypted BLE Sensor Auto-Discovery & Cloud Device Binding
- Story 2.2: 2-Stage Thermal Sensor Baseline Calibration
- Story 2.3: Airflow Volumetric Transformation & Wear Guardrails
- Story 2.4: App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue

## Requirements & Constraints

- **BLE Discovery & Pairing:** Automatically scan for D-BAND (`0x180D` service / `0x2A37` characteristic @ 10Hz) over BLE 4.0–5.0+ with AES-128 link security.
- **Cloud Device Binding:** Execute `POST /api/v1/devices/bind` with encrypted payload (`user_profile_id`, `device_hardware_id`, `ble_mac_address`, `binding_timestamp`). Queue locally if offline.
- **2-Stage Thermal Calibration:** 
  - Stage 1 (5–10s idle room sampling) computes noise floor $N_{\text{idle}}$.
  - Stage 2 (10–20s active breathing sampling) computes peak-to-peak volume $V_{pp}$ and sets zero-airflow apnea threshold to $0.10 \times V_{pp}$.
- **Wear Verification Guardrail:** Block monitoring initiation if active delta $\Delta V < 1.5 \times N_{\text{idle}}$.
- **App-Boot Background Streaming Queue:** On app launch, start the background BLE receiver (Android Foreground Service / iOS `bluetooth-central`) and stream packets into an RxDart `BehaviorSubject<double>` queue.

## Technical Decisions

- **SOLID Dependency Inversion (`NFR-4.6`):** All physical hardware drivers (`BLESensorDriver`) and background telemetry simulators (`BleTelemetryService`) implement the abstract `IBLESensorDriver` interface.
- **Reactive Stream Architecture:** Downstream BLoC logic (`BleBloc`), evaluators (`ApneaEvaluator`), and UI pages (`MeasurementPage`) consume bio-signals exclusively via constructor dependency injection from `BehaviorSubject<double>`.
- **State Management:** Unidirectional Flutter BLoC state management using RxDart operators (`BehaviorSubject`, `debounceTime`, `distinctUntilChanged`, `switchMap`).

## UX & Interaction Patterns

- **Calibration Wizard (`UX-DR4`):** Interactive 2-stage wizard displaying 10s circular progress ring fill and live thermal waveform canvas (`fl_chart` Skia GPU line graph).
