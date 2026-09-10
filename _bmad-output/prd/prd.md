---
title: Product Requirements Document — D-BAND Platform
status: final
version: 3.0.0
created: 2026-08-31
updated: 2026-09-10
author: Mary (Business Analyst) & Winston (System Architect)
---

# ⚡ Product Requirements Document (PRD)
## D-BAND Platform (Bio-Telemetry & Hardware Integration Suite)

---

## 1. Executive Summary & Goals

### 1.1 Product Overview
**D-BAND Platform** is an extensible, high-performance hardware integration suite and bio-telemetry platform designed for **d-band thermal and ink sensor technology** (manufactured in partnership with OM Sciences / 機質科學). The platform provides continuous wireless telemetry acquisition via **Bluetooth Low Energy (BLE 4.0, 4.1, 4.2, and 5.0+)**, sensor baseline drift calibration, edge signal processing, reactive data stream dispatching, and multi-tier emergency escalation.

Built with a modular, plug-and-play architecture (`flutter_bloc`, RxDart 10Hz-throttled BLE driver, reactive data sinks), D-BAND Platform is engineered to support a broad array of bio-telemetry and thermal/ink sensor applications — including continuous vital sign tracking, athletic respiratory performance, and clinical telemetry. 

The premier flagship solution launched on the platform is **At-Home Nocturnal Sleep Apnea Detection** (via the cross-platform client application `masker-app`). Instead of requiring costly, uncomfortable hospital polysomnography visits or intrusive CPAP masks, D-BAND Platform reads continuous 10Hz thermal airflow telemetry from a lightweight sensor worn comfortably at home. The platform establishes a per-session **Sensor Baseline Drift & Noise Floor Envelope** `[lower_bound, upper_bound]` and detects nocturnal apnea episodes as the absence of breath excursions beyond resting thresholds.

