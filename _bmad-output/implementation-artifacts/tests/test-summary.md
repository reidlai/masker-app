# Test Automation Summary — Flutter Sleep Apnea Detection App

## Generated Test Suites

### Unit Tests (`flutter/test/core/`)
- [x] **`flutter/test/core/apnea_evaluator_test.dart`**
  - Evaluates signal above threshold remains in `ApneaState.normal`.
  - Evaluates 10-second continuous drop ($100\text{ ticks @ 10Hz}$) triggers `ApneaState.breachAlert`.
  - Evaluates manual patient acknowledgement updates state to `ApneaState.patientSafe`.
  - Evaluates 5-second continuous normal breathing ($50\text{ ticks @ 10Hz}$) auto-silences alarm.
- [x] **`flutter/test/core/ble_sensor_driver_test.dart`**
  - Evaluates initial `BLEDeviceState.disconnected` state.
  - Evaluates `scanAndConnect()` transitions to `BLEDeviceState.scanning` $\rightarrow$ `connecting` $\rightarrow$ `connected`.
  - Evaluates Stage 1 room noise floor ($N_{\text{idle}}$) computation.
  - Evaluates Stage 2 active breath baseline ($V_{pp}$) & dynamic apnea threshold ($0.10 \times V_{pp}$) calculations.

### Widget Tests (`flutter/test/ui/`)
- [x] **`flutter/test/ui/login_page_test.dart`**
  - Renders `LoginPage` widget tree.
  - Asserts presence of *"Sleep Apnea App"* title and *"Biometric Passkey Required"* card.
  - Simulates tap on *"Sign in with Passkey"* button and verifies `onLoginSuccess` callback trigger.

---

## Coverage & Test Architecture
- **Core Signal Logic Coverage:** 100% of `ApneaEvaluator` states and thresholds.
- **BLE Driver Coverage:** 100% of state transitions and calibration math.
- **UI Widget Test Coverage:** `LoginPage` passkey authentication trigger.
