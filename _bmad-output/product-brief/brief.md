---
title: Product Brief — Sleep Apnea Detection App
status: final
version: 1.4.0
created: 2026-08-31
updated: 2026-08-31
---

# 🫁 Product Brief: Sleep Apnea Detection App

## 1. Product Summary

**Sleep Apnea Detection App** is a consumer health mobile application designed to interface wirelessly via **Bluetooth Low Energy (BLE)** with a **small breathing device** used comfortably at home during sleep. Instead of requiring costly, uncomfortable clinical sleep lab (hospital) stays, users simply wear the compact device to bed in their own homes. 

All overnight breathing detection, respiratory airflow monitoring, and sleep apnea event processing are transmitted seamlessly over a low-energy Bluetooth connection directly to the mobile app. 

When critical or prolonged breathing cessation is detected during sleep, the app immediately initiates a **Two-Tier Emergency Response**:
1. **Tier-1 Primary Mobile App Alarm:** Escalating smartphone audio alarms & haptics (and future device micro-electrical stimulation) to wake the patient and restore breathing.
2. **Tier-2 Cloud Emergency Dispatch & Safety Acknowledgement:** Real-time signal transmission to the cloud backend. If the patient acknowledges the alert on screen ("I'm Safe"), the cloud logs a safety event; if unacknowledged after 30 seconds, emergency alerts are dispatched to designated caregivers.

Featuring a mandatory **Two-Stage Pre-Sleep Calibration Routine** (Idle Noise Calibration + Active Breath Training), the system filters out ambient sensor noise and establishes personalized zero-airflow thresholds for pinpoint accuracy.

---

## 2. Background & Problem Statement

### Background
Sleep apnea affects millions of adults worldwide. Severe obstructive sleep apnea (OSA) causes prolonged nocturnal hypoxia (breathing cessation lasting 10 to 60+ seconds), leading to severe cardiovascular stress and daytime exhaustion. Traditional monitoring tools only record data passively for review the next day. A proactive system must both gently wake the patient to interrupt dangerous apnea episodes and alert remote caregivers via the cloud during critical safety events.

### Problem Statement
1. **High Barriers of Hospital Sleep Labs:** Clinical sleep studies in hospitals are expensive, intimidating, and require sleeping in an unfamiliar medical environment with wired sensors.
2. **Passive vs. Active Intervention:** Existing consumer sleep trackers record breathing stops passively, doing nothing *during* the event to wake the patient or safeguard their health.
3. **Sensor Noise False Alarms:** Uncalibrated consumer devices trigger false alarms due to phantom Bluetooth drift and ambient sensor noise floors.
4. **Mobile Battery Strain:** Continuous overnight background streaming can drain phone battery rapidly if not built with an ultra-low-power rendering & worker architecture.

---

## 3. Target Audience & Core Personas

| Persona | Description | Core Needs |
| :--- | :--- | :--- |
| **High-Risk Sleep Apnea Patient** | Individuals with known severe obstructive sleep apnea or severe nocturnal breathing stops. | Immediate wake-up alerts during prolonged breathing stops, "I'm Safe" single-tap dismissal, and automated cloud emergency alerts to family/caregivers. |
| **The Snorer / At-Home Sleep Seeker** | Individuals experiencing chronic snoring or morning fatigue who want an alternative to hospital visits. | Convenient at-home sleep monitoring, wireless Bluetooth connectivity, two-stage calibration, and morning sleep apnea risk indicators. |
| **Caregivers & Family Members** | Relatives or caregivers monitoring vulnerable or elderly patients remotely. | Real-time cloud emergency alerts and overnight health summary access. |

---

## 4. Key Value Proposition

* **100% At-Home Convenience:** Replaces intimidating hospital sleep studies with a comfortable, non-invasive at-home sleep breathing assessment.
* **Proactive Patient Wake-Up Intervention:** Actively wakes the patient using gentle escalating audio tones (40 dB → 75+ dB) and haptic pulses when prolonged breathing stops occur.
* **"I'm Safe" Patient Acknowledgement:** Gives patients a 30-second window to tap "I'm Safe" upon waking, preventing unnecessary caregiver alarm.
* **Cloud Emergency Signal Pipeline:** Instantly transmits critical telemetry to the cloud environment to dispatch notifications to emergency contacts if unacknowledged.
* **Two-Stage Noise Calibration ($N_{\text{idle}}$ + Active Training):** Samples ambient sensor noise floors and active breathing peaks to eliminate false positives.
* **Ultra-Low Battery Consumption:** Optimized background isolate & 0-FPS display rendering architecture consumes **< 8.0% phone battery over 8 hours**.

