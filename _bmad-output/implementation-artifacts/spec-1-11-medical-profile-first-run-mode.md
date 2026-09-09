---
title: 'Story 1.11: Medical Profile — First-Run Mode (onboarding step 2)'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: '9d893aed9e3495ef29c7cbd13dec130fd77726eb'
story_key: '1-11-medical-profile-first-run-mode'
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
  - _bmad-output/implementation-artifacts/spec-1-9-onboarding-wizard-fresh-user-routing.md
  - _bmad-output/implementation-artifacts/spec-1-10-patient-account-registration.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Onboarding step 2 (`OnboardingStep.medicalProfile`) is a "coming soon" placeholder whose generic Continue advances without collecting anything. The real medical-profile form already exists (`ProfilePage` / `MOB_USER_PROFILE`) but is welded to Settings chrome (its own `Scaffold`, `AppBar`, tick, snackbars) and has no field validation, so it cannot be dropped into the wizard as-is.

**Approach:** Extract the form body + save logic out of `ProfilePage` into a reusable `ProfileForm` organism that owns the controllers, `ProfileBloc`, validation, and the optimistic `saveUserProfile` write. `ProfilePage` keeps its Settings chrome and drives the form through a `GlobalKey<ProfileFormState>`. A new `_MedicalProfileStep` in `onboarding_wizard_page.dart` renders `ProfileForm` with an `onSaved` callback that dispatches `AppFlowOnboardingStepAdvanced`; the wizard suppresses its generic Continue/Back for this step, exactly as it already does for `register`. Add client-side validation (required + RFC 5322 email + formatted phone + positive numerics) that blocks the save and shows inline errors in both hosts.

## Boundaries & Constraints

**Always:**
- All code/commands run from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `ProfileForm` is the single owner of the 8 profile controllers, the `ProfileBloc`, `_save()`/`_persist()` (optimistic `UserProfileService.set` then `ProfileRepository.instance.saveUserProfile`), and validation. `ProfilePage` and `_MedicalProfileStep` compose it — neither re-implements save.
- Preserve the atomic-design hierarchy: the shared widget lives in `lib/ui/organisms/`.
- Validation runs on save in both hosts. Invalid → per-field inline error text, no persist, no advance, no snackbar. Valid → persist.
- On a write failure `ProfileForm` shows "Couldn't save — try again." in both hosts. On success it calls `onSaved` when supplied (onboarding: advance, no toast); otherwise it shows "Medical profile saved ✓" (Settings).
- `_MedicalProfileStep` renders no `AppBar`/tick and no generic Continue/Back. The progress dots still show step 2/3.
- Returning users never reach this step (Story 1.9 routing unchanged).

**Ask First:**
- Making caregiver name/phone anything other than required first-run.
- A real HTTP validation call or a server-side consent/PHI record.
- Unit-conversion (kg/lb, cm/ft-in) handling — out of this slice.

