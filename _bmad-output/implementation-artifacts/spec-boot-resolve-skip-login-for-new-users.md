---
title: 'Boot-time resolve so un-onboarded users skip the sign-in screen'
type: 'feature'
created: '2026-09-10'
status: 'done'
review_loop_iteration: 0
baseline_commit: '5278feddaa702c2a672007939650c794127d3dd6'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `AppFlowState` starts unconditionally at `stage: loggedOut`, so every first-run user is shown "Sign in with Passkey" (`LoginPage`) before they have an account or a passkey. Onboarding is only reached *after* that meaningless sign-in.

**Approach:** Add a boot-time `AppFlowStage.resolving` that reads a persisted "onboarding complete" flag and routes: flag set → `loggedOut` (LoginPage, returning user); flag absent → `onboarding` (step `register`) directly, `LoginPage` never rendered. The flag is a plain `shared_preferences` boolean written when the wizard finishes and cleared on account unregister. This is a local approximation of "is a passkey present on this device" — a real FIDO2 credential-store check is a deferred follow-on (no FIDO2 authenticator exists yet). Wizard step order is unchanged.

## Boundaries & Constraints

**Always:**
- New `AppFlowStage.resolving`, the default `AppFlowState.stage`. `_buildHome` renders it as the same minimal spinner `Scaffold` as `checkingPermission`.
- `AppFlowBloc` reads an injectable `OnboardingGate` (`OnboardingGate.instance`, default `SharedPreferencesOnboardingGate`, key `onboarding_complete`; `reset()` for tests) with `isComplete()` / `markComplete()` / `clear()`.
- On construction `AppFlowBloc` dispatches `AppFlowResolveRequested`; its handler (guarded to `stage == resolving`, `isClosed`-safe) emits `stage: loggedOut` when `isComplete()`, else `stage: onboarding, onboardingStep: register`.
- Advancing past the last onboarding step calls `await gate.markComplete()` (failure swallowed) **and** emits `stage: ready` regardless — a gate-write failure must never trap the user in onboarding.
- `AppFlowLogoutRequested` emits `stage: loggedOut` (explicitly — `const AppFlowState()` now means `resolving`); the gate is left set (logout keeps the user onboarded).
- New `AppFlowUnregistered` event → emits `resolving` and re-dispatches `AppFlowResolveRequested`; `SettingsActions.unregisterAccount` calls `OnboardingGate.instance.clear()` and dispatches `AppFlowUnregistered` in place of `AppFlowLogoutRequested`.
- `main()` already calls `WidgetsFlutterBinding.ensureInitialized()` (required by `shared_preferences`) — do not remove it.
- Existing post-`loggedOut` flow is untouched: `LoginPage.onLoginSuccess` → `ProfileSession.hydrate()` → `AppFlowLoginSucceeded(needsOnboarding)` → permission-check → `ready` (or `onboarding` if the profile is genuinely absent).
- `flutter analyze` clean; changed behavior covered by tests.

**Ask First:**
- Changing the wizard step order or contents (that is deferred Goal B).
- Using `flutter_secure_storage` instead of `shared_preferences`, or persisting anything beyond the one boolean.
- Making `logOut` also clear the gate.

**Never:**
- Render `LoginPage` when the gate is absent.
- Add a real FIDO2 / credential-store check here (deferred Goal C).
- Gate `resolving` on anything other than the `OnboardingGate` read (no network, no permission call).
- Persist onboarding step progress (still session-only).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Fresh install | `gate.isComplete()` → false | `resolving` → `onboarding` (step `register`); `LoginPage` never rendered |
| Returning user | `gate.isComplete()` → true | `resolving` → `loggedOut` (LoginPage) → existing sign-in → permission-check path |
| Onboarding completes | advance past `passkeyEnrollment` | `gate.markComplete()` called; `stage: ready` |
| Gate write fails | `markComplete()` throws | `stage: ready` still emitted; next boot re-onboards |
| Log out | from Settings (gate set) | `stage: loggedOut`; gate untouched |
| Unregister account | from Settings | `gate.clear()`; `AppFlowUnregistered` → `resolving` → `onboarding` (step `register`) |
| `resolving` on screen | any | minimal spinner `Scaffold`, identical to `checkingPermission` |
| App backgrounded during resolve | resume | `_onResolve` guard (`stage == resolving`) makes a re-fire idempotent |