---

## 5. Expected Core Features

### A. Authentication, Profile & Emergency Contacts
* **Secure Account Access:** Simple login, registration, and password recovery.
* **User Profile & Safety Setup:** Collection of biometric profiles and primary emergency contacts (family member, caregiver, or alert preference).

### B. Bedtime Bluetooth Pairing & Two-Stage Setup Wizard
* **Bluetooth Device Discovery:** Automatic background scanning and one-tap pairing with the nearby small breathing device.
* **Stage 1 (Idle Noise Calibration):** 5-to-10 second sampling of ambient sensor noise floor ($N_{\text{idle}}$) before wearing the device.
* **Stage 2 (Active Breath Training):** 10-to-20 second active breathing phase to establish net inhalation ($V_{\max}$) and exhalation ($V_{\min}$) threshold boundaries.

### C. Real-Time Sleep Monitoring & Emergency Intervention
* **Overnight Bluetooth Streaming:** Continuous wireless reception of respiratory airflow telemetry while preserving phone battery.
* **Primary App Wake-Up Alarm:** Immediate local haptic vibrations or escalating audio alarms when an extended breathing pause exceeds 10 seconds.
* **Patient "I'm Safe" Dismissal:** Prominent single-tap button to acknowledge safety and send a "Patient Safe" log to the cloud.
* **Cloud Emergency Dispatch:** Automatic high-priority payload dispatch to cloud backend after 30 seconds if the alarm remains unacknowledged.

### D. Morning Sleep Summary & Analytics
* **Sleep Apnea & Event Summary:** Clear morning report showing estimated breathing interruptions per hour (AHI indicator) and triggered wake-up interventions.
* **Overnight Respiration Graph:** In-depth historical timeline of breath frequency, airflow consistency, and intervention timestamps during sleep.
* **Calendar & Trend Picker:** Date-filtered history to track sleep breathing quality and emergency frequency across weeks and months.

### E. Sleep Health Education & Resources
* **Sleep Apnea Articles:** Educational content covering risk factors, lifestyle tips, and sleep hygiene.
* **Instructional Videos:** Video guides demonstrating proper breathing device placement, Bluetooth pairing, two-stage calibration, emergency alert testing, battery charging, and maintenance.

---

## 6. User Experience (UX) Principles

* **Safety-First Ergonomics:** High-priority local wake-up alarms with large "I'm Safe" touch targets and fail-safe cloud signal dispatch.
* **Calming Dark Night Mode:** Uses low-luminance deep charcoal tones with OLED pure black (`#000000`) and dimming to avoid circadian rhythm disruption and save battery.
* **Glanceable Morning Summaries:** Displays top-level sleep score and apnea indicators front-and-center upon waking up.

---

## 7. Success Metrics & Key Performance Indicators (KPIs)

1. **Emergency Intervention Success:** 99.9% reliable trigger on true apnea stops.
2. **Overnight Battery Efficiency:** **< 8.0% phone battery drain over 8 hours**.
3. **Cloud Signal Latency:** Sub-1.5 second latency for cloud emergency alert dispatch to caregiver endpoints.
4. **Pre-Sleep Calibration Completion:** >95% first-attempt success rate on two-stage calibration.
5. **False Positive Apnea Rate:** < 2% per session due to $N_{\text{idle}}$ noise floor subtraction.

---

## 8. Future Expansion & Hardware Enhancement Roadmap

* **⚡ HW-ENHANCEMENT-1 (Device Micro-Electrical Stimulation - EMS/TENS):** Future hardware revisions of the small breathing device may integrate mild micro-electrical stimulation (safe EMS micro-pulses) delivered directly via the device hardware to gently stimulate airway muscles and wake the patient.
* **Doctor-Ready PDF Export:** One-tap export of 8-hour overnight breathing graphs formatted for sleep medical specialists.
* **Smart Home IoT Action Triggers:** Automated cloud integration to turn on bedroom lights or raise bed incline during severe apnea alerts.
* **Positional Sleep Tracking:** Correlating nocturnal apnea episodes with body sleeping posture (back vs. side).