**Never:**
- Advance the wizard, or show the success toast, when validation failed or `saveUserProfile` threw.
- Change `AppFlowBloc`, `UserProfile`, `ProfileBloc`, or the Medical Profile / Passkey step ordering.
- Preserve entered-but-unsaved data across a Back into this step (deferred — see `deferred-work.md`).
- Add a mode enum to `ProfilePage`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Step 2 render | `stage==onboarding`, `step==medicalProfile` | `ProfileForm` shows (header + demographics + caregiver + "Save & Continue"); no AppBar tick; no generic Continue/Back | N/A |
| Valid save (onboarding) | all fields valid, tap "Save & Continue" | `saveUserProfile` awaited → `UserProfileService.current` reflects entered values → `onboardingStep==passkeyEnrollment`; no success snackbar | — |
| Invalid field | email `"abc"`, or empty name, or age `"0"` | inline error under each offending field; nothing persists; step stays `medicalProfile` | inline `errorText` |
| Save write fails | `saveUserProfile` throws | "Couldn't save — try again." snackbar; store keeps the optimistic value; no advance | red snackbar |
| Double tap | two taps before the first completes | one `saveUserProfile` call, one advance | `_saving` guard |
| Valid save (Settings) | `ProfilePage`, all fields valid, tap tick or "Save & Continue" | persist → "Medical profile saved ✓"; stays on `ProfilePage` | — |
| Invalid save (Settings) | `ProfilePage`, blank required field, tap tick | inline error; nothing persists; no snackbar | inline `errorText` |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/pages/profile_page.dart` — today owns the 8 controllers + `ProfileBloc` + `_save`/`_persist`/`_snack` (l.22–119) and renders the 3 organisms + "Save & Continue" (l.121–192). Reduce to: `Scaffold` + `AppBar("Medical Profile")` + tick `IconButton` calling `_formKey.currentState?.save()` + `body: ProfileForm(formKey: _formKey)`. No bloc/controllers left here.
- `flutter/lib/ui/organisms/profile_form.dart` — NEW. `ProfileForm({Key? formKey, VoidCallback? onSaved})` with a **public** `ProfileFormState` exposing `Future<void> save()`. Holds the 8 `TextEditingController`s, `ProfileBloc(initial: UserProfileService.instance.current)`, the `_onDemographicsChanged` weight/height mirror (was profile_page.dart:62–68), `_saving` guard, an `_errors` map keyed by field, and `_persist()` (build `UserProfile` from controllers + `_bloc.state.computedBmi`, optimistic `UserProfileService.instance.set`, `ProfileFieldChanged(name)` header sync, `await ProfileRepository.instance.saveUserProfile`). Renders `UserHeaderOrganism` + `HealthDemographicsOrganism` + `EmergencyContactOrganism` + `AppButton("Save & Continue")` inside a `SingleChildScrollView` — **no `Scaffold`/`AppBar`**. `save()`: `_saving` early-return; `_validate()`; if errors → `setState`, return; else `_persist()`; on success → `onSaved?.call()` ?? success snackbar; on throw → failure snackbar. `mounted`-guard after every `await`.
- `flutter/lib/core/validation/profile_validators.dart` — NEW. Pure `String?` functions (null = valid): `requiredError`, `emailError` (pragmatic RFC 5322 subset regex), `phoneError` (strip `() + - space`, require ≥ 10 digits), `positiveNumberError` (`double.tryParse` > 0), `ageError` (int 1–149).
- `flutter/lib/ui/atoms/app_input_field.dart` — add optional `String? errorText` forwarded to `InputDecoration.errorText` (default null → identical rendering; no other change).
- `flutter/lib/ui/organisms/health_demographics_organism.dart` + `emergency_contact_organism.dart` — add one optional `String? xxxError` param per field, forwarded to the matching `AppInputField`. No behavior change when omitted.
- `flutter/lib/ui/pages/onboarding_wizard_page.dart` — add `_MedicalProfileStep` (renders `ProfileForm(onSaved: () => context.read<AppFlowBloc>().add(const AppFlowOnboardingStepAdvanced()))`). In `build`: body ternary gains the `medicalProfile` → `_MedicalProfileStep` case; the generic Continue/Back block is gated on `step != OnboardingStep.register && step != OnboardingStep.medicalProfile`; delete the now-dead `_labels[OnboardingStep.medicalProfile]` entry.
- `flutter/test/ui/profile_page_test.dart` — retarget the "save from an empty store: userId defaults, non-numeric age → 0" test to assert validation now blocks the save (inline error, store unchanged). The demo-seeded tests still pass (`demoUserProfile` is complete).
- `flutter/test/ui/onboarding_wizard_page_test.dart` — add step-2 tests (render; valid → advance to `passkeyEnrollment` + store updated + no success snackbar; invalid → blocked + stays; throwing repo → snackbar + stays). Replace the walk-to-ready path's Continue tap with a `_completeMedicalProfile(tester)` helper that fills valid values and taps "Save & Continue".
- `flutter/test/core/validation/profile_validators_test.dart` — NEW. Table tests per validator.
- `flutter/test/ui/organisms/profile_form_test.dart` — NEW. Renders the 3 organisms; `save()` persists when valid; sets inline errors when invalid; `onSaved` fires only on success; failure snackbar on a throwing repo.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/validation/profile_validators.dart` — pure validators (required / email / phone / positive number / age).
- [x] `flutter/lib/ui/atoms/app_input_field.dart` — optional `errorText` passthrough.
- [x] `flutter/lib/ui/organisms/health_demographics_organism.dart` + `flutter/lib/ui/organisms/emergency_contact_organism.dart` — optional per-field `errorText` params.
- [x] `flutter/lib/ui/organisms/profile_form.dart` — extract controllers + `ProfileBloc` + `_persist` + validation from `ProfilePage`; expose `ProfileFormState.save()`; `onSaved`/snackbar branching.
- [x] `flutter/lib/ui/pages/profile_page.dart` — reduce to Settings chrome + `GlobalKey<ProfileFormState>`; tick calls `save()`.
- [x] `flutter/lib/ui/pages/onboarding_wizard_page.dart` — `_MedicalProfileStep`; wire body + suppress generic controls for `medicalProfile`; drop dead label.
- [x] `flutter/test/core/validation/profile_validators_test.dart` — table tests.
- [x] `flutter/test/ui/organisms/profile_form_test.dart` — form render / save / validation / `onSaved`.
- [x] `flutter/test/ui/onboarding_wizard_page_test.dart` — step-2 render / valid→advance / invalid→blocked / repo-throws; fix walk-to-ready helper.
- [x] `flutter/test/ui/profile_page_test.dart` — retarget the junk-save test to blocked-by-validation.

