---
title: 'Wire ProfilePage + Home to the profile stores; seed at login; fix unregister-doesn''t-logout'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: '00352b0'
context:
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/implementation-artifacts/spec-profile-stores-reset-seam.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `UserProfileService` / `DeviceProfileService` exist but nothing populates or reads them — `ProfilePage` renders its own hard-coded `ProfileBloc` demo data and Home's device card is driven by `SimulatorBloc.isSimulatorActive`. So Unbind / Unregister / Log out clear stores that are invisible, and Unregister doesn't even log the user out.

**Approach:** Add `ProfileRepository.fetch*` (simulated → return the current demo data). Seed both stores once at login via a `ProfileSession.hydrate()` step. Move `ProfileState`'s hard-coded defaults out to that demo payload; `ProfileBloc` takes an optional initial `UserProfile` and `ProfilePage` hydrates its form from `UserProfileService` (blank / "complete your profile" when `null`). Gate Home's device card on `DeviceProfileService` (`null` → the existing "D-BAND not found" state). Fix `SettingsActions.unregisterAccount` to clear **both** stores and dispatch `AppFlowLogoutRequested` (drop the stale `popUntil`). No onboarding flow (deferred G3) — logout / unregister still land on the existing `LoginPage`.

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- `ProfileRepository` gains `Future<UserProfile?> fetchUserProfile()` / `Future<DeviceProfile?> fetchDeviceProfile()`. `SimulatedProfileRepository` returns the demo `UserProfile` (David Miller, email/phone, age 48, 85 kg / 178 cm, BMI 26.8, caregiver Maria Chen …) and a demo bound `DeviceProfile`. `unbindDevice` / `unregisterUser` are unchanged (still just delay).
- `ProfileSession.hydrate()` (`lib/core/profile/profile_session.dart`): `await` both fetches, `set()` non-null results / `clear()` on `null`. Called from `main.dart`'s `onLoginSuccess` **before** `_appFlowBloc.add(AppFlowLoginSucceeded())`.
- `ProfileState` string/number defaults become empty (`''` / `0`). Add `ProfileState.fromProfile(UserProfile)`. `ProfileBloc({UserProfile? initial})` seeds from it (or empty). Keep `ProfileFieldChanged` + live-BMI behaviour exactly as-is.
- `ProfilePage` reads `UserProfileService.instance.current` in `initState`, builds `ProfileBloc(initial: …)`, seeds controllers from `_bloc.state`. Header text derives from the profile (`fullName`) with a "Complete your profile" placeholder when empty. One-time read — no live subscription.
- Home device card: wrap the existing `SimulatorBloc` logic in a `StreamBuilder<DeviceProfile?>` on `DeviceProfileService.instance.stream` (`initialData: …current`). `null` → `DeviceConnectionState.disconnected`; non-null → the current `isSimulatorActive` → connected/disconnected mapping.
- `SettingsActions.unregisterAccount`: on repo success → `UserProfileService.clear()` **and** `DeviceProfileService.clear()` → `AuthBloc.add(AuthUnregisterRequested())` → `AppFlowBloc.add(AppFlowLogoutRequested())`. Remove `Navigator.popUntil(...)` and the "Navigating to Onboarding…" snackbar (the screen swap is the feedback).
- Keep the confirm dialogs, `context.mounted` guards, and the repo-first / error-snackbar pattern from `spec-profile-stores-reset-seam`.

**Ask First:**
- Adding real HTTP / a persistence layer.
- Reworking `ProfilePage`'s edit/save into a separate flow (this spec only hydrates the existing form).
- Building any onboarding screen (deferred G3).

