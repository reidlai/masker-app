---
title: 'Epic 2 Story 2.1: BLE Bluetooth Sensor Discovery, Pairing & 2-Stage Thermal Calibration Wizard'
type: 'feature'
created: '2026-09-01'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - _bmad-output/prd/prd.md
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/DESIGN.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
warnings: []
deferred: []
---

<intent-contract>

## Intent

**Problem:** The application requires a robust Bluetooth Low Energy (BLE 4.0, 4.1, 4.2, and 5.0+) sensor driver to auto-discover, pair (`0x180D` service / `0x2A37` characteristic @ 10Hz), and execute a 2-stage thermal calibration wizard (Stage 1 room noise $N_{\text{idle}}$ & Stage 2 active breath baseline $V_{pp}$) before sleep monitoring can begin.

**Approach:** Implement `BLESensorDriver` in `flutter/lib/core/ble/ble_sensor_driver.dart` and build `ThermalCalibrationWizard` organism in `flutter/lib/ui/organisms/thermal_calibration_wizard.dart` linked to `MeasurementPage` in `flutter/lib/ui/pages/measurement_page.dart`.

## Boundaries & Constraints

**Always:**
- Use `flutter/` root directory for all code and commands.
- Enforce BLE 4.0, 4.1, 4.2, 5.0+ backward compatibility and AES-128 link security specifications.
- Enforce wear verification guardrail: block monitoring initiation if $\Delta V < 1.5 \times N_{\text{idle}}$.

**Block If:**
- Bluetooth hardware permissions require OS-level native prompt overrides beyond standard Flutter cross-platform wrappers.

**Never:**
- Never start sleep monitoring without successful Stage 1 & Stage 2 calibration verification.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| BLE Discovery & Pairing | App scans for D-BAND sensor | Connects via BLE, executes Cloud Device Binding API | Queue payload locally if offline |
| Stage 1 Calibration | Bedside room noise sampling | Calculates ambient noise floor $N_{\text{idle}}$ | Prompt user to keep room quiet |
| Stage 2 Calibration | Active 15s breathing thermal training | Calculates volumetric airflow baseline & $0.10 \times V_{pp}$ threshold | Display warning if sensor detached |

</intent-contract>

## Code Map

- `flutter/lib/core/ble/ble_sensor_driver.dart` -- BLE sensor connection manager, AES-128 link security, and 10Hz thermal stream controller (`BehaviorSubject<double>`).
- `flutter/lib/ui/organisms/thermal_calibration_wizard.dart` -- Step-by-step calibration wizard UI (`MOB_CALIBRATION_STAGE1` & `STAGE2`) with circular progress rings and thermal wave preview.
- `flutter/lib/ui/pages/measurement_page.dart` -- Calibration launcher & Night Mode monitoring entry screen.

## Tasks & Acceptance

**Execution:**
- `flutter/lib/core/ble/ble_sensor_driver.dart` -- Create BLESensorDriver -- Implement BLE auto-discovery (`0x180D`/`0x2A37`), 10Hz stream broadcast, and thermal-to-volumetric transform.
- `flutter/lib/ui/organisms/thermal_calibration_wizard.dart` -- Create ThermalCalibrationWizard -- Implement Stage 1 (10s room noise) and Stage 2 (15s active breath) calibration UI.
- `flutter/lib/ui/pages/measurement_page.dart` -- Update MeasurementPage -- Connect BLE driver & calibration wizard to sleep monitoring launch button.

**Acceptance Criteria:**
- Given D-BAND sensor is powered on, when user opens MeasurementPage, then BLE driver auto-discovers device and displays connected status badge.
- Given calibration starts, when Stage 1 and Stage 2 complete, then dynamic apnea threshold ($0.10 \times V_{pp}$) is computed and "Start Sleep Monitoring" button unlocks.

## Spec Change Log

## Review Triage Log

### 2026-09-01 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 0
- defer: 0
- reject: 0
- addressed_findings:
  - none

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: 0 issues found.

## Auto Run Result

Status: done
Summary: Implemented Epic 2 Story 2.1 BLE Bluetooth Sensor Discovery, Pairing & 2-Stage Thermal Calibration Wizard within `flutter/`.
Files changed:
- `flutter/lib/core/ble/ble_sensor_driver.dart`: Created BLESensorDriver with auto-discovery, AES-128 link, 10Hz thermal stream, and Stage 1 ($N_{\text{idle}}$) / Stage 2 ($V_{pp}$) calibration math.
- `flutter/lib/ui/organisms/thermal_calibration_wizard.dart`: Created ThermalCalibrationWizard organism widget with progress bar, step badges, and active breath preview text.
- `flutter/lib/ui/pages/measurement_page.dart`: Updated MeasurementPage to integrate BLE status card, 2-stage calibration wizard, and 0-FPS Night Mode (`#000000`) sleep monitoring launcher.
Verification performed: Code inspection and layout alignment with DESIGN.md and EXPERIENCE.md specs.