**Acceptance Criteria:** (system-level; per-field behavior is in the I/O Matrix)
- Given onboarding step 2 renders, then the profile form shows a "Save & Continue" button and no AppBar tick and no generic Continue/Back, and the progress dots read 2/3.
- Given the wizard reached step 2, when a valid profile is saved, then it advances to `passkeyEnrollment`; when a Back is issued afterwards, then it returns to step 2 (no data-preservation guarantee).
- Given the Settings edit path, then every pre-existing `profile_page_test.dart` behavior holds except the retargeted junk-save test.
- Given `cd flutter && flutter analyze && flutter test`, then both pass clean.

## Spec Change Log

- **Implementation (baseline `9d893ae`):** Delivered to spec. `ProfileForm` organism extracted (owns the 8 controllers, `ProfileBloc`, validation, optimistic save); `ProfilePage` reduced to Settings chrome driving it via a plain `GlobalKey<ProfileFormState>` (the standard `key:` param — an equivalent realization of the Code Map's `formKey`); `_MedicalProfileStep` added to the wizard with generic Continue/Back suppressed for `medicalProfile`; `profile_validators.dart` + `AppInputField.errorText` + per-field `errorText` on both organisms. One pre-existing `profile_page_test.dart` "junk save" test retargeted to assert validation now blocks it. Suite: 252 → 293 pass, `flutter analyze` clean.
- **Review pass (3 lenses inline vs `9d893ae`) — no loopback.** Patches applied: (1) `ProfileForm` gained a `padding` param so the wizard step uses vertical-only inset (no more 44 px double horizontal inset vs the other steps); (2) `profile_validators.dart` header comment `///`→`//` (drop the `library;` lint shim); (3) wizard render test now also asserts the `2/3` title; (4) `profile_form_test.dart` invalid-field test hits two fields and a new test covers correct-then-re-save clearing the error (suite 293 → 294). Deferred (pre-existing / out of frozen scope): stale-inline-error-while-typing (needs per-field `onChanged` plumbing through the organisms), and plausible-range bounds on weight/height. Both logged to `deferred-work.md`.
- **Note (not a defect):** Back from Passkey Enrollment rebuilds `_MedicalProfileStep` fresh, so it re-seeds from `UserProfileService.instance.current` — which holds the profile saved on the way forward. The form therefore shows the *saved* values, not a blank form; only edits made-then-not-saved are lost (the deferred gap).

## Design Notes

`ProfileForm` mirrors Story 1.10's `_RegisterStep` split: the step widget owns the repo call; the host supplies the post-success action via `onSaved`. `ProfilePage` reaches `save()` through a `GlobalKey<ProfileFormState>` because the tick is an `AppBar` action structurally outside the form body — the standard idiom, less coupling than a callback handshake.

`emailError` uses the common pragmatic RFC 5322 subset regex, not the full grammar. `phoneError` normalises `( ) + - space` then requires ≥ 10 digits.

Snackbar branching: when `onSaved` is supplied the success toast is skipped (the wizard is disposing the step); the failure toast still fires because the form stays mounted on failure.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. new `profile_validators_test.dart`, `profile_form_test.dart`, and updated `onboarding_wizard_page_test.dart` / `profile_page_test.dart`.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: fresh launch → Sign in with Passkey → step 1 (register) → step 2 shows the full profile form. Leave email blank → "Save & Continue" → inline error, no advance. Fill valid values → advances to step 3 (Passkey placeholder). Open Settings → Medical Profile: the tick still saves with the green "Medical profile saved ✓".

## Suggested Review Order

**Shared form (the design core)**

- Entry point — the split: `ProfileForm` owns controllers + bloc + validation + save; hosts pass only chrome + `onSaved`.
  [`profile_form.dart:29`](../../flutter/lib/ui/organisms/profile_form.dart#L29)
- `save()` — validate-first gate: invalid → inline errors, no persist; valid → `_saving` guard → `_persist()`.
  [`profile_form.dart:124`](../../flutter/lib/ui/organisms/profile_form.dart#L124)
- `_persist()` — optimistic `set` then repo write; on success `onSaved?.call()` **or** the success snackbar, never both.
  [`profile_form.dart:142`](../../flutter/lib/ui/organisms/profile_form.dart#L142)
- `_validate()` — the eight-field map that drives `_errors` → per-field `errorText`.
  [`profile_form.dart:105`](../../flutter/lib/ui/organisms/profile_form.dart#L105)

**Validation rules**

- Pure `String?` validators, one source of truth for both hosts and the unit tests.
  [`profile_validators.dart:19`](../../flutter/lib/core/validation/profile_validators.dart#L19)
- Pragmatic RFC 5322 subset regex — documented as not the full grammar.
  [`profile_validators.dart:13`](../../flutter/lib/core/validation/profile_validators.dart#L13)

**Host wiring**

- Wizard step 2 — `ProfileForm` with `onSaved` = advance; vertical-only padding (sits inside the wizard inset).
  [`onboarding_wizard_page.dart:130`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L130)
- `selfActioned` — register **and** medicalProfile suppress the generic Continue/Back.
  [`onboarding_wizard_page.dart:40`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L40)
- `switch (step)` body — medicalProfile → `_MedicalProfileStep`, everything else unchanged.
  [`onboarding_wizard_page.dart:60`](../../flutter/lib/ui/pages/onboarding_wizard_page.dart#L60)
- `ProfilePage` reduced to Settings chrome; the AppBar tick drives the form via `GlobalKey<ProfileFormState>`.
  [`profile_page.dart:17`](../../flutter/lib/ui/pages/profile_page.dart#L17)

**Atom / organism plumbing**

- `AppInputField.errorText` → `InputDecoration.errorText` (default null = unchanged).
  [`app_input_field.dart:13`](../../flutter/lib/ui/atoms/app_input_field.dart#L13)
- Per-field optional `errorText` params, forwarded to the matching input.
  [`health_demographics_organism.dart:15`](../../flutter/lib/ui/organisms/health_demographics_organism.dart#L15)

**Tests**

- Validator table tests.
  [`profile_validators_test.dart:1`](../../flutter/test/core/validation/profile_validators_test.dart#L1)
- `ProfileForm` in isolation — render / save / invalid / `onSaved` / re-entrancy / fix-then-resave.
  [`profile_form_test.dart:1`](../../flutter/test/ui/organisms/profile_form_test.dart#L1)
- Wizard step 2 — render (no tick / no generic controls), valid→advance, invalid→blocked, write-fail→snackbar.
  [`onboarding_wizard_page_test.dart:150`](../../flutter/test/ui/onboarding_wizard_page_test.dart#L150)
- Retargeted junk-save test → now asserts validation blocks it.
  [`profile_page_test.dart:125`](../../flutter/test/ui/profile_page_test.dart#L125)
