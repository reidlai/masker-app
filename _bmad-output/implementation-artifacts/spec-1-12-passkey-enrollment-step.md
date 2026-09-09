---
title: 'Story 1.12: Passkey Enrollment Step (onboarding step 3)'
type: 'feature'
created: '2026-09-10'
status: 'done'
review_loop_iteration: 0
baseline_commit: '701cc8ca432d3b8325f7e2f887772879efaacae9'
story_key: '1-12-passkey-enrollment-step'
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
  - _bmad-output/implementation-artifacts/spec-1-10-patient-account-registration.md
  - _bmad-output/implementation-artifacts/spec-1-11-medical-profile-first-run-mode.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Onboarding step 3 (`OnboardingStep.passkeyEnrollment`) is still a `_Placeholder` behind the generic "Finish" button. Nothing enrolls a passkey, and no `passkey_credential_id` is recorded, so a finished onboarding has no credential attached to the account.

**Approach:** Replace the placeholder with a real `_PasskeyEnrollmentStep` (stateful, mirroring `_RegisterStep`): a "Create Passkey" button that calls a new `ProfileRepository.enrollPasskey()` (simulated — brief delay, mints a `passkey-<micros>` id, records it on the stored `UserProfile`, returns it). On success the step stores the updated profile and dispatches `AppFlowOnboardingStepAdvanced` → `AppFlowStage.ready`. On failure it shows an inline retry and does not advance. Add `passkeyCredentialId` to `UserProfile` (+ a `copyWith`), and have `ProfileForm._persist` carry it through so a later Settings edit does not blank it. With every onboarding step now self-actioned, delete the wizard's generic Continue/Back/Finish block and the now-dead `_Placeholder` / `_labels`.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `enrollPasskey()` added to the `ProfileRepository` interface; `SimulatedProfileRepository` impl: after `latency`, require a stored `_user` (else throw), set its `passkeyCredentialId` to `passkey-<microsecondsSinceEpoch>`, return the updated profile. `fetchUserProfile()` then returns it with the id.
- `_PasskeyEnrollmentStep` renders a heading + biometric explainer + `AppButton` "Create Passkey" (`Key('onboarding-create-passkey')`), `isLoading` while in flight, re-entrant taps ignored via a `_busy` flag, `mounted`-guard after every `await`.
- The **Passkey Simulator** flag is read via `passkeySimulatorActive(developerBuild: kDebugMode || DEV_MODE)` — the same gate `main` feeds `AuthBloc`. Flag ON → simulated copy ("Simulated enrollment · developer"). Flag OFF → the explainer names the device-biometric prompt, and a `TODO(FIDO)` marks where real FIDO2/WebAuthn registration goes; until it lands both branches fall through to `enrollPasskey()` so a `DEV_MODE`-off build can still finish onboarding (mirrors `AuthBloc`'s passkey-login handling).
- On success: `UserProfileService.instance.set(updatedProfile)` then `context.read<AppFlowBloc>().add(const AppFlowOnboardingStepAdvanced())`.
- `UserProfile` gains `final String passkeyCredentialId` (default `''`), added to `props`, plus a `copyWith`. `ProfileForm._persist` sets `passkeyCredentialId: current?.passkeyCredentialId ?? ''` on the profile it writes.
- Returning users never reach this step (Story 1.9 routing unchanged).

**Ask First:**
- A real HTTP `enrollPasskey` or a server-side credential record.
- Persisting the credential id across relaunch (in-memory only, like the rest of the slice).
- Any change to `AppFlowBloc` (the last-step → `ready` transition already exists).

**Never:**
- Advance the wizard when `enrollPasskey()` threw.
- Add a Back affordance to any onboarding step — the wizard is now forward-only (register / medical profile already are).
- Verify-profile-exists or auto-bind a device on completion — split to `deferred-work.md`.
- Touch `ProfileState` / the profile form fields (`passkeyCredentialId` is not a form field).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Step 3 render | `stage==onboarding`, `step==passkeyEnrollment` | heading + explainer + "Create Passkey"; no Back / Finish / Continue | N/A |
| Create Passkey OK | tap "Create Passkey" | `enrollPasskey()` awaited → `UserProfileService.current.passkeyCredentialId` non-empty → `stage==ready`, `onboardingStep==done` | — |
| Create Passkey fails | `enrollPasskey()` throws | inline "Couldn't create your passkey — try again."; stays on `passkeyEnrollment`; button re-enabled | inline error line |
| Double tap | two taps before the first completes | one `enrollPasskey()` call, one advance | `_busy` guard |
| Flag ON vs OFF | `passkeySimulatorActive` true / false | copy differs (simulated vs biometric-prompt wording); both enroll via `enrollPasskey()` for now | — |
| Settings profile edit after enrollment | `passkeyCredentialId` set, save from `ProfilePage` | saved profile keeps the same `passkeyCredentialId` | — |
| `enrollPasskey()` with no account | repo has no stored `_user` | throws | caller surfaces the inline retry |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/profile/user_profile.dart` — add `final String passkeyCredentialId` (default `''`) to fields, ctor, and `props`; add `UserProfile copyWith({...})` covering all 12 fields.
- `flutter/lib/core/data/profile_repository.dart` — add `Future<UserProfile> enrollPasskey()` to the interface. `SimulatedProfileRepository` impl (l.115–122 pattern, next to `registerUser`): `await Future.delayed(latency)`; `final u = _user; if (u == null) throw StateError('enrollPasskey before registerUser');`; `_user = u.copyWith(passkeyCredentialId: 'passkey-${DateTime.now().microsecondsSinceEpoch}'); return _user!;`.
- `flutter/lib/ui/pages/onboarding_wizard_page.dart` — add `_PasskeyEnrollmentStep` (StatefulWidget, model on `_RegisterStep` l.145–229: `_busy`, `_error`, `_createPasskey()`). In `build`: `switch (step)` gains `OnboardingStep.passkeyEnrollment => const _PasskeyEnrollmentStep()`; **delete** `selfActioned` + the whole `if (!selfActioned) …` generic Back/Continue/Finish block, the `_Placeholder` class, and the `_labels` map (`index` stays — drives `_ProgressDots` + the AppBar `n/3` title). Add imports for `passkey_simulator_config.dart` and `package:flutter/foundation.dart` (`kDebugMode`).
- `flutter/lib/ui/organisms/profile_form.dart` — in `_persist()` `UserProfile(...)`, add `passkeyCredentialId: current?.passkeyCredentialId ?? ''` so a Settings save preserves an enrolled credential.
- `flutter/test/core/profile/user_profile_test.dart` — NEW. `copyWith` replaces only the named field; `props` includes `passkeyCredentialId` (two profiles differing only in it are unequal).
- `flutter/test/core/data/profile_repository_test.dart` — `enrollPasskey()`: mints + persists a non-empty `passkeyCredentialId` on the stored user; throws when no user; leaves other fields intact.
- `flutter/test/ui/onboarding_wizard_page_test.dart` — add `_completePasskey(tester)` helper (ensureVisible + tap "Create Passkey"). Rework "walk to ready" to end via `_completePasskey` → `stage==ready`. Add: step-3 render (no Back/Finish); enrolls → credential id set + `ready`; throwing repo → inline retry + stays; double-tap → one `enrollPasskey` call. Delete the now-invalid "Back on the passkeyEnrollment step" test.
- `flutter/test/ui/organisms/profile_form_test.dart` — add: a profile with a `passkeyCredentialId` still has it after a valid `save()`.
- `flutter/test/core/profile/profile_session_test.dart`, `flutter/test/ui/profile_page_test.dart`, `flutter/test/ui/settings_page_test.dart` — add an `enrollPasskey()` stub (`async => throw UnimplementedError();`) to each `implements ProfileRepository` fake.

## Tasks & Acceptance

**Execution:**
- [x] `user_profile.dart` — `passkeyCredentialId` field + `props` + `copyWith`.
- [x] `profile_repository.dart` — `enrollPasskey()` on the interface + `SimulatedProfileRepository`.
- [x] `onboarding_wizard_page.dart` — `_PasskeyEnrollmentStep`; wire the switch; delete the generic nav block + `_Placeholder` + `_labels`.
- [x] `profile_form.dart` — preserve `passkeyCredentialId` in `_persist()`.
- [x] `test/core/profile/user_profile_test.dart` — NEW: `copyWith` + `props`.
- [x] `test/core/data/profile_repository_test.dart` — `enrollPasskey` cases.
- [x] `test/ui/onboarding_wizard_page_test.dart` — step-3 render / enroll→ready / failure→retry / double-tap; fix walk-to-ready; drop the Back test.
- [x] `test/ui/organisms/profile_form_test.dart` — credential survives a Settings save.
- [x] `test/core/profile/profile_session_test.dart` + `test/ui/profile_page_test.dart` + `test/ui/settings_page_test.dart` — `enrollPasskey()` fake stubs.

**Acceptance Criteria:** (system-level; per-field behavior is in the I/O Matrix)
- Given the onboarding wizard, when a passkey is enrolled on step 3, then the flow reaches `AppFlowStage.ready` with `onboardingStep == done` and the stored profile carries a non-empty `passkeyCredentialId`.
- Given any onboarding step, then no "Back", "Continue", or "Finish" control is rendered — each step advances only through its own action.
- Given `ProfilePage` (Settings), when an enrolled profile is edited and saved, then its `passkeyCredentialId` is unchanged.
- Given `cd flutter && flutter analyze && flutter test`, then both pass clean.

## Spec Change Log

- **Implementation (baseline `701cc8c`):** Delivered to spec. `enrollPasskey()` on the interface + `SimulatedProfileRepository` (delay → require `_user` → `copyWith(passkeyCredentialId: 'passkey-<micros>')` → persist/return). `passkeyCredentialId` + `copyWith` on `UserProfile`. `_PasskeyEnrollmentStep` (mirrors `_RegisterStep`: `_busy`/`_error`, "Create Passkey", inline retry, `mounted` guards; copy switches on `passkeySimulatorActive`). `ProfileForm._persist` carries the credential through. Wizard cleanup: `switch` gains the `passkeyEnrollment` arm; `_Placeholder`, `_labels`, `selfActioned`, and the entire generic Back/Continue/Finish block deleted — the wizard is now forward-only. `enrollPasskey()` stubs added to the 4 `implements ProfileRepository` test fakes; the "Back on passkeyEnrollment" test dropped. Suite 294 → 304, `flutter analyze` clean.
- **Review pass (3 lenses inline vs `701cc8c`) — no loopback.** Patches: comment on the unreachable `switch` fallback; strengthened the `enrollPasskey` repo test to assert non-credential fields survive; comment on the walk-to-ready test's post-state. `AppFlowOnboardingStepBack` / `_onOnboardingBack` are retained in `AppFlowBloc` (still unit-tested from Story 1.9) though no UI dispatches them now — the spec's "no `AppFlowBloc` change" held, and the dead handler is a documented hook for future Android-back handling. No new deferred entries (the forward-only design precludes step re-entry, so a "passkey already enrolled" guard is moot).

## Design Notes

`_PasskeyEnrollmentStep` mirrors `_RegisterStep` exactly — same `_busy`/`_error` shape, same "step owns its repo call, dispatches `AppFlowOnboardingStepAdvanced` only on success" contract. The last-step → `ready` transition already lives in `AppFlowBloc._onOnboardingAdvanced` (`i == _steps.length - 1`), so no bloc change.

The Passkey Simulator flag only changes user-facing copy in this slice; both branches enroll through `enrollPasskey()`. This matches `AuthBloc`, which also falls through to a simulated success when no real authenticator is wired, keeping `DEV_MODE`-off builds able to finish onboarding. `AppFlowOnboardingStepBack` and `_onOnboardingBack` stay in the bloc (still unit-tested) even though no UI dispatches them now — a hook for future Android-back handling (already tracked in `deferred-work.md`).

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. new `user_profile_test.dart` and the updated `onboarding_wizard_page_test.dart`.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: fresh launch → passkey sign-in → register → medical profile → step 3 shows "Create Passkey". Tap → brief spinner → lands on the Dashboard (`ready`). Kill + relaunch + sign in → straight past onboarding.

## Suggested Review Order

**The enrollment seam**

- Entry point — `_PasskeyEnrollmentStep`: owns the repo call, advances only on success, inline retry on failure (mirrors `_RegisterStep`).
  [`onboarding_wizard_page.dart:94`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L94)
- `_createPasskey()` — the `_busy` guard, `mounted` checks, and the flag branch (TODO(FIDO) falls through to `enrollPasskey()` for now).
  [`onboarding_wizard_page.dart:110`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L110)
- `enrollPasskey()` on `SimulatedProfileRepository` — require an account, stamp `passkey-<micros>`, persist, return.
  [`profile_repository.dart:130`](../../flutter/lib/core/data/profile_repository.dart#L130)

**Model change + ripple**

- `passkeyCredentialId` field + `copyWith` on `UserProfile` (default `''`, in `props`).
  [`user_profile.dart:23`](../../flutter/lib/core/profile/user_profile.dart#L23)
- `ProfileForm._persist` carries the credential through so a Settings edit never blanks it.
  [`profile_form.dart:158`](../../flutter/lib/ui/organisms/profile_form.dart#L158)

**Wizard cleanup**

- `switch (step)` gains the passkey arm; `_Placeholder`, `_labels`, `selfActioned`, and the whole generic Back/Continue/Finish block are gone — every step is self-actioned.
  [`onboarding_wizard_page.dart:38`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L38)

**Tests**

- `UserProfile.copyWith` / `props` including the new field.
  [`user_profile_test.dart:1`](../../flutter/test/core/profile/user_profile_test.dart#L1)
- `enrollPasskey` — stamps + persists + leaves other fields intact; throws with no account.
  [`profile_repository_test.dart:58`](../../flutter/test/core/data/profile_repository_test.dart#L58)
- Wizard step 3 — render (no Back/Finish), enroll→ready, failure→retry, double-tap, flag-off copy.
  [`onboarding_wizard_page_test.dart:150`](../../flutter/test/ui/onboarding_wizard_page_test.dart#L150)
- Credential survives a Settings profile save.
  [`profile_form_test.dart:98`](../../flutter/test/ui/organisms/profile_form_test.dart#L98)
