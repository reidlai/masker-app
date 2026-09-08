---
title: 'DEV Simulator Toolbar Renders Nothing When the Simulator Is Off'
type: 'bugfix'
created: '2026-09-08'
status: 'done'
review_loop_iteration: 0
baseline_commit: ba3c4e270c59aac5ce0afcb5080876f1140fa227
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `DeveloperSimulatorBarOrganism.build()` paints its bordered/shadowed `Container` and the "⚡ DEV SIMULATOR TOOLBAR" header **unconditionally** — only the scenario *chips* are gated on `state.isSimulatorActive`. So with the simulator off it still renders a titled empty box (the reported screenshot). The only thing that hides it is one external gate in `MeasurementPage._buildMonitoring`, whose `catch` fallback (`context.select` unavailable → `_isDevMode` getter → a possibly-stale driver flag) can still resolve "show". The sibling "📊 DETECTION MECHANISM STAGE MONITOR" panel has no self-check at all.

**Approach:** Gate at the source. `DeveloperSimulatorBarOrganism` returns `const SizedBox.shrink()` when `!state.isSimulatorActive`, so "simulator off ⟹ no toolbar" holds for every call site. Tighten the `MeasurementPage` external gate so an unavailable `SimulatorBloc` resolves to hidden (dev tooling requires the bloc — no stale-driver fallback). Keep the external gate as redundant defense for the stage panel.

## Boundaries & Constraints

**Always:**
- With `SimulatorState.isSimulatorActive == false`, `DeveloperSimulatorBarOrganism` produces no visible widget from any call site.
- Behavior with the simulator **on** is unchanged: container, header, and both scenario chips render exactly as today.
- The `MeasurementPage` monitoring-screen `Builder` gate stays (belt-and-suspenders); its `catch (_)` branch resolves `active = false`, not `_isDevMode`.
- The "📊 DETECTION MECHANISM STAGE MONITOR" stage panel remains gated by that same `Builder` (it has no bloc of its own).

