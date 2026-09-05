---
title: 'Epic 2 Story 2.5: Bluetooth Background-Access Priming & Permission Recovery'
type: 'feature'
created: '2026-09-05'
status: 'done'
review_loop_iteration: 0
baseline_commit: '03e839c51b7b31db263984691140a91eba0900d1'
context:
  - _bmad-output/epics.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app requests no runtime Bluetooth permission anywhere — `FlutterBlueSensorDriver.scanAndConnect()` goes straight to `FlutterBluePlus.startScan` and silently no-ops if denied, and neither `AndroidManifest.xml` nor `Info.plist` declare any Bluetooth permission at all. Story 2.4's app-boot BLE receiver (AD-12) cannot legally run without it.

**Approach:** Add a one-time priming screen shown after login (before the tab shell) that hands off to the native OS Bluetooth permission dialog(s), and make `MeasurementPage` check live permission status before scanning, rendering a blocked "Open Settings" state instead of silently failing when not granted. Gate on live permission status at each check, never a persisted "seen it" flag.

## Boundaries & Constraints

**Always:**
- Use `permission_handler` for all permission checks/requests (Android: `Permission.bluetoothScan` + `Permission.bluetoothConnect` requested together; iOS: `Permission.bluetooth`). No `shared_preferences` or other persistence — gating is always a live status check, never a stored flag, so a later revocation is caught on the next check.
- Follow existing constructor-DI pattern (`MeasurementPage(sensorDriver: ...)`) — both new widgets accept an optional injected `BlePermissionService` for testability.
- Primer screen has exactly one CTA, no skip/decline path. Whatever the OS dialog result, tapping it always advances past the primer — it never re-blocks itself.
- `MeasurementPage` re-checks permission status on `AppLifecycleState.resumed` so returning from Settings clears the blocked state without an app restart.

**Ask First:** None — native manifest/plist declarations below are required for the feature to function and are in scope.

**Never:**
- Never implement `BleReceiverForegroundNotification` / `BleNotProtectedNotification` or any Android Foreground Service / notification code — deferred, see `deferred-work.md`.
- Never make `BleReceiverService` or `BleSimulatorDriver` permission-aware — permission handling is UI-layer only, ahead of where those services are already invoked from `main.dart`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First reach after login | Permission not yet granted | Shows primer screen with CTA | N/A |
| CTA tapped, full grant | OS dialog(s) resolve granted | Advances to `MainContainerPage` | N/A |
| CTA tapped, full or partial denial | Android: one or both of scan/connect denied | Advances to `MainContainerPage` anyway (primer never blocks) | N/A |
| Already granted (e.g. re-login) | `checkPermission()` returns granted | Primer is skipped entirely | N/A |
| `MeasurementPage` reached, not granted | `checkPermission()` != granted | Renders blocked state naming the missing permission, "Open Settings" button, no scan UI | Button calls `openAppSettings()` |
| Permission granted while app backgrounded | User grants via Settings, returns to app | `didChangeAppLifecycleState(resumed)` re-checks; blocked state clears, scan proceeds | N/A |
| Permission already granted | `MeasurementPage` reached, granted | Existing `scanAndConnect()` flow runs unchanged | N/A |

</frozen-after-approval>

## Code Map

- `flutter/lib/core/permissions/ble_permission_service.dart` -- NEW. Wraps `permission_handler`: `checkPermission()`, `requestPermission()` (returns granted/denied/partial), `openSettings()`.
- `flutter/lib/ui/pages/ble_permission_primer_page.dart` -- NEW. Single-CTA screen; follow `login_page.dart:11-58`'s `StatelessWidget` + `Scaffold`/`SafeArea`/`Column` structure and `passkey_auth_card_organism.dart`'s button pattern.
- `flutter/lib/main.dart` -- `_MaskerAppState` (lines 29-52): replace the `_isLoggedIn` boolean gate with a small state enum (loggedOut / checkingPermission / needsPrimer / ready) so login success triggers a permission check before showing `MainContainerPage`.
- `flutter/lib/ui/pages/measurement_page.dart` -- `_connectBle()` (lines 56-63) and `_isBleConnected` field (line 37): check permission before `_bleDriver.scanAndConnect()`; add blocked-state rendering and a `WidgetsBindingObserver` resume hook.
- `flutter/pubspec.yaml` -- add `permission_handler` to `dependencies` (line 17 area).
- `flutter/android/app/src/main/AndroidManifest.xml` -- add `<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />` and `<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />` before the `<application>` block (line 2).
- `flutter/ios/Runner/Info.plist` -- add `NSBluetoothAlwaysUsageDescription` key/string, copy: "This app uses Bluetooth to connect to your D-BAND sensor and monitor your breathing while you sleep." (near line 27).

## Tasks & Acceptance