</frozen-after-approval>

## Code Map

- `sleep-apnea-detection-app/lib/core/onboarding/onboarding_gate.dart` — **NEW.** `abstract class OnboardingGate { static OnboardingGate instance = SharedPreferencesOnboardingGate(); static void reset() => instance = SharedPreferencesOnboardingGate(); Future<bool> isComplete(); Future<void> markComplete(); Future<void> clear(); }` + `class SharedPreferencesOnboardingGate implements OnboardingGate` using `SharedPreferences.getInstance()` and key `'onboarding_complete'` (`getBool ?? false` / `setBool(true)` / `remove`).
- `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_state.dart:115-135` — add `resolving` as the **first** `AppFlowStage` value; change the `AppFlowState` ctor default to `this.stage = AppFlowStage.resolving`. `copyWith` / `props` unchanged.
- `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_event.dart` — add `class AppFlowResolveRequested extends AppFlowEvent { const AppFlowResolveRequested(); }` and `class AppFlowUnregistered extends AppFlowEvent { const AppFlowUnregistered(); }`.
- `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart:9-107` — ctor gains `OnboardingGate? onboardingGate` → `_gate = onboardingGate ?? OnboardingGate.instance`. Register `on<AppFlowResolveRequested>(_onResolve)` and `on<AppFlowUnregistered>(_onUnregistered)`; ctor body ends with `add(const AppFlowResolveRequested())`. `_onResolve` (async): `if (state.stage != AppFlowStage.resolving) return; final done = await _gate.isComplete(); if (isClosed || state.stage != AppFlowStage.resolving) return; emit(state.copyWith(stage: done ? AppFlowStage.loggedOut : AppFlowStage.onboarding, onboardingStep: OnboardingStep.register));`. `_onUnregistered`: `emit(state.copyWith(stage: AppFlowStage.resolving, onboardingStep: OnboardingStep.register)); add(const AppFlowResolveRequested());`. `_onOnboardingAdvanced` → `Future<void>`; in the "past last step" branch, `try { await _gate.markComplete(); } catch (_) {}` then `emit(... stage: ready, onboardingStep: done)`. `AppFlowLogoutRequested` handler → `emit(state.copyWith(stage: AppFlowStage.loggedOut, onboardingStep: OnboardingStep.register))` (was `emit(const AppFlowState())`).
- `sleep-apnea-detection-app/lib/main.dart:64-121` — `_buildHome`: add `case AppFlowStage.resolving:` returning the same `Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()))` as `checkingPermission` (share via a small `const` widget or duplicate). No `AppFlowBloc` ctor change (default gate).
- `sleep-apnea-detection-app/lib/ui/settings/settings_actions.dart:90-114` — `unregisterAccount`: after the store clears, `await OnboardingGate.instance.clear();` then `context.read<AppFlowBloc>().add(const AppFlowUnregistered());` **instead of** `AppFlowLogoutRequested`. `logOut` unchanged. Add the `onboarding_gate.dart` import.
- `sleep-apnea-detection-app/pubspec.yaml:9-19` — add `shared_preferences: ^2.3.2` under `dependencies`.
- `sleep-apnea-detection-app/test/core/onboarding/onboarding_gate_test.dart` — **NEW.** `TestWidgetsFlutterBinding.ensureInitialized()` + `SharedPreferences.setMockInitialValues({})`: `isComplete()` false by default, true after `markComplete()`, false after `clear()`.
- `sleep-apnea-detection-app/test/core/bloc/app_flow_bloc_test.dart` — add a `_FakeOnboardingGate({bool complete})` (records `markComplete`/`clear` calls); pass it to **every** `AppFlowBloc(...)` (the `SharedPreferences` default throws under `flutter test`). Existing logout tests: expect `loggedOut` via `emitsThrough`/`firstWhere` (a `resolving` transient may precede it on the unregister path only — logout stays direct). Add: gate-complete → `loggedOut`; gate-incomplete → `onboarding/register`; advance past last step → `markComplete` called + `ready`; `AppFlowUnregistered` (gate cleared) → `onboarding/register`.
- `sleep-apnea-detection-app/test/widget_test.dart` — `TestWidgetsFlutterBinding.ensureInitialized()`; `SharedPreferences.setMockInitialValues({'onboarding_complete': true})` in `setUp` for the two existing tests (they need `LoginPage`). Add: `setMockInitialValues({})` → `MaskerApp` boots to the onboarding wizard (`Key('onboarding-step-register')`), and "D-BAND Sleep Apnea Detection App" / "Sign in with Passkey" are **absent**.
- `sleep-apnea-detection-app/test/ui/onboarding_wizard_page_test.dart` — `_pumpAtOnboarding` injects `_FakeOnboardingGate(complete: false)` into its `AppFlowBloc`; the `bloc.add(AppFlowLoginSucceeded(needsOnboarding: true))` becomes a no-op (guard) and can be dropped. Rest of the file unchanged.
- `sleep-apnea-detection-app/test/ui/settings_page_test.dart` — set `OnboardingGate.instance` to a fake in `setUp`/`tearDown`; assert `clear()` is called by the unregister flow and **not** by log out.

