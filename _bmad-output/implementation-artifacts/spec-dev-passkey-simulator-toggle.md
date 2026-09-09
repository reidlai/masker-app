---
title: 'Developer Settings: rename BLE Simulator + add Passkey Simulator toggle'
type: 'feature'
created: '2026-09-09'
status: 'done'
review_loop_iteration: 0
baseline_commit: 'e55e4fca54819c5f6ae6e26ecfd50f03e94594ce'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Settings → Developer section has one toggle labeled "Simulator" (BLE telemetry only). Nothing gives QA runtime control over the fake-passkey login path ahead of the upcoming FIDO2/WebAuthn work.

**Approach:** Rename that row to "BLE Simulator" and add a sibling "Passkey Simulator" toggle (default On), shown only under `DEV_MODE`. A new reactive singleton `PasskeySimulatorConfig` holds the flag; `AuthBloc._onPasskeySubmitted` branches on it. Today On and Off both keep the current fake-success behavior — Off only adds the branch point where real FIDO will later attach. Outside `DEV_MODE` the flag is forced Off and the row hidden.

## Boundaries & Constraints

**Always:**
- Passkey Simulator row renders only when `_dev` is true (`developerEnabled ?? bool.fromEnvironment('DEV_MODE')`), never on `kDebugMode` alone. BLE Simulator row keeps its current `_showDeveloper` gate.
- Flag default is On. `PasskeySimulatorConfig` is an in-memory `ChangeNotifier` singleton — no persistence, resets to On each launch (matches `BleSimulatorDriver`/`SimulatorBloc`).
- Simulated passkey path is behaviorally unchanged: `AuthInProgress` → ~800ms → `AuthAuthenticated`.
- Flag Off with no real authenticator wired must still emit `AuthAuthenticated` — `DEV_MODE`-off / release builds must keep logging in. Mark the FIDO attach point `// TODO(FIDO):`.
- New `AuthBloc` ctor param defaults so every existing `auth_bloc_test.dart` case passes unchanged.
- Key both Developer-section `Switch`es so tests target each one.
- `flutter analyze` clean; changed behavior covered by widget + bloc tests.

**Ask First:**
- Adding persistence for the flag.
- Writing real FIDO2/WebAuthn logic, or making Off visibly differ from On.
- Renaming the "BLE Telemetry Simulator" card/header on `developer_options_page.dart`.

