---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.0.0
created: 2026-09-01
updated: 2026-09-01
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

## Voice and Tone

* **Brand Persona:** Reassuring, clear, clinical yet accessible, and empowering.
* **Microcopy Rules:**
  * **Onboarding & Setup:** Encouraging and straightforward (*"Secure your account with native biometrics in seconds"*).
  * **Calibration Instructions:** Unambiguous and direct (*"Place sensor on bedside table, remain silent for 10 seconds"*).
  * **Sleep Monitoring:** Calming and quiet (*"Calibration Verified ✓ — Sleep Monitoring Active"*).
  * **Emergency Alerts:** Urgent, high-contrast, and action-oriented (*"BREATHING PAUSE DETECTED — TAP 'I'M SAFE' TO DISMISS"*).

---

## Component Patterns (Behavioral Specifications)

### 1. `LiveAirflowMonitorOrganism`
* **Behavior:** Renders continuous 10Hz net volumetric airflow rates. When display is active, animates smooth cubic-spline curves at 60 FPS. When app enters Night Mode, locks display to pure black `{colors.night_mode}` (`#000000`) with zero frame rendering, reducing power consumption.

### 2. `ThermalCalibrationWizardOrganism`
* **Behavior:** Guides user through Stage 1 ambient noise sampling ($N_{\text{idle}}$) and Stage 2 active breath training ($V_{pp}$). Enforces wear verification guardrail: if $\Delta V < 1.5 \times N_{\text{idle}}$, blocks progression and displays warning toast (*"Sensor not detected — Please attach D-BAND and retry"*).

### 3. `ApneaAlertBannerOrganism`
* **Behavior:** Triggered upon 10s breathing stop. Immediately launches full-screen overlay, overrides system volume to maximum (40 dB $\rightarrow$ 75+ dB siren), and pulses device haptic motor. Renders 30s countdown timer. If user taps *"I'M SAFE"*, silences audio immediately and sends safety packet to cloud.

---

## State Patterns

1. **`State_Idle`:** App launched, awaiting Passkey authentication or sensor connection.
2. **`State_CalibratingStage1`:** Sampling 10s idle room noise floor ($N_{\text{idle}}$).
3. **`State_CalibratingStage2`:** Sampling 30s active thermal breathing baseline ($V_{pp}$).
4. **`State_MonitoringActive`:** 0-FPS Night Mode `#000000`, 10Hz background stream active into circular RAM buffer.
5. **`State_ApneaBreach`:** Airflow dropped $\ge 90\%$ for $\ge 10\text{s}$. Escalating local mobile siren & haptics active.
6. **`State_PatientSafe`:** Alarm acknowledged via "I'm Safe" tap or 5s breathing recovery. Siren silenced.
7. **`State_MorningSummary`:** Session finalized, rendering AHI score, duration, and interactive Skia GPU charts.

---

## Interaction Primitives

* **Pinch-to-Zoom & Pan:** Interactive 60 FPS gesture controls on `MOB_GRAPH_WAVEFORM` allowing patients to zoom into 8-hour overnight respiration timelines and inspect 256-point FFT spectral peaks.
* **Single-Tap Emergency Dismiss:** Prominent 64dp primary action button on `MOB_TIER1_ALARM` enabling single-tap alarm cancellation without requiring fine motor precision in dark rooms.
* **Auto-Silence Recovery:** Automatic alarm cancellation if natural breathing resumes continuously for 5 seconds ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$).

---

## Accessibility Floor

* **Visual Contrast:** All text meets or exceeds WCAG 2.1 AA contrast ratio ($\ge 4.5:1$) against dark surfaces `{colors.surface}` (`#1E293B`).
* **Touch Targets:** Minimum height $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) for standard controls; $64\text{dp}$ (`{spacing.emergency_button}`) for emergency dismiss buttons.
* **Multi-Sensory Feedback:** Emergency alerts combine high-contrast flashing red overlays (`#FF3B30`), 120dB audio sirens, and strong haptic vibration patterns for users with hearing or visual impairments.

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
