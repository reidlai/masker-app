---
title: 'Profile stores + repository seam: route Unbind / Unregister / Logout through it'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: '605aeab86b097627ac3b586a8285126cc5b386ac'
context:
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** "Unbind BLE Sensor Device" and "Unregister User Account" only poke local BLE / `AuthBloc` state. There is no server call, no user/device profile model, and no reactive store for them; there is also no way to log out — `AppFlowBloc` has no path back to `loggedOut`.

**Approach:** Add a `ProfileRepository` seam (interface + a simulated impl that just delays, like the passkey sim) and two RxDart reactive stores, `UserProfileService` / `DeviceProfileService`, each a `BehaviorSubject<T?>` seeded `null` (`null` = "empty"). Wire the two reset actions to call the repo then `clear()` the matching store. Add a **Log out** row in Settings (above the Developer section, visible in every build) that clears both stores + auth and drives `AppFlowBloc` back to `loggedOut` (→ the existing `LoginPage`). **This slice has no load/populate path** — stores start `null` and are only ever cleared; fetching is deferred (see deferred-work G2), full onboarding is deferred (G3).

## Boundaries & Constraints

**Always:**
- All code/commands from `flutter/`. `flutter analyze` clean; `flutter test` 100% pass.
- Stores are in-memory singletons (`static final instance`, `reset()` for tests) — same pattern as `PasskeySimulatorConfig` / `BleSimulatorDriver`. Expose `ValueStream<T?> stream`, `T? get current`, `void set(T)`, `void clear()` (adds `null`).
- `ProfileRepository.instance` is a mutable static defaulting to `SimulatedProfileRepository` (delay ~500 ms, then return) so tests can substitute. Methods: `Future<void> unbindDevice()`, `Future<void> unregisterUser()`.
- Model types are real but minimal, fields mirroring the architecture entities: `UserProfile` ⊂ `PatientUser`+`HealthBaseline`, `DeviceProfile` ⊂ `DeviceBinding`. `Equatable`, `const` ctor.
- Reset actions: call the repo **first**; on throw show a red "Couldn't … — try again." `SnackBar` and stop (no local reset, no `clear()`); on success do the existing local work, `clear()` the store, success `SnackBar`. Keep the two-step confirm dialogs and `context.mounted` guards.
- Log out routes via `AppFlowBloc.add(AppFlowLogoutRequested())` → `emit(const AppFlowState())` (stage `loggedOut`); also `AuthBloc.add(AuthLogoutRequested())`. No manual `Navigator` — the root `BlocBuilder<AppFlowBloc>` swaps `home`.
- `AppFlowBloc` must be reachable from `SettingsPage`: add `BlocProvider<AppFlowBloc>.value(value: _appFlowBloc)` to the root `MultiBlocProvider` in `main.dart`.

**Ask First:**
- Adding a real HTTP client / dependency, or a persistence layer for the stores.
- Any change to `ProfilePage` / `ProfileBloc` (that is deferred G2).