**Never:**
- Show the Passkey Simulator row in release / `DEV_MODE`-off builds.
- Let the flag gate anything except the `AuthBloc` passkey-submit branch.
- Touch `developer_options_page.dart`, the BLE simulator drivers, or `SimulatorBloc`.
- Add a logout / re-auth path (known limitation, see Design Notes) — out of scope.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Behavior |
|----------|--------------|-------------------|
| Row visibility | `_dev` true | "BLE Simulator" + "Passkey Simulator" both render; Passkey switch On |
| Row visibility | `_debug` only (`_dev` false) | "BLE Simulator" renders; "Passkey Simulator" absent |
| Toggle Passkey Simulator | Dev taps the switch | `PasskeySimulatorConfig.instance.isEnabled` flips; switch rebuilds via `ChangeNotifier` |
| Sign-in, flag On | `AuthPasskeySubmitted` | `AuthInProgress` → ~800ms → `AuthAuthenticated`; injected `passkeyAuthenticator` NOT called |
| Sign-in, flag Off, authenticator wired | `AuthPasskeySubmitted`, `passkeyAuthenticator != null` | awaits it → `AuthAuthenticated`; throw → `AuthFailure(e)` |
| Sign-in, flag Off, no authenticator | `AuthPasskeySubmitted`, `passkeyAuthenticator == null` | `AuthInProgress` → ~800ms → `AuthAuthenticated` (today's fallback) |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/pages/settings_page.dart` — Developer card. `_dev` getter L28-29. BLE row `Builder`/`BlocBuilder<SimulatorBloc>` L121-161: relabel `"Simulator"`→`"BLE Simulator"` (L135), key its `Switch` (L140). Insert `if (_dev) ...[Divider, PasskeySimulatorRow]` after that `Builder`, before the `_debug` block at L162.
- `flutter/lib/core/config/passkey_simulator_config.dart` — NEW. `ChangeNotifier` singleton: `static final instance`, `bool get isEnabled` (default `true`), `setEnabled(bool)`→`notifyListeners()`, `reset()` for tests. Plus top-level `passkeySimulatorActive({required bool devMode})` = `devMode && instance.isEnabled` — the single production gate `main` wires in (testable in the `DEV_MODE`-off env; added in review to close a verification gap).
- `flutter/test/core/config/passkey_simulator_config_test.dart` — NEW. Covers the default, change-only notification, `reset()`, and the `passkeySimulatorActive` gate (always false outside `DEV_MODE`; mirrors the flag under it).
- `flutter/lib/core/bloc/auth/auth_bloc.dart` — `_onPasskeySubmitted` L28-43 (`_passkeyAuthenticator != null ? await : 800ms`). Add `final bool Function() _isPasskeySimulatorEnabled;` ctor param, default `() => false`. Rebranch: simulate → real authenticator → fallback delay (Design Notes).
- `flutter/lib/main.dart` — L122 `AuthBloc()`: pass `isPasskeySimulatorEnabled: () => passkeySimulatorActive(devMode: const bool.fromEnvironment('DEV_MODE', defaultValue: false))`; add import.
- `flutter/lib/ui/molecules/settings_menu_row.dart` — READ-ONLY. Reuse: `showChevron: false`, `trailingWidget: Switch(...)` — the BLE row idiom.
- `flutter/test/ui/settings_page_test.dart` — `find.text('Simulator')`→`'BLE Simulator'` (L39, 48, 58, 124); toggling test (L63-80) now has 2 `Switch`es, tap the BLE one by key; add Passkey Simulator visible-under-`_dev` / absent-under-`_debug`-only / default-On / tap-flips-config cases; `PasskeySimulatorConfig.instance.reset()` in `setUp`.
- `flutter/test/core/bloc/auth_bloc_test.dart` — existing cases stay green (default closure → false). Add: On + throwing authenticator → `[AuthInProgress, AuthAuthenticated]`; Off + throwing authenticator → `[AuthInProgress, AuthFailure]`; Off + no authenticator → `[AuthInProgress, AuthAuthenticated]`.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/config/passkey_simulator_config.dart` — create the `ChangeNotifier` singleton.
- [x] `flutter/lib/core/bloc/auth/auth_bloc.dart` — add `isPasskeySimulatorEnabled` param (default `() => false`); rebranch `_onPasskeySubmitted`; `// TODO(FIDO):` at the authenticator branch.
- [x] `flutter/lib/main.dart` — wire the closure from `DEV_MODE` && `PasskeySimulatorConfig.instance.isEnabled`.
- [x] `flutter/lib/ui/pages/settings_page.dart` — relabel to `"BLE Simulator"`; key the BLE `Switch`; add `_dev`-gated "Passkey Simulator" row bound to `PasskeySimulatorConfig` via `ListenableBuilder`.
- [x] `flutter/test/core/bloc/auth_bloc_test.dart` — add the three flag-branch cases.
- [x] `flutter/test/ui/settings_page_test.dart` — fix renamed finders, disambiguate the BLE switch tap, add the Passkey Simulator cases, reset config in `setUp` (also added `ensureVisible` before the pre-existing "Developer" nav tap — the extra row pushed it past the 600px test viewport).

**Acceptance Criteria:**
- Given `DEV_MODE` on, when the Developer section renders, then rows read "BLE Simulator" and "Passkey Simulator" with the Passkey switch On.
- Given `kDebugMode` on but `DEV_MODE` off, when the Developer section renders, then "Passkey Simulator" is absent and "BLE Simulator" present.
- Given the Passkey Simulator switch is toggled, then `PasskeySimulatorConfig.instance.isEnabled` matches it and listeners rebuild.
- Given the flag Off with a real `passkeyAuthenticator`, when `AuthPasskeySubmitted` fires, then it is awaited and a throw surfaces as `AuthFailure`.
- Given the flag Off with no authenticator, when `AuthPasskeySubmitted` fires, then `AuthAuthenticated` is still emitted.
- Given the suite, when `cd flutter && flutter analyze && flutter test` runs, then both pass clean.

## Spec Change Log

### 2026-09-09 — review pass (patch only, no loopback)
- **patch** (verification-gap): the "never simulate auth outside `DEV_MODE`" rule existed only as an inline `&&` in `main.dart` with no test. Extracted to `passkeySimulatorActive({required bool devMode})` in `passkey_simulator_config.dart` and added `passkey_simulator_config_test.dart` pinning `devMode: false` → always `false`. No frozen-block change.
- **defer**: pre-existing `flutter analyze` warning `settings_page.dart:4` unused import `ble_simulator_driver.dart` — recorded in `deferred-work.md`, not caused by this change.

## Design Notes

`_onPasskeySubmitted`, after `emit(const AuthInProgress())`:

```dart
if (_isPasskeySimulatorEnabled()) {
  await Future.delayed(const Duration(milliseconds: 800)); // simulated passkey — unchanged
} else if (_passkeyAuthenticator != null) {
  await _passkeyAuthenticator!();                          // TODO(FIDO): real FIDO2/WebAuthn authenticator
} else {
  await Future.delayed(const Duration(milliseconds: 800)); // no real authenticator yet — preserve today's success
}
emit(const AuthAuthenticated());
```

Flag lives in `PasskeySimulatorConfig`, not `AuthBloc` state: `AuthBloc` is built once at app root before login, so it reads the flag through the injected closure at event time (change applies to the next `AuthPasskeySubmitted`). Known limitation, out of scope: no UI logout/re-auth path exists (`AuthLogoutRequested` is undispatched; `AppFlowBloc` has no return to `loggedOut`), so a mid-session toggle has no visible effect until relaunch — fine, since On and Off are behaviorally identical today. Wrap only the Passkey Simulator row in `ListenableBuilder(listenable: PasskeySimulatorConfig.instance, ...)` so its `Switch` rebuilds without a Bloc.

## Verification

**Commands:**
- `cd flutter && flutter analyze` — expected: "No issues found!"
- `cd flutter && flutter test` — expected: all pass, incl. updated `settings_page_test.dart` and `auth_bloc_test.dart`.

**Manual checks:**
- `flutter run --dart-define=DEV_MODE=true`: Developer section shows both toggles, Passkey Simulator On; toggling it still lets sign-out/sign-in succeed.
- `flutter run` (no DEV_MODE): Developer section shows "BLE Simulator" only.

## Suggested Review Order

**Auth branch (design intent)**

- Entry point: 3-way passkey branch — simulator flag first, then real authenticator, then today's fallback.
  [`auth_bloc.dart:42`](../../flutter/lib/core/bloc/auth/auth_bloc.dart#L42)
- New injected predicate; defaults `() => false` so every existing caller/test keeps its behavior.
  [`auth_bloc.dart:12`](../../flutter/lib/core/bloc/auth/auth_bloc.dart#L12)
- Where real FIDO2/WebAuthn attaches when the flag is off.
  [`auth_bloc.dart:46`](../../flutter/lib/core/bloc/auth/auth_bloc.dart#L46)

**Flag holder + production gate**

- In-memory `ChangeNotifier` singleton, default enabled, change-only notification.
  [`passkey_simulator_config.dart:13`](../../flutter/lib/core/config/passkey_simulator_config.dart#L13)
- The single gate: `devMode && isEnabled` — always false outside `DEV_MODE`, so release builds can't bypass auth.
  [`passkey_simulator_config.dart:38`](../../flutter/lib/core/config/passkey_simulator_config.dart#L38)
- Wiring: `main` passes the compile-time `DEV_MODE` into that gate.
  [`main.dart:127`](../../flutter/lib/main.dart#L127)

**Settings UI**

- Rename to "BLE Simulator" + a `Key` on its switch so both toggles are addressable.
  [`settings_page.dart:136`](../../flutter/lib/ui/pages/settings_page.dart#L136)
- New `_dev`-only "Passkey Simulator" row; `ListenableBuilder` rebuilds the switch without a Bloc.
  [`settings_page.dart:164`](../../flutter/lib/ui/pages/settings_page.dart#L164)

**Tests**

- Three flag-branch cases: On bypasses a throwing authenticator; Off routes to it; Off+none still authenticates.
  [`auth_bloc_test.dart:63`](../../flutter/test/core/bloc/auth_bloc_test.dart#L63)
- Gate pinned: `passkeySimulatorActive(devMode: false)` is always false.
  [`passkey_simulator_config_test.dart:36`](../../flutter/test/core/config/passkey_simulator_config_test.dart#L36)
- Row visibility per flag, default On, toggle flips the singleton; BLE switch tapped by key.
  [`settings_page_test.dart:88`](../../flutter/test/ui/settings_page_test.dart#L88)
