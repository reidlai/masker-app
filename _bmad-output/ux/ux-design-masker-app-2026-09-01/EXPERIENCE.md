---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.2.0
created: 2026-09-01
updated: 2026-09-04
author: Sally (UX Designer) & Winston (System Architect)
---

# 🧠 EXPERIENCE.md — Information Architecture & User Experience Specification

## Foundation

* **Target Form-Factor:** Mobile Smartphones (iOS 15+ & Android 10+).
* **Design System & UI Framework:** Built using **Flutter (Dart)** with **`flutter_shadcn` / `shadcn_ui`** atomic UI primitives and **`fl_chart`** Skia GPU chart rendering.
* **Visual Identity Reference:** All color tokens, typography scales, spacing units, and element shapes reference [`DESIGN.md`](./DESIGN.md) (`{colors.primary}`, `{colors.surface}`, `{colors.accent_green}`, `{colors.danger_red}`, `{spacing.emergency_button}`).

---

## Information Architecture

### Screen Navigation & Flow Map

```
[ App Launch / Passkey Prompt (MOB_PASSKEY_AUTH) ]
                        |
                        v
[ User Medical Profile Setup (MOB_USER_PROFILE) ]
                        |
                        v
[ Bluetooth Access Priming (MOB_BLE_PERMISSION_PRIMER) ]  ← first run only
                        |
                        v
[ BLE Sensor Discovery & Pairing (MOB_DEVICE_PAIRING) ]
                        |
                        v
[ 2-Stage Thermal Calibration Wizard ]
   ├── Stage 1: Ambient Room Noise Sampling (MOB_CALIBRATION_STAGE1)
   └── Stage 2: Active Breath Thermal Training (MOB_CALIBRATION_STAGE2)
                        |
                        v
[ Nocturnal Sleep Monitoring - 0-FPS Night Mode (MOB_SLEEP_MONITOR) ]
         │                                       │
         │ (Normal Breathing)                    │ (Apnea Breach >10s)
         v                                       v
[ Morning Sleep Summary ]            [ Tier-1 Local Mobile Alarm (MOB_TIER1_ALARM) ]
(MOB_SLEEP_SUMMARY)                             │
   ├── Interactive Waveform (MOB_GRAPH_WAVEFORM) │ (Tap "I'm Safe" / 5s Breathing Restore)
   ├── Calendar History (MOB_HISTORY_FILTER)    v
   └── Doctor Report Export (MOB_EXPORT_DOCTOR) [ Alarm Silenced / Return to Monitor ]
```

---

### Onboarding: Bluetooth Background-Access Priming (`MOB_BLE_PERMISSION_PRIMER`)

**First run only.** Appears exactly once, after Profile Setup (`MOB_USER_PROFILE`) and before BLE Sensor Discovery (`MOB_DEVICE_PAIRING`). Once the OS Bluetooth permission is granted, this screen is skipped on every subsequent launch — the app checks permission state at boot, not a "seen it" flag alone.

