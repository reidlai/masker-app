---
title: Product Requirements Document — Sleep Apnea Detection App
status: draft
version: 2.2.0
created: 2026-08-31
updated: 2026-09-04
author: Mary (Business Analyst) & Winston (System Architect)
---

# 🫁 Product Requirements Document (PRD)
## Sleep Apnea Detection App (D-BAND Integrated Platform)

---

## 1. Executive Summary & Goals

### 1.1 Product Overview
The **Sleep Apnea Detection App** is a specialized consumer health mobile application and cloud platform designed to interface wirelessly via **Bluetooth Low Energy (BLE 4.0, 4.1, 4.2, and 5.0+)** with the **D-BAND (Ductless-Breath ANalysis Device)**, a patented conducting polymer thermal sensor hardware device manufactured by OM Sciences (機質科學). 

Unlike traditional Continuous Positive Airway Pressure (CPAP) machines or turbine spirometers that require uncomfortable masks, headgear, mouthpieces, and noisy machinery, D-BAND is a **ductless, lightweight, portable, battery-operated, and quiet** sensor array worn comfortably at home. The application transforms raw 10Hz inhale/exhale thermal deviation streams ($\Delta T$) into accurate lung volumetric data ($V_{\text{volumetric}}$ in L/s) and overnight apnea insights, eliminating the need for expensive hospital polysomnography visits ($200–$300/visit).

Access is secured via passwordless **Passkey (FIDO2/WebAuthn)** biometrics and strictly compliant with **HIPAA Security & Privacy Rules** for Protected Health Information (PHI). When severe or prolonged breathing stops are detected during sleep, the application initiates an active **Two-Tier Emergency Response**:
1. **Tier-1 Primary App & Device Wake-Up Alert:** Escalating smartphone audio alarms & haptics (and future device micro-electrical stimulation) to wake the patient and restore breathing.
2. **Tier-2 Cloud Emergency Dispatch & Safety Acknowledgement:** Real-time signal transmission to the cloud backend. If the patient acknowledges the alert via the app ("I'm Safe"), the cloud logs a safety event; if unacknowledged after 30 seconds, emergency notifications are dispatched to caregivers and 911 EMS CAD gateways.

### 1.2 Strategic Business Goals
* **At-Home Ductless Accessibility:** Provide a comfortable, maskless ($388 USD target price) alternative to clinical CPAP machines and hospital sleep studies.
* **Multi-Domain Respiratory Platform:** Support nocturnal sleep monitoring, athletic respiration training, individual respiratory health checks, and meditation.
* **Frictionless HIPAA Security:** Passwordless **Passkey** onboarding and hardware-encrypted local/cloud PHI storage.
* **Proactive Patient Safety:** Move from passive morning data logging to active overnight intervention during critical apnea episodes.
* **Big Data & Clinical Integration:** Aggregated cloud big data analytics for AI model training (PolyU/CUHK clinical research) and extensible EHR/EMR physician chart sharing.

### 1.3 MVP1 Project Scope Statement (UJ-1 Focus)

> [!IMPORTANT]
> **MVP1 Release Scope Boundary:** MVP1 focuses **exclusively on User Journey 1 (UJ-1)**—delivering a production-grade, HIPAA-compliant at-home nocturnal monitoring system for David (Persona A). Advanced multi-mode applications and secondary external integrations are explicitly deferred to MVP2+.

#### 🎯 Primary MVP1 Objective
To deliver a production-ready mobile application (iOS & Android) and supporting backend cloud infrastructure that enables high-risk sleep apnea patients to perform passwordless biometric onboarding, wirelessly pair their **D-BAND thermal sensor**, complete 2-stage thermal calibration, undergo 8+ hours of continuous nocturnal sleep apnea monitoring, receive instant Tier-1 local sirens (<200ms) with a 30s "I'm Safe" safety tap, trigger Tier-2 cloud caregiver SMS/voice emergency escalation upon unacknowledged alerts (>30s), and view morning AHI sleep summaries.

