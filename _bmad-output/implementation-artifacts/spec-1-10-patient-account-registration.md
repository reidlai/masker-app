---
title: 'Story 1.10: Patient Account Registration (onboarding step 1)'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'c82669b'
story_key: '1-10-patient-account-registration'
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
  - _bmad-output/implementation-artifacts/spec-1-9-onboarding-wizard-fresh-user-routing.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Onboarding step 1 (`OnboardingStep.register`) is a placeholder — "This step is coming soon." + a generic Continue that advances without creating anything. There is no account-creation call, so `UserProfileService` is still empty when the wizard advances.

**Approach:** Add `ProfileRepository.registerUser()` (simulated → mint a `UserProfile` with a fresh `userId` and empty PHI, store it). Replace the `register` step body in `OnboardingWizardPage` with a real step: a short HIPAA §164.312 consent line + a checkbox, and a "Create account" button that is disabled until the box is checked. On tap it awaits `registerUser()`, `UserProfileService.instance.set(profile)`, then dispatches `AppFlowOnboardingStepAdvanced` (→ Medical Profile). A failure shows an inline error and stays on the step. The `register` step has no generic Continue/Back.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `ProfileRepository` gains `Future<UserProfile> registerUser()`. `SimulatedProfileRepository`: after `latency`, set `_user = UserProfile(userId: 'user-<microsecondsSinceEpoch>', /* all PHI fields empty/0 */)` and return it (subsequent `fetchUserProfile()` returns it).
- `OnboardingWizardPage`: when `step == OnboardingStep.register`, render a stateful `_RegisterStep` in place of the placeholder body **and** render no generic Continue/Back. Other steps keep the placeholder + Continue (+ Back when `index > 0`).
- `_RegisterStep` (in `onboarding_wizard_page.dart`): a `CheckboxListTile` (`Key('onboarding-consent-checkbox')`) for "I agree to the HIPAA privacy & data terms"; an `AppButton` "Create account" (`Key('onboarding-create-account')`), `onPressed: null` until checked, `isLoading` while the call is in flight (re-entrant taps ignored via a `_busy` flag).
- On "Create account": `await ProfileRepository.instance.registerUser()` → `UserProfileService.instance.set(profile)` → `context.read<AppFlowBloc>().add(const AppFlowOnboardingStepAdvanced())`. On throw → `setState` an error line ("Couldn't create your account — try again.") and do **not** advance. `mounted`-guard every post-`await` use.
- Root of the register body keeps `Key('onboarding-step-register')` (wizard tests / `_ProgressDots` unaffected).
- Returning users never see this — Story 1.9 routes them past onboarding.

**Ask First:**
- Collecting any identity field here (name/email/etc.) — that is Story 1.11's Medical Profile step.
- A real HTTP `registerUser` / a backend consent record.
- Persisting the consent flag.