* **Purpose:** Architecture invariant AD-12 starts the BLE receiver's Foreground Service at app boot on every future launch. On Android 12+, a `connectedDevice`-type foreground service requires `BLUETOOTH_CONNECT` already granted before it can start — so this screen exists to get that permission with context, before the bare native dialog fires, rather than after it fires.
* **Content:** Full-screen, same dark glassmorphic surface as onboarding. Headline + reassuring body copy (for example *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access"*), and a single primary CTA button, for example **"Allow Bluetooth Access."** No skip or decline path — the app cannot monitor without this permission, so the framing matches the Passkey auth screen's single-path pattern rather than offering an alternate route.
* **Handoff:** Tapping the CTA triggers the native OS permission flow (Android: `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`, shown as **sequential dialogs, not one** — the CTA hands off to whichever the OS presents first; iOS: the system `bluetooth-central` background-mode disclosure, surfaced automatically the first time the app touches CoreBluetooth). On full grant, the app proceeds to `MOB_DEVICE_PAIRING` and the AD-12 receiver service becomes eligible to start on this and all future boots.
* **Prior-denial check:** Before acting, the CTA checks each platform's permission-status API. If a prior denial means the OS itself won't reissue its dialog (iOS CoreBluetooth's one-shot behavior after a first denial; Android's "Don't ask again"), the CTA routes straight to the "Open Settings" deep-link instead of re-tapping a dialog that cannot fire — a silent no-op here would be a dead end for an anxious patient.
* `[NOTE FOR UX/ARCH]` Android manifest must declare the `neverForLocation` flag on `BLUETOOTH_SCAN` so the OS dialog doesn't fold in unrelated location-permission language that would contradict this screen's Bluetooth-only framing. Cross-check with architecture at build.
* **Denial / partial-grant recovery:** See State Patterns #11 `State_BlePermissionDenied` and #12 `State_BlePermissionPartial` for the full behavior — in short, `MOB_DEVICE_PAIRING` blocks with an "Open Settings" recovery CTA naming the missing permission.

---

### Primary Navigation — Persistent Bottom Nav Bar (Post-Onboarding)

Once onboarding completes, the app shell presents a persistent 4-tab bottom navigation bar (`PrimaryNavBarOrganism`). Tabs, left to right:

| # | Tab | Icon | Destination |
| :- | :- | :- | :- |
| 1 | Home | house (outlined) | `MOB_HOME` — `[ASSUMPTION]` not specified in this spine yet; listed only as the existing tab-1 target. |
| 2 | Monitor | moon (outlined) | `MOB_SLEEP_MONITOR` |
| 3 | Summary | bar-chart (outlined) | `MOB_SLEEP_SUMMARY` |
| 4 | **Settings** | **gear / `settings` (outlined)** | **`MOB_SETTINGS`** — replaces the former "Profile" tab (was: person icon → `MOB_USER_PROFILE`). |

`MOB_USER_PROFILE` loses its direct tab: post-onboarding it is reachable **only** through the Settings list, with no other entry points.

### Settings Screen (`MOB_SETTINGS`)

Full-screen destination pushed from tab 4, with a standard app bar: back affordance (‹) and title "Settings". Content is a single vertical list of menu rows (`SettingsMenuRow`) grouped on a glassmorphic surface card.

```
[ Settings  (app bar: ‹ back · title "Settings") ]
        |
        ├── Profile ───────────────────────────►  MOB_USER_PROFILE   (always present; navigable)
        |
        └── Advanced  ── shown only if (debuggingMode OR developerMode) ──┐
                 ├── Debugging  ── shown if debuggingMode ── (inert, no action)
                 └── Developer  ── shown if developerMode ── (inert, no action)
```

* **Profile row** — always visible. Leading person icon, label "Profile", trailing chevron. Tap → navigates to `MOB_USER_PROFILE`. Back from there returns to `MOB_SETTINGS`; back again returns to the tab the user came from.
* **Advanced section** — a `SettingsSectionHeader` labeled "Advanced" followed by 1–2 rows. It renders **only when** `debuggingMode` **or** `developerMode` is enabled. When **both are disabled**, the Settings screen shows **only the Profile row** — no "Advanced" header, no empty section.
* **Debugging / Developer rows** — each visible only when its own flag is enabled; both inert for now (no destination, tap is a no-op). `[ASSUMPTION]` final behavior TBD at build or architecture.
* `debuggingMode` and `developerMode` are **two independent booleans**. `[ASSUMPTION]` — `debuggingMode` follows Flutter `kDebugMode`; `developerMode` follows a `--dart-define=DEV_MODE=true` build flag. Confirm the mechanism during architecture or build.

> `[NOTE FOR UX]` — `MOB_USER_PROFILE` is specified as an onboarding "Setup" step (Save & Continue advances the wizard); reached from Settings it is an **edit-existing-profile** context (Save persists; back returns). Two open items tracked:
> - The Profile screen likely needs a first-run vs. edit mode distinction.
> - It depends on the planned **Units** preference: the Weight/Height fields and BMI output follow the selected measurement system (default metric).

#### Planned rows (future iterations — not built in this one)

This iteration ships only the **Profile** row (plus the conditional Advanced section). The row order and grouping below are the intended target so the list stays coherent as it grows:

| Group | Rows | Notes |
| :- | :- | :- |
| Account & Profile | Profile · Account · Caregiver contacts | Caregiver contacts currently captured inline on `MOB_USER_PROFILE`; may migrate to its own row. |
| Preferences | Notifications · Units | Units = metric ↔ imperial (kg/lb, cm/ft-in). Governs the Weight and Height **entry fields** on `MOB_USER_PROFILE` and the resulting **BMI computation** — the user enters weight and height, the app computes BMI in the selected system. Default metric. |
| Advanced *(conditional)* | Debugging · Developer | Gated on build flags; see above. |
| — | About | Standalone, near the bottom. |
| — | Sign out | Destructive treatment (red label, confirm dialog); bottom of the list. |

---

## Voice and Tone

* **Brand Persona:** Reassuring, clear, clinical yet accessible, and empowering.
* **Microcopy Rules:**
  * **Onboarding & Setup:** Encouraging and straightforward (*"Secure your account with native biometrics in seconds"*; *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access"*).
  * **Background Monitoring Notification:** Reassuring and status-oriented, same bucket as onboarding — confirms protection is active rather than reading as generic system chrome. Title *"Sleep Monitoring Ready"*, body *"D-BAND connection active — you're covered tonight."*
  * **Not-Protected Notification:** Same reassuring register, urgency dialed toward "fix this," not toward alarm. Title *"Bluetooth Permission Needed"*, body *"Sleep monitoring can't start until Bluetooth access is granted. Tap to fix."*
  * **iOS System Permission String (`NSBluetoothAlwaysUsageDescription`):** The one native-dialog string this team authors directly — same reassuring register as the primer, since it appears inside Apple's own system alert verbatim: *"This app uses Bluetooth to connect to your D-BAND sensor and monitor your breathing while you sleep."*
  * **Calibration Instructions:** Unambiguous and direct (*"Place sensor on bedside table, remain silent for 10 seconds"*).
  * **Sleep Monitoring:** Calming and quiet (*"Calibration Verified ✓ — Sleep Monitoring Active"*).
  * **Emergency Alerts:** Urgent, high-contrast, and action-oriented (*"BREATHING PAUSE DETECTED — TAP 'I'M SAFE' TO DISMISS"*).
  * **Settings & Navigation:** Plain and utilitarian — no marketing voice. Tab label "Settings"; screen title "Settings"; keep row labels short, one word where possible ("Profile", "Debugging", "Developer"); section header "Advanced". Sentence case, no trailing punctuation.

---

## Component Patterns (Behavioral Specifications)

### 1. `LiveAirflowMonitorOrganism`
* **Behavior:** Renders continuous 10Hz net volumetric airflow rates. When display is active, animates smooth cubic-spline curves at 60 FPS. When app enters Night Mode, locks display to pure black `{colors.night_mode}` (`#000000`) with zero frame rendering, reducing power consumption. Even though nothing renders visually in Night Mode, the screen's root semantics node still carries a persistent accessible label — *"Sleep monitoring active — D-BAND connected"* — so a screen-reader user who opens the app mid-session gets immediate confirmation without needing to background the app and read the notification shade.

### 2. `ThermalCalibrationWizardOrganism`
* **Behavior:** Guides user through Stage 1 ambient noise sampling ($N_{\text{idle}}$) and Stage 2 active breath training ($V_{pp}$). Enforces wear verification guardrail: if $\Delta V < 1.5 \times N_{\text{idle}}$, blocks progression and displays warning toast (*"Sensor not detected — Please attach D-BAND and retry"*).

### 3. `ApneaAlertBannerOrganism`
* **Behavior:** Triggered upon 10s breathing stop. Immediately launches full-screen overlay, overrides system volume to maximum (40 dB $\rightarrow$ 75+ dB siren), and pulses device haptic motor. Renders 30s countdown timer. If user taps *"I'M SAFE"*, silences audio immediately and sends safety packet to cloud.

### 4. `PrimaryNavBarOrganism`
* **Behavior:** Persistent bottom navigation across the 4 post-onboarding tabs. Tapping a tab switches the shell's active destination without a page-push animation; the active tab shows `{colors.accent_green}` icon + label, inactive tabs `{colors.text_secondary}`. Tab 4 ("Settings", gear icon) activates `MOB_SETTINGS`. Per-tab navigation state is preserved across switches. Hidden entirely during onboarding and during `State_MonitoringActive` (Night Mode).

### 5. `SettingsMenuRowOrganism`
* **Behavior:** Full-width tappable list row, minimum 48dp height (`{spacing.touch_target_min}`). **Navigable** rows (Profile) show a trailing right chevron and, on tap, push their destination with a light haptic. **Inert** rows (Debugging, Developer) render with no trailing chevron and a `{colors.text_secondary}` label; tap is a no-op. Conditional rows evaluate their build-flag gate at screen-build time — a flag flip takes effect on the next entry to `MOB_SETTINGS`, not live. The "Advanced" `SettingsSectionHeader` and its rows are omitted from the widget tree (not merely hidden) when both `debuggingMode` and `developerMode` are false.

### 6. `DeveloperSimulatorBarOrganism`
* **Behavior:** Conditionally rendered at the top of `MeasurementPage` when compile-time flag `DEV_MODE=true` is enabled. Emits simulated background telemetry streams into global `BleTelemetryService` singleton upon tapping scenario chips (`Idle Noise`, `Active Baseline`, `Normal 16 bpm`, `Apnea Drop >10s`, `Recovery 5s`). Enables developers to trigger AASM apnea alerts and 0-FPS Night Mode alarms anywhere in the application.

### 7. `BlePermissionPrimerOrganism`
* **Behavior:** Gated on a permission-state check performed at boot (see §Onboarding above — a revoked permission re-triggers this flow, not just a local "seen it" flag). Single primary CTA ("Allow Bluetooth Access") triggers the native OS permission request directly. On grant, navigates forward to `MOB_DEVICE_PAIRING` and unblocks the AD-12 app-boot receiver Foreground Service for this and all future launches. On denial or partial grant, `MOB_DEVICE_PAIRING` renders `State_BlePermissionDenied` / `State_BlePermissionPartial` instead of its scan UI.

### 8. `BleReceiverForegroundNotification`
* **Behavior:** OS-level chrome, not a Flutter widget — appears the moment the AD-12 receiver's Foreground Service starts (every app boot once permission is granted). Marked "ongoing" (Android): not swipe-dismissible while the service is resident, matching AD-12's "queue survives for next session" invariant. Small monochrome status-bar icon per platform convention (not the full-color launcher icon). Tapping opens the app to its current screen — `MOB_SLEEP_MONITOR` if a session is active, otherwise the last foregrounded screen. This is a **user-initiated** tap-to-open; it does not conflict with the DESIGN.md Do/Don't against notification-initiated screen wake (no heads-up alert, no sound, no auto-opening) — see that entry's cross-reference.

### 9. `BleNotProtectedNotification`
* **Behavior:** The inverse of `BleReceiverForegroundNotification`, and the state's only accessible confirmation. If the AD-12 receiver service fails to start at boot — permission missing, revoked, or only partially granted — the app posts this persistent notification rather than simply omitting the "Sleep Monitoring Ready" one. **Absence of a notification is not an accessible or noticeable cue on its own**, so the negative state gets its own positive, persistent signal, per Voice and Tone's Not-Protected Notification copy. Tapping routes to `MOB_DEVICE_PAIRING`'s blocked state (or straight to the Settings deep-link, per the prior-denial check above). Same "ongoing" / non-swipe-dismissible treatment as its counterpart.

---

## State Patterns

1. **`State_Idle`:** App launched, awaiting Passkey authentication or sensor connection.
2. **`State_CalibratingStage1`:** Sampling 10s idle room noise floor ($N_{\text{idle}}$).
3. **`State_CalibratingStage2`:** Sampling 30s active thermal breathing baseline ($V_{pp}$).
4. **`State_MonitoringActive`:** 0-FPS Night Mode `#000000`, 10Hz background stream active into circular RAM buffer.
5. **`State_ApneaBreach`:** Airflow dropped $\ge 90\%$ for $\ge 10\text{s}$. Escalating local mobile siren & haptics active.
6. **`State_PatientSafe`:** Alarm acknowledged via "I'm Safe" tap or 5s breathing recovery. Siren silenced.
7. **`State_MorningSummary`:** Session finalized, rendering AHI score, duration, and interactive Skia GPU charts.
8. **`State_SettingsDefault`:** `MOB_SETTINGS` open with `debuggingMode == false && developerMode == false`. Renders the Profile row only — no "Advanced" header, no section.
9. **`State_SettingsAdvanced`:** `MOB_SETTINGS` open with `debuggingMode || developerMode`. Renders the Profile row, an "Advanced" section header, and whichever of the Debugging / Developer rows are individually enabled.
10. **`State_BlePermissionPriming`:** `MOB_BLE_PERMISSION_PRIMER` shown, first run only, before the native OS Bluetooth permission dialog fires.
11. **`State_BlePermissionDenied`:** The OS-level Bluetooth permission was fully denied (or the platform's dialog can no longer fire after a prior denial). `MOB_DEVICE_PAIRING` renders a blocked state (no scan UI) with an "Open Settings" recovery CTA in place of the normal pairing flow.
12. **`State_BlePermissionPartial`:** Android only. One of `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` was granted and the other denied — the OS presents these as separate sequential dialogs, so a partial outcome is possible. Treated the same as `State_BlePermissionDenied` for `MOB_DEVICE_PAIRING` purposes (same blocked state and "Open Settings" CTA, since the receiver needs both), but the blocked-state copy names the specific missing permission.
13. **`State_BleNotProtected`:** The AD-12 receiver service is not running while the app would otherwise expect to monitor (permission missing, revoked, or partially granted). Surfaced via `BleNotProtectedNotification` — a positive, persistent, accessible signal, not merely the absence of `BleReceiverForegroundNotification`.

---

## Interaction Primitives

* **Pinch-to-Zoom & Pan:** Interactive 60 FPS gesture controls on `MOB_GRAPH_WAVEFORM` allowing patients to zoom into 8-hour overnight respiration timelines and inspect 256-point FFT spectral peaks.
* **Single-Tap Emergency Dismiss:** Prominent 64dp primary action button on `MOB_TIER1_ALARM` enabling single-tap alarm cancellation without requiring fine motor precision in dark rooms.
* **Auto-Silence Recovery:** Automatic alarm cancellation if natural breathing resumes continuously for 5 seconds ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$).
* **List-Row Navigation & Back Stack:** Tapping a navigable `SettingsMenuRow` pushes its destination with the platform-standard slide transition; the pushed screen carries an app-bar back affordance (‹). Back from `MOB_USER_PROFILE` (entered via Settings) returns to `MOB_SETTINGS`; a second back returns to the originating tab.
* **OS Permission Hand-off:** The app never layers its own dialog on top of the OS's — see Component Pattern #7 and §Onboarding "Handoff" for the full sequencing.

---

## Accessibility Floor

* **Visual Contrast:** All text meets or exceeds WCAG 2.1 AA contrast ratio ($\ge 4.5:1$) against dark surfaces `{colors.surface}` (`#1E293B`).
* **Touch Targets:** Minimum height $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) for standard controls; $64\text{dp}$ (`{spacing.emergency_button}`) for emergency dismiss buttons.
* **Multi-Sensory Feedback:** Emergency alerts combine high-contrast flashing red overlays (`#FF3B30`), 120dB audio sirens, and strong haptic vibration patterns for users with hearing or visual impairments.
* **Navigation Labels:** Every bottom-nav tab and every `SettingsMenuRow` exposes a text label (never icon-only) to assistive tech. Inert rows (Debugging, Developer) are announced with a dimmed, not-actionable state rather than being silently unfocusable. The "Settings" tab and screen share the accessible name "Settings".
* **Settings Touch Targets:** Each `SettingsMenuRow` is $\ge 48\text{dp}$ tall (`{spacing.touch_target_min}`) with the full row width as the hit area.
* **Permission Priming Touch Target:** The `MOB_BLE_PERMISSION_PRIMER` primary CTA meets the $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) minimum. Screen-reader traversal order alone doesn't guarantee reading order for a touch-exploring user (VoiceOver/TalkBack "explore by touch" lands wherever the finger first touches) — so when the screen appears, initial accessibility focus is set programmatically to the headline/rationale text, not left to tree order alone, ensuring the rationale is announced before the CTA regardless of where the user first touches.
* **Night Mode Accessible State:** `State_MonitoringActive` renders zero pixels by design, but its root semantics node still carries the persistent accessible label described under `LiveAirflowMonitorOrganism` — a screen-reader user is never left with literally nothing to query.
* **Notification Text:** Both `BleReceiverForegroundNotification` and `BleNotProtectedNotification` expose their full title and body as accessible text (never icon-only), consistent with the Navigation Labels bullet above. Together they ensure "am I protected right now" always has a positive, accessible answer — never inferred from the absence of a notification.