#### ✅ In-Scope Capabilities for MVP1 (UJ-1 Only):
1. **Biometric Onboarding & Passkey Auth:** FIDO2 passwordless authentication (Face ID / Touch ID / BiometricPrompt) and HIPAA health profile setup (Age, Weight, Height, computed BMI, Emergency Caregiver Phone).
2. **D-BAND Hardware Pairing & Cloud Binding:** Wireless BLE (BLE 4.0, 4.1, 4.2, and 5.0+) auto-discovery, pairing (`0x180D` service / `0x2A37` characteristic @ 10Hz), AES-128 link encryption, and Cloud Device Binding API (`POST /api/v1/devices/bind`) with offline queuing.
3. **Two-Stage Thermal Calibration Wizard:** Stage 1 ambient room thermal sampling ($N_{\text{idle}}$) + Stage 2 active thermal breath training ($\Delta T$) to calculate dynamic volumetric baselines and zero-airflow apnea thresholds ($0.10 \times V_{pp}$). Includes wear verification guardrails ($\Delta V < 1.5 \times N_{\text{idle}}$).
4. **Nocturnal Sleep Apnea Monitoring (Mode A):** Continuous 10Hz background telemetry logging, low-power 0-FPS Night Mode (`#000000` black screen, <8% battery drain over 8h), and real-time AASM Obstructive Apnea evaluation ($\ge 90\%$ drop for $\ge 10\text{s}$).
5. **Two-Tier Emergency Response System:**
   - **Tier-1 Local Mobile Siren (<200ms):** Escalating 40 dB $\rightarrow$ 75+ dB audio alarm and full-screen haptic vibration pulses.
   - **Tier-1 Patient "I'm Safe" Tap:** Large touch target with 30s countdown. Silences alarm, notifies cloud, or auto-silences upon 5s continuous breathing restoration.
   - **Tier-2 Caregiver Telephony Escalation:** Automated cloud dispatch of priority SMS and voice calls (Twilio telephony) to designated caregiver if alarm is unacknowledged after 30s.
6. **Morning Analytics & Session History:** Morning sleep summary dashboard (Total duration, AHI score, intervention count, quality score), interactive respiration wave graph, AES-256 local SQLCipher database encryption, and 5-minute inactivity session timeout under HIPAA 45 CFR §164.312.

#### ❌ Out-of-Scope for MVP1 (Deferred to Future Releases / MVP2+):
- **Secondary Application Modes (Modes B, C, D):** Athletic Respiration Training (Mode B), Individual Respiratory Health Check (Mode C), and Meditation Rhythms (Mode D) are deferred to MVP2.
- **Direct 911 Municipal CAD Gateway Dispatch:** Automated integration with 911 emergency services (`Task_DispatchEMS`) is deferred to MVP2 (MVP1 relies on Tier-2 Caregiver SMS/Voice calls).
- **Direct HL7 FHIR EMR/EHR Hospital Sync:** Direct API synchronization with hospital electronic medical record systems is deferred to MVP2 (MVP1 provides in-app graphs and PDF export).
- **Cloud Neural Network Deep Learning AI Engine:** Complex cloud-side neural re-classification of raw bio-signals is deferred to MVP2 (MVP1 executes real-time AASM signal processing on edge Dart Isolates).
- **Hardware EMS/TENS Micro-Electrical Stimulation:** Micro-electrical pulses on D-BAND hardware are deferred to future hardware revisions (`HW-ENHANCEMENT-1`).

---

## 2. Target Personas & Primary User Journey

### 2.1 Target Personas & Customer Segments
* **Persona A: David (At-Home High-Risk Sleep Patient - Age 48):** Suffers from severe loud snoring, morning fatigue, and unmonitored nocturnal breathing pauses. Cannot tolerate CPAP masks or pressure.
* **Persona B: Post-COVID & Chronic Lung Disease Sufferers:** Patients recovering from COVID-19 or living with COPD, asthma, or pulmonary fibrosis requiring 24-hour continuous respiratory trend tracking.
* **Persona C: Pulmonary Exercisers & Athletes:** Users utilizing real-time respiration metrics during running, athletic workouts, or meditation.
* **Persona D: Elderly Tech Users:** Seniors requiring simple, non-invasive, low-friction respiratory monitoring at home.

