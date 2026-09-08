---
title: 'Fix Apnea Index labeling, apnea-only caveat coverage, and 4-band AI severity'
type: 'bugfix'
created: '2026-09-08'
status: 'done'
review_loop_iteration: 0
baseline_commit: '035363075630ab6607dcced33ab734883fa1d0f1'
context:
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/prd/prd.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Morning Sleep Summary score card renders the literal text `"AHI 3.2 (Normal)"` (`sleep_score_organism.dart:71`), and its widget fields are named `ahiValue` / `ahiStatus`. The D-BAND is airflow-only and does not score hypopneas, so the metric is an **Apnea Index (AI)**, never an AHI — every planning doc says so, and `EXPERIENCE.md` §225 states "Never 'AHI'". Two widget tests assert the wrong string, locking the bug in. Separately: the spec-mandated apnea-only caveat appears on only one surface (in non-canonical wording), and the AI severity bands are implemented as 3 bands (Normal <5 / Moderate 5–<30 / Severe ≥30) while `ARCHITECTURE-SPINE.md` §52/§1339/§1836 mandate 4 bands with a **Mild** band (Normal <5 / Mild 5–15 / Moderate 15–30 / Severe ≥30). `prd.md` FR-4.1 / NFR-6.1 and `EXPERIENCE.md` §107 currently carry the older 3-band wording and must be reconciled to 4 bands.

**Approach:** (1) Rename `SleepScoreOrganism.ahiValue/ahiStatus` → `apneaIndexValue/apneaIndexStatus` and render `"Apnea Index …"`; fix the one caller and the two tests. (2) Add `HistorySeverity.mild` and re-band `HistoryState.severityFor` to the 4-band thresholds; route every AI-band surface (`history_filter_page`, `home_summary_card`) through `severityFor` as the single source of truth; update filter chips and seed data. (3) Put the canonical caveat string verbatim on all three clinician/patient AI surfaces that lack it or carry off-spec wording (`summary_screen_page`, `export_doctor_page`, `history_filter_page`); the compact Home hero + trend cards stay caveat-free per `EXPERIENCE.md` §107. (4) Correct the FHIR mock fixture's AHI LOINC code and `ahiScore` param. (5) Update `prd.md` and `EXPERIENCE.md` band wording to 4 bands.

## Boundaries & Constraints