---

## Key Flows (Named Protagonist Journey)

### Protagonist: David (Age 48, At-Home High-Risk Sleep Apnea Patient)

1. **10:15 PM — Bedtime Passkey Login (`MOB_PASSKEY_AUTH`):**  
   David opens the app at bedtime. He authenticates instantly using Face ID / Touch ID via passwordless FIDO2 Passkey (`{colors.primary}` background).
2. **10:20 PM — Bluetooth Access Priming (`MOB_BLE_PERMISSION_PRIMER`, first run only):**  
   On his very first night with the app, David sees one extra screen: *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access."* He taps *"Allow Bluetooth Access"* and grants the native OS prompt that follows. On every future night, this step no longer appears.
3. **10:25 PM — D-BAND Sensor Discovery (`MOB_DEVICE_PAIRING`):**  
   David powers on his ductless D-BAND sensor. The app auto-discovers and pairs via BLE (BLE 4.0, 4.1, 4.2, 5.0+), rendering a green checkmark badge (`{colors.accent_green}`).
4. **10:30 PM — 2-Stage Thermal Calibration (`MOB_CALIBRATION_STAGE1` & `STAGE2`):**  
   David completes 10s room noise sampling and 15s normal breath training. The screen displays *"Calibration Complete — Ready for Sleep ✓"*. David taps *"Start Sleep Monitoring"*.