## Tasks & Acceptance

**Execution:**
- [x] `sleep-apnea-detection-app/pubspec.yaml` — `shared_preferences: ^2.3.2` added (resolved 2.5.5); `flutter pub get` run.
- [x] `sleep-apnea-detection-app/lib/core/onboarding/onboarding_gate.dart` — `OnboardingGate` (abstract + static `instance`/`reset`) + `SharedPreferencesOnboardingGate` (key `onboarding_complete`).
- [x] `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_state.dart` — `AppFlowStage.resolving` first; `AppFlowState.stage` default `resolving`.
- [x] `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_event.dart` — `AppFlowResolveRequested`, `AppFlowUnregistered`.
- [x] `sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart` — `_gate` injected; `_onResolve` (guarded, `isClosed`-safe) + `add(AppFlowResolveRequested())` on construct; `_onUnregistered` → `resolving` + re-resolve; `_onOnboardingAdvanced` → async, `try { await _gate.markComplete() } catch (_) {}` then `ready` regardless; `AppFlowLogoutRequested` → `copyWith(stage: loggedOut, step: register)`.
- [x] `sleep-apnea-detection-app/lib/main.dart` — `_buildHome` `case AppFlowStage.resolving:` → `checkingPermission`-style spinner.
- [x] `sleep-apnea-detection-app/lib/ui/settings/settings_actions.dart` — `unregisterAccount` `await OnboardingGate.instance.clear()` + `AppFlowUnregistered` (was `AppFlowLogoutRequested`); `context.mounted` re-check across the new gap.
- [x] `sleep-apnea-detection-app/test/core/onboarding/onboarding_gate_test.dart` — NEW, `SharedPreferences.setMockInitialValues`.
- [x] `sleep-apnea-detection-app/test/core/bloc/app_flow_bloc_test.dart` — `_FakeOnboardingGate` (`complete`, `throwOnMarkComplete`, call counters) + `build()`/`resolved()` helpers at every construction; new cases: resolve→onboarding, resolve→loggedOut, resolve idempotent, `AppFlowUnregistered`→wizard, advance→`markComplete`+ready, gate-write-failure→ready.
- [x] `sleep-apnea-detection-app/test/widget_test.dart` — inject `OnboardingGate.instance` fake per test (no `shared_preferences`); fresh-install→wizard case + returning-user group.
- [x] `sleep-apnea-detection-app/test/ui/onboarding_wizard_page_test.dart` — `_IncompleteOnboardingGate` injected in `_pumpAtOnboarding`; dropped the now-noop `AppFlowLoginSucceeded`.
- [x] `sleep-apnea-detection-app/test/ui/settings_page_test.dart` — `_FakeOnboardingGate` in `setUp`; assert `gate.clearCalls == 1` on unregister (+ new `onboarding` stage), `== 0` on log out.
- [x] **(beyond the original Code Map)** `sleep-apnea-detection-app/test/flutter_test_config.dart` — NEW; auto-loaded, swaps `OnboardingGate.instance` to an in-memory gate (`complete: true`) suite-wide so the ~4 other files that build `AppFlowBloc` / pump `MaskerApp` (`app_flow_test.dart`, `session_flow_test.dart`, …) don't hit the unmocked `SharedPreferences`.
- [x] **(beyond the original Code Map)** `sleep-apnea-detection-app/test/app_flow_test.dart`, `test/session_flow_test.dart` — added pumps to land off the `resolving` spinner; `session_flow_test` unregister assertions updated to expect the wizard directly.

