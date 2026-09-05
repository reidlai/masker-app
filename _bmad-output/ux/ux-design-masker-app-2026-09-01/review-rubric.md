# Spine Pair Review — masker-app

## Overall verdict
DESIGN.md and EXPERIENCE.md are structurally sound — canonical section order is respected in both files, every `{token}` reference resolves, and every color has a hex value. But the pair is not yet a clean source-extractable contract: two IA surfaces (`MOB_HISTORY_FILTER`, `MOB_EXPORT_DOCTOR`) are named once in the flow map and never specified again anywhere, several load-bearing components have only half a spec (visual-only or behavior-only), and component names drift between the two files for nearly every shared organism (`BottomNavBar`/`PrimaryNavBarOrganism`, `ApneaAlertBanner`/`ApneaAlertBannerOrganism`, `SettingsMenuRow`/`SettingsMenuRowOrganism`, `BlePermissionPrimerCard`/`BlePermissionPrimerOrganism`). A downstream consumer building the Settings nav bar, the history/export screens, or the live-signal component would have to guess or go back to the author.

## 1. Flow coverage — thin
Checked: every IA surface in the Screen Navigation & Flow Map against Key Flows (Primary "David" journey, Secondary "David corrects his weight"), and against states/behaviors described elsewhere that imply a scenario (wear-guardrail failure, BLE denial).
### Findings
- **critical** `MOB_HISTORY_FILTER` and `MOB_EXPORT_DOCTOR` appear once each, only inside the ASCII flow-map diagram (EXPERIENCE.md lines 49–50), and are never mentioned again — no flow step, no component, no state. *Fix:* either add a Key Flow beat (or sub-flow) and Component/State entries for both, or explicitly mark them `[ASSUMPTION — out of scope this iteration]` the way `MOB_HOME` is (line 72), so downstream doesn't try to source-extract a spec that isn't there.
- **high** The calibration wear-guardrail failure ("Sensor not detected — Please attach D-BAND and retry," DESIGN.md §Components #2 / EXPERIENCE.md Component Pattern #2, line 135) and the BLE-permission-denial path (`State_BlePermissionDenied`, line 169) are both described as isolated behaviors/states but neither is walked as a numbered flow with a protagonist — a consumer has to infer how the failure interrupts the Primary Flow's linear sequence.
- **medium** No flow or state covers a mid-session BLE disconnect during `State_MonitoringActive`. This is the exact scenario the AD-12 background-receiver work (referenced throughout the BLE-priming section) exists to harden against, yet the Key Flows never dramatize a dropout-and-recovery beat during the 10:31 PM–2:15 AM monitoring window.
- **low** `MOB_DEVICE_PAIRING`'s "sensor not found" failure is only gestured at by analogy ("mirroring the existing wear-guardrail block pattern (Story 2.3)," EXPERIENCE.md line 62) rather than specified inline — the actual pairing-timeout copy/behavior is not in this document.

## 2. Token completeness — strong
Extracted every frontmatter token (11 colors, 7 typography, 8 spacing, 5 rounded) and every `{path.to.token}` reference in both files' prose (regex-verified, digits included for `h2`/`h3`-style keys). All references resolve to a defined frontmatter token; every color row has a hex code.
### Findings
- **low** `{colors.purple_analytics}` is fully defined (frontmatter + Colors table, "Morning summary dashboard headers... FFT spectral peaks") but is never referenced by `{}` syntax anywhere, and `MOB_SLEEP_SUMMARY` has no dedicated Components entry to consume it — the token's application is asserted in a table cell, never shown on a component. *Fix:* either add a Sleep Summary component spec that uses it, or drop the claim from the Purpose column.
- **low** `{typography.h1}`, `{typography.h3}`, `{typography.font_family}`, `{typography.numeric_tabular}` are defined but never wired via `{}` reference outside their own definition — components instead restate raw values (see Bloat finding #1). Not a broken reference, just unused token plumbing.

## 3. Component coverage — broken
Extracted every component name in DESIGN.md's frontmatter list (16), DESIGN.md's Components section (9 rows), and EXPERIENCE.md's Component Patterns section (8 rows), then cross-matched by name and by evident identity.
### Findings
- **critical** `LiveAirflowMonitorOrganism` (EXPERIENCE.md Component Pattern #1) — the real-time 10Hz signal renderer, arguably the app's most safety-critical visual — has no matching row in DESIGN.md's Components (Visual Specifications) section at all, and isn't in the DESIGN.md frontmatter `components:` list.
- **critical** `MetricStatCard` and `SessionHistoryListItem` (DESIGN.md Components #1 and #4) have no matching row in EXPERIENCE.md's Component Patterns — their visuals are specified but their behavior (live-update cadence, tap targets, empty/loading state) is not.
- **high** Component names drift between the two files for nearly every shared organism instead of matching exactly:
  - `BottomNavBar` (DESIGN.md #5) vs. `PrimaryNavBarOrganism` (EXPERIENCE.md #4) — different names, not just a suffix, for the same 4-tab bar.
  - `ApneaAlertBanner` (DESIGN.md #3) vs. `ApneaAlertBannerOrganism` (EXPERIENCE.md #3).
  - `SettingsMenuRow` (DESIGN.md #6) vs. `SettingsMenuRowOrganism` (EXPERIENCE.md #5) — and EXPERIENCE.md itself is inconsistent internally, calling it plain `SettingsMenuRow` in Interaction Primitives (line 178) and Accessibility Floor (lines 188–189) but `SettingsMenuRowOrganism` in the Component Patterns heading.
  - `BlePermissionPrimerCard` (DESIGN.md #9) vs. `BlePermissionPrimerOrganism` (EXPERIENCE.md #7).
  - `DeveloperSimulatorBarOrganism` is named identically in both files, proving the drift above is inconsistency rather than an intentional DESIGN/EXPERIENCE naming convention. *Fix:* pick one canonical name per component and use it verbatim in both files (and internally within EXPERIENCE.md).
- **medium** `SettingsSectionHeader` has a DESIGN.md visual row (#7) but no numbered EXPERIENCE.md Component Patterns entry; its real behavioral rule ("rendered only when its section contains at least one visible row") lives instead in IA prose (line 94). A consumer scanning Component Patterns only would miss it.
- **medium** `ShadButton`, `ShadCard`, `ShadBadge`, `ShadInput`, `ShadSwitch`, `ShadDialog`, `ShadProgress` are declared in DESIGN.md's frontmatter `components:` list but have no row in Components or Component Patterns anywhere — only `ShadButton` gets a passing mention (DESIGN.md line 162). *Fix:* either give the base primitives a one-line usage row each, or drop them from the components: list and treat them as an implicit UI-kit dependency rather than a spec'd component.

## 4. State coverage — thin
Walked every IA surface against the 11 named `State_*` patterns plus states implied elsewhere (guardrail toasts, denial paths).
### Findings
- **high** `MOB_USER_PROFILE`'s own `[NOTE FOR UX]` (line 98) flags an unresolved first-run-vs-edit-mode distinction, but no `State_ProfileSetup` / `State_ProfileEdit` pair exists to formalize it — the ambiguity is named, not resolved into state.
- **high** No offline/network-failure state exists anywhere, despite `ApneaAlertBannerOrganism`'s behavior spec claiming it "sends a safety packet to cloud" on dismissal (EXPERIENCE.md line 138) — the one moment a network failure would matter most for patient safety has no defined fallback state.
- **medium** `MOB_DEVICE_PAIRING` has no "scanning," "paired successfully," or "sensor not found / timeout" state — only `State_BlePermissionDenied` touches this screen, leaving the entire non-permission failure space unspecified.
- **medium** `MOB_GRAPH_WAVEFORM`, `MOB_HISTORY_FILTER`, `MOB_EXPORT_DOCTOR` have no cold-load/empty-state coverage (e.g., first-ever session with no history to show, export with nothing to export).
- **low** `State_Idle` ("awaiting Passkey authentication or sensor connection") conflates two distinct waits into one state name — imprecise for a state machine a developer would implement as a discrete enum.

## 5. Visual reference coverage — broken
`mockups/` contains 3 files: `mob_passkey_auth.html`, `mob_sleep_summary.html`, `mob_tier1_alarm.html`. No `wireframes/` or `imports/` directory exists. Searched both spines for any inline link or filename reference to any mockup file.
### Findings
- **high** All three mockups are orphans — neither DESIGN.md nor EXPERIENCE.md links to them inline or names what each illustrates anywhere in the text. The corresponding screens (`MOB_PASSKEY_AUTH`, `MOB_SLEEP_SUMMARY`, `MOB_TIER1_ALARM`) are discussed at length in prose, but a downstream consumer reading the spine has no way to discover the mockups exist. *Fix:* add an inline reference at each relevant section, e.g. "See `mockups/mob_tier1_alarm.html` for the full-screen siren overlay."
- **low** Even with links added, coverage would still be partial: only 3 of the ~13 named IA surfaces have any visual reference. Onboarding, BLE priming, pairing, both calibration stages, monitor, settings, profile, waveform, history, and export have none.

## Mechanical notes
- **Frontmatter completeness:** DESIGN.md's frontmatter is fully populated (name/status/version/created/updated/author + colors/typography/spacing/rounded/components). EXPERIENCE.md's frontmatter carries only identity fields (no token block), which is correct given it defers to DESIGN.md — but note EXPERIENCE.md's Foundation section (line 16) only cross-references 5 example tokens as an index, not the full set actually used later in the file.
- **Versions match:** both files are `version: 1.2.0`, `updated: 2026-09-04` — consistent.
- **Diagram syntax:** the Screen Navigation & Flow Map (EXPERIENCE.md lines 24–51) and the Settings sub-tree (lines 83–91) are plain ASCII art in an untagged code fence, not Mermaid — renders fine as text but isn't a diagramming-tool-checkable format; no Mermaid blocks exist anywhere in either file.
- **No broken cross-refs found:** every `{colors.*}`, `{typography.*}`, `{spacing.*}`, `{rounded.*}` reference in both files resolves to a token defined in DESIGN.md's frontmatter (verified by full-file regex extraction, not sampling).
- **Screen-ID consistency:** all `MOB_*` IDs are spelled consistently everywhere they appear (no typo variants found) — the coverage gap for `MOB_HISTORY_FILTER`/`MOB_EXPORT_DOCTOR` is a specification gap, not a naming-consistency defect.
- **Section order:** DESIGN.md matches the canonical order exactly (Brand & Style → Colors → Typography → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts). EXPERIENCE.md matches its required default order exactly (Foundation → IA → Voice and Tone → Component Patterns → State Patterns → Interaction Primitives → Accessibility Floor → Key Flows).