5. **10:31 PM — Night Mode Display Lock (`MOB_SLEEP_MONITOR`):**  
   The screen switches to 0-FPS pitch black `{colors.night_mode}` (`#000000`) with a dim pulsing green dot. In the notification shade, a quiet *"Sleep Monitoring Ready — D-BAND connection active"* notification confirms the receiver is running, without lighting up his screen.
6. **02:15 AM — Apnea Breach & Emergency Siren (`MOB_TIER1_ALARM`):**  
   David suffers a 12-second airway blockage. The app immediately triggers an escalating 75+ dB audio siren and full-screen flashing red overlay (`{colors.danger_red}`).
7. **02:15 AM — Safety Dismissal:**  
   Awakened by the alarm, David taps the large 64dp *"I'M SAFE"* button. The siren silences instantly, logging a safety event.
8. **07:00 AM — Morning Sleep Summary (`MOB_SLEEP_SUMMARY`):**  
   David taps *"End Sleep Session"*, viewing his morning AHI score (`AHI 3.2 Normal`), duration (7h 45m), and interactive waveform graph.

### Secondary Flow: David corrects his weight (`MOB_SETTINGS` → `MOB_USER_PROFILE`)

1. **08:10 AM — Opening Settings:**  
   Over coffee on the Home tab, David remembers he weighed in lighter this week. He taps the **Settings** tab (gear icon, tab 4). The Settings screen slides in — on his production build it shows a single row: **Profile**.
2. **08:10 AM — Into the Profile:**  
   He taps **Profile**. `MOB_USER_PROFILE` pushes in, pre-filled with his saved baseline.
3. **08:11 AM — The edit (climax beat):**  
   David changes Weight to `82`. The Computed BMI field updates live to **25.9** — the number ticking down is the small, satisfying confirmation that the app already knows him. He taps **Save**.
4. **08:11 AM — Back out:**  
   One back tap returns him to Settings; a second returns him to the Home tab he started from. No "Advanced" section ever appeared — his build has neither debugging nor developer mode on.