### 2.2 User Journey 1 (UJ-1): Bedtime Monitoring, Calibration & Emergency Response Lifecycle

**Protagonist:** David (48, high-risk sleep apnea patient sleeping at home).

1. **10:15 PM — Passkey Onboarding & Profile Verification:**  
   David opens the Sleep Apnea Detection App on his smartphone at bedtime. Instead of typing passwords, he authenticates instantly using his phone's native biometrics (Face ID / Touch ID) via passwordless FIDO2 Passkey. The app displays his health baseline profile (Age: 48, Weight: 85kg, Height: 178cm, BMI: 26.8) and emergency contact information.

2. **10:25 PM — D-BAND Sensor Discovery & Wireless Pairing:**  
   David turns on his lightweight D-BAND ductless sensor. The mobile app automatically scans, discovers, and pairs with the D-BAND sensor via Bluetooth Low Energy (BLE 4.0, 4.1, 4.2, and 5.0+). The app securely registers the hardware binding with the cloud environment.

3. **10:30 PM — Two-Stage Thermal Calibration Wizard:**  
   - **Stage 1 (Idle Room Noise Sampling):** The app prompts David to place the sensor on his bedside table for 5 to 10 seconds. The app measures the ambient room thermal baseline ($N_{\text{idle}}$).
   - **Stage 2 (Active Breath Thermal Training):** David puts on his D-BAND sensor and breathes normally for 15 seconds. The app measures inhale/exhale thermal deviation curves ($\Delta T$) and calculates his personalized net volumetric airflow baseline and zero-airflow apnea threshold ($0.10 \times V_{pp}$).
   - **Confirmation:** The screen displays *"Calibration Complete — Ready for Sleep ✓"*. David taps *"Start Sleep Recording"*, and the app enters low-power 0-FPS Night Mode (locked black screen `#000000` with a subtle pulsing green dot).

4. **02:15 AM — Nocturnal Apnea Event & Tier-1 Local Alarm:**  
   During deep sleep, David suffers an obstructive airway blockage. The D-BAND sensor detects a 90% drop in thermal breath amplitude lasting longer than 10 seconds.
   - **Sub-200ms Intervention:** The mobile app immediately triggers an escalating Tier-1 local alarm (40 dB $\rightarrow$ 75+ dB audio tones and full-screen haptic vibration pulses) to wake David and restore natural respiration.

5. **02:15 AM — Patient Safety Acknowledgement & Cloud Escalation:**  
   - **Option A (Patient Taps "I'm Safe"):** Awakened by the alarm, David taps the large *"I'M SAFE / I'M AWAKE"* button within 30 seconds. The app immediately silences the siren and transmits a safety status signal to the cloud, logging the event without escalating to caregivers.
   - **Option B (Unacknowledged >30s):** If David remains unawakened and does not tap the screen within 30 seconds, the cloud backend automatically triggers Tier-2 Emergency Escalation—dispatching priority SMS/voice calls to his caregiver and pushing patient GPS coordinates to the 24/7 Command Center dispatcher.

6. **07:00 AM — Morning Sleep Summary & Clinical Review:**  
   Waking up in the morning, David taps *"End Sleep Session"*. The app closes the BLE stream, synchronizes nocturnal session data with the cloud, and renders his **Morning Sleep Summary Dashboard**—displaying total sleep duration, overnight AHI score, intervention count, and interactive respiration waveform graphs.

---

## 3. Functional Requirements (FR)

### 3.1 FR-1: Device Pairing, Two-Stage Thermal Calibration & Multi-Mode Framework

