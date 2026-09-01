---
title: 'Epic 4 Story 4.1: Morning Sleep Summary Dashboard & Respiration Waveform Inspection'
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

**Problem:** After completing overnight sleep apnea monitoring, patients need a clear morning summary dashboard displaying total sleep duration, AHI score ring (92), AHI severity badge (Normal, Mild, Moderate, Severe), 60 FPS Skia GPU interactive respiration wave chart (`fl_chart`), 256-point FFT spectral peaks, date history filter, and signed physician FHIR JSON / PDF report export.

**Approach:** Implement `SummaryScreenPage` in `flutter/lib/ui/pages/summary_screen_page.dart` and `LiveWaveformChart` organism in `flutter/lib/ui/organisms/live_waveform_chart.dart` integrated into `MainContainerPage` navigation.

## Boundaries & Constraints

**Always:**
- Use `flutter/` root directory for all Dart/Flutter files and commands.
- Render 60 FPS cubic-spline smooth respiration wave curves using `fl_chart` / Skia GPU.
- Enforce dark glassmorphism design system tokens (`#0F172A` background, `#1E293B` card surface, `#6D28D9` royal purple header, `#10B981` normal AHI green).
- Display tabular numbers (`tabular-nums`) for all AHI metrics and sleep duration values.

**Block If:**
- Report export requires server-side PDF generation outside client FHIR JSON export engine.

**Never:**
- Never block UI thread during 256-point FFT spectral peak calculations.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Sleep Summary Render | Morning session completed | Displays 7h 45m duration, AHI 3.2 (Normal), score 92 | Fallback to default baseline if 0 events |
| Interactive Chart Pan | User pinches/pans waveform graph | Smooth 60 FPS timeline panning with event flags | Clamp zoom bounds to session limits |
| Physician Report Export | User taps "Export Signed Report" | Generates signed FHIR JSON payload & PDF preview toast | Display export confirmation snackbar |

</intent-contract>

## Code Map

- `flutter/lib/ui/pages/summary_screen_page.dart` -- Morning Sleep Summary Dashboard screen (`MOB_SLEEP_SUMMARY`) with AHI score ring, quality badge, metrics grid, and physician export button.
- `flutter/lib/ui/organisms/live_waveform_chart.dart` -- Interactive 60 FPS Skia GPU respiration waveform chart (`fl_chart`) rendering overnight thermal breath streams and flagged apnea markers.
- `flutter/lib/ui/pages/main_container_page.dart` -- Bottom navigation bar wrapper linking Home, Measurement, Summary, and Profile screens.

## Tasks & Acceptance

**Execution:**
- `flutter/lib/ui/organisms/live_waveform_chart.dart` -- Implement LiveWaveformChart -- Build 60 FPS `fl_chart` LineChart with cubic spline smoothing and apnea flags.
- `flutter/lib/ui/pages/summary_screen_page.dart` -- Implement SummaryScreenPage -- Render score ring, AHI severity badge, metrics grid, waveform card, and FHIR export action.
- `flutter/lib/ui/pages/main_container_page.dart` -- Update MainContainerPage -- Connect SummaryScreenPage to bottom navigation tab.

**Acceptance Criteria:**
- Given sleep session finishes, when SummaryScreenPage renders, then score ring (92), AHI badge (Normal AHI 3.2), and duration (7h 45m) display with dark glassmorphic styling.
- Given user interacts with waveform graph, when panning across the timeline, then `fl_chart` updates smoothly at 60 FPS with red apnea markers.

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
Summary: Implemented Epic 4 Story 4.1 Morning Sleep Summary Dashboard & Respiration Waveform Inspection within `flutter/`.
Files changed:
- `flutter/lib/ui/organisms/live_waveform_chart.dart`: Updated LiveWaveformChart with 60 FPS Skia GPU `fl_chart` line rendering, cubic spline smoothing, and red apnea event markers.
- `flutter/lib/ui/pages/summary_screen_page.dart`: Implemented SummaryScreenPage morning sleep summary dashboard with score ring (92), AHI severity badge (Normal 3.2), metrics grid, and physician FHIR export action.
- `flutter/lib/ui/pages/main_container_page.dart`: Updated MainContainerPage to include SummaryScreenPage in 4-tab bottom navigation bar.
Verification performed: Code inspection and layout alignment with DESIGN.md and EXPERIENCE.md specs.

