# Deferred Work

Findings surfaced during build reviews that were intentionally not addressed in their originating story. Append-only.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Inert Settings rows (Debugging / Developer) are not announced to assistive tech as disabled / not-actionable.
  evidence: EXPERIENCE.md v1.1.0 Accessibility Floor requires inert rows be "announced with a dimmed, not-actionable state rather than being silently unfocusable." `SettingsMenuRow`'s inert variant renders a plain `Row` with no `Semantics(enabled: false)`. The whole app currently has zero `Semantics` usage, so this is an app-wide accessibility gap, not a regression from this change — worth a focused a11y pass.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Row dividers in the Settings list are handled ad hoc in `settings_page.dart`, not by the `SettingsMenuRow` component.
  evidence: DESIGN.md §6 specifies a "1px #334155 divider between rows (never after the last)." This build only has the single Profile row plus a manual `Divider` between Debugging/Developer, so it is not yet a defect. When the planned rows (Notifications, Account, Sign out, About, Caregiver contacts) land, divider handling should move into the component or a shared list wrapper.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: BleReceiverForegroundNotification / BleNotProtectedNotification (persistent Android Foreground Service notifications confirming BLE receiver status) and the Night Mode accessible label on MeasurementPage's monitoring state.
  evidence: Story 2.5's acceptance criteria cover this, but the codebase has zero existing notification/foreground-service infrastructure (no `flutter_local_notifications`, no `flutter_background_service`, no native Android Foreground Service code, no platform channel). Building it is a meaningfully separate native-platform undertaking from the permission-priming screen and OS permission hand-off, which spec-2-5 covers instead. Split approved by Reid during spec planning, 2026-09-05.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Android 10/11 (API 29-30, below the API 31 threshold where `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` exist) have no legacy Bluetooth permission fallback declared — no `android.permission.BLUETOOTH`/`BLUETOOTH_ADMIN` (maxSdkVersion 30) or `ACCESS_FINE_LOCATION` (maxSdkVersion 30, required for BLE scanning pre-API-31).
  evidence: The UX Foundation states the target as "iOS 15+ & Android 10+," so Android 10-11 are explicitly in scope, but `permission_handler`'s `bluetoothScan`/`bluetoothConnect` map to nothing meaningful below API 31 — real BLE scanning on those OS versions needs the legacy permission model instead. Not a regression (zero permissions were requested at all before this story), but incomplete for the full stated OS range. Surfaced by the blind-hunter review lens during step-04; classified as defer rather than a blocking gap since nothing is made worse, but it needs a dedicated follow-up (either add the legacy fallback, or make an explicit product call to raise the minimum supported Android version for this feature to 12+).

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Missing `<uses-feature android:name="android.hardware.bluetooth_le" android:required="true"/>` in `AndroidManifest.xml`.
  evidence: Commonly declared alongside BLE permissions to filter the app to BLE-capable devices on the Play Store; absent here. Low risk, cheap to add whenever `AndroidManifest.xml` is next touched.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Bluetooth radio/adapter power state (as opposed to OS permission grant) is never checked or messaged — a user with permission granted but Bluetooth switched off gets no dedicated UI, just a silent `scanAndConnect()` failure.
  evidence: `permission_handler`'s `checkServiceStatus` API exists for exactly this but is unused by `BlePermissionService`. Out of this story's stated Problem (permission, not radio state), but a real adjacent gap.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: iOS `restricted` permission status (MDM/parental-control managed devices) is treated identically to plain `denied` — the blocked state always offers "Open Settings," which may be a dead end since a restricted permission generally cannot be granted from Settings by the user at all.
  evidence: Narrow edge case (managed/parental-control iOS devices) for this patient population; real but low-frequency. Worth distinguishing in copy in a future pass.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Permission revocation *during* an active nocturnal monitoring session (not just during the pre-monitoring pairing/blocked state) is never detected or handled — `build()`'s permission-blocked branch is only reached when not monitoring and not showing the alert overlay.
  evidence: A patient's monitoring session could be silently compromised if the OS revokes Bluetooth permission mid-night. Real safety-relevant gap, but squarely Epic 3's concern (nocturnal monitoring resilience), not Story 2.5's (pairing/calibration, before monitoring begins) — this story never claimed to cover in-session revocation.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: `denied` and `permanentlyDenied` are collapsed into one blocked-state treatment on `MeasurementPage` (always "Open Settings," never an in-app "Try Again" for a merely-denied, not-yet-permanent case).
  evidence: Matches the frozen spec's I/O matrix exactly as written (one row, one behavior, regardless of denial type) — not a defect against this story's contract, but a defensible future UX refinement to offer a lighter-weight retry when the OS could still show its own dialog again.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: Potential interaction between `permission_handler`'s explicit permission request and `flutter_blue_plus`'s own internal platform-level Bluetooth prompts during `scanAndConnect()` is unverified either way.
  evidence: `FlutterBlueSensorDriver` (unmodified by this story) may itself trigger platform Bluetooth behavior when `startScan` is called; whether this collides or double-prompts on any OS version wasn't investigated. Worth a dedicated check before relying on this in production.

- source_spec: `spec-2-5-bluetooth-background-access-priming-permission-recovery.md`
  summary: In-foreground permission revocation via OS quick-settings (without the app losing focus/backgrounding) is not caught — the live recheck only fires on `initState` and `AppLifecycleState.resumed`.
  evidence: Possible on some Android versions/OEM skins where toggling a quick-settings tile doesn't trigger a lifecycle transition. Narrow timing window, not addressed by this story's matrix.
