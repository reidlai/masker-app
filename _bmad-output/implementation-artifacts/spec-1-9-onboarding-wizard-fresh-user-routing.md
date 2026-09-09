---
title: 'Story 1.9: First-Run Onboarding Wizard & Fresh-User Routing'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'da54b39'
story_key: '1-9-first-run-onboarding-wizard-and-fresh-user-routing'
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** After login the app always goes straight to the tab shell. A new / just-unregistered user has no profile, yet `SimulatedProfileRepository.fetchUserProfile()` always re-seeds the demo `David Miller` payload, so there is no way to reach onboarding. Epic 1 stories reference "the onboarding wizard chain" but nothing owns the wizard shell or the fresh-vs-returning routing.

**Approach:** Add `AppFlowStage.onboarding` + a step enum to `AppFlowState`. `SimulatedProfileRepository` becomes stateful — it holds the current `UserProfile?` / `DeviceProfile?` (default **null** = new user); `saveUserProfile` / `unregisterUser` mutate it; a `SimulatedProfileRepository.seededReturningUser()` factory restores the demo payload for the returning-user path. `main`'s `onLoginSuccess` reports `needsOnboarding` (= `UserProfileService.current == null` after hydrate) on `AppFlowLoginSucceeded`; `AppFlowBloc` routes to `onboarding` when set, else the existing permission-check → `ready` path. A new `OnboardingWizardPage` renders a 4-step stepper (Register / Medical Profile / Passkey Enrollment / Ready) with **placeholder step bodies** (Stories 1.10–1.12 fill them), driven by `AppFlowBloc` step events; completing the last step transitions to `ready`.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `AppFlowStage.onboarding` added; `AppFlowState` gains `OnboardingStep onboardingStep` (enum `register`, `medicalProfile`, `passkeyEnrollment`, `done`; default `register`) + `copyWith`.
- `AppFlowLoginSucceeded` gains `bool needsOnboarding` (default `false`, so every existing `const AppFlowLoginSucceeded()` and the retry path keep today's behaviour). `main`'s `onLoginSuccess` passes `needsOnboarding: UserProfileService.instance.current == null` (evaluated after `await ProfileSession.hydrate()`).
- `AppFlowBloc._onLoginSucceeded`: after the re-entrancy guard, `if (event.needsOnboarding) → emit(stage: onboarding, onboardingStep: register); return;` before the permission check.
- New events `AppFlowOnboardingStepAdvanced` / `AppFlowOnboardingStepBack`: advance/retreat `onboardingStep` across the enum; advancing past `passkeyEnrollment` → `emit(stage: ready)`. `Back` on `register` is a no-op.
- `AppFlowLogoutRequested` still `emit(const AppFlowState())` — resets stage **and** `onboardingStep`.
- `SimulatedProfileRepository`: private `_user` / `_device` fields (ctor `seedUser` / `seedDevice`, both default `null`); `fetchUserProfile`/`fetchDeviceProfile` return them; `saveUserProfile(p)` sets `_user = p`; `unregisterUser()` sets both `null`; `unbindDevice()` sets `_device = null`. `factory SimulatedProfileRepository.seededReturningUser()` → seeded with `demoUserProfile` / `demoDeviceProfile`. `ProfileRepository.reset()` → the plain (new-user) constructor.
- `main.dart` `_buildHome`: `case AppFlowStage.onboarding: return const OnboardingWizardPage();`.
- `OnboardingWizardPage` (`lib/ui/pages/onboarding_wizard_page.dart`): `BlocBuilder<AppFlowBloc, AppFlowState>`; a progress indicator (4 steps) + the current step's placeholder body (keyed `Key('onboarding-step-<name>')`, text naming the owning story) + "Continue" (→ `AppFlowOnboardingStepAdvanced`) and, when `onboardingStep != register`, "Back" (→ `AppFlowOnboardingStepBack`). No bottom nav (it is the `home:`, not inside `MainContainerPage`).

**Ask First:**
- Real step content / screens for Register, Medical Profile, Passkey Enrollment (Stories 1.10 / 1.11 / 1.12).
- Cross-relaunch resumability (needs persistence — see Design Notes; this slice is session-only).

**Never:**
- Persist onboarding progress or the registered flag to disk.
- Add `MOB_DEVICE_PAIRING` / BLE-permission steps (Epic 2).
- Return `demoUserProfile` from `fetchUserProfile()` by default (only via `seededReturningUser()`).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| New user login | `fetchUserProfile()` → `null` (default repo) | `onLoginSuccess` sets `needsOnboarding: true` → `AppFlowBloc.stage == onboarding`, `onboardingStep == register`; `main` renders `OnboardingWizardPage` |
| Returning user login | repo `seededReturningUser()` (or a prior `saveUserProfile`) | `needsOnboarding: false` → existing `checkingPermission` → `ready`/`needsPrimer` path; no wizard |
| Advance through steps | `AppFlowOnboardingStepAdvanced` ×3 from `register` | `onboardingStep` → `medicalProfile` → `passkeyEnrollment` → (4th advance) `stage == ready` |
| Back | `AppFlowOnboardingStepBack` from `medicalProfile` | `onboardingStep == register`; from `register` → no-op |
| Unregister → re-login | `unregisterUser()` then login | `fetchUserProfile()` → `null` → onboarding again (not Home) |
| Save then re-login | `saveUserProfile(p)` then login | `fetchUserProfile()` → `p` → `ready` (onboarding skipped) |
| Logout mid-onboarding | `AppFlowLogoutRequested` while `stage == onboarding` | `stage == loggedOut`, `onboardingStep == register` |
| Retry after permission failure | `AppFlowPermissionRetryRequested` | unchanged — retries with `needsOnboarding: false` |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/bloc/app_flow/app_flow_state.dart` — `AppFlowStage.onboarding`; `OnboardingStep` enum; `onboardingStep` field + `copyWith` + `props`.
- `flutter/lib/core/bloc/app_flow/app_flow_event.dart` — `needsOnboarding` on `AppFlowLoginSucceeded`; new `AppFlowOnboardingStepAdvanced` / `AppFlowOnboardingStepBack`.
- `flutter/lib/core/bloc/app_flow/app_flow_bloc.dart` — onboarding branch in `_onLoginSucceeded`; handlers for the two step events (advance-past-last → `ready`).
- `flutter/lib/core/data/profile_repository.dart` — `SimulatedProfileRepository` stateful (`_user`/`_device`, `seedUser`/`seedDevice` ctor, `seededReturningUser()` factory); `fetch*` return fields; `saveUserProfile`/`unregisterUser`/`unbindDevice` mutate. `ProfileRepository.reset()` → new-user ctor.
- `flutter/lib/ui/pages/onboarding_wizard_page.dart` — NEW. Stepper + placeholder bodies + Continue/Back.
- `flutter/lib/main.dart` — `onLoginSuccess` passes `needsOnboarding`; `_buildHome` `onboarding` case.
- Tests: `flutter/test/core/bloc/app_flow_bloc_test.dart` (onboarding routing, step advance/back, past-last→ready, logout reset), `flutter/test/core/data/profile_repository_test.dart` (default null, `saveUserProfile` then fetch, `unregisterUser` clears, `seededReturningUser`), `flutter/test/core/profile/profile_session_test.dart` + `flutter/test/session_flow_test.dart` + `flutter/test/app_flow_test.dart` (seed a returning user where they assert the tab-shell path; add a new-user → wizard case), new `flutter/test/ui/onboarding_wizard_page_test.dart` (renders per step, Continue/Back dispatch, last step → ready).

## Tasks & Acceptance

**Execution:**
- [x] `app_flow_state.dart` — stage + `OnboardingStep` + field/copyWith.
- [x] `app_flow_event.dart` — `needsOnboarding` + two step events.
- [x] `app_flow_bloc.dart` — routing branch + step handlers.
- [x] `profile_repository.dart` — stateful `SimulatedProfileRepository` + `seededReturningUser()`.
- [x] `onboarding_wizard_page.dart` — NEW stepper with placeholder bodies.
- [x] `main.dart` — wire `needsOnboarding` + the `_buildHome` case.
- [x] tests — new `app_flow_bloc` / `onboarding_wizard_page` cases; fix `profile_repository` / `profile_session` / `session_flow` / `app_flow_test` for the null-default repo.

**Acceptance Criteria:**
- Given a new user (default repo), when login completes, then `AppFlowBloc.state.stage == onboarding` and `OnboardingWizardPage` renders at step `register`.
- Given a returning user (seeded / previously saved), when login completes, then the flow reaches `ready` without the wizard.
- Given the wizard, when "Continue" is tapped on each step, then the step advances; on the last step the app transitions to `ready` / `MOB_HOME`.
- Given "Back" beyond the first step, then the wizard returns to the previous step; on the first step it is a no-op.
- Given `unregisterAccount` then a re-login, then onboarding is entered again (not Home).
- Given the suite, when `cd flutter && flutter analyze && flutter test` run, then both pass clean.

## Spec Change Log

### 2026-09-09 — review pass (patches only, no loopback)
- **patch** (edge-case): `needsOnboarding` was `UserProfileService.current == null` after `hydrate()`, but `hydrate()` also clears the store on a fetch **error** — a returning user with a login-time blip would be dumped into onboarding. `ProfileSession.hydrate()` now returns `bool` = *cleanly known-absent* (a fetch error returns `false`); `main` passes that through. `profile_session_test.dart` updated + a throwing-repo → `false` case.
- **patch**: placeholder step text "Content arrives in Story 1.10" → neutral "This step is coming soon." (story references kept as code comments).
- **defer**: no back-press / `PopScope` handling on the onboarding root — recorded in `deferred-work.md` (belongs with the 1.10–1.12 step screens).

## Design Notes

`needsOnboarding` is carried on the event (not read from `UserProfileService` inside the bloc) to keep `AppFlowBloc` decoupled from the profile singletons — `main` already `await`s `hydrate()` before dispatching, so `UserProfileService.instance.current` is settled at that point.

`OnboardingStep` lives in `AppFlowState` (not the wizard's local state) so the step survives widget rebuilds and is bloc-testable. **Cross-relaunch** resumability is out of scope: nothing persists, so a kill+relaunch restarts at `loggedOut` → login → `fetchUserProfile()` still `null` → onboarding from `register`. Acceptable — full resumability needs the persistence layer (deferred).

Step bodies are deliberately placeholders (`"Register — Story 1.10"`, etc.); 1.10–1.12 replace each with its real screen and its repo call, then wire that step's completion to `AppFlowOnboardingStepAdvanced`.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. new + updated suites.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: fresh launch → Sign in with Passkey → **Onboarding wizard** (step 1 placeholder), not the dashboard. Tap Continue ×4 → Home. Settings → Unregister → sign in again → wizard again.
- A returning user (after completing the wizard / a save) → login goes straight to Home.

## Suggested Review Order

**Routing (design intent)**

- `hydrate()` now returns *cleanly known-absent*; a fetch error returns `false` so a login blip can't force onboarding.
  [`profile_session.dart:18`](../../flutter/lib/core/profile/profile_session.dart#L18)
- `main` passes that through as `needsOnboarding`; `_buildHome` renders the wizard for the new stage.
  [`main.dart:74`](../../flutter/lib/main.dart#L74)
- `AppFlowBloc`: onboarding branch (before the permission check) + the two step handlers (advance-past-last → `ready`).
  [`app_flow_bloc.dart:71`](../../flutter/lib/core/bloc/app_flow/app_flow_bloc.dart#L71)
  [`app_flow_bloc.dart:34`](../../flutter/lib/core/bloc/app_flow/app_flow_bloc.dart#L34)

**Repository + wizard**

- `SimulatedProfileRepository` is now stateful — empty by default (new user); `seededReturningUser()` restores the demo payload.
  [`profile_repository.dart:76`](../../flutter/lib/core/data/profile_repository.dart#L76)
- The wizard shell: `BlocBuilder<AppFlowBloc>` → progress dots + placeholder body + Continue/Back.
  [`onboarding_wizard_page.dart:12`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L12)

**Tests**

- Bloc: routing, advance→ready, back, logout-reset, ignore-outside-stage.
  [`app_flow_bloc_test.dart`](../../flutter/test/core/bloc/app_flow_bloc_test.dart)
- Full tree: new user → wizard; returning user → Home; unregister → sign in again → wizard.
  [`session_flow_test.dart`](../../flutter/test/session_flow_test.dart)
- Widget: per-step render, Continue/Back, last step → ready.
  [`onboarding_wizard_page_test.dart`](../../flutter/test/ui/onboarding_wizard_page_test.dart)
