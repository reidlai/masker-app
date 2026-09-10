---
title: Product Brief — D-BAND Platform
status: final
version: 2.0.0
created: 2026-08-31
updated: 2026-09-10
---

# ⚡ Product Brief: D-BAND Platform

## 1. Executive Summary & Vision

**D-BAND Platform** is an extensible, high-performance hardware integration and bio-telemetry suite engineered for **d-band thermal and ink sensor technology**. Built to bridge cutting-edge physical sensor telemetry with real-time digital health monitoring, D-BAND Platform delivers continuous, ultra-low-power signal acquisition, baseline calibration, edge interpretation, and multi-tier emergency response.

While engineered from the ground up as a general platform to support diverse thermal, vital, and ink-telemetry use cases, D-BAND Platform launches with its premier flagship application: **At-Home Nocturnal Sleep Apnea Detection** (via the cross-platform client `masker-app`).

Instead of subjecting patients to expensive, uncomfortable clinical sleep lab stays, D-BAND Platform enables non-invasive, continuous overnight respiratory airflow tracking directly from home. When critical breathing pauses are detected, the platform activates a fail-safe **Two-Tier Emergency Response System** — combining localized audio/haptic patient wake-up alerts with automated cloud caregiver escalation.

---

## 2. Background & Problem Statement

### Strategic Background
Traditional clinical diagnostics (such as hospital-based polysomnography) are expensive, intimidating, and rely on restrictive wired sensors. Concurrently, existing consumer sleep wearables are purely passive — logging data after the fact without intervening during dangerous nocturnal hypoxia episodes. 

Furthermore, proprietary single-purpose sensor apps lack the modular architecture required to scale across different bio-telemetry domains (e.g., continuous thermal monitoring, respiratory dynamics, vital sign ink sensors).

### Core Problems Solved
1. **High Barriers of Clinical Sleep Labs:** Replaces costly hospital stays with a comfortable, non-invasive at-home wearable powered by d-band thermal/ink telemetry.
2. **Passive Wearables vs. Active Intervention:** Elevates monitoring from passive logging to active, life-saving intervention by waking patients during prolonged apnea episodes and alerting emergency contacts.
3. **Sensor Baseline Drift & Noise Alarms:** Solves phantom Bluetooth drift and ambient noise interference through a mandatory **Two-Stage Pre-Sleep Calibration Routine**.
4. **Platform Monolith Bottlenecks:** Replaces single-use app structures with a modular Flutter/Dart architecture (`flutter_bloc`, RxDart 10Hz-throttled BLE driver) capable of supporting future OEM integrations and clinical partners.
5. **Mobile Battery & Foreground Constraints:** Guarantees **< 8.0% phone battery consumption over an 8-hour sleep session** through zero-FPS rendering isolate optimizations and persistent foreground services.

---

## 3. Target Audience & Ecosystem Personas

```
                     ┌──────────────────────────────────────────┐
                     │          D-BAND PLATFORM ECOSYSTEM       │
                     └────────────────────┬─────────────────────┘
                                          │
            ┌─────────────────────────────┼─────────────────────────────┐
            ▼                             ▼                             ▼
┌───────────────────────┐     ┌───────────────────────┐     ┌───────────────────────┐
│   DIRECT CONSUMERS    │     │ CLINICAL PARTNERS     │     │ HARDWARE OEMS         │
│ (Phase 1 Target)      │     │ (Phase 2 Roadmap)     │     │ (Phase 3 Roadmap)     │
│ • OSA Patients        │     │ • Sleep Specialists   │     │ • Sensor Manufacturers│
│ • At-Home Health      │     │ • Remote Caregivers   │     │ • Telehealth Tech     │
│ • Families & Support  │     │ • Clinical Researchers│     │ • Custom Wearables    │
└───────────────────────┘     └───────────────────────┘     └───────────────────────┘
```