**Ask First:**
- Removing the `MeasurementPage` external `Builder` gate entirely.
- Changing where `SimulatorScenario` lives, or how `SimulatorBloc` is provided (the organism's self-created fallback `BlocProvider` at `:96-103`).
- Any change to `SimulatorBloc`, `settings_page.dart`, `home_page.dart`, or `main_container_page.dart`.

**Never:**
- Add a new "is dev mode" derivation — reuse `state.isSimulatorActive` from the organism's existing `BlocBuilder`.
- Touch the scenario-chip wiring, the stage-panel copy, or `SleepMonitoringBloc`.
- Make `DeveloperSimulatorBarOrganism` depend on `MeasurementPage` state.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Render the organism, simulator OFF | `SimulatorState.isSimulatorActive == false` (any call site / any screen) | `const SizedBox.shrink()` — no `Container`, no "⚡ DEV SIMULATOR TOOLBAR" text | N/A |
| Render the organism, simulator ON | `isSimulatorActive == true` | Container + header + both scenario chips, unchanged | N/A |
| Monitoring screen, toggle simulator OFF mid-session | `status == monitoring`, then `isSimulatorActive → false` | Toolbar **and** the "📊 DETECTION MECHANISM STAGE MONITOR" panel leave the tree on the next frame; the session stays on the night-mode screen | N/A |
| Dev widgets with no `SimulatorBloc` ancestor and `developerEnabled` not forced | `context.select<SimulatorBloc,bool>` throws in the `MeasurementPage` `Builder` | `active = false` → nothing renders (dev tooling needs the bloc) | swallow the lookup failure, render nothing |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/organisms/developer_simulator_bar_organism.dart` — `BlocBuilder<SimulatorBloc, SimulatorState>` builder at `:24`; `final isSimEnabled = state.isSimulatorActive;` at `:25`. **Insert** `if (!isSimEnabled) return const SizedBox.shrink();` immediately after `:26` (before `return Container(` at `:28`). The `if (isSimEnabled) ...[` chip wrapper at `:66` is now always true inside the builder — simplify it to an unconditional spread (or leave it; harmless). Fallback `BlocProvider(create: (_) => SimulatorBloc())` at `:96-103` is **read-only** (Ask First).
- `flutter/lib/ui/pages/measurement_page.dart` — the dev `Builder` gate at `:296-318`: keep it; change the `catch (_) { active = _isDevMode; }` at `~:308` to `catch (_) { active = false; }`. `_devStagePanel(...)` def at `:238` and the `DeveloperSimulatorBarOrganism()` call at `:315` are otherwise unchanged. `_isDevMode` getter at `:53-61` stays (still used for `isDevMode:` in `initState`).
- `flutter/test/ui/developer_simulator_bar_organism_test.dart` — `setUp` at `:7` does `BleSimulatorDriver().setSimulatorEnabled(true)`; the one test (`:15-34`) asserts the header **is** present. Add a second `testWidgets` (or a `group`) that pumps with the simulator disabled and asserts the whole organism renders nothing.
- `flutter/test/ui/measurement_page_test.dart` — the monitoring-gate test (`~:357`, "…toggling it off hides them…") already asserts `find.text("⚡ DEV SIMULATOR TOOLBAR")` / `"📊 DETECTION MECHANISM STAGE MONITOR"` `findsNothing` after `SimulatorEnabledSet(false)`. It must stay green; add an assertion that the toolbar is absent even while the session is still `monitoring` (already there — verify).
- Read-only: `flutter/lib/core/bloc/simulator/simulator_state.dart` (`isSimulatorActive`); `flutter/lib/ui/pages/main_container_page.dart` (`const MeasurementPage()` — no driver seam, so a true cross-tab widget test is out of scope; see Design Notes).

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/ui/organisms/developer_simulator_bar_organism.dart` -- return `const SizedBox.shrink()` from the `BlocBuilder` builder when `!isSimEnabled`; simplify the now-redundant `if (isSimEnabled)` chip guard -- the fix; makes the toolbar correct at every call site.
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- the dev `Builder` gate's `catch` resolves `active = false` (was `_isDevMode`) -- dev tooling requires a live `SimulatorBloc`; removes the stale-driver "show" path.
- [x] `flutter/test/ui/developer_simulator_bar_organism_test.dart` -- add a simulator-OFF case: pump `DeveloperSimulatorBarOrganism` with `BleSimulatorDriver` disabled (or a `SimulatorBloc` seeded `isSimulatorActive:false`), assert `find.text("⚡ DEV SIMULATOR TOOLBAR")` and `find.byType(Container)` within it `findsNothing` -- regression guard at the source (the current single test enshrines the always-render bug).
- [x] `flutter/test/ui/measurement_page_test.dart` -- confirm the existing monitoring-gate test still passes after the organism self-gates; add one assertion that the toolbar stays absent through a subsequent signal tick (no rebuild-cadence dependence) -- integrated coverage.

**Acceptance Criteria:**
- Given `DeveloperSimulatorBarOrganism` built with `SimulatorState.isSimulatorActive == false`, when it renders, then there is no `Container` and no "⚡ DEV SIMULATOR TOOLBAR" text in the tree.
- Given the monitoring screen with the simulator on, when the user turns the Simulator off, then both the toolbar and the "📊 DETECTION MECHANISM STAGE MONITOR" panel are gone and the session remains on the night-mode screen.
- Given the simulator on, when the toolbar renders, then the header and both scenario chips are present and tapping a chip still dispatches its `SimulatorScenarioStarted` / `SimulatorStopped` event.
- Given `flutter analyze` and `flutter test`, then no new analyzer issues and the full suite (incl. the new case) passes.

## Spec Change Log

- **Trigger:** human clarification during step-04 ("keep `developerEnabled` because we are still in development phase and need this indicator in demo to user"), plus 3 reviewers flagging that a `developerEnabled: true` seam + simulator-off rendered `_devStagePanel` alone while the self-gating organism collapsed.
- **Amended:** `DeveloperSimulatorBarOrganism` gained `showEvenIfInactive` (default `false`). `MeasurementPage._buildMonitoring` restores the `developerEnabled` force-show branch and passes `showEvenIfInactive: (developerEnabled == true)` so the flag forces the **complete** dev section (toolbar + stage panel), not half of it. Normal builds (`developerEnabled` unset) are unchanged: the organism self-gates on `SimulatorBloc.isSimulatorActive`, the page `Builder` keys on the same via `context.select` with `catch → false`.
- **Known-bad state avoided:** stage panel visible with no toolbar above it under the demo flag; and the reported bug (toolbar painted with the simulator off) in normal builds.
- **KEEP:** the organism self-gate (`!isSimulatorActive && !showEvenIfInactive ⟹ SizedBox.shrink()`) is the core fix — do not remove it. The `_buildMonitoring` gate's `catch` must resolve `false` (never `_isDevMode`), pinned by the "NO SimulatorBloc ancestor" discriminating test.
- **Frozen I/O Matrix row 1** ("simulator OFF ⟹ SizedBox.shrink() — any call site") now carries the `showEvenIfInactive` exception, covered by its own test.

## Design Notes

**Why self-gate at the organism, not just fix the caller.** The `MeasurementPage` gate is one point of failure with a three-layer fallback (`context.select` → `_isDevMode` getter → driver flag). A widget that must not show for a disabled simulator should enforce that itself; the caller gate becomes redundant defense for the stage panel, which genuinely has no bloc.

**Cross-tab test is out of scope.** The real user path (toggle from the Settings tab on the app-root `SimulatorBloc` while `MeasurementPage` sits offstage in `MainContainerPage`'s `IndexedStack`) can't be driven to `monitoring` in a widget test — `MainContainerPage` builds `const MeasurementPage()` with no driver injection seam. The organism-level OFF test plus the existing `measurement_page_test` toggle-off case are the coverage; a `MainContainerPage` driver seam is a separate change.

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: no new issues (2 pre-existing unused-import warnings only).
- `cd flutter && flutter test` -- expected: full suite green, including the new simulator-OFF organism case.

**Manual check:**
- Launch the app, enable the Simulator, run a session to the night-mode screen (toolbar visible), then open Settings and turn the Simulator off: the "⚡ DEV SIMULATOR TOOLBAR" and "📊 DETECTION MECHANISM STAGE MONITOR" must both disappear; the session stays running.

## Suggested Review Order

**The fix — organism self-gate**

- The core change: the toolbar renders nothing when the simulator is off, unless `showEvenIfInactive` (the demo override) is set. Correct at every call site now.
  [`developer_simulator_bar_organism.dart:38`](../../flutter/lib/ui/organisms/developer_simulator_bar_organism.dart#L38)
- The new opt-out flag + its class dartdoc.
  [`developer_simulator_bar_organism.dart:18`](../../flutter/lib/ui/organisms/developer_simulator_bar_organism.dart#L18)

**The caller gate (`MeasurementPage`)**

- Monitoring-screen `Builder`: `forced = developerEnabled == true` → show the whole dev section; else key on `context.select<SimulatorBloc>((b)=>b.state.isSimulatorActive)` with `catch → false` (never a stale-driver "show"). Passes `showEvenIfInactive: forced` so the organism and the stage panel stay in lock-step.
  [`measurement_page.dart:307`](../../flutter/lib/ui/pages/measurement_page.dart#L307)
- `_isDevMode` is now documented as **permission-bypass only** — deliberately permissive, and explicitly *not* the visibility gate.
  [`measurement_page.dart:53`](../../flutter/lib/ui/pages/measurement_page.dart#L53)

**Tests**

- Organism: off-at-mount → nothing; `showEvenIfInactive: true` → shows anyway; runtime toggle under a real `SimulatorBloc` (visible → off → hidden → on).
  [`developer_simulator_bar_organism_test.dart:40`](../../flutter/test/ui/developer_simulator_bar_organism_test.dart#L40)
- `MeasurementPage`: NO `SimulatorBloc` ancestor + `_isDevMode` true ⟹ still hidden (the test that actually pins `catch → false`); and `developerEnabled: true` + simulator off ⟹ toolbar **and** stage panel both show.
  [`measurement_page_test.dart:319`](../../flutter/test/ui/measurement_page_test.dart#L319)
