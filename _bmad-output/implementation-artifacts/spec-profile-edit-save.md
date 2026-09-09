---
title: 'ProfilePage: make Save actually persist; share one handler for the tick + "Save & Continue"'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: '1b9685c'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On `ProfilePage`, the AppBar tick icon and the "Save & Continue" button each run a separate inline closure that only shows a `SnackBar` — no field values are written anywhere. Edits are lost when the page is reopened (`ProfileBloc` is rebuilt from `UserProfileService`).

**Approach:** Extract one `_save()` method on `_ProfilePageState`. It builds a `UserProfile` from the controllers + `_bloc.state.computedBmi`, calls `UserProfileService.instance.set(...)`, then `await ProfileRepository.instance.saveUserProfile(...)` (a new simulated write, like `fetch*`). Wire both the tick and "Save & Continue" to `_save`. Unify the two snackbars into one "Medical profile saved ✓" (error snackbar on repo throw). No wizard exists, so "Continue" navigation stays a no-op.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `ProfileRepository` gains `Future<void> saveUserProfile(UserProfile profile)`; `SimulatedProfileRepository` → `Future<void>.delayed(latency)`.
- `_save()` reads straight from the eight `TextEditingController`s (not `_bloc.state`, which only tracks weight/height) plus `_bloc.state.computedBmi`. `userId` / `gender` carry over from `UserProfileService.instance.current` (fallback `'demo-user'` / `''`). Numeric parses use `int.tryParse` / `double.tryParse` with `0` fallback. Trim string fields.
- Order: `UserProfileService.instance.set(updated)` **first** (optimistic), then `await saveUserProfile`. On throw → red "Couldn't save — try again." snackbar and return (store already updated — no rollback this slice, matching `unregisterAccount`).
- `_save()` also pushes `ProfileFieldChanged(ProfileField.name, updated.fullName)` into `_bloc` so the header ("Complete your profile" ↔ name) reflects the save without a reopen.
- Guard post-`await` UI with the `State`'s `mounted`.
- Both controls call the same `_save` — the tick `IconButton(onPressed: _save)` and `AppButton(onPressed: _save)`.

**Ask First:**
- A real HTTP / persistence layer for `saveUserProfile`.
- Client-side validation (required fields, email/phone format) or a dirty-state guard before leaving the page.
- Reworking `ProfileBloc` to hold the full profile (this slice keeps its weight/height + BMI role).

**Never:**
- Persist to disk (in-memory only; a relaunch re-seeds from the demo payload via `ProfileSession.hydrate`).
- Add wizard/"Continue" navigation.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Save via tick | edit Patient Full Name, tap the AppBar ✓ | `UserProfileService.instance.current.fullName` == the edited text; "Medical profile saved ✓" snackbar; header updates to the new name |
| Save via button | edit a field, tap "Save & Continue" | identical effect to the tick (same `_save`) |
| Reopen after save | pop `ProfilePage`, push it again | fields show the saved values (`ProfileBloc(initial: UserProfileService.instance.current)`) |
| Repo write throws | `saveUserProfile` throws | store still holds the optimistic value; red "Couldn't save — try again." snackbar; no success snackbar |
| Non-numeric age/weight/height | e.g. age `"abc"` | saved as `0` for that field (`tryParse` fallback); no crash |
| Empty store on save | `UserProfileService.current == null`, user fills fields, saves | `userId` = `'demo-user'`, `gender` = `''`; the rest from the controllers |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/data/profile_repository.dart` — add `Future<void> saveUserProfile(UserProfile profile)` to the interface; `SimulatedProfileRepository` → `Future<void>.delayed(latency)`.
- `flutter/lib/ui/pages/profile_page.dart` — add `Future<void> _save()` + a `_snack(String, Color)` helper on `_ProfilePageState`. Replace the two inline `onPressed` closures (AppBar `IconButton` ~L77, `AppButton` "Save & Continue" ~L126) with `_save`. Add the `ProfileRepository` / `UserProfile` imports.
- `flutter/test/core/data/profile_repository_test.dart` — `saveUserProfile` completes.
- `flutter/test/ui/profile_page_test.dart` — `setUp` substitutes a zero-latency repo + `tearDown(ProfileRepository.reset)`. Cases: edit + tick → store updated + snackbar + header; edit + button → same; reopen shows saved values; a throwing repo → error snackbar.

## Tasks & Acceptance

**Execution:**
- [x] `profile_repository.dart` — `saveUserProfile` on interface + sim impl.
- [x] `profile_page.dart` — `_save()` + `_snack()`; both controls call `_save`; imports.
- [x] `test/core/data/profile_repository_test.dart` — `saveUserProfile` completes.
- [x] `test/ui/profile_page_test.dart` — the four cases above; repo substitution in `setUp`.

**Acceptance Criteria:**
- Given an edited Patient Full Name, when the tick is tapped, then `UserProfileService.instance.current.fullName` equals the edited text and a "Medical profile saved ✓" snackbar shows.
- Given the same edit, when "Save & Continue" is tapped, then the effect is identical (both call `_save`).
- Given a save, when `ProfilePage` is reopened, then the form shows the saved values.
- Given `saveUserProfile` throws, when a save is attempted, then a red "Couldn't save — try again." snackbar shows and no success snackbar.
- Given the suite, when `cd flutter && flutter analyze && flutter test` run, then both pass clean.

## Spec Change Log

### 2026-09-09 — review pass (patch only, no loopback)
- **patch** (edge-case): `_save()` had no in-flight guard — double-tapping the tick fired two writes + stacked snackbars. Split into `_save()` (guarded by `bool _saving`, `try/finally`) → `_persist()`. Added `profile_page_test.dart` "a second tap while a save is in flight is ignored".
- **defer**: no unsaved-changes guard when leaving `ProfilePage` (edits lost on back-nav); no field validation; the `'demo-user'` `userId` fallback — recorded in `deferred-work.md`.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. updated `profile_page_test.dart`.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: log in → Settings → Profile → change the name → tap ✓ → "Medical profile saved ✓". Back out, reopen Profile → the new name persists.

## Suggested Review Order

- The shared handler: `_save()` (in-flight guarded) → `_persist()` builds a `UserProfile` from the controllers + `_bloc.state.computedBmi`, `set()`s the store optimistically, syncs the name into `_bloc` for the header, then `await`s the write.
  [`profile_page.dart:82`](../../flutter/lib/ui/pages/profile_page.dart#L82)
- Both controls point at it — AppBar tick and "Save & Continue".
  [`profile_page.dart:133`](../../flutter/lib/ui/pages/profile_page.dart#L133)
- New simulated write.
  [`profile_repository.dart:81`](../../flutter/lib/core/data/profile_repository.dart#L81)
- Tests: tick persists + retitles header; "Save & Continue" runs the identical save; reopen shows saved values; in-flight re-tap ignored; throwing repo → error snackbar + optimistic value kept; empty-store defaults.
  [`profile_page_test.dart:65`](../../flutter/test/ui/profile_page_test.dart#L65)