**Never:**
- Advance the wizard when `registerUser()` failed.
- Change `AppFlowBloc` (registration is a step-widget concern; the bloc stays navigation-only) or the Medical Profile / Passkey placeholders.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Register step render | `stage == onboarding`, `step == register` | consent checkbox + disabled "Create account"; no "Continue"/"Back" |
| Consent toggled on | tap the checkbox | "Create account" becomes enabled |
| Create account, repo OK | consent checked, tap "Create account" | `registerUser()` awaited → `UserProfileService.current` non-null with a non-empty `userId` and empty PHI → `onboardingStep == medicalProfile` |
| Create account, repo throws | `registerUser()` throws | inline "Couldn't create your account — try again."; `onboardingStep` stays `register`; store unchanged |
| Double tap | two taps before the first completes | one `registerUser()` call, one advance |
| Returning user | `needsOnboarding == false` | wizard never shown (unchanged from 1.9) |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/data/profile_repository.dart` — add `Future<UserProfile> registerUser()` to the interface; `SimulatedProfileRepository` implementation (mint + store + return). Reuse a private id helper.
- `flutter/lib/ui/pages/onboarding_wizard_page.dart` — split the `build` body into `_stepBody(step)` / step controls; add `_RegisterStep` (StatefulWidget: consent checkbox, "Create account", `_busy` guard, error line); register step renders `_RegisterStep` with no generic Continue/Back.
- Tests:
  - `flutter/test/core/data/profile_repository_test.dart` — `registerUser()` returns a `UserProfile` with a non-empty `userId` + empty PHI, and stores it (`fetchUserProfile()` then returns it).
  - `flutter/test/ui/onboarding_wizard_page_test.dart` — register step: checkbox + disabled button + no Continue; check → enabled; tap → store populated + advance to `medicalProfile`; a throwing repo → error line + stays on `register`; adjust the "walk to ready" test to complete the register step first (helper).

## Tasks & Acceptance

**Execution:**
- [ ] `profile_repository.dart` — `registerUser()` on interface + sim impl.
- [ ] `onboarding_wizard_page.dart` — `_RegisterStep` + wire it as the register body; drop the generic controls for `register`.
- [ ] `test/core/data/profile_repository_test.dart` — `registerUser` cases.
- [ ] `test/ui/onboarding_wizard_page_test.dart` — register-step render / success / failure / re-tap; fix the walk-to-ready test.

**Acceptance Criteria:**
- Given the register step, when consent is unchecked, then "Create account" is disabled and there is no "Continue".
- Given consent is checked and "Create account" is tapped and `registerUser()` succeeds, then `UserProfileService.instance.current` is non-null with a non-empty `userId` and the wizard advances to `medicalProfile`.
- Given `registerUser()` throws, then an inline error shows and the wizard stays on `register`.
- Given the suite, when `cd flutter && flutter analyze && flutter test` run, then both pass clean.

## Spec Change Log

- **Implementation (baseline `c82669b`):** Delivered as specified. `registerUser()` added to the `ProfileRepository` interface + `SimulatedProfileRepository` (mints `UserProfile(userId: 'user-<microsecondsSinceEpoch>')`, stores it, returns it). `_RegisterStep` (stateful) replaces the `register` placeholder: HIPAA §164.312 line, consent `CheckboxListTile`, disabled "Create account" until checked, `_busy` re-entrancy guard, inline error line on failure, `mounted` guards after every `await`. Generic Continue/Back suppressed for the `register` step only. All pre-existing repo/profile test fakes gained a `registerUser()` stub.
- **Review pass (3 lenses inline vs `c82669b`) — no patch.** Every finding was already tested, minor, or spec-documented (the "completes registration then quits mid-onboarding resumes past the wizard" behavior is the Design Notes trade-off, deferred). Added one test for the I/O matrix's "Double tap" row (previously guarded by `_busy` but not verified): `_CountingRegisterRepository` (200 ms latency, counts `registerUser` calls) → two rapid taps → asserts exactly one call and a single advance to `medicalProfile`. Suite: 252 pass, `flutter analyze` clean.

## Suggested Review Order

1. `flutter/lib/core/data/profile_repository.dart` — the `registerUser()` contract: mint-and-store, id-only `UserProfile`, no PHI.
2. `flutter/lib/ui/pages/onboarding_wizard_page.dart` — `_RegisterStep` state machine (`_consented` / `_busy` / `_error`), the success path (`set` → `AppFlowOnboardingStepAdvanced`), and that the generic controls are gone for `register` only.
3. `flutter/test/ui/onboarding_wizard_page_test.dart` — render / success / failure / double-tap / Back-from-medicalProfile.
4. `flutter/test/core/data/profile_repository_test.dart` — `registerUser` mints + persists.
5. The `registerUser()` stubs across `profile_session_test.dart`, `profile_page_test.dart`, `settings_page_test.dart`, `profile_repository_test.dart` — mechanical fake conformance only.

## Design Notes

Keeping the `registerUser()` call in `_RegisterStep` (not `AppFlowBloc`) mirrors how `ProfilePage._save` and `SettingsActions` own their repo calls — `AppFlowBloc` stays a pure navigation state machine. The step dispatches `AppFlowOnboardingStepAdvanced` only on success.

`UserProfile` minted by `registerUser()` has an id but no PHI; Story 1.11 fills the identity fields via the existing `saveUserProfile` path, and the profile persists across the wizard (and a re-login → `fetchUserProfile()` returns it → `needsOnboarding == false`, so a user who completes registration but quits mid-onboarding resumes past the wizard — acceptable; full step-level resumability is deferred).

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. updated `onboarding_wizard_page_test.dart`.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: fresh launch → Sign in with Passkey → onboarding step 1 shows the consent checkbox + a disabled "Create account". Check the box → tap → step 2 (Medical Profile placeholder). Kill + relaunch + sign in → lands past the wizard (account now exists).