**Never:**
- Populate the stores from anywhere in this slice (no fetch, no demo seed).
- Build onboarding screens (deferred G3).
- Gate the Log out row behind `DEV_MODE` / `kDebugMode` — it is a normal user action.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Store lifecycle | fresh `UserProfileService` / `DeviceProfileService` | `current == null`; `stream` is a `ValueStream` replaying `null` |
| Clear after set | `set(profile)` then `clear()` | `stream` emits `profile` then `null`; `current == null` |
| Unbind, repo OK | confirm "Unbind BLE Sensor?" | `repo.unbindDevice()` awaited → local BLE reset → `DeviceProfileService.clear()` → success snackbar |
| Unbind, repo throws | `repo.unbindDevice()` throws | red "Couldn't unbind device — try again." snackbar; store untouched; no local reset |
| Unregister, repo OK | confirm "Unregister User Account?" | `repo.unregisterUser()` awaited → `UserProfileService.clear()` → `AuthUnregisterRequested` → snackbar → pop to first route |
| Log out | tap "Log out", confirm | both stores `clear()`ed → `AuthLogoutRequested` + `AppFlowLogoutRequested` → app shows `LoginPage` |
| Log out then log in | after logout, tap "Sign in with Passkey" | `AppFlowLoginSucceeded` re-entrancy guard passes (stage is `loggedOut`); normal post-login gate runs |
| Cancel any dialog | tap "Cancel" | no repo call, no store change, dialog dismissed |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/data/profile_repository.dart` — NEW. `abstract ProfileRepository` + `SimulatedProfileRepository` (`Future.delayed(500ms)`), mutable `static ProfileRepository instance`.
- `flutter/lib/core/profile/user_profile.dart`, `device_profile.dart` — NEW. Minimal `Equatable` models (fields per `PatientUser`+`HealthBaseline` / `DeviceBinding`).
- `flutter/lib/core/profile/user_profile_service.dart`, `device_profile_service.dart` — NEW. `BehaviorSubject<T?>.seeded(null)` singletons; `stream` / `current` / `set` / `clear` / `reset`.
- `flutter/lib/core/bloc/app_flow/app_flow_event.dart` — add `AppFlowLogoutRequested`.
- `flutter/lib/core/bloc/app_flow/app_flow_bloc.dart` — `on<AppFlowLogoutRequested>((e, emit) => emit(const AppFlowState()))`.
- `flutter/lib/main.dart` — add `BlocProvider<AppFlowBloc>.value(value: _appFlowBloc)` to the root `MultiBlocProvider` (keep the existing `BlocBuilder(bloc: _appFlowBloc)`).
- `flutter/lib/ui/developer/developer_reset_actions.dart` → **rename** to `flutter/lib/ui/settings/settings_actions.dart`, class `DeveloperResetActions` → `SettingsActions`. Add `static Future<void> logOut(BuildContext)` (confirm "Log out?" → clear both stores → `AuthLogoutRequested` + `AppFlowLogoutRequested`). Thread the repo call + `clear()` into `unbindBleDevice` / `unregisterAccount` per the matrix.
- `flutter/lib/ui/pages/settings_page.dart` — swap the helper import; add a one-row `_buildMenuCard` "Log out" (`Icons.logout`, `showChevron: false`) between the Subscription section and `if (_showDeveloper)`.
- `flutter/test/core/data/profile_repository_test.dart`, `flutter/test/core/profile/user_profile_service_test.dart`, `device_profile_service_test.dart`, `flutter/test/core/bloc/app_flow_bloc_test.dart` — NEW, cover the matrix rows.
- `flutter/test/ui/settings_page_test.dart` — "Log out" row present with both flags off; tap "Log out" → confirm → both services `current == null`; substitute a throwing `ProfileRepository.instance` for the unbind/unregister failure rows; `reset()` the services + `ProfileRepository.instance` in `setUp`.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/profile/user_profile.dart` + `device_profile.dart` — minimal Equatable models.
- [x] `flutter/lib/core/data/profile_repository.dart` — interface + `SimulatedProfileRepository` + mutable `instance`.
- [x] `flutter/lib/core/profile/user_profile_service.dart` + `device_profile_service.dart` — `BehaviorSubject<T?>` singletons.
- [x] `flutter/lib/core/bloc/app_flow/app_flow_event.dart` + `app_flow_bloc.dart` — `AppFlowLogoutRequested` + handler.
- [x] `flutter/lib/main.dart` — provide `AppFlowBloc` in the widget tree.
- [x] `flutter/lib/ui/settings/settings_actions.dart` — renamed helper; `logOut`; repo + `clear()` wiring in the two reset flows.
- [x] `flutter/lib/ui/pages/settings_page.dart` — import swap + "Log out" row.
- [x] tests — the four new test files + `settings_page_test.dart` updates.

**Acceptance Criteria:**
- Given fresh services, when read, then `current` is `null` and `stream` replays `null`.
- Given a confirmed Unbind with the repo succeeding, when it completes, then `DeviceProfileService.current` is `null` and the success snackbar shows; given the repo throwing, then the store is unchanged and an error snackbar shows.
- Given a confirmed Unregister with the repo succeeding, then `UserProfileService.current` is `null` and `AuthBloc` is `AuthInitial`.
- Given "Log out" confirmed, then both services are `null`, `AppFlowBloc.state.stage == loggedOut`, and the app renders `LoginPage`.
- Given the suite, when `cd flutter && flutter analyze && flutter test` run, then both pass clean.

## Spec Change Log

