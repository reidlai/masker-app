---
title: 'Passkey Simulator toggle on the sign-in screen'
type: 'feature'
created: '2026-09-10'
status: 'done'
review_loop_iteration: 0
baseline_commit: '1c2f51d017610d075f21f8b06e7200a0cfab3feb'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The "Passkey Simulator" developer flag decides whether "Sign in with Passkey" runs the simulated always-succeeds path or the real FIDO2 path, but its only control lives in Settings → Developer — unreachable before sign-in. On the sign-in screen a developer/QA cannot see or change which path the button takes, and nothing signals the auth is simulated (the flag defaults On in dev builds).

**Approach:** Add a second "Passkey Simulator" control on `LoginPage`, between the passkey auth card and the security badge, bound to the same `PasskeySimulatorConfig.instance` singleton as the Settings row so both stay in sync through its `ChangeNotifier`. Gate its visibility on the exact `kDebugMode || DEV_MODE` condition the Settings row uses. When the flag is on, show a visible "Simulated authentication — not real FIDO2" caption. Leave the Settings → Developer row unchanged.

## Boundaries & Constraints

**Always:**
- The login control renders only when `kDebugMode || DEV_MODE` — the same disjunction `settings_page.dart` uses. Release build (neither flag): absent, and `passkeySimulatorActive(developerBuild: false)` stays `false`.
- Both switches bind the one `PasskeySimulatorConfig.instance` via `ListenableBuilder`. No local `bool`, no new provider, no second source of truth.
- Flag default (`true`) and no-persistence behavior unchanged. No change to `auth_bloc.dart`, `passkey_simulator_config.dart`, `main.dart`, or onboarding enrollment.
- Caption "Simulated authentication — not real FIDO2" is visible exactly when `isEnabled`.
- The login `Switch` is non-interactive (`onChanged: null`) while `state is AuthInProgress`, and carries `Key('passkey-simulator-switch-login')` plus a `Semantics` label marking it developer-only.
- `LoginPage` gains an optional `bool? developerEnabled` ctor param (default `const bool.fromEnvironment('DEV_MODE', defaultValue: false)`), mirroring `SettingsPage`; the `main.dart` call site is unchanged.
- `LoginPage`'s body does not overflow with the extra control on a short viewport.
- New behavior covered by widget tests; `flutter analyze` clean.

**Ask First:**
- Persisting the flag or changing its default.
- Making the login control differ from the Settings row beyond the caption and the in-progress disable.
- Removing the Settings → Developer row.
- Touching `AuthBloc`, `passkey_simulator_config.dart`, or onboarding enrollment.

**Never:**
- Show the control, or let the flag take effect, in a release build.
- Let the flag gate anything beyond what it gates today (the `AuthBloc` passkey-submit branch and the existing onboarding read).
- Narrow the gate to `DEV_MODE`-only — it must match the Settings row so both appear/disappear together.
- Add a logout / re-auth path (out of scope).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Dev build, flag On (default) | `kDebugMode || DEV_MODE`, `isEnabled` | Control visible between card and badge, switch On; caption shown |
| Dev build, flag Off | same gate, `!isEnabled` | Switch Off; caption absent; sign-in uses real authenticator / today's fallback |
| Release build | neither flag | Control absent; no caption; gate `false` regardless of stored flag |
| Toggle on either surface | flip login or Settings switch | `instance.isEnabled` flips; the other surface reflects it next build; next `AuthPasskeySubmitted` uses the new value |
| Toggle while authenticating | `state is AuthInProgress` | Login switch disabled, no-op; Settings row unaffected |
| Short viewport / landscape | reduced height | Body scrolls; no RenderFlex overflow |

</frozen-after-approval>

## Code Map