* **FR-1.1 (BLE Auto-Discovery):** The application shall automatically scan for, identify, and establish a low-energy Bluetooth (BLE 4.0, 4.1, 4.2, and 5.0+, AES-128 link security) connection with the D-BAND sensor array (`0x180D` service / `0x2A37` characteristic).
* **FR-1.2 (Device Binding API Framework):** Upon successful BLE pairing, the application shall execute the **Cloud Device Binding API** (`POST /api/v1/devices/bind`), transmitting an encrypted payload containing `user_profile_id`, `device_hardware_id`, `ble_mac_address`, and `binding_timestamp`.
* **FR-1.3 (Offline Device Binding Queue):** If the device is paired without active internet connectivity, the application shall queue the device binding payload locally in an encrypted buffer and retry transmission upon network restoration.
* **FR-1.4 (Stage-1 Idle Room Noise Calibration):** Prior to sensor positioning, the application shall execute a 5-to-10 second sampling phase of idle BLE data to compute ambient room thermal noise floor ($N_{\text{idle}}$).
* **FR-1.5 (Stage-2 Active Thermal Breath Training):** Following device attachment, the application shall execute a 10-to-20 second active breathing calibration phase, sampling inhale temperature ($T_{\text{inhale}}$) and exhalation peak temperature ($T_{\text{exhale}}$).
* **FR-1.6 (Thermal-to-Volumetric Airflow Transformation & Scientific Baseline):** The application shall transform instantaneous thermal deviation data $\Delta T(t) = T_{\text{exhale}}(t) - T_{\text{inhale}}(t)$ into lung volumetric airflow rates $V_{\text{volumetric}}(t) = f(\Delta T(t), N_{\text{idle}})$, calibrated against clinical adult respiratory physiology research establishing resting peak-to-peak tidal volume airflow ($V_{pp}$) centered at $5.0\text{ L/s}$ ($4.0\text{ L/s} - 6.0\text{ L/s}$ normal resting range).
* **FR-1.7 (Dynamic Apnea Threshold Binding):** The application shall dynamically set the zero-airflow (Apnea) threshold for the session based on the calibrated net volumetric breathing baseline ($0.10 \times V_{pp}$, initialized at $0.5\text{ L/s}$ based on the $5.0\text{ L/s}$ physiological baseline).
* **FR-1.8 (Wear Verification Guardrail):** The application shall block sleep recording initiation if active breathing signal $\Delta V < \text{Threshold}_{\min} = 1.5 \times N_{\text{idle}}$.
* **FR-1.9 (Multi-Mode Application Support):** The application shall support 4 distinct operating modes:
  - **Mode A (Nocturnal Sleep Apnea Monitoring):** 0-FPS night mode, 8h continuous logging, 2-tier emergency alarm.
  - **Mode B (Athletic Respiration Training):** Real-time lung capacity, ventilation volume, and respiration rate during running/exercise.
  - **Mode C (Individual Respiratory Health Check):** Vital capacity & lung function baseline assessment.
  - **Mode D (Meditation & Breath Control):** Guided breathing rhythms & coherence metrics.
