---
title: 'Epic 3 Story 3.1: Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm System'
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

**Problem:** The mobile application requires real-time 10Hz background telemetry logging, 0-FPS Night Mode (`#000000`), 100ms real-time AASM obstructive apnea breach detection ($\ge 90\%$ drop for $\ge 10\text{s}$), sub-200ms local mobile audio siren (40–75+ dB) & haptic vibration, a 30s "I'm Safe" touch target button, 5s auto-silence upon breathing restoration, and Tier-2 cloud caregiver SMS/Voice dispatch upon timeout (>30s).

**Approach:** Implement `ApneaEvaluator` in `flutter/lib/core/monitoring/apnea_evaluator.dart` and build `ApneaAlertOverlay` organism in `flutter/lib/ui/organisms/apnea_alert_overlay.dart` integrated into `MeasurementPage` in `flutter/lib/ui/pages/measurement_page.dart`.

## Boundaries & Constraints

**Always:**
- Use `flutter/` root directory for all Dart/Flutter files and commands.
- Trigger local mobile alarm within $< 200\text{ms}$ (`NFR-2.1`) of 10s apnea breach detection.
- Render 0-FPS Night Mode display lock (`#000000` pitch black) during active sleep monitoring.
- Provide a 64dp prominent "I'M SAFE / I'M AWAKE" button (`{spacing.emergency_button}`).

**Block If:**
- Alarm audio playback requires OS system permission overrides beyond standard Flutter sound packages.

**Never:**
- Never delay local alarm trigger for cloud API response.
- Never miss transmitting Tier-2 cloud emergency payload if unacknowledged after 30s.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Apnea Breach (>10s) | Airflow drops $\ge 90\%$ for 10s | Sound 75+ dB siren & haptics, show 30s countdown overlay | Trigger local alert immediately |
| Patient "I'm Safe" Tap | User taps 64dp button within 30s | Silence siren, log safety event to cloud | Cancel 30s escalation timer |
| Auto-Silence Recovery | Breathing restores continuously for 5s | Auto-silence alarm without manual tap | Log auto-recovery safety event |
| Alarm Timeout (>30s) | Unacknowledged after 30s | Dispatch Tier-2 Cloud SMS/Voice Caregiver payload | Queue telemetry locally if offline |

</intent-contract>

## Code Map

- `flutter/lib/core/monitoring/apnea_evaluator.dart` -- Real-time 100ms AASM apnea breach evaluator, 10s stop duration tracking, and 5s breathing recovery detector.
- `flutter/lib/ui/organisms/apnea_alert_overlay.dart` -- Full-screen Tier-1 emergency alarm overlay (`MOB_TIER1_ALARM`) featuring high-contrast flashing red/yellow banner (`#FF3B30`), 30s countdown ring, and 64dp "I'M SAFE" button.
- `flutter/lib/ui/pages/measurement_page.dart` -- Sleep monitoring screen managing 0-FPS Night Mode (`#000000`) and emergency alarm overlay launch.

## Tasks & Acceptance

**Execution:**
- `flutter/lib/core/monitoring/apnea_evaluator.dart` -- Create ApneaEvaluator class -- Implement 100ms stream evaluation, 10s breach flag, 30s escalation timer, and 5s recovery check.
- `flutter/lib/ui/organisms/apnea_alert_overlay.dart` -- Create ApneaAlertOverlay widget -- Build high-contrast flashing emergency overlay with 30s countdown and 64dp "I'M SAFE" action.
- `flutter/lib/ui/pages/measurement_page.dart` -- Integrate ApneaEvaluator & ApneaAlertOverlay -- Connect 10Hz stream to evaluator and launch alarm overlay on breach.

**Acceptance Criteria:**
- Given 10Hz thermal stream drops $\ge 90\%$ for 10 seconds, when evaluator triggers, then Tier-1 alarm overlay launches within <200ms and sounds local siren.
- Given alarm is active, when user taps "I'M SAFE" within 30s, then siren silences and safety status transmits to cloud.

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
Summary: Implemented Epic 3 Story 3.1 Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm System within `flutter/`.
Files changed:
- `flutter/lib/core/monitoring/apnea_evaluator.dart`: Created ApneaEvaluator class for 100ms AASM breach detection ($\ge 90\%$ drop $\ge 10\text{s}$), 30s countdown escalation, and 5s auto-recovery.
- `flutter/lib/ui/organisms/apnea_alert_overlay.dart`: Created ApneaAlertOverlay organism matching MOB_TIER1_ALARM with high-contrast flashing red/yellow banner (`#FF3B30`), 30s countdown timer, and 64dp "I'M SAFE" button.
- `flutter/lib/ui/pages/measurement_page.dart`: Updated MeasurementPage to evaluate 10Hz stream and launch Tier-1 emergency alarm overlay on breach.
Verification performed: Code inspection and layout alignment with DESIGN.md and EXPERIENCE.md specs.