- `sleep-apnea-detection-app/lib/ui/pages/login_page.dart` — `LoginPage` (StatelessWidget, `onLoginSuccess` only). `BlocConsumer<AuthBloc,AuthState>` :18; `isAuthenticating = state is AuthInProgress` :25; body `Column(mainAxisAlignment: center)` :32 = `[Spacer, BrandHeaderOrganism, Spacer, PasskeyAuthCardOrganism, Spacer, SecurityBadgeOrganism, SizedBox(24)]`. **Change:** add `debuggingEnabled` + `developerEnabled` nullable fields + ctor params (exact mirror of `SettingsPage`); `_showDev` getter = `(debuggingEnabled ?? kDebugMode) || (developerEnabled ?? const bool.fromEnvironment('DEV_MODE', defaultValue: false))` (import `package:flutter/foundation.dart`); replace the final `Spacer` with a `_showDev`-gated `ListenableBuilder(listenable: PasskeySimulatorConfig.instance)` rendering the row + caption; make the outer layout scroll-safe (`LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight` so the `Spacer`s still center on tall screens). Two seams (not one) so a test can drive the gate to `false` even though `kDebugMode` is `true` under `flutter test`.
- `sleep-apnea-detection-app/lib/core/config/passkey_simulator_config.dart` — **READ-ONLY.** `ChangeNotifier` singleton `PasskeySimulatorConfig.instance`: `isEnabled` (default `true`), `setEnabled` (change-only notify), `reset()`. Top-level `passkeySimulatorActive({required bool developerBuild}) = developerBuild && instance.isEnabled`.
- `sleep-apnea-detection-app/lib/ui/pages/settings_page.dart:27-30, 179-197` — **READ-ONLY reference.** `_showDeveloper = (debuggingEnabled ?? kDebugMode) || (developerEnabled ?? bool.fromEnvironment('DEV_MODE'))` — copy the param idiom and disjunction. Existing passkey row: `ListenableBuilder` → `SettingsMenuRow(Icons.fingerprint, "Passkey Simulator", trailingWidget: Switch(key: Key('passkey-simulator-switch'), activeThumbColor: AppColors.accentGreen, onChanged: PasskeySimulatorConfig.instance.setEnabled))` — mirror this shape.
- `sleep-apnea-detection-app/lib/ui/organisms/security_badge_organism.dart` — **READ-ONLY.** Renders the HIPAA / FIDO2 line (`fontSize 12`, `AppColors.textSecondary`) directly below the new caption — keep them distinct (caption in `AppColors.warningAmber`). Styling precedent for a dev-framed container: `developer_simulator_bar_organism.dart` (surface bg, teal border, small-caps header).
- `sleep-apnea-detection-app/lib/core/bloc/auth/auth_bloc.dart:20-24, 36-57` / `lib/main.dart:66-76, 135-145` — **READ-ONLY, no edit.** `AuthPasskeySubmitted` is `throttleTime(300ms).switchMap`; `_onPasskeySubmitted` reads `_isPasskeySimulatorEnabled()` once, synchronously, after `emit(AuthInProgress())` → a mid-flight toggle can't change an in-progress attempt (the disable is for clarity). `LoginPage(onLoginSuccess: …)` and the `AuthBloc` wiring need no change (new param defaults).
- `sleep-apnea-detection-app/test/ui/login_page_test.dart` — one widget test; builds its own `AuthBloc`, imports `package:masker_app/...`, does **not** reset `PasskeySimulatorConfig`. **Change:** add `setUp`/`addTearDown` → `PasskeySimulatorConfig.instance.reset()`; add the matrix cases (gate visible with `developerEnabled: true`; absent with `debuggingEnabled: false, developerEnabled: false`; toggle via `Key('passkey-simulator-switch-login')` flips `instance.isEnabled`; caption only when enabled; switch disabled while an `AuthInProgress`-stuck `AuthBloc` is provided).
- `sleep-apnea-detection-app/test/ui/settings_page_test.dart:39, 171-189` — **READ-ONLY / regression.** Already resets the config and drives `passkey-simulator-switch`; must stay green under the shared singleton.
- `sleep-apnea-detection-app/README.md` — references the toggle's location; **update** to add the sign-in-screen control.

## Tasks & Acceptance