| Persona | Ecosystem Role | Core Needs & Use Cases |
| :--- | :--- | :--- |
| **High-Risk Sleep Apnea Patient** | Primary Direct Consumer (Phase 1) | Immediate wake-up alerts during prolonged breathing stops, 30-second "I'm Safe" single-tap dismissal, and non-intrusive night mode UX. |
| **At-Home Health Seeker / Snorer** | Direct Consumer (Phase 1) | Seamless Bluetooth pairing, simple 2-stage pre-sleep calibration, morning AHI trend metrics, and digestible sleep health insights. |
| **Caregivers & Relatives** | Patient Support System | Real-time automated cloud emergency alerts when patient alarms go unacknowledged after 30 seconds. |
| **Clinical Partners & Sleep Physicians** | Professional Care Providers (Phase 2) | Standardized export of respiratory waveforms, historical trend analytics, and verified sensor signal integrity. |
| **Hardware OEMs & Telehealth Integrators** | Hardware / Tech Partners (Phase 3) | Standardized BLE driver interfaces, plug-and-play signal interpretation pipelines, and multi-sensor ink telemetry support. |

---

## 4. Key Value Proposition

* **Extensible Bio-Telemetry Core:** Generic platform architecture supporting d-band thermal and ink sensor hardware across multiple health monitoring domains.
* **100% Non-Invasive At-Home Care:** Eliminates hospital sleep lab friction with lightweight wireless telemetry.
* **Active Two-Tier Emergency Response:**
  * **Tier-1 Local Wake-Up:** Immediate escalating audio (40 dB → 75+ dB) and haptic pulses to restore breathing.
  * **Tier-2 Cloud Escalation:** Automated cloud dispatch to emergency contacts if patient does not tap "I'm Safe" within 30 seconds.
* **Two-Stage Signal Calibration ($N_{\text{idle}}$ + Active Training):** Eliminates sensor noise floor drift and establishes personalized zero-airflow boundaries.
* **Ultra-Low Battery Budget:** Consumes **< 8.0% phone battery over 8 hours** via RxDart 10Hz sampling throttled to 5 FPS display updates.
* **Passkey / WebAuthn Security:** Passwordless authentication paired with AES-128 link encryption and TLS 1.3 payload transit.

---

## 5. Platform Capabilities & Flagship Features

### A. Core Platform Hardware & BLE Integration Suite
* **BLE Sensor Receiver Service:** Automatic background scanning, encrypted pairing (`0x180D` GATT service / `0x2A37` characteristic @ 10Hz), and AES-128 link security.
* **Throttled Telemetry Bus:** Uses RxDart `sampleTime` (200ms / 5 FPS) and `distinct` filtering to protect mobile CPU, battery, and UI thread performance.
* **Mock & Simulator Drivers:** Native developer/QA simulation drivers (`BleSimulatorDriver`, `MockBLESensorDriver`) alongside physical hardware drivers (`FlutterBlueSensorDriver`).

### B. Flagship Solution: Nocturnal Sleep Apnea Detection (`masker-app`)
* **Two-Stage Setup & Calibration Wizard:**
  * *Stage 1 (Idle Noise Floor $N_{\text{idle}}$):* 5–10s ambient noise sampling before device fitting.
  * *Stage 2 (Active Breath Training):* 10–20s active respiration sampling to set net inhalation ($V_{\max}$) and exhalation ($V_{\min}$) boundaries.
* **Real-Time Sleep Monitor:** Continuous overnight respiratory graph rendering, live breathing rate indicators, and signal status alerts.
* **Tier-1 & Tier-2 Emergency Response Pipeline:** Local alarm escalation with prominent "I'm Safe" dismissal, coupled with 30-second cloud fail-safe dispatch.
* **Morning Sleep Summary & Trend Analytics:** Apnea-Hypopnea Index (AHI) estimates, event frequency timelines, interactive historical calendar, and doctor export reports.

