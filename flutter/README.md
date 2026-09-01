# 🫁 Masker App — Nocturnal Sleep Apnea Detection & Alert System (Flutter Mobile App)

Welcome to the **Masker App** Flutter codebase. This mobile application provides real-time nocturnal sleep apnea monitoring, 2-stage thermal sensor calibration, sub-200ms Tier-1 local emergency alarm alerts, 0-FPS pitch black Night Mode (`#000000`), and morning AHI clinical summary reports with signed HL7 LOINC FHIR JSON export.

---

## 📋 Product Briefing

### Key Capabilities & User Experience
* **Passwordless Biometric Onboarding:** FIDO2 Passkey login interface (`LoginPage`) ensuring HIPAA-compliant biometric security.
* **BLE Sensor Discovery & Pairing:** BLE 4.0, 4.1, 4.2, and 5.0+ auto-discovery of D-BAND thermal bio-signal sensor (`0x180D` service / `0x2A37` characteristic @ 10Hz) with AES-128 link security.
* **2-Stage Thermal Calibration Wizard:** 
  - **Stage 1 (10s):** Room ambient thermal noise floor sampling ($N_{\text{idle}}$).
  - **Stage 2 (15s):** Active thermal breath baseline training ($V_{pp}$) establishing the dynamic AASM zero-airflow apnea threshold ($0.10 \times V_{pp}$).
* **Nocturnal Sleep Monitoring (0-FPS Night Mode):** Display lock using pitch black `#000000` surface with dim 1Hz heartbeat LED indicator to prevent circadian disruption and eliminate battery drain.
* **Real-time AASM Apnea Evaluator:** 100ms stream evaluation loop flagging continuous $\ge 90\%$ volumetric airflow drops lasting $\ge 10\text{s}$.
* **Tier-1 Local Emergency Alarm System:** Sub-200ms local mobile audio siren alert (75+ dB) & haptic vibration overlay (`MOB_TIER1_ALARM`) featuring a high-contrast `#FF3B30` flashing banner, 30s countdown ring, prominent $64\text{dp}$ *"I'M SAFE / I'M AWAKE"* button, and 5s auto-silence recovery upon breathing restoration.
* **Morning Sleep Summary & Respiration Waveforms:** AHI score ring (`92`), AHI severity badge (`Normal 3.2`), 60 FPS Skia GPU cubic-spline respiration line chart (`fl_chart`), 256-point FFT spectral peaks, metrics grid, and signed FHIR JSON / PDF doctor report export action.

---

## 🚀 Quick Start Guide

### Prerequisites
- **Flutter SDK:** $\ge 3.19.0$
- **Dart SDK:** $\ge 3.3.0$
- **Target OS:** Android / iOS / Desktop (Flutter Web compatible)

### 1. Install Dependencies
Always execute Flutter CLI commands from the `flutter/` root folder:

```bash
cd flutter
flutter pub get
```

### 2. Run Application Locally
Launch the application on an attached emulator, simulator, or connected device:

```bash
flutter run
```

### 3. Run Automated Unit & Widget Test Suites
Execute the complete test suite including core signal evaluators, BLE state machines, FHIR report serialization mocks/stubs, and UI widget suites:

```bash
flutter test
```

---

## 🛡️ DevSecOps Architecture & Security Gates

The Masker App enforces strict DevSecOps automation pipeline security gates before any release artifact is built or deployed (aligned with Section 5.3 of [`ARCHITECTURE-SPINE.md`](file:///c:/Users/reidl/GitLocal/masker-app/_bmad-output/architecture/ARCHITECTURE-SPINE.md)):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       DEVSECOPS CI/CD PIPELINE                              │
├───────────────┬────────────────┬─────────────────┬──────────────────────────┤
│ 1. SAST GATE  │ 2. SECRETS     │ 3. QA TEST      │ 4. BUILD & DEPLOY        │
│ flutter       │ git leaks &    │ flutter test    │ Signed APK/IPA &         │
│ analyze       │ PHI audit      │ --coverage      │ GCP Cloud Run Sync       │
└───────────────┴────────────────┴─────────────────┴──────────────────────────┘
```

### Security Pipeline Commands

#### Step 1: Static Application Security Testing (SAST)
Run strict static code analysis to enforce zero lint warnings, type safety, and memory management invariants:

```bash
cd flutter
flutter analyze
```

#### Step 2: Dependency Security & Vulnerability Audit
Audit project dependencies for known CVE vulnerabilities and package integrity:

```bash
cd flutter
flutter pub deps
```

#### Step 3: Test Coverage & Quality Gate
Run automated unit and widget tests with code coverage report generation:

```bash
cd flutter
flutter test --coverage
```

#### Step 4: Secret Scanning & HIPAA PHI Protection Audit
Verify no unencrypted Protected Health Information (PHI) or hardcoded credentials exist in source code or memory loggers:

```bash
git diff HEAD~1 HEAD | grep -iE "(password|secret|api_key|private_key|token)"
```

---

## 📁 Repository Directory Map

```
flutter/
  ├── README.md                                # Product Briefing, Quick Start & DevSecOps Guide
  ├── pubspec.yaml                             # Flutter Dependencies & Assets Configuration
  ├── lib/
  │   ├── main.dart                            # Application Entry Point (MaskerApp Root)
  │   ├── core/
  │   │   ├── ble/ble_sensor_driver.dart       # BLE 4.0/5.0+ Driver, AES-128, 10Hz Stream & Calibration Math
  │   │   ├── monitoring/apnea_evaluator.dart  # 100ms AASM Breach Evaluator, 30s Countdown & Auto-Recovery
  │   │   └── theme/app_theme.dart             # Dark Glassmorphism Design Tokens (#0F172A, #10B981)
  │   └── ui/
  │       ├── atoms/app_button.dart            # Accessible Touch Targets & Emergency 64dp Buttons
  │       ├── organisms/
  │       │   ├── thermal_calibration_wizard.dart  # Stage 1 & Stage 2 Sensor Calibration Wizard Widget
  │       │   ├── apnea_alert_overlay.dart     # MOB_TIER1_ALARM Emergency Overlay (#FF3B30 Banner)
  │       │   └── live_waveform_chart.dart     # 60 FPS Skia GPU fl_chart Line Chart with Red Apnea Markers
  │       └── pages/
  │           ├── login_page.dart              # FIDO2 Passkey Biometric Login UI
  │           ├── profile_page.dart            # David's Medical Profile & Dynamic BMI Computation
  │           ├── measurement_page.dart        # BLE Status, Calibration & 0-FPS Night Mode Monitor
  │           ├── summary_screen_page.dart    # Morning Sleep Summary Dashboard & FHIR Report Export
  │           └── main_container_page.dart    # 4-Tab Bottom Navigation Container Widget
  └── test/
      ├── core/
      │   ├── apnea_evaluator_test.dart        # Unit Test for 100ms Breach Evaluation & Auto-Recovery
      │   ├── ble_sensor_driver_test.dart      # Unit Test for BLE Connection & Calibration Math
      │   └── fhir_report_exporter_test.dart   # Serverless Mock/Stub Test for HL7 LOINC FHIR JSON Export
      └── ui/
          ├── login_page_test.dart             # Widget Test for Passkey Login UI
          ├── summary_screen_page_test.dart    # Widget Test for Morning Summary Dashboard & Export Action
          └── profile_page_test.dart           # Widget Test for Medical Baseline Inputs & Dynamic BMI
```