**Execution:**
- [x] `sleep-apnea-detection-app/lib/ui/pages/login_page.dart` — added `debuggingEnabled` + `developerEnabled` params + `_showDev` gate (exact `SettingsPage` mirror); gated "Passkey Simulator" row (`Icons.fingerprint` label + `Switch(key: Key('passkey-simulator-switch-login'))` in `Semantics(label: 'Passkey Simulator, developer only')`, bound to `PasskeySimulatorConfig.instance` via `ListenableBuilder`) in the final `Spacer` slot above `SecurityBadgeOrganism`; `AppColors.warningAmber` caption when `isEnabled`; `onChanged: null` while `state is AuthInProgress`; body wrapped in `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight)` + `IntrinsicHeight`.
- [x] `sleep-apnea-detection-app/test/ui/login_page_test.dart` — `PasskeySimulatorConfig.instance.reset()` in `setUp`/`tearDown`; 7 cases (gate ON, gate OFF with both seams false, toggle flips singleton + caption, Settings-side change reflected, switch disabled during `AuthInProgress` via `_ProbeAuthBloc` with no `addTearDown(bloc.close)`, no overflow at 320×480, plus the kept render/tap case).
- [x] `sleep-apnea-detection-app/README.md` — documented the sign-in-screen location under "How to Start Developer Mode".

**Acceptance Criteria:**
- Given a release build (neither `kDebugMode` nor `DEV_MODE`), when `LoginPage` renders, then no Passkey Simulator control and no simulated-auth caption appear.
- Given a dev build, when the flag is toggled on the login screen and Settings → Developer is then opened, then that row's switch shows the same value (and the reverse holds), with no path other than `PasskeySimulatorConfig.instance`.
- Given the login screen with the flag enabled, when it renders, then a visible caption states the auth is simulated; disabled, no such caption.
- Given `state is AuthInProgress`, when the user taps the login switch, then `PasskeySimulatorConfig.instance.isEnabled` does not change.
- Given `cd sleep-apnea-detection-app && flutter analyze && flutter test`, then both pass, including the updated `login_page_test.dart` and unchanged `settings_page_test.dart` / `passkey_simulator_config_test.dart`.

## Spec Change Log

### 2026-09-10 — step-04 review pass (patch only, no loopback)

Three lenses (blind-hunter, edge-case, verification-gap) ran on the diff. No `intent_gap` / `bad_spec`; frozen block untouched. Patches applied:

- **verification-gap + blind-hunter:** the `developerEnabled ?? DEV_MODE` half of `_showDev` was untested (every login test runs with `kDebugMode == true`). Added `developer gate ON via the DEV_MODE seam alone (debug seam false)`.
- **edge-case + blind-hunter:** `ConstrainedBox(minHeight: constraints.maxHeight)` guarded with `.isFinite ? … : 0`.
- **blind-hunter:** README wording corrected (real FIDO2 is "once an authenticator is wired") and expanded (default-on / in-memory / release-absent).
- **blind-hunter:** `_DevPasskeySimRow` icon `Icons.fingerprint` → `Icons.developer_mode`; row wrapped in `MergeSemantics`, `Switch` semantics label cut to `"Developer only"` to stop a screen reader double-announcing "Passkey Simulator".
- **verification-gap:** added a positional assertion (switch between `PasskeyAuthCardOrganism` and `SecurityBadgeOrganism`); caption given `Key('passkey-sim-caption')`.
- **blind-hunter:** in-progress test also asserts the switch re-enables after `AuthInProgress` clears.

Deferred (`deferred-work.md`): DEV_MODE auth-simulation hardening (audit trail + louder warning + QA-build policy) now that the toggle is pre-auth — pre-existing, applies equally to the Settings row.

Rejected: OFF-state indicator and security-badge adjacency (settled by frozen intent), the throttle-window race (flag read synchronously in `_onPasskeySubmitted`), whole-row tap parity, `IntrinsicHeight` intrinsic-incompatible-descendant crash (`MaskerApp boots to the login screen` renders the real tree).

