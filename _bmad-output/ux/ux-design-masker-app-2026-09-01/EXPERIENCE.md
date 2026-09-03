---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.1.0
created: 2026-09-01
updated: 2026-09-02
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
  * **Onboarding & Setup:** Encouraging and straightforward (*"Secure your account with native biometrics in seconds"*).
  * **Calibration Instructions:** Unambiguous and direct (*"Place sensor on bedside table, remain silent for 10 seconds"*).
  * **Sleep Monitoring:** Calming and quiet (*"Calibration Verified ✓ — Sleep Monitoring Active"*).
  * **Emergency Alerts:** Urgent, high-contrast, and action-oriented (*"BREATHING PAUSE DETECTED — TAP 'I'M SAFE' TO DISMISS"*).
  * **Settings & Navigation:** Plain and utilitarian — no marketing voice. Tab label "Settings"; screen title "Settings"; keep row labels short, one word where possible ("Profile", "Debugging", "Developer"); section header "Advanced". Sentence case, no trailing punctuation.

---

## Component Patterns (Behavioral Specifications)

### 1. `LiveAirflowMonitorOrganism`
* **Behavior:** Renders continuous 10Hz net volumetric airflow rates. When display is active, animates smooth cubic-spline curves at 60 FPS. When app enters Night Mode, locks display to pure black `{colors.night_mode}` (`#000000`) with zero frame rendering, reducing power consumption.

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

---

## Interaction Primitives

* **Pinch-to-Zoom & Pan:** Interactive 60 FPS gesture controls on `MOB_GRAPH_WAVEFORM` allowing patients to zoom into 8-hour overnight respiration timelines and inspect 256-point FFT spectral peaks.
* **Single-Tap Emergency Dismiss:** Prominent 64dp primary action button on `MOB_TIER1_ALARM` enabling single-tap alarm cancellation without requiring fine motor precision in dark rooms.
* **Auto-Silence Recovery:** Automatic alarm cancellation if natural breathing resumes continuously for 5 seconds ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$).
* **List-Row Navigation & Back Stack:** Tapping a navigable `SettingsMenuRow` pushes its destination with the platform-standard slide transition; the pushed screen carries an app-bar back affordance (‹). Back from `MOB_USER_PROFILE` (entered via Settings) returns to `MOB_SETTINGS`; a second back returns to the originating tab.

---

## Accessibility Floor

* **Visual Contrast:** All text meets or exceeds WCAG 2.1 AA contrast ratio ($\ge 4.5:1$) against dark surfaces `{colors.surface}` (`#1E293B`).
* **Touch Targets:** Minimum height $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) for standard controls; $64\text{dp}$ (`{spacing.emergency_button}`) for emergency dismiss buttons.
* **Multi-Sensory Feedback:** Emergency alerts combine high-contrast flashing red overlays (`#FF3B30`), 120dB audio sirens, and strong haptic vibration patterns for users with hearing or visual impairments.
* **Navigation Labels:** Every bottom-nav tab and every `SettingsMenuRow` exposes a text label (never icon-only) to assistive tech. Inert rows (Debugging, Developer) are announced with a dimmed, not-actionable state rather than being silently unfocusable. The "Settings" tab and screen share the accessible name "Settings".
* **Settings Touch Targets:** Each `SettingsMenuRow` is $\ge 48\text{dp}$ tall (`{spacing.touch_target_min}`) with the full row width as the hit area.

---

## Key Flows (Named Protagonist Journey)

### Protagonist: David (Age 48, At-Home High-Risk Sleep Apnea Patient)

1. **10:15 PM — Bedtime Passkey Login (`MOB_PASSKEY_AUTH`):**  
   David opens the app at bedtime. He authenticates instantly using Face ID / Touch ID via passwordless FIDO2 Passkey (`{colors.primary}` background).
2. **10:25 PM — D-BAND Sensor Discovery (`MOB_DEVICE_PAIRING`):**  
   David powers on his ductless D-BAND sensor. The app auto-discovers and pairs via BLE (BLE 4.0, 4.1, 4.2, 5.0+), rendering a green checkmark badge (`{colors.accent_green}`).
3. **10:30 PM — 2-Stage Thermal Calibration (`MOB_CALIBRATION_STAGE1` & `STAGE2`):**  
   David completes 10s room noise sampling and 15s normal breath training. The screen displays *"Calibration Complete — Ready for Sleep ✓"*. David taps *"Start Sleep Monitoring"*.
4. **10:31 PM — Night Mode Display Lock (`MOB_SLEEP_MONITOR`):**  
   The screen switches to 0-FPS pitch black `{colors.night_mode}` (`#000000`) with a dim pulsing green dot.
5. **02:15 AM — Apnea Breach & Emergency Siren (`MOB_TIER1_ALARM`):**  
   David suffers a 12-second airway blockage. The app immediately triggers an escalating 75+ dB audio siren and full-screen flashing red overlay (`{colors.danger_red}`).
6. **02:15 AM — Safety Dismissal:**  
   Awakened by the alarm, David taps the large 64dp *"I'M SAFE"* button. The siren silences instantly, logging a safety event.
7. **07:00 AM — Morning Sleep Summary (`MOB_SLEEP_SUMMARY`):**  
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