### C. Passkey & Cloud Security Layer
* **FIDO2 / WebAuthn Passkey Authentication:** Fast, biometric, passwordless login.
* **Cloud Device Binding:** Secure API endpoint registration linking d-band hardware UUIDs to patient user accounts with offline payload queuing.

---

## 6. User Experience & Design System Invariants

* **Atomic Design Hierarchy:** Built with modular UI components (`atoms`, `molecules`, `organisms`, `pages`) ensuring platform UI consistency.
* **Circadian OLED Night Mode:** Low-luminance palette utilizing pure black (`#000000`) and deep charcoal surfaces to prevent circadian disruption and maximize battery savings.
* **Accessibility-First Emergency Ergonomics:** Prominent, high-contrast touch targets for "I'm Safe" dismissal, screen-reader friendly accessibility labels, and unambiguous status affordances.

---

## 7. Strategic Product Roadmap

```
Phase 1: Consumer Flagship (Current) ──► Phase 2: Clinical Ecosystem ──► Phase 3: OEM Platform & Multi-Sensor
• At-Home Sleep Apnea Detection        • Doctor Portal & Cloud Analytics  • Generic SDK / OEM Driver Suite
• Flutter Client (masker-app)          • Clinical Data Export (FHIR/PDF)  • Multi-Sensor Ink Telemetry
• Two-Tier Emergency Response          • Physician Dashboard              • Extended Bio-Signal Monitoring
```

1. **Phase 1 (Current Focus — Direct Consumer Flagship):** 
   - Launch `masker-app` for direct-to-consumer nocturnal sleep apnea detection.
   - Solidify 2-stage calibration, 10Hz BLE telemetry throttling, and 2-tier emergency dispatch.
2. **Phase 2 (Clinical & Provider Expansion):**
   - Introduce clinical partner data integration and doctor export workflows (FHIR / PDF).
   - Remote patient monitoring (RPM) cloud dashboard for healthcare providers.
3. **Phase 3 (OEM & Multi-Use Case Hardware Integration):**
   - Release D-BAND Platform SDK / OEM integration suite.
   - Support expanded d-band thermal and ink sensor applications (e.g., continuous vital signs, body temperature dynamics, athletic performance telemetry).

---

## 8. Success Metrics & Key Performance Indicators (KPIs)

| Metric | Target Standard | Rationale |
| :--- | :--- | :--- |
| **Emergency Alarm Trigger Reliability** | **99.99%** on true nocturnal apnea events | Zero tolerance for missed life-safety incidents during extended breathing cessation. |
| **Overnight Mobile Battery Consumption** | **< 8.0%** over 8 hours continuous monitoring | Ensures smartphone remains operational until morning without requiring bedside charging. |
| **Cloud Emergency Dispatch Latency** | **< 1.5 seconds** post 30-sec unacknowledged threshold | Critical for rapid caregiver response during unacknowledged emergencies. |
| **Pre-Sleep Calibration Completion** | **> 95%** first-attempt success rate | Guarantees friction-free nightly setup for non-technical consumers. |
| **Platform Telemetry Latency** | **≤ 200 ms** (5 FPS UI rendering) | Smooth real-time graph visualization without CPU/GPU thermal throttle. |

---

## 9. Next Steps & Artifact References

- **Architecture Spine:** [`_bmad-output/architecture/`](file:///c:/Users/reidl/GitLocal/dband-platform/_bmad-output/architecture)
- **PRD Specification:** [`_bmad-output/prd/prd.md`](file:///c:/Users/reidl/GitLocal/dband-platform/_bmad-output/prd/prd.md)
- **UX Specifications:** [`_bmad-output/ux/ux-design-masker-app-2026-09-01/`](file:///c:/Users/reidl/GitLocal/dband-platform/_bmad-output/ux/ux-design-masker-app-2026-09-01)
- **Flutter Implementation:** [`sleep-apnea-detection-app/lib/`](file:///c:/Users/reidl/GitLocal/dband-platform/sleep-apnea-detection-app/lib)