**Execution:**
- [x] `flutter/pubspec.yaml` -- add `permission_handler` dependency -- required by the service below.
- [x] `flutter/android/app/src/main/AndroidManifest.xml` -- add `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` permissions -- required for the OS dialogs to exist at all.
- [x] `flutter/ios/Runner/Info.plist` -- add `NSBluetoothAlwaysUsageDescription` -- required or iOS silently kills any Bluetooth call.
- [x] `flutter/lib/core/permissions/ble_permission_service.dart` -- create service -- single seam for permission logic, injectable into both consumers.
- [x] `flutter/lib/ui/pages/ble_permission_primer_page.dart` -- create primer screen -- the one-time onboarding beat.
- [x] `flutter/lib/main.dart` -- insert primer into the post-login gate -- matches the approved insertion point (after login, before the tab shell).
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- add permission check + blocked state + resume re-check -- closes the silent-failure gap.
- [x] `flutter/test/core/permissions/ble_permission_service_test.dart` -- unit tests -- cover granted/denied/partial/permanently-denied via `permission_handler`'s test platform override.
- [x] `flutter/test/ui/ble_permission_primer_page_test.dart` -- widget test -- CTA tap always advances regardless of mocked grant/deny result.
- [x] `flutter/test/ui/measurement_page_test.dart` -- new widget test -- blocked state renders when permission denied; clears on simulated resume once granted.
- [x] `flutter/lib/main.dart` -- add optional `permissionService` constructor param to `MaskerApp`, threaded to `_MaskerAppState` -- matching-testability gap found during Matrix Test Audit: rows "First reach after login" and "Already granted (e.g. re-login)" cover `_AppFlowState` gating logic that had no injection seam.
- [x] `flutter/test/app_flow_test.dart` -- new widget test -- covers the two matrix rows above: primer shown after login when not granted, primer skipped when already granted.
- [x] `flutter/lib/main.dart` -- add `permissionCheckFailed` flow state + retry UI, re-entrancy guard on `_handleLoginSuccess` -- patch from step-04 review: an unguarded `checkPermission()` throw left the app hanging on the checking-permission spinner forever.
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- add `_permissionCheckFailed` error state + retry UI, DEV_MODE bypass of the live permission gate, pluralization fix in blocked-state copy, decorative `Semantics` on the blocked-state icon, `openSettings()` failure feedback -- patches from step-04 review.
- [x] `flutter/lib/ui/pages/ble_permission_primer_page.dart` -- add `catch` alongside the existing `finally`, decorative `Semantics` on the icon, programmatic initial accessibility focus on the headline -- patches from step-04 review.
- [x] `flutter/test/app_flow_test.dart`, `flutter/test/ui/measurement_page_test.dart` -- add tests for the `partial`-grant case and the new throw-then-retry error paths.

**Acceptance Criteria:**
- Given permission not yet granted, when the user completes login, then the primer screen appears before `MainContainerPage`.
- Given permission already granted, when the user logs in, then the primer is skipped entirely.
- Given any OS dialog outcome, when the user taps the primer's CTA, then the app advances to `MainContainerPage` without exception.
- Given permission is not granted, when `MeasurementPage` is reached, then it renders a blocked state (no scan UI) instead of silently leaving `_isBleConnected = false`.
- Given the blocked state is showing, when the user grants permission via Settings and returns to the app, then the blocked state clears without restarting the app.

## Spec Change Log