**Acceptance Criteria:**
- Given `OnboardingGate.isComplete()` is false, when `AppFlowBloc` resolves on construction, then `state.stage == onboarding` with `onboardingStep == register`, and no code path renders `LoginPage`.
- Given `OnboardingGate.isComplete()` is true, when `AppFlowBloc` resolves, then `state.stage == loggedOut`.
- Given the onboarding wizard, when the user advances past the passkey-enrollment step, then `OnboardingGate.markComplete()` is called and `state.stage == ready` — and `state.stage == ready` even if `markComplete()` throws.
- Given a returning user in `loggedOut`, when they log out from Settings, then `state.stage == loggedOut` and the gate is unchanged.
- Given a user unregisters from Settings, then `OnboardingGate.clear()` is called and `AppFlowBloc` resolves to `onboarding` / `register`.
- Given `flutter run` on a fresh install, then the first screen is the onboarding wizard (not "Sign in with Passkey"); after completing onboarding and relaunching, the first screen is "Sign in with Passkey".
- Given `cd sleep-apnea-detection-app && flutter analyze && flutter test`, then both pass.

## Spec Change Log

### 2026-09-10 — step-04 review pass (patch only, no loopback)

Three lenses (blind-hunter, edge-case, verification-gap) on the diff. No `intent_gap` / `bad_spec`; frozen block untouched. Patches applied:

- **all three lenses:** `_onResolve` now wraps `await _gate.isComplete()` in `try/catch` (fall through as a returning user — the boot spinner can never hang on a prefs-read failure); `app_flow_bloc_test` gained a `throwOnIsComplete` case.
- **edge-case + verification-gap:** `_onOnboardingAdvanced` re-checks `state.stage == onboarding` (not just `isClosed`) after the `markComplete()` await, before `emit(ready)`.
- **blind-hunter + edge-case:** the onboarding-flag `clear()` moved from `SettingsActions.unregisterAccount` **into** `_onUnregistered` (async, `try/catch`) — the bloc owns it, no dispatch site can forget it; removed the extra `context.mounted` gap from settings_actions.
- **verification-gap:** added a `widget_test.dart` group that boots the real `MaskerApp` against the real `SharedPreferencesOnboardingGate` (`OnboardingGate.reset()` + `SharedPreferences.setMockInitialValues`) — asserts wizard for `{}` and sign-in for `{onboarding_complete: true}`, pinning `main`'s wiring.
- **blind-hunter:** added `app_flow_bloc_test` "boot straight into the wizard walks to ready and marks the gate" — the boot-resolve path end-to-end (was only reached via the login path).
- **blind-hunter:** `flutter_test_config.dart` now registers a `setUp` (fresh in-memory gate per test) instead of a one-time assignment; `OnboardingGate.reset()` dartdoc corrected; `debugPrint` breadcrumb on the swallowed `markComplete()` failure; shared `_TransientSpinner` (with `semanticsLabel`) for `resolving` + `checkingPermission`; stale comments in `app_flow_event.dart` / `app_flow_test.dart` updated.

Deferred (`deferred-work.md`): a fresh install can't reach `ready` in a simulator-off / no-FIDO build (onboarding step 3 blocks; no fallback) and wizard progress isn't persisted — both closed by Goals B/C/D.

