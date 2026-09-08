---
title: 'Developer Options: Unbind BLE Device & Unregister User Account'
type: 'feature'
created: '2026-09-08'
status: 'done'
baseline_commit: '6d30129'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Developers and QA testers cannot easily reset the paired BLE sensor state or wipe patient authentication credentials to test the 4-Phase Onboarding Journey (Registration, Medical Profile, Passkey Enrollment, Bedtime Ready State) repeatedly without reinstalling the app.

**Approach:** Add two developer reset options under Developer Options (`DeveloperOptionsPage`): "Unbind BLE Sensor Device" (disconnects active BLE stream and resets noise floor envelope state) and "Unregister User Account" (dispatches `AuthUnregisterRequested` to `AuthBloc`, clearing local WebAuthn/Passkey credentials and navigating back to Phase 1 Onboarding).

## Boundaries & Constraints

**Always:** Gate developer tools behind the `_dev` flag (`DEV_MODE=true` environment define or `kDebugMode`). Require a 2-step confirmation dialog (`AlertDialog`) before executing destructive resets. Terminate active monitoring sessions before unbinding BLE hardware.

**Ask First:** Modifying production user profile schemas or deleting remote backend HIPAA audit logs without explicit confirmation.

**Never:** Expose reset options in production release builds where `DEV_MODE` is false. Never mutate global singleton states directly without using established service and BLoC methods.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Unbind BLE Device | Developer taps "Unbind BLE Sensor Device" and confirms dialog | `BleReceiverService.disconnect()` is called, stream resets to seeded resting value (`0.3`), snackbar shows success | If session is active, safely stops monitoring session first |
| Unregister User Account | Developer taps "Unregister User Account" and confirms dialog | `AuthBloc.add(AuthUnregisterRequested())` dispatched, local secure credentials wiped, UI pops to Onboarding root | If network offline, performs local storage reset with warning snackbar |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/pages/developer_options_page.dart` -- UI page where the Developer Tools card with Unbind Device and Unregister Account rows will be added.
- `flutter/lib/core/bloc/auth/auth_bloc.dart` -- Handles `AuthUnregisterRequested` event, clears cached credentials, and emits `AuthUnauthenticatedState`.
- `flutter/lib/core/bloc/auth/auth_event.dart` -- Declares `AuthUnregisterRequested` event class.
- `flutter/lib/core/ble/ble_receiver_service.dart` -- Manages active driver lifecycle and handles unbinding / resetting background telemetry queue.

## Tasks & Acceptance

**Execution:**
- [ ] `flutter/lib/core/bloc/auth/auth_event.dart` -- Add `AuthUnregisterRequested` event class to `AuthEvent` hierarchy.
- [ ] `flutter/lib/core/bloc/auth/auth_bloc.dart` -- Implement `_onUnregisterRequested` handler clearing local credentials and emitting `AuthUnauthenticatedState`.
- [ ] `flutter/lib/ui/pages/developer_options_page.dart` -- Add "Onboarding & Reset Tools" section with "Unbind BLE Sensor Device" and "Unregister User Account" menu rows and confirmation dialogs.
- [ ] `flutter/test/ui/developer_options_page_test.dart` -- Add widget unit test verifying Developer unbind and unregister actions.

**Acceptance Criteria:**
- Given Developer Mode is enabled (`DEV_MODE=true`), when navigating to Settings -> Developer Options, then the "Onboarding & Reset Tools" card renders "Unbind BLE Sensor Device" and "Unregister User Account".
- Given the developer confirms "Unbind BLE Sensor Device", when confirmed, then the BLE service disconnects, resets its telemetry stream, and displays a success notification.
- Given the developer confirms "Unregister User Account", when confirmed, then `AuthBloc` clears local credentials and returns the user to the Phase 1 Onboarding Registration screen.

## Verification

**Commands:**
- `flutter test test/ui/developer_options_page_test.dart` -- expected: SUCCESS
- `flutter test` -- expected: All 181+ tests pass

## Suggested Review Order

**UI Reset Controls**

- Developer menu card containing Unbind BLE Device and Unregister Account rows with 2-step confirmation dialogs.
  [`developer_options_page.dart:108`](../../flutter/lib/ui/pages/developer_options_page.dart#L108)

**Auth State Management**

- Handler resetting AuthBloc to AuthInitial unauthenticated state upon unregistration.
  [`auth_bloc.dart:23`](../../flutter/lib/core/bloc/auth/auth_bloc.dart#L23)

- AuthUnregisterRequested event definition extending AuthEvent hierarchy.
  [`auth_event.dart:18`](../../flutter/lib/core/bloc/auth/auth_event.dart#L18)

**Automated Unit Tests**

- Widget unit test suite verifying dialog confirmations, BLE device reset, and user unregistration flows.
  [`developer_options_page_test.dart:1`](../../flutter/test/ui/developer_options_page_test.dart#L1)