* **FR-1.10 (D-BAND Hardware Sensor Lost & Unbinding Workflow):** The application and web portal shall provide a **"Report D-BAND Sensor Lost"** workflow. Upon invocation, the cloud gateway shall execute `POST /api/v1/devices/unbind`, mark the hardware serial number as `DEPRECATED/LOST`, revoke its paired BLE MAC binding, and allow immediate discovery and pairing of a replacement D-BAND sensor array without losing cloud session history.
* **FR-1.11 (App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue):** Upon application launch, the BLE background receiver service shall automatically start in the background (via Android Foreground Service / iOS `bluetooth-central` mode) and listen for incoming BLE packets (from either physical BLE hardware or `BleTelemetryService` simulator). Incoming signals MUST be pushed into a reactive `BehaviorSubject<double>` queue using RxDart `.add()` (`next`) so downstream consumers (including the Measure Page's Stage-1 5–10s idle calibration, Stage-2 10–30s active breath calibration, and 8+ hour sleep monitoring cycles) consume signals seamlessly from a single unified reactive stream.

---

### 3.2 FR-2: Real-Time Overnight Telemetry & Apnea Detection

* **FR-2.1 (Continuous Background Logging):** The application shall log continuous 10Hz respiratory airflow streams throughout an 8+ hour sleep window in a low-power background state.
* **FR-2.2 (Real-Time Apnea Evaluator):** The application shall evaluate real-time net volumetric airflow against the calibrated threshold every 100 milliseconds.
* **FR-2.3 (Apnea Event Flagging):** An obstructive apnea event shall be flagged whenever net airflow remains below threshold continuously for $\ge 10$ seconds.
* **FR-2.4 (Session Data Integrity):** Telemetry packets shall be timestamped locally and buffered in hardware-encrypted storage during temporary signal interruptions.
* **FR-2.5 (Cloud AI Respiration Waveform Analytics):** The cloud platform shall ingest compressed telemetry streams and execute AI waveform classification algorithms to refine apnea event detection and flag anomalous breathing patterns (PolyU/CUHK clinical AI model integration).

---

### 3.3 FR-3: Primary App Alarm, Patient Safety Acknowledgement & Cloud Dispatch

* **FR-3.1 (Primary Mobile App Alarm):** Upon flagging a critical apnea event (>10s breathing stop), the smartphone application shall trigger high-priority escalating audio tones (40 dB → 75+ dB) and full-screen haptic vibration pulses.
* **FR-3.2 (Patient "I'm Safe" Acknowledgement Action):** The application shall render a prominent, large touch target button (**"I'm Safe / I'm Awake"**) on the screen during an alarm event.
* **FR-3.3 (Patient Safety Signal to Cloud):** If the patient taps "I'm Safe" within 30 seconds of alarm initiation, the application shall silence the alarm and transmit a **"Patient Awake & Safe"** status signal.
* **FR-3.4 (Automatic Alarm Silence on Breathing Restoration):** If normal respiratory airflow is restored ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$) continuously for 5 seconds without manual tap, the app shall auto-silence the alarm.
* **FR-3.5 (Tier-2 Cloud Emergency Dispatch on Timeout):** If the alarm remains unacknowledged after 30 seconds, the application shall transmit a high-priority **Emergency Dispatch Payload** to alert designated caregivers and EMS 911 CAD gateways.

---

### 3.4 FR-4: Morning Analytics, History & Big Data Platform Insights

* **FR-4.1 (Morning Sleep Summary):** Displays Total Sleep Duration, Overnight AHI Score (events/hour), Intervention Count, and Quality Score (0–100).
* **FR-4.2 (Interactive Respiration Timeline):** Renders interactive overnight wave graphs with color-coded markers for flagged apnea episodes and safety acknowledgements.
* **FR-4.3 (Calendar & History Filter):** Date-filtered historical sleep sessions.
* **FR-4.4 (Educational Library):** Integrated articles and instructional videos.
* **FR-4.5 (Big Data Platform & Clinical Research Export):** The cloud platform shall provide a secure, de-identified big data export interface for clinical research studies (CUHK / Prince of Wales Hospital pilot research).

---

### 3.5 FR-5: Passkey Authentication, Health Profile & Doctor Sharing Framework

* **FR-5.1 (Passkey FIDO2/WebAuthn Authentication):** The application shall support passwordless authentication via **Passkeys**, utilizing native OS biometrics (Face ID, Touch ID, Android BiometricPrompt) and hardware secure enclave tokens.
* **FR-5.2 (Health Profile Management):** The application shall collect and manage the user's health baseline profile: Weight, Height, Age, Gender, computed BMI, and Sleep Risk Factors.
* **FR-5.3 (Extensible Doctor Sharing Framework):** Provides a dedicated **"Share Profile with Doctor"** UI module and extensible JSON data export engine formatted for future EHR/EMR physician integrations.
* **FR-5.4 (Mobile Device Lost & Remote Session Revocation):** The platform shall provide a WebAuthn-backed self-service Web Portal allowing users or designated emergency contacts to report a lost or stolen mobile phone. The cloud platform shall immediately invalidate all active JWT tokens, revoke session refresh tokens, and issue an automated cryptographic remote wipe signal.
* **FR-5.6 (Developer Options Page & BLE Signal Simulator):** When Developer Mode is enabled (via `DEV_MODE=true` compile-time flag), the application shall render a "Developer" menu item in Settings under the Advanced section. Tapping "Developer" shall navigate to the Developer Options Page, providing interactive BLE signal simulation controls to simulate 2-stage calibration lifecycles (ambient idle noise $N_{\text{idle}}$ and active breathing baseline $V_{pp}$) and nocturnal sleep cycles (normal 16 bpm respiration streams, $\ge 10\text{s}$ apnea breathing stop alerts, and 5s patient breathing recovery signals).

