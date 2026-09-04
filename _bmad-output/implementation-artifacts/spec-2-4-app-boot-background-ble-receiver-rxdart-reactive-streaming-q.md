---
title: 'Epic 2 Story 2.4: App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue'
type: 'feature'
created: '2026-09-04'
status: 'done'
review_loop_iteration: 0
context:
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/epics.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Bio-signal streams must be ingested continuously from app boot in a low-power background receiver service and exposed through a single reactive `BehaviorSubject<double>` queue using RxDart, ensuring calibration stages and sleep monitoring consume bio-signal streams seamlessly from a unified `IBLESensorDriver` polymorphism regardless of physical BLE hardware vs simulator source.

**Approach:** Ensure `BleTelemetryService` and `BLESensorDriver` initialize background reactive `BehaviorSubject<double>` streams on app boot, provide a central reactive stream provider/factory in `flutter/lib/core/ble/ble_receiver_service.dart`, and add unit tests in `flutter/test/core/ble/ble_receiver_service_test.dart` verifying multi-subscriber streaming and RxDart queue behavior.

## Boundaries & Constraints

**Always:**
- Use `flutter/` root directory for code and test files.
- Enforce SOLID Dependency Inversion principle (`NFR-4.6`) with `IBLESensorDriver` polymorphism.
- Enforce `BehaviorSubject<double>` reactive stream `.add()` queueing with RxDart.

**Ask First:**
- Modifying OS-level native background service manifest configurations (Android `AndroidManifest.xml` / iOS `Info.plist`) beyond Dart-level services.

**Never:**
- Never force downstream listeners (`MeasurementPage`, `ApneaEvaluator`) to handle direct hardware vs simulator branching.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| App Boot Service Launch | Application initializes `BleReceiverService` | Starts background receiver and exposes `BehaviorSubject<double>` queue | Seed stream with default baseline |
| RxDart Stream Broadcast | Ingest packets from `IBLESensorDriver` | Pushes double telemetry values via `.add()` to all active subscribers | Re-open BehaviorSubject if closed |
| Multiple Downstream Listeners | `MeasurementPage` and `ApneaEvaluator` subscribe simultaneously | Both receive identical 10Hz bio-signal streams concurrently | Broadcast stream protection |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/ble/i_ble_sensor_driver.dart` -- Abstract interface defining `Stream<double> get thermalStream` and driver lifecycle methods.
- `flutter/lib/core/ble/ble_sensor_driver.dart` -- Physical BLE hardware driver implementing `IBLESensorDriver` with 10Hz thermal stream broadcast.
- `flutter/lib/core/ble/ble_telemetry_service.dart` -- Singleton telemetry service implementing `IBLESensorDriver` backed by RxDart `BehaviorSubject<double>`.
- `flutter/lib/core/ble/ble_receiver_service.dart` -- App-boot background BLE receiver service managing central `IBLESensorDriver` instance and reactive queue lifecycle.
- `flutter/test/core/ble/ble_receiver_service_test.dart` -- Unit tests for `BleReceiverService` verifying app-boot initialization, RxDart stream queueing, and driver polymorphism.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/ble/ble_receiver_service.dart` -- Create BleReceiverService -- Implement app-boot background BLE receiver service managing active `IBLESensorDriver` and exposing reactive `BehaviorSubject<double>` stream.
- [x] `flutter/test/core/ble/ble_receiver_service_test.dart` -- Create ble_receiver_service_test.dart -- Write unit tests for background receiver initialization, RxDart queueing, and driver polymorphism.

**Acceptance Criteria:**
- Given app completes boot sequence, when `BleReceiverService` initializes, then incoming BLE packets are pushed into `BehaviorSubject<double>` via `.add()`.
- Given multiple UI or background consumers subscribe to `thermalStream`, when telemetry packets arrive, then all subscribers receive identical bio-signal streams without signal loss or stream closed errors.

## Spec Change Log

## Design Notes

The `BleReceiverService` acts as a central app-level service (initialized during app boot in `main.dart` or service locator) that wraps an `IBLESensorDriver` (defaulting to `BleTelemetryService` or `BLESensorDriver`). It exposes `Stream<double> get stream => driver.thermalStream;` backed by RxDart `BehaviorSubject<double>`.

## Verification

**Commands:**
- `cd flutter && flutter test test/core/ble/ble_receiver_service_test.dart` -- expected: All tests pass cleanly with 0 failures.

## Suggested Review Order

**Background BLE Receiver Service & RxDart Stream Queue**

- App-boot background BLE receiver service with `BehaviorSubject<double>` queue and `IBLESensorDriver` polymorphism.
  [`ble_receiver_service.dart:1`](../../flutter/lib/core/ble/ble_receiver_service.dart#L1)

**Supporting Unit Tests**

- Unit tests for app-boot receiver initialization, RxDart stream queueing, multi-subscriber broadcasting, and driver switching (`NFR-4.6`).
  [`ble_receiver_service_test.dart:1`](../../flutter/test/core/ble/ble_receiver_service_test.dart#L1)