`flutter analyze` clean; `flutter test` 317 pass.

## Design Notes

Second control, not a move: the flag governs this screen's own button and is unreachable pre-login, so surfacing it here is transparency for QA/demos; keeping the Settings row preserves post-login access. One `ChangeNotifier` singleton → both `ListenableBuilder`s rebuild on any change, no cross-wiring.

The caption matters because the flag defaults **on** in dev builds while the screen advertises "FIDO2 Hardware Encryption" — without it, a debug build silently presents fake auth under a hardware-security claim.

Sketch (in place of the final `Spacer`):

```dart
if (_showDev)
  ListenableBuilder(
    listenable: PasskeySimulatorConfig.instance,
    builder: (context, _) {
      final on = PasskeySimulatorConfig.instance.isEnabled;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        _DevPasskeySimRow(value: on,
          onChanged: isAuthenticating ? null : PasskeySimulatorConfig.instance.setEnabled),
        if (on) const Text('Simulated authentication — not real FIDO2',
          style: TextStyle(fontSize: 12, color: AppColors.warningAmber)),
      ]);
    },
  ),
```

## Verification

**Commands:**
- `cd sleep-apnea-detection-app && flutter analyze` — expected: "No issues found!" (or only pre-existing `deferred-work.md` warnings).
- `cd sleep-apnea-detection-app && flutter test` — expected: full suite green, including the updated `login_page_test.dart`.

**Manual checks:**
- `flutter run` (plain debug) and `flutter run --dart-define=DEV_MODE=true`: the sign-in screen shows the "Passkey Simulator" row (On) with the caption between the passkey card and the HIPAA badge; toggling it and opening Settings → Developer shows the same state.
- A build with neither `kDebugMode` nor `DEV_MODE`: row and caption absent.

## Suggested Review Order

**The gate — must stay identical to the Settings row**

- Entry point: the disjunction that decides whether the dev row shows; must match `SettingsPage._showDeveloper` exactly.
  [`login_page.dart:33`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L33)
- Two nullable seams (not one) mirroring `SettingsPage`, so a widget test can force the gate off despite `kDebugMode == true`.
  [`login_page.dart:21`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L21)

**UI binding — one singleton, two switches**

- The gated block: `ListenableBuilder` on the shared `PasskeySimulatorConfig.instance`, so this switch and the Settings row rebuild together.
  [`login_page.dart:83`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L83)
- `onChanged: null` while `state is AuthInProgress` disables the switch; the amber caption renders only while the flag is on.
  [`login_page.dart:104`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L104)
- The dev-framed row widget: `Icons.developer_mode` (not the biometric glyph), `MergeSemantics` to avoid a double screen-reader announcement.
  [`login_page.dart:144`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L144)

**Layout — scroll-safe so the extra control can't overflow**

- `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight, .isFinite-guarded)` + `IntrinsicHeight` keeps the `Spacer`s centering on tall screens and lets short screens scroll.
  [`login_page.dart:56`](../../sleep-apnea-detection-app/lib/ui/pages/login_page.dart#L56)

**Supporting**

- `_ProbeAuthBloc` drives `AuthState` directly (no rxdart transformer / timers under fake-async); note the deliberate absence of `addTearDown(bloc.close)`.
  [`login_page_test.dart:19`](../../sleep-apnea-detection-app/test/ui/login_page_test.dart#L19)
- Singleton reset in `setUp`/`tearDown` — `PasskeySimulatorConfig.instance` is process-global.
  [`login_page_test.dart:25`](../../sleep-apnea-detection-app/test/ui/login_page_test.dart#L25)
- Gate coverage: the `DEV_MODE` seam alone (debug seam forced false), and a positional assertion that the row sits between card and badge.
  [`login_page_test.dart:90`](../../sleep-apnea-detection-app/test/ui/login_page_test.dart#L90)
- README: the sign-in-screen control documented under "How to Start Developer Mode".
  [`README.md:119`](../../sleep-apnea-detection-app/README.md#L119)