---

## 4. Non-Functional Requirements (NFR)

### 4.1 NFR-1: Reliability & BLE Reconnect Resilience
* **Auto-Reconnect:** Automatic BLE re-connection within 3.0 seconds.
* **Data Recovery:** 1-hour local circular RAM ring buffer for data preservation.

### 4.2 NFR-2: Performance & Alert Latency
* **Local Alert Trigger:** Primary mobile alarm triggers within **< 200 milliseconds**.
* **Cloud Signal Latency:** Safety acknowledgement and Tier-2 emergency payloads transmit within **< 1.5 seconds**.

### 4.3 NFR-3: Maximum Battery Efficiency & Ultra-Low Power Architecture
* **Maximum Overnight Battery Consumption:** Continuous 8-to-10 hour background sleep logging consumes **< 8.0% total phone battery**.
* **0-FPS Display Throttling:** 0 FPS rendering when screen is locked/darkened.
* **Isolate Worker Offloading:** FFT and signal calculations offloaded to background Dart Isolates.

### 4.4 NFR-4: Full HIPAA Security Rule & PHI Safeguards (45 CFR Part 160 & 164)

* **NFR-4.1 (Technical Access Control & Passkey Enforcement - 45 CFR § 164.312(a)):** Access to Protected Health Information (PHI) shall require unique user identification via Passkeys (FIDO2/WebAuthn). The app shall enforce automatic session timeout and re-authentication after 5 minutes of inactivity.
* **NFR-4.2 (Audit Controls & Tamper-Evident Logs - 45 CFR § 164.312(b)):** The application and cloud gateway shall record immutable audit logs (`phi_audit_logs`) capturing all PHI creation, modification, doctor exports, and caregiver emergency alert dispatches.
* **NFR-4.3 (Data Integrity & Automated Remote Wipe - 45 CFR § 164.312(c)):** The application shall support an automated remote wipe protocol. Upon receiving a cloud session revocation signal or after 10 consecutive failed biometric Passkey authentication attempts, the mobile app shall execute a sub-1-second zeroization routine—deleting all local SQLCipher database files, Hive key-value stores, and destroying cached encryption keys in the OS Secure Enclave.
* **NFR-4.4 (Encryption in Transit & Certificate Pinning - 45 CFR § 164.312(e)):** BLE telemetry packets shall be encrypted in transit via AES-128. All mobile-to-cloud communications shall enforce TLS 1.3 HTTPS/WSS with SSL Certificate Pinning to prevent man-in-the-middle (MITM) attacks.
* **NFR-4.5 (Encryption at Rest - 45 CFR § 164.312(e)):** Local mobile databases (Hive/SQLCipher) shall be encrypted using **AES-256** with keys stored inside OS Secure Enclave / Android Keystore. Cloud databases shall enforce AES-256 disk and column-level encryption at rest.
* **NFR-4.6 (SOLID Dependency Inversion & Abstract Stream Ingestion):** All BLE physical hardware drivers (`BLESensorDriver`) and background telemetry simulators (`BleTelemetryService`) shall adhere to SOLID principles by implementing a unified abstract interface (`IBLESensorDriver`). Monitoring services (`ApneaEvaluator`, `BleBloc`) and live UI listeners (`MeasurementPage`) shall consume bio-signal streams exclusively through Constructor Dependency Injection (DI), enabling seamless asynchronous queueing and instant injection of developer simulation streams without modifying core monitoring logic.

### 4.5 NFR-5: Real-Time Data Visualization & Chart Specifications