Rejected: `SharedPreferencesAsync` API migration (`getInstance()` is fine); per-`firstWhere` timeouts (matches the file's existing style); `pubspec.yaml` dep ordering; a shared test "pump-past-resolving" helper (two-line repetition ×3).

`flutter analyze` clean; `flutter test` 333 pass.

## Design Notes

Local boolean, not a real passkey check: the FIDO2 credential store doesn't exist yet (`// TODO(FIDO)`). The flag is the smallest change that lets a first-run user skip `LoginPage` now; swapping it for a platform credential-store query is deferred Goal C (`deferred-work.md`).

`resolving` as an `AppFlowStage`, not a `FutureBuilder` in `main`: `AppFlowBloc` stays the single source of "where the user is" (its own class doc), and `checkingPermission` already models a brief async gate the same way.

`AppFlowUnregistered` separate from `AppFlowLogoutRequested`: logout keeps you onboarded → `loggedOut` (LoginPage); unregister wipes the account → `onboarding`. Different destinations, so different events rather than an async branch inside the logout handler.

## Verification

**Commands:**
- `cd sleep-apnea-detection-app && flutter pub get`
- `cd sleep-apnea-detection-app && flutter analyze` — expected: "No issues found!" (or only pre-existing `deferred-work.md` warnings).
- `cd sleep-apnea-detection-app && flutter test` — expected: full suite green, incl. the updated `app_flow_bloc_test.dart`, `widget_test.dart`, `onboarding_wizard_page_test.dart`, `settings_page_test.dart`.

**Manual checks:**
- Fresh install / cleared app data: `flutter run` → lands on the onboarding wizard step 1, **not** "Sign in with Passkey".
- Complete onboarding → kill the app → relaunch → lands on "Sign in with Passkey".
- Sign in → Settings → **Unregister** → back to the onboarding wizard. Settings → **Log out** → back to "Sign in with Passkey".

## Suggested Review Order

**The boot decision**

- Entry point: the resolve handler. Reads the gate (guarded), routes `resolving` → `loggedOut` | `onboarding`.
  [`app_flow_bloc.dart:42`](../../sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart#L42)
- The new default state and stage. `AppFlowState` now starts at `resolving`, not `loggedOut`.
  [`app_flow_state.dart:29`](../../sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_state.dart#L29)
- The bloc self-dispatches the resolve on construction.
  [`app_flow_bloc.dart:39`](../../sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart#L39)

**The flag**

- `OnboardingGate` + the `shared_preferences` implementation (key `onboarding_complete`).
  [`onboarding_gate.dart:30`](../../sleep-apnea-detection-app/lib/core/onboarding/onboarding_gate.dart#L30)
- Written past the last wizard step — best-effort, `ready` emitted regardless, with a concurrency re-check.
  [`app_flow_bloc.dart:94`](../../sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart#L94)
- Cleared by the bloc on unregister (`_onUnregistered` owns it); `SettingsActions` just dispatches `AppFlowUnregistered`.
  [`app_flow_bloc.dart:63`](../../sleep-apnea-detection-app/lib/core/bloc/app_flow/app_flow_bloc.dart#L63) · [`settings_actions.dart:115`](../../sleep-apnea-detection-app/lib/ui/settings/settings_actions.dart#L115)

**Rendering**

- `_buildHome` renders `resolving` as the shared `_TransientSpinner`.
  [`main.dart:66`](../../sleep-apnea-detection-app/lib/main.dart#L66) · [`main.dart:175`](../../sleep-apnea-detection-app/lib/main.dart#L175)

**Verification**

- Real gate wired through `MaskerApp`: empty prefs → wizard, `onboarding_complete: true` → sign-in.
  [`widget_test.dart:75`](../../sleep-apnea-detection-app/test/widget_test.dart#L75)
- Boot-resolve path end-to-end (wizard → ready → gate marked); gate-read failure never hangs.
  [`app_flow_bloc_test.dart:116`](../../sleep-apnea-detection-app/test/core/bloc/app_flow_bloc_test.dart#L116) · [`app_flow_bloc_test.dart:108`](../../sleep-apnea-detection-app/test/core/bloc/app_flow_bloc_test.dart#L108)
- Suite-wide gate fake so the other `AppFlowBloc` / `MaskerApp` tests don't hit unmocked `SharedPreferences`.
  [`flutter_test_config.dart`](../../sleep-apnea-detection-app/test/flutter_test_config.dart)