- **Matrix Test Audit (step-03, pre-review):** The implementing subagent's report claimed full matrix coverage, but independent verification found `MaskerApp`/`_AppFlowState` (the "First reach after login" and "Already granted" rows) had zero test coverage and no DI seam to test it with — the existing `test/widget_test.dart` smoke test only exercises the logged-out state. Amended: added `permissionService` injection to `MaskerApp` and a new `test/app_flow_test.dart` covering both rows. Full suite re-verified at 67/67 passing after the fix.
- **Step-04 review (blind-hunter + edge-case-hunter + verification-gap, run in parallel):** No `intent_gap`/`bad_spec` findings — all real findings were mechanically fixable without renegotiating the frozen Intent/Boundaries/Matrix. Applied as patches (KEEP: everything in `<frozen-after-approval>` unchanged):
  - Unguarded `checkPermission()`/`requestPermission()` exceptions left the app hanging forever on the checking-permission spinner (empirically demonstrated by the verification-gap reviewer via a real `MissingPluginException` probe, which also silently broke `main_container_page_test.dart`'s "simulated BLE scan" comment without failing the test). Fixed with try/catch + a retry state in `main.dart` and `measurement_page.dart`, plus new tests exercising the throw-then-retry path.
  - `MeasurementPage`'s live permission gate unconditionally blocked the `DEV_MODE` simulator path, contradicting Story 1.5's "test without physical hardware" intent (the simulator touches no real Bluetooth). Fixed by exempting `_isDevMode` from the gate.
  - Minor patches: re-entrancy guard on `_handleLoginSuccess`; `openSettings()` failure now shows a snackbar instead of failing silently; pluralization grammar fix in blocked-state copy; decorative `Semantics` on the new Bluetooth icons and programmatic initial accessibility focus on the primer's headline, both per already-specified `EXPERIENCE.md`/`DESIGN.md` guidance that the first implementation pass missed; added a widget test for the `partial`-grant case on `MeasurementPage` (previously only unit-tested at the service layer).
  - 8 findings judged real but out of this story's scope or non-regressing (Android 10/11 legacy Bluetooth permission model, missing `bluetooth_le` uses-feature, radio-off detection, iOS `restricted` status handling, in-session permission revocation, `denied`-vs-`permanentlyDenied` retry UX, potential `flutter_blue_plus` double-prompt interaction, in-foreground revocation outside app lifecycle events) — logged to `deferred-work.md` rather than fixed here.
  - 1 finding rejected: non-Android/iOS platforms (Windows/macOS/Linux/Web) receiving Android-specific permissions — default Flutter multi-platform scaffolding, not an actual target for this mobile-only health app.
  - Full suite re-verified at 70/70 passing after all patches (67 + 3 new tests: 1 partial-grant case, 2 throw-then-retry cases).

## Design Notes

Dropped `shared_preferences` from the original plan: the UX spec explicitly requires permission state to be checked live "not a seen-it flag alone" (a stored-flag/reality drift was exactly what the UX accessibility review flagged as a risk). `permission_handler`'s status check is cheap enough to call on every gate evaluation and on every `MeasurementPage.initState()`/resume, so no persistence is needed.

`main.dart`'s new `checkingPermission` state is a brief native-call wait — render it as a minimal `Center(CircularProgressIndicator())`, not a full loading screen.

## Verification

**Commands:**
- `cd flutter && flutter test test/core/permissions/ble_permission_service_test.dart test/ui/ble_permission_primer_page_test.dart test/ui/measurement_page_test.dart test/app_flow_test.dart` -- expected: all pass.
- `cd flutter && flutter test` -- expected: full suite passes (70/70), no regressions.
- `cd flutter && flutter analyze` -- expected: no new warnings (5 pre-existing info-level warnings unrelated to this change).

**Manual checks (if no CLI):**
- Confirm `AndroidManifest.xml` and `Info.plist` diffs contain only the additions listed above, no unrelated changes.

## Suggested Review Order

**Permission gate & flow control**

- Entry point: the post-login gate state machine deciding primer vs. tab shell vs. retry.
  [`main.dart:30`](../../flutter/lib/main.dart#L30)

- Live permission check on login, with a re-entrancy guard and a retry path if the platform channel throws.
  [`main.dart:51`](../../flutter/lib/main.dart#L51)

**Permission service (the seam)**

- Single wrapper over `permission_handler`; no persistence by design — every call reflects live OS status.
  [`ble_permission_service.dart:31`](../../flutter/lib/core/permissions/ble_permission_service.dart#L31)

**Priming screen**

- Single-CTA onboarding screen; hands off to the OS dialog and always advances regardless of outcome.
  [`ble_permission_primer_page.dart:52`](../../flutter/lib/ui/pages/ble_permission_primer_page.dart#L52)

**MeasurementPage gating & recovery**

- Permission check before scanning, the DEV_MODE simulator bypass, and the retry-on-throw path.
  [`measurement_page.dart:76`](../../flutter/lib/ui/pages/measurement_page.dart#L76)

- Resume-triggered recheck so returning from Settings clears the blocked state without a restart.
  [`measurement_page.dart:109`](../../flutter/lib/ui/pages/measurement_page.dart#L109)

- Blocked-state UI naming the missing permission, with an Open Settings recovery path.
  [`measurement_page.dart:218`](../../flutter/lib/ui/pages/measurement_page.dart#L218)

**Native platform config**

- Android Bluetooth permissions declared for the first time in this app.
  [`AndroidManifest.xml:2`](../../flutter/android/app/src/main/AndroidManifest.xml#L2)

- iOS Bluetooth usage-description string, shown verbatim inside Apple's own system dialog.
  [`Info.plist:29`](../../flutter/ios/Runner/Info.plist#L29)

**Tests**

- Service-layer coverage of every OS-reported permission status via `permission_handler`'s test platform override.
  [`ble_permission_service_test.dart:1`](../../flutter/test/core/permissions/ble_permission_service_test.dart#L1)

- Gate-level coverage: primer shown/skipped, plus the throw-then-retry path.
  [`app_flow_test.dart:1`](../../flutter/test/app_flow_test.dart#L1)

- `MeasurementPage` coverage: blocked/partial/resume-recovery/throw-then-retry states.
  [`measurement_page_test.dart:1`](../../flutter/test/ui/measurement_page_test.dart#L1)