| Chart Identifier | Visual Chart Type | Underlying Library | Data Rendered | Rendering & Performance Spec |
| :--- | :--- | :--- | :--- | :--- |
| **CHART-01** | **Live Airflow Telemetry Line Chart** | `fl_chart` / Skia GPU | Continuous respiratory airflow wave ($V_{\text{net}}$ / $V_{\text{volumetric}}$). | 60 FPS active / 0 FPS locked. 100ms updates with cubic spline smoothing. |
| **CHART-02** | **FFT Frequency Spectrum Graph** | `victory-native` / `fl_chart` | FFT magnitude vs. Frequency (Hz). | Renders spectral peaks to compute respiration rate (BPM). |
| **CHART-03** | **Circular Progress Metric Rings** | Circular Progress Indicator | Sleep Quality Score %, Calibration progress. | Animated stroke fill with dynamic status colors. |
| **CHART-04** | **Multi-Axis Historical Session Chart** | `fl_chart` | Overnight AHI events, SpO2, and Heart Rate over 8h. | Pinch-to-zoom and pan interactions with event markers. |

### 4.6 NFR-6: Clinical Standards, International Regulations & Air Freight

* **NFR-6.1 (AASM Diagnostic Standard Alignment):** Apnea ($\ge 90\%$ drop $\ge 10\text{s}$) & Hypopnea ($\ge 30\%$ drop $\ge 10\text{s}$) classification.
* **NFR-6.2 (IEC 60601-1-8 Medical Alarm Hierarchy):** High (>20s), Medium (10–20s), and Low (BLE drop) alarm priority levels.
* **NFR-6.3 (SaMD & Quality Management Framework):** Developed under FDA 21 CFR Part 820 / ISO 13485 framework.
* **NFR-6.4 (GDPR Article 9 Compliance):** Special Category Health Data rules with explicit consent management.
* **NFR-6.5 (Hardware Air Freight Customs Compliance):** UN 38.3 battery certification, IATA PI 967 Section II **< 2.7 Wh (<700 mAh)** battery cap, ISO 10993 skin biocompatibility, pre-certified 2.4 GHz BLE spectrum (BLE 4.0, 4.1, 4.2, and 5.0+; FCC, CE RED, TELEC, SRRC, KC, Bluetooth SIG QDID).
* **NFR-6.6 (Phased International Regulatory Roadmap):**
  - **Phase 1 (Years 1–2):** NMPA Class II Medical Device (China/HK) + EU CE Marking.
  - **Phase 2 (Year 3):** European Union CE Marking (MDR).
  - **Phase 3 (Year 4):** US FDA Class I Medical Device Clearance & USPTO Patent Enforcement.

---

## 5. Success Metrics & Key Performance Indicators (KPIs)

| Metric | Target | Verification Method |
| :--- | :--- | :--- |
| **HIPAA Security Compliance** | 100% compliance across all §164.312 technical safeguards | Annual HIPAA security audit & penetration testing |
| **Passkey Authentication Success** | >98% first-attempt biometric login | In-app auth telemetry |
| **Device Binding API Success** | 100% cloud binding acknowledgment | End-to-end API integration tests |
| **Emergency Intervention Success** | 99.9% reliable trigger on true apnea stops | Automated signal simulation tests |
| **Overnight Battery Efficiency** | **< 8.0% drain over 8 hours** | Battery profiling benchmarks |

---

## 6. Future Expansion & Hardware Enhancement Roadmap

* **⚡ HW-ENHANCEMENT-1 (Device Micro-Electrical Stimulation - EMS/TENS):** Future hardware revisions of the D-BAND device may integrate mild micro-electrical stimulation (safe EMS micro-pulses) delivered directly via the device hardware to gently stimulate airway muscles and wake the patient.
* **Full EHR/EMR Doctor Integration:** Direct HL7 FHIR API synchronization for seamless health profile and sleep report delivery to primary care physicians.
* **Smart Home IoT Action Triggers:** Automated cloud integration to turn on bedroom lights or raise bed incline during severe apnea alerts.