### 2026-09-09 — review pass (patches only, no loopback)
- **patch** (verification-gap): the "Log out" widget test asserted the stores cleared but not that `AuthLogoutRequested` / `AppFlowLogoutRequested` fired — deleting either dispatch would keep the test green. Test now provides real `AuthBloc` / `AppFlowBloc` and asserts `AuthInitial` + `stage == loggedOut`.
- **patch** (edge-case): the new logout path made an existing race reachable — `_onLoginSucceeded` did not re-check the stage after `await checkPermission()`, so `login → checking → logout → check resolves` bounced the user back to `ready`. Added a post-`await` (and `catch`) `state.stage == checkingPermission` guard in `app_flow_bloc.dart` + an `app_flow_bloc_test.dart` case.
- **defer**: `logOut` does not stop an active monitoring session / BLE foreground service — recorded in `deferred-work.md`.

## Design Notes

The "Log out" row sits under a new "Session" section header (not folded into the existing "Account" card) to keep a single-purpose destructive action visually distinct; "Session" avoids a duplicate "Account" header.

`AppFlowBloc` is currently owned by `_MaskerAppState` and only read via `BlocBuilder(bloc: _appFlowBloc)`. Adding `BlocProvider.value` for it (not a new instance) is the minimal way to let a `SettingsPage` row dispatch `AppFlowLogoutRequested`; the existing explicit `bloc:` binding still works and needn't change.

`clear()` = `subject.add(null)` — a seeded `BehaviorSubject` is never value-less, so "empty" is modelled as a `null` payload, not a closed/dry subject.

The helper rename (`DeveloperResetActions` → `SettingsActions`) is because it now also owns `logOut`, which is not a developer action. The file was added one PR ago (#9); no external consumers.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. the four new suites and updated `settings_page_test.dart`.

**Manual checks:**
- `flutter run`: Settings shows a "Log out" row above the DEVELOPER section; tapping it → confirm → app returns to the passkey login screen. Re-login works.

## Suggested Review Order

**The seam (design intent)**

- Repository interface — the two server ops; `unbindDevice` maps to `POST /api/v1/devices/unbind`.
  [`profile_repository.dart:7`](../../flutter/lib/core/data/profile_repository.dart#L7)
- No-backend stand-in: delay-then-return, substitutable via the static `instance`.
  [`profile_repository.dart:23`](../../flutter/lib/core/data/profile_repository.dart#L23)
- Reactive store: `BehaviorSubject<T?>` seeded `null`; `null` = empty. `set` exists for the deferred fetch path.
  [`user_profile_service.dart:9`](../../flutter/lib/core/profile/user_profile_service.dart#L9)

**Wiring the actions**

- `unbindBleDevice`: repo first — on throw, error snackbar + bail (no local reset, no clear); on success, local BLE reset → `clear()` → success snackbar.
  [`settings_actions.dart:64`](../../flutter/lib/ui/settings/settings_actions.dart#L64)
- `logOut`: clear both stores → `AuthLogoutRequested` + `AppFlowLogoutRequested`; no `Navigator` — the root swaps `home`.
  [`settings_actions.dart:123`](../../flutter/lib/ui/settings/settings_actions.dart#L123)
- New "Log out" row under a "Session" header, above the Developer section, ungated.
  [`settings_page.dart:117`](../../flutter/lib/ui/pages/settings_page.dart#L117)

**App-flow logout + the race fix**

- `AppFlowLogoutRequested` → `emit(const AppFlowState())` (→ `loggedOut`).
  [`app_flow_bloc.dart:21`](../../flutter/lib/core/bloc/app_flow/app_flow_bloc.dart#L21)
- Post-`await` stage guard so a logout during an in-flight permission check isn't clobbered by its stale result (both the try and catch paths).
  [`app_flow_bloc.dart:42`](../../flutter/lib/core/bloc/app_flow/app_flow_bloc.dart#L42)
- `AppFlowBloc` added to the root `MultiBlocProvider` (`.value`) so a Settings row can dispatch to it.
  [`main.dart:125`](../../flutter/lib/main.dart#L125)

**Tests**

- Store lifecycle + set→clear emission; repository default / substitution / reset.
  [`user_profile_service_test.dart:1`](../../flutter/test/core/profile/user_profile_service_test.dart#L1)
- Logout transition, re-login after logout, and the in-flight-check race.
  [`app_flow_bloc_test.dart:54`](../../flutter/test/core/bloc/app_flow_bloc_test.dart#L54)
- Unbind success/failure store effects; Unregister store + `AuthInitial`; Log out clears stores and drives auth + app-flow to logged-out.
  [`settings_page_test.dart:274`](../../flutter/test/ui/settings_page_test.dart#L274)