**Never:**
- Give `ProfileBloc` / any store knowledge of `SimulatorBloc` or BLE drivers.
- Persist anything (all in-memory; a relaunch re-seeds from the demo payload — acceptable for this slice).
- Leave demo identity strings hard-coded in `ProfileState` or `UserHeaderOrganism`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Login seed | `onLoginSuccess` fires | `hydrate()` awaited → `UserProfileService.current` = demo profile, `DeviceProfileService.current` = demo device, before `MainContainerPage` builds |
| Open ProfilePage, store populated | `UserProfileService.current != null` | fields + header show the demo identity (David Miller, BMI 26.8) |
| Open ProfilePage, store empty | `UserProfileService.current == null` | blank fields; header shows "Complete your profile" |
| Live BMI | weight 85 → 90 with a seeded profile | BMI recomputes 26.8 → 28.4 (unchanged behaviour) |
| Home card, device bound | `DeviceProfileService.current != null`, simulator on | `DeviceStatusCard` "D-BAND connected" |
| Home card, device unbound | `DeviceProfileService.current == null` | `DeviceStatusCard` "D-BAND not found" / tap-to-pair, regardless of `isSimulatorActive` |
| Unbind | confirm, repo OK | `DeviceProfileService` cleared → Home card flips to "not found" |
| Unregister | confirm, repo OK | both stores cleared → `AuthInitial` → `AppFlowLogoutRequested` → app shows `LoginPage` (no `popUntil`) |
| Log out | confirm | both stores cleared → `LoginPage` (unchanged from prior slice) |
| Re-login after unregister/logout | tap "Sign in with Passkey" | `hydrate()` re-seeds the demo payload; app returns to Home with the demo profile |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/data/profile_repository.dart` — add `fetchUserProfile()` / `fetchDeviceProfile()` to the interface; `SimulatedProfileRepository` returns demo payloads (define the demo constants here or in a `profile_demo_data.dart`).
- `flutter/lib/core/profile/profile_session.dart` — NEW. `ProfileSession.hydrate()` — await both fetches, `set`/`clear` the two services.
- `flutter/lib/main.dart` — `onLoginSuccess` becomes `() async { await ProfileSession.hydrate(); _appFlowBloc.add(const AppFlowLoginSucceeded()); }`.
- `flutter/lib/core/bloc/profile/profile_state.dart` — defaults → `''` / `0`; add `ProfileState.fromProfile(UserProfile)`.
- `flutter/lib/core/bloc/profile/profile_bloc.dart` — `ProfileBloc({UserProfile? initial})` → `super(initial != null ? ProfileState.fromProfile(initial) : const ProfileState())`. `_onFieldChanged` unchanged.
- `flutter/lib/ui/pages/profile_page.dart` — `initState`: `ProfileBloc(initial: UserProfileService.instance.current)`; header text from `state`/profile; empty placeholder.
- `flutter/lib/ui/pages/home_page.dart` — device-card `Builder`: wrap `cardContent` in `StreamBuilder<DeviceProfile?>(stream: DeviceProfileService.instance.stream, initialData: DeviceProfileService.instance.current)`; `null` forces `disconnected`.
- `flutter/lib/ui/settings/settings_actions.dart` — `unregisterAccount`: clear both stores, `AppFlowLogoutRequested`, drop `popUntil` + the navigating snackbar.
- `flutter/lib/ui/organisms/user_header_organism.dart` — accept a nullable name/title instead of the hard-coded "David" literals (or `ProfilePage` passes them).
- Tests: `flutter/test/core/bloc/profile_bloc_test.dart` (default-state change + `fromProfile` / `initial`), `flutter/test/ui/profile_page_test.dart` (seed the store; add empty-state case), `flutter/test/ui/home_page_test.dart` (seed / clear `DeviceProfileService`), `flutter/test/ui/settings_page_test.dart` (unregister now needs an `AppFlowBloc` provider + asserts `loggedOut` and both stores clear), `flutter/test/core/data/profile_repository_test.dart` (`fetch*` return demo), `flutter/test/core/profile/profile_session_test.dart` (NEW — hydrate populates both), `flutter/test/session_flow_test.dart` (NEW — `MaskerApp`: login → Home; Log out / Unregister → `LoginPage`).

## Tasks & Acceptance

**Execution:**
- [x] `profile_repository.dart` — `fetch*` methods + demo payloads.
- [x] `profile_session.dart` — NEW `ProfileSession.hydrate()`.
- [x] `main.dart` — await `hydrate()` in `onLoginSuccess`.
- [x] `profile_state.dart` + `profile_bloc.dart` — empty defaults, `fromProfile`, `initial` param.
- [x] `profile_page.dart` (+ `user_header_organism.dart`) — hydrate the form from the store; empty placeholder.
- [x] `home_page.dart` — gate the device card on `DeviceProfileService`.
- [x] `settings_actions.dart` — `unregisterAccount` clears both stores + `AppFlowLogoutRequested`, no `popUntil`.
- [x] tests — the updates + `profile_session_test.dart` + `session_flow_test.dart`.

**Acceptance Criteria:**
- Given login, when `onLoginSuccess` completes, then both services hold the demo payload before Home renders.
- Given `ProfilePage` with a populated store, then it shows the demo identity; given an empty store, then blank fields + "Complete your profile".
- Given Unbind confirmed, then `DeviceProfileService.current` is `null` and Home's card reads "D-BAND not found".
- Given Unregister confirmed, then both stores are `null`, `AuthBloc` is `AuthInitial`, `AppFlowBloc.stage == loggedOut`, and `MaskerApp` shows `LoginPage`.
- Given the suite, when `cd flutter && flutter analyze && flutter test` run, then both pass clean.

## Spec Change Log

### 2026-09-09 — review pass (patches only, no loopback)
- **patch** (edge-case): `ProfileSession.hydrate()` ran unguarded in the login-critical path — a fetch throw would leave `onLoginSuccess` never dispatching `AppFlowLoginSucceeded`, hanging the user on `LoginPage`. Extracted a `_load` helper that `try/catch`es each fetch and `clear()`s the store on error; login always proceeds. `profile_session_test.dart` "a fetch failure does not throw and leaves the stores empty".
- **patch** (verification-gap): no test covered the positive "D-BAND connected" render (`bound && isSimulatorActive`). Added `home_page_test.dart` "bound device + simulator active → 'D-BAND connected'" (activates the driver, asserts, cancels the emitter timer before test end).
- **patch** (tidy): dropped a pointless `Builder` wrapper around the ProfilePage header.
- **defer**: ProfilePage "Save" is still a no-op (edits don't persist); `ProfileState.fromProfile` shows BMI 0 when a fetched profile has weight/height but no `computedBmi`. Both are real-fetch / later concerns — recorded in `deferred-work.md`.

## Design Notes

`hydrate()` is awaited in `onLoginSuccess` (not inside `AppFlowBloc`) to keep the bloc free of profile concerns; the extra ~500 ms sits behind the existing post-login flow before `MainContainerPage` mounts.

`ProfileState.fromProfile` maps typed `UserProfile` fields to the form's string fields (`age.toString()`, `weightKg.toString()`, …) and takes `computedBmi` straight from the profile.

Home's card keeps its `SimulatorBloc` inner mapping for the "bound" case; the `DeviceProfileService` `StreamBuilder` is only an outer "is there a device at all" gate. A distinct `State_HomeNoDevice` visual is onboarding polish (deferred G3).

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. the updated + new suites.

**Manual checks:**
- `flutter run`: log in → Home shows D-BAND connected, Profile shows David Miller. Settings → Unbind → Home flips to "not found". Settings → Unregister → app returns to the passkey login screen; sign back in → demo profile restored.

## Suggested Review Order

**The seed path (design intent)**

- Login hook: `hydrate()` is `await`ed before the app-flow advances.
  [`main.dart:70`](../../flutter/lib/main.dart#L70)
- `hydrate()` + the `_load` helper — a fetch failure `clear()`s the store and never blocks login.
  [`profile_session.dart:12`](../../flutter/lib/core/profile/profile_session.dart#L12)
- Repo `fetch*` return the demo payloads (the values that used to be `ProfileState` defaults).
  [`profile_repository.dart:41`](../../flutter/lib/core/data/profile_repository.dart#L41)

**Profile form hydration**

- `ProfileState` defaults now empty; `fromProfile` maps a `UserProfile` into the form fields.
  [`profile_state.dart:33`](../../flutter/lib/core/bloc/profile/profile_state.dart#L33)
- `ProfileBloc({UserProfile? initial})` — seed or empty.
  [`profile_bloc.dart:13`](../../flutter/lib/core/bloc/profile/profile_bloc.dart#L13)
- `ProfilePage` reads the store once at init; header shows "Complete your profile" when empty.
  [`profile_page.dart:21`](../../flutter/lib/ui/pages/profile_page.dart#L21)

**Home device card + the unregister fix**

- Card gated by `StreamBuilder<DeviceProfile?>`: no bound device → "D-BAND not found" whatever the simulator says.
  [`home_page.dart:82`](../../flutter/lib/ui/pages/home_page.dart#L82)
- `unregisterAccount`: clear **both** stores → `AuthUnregisterRequested` + `AppFlowLogoutRequested`; no more stale `popUntil`.
  [`settings_actions.dart:113`](../../flutter/lib/ui/settings/settings_actions.dart#L113)

**Tests**

- `hydrate` populates / clears / survives a throwing repo.
  [`profile_session_test.dart:1`](../../flutter/test/core/profile/profile_session_test.dart#L1)
- Full tree: login seeds the stores; Log out / Unregister return to the passkey screen.
  [`session_flow_test.dart:1`](../../flutter/test/session_flow_test.dart#L1)
- Home card bound/unbound/connected; ProfilePage populated + empty-state; settings unregister now logs out.
  [`home_page_test.dart:1`](../../flutter/test/ui/home_page_test.dart#L1)