Access is secured via passwordless **Passkey (FIDO2/WebAuthn)** biometrics and strictly compliant with **HIPAA Security & Privacy Rules** for Protected Health Information (PHI). When severe or prolonged breathing stops are detected during sleep, the application initiates an active **Two-Tier Emergency Response System**:
1. **Tier-1 Primary App & Device Wake-Up Alert:** Escalating smartphone audio alarms & haptics (and future device micro-electrical stimulation) to wake the patient and restore breathing. *(MVP1.)*
2. **Tier-2 Cloud Safety Signal (MVP1) & Outbound Dispatch (MVP2):** Real-time signal transmission to the cloud backend. In **MVP1** the cloud **logs** the event — a "Patient Awake & Safe" signal on an "I'm Safe" tap, or an unacknowledged-timeout signal after 30 seconds — with **no outbound contact**. **Tier-2 outbound dispatch** (priority SMS/voice to designated caregivers, and region-aware EMS CAD gateways routed by the patient's country/location) is a **Premium capability deferred to MVP2** — see FR-3.5.

### 1.2 Strategic Business Goals
* **Extensible Bio-Telemetry Platform:** Provide a standardized hardware integration layer, reactive telemetry queue, and plug-and-play signal processing framework for d-band thermal and ink sensor technology across direct-consumer, clinical, and OEM hardware ecosystem partners.
* **At-Home Non-Invasive Accessibility:** Provide a comfortable, ductless alternative to clinical CPAP machines and hospital sleep studies.
* **Multi-Domain Telemetry Suite:** Support nocturnal sleep monitoring (Phase 1 flagship), athletic respiration training (Phase 2), individual respiratory health checks, and extended ink/thermal sensor telemetry (Phase 3).
* **Frictionless HIPAA Security:** Passwordless **Passkey** onboarding and hardware-encrypted local/cloud PHI storage.
* **Proactive Patient Safety:** Move from passive morning data logging to active overnight intervention during critical apnea episodes.
* **Big Data & Ecosystem Integration:** Aggregated cloud big data analytics for AI model training (PolyU/CUHK clinical research), extensible EHR/EMR physician chart sharing, and open OEM driver SDKs.
* **Sustainable Subscription Model:** A free tier delivers the full safety-critical local monitoring path to every user; a paid **Premium** subscription funds cloud analytics, long-term history/archive, doctor-sharing, and monitored emergency-dispatch tier.

### 1.3 MVP1 Project Scope Statement (UJ-1 Focus)

> [!IMPORTANT]
> **MVP1 Release Scope Boundary:** MVP1 focuses **exclusively on User Journey 1 (UJ-1)**—delivering a production-grade, HIPAA-compliant at-home nocturnal sleep apnea monitoring solution on the D-BAND Platform for David (Persona A). Advanced multi-mode applications, clinical portals, and OEM driver SDKs are deferred to Phase 2/3.

#### 🎯 Primary MVP1 Objective
To deliver a production-ready mobile application (iOS & Android) and supporting backend cloud infrastructure that enables high-risk sleep apnea patients to perform passwordless biometric onboarding, wirelessly pair their **D-BAND sensor array**, complete the single-stage **Sensor Baseline Drift & Noise Floor Envelope** calibration, undergo 8+ hours of continuous nocturnal sleep apnea monitoring, receive instant Tier-1 local sirens (<200ms) with a 30s "I'm Safe" safety tap, record the Tier-2 cloud safety signal (log only — acknowledged or unacknowledged-timeout), and view a morning **Apnea Index** sleep summary and a daily Home dashboard. **Tier-2 outbound dispatch (caregiver telephony and region-aware EMS) is deferred to MVP2.**

#### ✅ In-Scope Capabilities for MVP1 (UJ-1 Only):
1. **Biometric Onboarding & Passkey Auth:** FIDO2 passwordless authentication (Face ID / Touch ID / BiometricPrompt) and HIPAA health profile setup (Patient Full Name, Email Address, Phone Number, Age, Weight, Height, computed BMI, Caregiver Name, Caregiver Emergency Phone) under HIPAA 45 CFR § 164.312 & FDA SaMD technical access, encryption, and audit compliance rules.
2. **D-BAND Hardware Pairing & Cloud Binding:** Wireless BLE (BLE 4.0, 4.1, 4.2, and 5.0+) auto-discovery, pairing (`0x180D` service / `0x2A37` characteristic @ 10Hz), AES-128 link encryption, and Cloud Device Binding API (`POST /api/v1/devices/bind`) with offline queuing.
3. **Sensor Baseline Drift & Noise Floor Envelope Calibration Wizard:** A single worn-sensor idle sample (~10s, patient still) that records the running **min and max** of the raw bio-signal to establish the session **Sensor Baseline Drift & Noise Floor Envelope** `[lower_bound, upper_bound]`, followed by a **wear check** that requires ≥ 2 valid band-excursion breath cycles (signal rising above `upper_bound` on inhale *and* falling below `lower_bound` on exhale) before monitoring can start. No active-breath training stage.
4. **Nocturnal Sleep Apnea Monitoring (Mode A):** Continuous 10Hz background telemetry logging, low-power 0-FPS Night Mode (`#000000` black screen, <8% battery drain over 8h), and real-time apnea evaluation — an apnea event when **no valid noise-envelope breath excursion occurs for $\ge 10\text{s}$** (retains the AASM 10-second duration standard).
5. **Emergency Response — Tier-1 Local + Tier-2 Cloud Safety Signal (log only):**
   - **Tier-1 Local Mobile Siren (<200ms):** Escalating 40 dB $\rightarrow$ 75+ dB audio alarm and full-screen haptic vibration pulses.
   - **Tier-1 Patient "I'm Safe" Tap:** Large touch target with 30s countdown. Silences alarm, or auto-silences upon 5s continuous breathing restoration.
   - **Tier-2 Cloud Safety Signal (log only):** The cloud records the acknowledged "Patient Awake & Safe" event, or the unacknowledged-timeout event after 30s. **No outbound contact in MVP1.** Cloud transmission of this signal is a Premium capability (FR-3.3).
   - *Out of MVP1 scope:* **Tier-2 outbound dispatch** — caregiver SMS/voice and region-aware EMS CAD — deferred to MVP2 (FR-3.5).
6. **Morning Analytics & Session History:** Morning sleep summary dashboard (Total duration, **Apnea Index (AI)**, intervention count, quality score, apnea-only caveat), Home dashboard (last night, 7-night trend, streak, device status), interactive raw-signal respiration wave graph with the Sensor Baseline & Noise Envelope bounds overlaid, rolling 7-day on-device history, AES-256 local SQLCipher database encryption, and 5-minute inactivity session timeout under HIPAA 45 CFR §164.312.
7. **Free / Premium Subscription & Billing:** Two-tier entitlement model with the full safety-critical local path always free; Stripe-hosted card capture (PCI-DSS SAQ-A); backend-owned subscription lifecycle; server-verified entitlement with a bounded offline grace window; monthly and discounted-annual pricing; no free trial. See FR-6.

#### ❌ Out-of-Scope for MVP1 (Deferred to Future Releases / MVP2+):
- **Secondary Application Modes (Modes B, C, D):** Athletic Respiration Training (Mode B), Individual Respiratory Health Check (Mode C), and Meditation Rhythms (Mode D) are deferred to MVP2.
- **All Tier-2 Outbound Emergency Dispatch:** Both caregiver telephony escalation (priority SMS/voice, `Task_DispatchCaregiver`) *and* region-aware EMS CAD gateway integration (`Task_DispatchEMS`, routed by patient country/location — not US-911-only) are deferred to MVP2. MVP1's Tier-2 is a **cloud log only** (FR-3.3); no one is contacted on an unacknowledged event in MVP1. Emergency caregiver contact details are still captured at onboarding for the MVP2 feature.
- **Direct HL7 FHIR EMR/EHR Hospital Sync:** Direct API synchronization with hospital electronic medical record systems is deferred to MVP2 (MVP1 provides in-app graphs and PDF export).
- **Cloud Neural Network Deep Learning AI Engine:** Complex cloud-side neural re-classification of raw bio-signals is deferred to MVP2 (MVP1 executes real-time IDLE-Band signal processing on edge Dart Isolates).
- **Hypopnea Detection & True AHI:** MVP1 scores **apnea events only** (IDLE-Band quiescence ≥ 10 s). Hypopnea scoring per AASM requires a ≥ 3 % SpO₂ desaturation *or* an EEG arousal — signals the airflow-only D-BAND cannot measure — so the nightly metric is an **Apnea Index (AI)**, not a full Apnea-Hypopnea Index. Co-sensing with an oximeter to produce a true AHI is deferred (see §6).
- **Hardware EMS/TENS Micro-Electrical Stimulation:** Micro-electrical pulses on D-BAND hardware are deferred to future hardware revisions (`HW-ENHANCEMENT-1`).

---

## 2. Target Personas & Primary User Journey

### 2.1 Target Personas & Platform Ecosystem Segments
* **Persona A: David (At-Home High-Risk Sleep Patient - Age 48) — Primary Direct Consumer (MVP1):** Suffers from severe loud snoring, morning fatigue, and unmonitored nocturnal breathing pauses. Cannot tolerate CPAP masks or pressure. Needs immediate local wake-up alarms and 30-second "I'm Safe" dismissal.
* **Persona B: At-Home Health Seeker / Snorer — Direct Consumer (MVP1):** Individuals experiencing chronic snoring or morning exhaustion seeking non-invasive at-home monitoring, simple calibration, and morning sleep quality metrics.
* **Persona C: Relatives & Caregivers — Support Ecosystem (MVP1/MVP2):** Relatives monitoring vulnerable patients remotely who require automated cloud emergency alerts when alarms go unacknowledged after 30 seconds.
* **Persona D: Sleep Physicians & Clinical Partners — Clinical Ecosystem (Phase 2):** Sleep specialists and pulmonology researchers who require standardized export of raw respiratory waveforms, historical trend analytics, and EHR chart integration.
* **Persona E: Hardware OEMs & Telehealth Integrators — Platform Partners (Phase 3):** Device manufacturers and digital health developers building custom wearables or telehealth apps on the D-BAND Platform BLE driver and reactive telemetry pipeline.

### 2.2 User Journey 1 (UJ-1): Bedtime Monitoring, Calibration & Emergency Response Lifecycle

**Protagonist:** David (48, high-risk sleep apnea patient sleeping at home).

1. **10:15 PM — Passkey Onboarding & Profile Verification:**  
   David opens the Sleep Apnea Detection App on his smartphone at bedtime. Instead of typing passwords, he authenticates instantly using his phone's native biometrics (Face ID / Touch ID) via passwordless FIDO2 Passkey. The app displays his health baseline profile (Age: 48, Weight: 85kg, Height: 178cm, BMI: 26.8) and emergency contact information.

2. **10:25 PM — D-BAND Sensor Discovery & Wireless Pairing:**  
   David turns on his lightweight D-BAND ductless sensor. The mobile app automatically scans, discovers, and pairs with the D-BAND sensor via Bluetooth Low Energy (BLE 4.0, 4.1, 4.2, and 5.0+). The app securely registers the hardware binding with the cloud environment.

3. **10:30 PM — IDLE Band Calibration:**  
   - **Idle sample:** With the D-BAND already on, the app asks David to sit still and breathe gently for ~10 seconds. It tracks the running **minimum and maximum** of the raw bio-signal over the window; those become his session **IDLE Band** `[lower_bound, upper_bound]`.
   - **Wear check:** David then takes a few normal breaths. The app confirms it can see ≥ 2 full breath cycles cross *both* band lines — the signal rising above `upper_bound` on inhale and dropping below `lower_bound` on exhale. If it can't, it blocks with *"Sensor not detecting breathing — check the fit."*
   - **Confirmation:** The screen displays *"Calibration Complete — Ready for Sleep ✓"*. David taps *"Start Sleep Monitoring"*, and the app enters low-power 0-FPS Night Mode (locked black screen `#000000` with a subtle pulsing green dot).

4. **02:15 AM — Nocturnal Apnea Event & Tier-1 Local Alarm:**  
   During deep sleep, David suffers an obstructive airway blockage. His breathing signal stops crossing the IDLE Band — no inhale excursion above `upper_bound`, no exhale excursion below `lower_bound` — for longer than 10 seconds.
   - **Sub-200ms Intervention:** The mobile app immediately triggers an escalating Tier-1 local alarm (40 dB $\rightarrow$ 75+ dB audio tones and full-screen haptic vibration pulses) to wake David and restore natural respiration.

5. **02:15 AM — Patient Safety Acknowledgement & Cloud Safety Signal:**  
   - **Option A (Patient Taps "I'm Safe"):** Awakened by the alarm, David taps the large *"I'M SAFE / I'M AWAKE"* button within 30 seconds. The app immediately silences the siren; on a Premium plan it also transmits a "Patient Awake & Safe" signal to the cloud (FR-3.3). On a Free plan the acknowledgement is written to the local event trace only.
   - **Option B (Unacknowledged >30s):** If David remains unawakened and does not tap the screen within 30 seconds, the Tier-1 local siren continues its escalation and the unacknowledged event is recorded — in the local trace, and (Premium) as a cloud safety-signal log entry. **In MVP1 no caregiver or emergency service is contacted.** Tier-2 outbound dispatch — caregiver telephony and region-aware EMS — is the MVP2 extension of this step (FR-3.5).

6. **07:00 AM — Morning Sleep Summary & Clinical Review:**  
   Waking up in the morning, David taps *"End Sleep Session"*. The app closes the BLE stream, synchronizes nocturnal session data with the cloud, and renders his **Morning Sleep Summary Dashboard**—displaying total sleep duration, overnight **Apnea Index (AI)** with an apnea-only caveat, intervention count, and the raw-signal respiration waveform with its IDLE Band bounds.

---

## 3. Functional Requirements (FR)

### 3.1 FR-1: Device Pairing, Sensor Baseline Drift & Noise Floor Envelope Calibration & Multi-Mode Framework

* **FR-1.1 (BLE Auto-Discovery):** The application shall automatically scan for, identify, and establish a low-energy Bluetooth (BLE 4.0, 4.1, 4.2, and 5.0+, AES-128 link security) connection with the D-BAND sensor array (`0x180D` service / `0x2A37` characteristic).
* **FR-1.2 (Device Binding API Framework):** Upon successful BLE pairing, the application shall execute the **Cloud Device Binding API** (`POST /api/v1/devices/bind`), transmitting an encrypted payload containing `user_profile_id`, `device_hardware_id`, `ble_mac_address`, and `binding_timestamp`.
* **FR-1.3 (Offline Device Binding Queue):** If the device is paired without active internet connectivity, the application shall queue the device binding payload locally in an encrypted buffer and retry transmission upon network restoration.
* **FR-1.4 (Sensor Baseline Drift & Noise Floor Envelope Calibration):** With the D-BAND worn and the patient still, the application shall sample the raw bio-signal for ~10 seconds (`[ASSUMPTION]` window, tunable 5–30 s), tracking the running **minimum** and **maximum** of the stream. Those two values are the session **Sensor Baseline Drift & Noise Floor Envelope** (historically IDLE Band) — `lower_bound` and `upper_bound` — the resting reference against which all breath detection and apnea evaluation run. Each new sample only widens the band; it is never narrowed within the window.
* **FR-1.5 (removed — v2.5.0):** *The former "Stage-2 Active Thermal Breath Training" step is eliminated. Rationale: awake, seated breathing differs materially from sleep breathing, so a `V_pp` amplitude baseline trained while awake is not a valid reference. The Sensor Baseline & Noise Envelope (FR-1.4) is now the only calibrated reference. ID retired; not reused.*
* **FR-1.6 (Breath Excursion Definition):** The application shall classify a **valid breath** as a cycle in which the raw signal rises to or above `upper_bound` (inhale phase) **and** falls to or below `lower_bound` (exhale phase). A breath phase that fails to cross its bound is a **"stop-breathing" sample**. The application works directly in raw signal units — there is **no** thermal-to-volumetric (L/s) transformation and no `V_pp` peak-to-peak baseline.
* **FR-1.7 (Apnea Condition Binding):** The application shall define the per-sample apnea condition directly from the Sensor Baseline & Noise Envelope: a sample is a **"stop-breathing"** sample whenever the signal lies within `[lower_bound, upper_bound]` (no excursion beyond either bound). No `0.10 × V_pp` threshold.
* **FR-1.8 (Wear Verification Guardrail):** Immediately after the noise envelope sample (FR-1.4), the application shall run a **wear check**: the patient breathes normally and the application shall block "Start Sleep Monitoring" until it observes **≥ 2 valid breath excursion cycles** (per FR-1.6) within a bounded window (`[ASSUMPTION]` ~15 s). On failure it shall show *"Sensor not detecting breathing — check the fit."* with a retry.
* **FR-1.9 (Multi-Mode Application Support):** The application shall support 4 distinct operating modes:
  - **Mode A (Nocturnal Sleep Apnea Monitoring):** 0-FPS night mode, 8h continuous logging, 2-tier emergency alarm.
  - **Mode B (Athletic Respiration Training):** Real-time lung capacity, ventilation volume, and respiration rate during running/exercise.
  - **Mode C (Individual Respiratory Health Check):** Vital capacity & lung function baseline assessment.
  - **Mode D (Meditation & Breath Control):** Guided breathing rhythms & coherence metrics.
* **FR-1.10 (D-BAND Hardware Sensor Lost & Unbinding Workflow):** The application and web portal shall provide a **"Report D-BAND Sensor Lost"** workflow. Upon invocation, the cloud gateway shall execute `POST /api/v1/devices/unbind`, mark the hardware serial number as `DEPRECATED/LOST`, revoke its paired BLE MAC binding, and allow immediate discovery and pairing of a replacement D-BAND sensor array without losing cloud session history.
* **FR-1.11 (App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue):** Upon application launch, the BLE background receiver service shall automatically start in the background (via Android Foreground Service / iOS `bluetooth-central` mode) and listen for incoming BLE packets (from either physical BLE hardware or `BleTelemetryService` simulator). Incoming signals MUST be pushed into a reactive `BehaviorSubject<double>` queue using RxDart `.add()` (`next`) so downstream consumers (including the Measure Page's IDLE Band idle calibration, the wear check, and 8+ hour sleep monitoring cycles) consume signals seamlessly from a single unified reactive stream.

---

### 3.2 FR-2: Real-Time Overnight Telemetry & Apnea Detection

* **FR-2.1 (Continuous Background Logging):** The application shall log the continuous 10Hz raw respiratory signal throughout an 8+ hour sleep window in a low-power background state.
* **FR-2.2 (Real-Time Apnea Evaluator):** The application shall evaluate the real-time raw signal against the session Sensor Baseline Drift & Noise Floor Envelope every 100 milliseconds, classifying each interval as a valid breath excursion (FR-1.6) or a "stop-breathing" interval (FR-1.7).
* **FR-2.3 (Apnea Event Flagging):** An apnea event shall be flagged whenever **no valid Noise Floor Envelope breath excursion occurs for $\ge 10$ seconds continuously** (the AASM 10-second duration standard is retained).
* **FR-2.4 (Session Data Integrity):** Telemetry packets shall be timestamped locally and buffered in hardware-encrypted storage during temporary signal interruptions.
* **FR-2.5 (Cloud AI Respiration Waveform Analytics) — `PREMIUM`:** The cloud platform shall ingest compressed telemetry streams and execute AI waveform classification algorithms to refine apnea event detection and flag anomalous breathing patterns (PolyU/CUHK clinical AI model integration). This capability is gated to the Premium tier (see FR-6); Free-tier sessions are evaluated by the on-device Noise Floor Envelope evaluator (FR-2.2/FR-2.3) only and are not streamed to the cloud AI pipeline.

---

### 3.3 FR-3: Primary App Alarm, Patient Safety Acknowledgement & Cloud Safety Signal

* **FR-3.1 (Primary Mobile App Alarm):** Upon flagging a critical apnea event (>10s breathing stop), the smartphone application shall trigger high-priority escalating audio tones (40 dB → 75+ dB) and full-screen haptic vibration pulses.
* **FR-3.2 (Patient "I'm Safe" Acknowledgement Action):** The application shall render a prominent, large touch target button (**"I'm Safe / I'm Awake"**) on the screen during an alarm event.
* **FR-3.3 (Patient Safety Signal to Cloud — log only) — `MVP1` · `PREMIUM` · `[OPEN — legal/regulatory/clinical sign-off]`:** On an "I'm Safe" tap within 30 seconds, or on an unacknowledged 30-second timeout, the application shall transmit the corresponding status signal ("Patient Awake & Safe" or "Unacknowledged apnea event") to the cloud, where it is **logged with no outbound action**. Cloud transmission is gated to the Premium tier (see FR-6). On the Free tier the alarm is silenced (or continues, on timeout) and the event is written to a **local-only** trace with no cloud transmission. **Open item:** paywalling cloud transmission of a safety-critical acknowledgement carries liability, SaMD intended-use, and IEC 60601-1-8 (NFR-6.2) exposure and must clear legal/regulatory/clinical sign-off before billing build. Recorded fallback if sign-off is negative: cloud safety-signal logging becomes free; only downstream dispatch (FR-3.5) remains Premium.
* **FR-3.4 (Automatic Alarm Silence on Breathing Restoration):** If valid Noise Floor Envelope breath excursions resume (per FR-1.6) continuously for 5 seconds without a manual tap, the app shall auto-silence the alarm. *(Free and Premium.)*
* **FR-3.5 (Tier-2 Outbound Emergency Dispatch on Timeout) — `MVP2` · `PREMIUM` · `[OPEN — legal/regulatory/clinical sign-off]`:** *Deferred to MVP2.* When built, if the alarm remains unacknowledged after 30 seconds the platform shall dispatch a high-priority **Emergency Dispatch Payload**: priority SMS/voice to designated caregiver contacts, and — routed by the patient's country/location, not US-911-only — the appropriate regional EMS Computer-Aided-Dispatch gateway. Gated to the Premium tier (see FR-6). **MVP1 behaviour:** no outbound contact of any kind on an unacknowledged event; the Tier-1 local alarm (FR-3.1) continues escalating and FR-3.3 records the event. **Open item:** the Premium gate on this capability must clear legal/regulatory/clinical sign-off. Recorded fallback if sign-off is negative: caregiver-contact escalation becomes free; only regional EMS CAD dispatch remains Premium.

---

### 3.4 FR-4: Home Dashboard, Morning Analytics, History & Big Data Platform Insights

* **FR-4.1 (Morning Sleep Summary):** Displays Total Sleep Duration, Overnight **Apnea Index (AI)** — apnea events per hour — Intervention Count, and Quality Score (0–100). Every surface that shows the AI shall carry an **apnea-only caveat**: *"This is an apnea-only screen. A full sleep study also counts shallow-breathing (hypopnea) events and may score higher."* Severity bands (Normal < 5 / Mild 5–15 / Moderate 15–30 / Severe ≥ 30) are the standard AHI bands applied to the AI. **Alarm-fired awareness:** whenever the persisted `alarm_fired` signal is true for the night, both the Morning Sleep Summary and the Home dashboard hero card (FR-4.6) shall surface an alert treatment for that night rather than a calm "Normal" state. The Summary and Home cards read the same single persisted per-session signal so the two surfaces cannot disagree. *(Free and Premium.)*
* **FR-4.2 (Interactive Respiration Timeline) — `PREMIUM`:** Renders the interactive overnight **raw-signal** wave graph with the Noise Floor Envelope bounds drawn as horizontal reference lines, pinch-to-zoom, pan, a 256-point FFT view (computed on the raw signal for respiration rate), and color-coded markers for flagged apnea episodes and safety acknowledgements. An apnea reads as a flat trace held between the band lines. Gated to the Premium tier (see FR-6). Free-tier users see the static summary metrics (FR-4.1) and a non-interactive waveform thumbnail for the current night.
* **FR-4.3 (Calendar & History Filter):** Date-filtered historical sleep sessions. **Free tier:** a rolling **7-day** window, stored on-device only, with no cloud backup and no archive — sessions older than 7 days are discarded. **Premium tier:** unlimited night-by-night history with cloud backup and archive; the local last-N window remains the offline read model (see architecture AD-15).
* **FR-4.4 (Educational Library):** Integrated articles and instructional videos. *(Free and Premium.)*
* **FR-4.5 (Big Data Platform & Clinical Research Export):** The cloud platform shall provide a secure, de-identified big data export interface for clinical research studies (CUHK / Prince of Wales Hospital pilot research). *(Platform-side; not a user-tier feature. Only Premium sessions, which stream to the cloud, contribute to this corpus.)*
* **FR-4.6 (Home Dashboard):** The application shall present a read-only Home dashboard as the post-onboarding landing surface, composed of: a greeting with the user's current monitoring streak; a **last-night hero card** (summary metrics plus the FR-4.1 alarm-fired treatment, tapping through to the Morning Sleep Summary); a **D-BAND device-status card**; and a **7-night Apnea Index trend** card. The dashboard is a pure consumer of already-computed state — it reads the local last-N `SessionSummary` cache (architecture AD-15) and the app-boot BLE receiver-service status (architecture AD-12) and shall not open its own BLE subscription or trigger a cloud fetch on load. *(Free and Premium; the 7-night trend on Free is drawn from the 7-day local window.)*

---

### 3.5 FR-5: Passkey Authentication, Health Profile, Settings, Locale & Doctor Sharing Framework

* **FR-5.1 (Passkey FIDO2/WebAuthn Authentication):** The application shall support passwordless authentication via **Passkeys**, utilizing native OS biometrics (Face ID, Touch ID, Android BiometricPrompt) and hardware secure enclave tokens.
* **FR-5.2 (Health Profile Management):** The application shall collect and manage the user's health baseline profile: Weight, Height, Age, Gender, computed BMI, and Sleep Risk Factors. Weight and Height shall be captured, stored, and displayed in the measurement units selected in FR-5.7 (kg/lb, cm/ft-in), with a single canonical unit persisted server-side and converted for display.
* **FR-5.3 (Extensible Doctor Sharing Framework) — `PREMIUM` · `[OPEN — legal sign-off, HIPAA § 164.524]`:** Provides a dedicated **"Share Profile with Doctor"** UI module and extensible JSON data export engine formatted for future EHR/EMR physician integrations. Gated to the Premium tier (see FR-6). **Open item:** HIPAA § 164.524 gives an individual the right to access their own PHI without a cost barrier beyond a reasonable copying fee; gating the doctor-report export behind Premium must clear legal sign-off before build. Recorded fallback if sign-off is negative: a basic self-service PHI export is free; only the formatted multi-visit clinical report / EHR-integration path remains Premium.
* **FR-5.4 (Mobile Device Lost & Remote Session Revocation):** The platform shall provide a WebAuthn-backed self-service Web Portal allowing users or designated emergency contacts to report a lost or stolen mobile phone. The cloud platform shall immediately invalidate all active JWT tokens, revoke session refresh tokens, and issue an automated cryptographic remote wipe signal.
* **FR-5.6 (Developer Options Page & BLE Signal Simulator):** When Developer Mode is enabled (via `DEV_MODE=true` compile-time flag), the application shall render a "Developer" menu item in Settings under the Advanced section. Tapping "Developer" shall navigate to the Developer Options Page, providing interactive BLE signal simulation controls to simulate the Sensor Baseline Drift & Noise Floor Envelope calibration, the wear check, and nocturnal sleep cycles (normal 16 bpm respiration streams that cross both band lines, $\ge 10\text{s}$ in-band [no excursion] stretches that fire an apnea alert, and 5s patient breathing recovery signals).
* **FR-5.7 (Locale & Units):** The application shall provide a **Language & Region** screen letting the user select the app display language and measurement units for weight (kg / lb) and height (cm / ft-in). The selection persists per user, applies immediately across all surfaces, and governs how FR-5.2 profile values and any weight/height-derived display (e.g. BMI inputs) are rendered. A canonical unit and an IETF language tag are stored server-side; conversion and formatting happen at display time. *(Free and Premium.)*
* **FR-5.8 (Settings Surface):** The application shall provide a single grouped **Settings** screen as the navigation home for account and app configuration, organized into **Account** (Health Profile, Passkey / device security, Mobile Device Lost), **Preferences** (Language & Region, notifications, Developer Options when enabled), and **Subscription** (current plan, Billing, Payment Method — see FR-6). Settings is a pushed detail surface reached from the Home dashboard; it is not a primary navigation tab. *(Free and Premium; the Subscription group shows tier-appropriate state.)*

---

### 3.6 FR-6: Subscription, Billing & Entitlement

* **FR-6.1 (Two-Tier Entitlement Model):** The platform shall offer exactly two tiers — **Free** and **Premium** — with a single paid subscription product. Every account is Free by default; Premium is an opt-in paid upgrade. There is **no free trial**: the Free tier is itself the always-available entry experience.
* **FR-6.2 (Safety-Critical Local Path Is Always Free):** The following shall remain fully functional on the Free tier and shall never be gated, degraded, or time-limited by subscription state: overnight monitoring and the 100 ms on-device apnea evaluator (FR-2.1–2.4), the local Tier-1 escalating alarm and its auto-silence (FR-3.1, FR-3.4), the "I'm Safe" acknowledgement with local event trace (FR-3.2 local path), Sensor Baseline Drift & Noise Floor Envelope calibration and the wear check (FR-1.4–1.8), the Morning Sleep Summary of the just-finished night (FR-4.1), the rolling 7-day on-device history (FR-4.3 Free scope), the Home dashboard (FR-4.6), and passkey auth / health profile / device pairing and loss (FR-5.1, FR-5.2, FR-5.4, FR-1.10).
* **FR-6.3 (Tier Boundary):** Feature availability by tier:

  | Capability | Free | Premium |
  | :--- | :---: | :---: |
  | Overnight monitoring + 100 ms apnea evaluator + integrity (FR-2.1–2.4) | ✅ | ✅ |
  | Local Tier-1 alarm, escalation, auto-silence (FR-3.1, FR-3.4) | ✅ | ✅ |
  | "I'm Safe" + local event trace (FR-3.2) | ✅ | ✅ |
  | IDLE Band calibration + wear check (FR-1.4–1.8) | ✅ | ✅ |
  | Morning Sleep Summary of the just-finished night (FR-4.1) | ✅ | ✅ |
  | Home dashboard — last night, 7-night trend, streak, device status (FR-4.6) | ✅ | ✅ |
  | Rolling 7-day history, on-device only, no backup / no archive (FR-4.3) | ✅ | ✅ |
  | Passkey auth, health profile, device pairing / loss (FR-5.1/5.2/5.4, FR-1.10) | ✅ | ✅ |
  | Language & Region / units (FR-5.7) | ✅ | ✅ |
  | Cloud safety-signal logging — no outbound action (FR-3.3) `[OPEN]` | — | ✅ (MVP1) |
  | Tier-2 outbound dispatch — caregiver telephony + region-aware EMS CAD (FR-3.5) `[OPEN]` | — | ✅ (MVP2) |
  | History beyond 7 days + cloud backup / archive (FR-4.3) | — | ✅ |
  | Doctor Report export / doctor sharing (FR-5.3) `[OPEN — § 164.524]` | — | ✅ |
  | Cloud AI respiration waveform analytics (FR-2.5) | — | ✅ |
  | Interactive respiration timeline + 256-pt FFT (FR-4.2) | — | ✅ |

* **FR-6.4 (Payment Processor & Card Data Scope):** All payment-card capture shall occur exclusively inside the Stripe-hosted PaymentSheet / Elements surface. No platform component (mobile app, backend, logs, analytics) shall receive, process, or store a primary account number or CVC. The platform shall persist only a display triplet (card brand, last 4, expiry) and an opaque Stripe payment-method reference. This keeps the platform in **PCI-DSS SAQ-A** scope. *(Aligns with architecture AD-14.)*
* **FR-6.5 (Backend-Owned Subscription Lifecycle):** The backend Billing service shall be the sole source of truth for subscription state. Subscription state shall be mutated only in response to HMAC-SHA256-verified Stripe webhook events; the client shall never assert entitlement to the backend. Stripe executes payment only. *(Aligns with architecture AD-13.)*
* **FR-6.6 (Server-Verified Entitlement with Bounded Offline Grace):** The client shall gate Premium capabilities on a signed entitlement claim issued by the backend. The client may honor a cached claim through a bounded connectivity grace window when the backend is unreachable; it shall fail **open** only for transport failure and shall fail **closed** for a claim that is known-expired. Loss of connectivity shall never disable any FR-6.2 safety-critical capability.
* **FR-6.7 (Pricing Structure):** Premium shall be offered as a **monthly** plan and a **discounted annual** plan. `[ASSUMPTION]` No price points are set; the PRD carries no currency amounts. Final pricing is a business decision to be recorded before billing build.
* **FR-6.8 (Pre-Paid Term & Cancel-at-Period-End Lapse):** Premium is billed on a pre-paid basis. On cancellation or failed renewal, the account shall retain Premium entitlement until the end of the paid period, then transition to Free. There shall be no mid-period downgrade and no separate post-expiry grace beyond FR-6.6. On transition to Free, cloud-archived history beyond the 7-day window shall be retained but not user-visible until re-subscription `[ASSUMPTION — retention/deletion policy pending legal]`.
* **FR-6.9 (Subscription Management UI):** The application shall provide, under Settings → Subscription (FR-5.8): a **Billing** screen showing current plan, renewal date, and plan-change / cancel actions; and a **Payment Method** screen showing the card-on-file display triplet with an update action that launches the Stripe-hosted surface (FR-6.4). Invoice history is deferred (see §6).
* **FR-6.10 (Downgrade Transparency):** Before a user completes a downgrade or cancellation, the application shall disclose in plain language which capabilities they will lose and when (in MVP1: cloud safety-signal logging, history beyond 7 days, doctor export, cloud AI analytics, interactive timeline; and Tier-2 outbound dispatch once that ships in MVP2), and shall confirm that all FR-6.2 safety-critical local capabilities remain unaffected.

> **Open items carried by FR-6 (phase-blockers for billing build, not for UX/architecture):**
> 1. FR-3.3 / FR-3.5 Premium gating — legal / regulatory (SaMD, IEC 60601-1-8) / clinical sign-off.
> 2. FR-5.3 Premium gating — legal sign-off against HIPAA § 164.524 right-of-access.
> 3. FR-6.7 price points — business decision.
> 4. FR-6.8 post-downgrade archived-PHI retention/deletion policy — legal.

---

### 3.7 Biomedical Signal Processing (BSP) & Telemetry Mathematical Specifications

* **FR-7.1 (Sensor Baseline Drift & Noise Floor Envelope Estimation):** For a discrete 10Hz bio-signal stream $S[n]$ sampled over an idle calibration window $n \in [1, N]$ ($N = f_s \times T_{\text{window}} = 10\text{ Hz} \times 10\text{ s} = 100\text{ samples}$), the session Sensor Baseline Drift & Noise Floor Envelope bounds and noise floor amplitude ($V_{pp\_noise}$) shall be calculated as non-parametric order statistics:

$$\text{lower\_bound} = \min_{n \in [1, N]} \{ S[n] \}$$

$$\text{upper\_bound} = \max_{n \in [1, N]} \{ S[n] \}$$

$$\text{Noise Floor Amplitude } (V_{pp\_noise}) = \text{upper\_bound} - \text{lower\_bound}$$

  *Percentile Outlier Trimming Option:* To prevent single-sample motion/glitch artifacts from corrupting calibration, trimmed bounds may be derived from the $5^{\text{th}}$ ($P_5$) and $95^{\text{th}}$ ($P_{95}$) percentiles of the idle sample distribution.

* **FR-7.2 (Discrete Breath Excursion & Apnea Condition Function):** A sample $S[k]$ at discrete tick $k$ is mapped to a trinary excursion state $E[k] \in \{-1, 0, 1\}$:

$$E[k] = \begin{cases} 
1 & \text{if } S[k] \ge \text{upper\_bound} \quad (\text{Inhale Excursion}) \\
-1 & \text{if } S[k] \le \text{lower\_bound} \quad (\text{Exhale Excursion}) \\
0 & \text{if } \text{lower\_bound} < S[k] < \text{upper\_bound} \quad (\text{In-Band Quiescence / Stop-Breathing Sample})
\end{cases}$$

  An **Apnea Event** is declared when the signal remains in in-band quiescence continuously for $N_{\text{apnea}} = 100$ samples ($10\text{ seconds}$ at $10\text{ Hz}$):

$$\sum_{m=k - 99}^{k} |E[m]| = 0$$

* **FR-7.3 (256-Point FFT Respiration Frequency Formula):** To extract respiration rate in Breaths Per Minute (BPM) for spectral graphs and clinical analytics (FR-4.2), the application computes a 256-point Fast Fourier Transform ($X[m]$) over a sliding $N_{\text{fft}} = 256$ sample buffer at $f_s = 10\text{ Hz}$:

$$X[m] = \sum_{n=0}^{N_{\text{fft}}-1} S[n] \cdot w[n] \cdot e^{-j 2 \pi m n / N_{\text{fft}}}$$

  where $w[n] = 0.5 \left( 1 - \cos\left(\frac{2 \pi n}{N_{\text{fft}}-1}\right)\right)$ is a Hanning window function to reduce spectral leakage. The respiration frequency $f_{\text{resp}}$ (BPM) is derived from the spectral peak index $m^*$ within the physiological breathing band ($0.067\text{ Hz to } 0.67\text{ Hz} \equiv 4\text{ to } 40\text{ BPM}$):

$$m^* = \arg\max_{m \in [m_{\min}, m_{\max}]} |X[m]|$$

$$f_{\text{resp}} (\text{BPM}) = 60 \times \left( m^* \times \frac{f_s}{N_{\text{fft}}} \right)$$

* **FR-7.4 (10Hz BLE Telemetry Quantization & Signal Conditioning):** Sensor analog-to-digital converter (ADC) readings received over BLE characteristic `0x2A37` are converted to raw bio-signal units ($S[n]$):

$$S[n] = \text{ADC}[n] \times \frac{V_{\text{ref}}}{2^N} - V_{\text{offset}}$$

  where $N$ is the ADC bit resolution ($N=12$ or $16$), $V_{\text{ref}}$ is reference voltage, and $V_{\text{offset}}$ zeroes out hardware DC bias.

---

## 4. Non-Functional Requirements (NFR)

### 4.1 NFR-1: Reliability & BLE Reconnect Resilience
* **Auto-Reconnect:** Automatic BLE re-connection within 3.0 seconds.
* **Data Recovery:** 1-hour local circular RAM ring buffer for data preservation.

### 4.2 NFR-2: Performance & Alert Latency
* **Local Alert Trigger:** Primary mobile alarm triggers within **< 200 milliseconds**.
* **Cloud Signal Latency:** The Tier-2 cloud safety-signal payload (FR-3.3) transmits within **< 1.5 seconds** on an available connection. (When Tier-2 outbound dispatch ships in MVP2, the same budget applies to the dispatch payload.)

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
| **CHART-01** | **Live Raw-Signal Line Chart** | `fl_chart` / Skia GPU | Continuous raw bio-signal wave with the IDLE Band `lower_bound` / `upper_bound` drawn as horizontal reference lines. | 60 FPS active / 0 FPS locked. 100ms updates with cubic spline smoothing. |
| **CHART-02** | **FFT Frequency Spectrum Graph** | `victory-native` / `fl_chart` | FFT magnitude vs. Frequency (Hz). | Renders spectral peaks to compute respiration rate (BPM). |
| **CHART-03** | **Circular Progress Metric Rings** | Circular Progress Indicator | Sleep Quality Score %, Calibration progress. | Animated stroke fill with dynamic status colors. |
| **CHART-04** | **Multi-Axis Historical Session Chart** | `fl_chart` | Overnight Apnea Index events, SpO2, and Heart Rate over 8h. | Pinch-to-zoom and pan interactions with event markers. |

### 4.6 NFR-6: Clinical Standards, International Regulations & Air Freight

* **NFR-6.1 (AASM Duration Standard Alignment):** An apnea event is scored as **no valid IDLE-Band breath excursion for $\ge 10\text{s}$** — the AASM 10-second minimum-duration standard is retained; the ≥ 90 % airflow-reduction criterion is expressed as "no excursion beyond the calibrated resting band." **Hypopnea is not scored** in MVP1 (AASM hypopnea requires a ≥ 3 % SpO₂ desaturation or an EEG arousal, which the airflow-only D-BAND cannot measure). The nightly metric is therefore an **Apnea Index (AI)**, not a full AHI; severity bands (Normal < 5 / Mild 5–15 / Moderate 15–30 / Severe ≥ 30) are the standard AHI bands applied to the AI, and every surface showing it carries the apnea-only caveat (FR-4.1).
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

### 5.1 Subscription & Revenue KPIs

| Metric | Target | Verification Method |
| :--- | :--- | :--- |
| **Free → Premium Conversion** | `[ASSUMPTION]` baseline set post-launch | Billing telemetry (entitlement grants / active Free accounts) |
| **Premium Retention (12-month)** | `[ASSUMPTION]` baseline set post-launch | Stripe subscription lifecycle events |
| **Annual-plan Mix** | Trend up (annual improves retention & cash flow) | Billing telemetry by plan type |
| **Entitlement Check Availability** | > 99.9% successful server verification; offline grace invoked < 1% of sessions | Client + backend entitlement telemetry |
| **Card Capture Scope Compliance** | 100% of card capture in Stripe-hosted surface; zero PAN/CVC in platform logs | PCI SAQ-A self-assessment + log scanning |

### 5.2 Counter-Metrics (must **not** regress at the paywall)

| Counter-Metric | Guardrail | Verification Method |
| :--- | :--- | :--- |
| **Nights monitored per active user** | No statistically significant drop after a user encounters a paywall vs. before | Cohort analysis around first paywall impression |
| **Uninstall rate at Free/Premium boundary** | No uninstall spike within 48h of a paywall impression | Store + in-app lifecycle telemetry |
| **Free-tier safety function** | 100% — local Tier-1 alarm, evaluator, "I'm Safe" local trace, auto-silence fire on true apnea stops regardless of subscription state | Automated signal simulation on Free-tier build |
| **Free-tier session completion** | Free overnight sessions complete and produce a Morning Summary at the same rate as Premium | Session-completion telemetry by tier |

---

## 6. Future Expansion & Hardware Enhancement Roadmap

* **⚡ HW-ENHANCEMENT-1 (Device Micro-Electrical Stimulation - EMS/TENS):** Future hardware revisions of the D-BAND device may integrate mild micro-electrical stimulation (safe EMS micro-pulses) delivered directly via the device hardware to gently stimulate airway muscles and wake the patient.
* **Tier-2 Outbound Emergency Dispatch (MVP2, Premium):** Build-out of FR-3.5 — priority SMS/voice caregiver escalation and region-aware EMS CAD gateway integration (routed by patient country/location) on an unacknowledged >30s event. MVP1 ships only the cloud safety-signal log (FR-3.3); caregiver contacts are already captured at onboarding.
* **Full EHR/EMR Doctor Integration:** Direct HL7 FHIR API synchronization for seamless health profile and sleep report delivery to primary care physicians.
* **Hypopnea / SpO₂ Co-Sensing → True AHI:** Pairing the D-BAND airflow signal with a pulse-oximetry input (bundled ring or third-party BLE oximeter) to score hypopneas against a ≥ 3 % desaturation and upgrade the nightly metric from an **Apnea Index** to a full clinical **AHI**.
* **Smart Home IoT Action Triggers:** Automated cloud integration to turn on bedroom lights or raise bed incline during severe apnea alerts.
* **In-App Invoice History (`MOB_INVOICES`):** A billing-history / downloadable-invoice screen under Settings → Subscription is deferred; MVP1 relies on Stripe's own emailed receipts (FR-6.9).
* **Family / Multi-Seat Plans & Regional Pricing:** Deferred; MVP1 is single-account, single-currency (FR-6.7).

