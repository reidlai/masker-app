---
title: 'Passkey sign-in & enrollment unavailable when the simulator is off'
type: 'feature'
created: '2026-09-10'
status: 'done'
review_loop_iteration: 0
baseline_commit: '1c2f51d017610d075f21f8b06e7200a0cfab3feb'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** With the Passkey Simulator flag **off** and no real FIDO2 authenticator wired (the app's state today), `AuthBloc._onPasskeySubmitted` still falls through to an 800 ms delay and emits `AuthAuthenticated`, and onboarding's "Create Passkey" still records a fake credential. "Off" silently grants a session it cannot back with real authentication, under the screen's "FIDO2 Hardware Encryption" copy.

**Approach:** When the simulator is off, route passkey sign-in and onboarding passkey-enrollment to the real FIDO2 seam instead of the fake fallback. No real implementation is registered yet (`// TODO(FIDO)`), so that seam surfaces an explicit **unavailable** state — a new `AuthUnavailable` state shown on `LoginPage`, and an inline "not available yet" message on the onboarding step that does not advance the wizard. Simulator **on** is unchanged. This holds in every build, including release, so a release build cannot passkey-sign-in until a real authenticator is dropped into the seam.

## Boundaries & Constraints

**Always:**
- Simulator **on**: unchanged — `AuthInProgress` → ~800 ms → `AuthAuthenticated`; onboarding records a simulated credential and advances.
- Simulator **off** with a `passkeyAuthenticator` injected: unchanged — awaited; a throw still surfaces as `AuthFailure`. This is the real-FIDO2 attach point.
- Simulator **off**, no `passkeyAuthenticator` (today, every build): `AuthBloc` emits `AuthInProgress` → `AuthUnavailable(message)` and **never** `AuthAuthenticated`; no 800 ms delay, no session.
- New `AuthUnavailable extends AuthState` with a `String message` in `props`.
- `LoginPage` renders `AuthUnavailable`'s message inline (non-error styling, `AppColors.warningAmber`); the "Sign in with Passkey" button stays enabled, and a repeat tap re-emits `AuthInProgress` → `AuthUnavailable`.
- Onboarding `_PasskeyEnrollmentStep`, simulator off: `_createPasskey` shows an inline unavailable message and returns; `ProfileRepository.enrollPasskey()` is **not** called; the wizard does **not** advance. The simulator-off body copy says enrollment is unavailable in this build (not "you'll be prompted for biometrics").
- The no-authenticator `else` branches in `AuthBloc._onPasskeySubmitted` and `_PasskeyEnrollmentStep._createPasskey` are the `// TODO(FIDO)` markers — a real ceremony replaces the body with no further UI/flow change.
- `flutter analyze` clean; changed behavior covered by tests.

**Ask First:**
- Implementing any real FIDO2/WebAuthn ceremony, package, or backend endpoint (separate epic).
- Adding a "skip passkey / set up later" path to onboarding (this spec leaves onboarding blocked when the simulator is off).
- Reusing `AuthFailure` instead of a new `AuthUnavailable`.
- Changing `main.dart`'s `AuthBloc` wiring or injecting a `passkeyAuthenticator`.

**Never:**
- Emit `AuthAuthenticated` or record a credential on the simulator-off + no-authenticator path.
- Gate anything on the flag beyond the `AuthBloc` passkey-submit branch and the onboarding passkey-enrollment branch.
- Touch simulator-**on** behavior, the BLE simulator / `SimulatorBloc`, or `passkeySimulatorActive`'s gate.
- Add a logout / re-auth path (out of scope).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Sign-in, simulator on | flag true | `AuthInProgress` → ~800 ms → `AuthAuthenticated`; `onLoginSuccess` runs |
| Sign-in, simulator off, authenticator injected | flag false, `passkeyAuthenticator != null` | awaited → `AuthAuthenticated`; throw → `AuthFailure` |
| Sign-in, simulator off, no authenticator (today) | flag false, `passkeyAuthenticator == null` | `AuthInProgress` → `AuthUnavailable`; no `AuthAuthenticated`; `onLoginSuccess` not called |
| `LoginPage` on `AuthUnavailable` | state is `AuthUnavailable` | inline amber message; button enabled; repeat tap re-emits `AuthInProgress` → `AuthUnavailable` |
| Onboarding Create Passkey, simulator on | flag true, step 3/3 | records simulated credential, advances to `ready` (unchanged) |
| Onboarding Create Passkey, simulator off | flag false, tap "Create Passkey" | inline "not available yet"; `enrollPasskey()` not called; stays on `passkeyEnrollment` |
| Release build | `passkeySimulatorActive(developerBuild:false)` → flag off, no toggle | sign-in and enrollment unavailable until a real authenticator is registered |

</frozen-after-approval>

## Code Map

- `sleep-apnea-detection-app/lib/core/bloc/auth/auth_state.dart` — add `class AuthUnavailable extends AuthState { final String message; const AuthUnavailable(this.message); @override List<Object?> get props => [message]; }`.
- `sleep-apnea-detection-app/lib/core/bloc/auth/auth_bloc.dart:36-57` — `_onPasskeySubmitted`. Today: `if (sim) 800ms; else if (auth!=null) await auth; else 800ms;` then a **shared** `emit(const AuthAuthenticated())`, wrapped in `try/catch → AuthFailure`. **Change:** move `emit(AuthAuthenticated())` into the first two branches; the `else` becomes `emit(const AuthUnavailable("Passkey sign-in isn't available yet — turn on the Passkey Simulator to continue in this build.")); return;`. Keep the `try/catch` and the throttle/`switchMap` transformer.
- `sleep-apnea-detection-app/lib/ui/pages/login_page.dart:18-56` — `BlocConsumer<AuthBloc,AuthState>`; `listener` fires `onLoginSuccess` on `AuthAuthenticated` (leave as-is — `AuthUnavailable` navigates nowhere); `builder` has `isAuthenticating = state is AuthInProgress`. **Change:** in the centered `Column`, after `PasskeyAuthCardOrganism` + its `Spacer` and before `SecurityBadgeOrganism`, add `if (state is AuthUnavailable) ...[ const SizedBox(height: 12), Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.warningAmber)) ]`.
- `sleep-apnea-detection-app/lib/ui/pages/onboarding_wizard_page.dart:101-175` — `_PasskeyEnrollmentStepState`. **Change `_createPasskey`:** `if (_simulated) { …existing enrollPasskey path… } else { setState(() => _error = "Passkey creation isn't available yet — turn on the Passkey Simulator to continue in this build."); return; }`. **Change the body copy:** the `_simulated ? … : …` ternary's false branch (currently "You'll be prompted for your device biometrics…") becomes the "not available in this build yet" line. Keep `Key('onboarding-create-passkey')`, the `_busy` guard, `_error` display.
- **READ-ONLY:** `sleep-apnea-detection-app/lib/main.dart:135-145` (`AuthBloc(isPasskeySimulatorEnabled: …)`, no `passkeyAuthenticator` — confirms the `else` branch is live in every build); `sleep-apnea-detection-app/lib/core/config/passkey_simulator_config.dart` (`passkeySimulatorActive`; its dartdoc already says "routes to the real FIDO2/WebAuthn authenticator once one is wired").
- `sleep-apnea-detection-app/test/core/bloc/auth_bloc_test.dart:98-110` — the "flag Off with no authenticator wired still emits AuthAuthenticated" case pins the reversed behavior. **Rewrite** to `emitsInOrder([isA<AuthInProgress>(), isA<AuthUnavailable>()])` + rename. Keep the flag-On and flag-Off+throwing-authenticator cases (untouched branches). **Add** flag-Off + non-throwing authenticator → `AuthAuthenticated`.
- `sleep-apnea-detection-app/test/ui/login_page_test.dart` — builds its own `AuthBloc`. **Add:** flag off + no authenticator + tap "Sign in with Passkey" → `AuthUnavailable` message visible, `onLoginSuccess` not called, button still tappable (repeat tap → still the message). Reset `PasskeySimulatorConfig.instance` in `setUp`/`tearDown`. Keep the existing render/tap test.
- `sleep-apnea-detection-app/test/ui/onboarding_wizard_page_test.dart:110-113, 216-226` — `_completePasskey` taps "Create Passkey"; the "reaches ready" tests run with the flag **on** (default) and stay green. **Add:** flag off → tap "Create Passkey" → inline "not available yet", `stage == onboarding`, `onboardingStep == passkeyEnrollment`, `enrollPasskey()` not called. **Update** "shows the biometric copy when the simulator flag is off" — the resting copy is now the unavailable line.
- `_bmad-output/implementation-artifacts/spec-dev-passkey-simulator-toggle.md` — **append a dated `## Spec Change Log` entry** (non-frozen) recording that this spec supersedes, in part, its frozen "Flag Off … must still emit `AuthAuthenticated` — release builds must keep logging in until FIDO lands" line. Do **not** edit its `<frozen-after-approval>` block.
- `sleep-apnea-detection-app/README.md` — where it describes the Passkey Simulator / passwordless login, note that with the flag **off**, passkey sign-in and enrollment are unavailable until FIDO2 is implemented (all builds).

## Tasks & Acceptance

**Execution:**
- [x] `sleep-apnea-detection-app/lib/core/bloc/auth/auth_state.dart` — added `AuthUnavailable(String message)` (Equatable `props` = `[message]`).
- [x] `sleep-apnea-detection-app/lib/core/bloc/auth/auth_bloc.dart` — `_onPasskeySubmitted`: `emit(AuthAuthenticated())` moved into the sim + `_passkeyAuthenticator != null` branches; the no-authenticator `else` emits `AuthUnavailable` and returns; `try/catch → AuthFailure` kept; `// TODO(FIDO)` marks the `else`.
- [x] `sleep-apnea-detection-app/lib/ui/pages/login_page.dart` — `if (state is AuthUnavailable)` renders `state.message` (`fontSize 12`, `AppColors.warningAmber`) + a `SizedBox(12)` between the auth card's `Spacer` and `SecurityBadgeOrganism`; button unchanged.
- [x] `sleep-apnea-detection-app/lib/ui/pages/onboarding_wizard_page.dart` — `_createPasskey`: `if (!_simulated) { setState(_error = "Passkey creation isn't available yet…"); return; }` before the `enrollPasskey()` call; the `_simulated ? … : …` body copy's false branch now says real passkey creation isn't available in this build yet.
- [x] `sleep-apnea-detection-app/test/core/bloc/auth_bloc_test.dart` — the flag-off/no-authenticator case now expects `[AuthInProgress, AuthUnavailable]` (renamed); added "flag Off with a non-throwing authenticator wired authenticates for real" → `AuthAuthenticated`.
- [x] `sleep-apnea-detection-app/test/ui/login_page_test.dart` — added "simulator off + no authenticator: Sign in shows an unavailable message and does not log in" (asserts the message, `onLoginSuccess` not called, and a repeat tap re-shows it); `setUp`/`tearDown` reset `PasskeySimulatorConfig.instance`.
- [x] `sleep-apnea-detection-app/test/ui/onboarding_wizard_page_test.dart` — replaced "shows the biometric copy when the simulator flag is off" with "passkey step, simulator off: shows the unavailable copy and Create Passkey is blocked" (resting copy, then tap → inline message, `repo.calls == 0`, `stage == onboarding`, `onboardingStep == passkeyEnrollment`).
- [x] `_bmad-output/implementation-artifacts/spec-dev-passkey-simulator-toggle.md` — appended a dated "superseded in part" entry to its `## Spec Change Log`; frozen block untouched.
- [x] `sleep-apnea-detection-app/README.md` — added a "Passkey Simulator (Settings → Developer)" subsection under Developer Mode describing on/off behavior and the release-build consequence.

**Acceptance Criteria:**
- Given the simulator is off and no `passkeyAuthenticator` is injected, when `AuthPasskeySubmitted` is dispatched, then the states are `[AuthInProgress, AuthUnavailable]` and never `AuthAuthenticated`.
- Given the simulator is off, when the user taps "Sign in with Passkey", then an inline unavailable message shows, `onLoginSuccess` is not called, and the button stays tappable.
- Given the simulator is off, when the user taps "Create Passkey" in step 3/3, then an inline unavailable message shows, `enrollPasskey()` is not called, and `AppFlowState` stays `stage: onboarding, onboardingStep: passkeyEnrollment`.
- Given the simulator is on, then sign-in and onboarding enrollment behave exactly as before.
- Given a `passkeyAuthenticator` is injected with the simulator off, when `AuthPasskeySubmitted` is dispatched, then it is awaited (`AuthAuthenticated`, or `AuthFailure` on throw) — the `AuthUnavailable` path is not taken.
- Given `cd sleep-apnea-detection-app && flutter analyze && flutter test`, then both pass.

## Spec Change Log

### 2026-09-10 — step-04 review pass (patch only, no loopback)

Three lenses (blind-hunter, edge-case, verification-gap) ran on the diff. No `intent_gap` / `bad_spec`; frozen block untouched. Patches applied:

- **all three lenses:** the message string was hardcoded and diverging across three sites. Extracted `const passkeyUnavailableMessage` in `auth_state.dart`; `AuthBloc` (`AuthUnavailable()` default), the onboarding `_error`, and the tests all use it. Reworded build-agnostic ("real FIDO2 authentication is not wired up in this build") — a release build has no toggle to point at.
- **blind-hunter + edge-case:** `LoginPage` now also renders `AuthFailure` (red) alongside `AuthUnavailable` (amber), wrapped in `Semantics(liveRegion: true)`, moved directly under the auth card.
- **verification-gap:** the "button stays enabled / repeat tap re-runs" claim was unverified (the second tap fell inside `throttleTime(300ms)`). Rewritten to assert `ElevatedButton.onPressed` is non-null after `AuthUnavailable`, then issue the second attempt *after* the throttle window and assert a fresh `[AuthInProgress, AuthUnavailable]` via a `bloc.stream` collector.
- **verification-gap:** added a `widget_test.dart` case that boots the real `MaskerApp`, forces the simulator off, taps "Sign in with Passkey", and asserts the unavailable message with no navigation — pins that `main` wires the gate in and wires no authenticator.
- **blind-hunter:** onboarding renders the "not wired up" message in `AppColors.warningAmber` (matching the "not a fault" framing), not the `_error` red; `onboarding_wizard_page_test.dart` got file-level singleton reset.
- **blind-hunter:** the supersession note in `spec-dev-passkey-simulator-toggle.md` rewritten as bullets naming the replacement I/O row.

Deferred (`deferred-work.md`): the `_passkeyAuthenticator` success/failure contract should be explicit before real FIDO2; the `developerBuild` expression is inlined in 3 places.

Rejected: adding a "skip passkey" path to onboarding (Ask-First'd and declined — the mid-onboarding dead-end when the simulator is off is the accepted consequence); conditionalising the `SecurityBadgeOrganism` "FIDO2 Hardware Encryption" copy (out of scope); the 1-frame `AuthInProgress` flash; onboarding not live-listening to the flag `ChangeNotifier` (pre-existing).

`flutter analyze` clean; `flutter test` 313 pass.

## Design Notes

New `AuthUnavailable`, not `AuthFailure`: "not implemented yet" is expected, not a fault; the error channel would style and log it wrongly.

Condition on `_passkeyAuthenticator == null`, not the flag: once real FIDO2 is wired (a non-null authenticator or a real ceremony in that `else`), the simulator-off path authenticates for real with no further change here. The `else` branch **is** the `// TODO(FIDO)` seam.

Reachability caveat (noted, not fixed here): on `main` the flag is only toggled from Settings → Developer, which is post-login, so a dev who turns it off and logs out cannot log back in. The sibling change that puts the toggle on `LoginPage` (`spec-passkey-simulator-toggle-on-login.md`, branch `feature/passkey-simulator-toggle-on-login`) makes the off state reachable pre-login; this spec pairs with that.

## Verification

**Commands:**
- `cd sleep-apnea-detection-app && flutter analyze` — expected: "No issues found!" (or only pre-existing `deferred-work.md` warnings).
- `cd sleep-apnea-detection-app && flutter test` — expected: full suite green.

**Manual checks:**
- `flutter run` (debug): log in (simulator on by default), Settings → Developer → turn "Passkey Simulator" off → log out. Tap "Sign in with Passkey" → amber "isn't available yet", no login. Turn the flag back on → sign-in works.
- Fresh install, flag off, run onboarding to step 3/3, tap "Create Passkey" → inline "isn't available yet", wizard stays on step 3/3.

## Suggested Review Order

**The contract — one shared message, one gate**

- Entry point: the retired fake fallback. The `else` (simulator off, no authenticator) now emits `AuthUnavailable` instead of a delayed `AuthAuthenticated`; the other two branches are unchanged.
  [`auth_bloc.dart:50`](../../sleep-apnea-detection-app/lib/core/bloc/auth/auth_bloc.dart#L50)
- The single source of truth for the copy — build-agnostic, used by the bloc, onboarding, and the tests.
  [`auth_state.dart:34`](../../sleep-apnea-detection-app/lib/core/bloc/auth/auth_state.dart#L34)

**UI — surface it, don't hide it**

- `LoginPage` renders `AuthUnavailable` (amber) and `AuthFailure` (red) inline under the auth card, in a `Semantics(liveRegion: true)` so a screen reader announces the outcome.
  [`login_page.dart:49`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L49)
- Onboarding step 3/3: `if (!_simulated)` short-circuits before `enrollPasskey()` — inline message, no advance; the message renders amber (not the `_error` red).
  [`onboarding_wizard_page.dart:118`](../../sleep-apnea-detection-app/lib/ui/pages/onboarding_wizard_page.dart#L118)

**Verification**

- End-to-end: boots the real `MaskerApp`, forces the flag off, taps Sign in → unavailable message, no navigation. Pins `main`'s wiring.
  [`widget_test.dart:26`](../../sleep-apnea-detection-app/test/widget_test.dart#L26)
- Bloc contract: flag-off + no authenticator → `AuthUnavailable`; flag-off + authenticator → real auth.
  [`auth_bloc_test.dart:99`](../../sleep-apnea-detection-app/test/core/bloc/auth_bloc_test.dart#L99)
- `LoginPage`: button stays enabled after `AuthUnavailable`; a post-throttle re-tap genuinely re-runs.
  [`login_page_test.dart:42`](../../sleep-apnea-detection-app/test/ui/login_page_test.dart#L42)
- Onboarding: resting copy + tap → blocked, `repo.calls == 0`, state unchanged.
  [`onboarding_wizard_page_test.dart:223`](../../sleep-apnea-detection-app/test/ui/onboarding_wizard_page_test.dart#L223)