**Always:**
- Run all Dart/Flutter commands from the `flutter/` directory.
- The metric label is **"Apnea Index"** spelled out (an "AI" short-form suffix like the Home hero card's is acceptable *after* first use on a screen); never "AHI" as the app's own metric label. The phrase "standard AHI severity bands" may remain in **doc prose** where it describes the bands' clinical provenance.
- Canonical caveat string, used verbatim wherever a caveat is added or replaced: `This is an apnea-only screen. A full sleep study also counts shallow-breathing (hypopnea) events and may score higher.`
- 4-band thresholds everywhere AI severity is derived: Normal `ai < 5`, Mild `5 ≤ ai < 15`, Moderate `15 ≤ ai < 30`, Severe `ai ≥ 30`. Upper bound is exclusive; the lower band wins at the boundary.
- `HistoryState.severityFor` is the ONE place bands are defined; `history_filter_page` and `home_summary_card` derive from it, not from re-inlined numeric literals.
- Keep the `alarm_fired` amber-alert treatment on `home_summary_card` unchanged and layered on top of the band logic.
- Preserve the existing dark glassmorphism tokens and tabular-number styling.

**Ask First:**
- The Mild badge colour. This spec maps Mild → the existing amber (`ShadBadgeVariant.moderate` styling) because the palette has only green/amber/red severity colours; Mild and Moderate are then distinguished by label text only. If a distinct Mild colour/token is wanted, that is a design-system change — halt and confirm.
- Any change to the FHIR payload beyond the mock test fixture (there is no production exporter; `export_doctor_page` only shows a toast).

**Never:**
- Do not add the full caveat line to the compact Home hero card (`home_summary_card`) or the 7-night trend card (`weekly_trend_card`) — `EXPERIENCE.md` §107 explicitly keeps those compact cards caveat-free.
- Do not implement severity-driven ring/badge colours on `SleepScoreOrganism` (its hard-green ring for non-Normal sessions) — deferred, out of scope.
- Do not implement the alarm-fired "demote AI band to a clinical caption" behaviour on `home_summary_card` — deferred, out of scope.
- Do not build a real FHIR/PDF exporter or wire session data into these mock/placeholder screens.
- Do not change `ARCHITECTURE-SPINE.md` (already 4-band).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Summary score card render | `SleepScoreOrganism(apneaIndexValue:"3.2", apneaIndexStatus:"Normal")` | Renders `Apnea Index 3.2 (Normal)`; no widget in the tree contains the substring "AHI" | N/A |
| `severityFor` — Normal boundary | `ai = 4.99` / `ai = 5.0` | `HistorySeverity.normal` / `HistorySeverity.mild` | N/A |
| `severityFor` — Mild→Moderate boundary | `ai = 14.99` / `ai = 15.0` | `HistorySeverity.mild` / `HistorySeverity.moderate` | N/A |
| `severityFor` — Severe boundary | `ai = 29.99` / `ai = 30.0` | `HistorySeverity.moderate` / `HistorySeverity.severe` | N/A |
| `severityFor` — invalid AI | `ai` is `NaN` or `< 0` | `HistorySeverity.normal` (no throw) | Guard clause returns `normal` |
| History Mild filter chip | User taps `Mild (5–15)` | List shows only sessions with `5 ≤ ai < 15` (seed row `Sep 3, 2026`) | N/A |
| History Moderate filter chip | User taps `Moderate (15–30)` | List shows only sessions with `15 ≤ ai < 30` (seed row `Aug 31, 2026`) | N/A |
| Doctor export caveat | `ExportDoctorPage` renders | Canonical caveat string visible on the page | N/A |
| History list caveat | `HistoryFilterPage` renders | Canonical caveat string visible once (not per row) | N/A |
| FHIR mock fixture | `generateSignedFhirJson(apneaIndexScore: 3.2, …)` | `code` describes an apnea-only index (no "Hypopnea"); an `Observation.note` carries the canonical caveat; `valueQuantity.value == 3.2` | N/A |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/organisms/sleep_score_organism.dart` — **primary bug.** Line 71 renders `"AHI $ahiValue ($ahiStatus)"`; fields `ahiValue`/`ahiStatus` at lines 6-7, defaults at 14-15. Rename fields → `apneaIndexValue`/`apneaIndexStatus`, change literal → `"Apnea Index $apneaIndexValue ($apneaIndexStatus)"`. Ring border (`:41`) and badge (`:87-101`) stay hard green — leave as-is.
- `flutter/lib/ui/pages/summary_screen_page.dart` — the only `SleepScoreOrganism` caller (`:61-67`, passes `ahiValue:"3.2"`, `ahiStatus:"Normal"`). Update the two param names. Line 74 caveat `"* Apnea Index scores apnea events per hour recorded by D-BAND thermal sensor. Not a full polysomnography AHI."` → replace with the canonical string (keep the leading `* ` and italic styling if desired).
- `flutter/lib/core/bloc/history/history_state.dart` — `enum HistorySeverity { normal, moderate, severe }` (`:6`) → add `mild` between `normal` and `moderate`. `severityFor` (`:43-47`) → 4-band + NaN/negative guard. `filteredSessions` (`:31-41`) switches on `selectedFilterIndex`; indices shift because a Mild chip is inserted (see below) — Normal=1, Mild=2, Moderate=3, Severe=4; predicates: `<5`, `5..<15`, `15..<30`, `>=30`. `_seedSessions` (`:17-24`): change the `Sep 3, 2026` row from `"ai": 4.0, "events": 3, "status": "Normal"` to `"ai": 9.4, "events": 8, "status": "Mild"` so the Mild band is demonstrable; keep the list length at 6. Comment at `:42` — update to the 4-band description.
- `flutter/lib/ui/pages/history_filter_page.dart` — chip row (`:50-58`): insert `Mild (5–15)` chip, relabel `Moderate (5–29)` → `Moderate (15–30)`, keep `Normal (<5)` / `Severe (≥30)`; indices become All=0…Severe=4. Row-badge `switch` (`:76-81`): add `HistorySeverity.mild => ShadBadgeVariant.moderate`. Add one caveat line (canonical string) — e.g. a padded footer below the `ListView` or a subtitle under the chips; shown once.
- `flutter/lib/ui/molecules/home_summary_card.dart` — `_getBadgeVariant` (`:27-32`) and `_getBadgeLabel` (`:34-41`) re-inline `<5 / <30` thresholds. Replace both bodies (below the `alarmFired` early-returns) with a lookup off `HistoryState.severityFor(apneaIndex)` → `{normal:"Normal"/normal, mild:"Mild"/moderate, moderate:"Moderate"/moderate, severe:"Severe"/severe}`. Add `import '../../core/bloc/history/history_state.dart';`.
- `flutter/lib/ui/pages/export_doctor_page.dart` — physician report card (`:66-74`) already labels the row `"Apnea Index"` correctly; no caveat anywhere. Add the canonical caveat string as a small `textSecondary` line inside or just below the report card `Container` (`:34-76`).
- `flutter/lib/ui/molecules/weekly_trend_card.dart` — already titled `"APNEA INDEX — LAST 7 NIGHTS"`, no "AHI". **No change** (compact card, caveat-exempt).
- `flutter/lib/ui/atoms/shad_badge.dart` — `ShadBadgeVariant` has no `mild`; **no change** (Mild reuses `moderate`/amber styling).
- `flutter/lib/core/theme/app_theme.dart` — colour comments `:8-9` say "Normal/Moderate Apnea Index"; fine, no change.

Tests:
- `flutter/test/ui/sleep_score_organism_test.dart` — `:6` title "AHI details", `:12-13` param names, `:21` `expect(find.text("AHI 3.2 (Normal)")…)`. Update all three; add `expect(find.textContaining("AHI"), findsNothing)`.
- `flutter/test/ui/summary_screen_page_test.dart` — `:6` title, `:17` comment, `:19` assertion. Update; add a `find.textContaining("apnea-only screen")` presence check.
- `flutter/test/core/bloc/history_bloc_test.dart` — `:16-24` Moderate now index 3 with `15 ≤ ai < 30`; `:26-35` Normal now length 4 (seed row moved to Mild); `:37-42` Severe now index 4; `:44-49` `severityFor` expectations → 4-band + add boundary + NaN/negative cases; add a Mild-filter (index 2) test.
- `flutter/test/ui/history_filter_page_test.dart` — `:19-21` chip labels (+ new `Mild (5–15)`, `Moderate (15–30)`); `:27` taps "Moderate" — retarget to the new label; `:30-31` still expects `Aug 31, 2026` (ai 16.4 ∈ [15,30)). Add caveat presence check.
- `flutter/test/core/fhir_report_exporter_test.dart` — rename `ahiScore` → `apneaIndexScore` (`:6,41,87,103`); `code` block (`:26-34`) → drop the AHI LOINC, use `{"text": "Apnea Index (apnea events per hour, apnea-only)"}`; add a `note` entry with the canonical caveat; add assertions: `code.text` has no "Hypopnea", a note contains "apnea-only screen".

Planning docs:
- `_bmad-output/prd/prd.md` — FR-4.1 (`:145`) and NFR-6.1 (`:283`): `Severity bands (Normal < 5 / Moderate 5–29.9 / Severe ≥ 30)` → `Severity bands (Normal < 5 / Mild 5–15 / Moderate 15–30 / Severe ≥ 30)`.
- `_bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md` — §107 (`:107`) badge mapping: add `{colors.warning_amber} "Mild" for 5–15`, change Moderate to `15–30`. §225 (`:225`) parenthetical `("Normal range" / "Moderate" / "Severe")` → add `"Mild"`.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/ui/organisms/sleep_score_organism.dart` — rename `ahiValue`/`ahiStatus` → `apneaIndexValue`/`apneaIndexStatus` (+ defaults) and render `"Apnea Index …"`.
- [x] `flutter/lib/ui/pages/summary_screen_page.dart` — update the two `SleepScoreOrganism` params; replace the line-74 caveat with the canonical string.
- [x] `flutter/lib/core/bloc/history/history_state.dart` — add `HistorySeverity.mild`; 4-band `severityFor` with NaN/negative guard; shift `filteredSessions` indices for the new Mild chip; move the `Sep 3, 2026` seed row into the Mild range; refresh the `:42` comment.
- [x] `flutter/lib/ui/pages/history_filter_page.dart` — insert `Mild (5–15)` chip, relabel Moderate, extend the badge `switch`, add one canonical caveat line.
- [x] `flutter/lib/ui/molecules/home_summary_card.dart` — derive badge variant + label from `HistoryState.severityFor`; keep `alarmFired` branch on top.
- [x] `flutter/lib/ui/pages/export_doctor_page.dart` — add the canonical caveat line to/under the report card.
- [x] `flutter/test/ui/sleep_score_organism_test.dart` — retarget to "Apnea Index"; add no-"AHI" assertion.
- [x] `flutter/test/ui/summary_screen_page_test.dart` — retarget assertion/title/comment; assert caveat present.
- [x] `flutter/test/core/bloc/history_bloc_test.dart` — 4-band + index-shift updates; add Mild-filter and `severityFor` boundary/NaN tests.
- [x] `flutter/test/ui/history_filter_page_test.dart` — chip-label updates; retarget the Moderate-filter tap; assert caveat present.
- [x] `flutter/test/core/fhir_report_exporter_test.dart` — rename param; de-AHI the `code`; add `note` with caveat; add code/note assertions.
- [x] `_bmad-output/prd/prd.md` — 4-band wording in FR-4.1 and NFR-6.1.
- [x] `_bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md` — 4-band wording + Mild colour in §107; add "Mild" to §225 severity words.

**Acceptance Criteria:**
- Given the Morning Sleep Summary renders, when the score card is shown, then it reads `Apnea Index 3.2 (Normal)` and no descendant text contains "AHI".
- Given any AI value, when severity is derived on any surface (summary badge, history row badge, history filter, Home hero badge), then it uses the identical 4-band thresholds sourced from `HistoryState.severityFor`.
- Given the History filter has a `Mild (5–15)` chip, when tapped, then only sessions with `5 ≤ ai < 15` are listed and the seed contains at least one such session.
- Given the Morning Sleep Summary, the Physician Export page, and the Session History page each render, then the exact canonical caveat string is present on each; given the Home hero card and the 7-night trend card render, then the full caveat line is absent.
- Given the FHIR mock fixture, when `generateSignedFhirJson` is called, then the `code` does not reference "Hypopnea" and an `Observation.note` carries the canonical caveat.
- Given `flutter analyze` and `flutter test` run, then analyze reports no new issues (4 pre-existing issues in untouched files — `lib/main.dart`, `developer_options_page.dart`, `settings_page.dart`, `test/ui/developer_options_page_test.dart` — allowed) and all tests pass.

## Spec Change Log

_No `bad_spec` / `intent_gap` loopback — the frozen intent held through implementation and review._

## Review Triage Log

### 2026-09-08 — step-04 review pass (3 lenses: blind-hunter, edge-case-hunter, verification-gap)
- intent_gap: 0
- bad_spec: 0
- patch: 5 — (1) new `home_summary_card_test.dart` pinning the badge label + `ShadBadge` variant per band and at every boundary (the severity rewrite shipped with no card-level test); (2) `history_filter_page_test.dart` now asserts the Mild-band row (AI 9.4) badge is the amber `moderate` variant, not green `normal`; (3) canonical caveat extracted to `lib/core/constants/apnea_copy.dart` (`kApneaOnlyCaveat`) and referenced from all three surfaces + the FHIR test — was hand-copied 4×; (4) dropped the `"* "` prefix on the summary caveat so all three surfaces render the string byte-identically ("verbatim"); (5) removed the dead `"status"` key from `_seedSessions` (never read; a second un-checked source of truth).
- defer: 3 — summary caveat swap dropped the per-hour metric definition + sensor provenance from that surface; `HistorySeverity`/`severityFor` mis-layered in the history bloc state file (should be `core/domain`); 5 history filter chips overflow small screens and the "(5–15)"/"(15–30)" labels share the boundary number. All appended to `deferred-work.md`.
- reject: NaN/negative → `normal` (frozen I/O-matrix intent); `SleepScoreOrganism` severity ring colour (already deferred, in "Never"); no production FHIR exporter (frozen "Ask First" + deferred item c); Mild/Moderate sharing amber (approved "Ask First" trade-off); filter-index persistence migration (no `HydratedBloc` exists); seed `ai`/`events` not being mutually consistent (pre-existing placeholder-data pattern).

## Design Notes

**4-band is the resolved canon.** Three planning docs disagreed: `ARCHITECTURE-SPINE.md` (4-band w/ Mild) vs `prd.md` FR-4.1/NFR-6.1 and `EXPERIENCE.md` §107 (3-band). Human decision (2026-09-08): `ARCHITECTURE-SPINE.md`'s 4-band scheme wins; PRD and EXPERIENCE.md are updated to match in this change. `spec-4-1-morning-sleep-summary-dashboard.md` (status: done) already named "Normal, Mild, Moderate, Severe" in its intent, so the code was the outlier.

**Mild colour.** Palette (`app_theme.dart`) exposes exactly three severity colours: `accentGreen` / `warningAmber` / `dangerRed`. Mild maps to `warningAmber` (via `ShadBadgeVariant.moderate`); Mild vs Moderate is disambiguated by the label text. Flagged under "Ask First" in case a dedicated Mild token is preferred.

**Single source of truth for bands.** Today the thresholds are copy-pasted in `severityFor`, `filteredSessions`, the filter-chip labels, and `home_summary_card`'s two helpers. After this change the numeric thresholds live only in `severityFor` (+ the human-readable chip label strings). Example shape:

```dart
static HistorySeverity severityFor(double ai) {
  if (ai.isNaN || ai < 0) return HistorySeverity.normal;
  if (ai >= 30.0) return HistorySeverity.severe;
  if (ai >= 15.0) return HistorySeverity.moderate;
  if (ai >= 5.0) return HistorySeverity.mild;
  return HistorySeverity.normal;
}
```

**Deferred (logged to `deferred-work.md`):** (a) severity-driven ring/badge colour on `SleepScoreOrganism` for non-Normal sessions; (b) alarm-fired "demote AI band to clinical caption" on `home_summary_card`; (c) a real signed FHIR/PDF exporter with a correct apnea-only code system.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: no new issues (4 pre-existing issues in untouched files acceptable, 0 errors).
- `cd flutter && flutter test` — expected: all tests pass; suite count rises (new boundary/caveat/Mild tests).
- `cd flutter && rg -n "AHI" lib/` — expected: no match in `lib/` as the app's own metric label (doc-prose "standard AHI severity bands" is not in `lib/`).

## Suggested Review Order

**The label bug (start here)**

- The one-line fix: the score card no longer says "AHI".
  [`sleep_score_organism.dart:71`](../../flutter/lib/ui/organisms/sleep_score_organism.dart#L71)
- Field rename ripples to exactly one caller.
  [`summary_screen_page.dart:64`](../../flutter/lib/ui/pages/summary_screen_page.dart#L64)

**4-band severity — single source of truth**

- The whole banding decision lives here: enum + `severityFor` with the NaN/negative guard.
  [`history_state.dart:61`](../../flutter/lib/core/bloc/history/history_state.dart#L61)
- New `mild` enum value; note enum order (affects `.index`, only used by one switch).
  [`history_state.dart:6`](../../flutter/lib/core/bloc/history/history_state.dart#L6)
- Filter chips now derive membership from `severityFor`, not re-inlined literals; indices shifted 1→4.
  [`history_state.dart:33`](../../flutter/lib/core/bloc/history/history_state.dart#L33)
- Home hero badge routes through `severityFor`; `alarmFired` still wins on top.
  [`home_summary_card.dart:30`](../../flutter/lib/ui/molecules/home_summary_card.dart#L30)
- History row badge + the 5th chip ("Mild (5–15)"); `mild → moderate` (amber) variant.
  [`history_filter_page.dart:95`](../../flutter/lib/ui/pages/history_filter_page.dart#L95)

**Apnea-only caveat — one string, three surfaces**

- The canonical string, defined once.
  [`apnea_copy.dart:5`](../../flutter/lib/core/constants/apnea_copy.dart#L5)
- Summary: replaces the old off-spec footnote (no more `"* "` prefix).
  [`summary_screen_page.dart:75`](../../flutter/lib/ui/pages/summary_screen_page.dart#L75)
- Physician export: new — clinician surface had none.
  [`export_doctor_page.dart:77`](../../flutter/lib/ui/pages/export_doctor_page.dart#L77)
- History list: new — shown once for the list, not per row.
  [`history_filter_page.dart:69`](../../flutter/lib/ui/pages/history_filter_page.dart#L69)

**FHIR mock fixture**

- AHI LOINC `93832-4` removed; `code.text` is apnea-only; `ahiScore` → `apneaIndexScore`; caveat `note` added.
  [`fhir_report_exporter_test.dart:30`](../../flutter/test/core/fhir_report_exporter_test.dart#L30)

**Planning-doc reconciliation (3-band → 4-band)**

- FR-4.1 and NFR-6.1 band wording.
  [`prd.md:145`](../prd/prd.md#L145)
- Home-card colour mapping + §225 severity words.
  [`EXPERIENCE.md:107`](../ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md#L107)

**Tests (supporting)**

- Band label + variant per band and at every boundary; `alarm_fired` override; empty state.
  [`home_summary_card_test.dart:1`](../../flutter/test/ui/home_summary_card_test.dart#L1)
- 4-band filter indices, boundary cases, NaN/negative guard.
  [`history_bloc_test.dart:1`](../../flutter/test/core/bloc/history_bloc_test.dart#L1)
- "Apnea Index" text + no-"AHI" negative assertion.
  [`sleep_score_organism_test.dart:21`](../../flutter/test/ui/sleep_score_organism_test.dart#L21)
- Caveat presence on summary / export / history; Mild-row badge variant.
  [`history_filter_page_test.dart:41`](../../flutter/test/ui/history_filter_page_test.dart#L41)
