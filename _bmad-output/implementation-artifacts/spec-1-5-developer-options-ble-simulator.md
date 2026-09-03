# Story 1.5: Developer Options Page & BLE Signal Simulator Controls

## Overview
Interactive `DeveloperOptionsPage` and `BleSimulatorOrganism` component exposed when `DEV_MODE=true` is enabled, providing simulation triggers for 2-stage calibration lifecycles ($N_{\text{idle}}$ & $V_{pp}$) and nocturnal sleep cycles (normal respiration, apnea stop alerts, recovery signals).

## User Story
**As a** developer or tester,  
**I want** to navigate to a dedicated `DeveloperOptionsPage` when Developer Mode (`DEV_MODE=true`) is enabled,  
**So that** I can trigger interactive BLE signal simulation controls to test the calibration lifecycle and nocturnal sleep apnea alarm cycles without requiring physical hardware.

## Acceptance Criteria
- **Given** Developer Mode (`DEV_MODE=true`) is enabled,
- **When** I view `SettingsPage` under the Advanced section (`SettingsGroupCardOrganism`),
- **Then** the "Developer" menu row (`SettingsMenuRow`) is displayed.
- **And** tapping "Developer" navigates to `DeveloperOptionsPage`.
- **And** `DeveloperOptionsPage` renders `BleSimulatorOrganism` with controls for:
  1. **Calibration Lifecycle Simulation**: Triggering ambient idle noise ($N_{\text{idle}}$) and active breathing baseline ($V_{pp}$).
  2. **Sleep Cycle Simulation**: Triggering normal 16 bpm respiration streams, $\ge 10\text{s}$ apnea breathing stop alerts, and 5s patient recovery signals.

## Implementation Summary
- Files created:
  - `flutter/lib/ui/organisms/ble_simulator_organism.dart`
  - `flutter/lib/ui/pages/developer_options_page.dart`
  - `flutter/test/ui/ble_simulator_organism_test.dart`
  - `flutter/test/ui/developer_options_page_test.dart`
- Status: Completed (done)
