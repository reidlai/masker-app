---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/prd/prd.md
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/DESIGN.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
---

# Sleep Apnea Detection App (D-BAND Integrated Platform) - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Sleep Apnea Detection App (D-BAND Integrated Platform), decomposing the requirements from the PRD and Architecture requirements into implementable stories.

> [!IMPORTANT]
> **MVP1 Scope & Implementation Directive:**  
> In accordance with product owner strategy, **MVP1 focuses exclusively on the Mobile Application (Flutter) and Bluetooth Device Connection (BLE 4.0, 4.1, 4.2, and 5.0+)** for at-home sleep apnea monitoring (Epics 1–4). All web portal backoffice, physician EHR sync, multi-mode athletic/meditation applications, and cloud big data exports (Epics 5–8) are categorized as **UNPLANNED** and will remain deferred until further instruction.

## Requirements Inventory

### Functional Requirements

- **FR-1.1:** The application shall automatically scan for, identify, and establish a low-energy Bluetooth (BLE 4.0, 4.1, 4.2, and 5.0+, AES-128 link security) connection with the D-BAND sensor array (`0x180D` service / `0x2A37` characteristic @ 10Hz).
- **FR-1.2:** Upon successful BLE pairing, the application shall execute the Cloud Device Binding API (`POST /api/v1/devices/bind`), transmitting an encrypted payload containing `user_profile_id`, `device_hardware_id`, `ble_mac_address`, and `binding_timestamp`.
- **FR-1.3:** If the device is paired without active internet connectivity, the application shall queue the device binding payload locally in an encrypted buffer and retry transmission upon network restoration.
- **FR-1.4:** Prior to sensor positioning, the application shall execute a 5-to-10 second sampling phase of idle BLE data to compute ambient room thermal noise floor ($N_{\text{idle}}$).
- **FR-1.5:** Following device attachment, the application shall execute a 10-to-20 second active breathing calibration phase, sampling inhale temperature ($T_{\text{inhale}}$) and exhalation peak temperature ($T_{\text{exhale}}$).
- **FR-1.6:** The application shall transform instantaneous thermal deviation data $\Delta T(t) = T_{\text{exhale}}(t) - T_{\text{inhale}}(t)$ into lung volumetric airflow rates $V_{\text{volumetric}}(t) = f(\Delta T(t), N_{\text{idle}})$.
- **FR-1.7:** The application shall dynamically set the zero-airflow (Apnea) threshold for the session based on the calibrated net volumetric breathing baseline ($0.10 \times V_{pp}$).
- **FR-1.8:** The application shall block sleep recording initiation if active breathing signal $\Delta V < \text{Threshold}_{\min} = 1.5 \times N_{\text{idle}}$.
- **FR-1.9:** The application shall support multi-mode operating frameworks: Mode A (Nocturnal Sleep Apnea Monitoring), Mode B (Athletic Respiration Training), Mode C (Individual Respiratory Health Check), Mode D (Meditation & Breath Control).
- **FR-1.10:** The application and web portal shall provide a "Report D-BAND Sensor Lost" workflow. Upon invocation, the cloud gateway shall execute `POST /api/v1/devices/unbind`, mark hardware serial as `DEPRECATED/LOST`, revoke BLE MAC binding, and allow pairing of a replacement sensor without losing cloud history.
- **FR-2.1:** The application shall log continuous 10Hz respiratory airflow streams throughout an 8+ hour sleep window in a low-power background state.
- **FR-2.2:** The application shall evaluate real-time net volumetric airflow against the calibrated threshold every 100 milliseconds.
- **FR-2.3:** An obstructive apnea event shall be flagged whenever net airflow remains below threshold continuously for $\ge 10$ seconds.
- **FR-2.4:** Telemetry packets shall be timestamped locally and buffered in hardware-encrypted storage during temporary signal interruptions.
- **FR-2.5:** The cloud platform shall ingest compressed telemetry streams and execute AI waveform classification algorithms to refine apnea event detection and flag anomalous breathing patterns.
- **FR-3.1:** Upon flagging a critical apnea event (>10s breathing stop), the smartphone application shall trigger high-priority escalating audio tones (40 dB → 75+ dB) and full-screen haptic vibration pulses (<200ms latency).
- **FR-3.2:** The application shall render a prominent, large touch target button ("I'm Safe / I'm Awake") on the screen during an alarm event.
- **FR-3.3:** If the patient taps "I'm Safe" within 30 seconds of alarm initiation, the application shall silence the alarm and transmit a "Patient Awake & Safe" status signal to the cloud.
- **FR-3.4:** If normal respiratory airflow is restored ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$) continuously for 5 seconds without manual tap, the app shall auto-silence the alarm.
- **FR-3.5:** If the alarm remains unacknowledged after 30 seconds, the application shall transmit a high-priority Emergency Dispatch Payload to alert designated caregivers via automated cloud SMS/Voice calls.
- **FR-4.1:** Morning Sleep Summary displaying Total Sleep Duration, Overnight AHI Score (events/hour), Intervention Count, and Quality Score (0–100).
- **FR-4.2:** Interactive Respiration Timeline rendering overnight wave graphs with color-coded markers for flagged apnea episodes and safety acknowledgements.
- **FR-4.3:** Calendar & History Filter for date-filtered historical sleep sessions.
- **FR-4.4:** Educational Library containing integrated articles and instructional videos.
- **FR-4.5:** Big Data Platform & Clinical Research Export providing a secure, de-identified big data export interface for clinical research studies.
- **FR-5.1:** Passkey FIDO2/WebAuthn Authentication supporting passwordless login via native OS biometrics (Face ID, Touch ID, Android BiometricPrompt) and hardware secure enclave tokens.
- **FR-5.2:** Health Profile Management collecting and managing user health baseline profile (Weight, Height, Age, Gender, computed BMI, Emergency Contacts).
- **FR-5.3:** Extensible Doctor Sharing Framework providing a dedicated "Share Profile with Doctor" UI module and extensible JSON data export engine formatted for physician chart sharing.
- **FR-5.4:** Mobile Device Lost & Remote Session Revocation self-service Web Portal allowing users or emergency contacts to report a lost mobile phone, revoking active JWT session tokens and issuing a cryptographic remote wipe signal.
- **FR-5.5:** Application Documentation & Developer Setup Guide providing comprehensive developer README covering project summary, product background, quick start, developer mode, debugging mode, and release build workflows.
- **FR-5.6:** Developer Options Page & BLE Signal Simulator providing interactive controls for simulating 2-stage calibration lifecycles ($N_{\text{idle}}$ & $V_{pp}$) and nocturnal sleep cycles (normal 16 bpm respiration streams, $\ge 10\text{s}$ apnea breathing stop alerts, and 5s patient breathing recovery signals).

### NonFunctional Requirements

- **NFR-1.1:** Auto-Reconnect BLE connection within 3.0 seconds of signal loss.
- **NFR-1.2:** Data Recovery via a 1-hour local circular RAM ring buffer for telemetry data preservation.
- **NFR-2.1:** Primary mobile alarm triggers locally within < 200 milliseconds of apnea threshold breach.
- **NFR-2.2:** Safety acknowledgement and Tier-2 emergency payloads transmit within < 1.5 seconds to cloud backend.
- **NFR-3.1:** Continuous 8-to-10 hour background sleep logging consumes < 8.0% total phone battery.
- **NFR-3.2:** 0-FPS display throttling (Night Mode `#000000` locked black display) during active sleep monitoring.
- **NFR-3.3:** Signal processing and 256-point FFT math offloaded to background Dart Isolates for zero UI thread jank.
- **NFR-4.1:** Technical Access Control & Passkey Enforcement (HIPAA 45 CFR § 164.312(a)) with 5-minute inactivity mobile auto-lock and 15-minute portal idle timeout.
- **NFR-4.2:** Audit Controls & Tamper-Evident Logs (`phi_audit_logs` / `PhiAuditLog`) capturing all PHI access, doctor exports, and alert dispatches.
- **NFR-4.3:** Sub-1s automated cryptographic remote zeroization protocol deleting local SQLCipher databases, Hive stores, and Secure Enclave master keys upon remote wipe signal or 10 failed auth retries.
- **NFR-4.4:** Encryption in Transit & Certificate Pinning (AES-128 BLE, HTTPS TLS 1.3 with SSL Certificate Pinning, gRPC mTLS internal service mesh).
- **NFR-4.5:** Encryption at Rest (AES-256 SQLCipher local database encryption + Cloud KMS master key envelope encryption for Level 1 PHI fields).
- **NFR-5.1:** CHART-01 Live Airflow Telemetry Line Chart (`fl_chart` / Skia GPU, 60 FPS active / 0 FPS locked).
- **NFR-5.2:** CHART-02 FFT Frequency Spectrum Graph (256-point FFT magnitude vs Hz).
- **NFR-5.3:** CHART-03 Circular Progress Metric Rings (Animated stroke fill for calibration & sleep quality score).
- **NFR-5.4:** CHART-04 Multi-Axis Historical Session Chart (Interactive overnight AHI, SpO2, and respiratory amplitude curves).
- **NFR-6.1:** AASM Diagnostic Standard Alignment (Apnea $\ge 90\%$ drop $\ge 10\text{s}$ & Hypopnea $\ge 30\%$ drop $\ge 10\text{s}$).
- **NFR-6.2:** IEC 60601-1-8 Medical Alarm Hierarchy (High, Medium, Low priority audio/visual alarms).
- **NFR-6.3:** SaMD & Quality Management Framework under FDA 21 CFR Part 820 / ISO 13485 guidelines.
- **NFR-6.4:** GDPR Article 9 Special Category Health Data compliance with explicit consent management.
- **NFR-6.5:** Hardware Air Freight Customs Compliance (UN 38.3, IATA PI 967 Section II < 2.7 Wh battery cap, ISO 10993 skin biocompatibility, BLE 4.0, 4.1, 4.2, and 5.0+ FCC/CE certification).
- **NFR-6.6:** Phased International Regulatory Roadmap (Phase 1 NMPA/CE, Phase 2 EU MDR CE, Phase 3 US FDA Class I Clearance).

### Additional Requirements

- **Client Technology Stack:** Flutter (Dart) cross-platform mobile client (iOS & Android).
- **Component Architecture Pattern:** Atomic Design System Hierarchy (`flutter_shadcn` / `shadcn_ui` atoms, visual molecules, logic organisms, template pages).
- **State Management & Data Flow:** Unidirectional Data Flow + ReactiveX (`RxDart` / BLoC) stream operators (`BehaviorSubject`, `debounceTime`, `distinctUntilChanged`, `switchMap`, `catchError`).
- **Cloud Infrastructure & Streaming Pipeline:** Hybrid Firebase + GCP Ingestion Pipeline (`Flutter App` -> `Firebase Realtime DB / Cloud Functions v2` -> `GCP Eventarc` -> `GCP Cloud Pub/Sub` -> `GCP Dataflow` -> `GCP BigQuery` & `GCP Cloud SQL`).
- **DevSecOps Pipeline Security:** Secret scanning (`Gitleaks`), SAST (`Semgrep` / `SonarQube`), SCA (`Snyk` / `Trivy`), FDA-compliant SBOM (`CycloneDX`), Flutter R8/ProGuard obfuscation, Firebase App Check attestation (`Play Integrity` & `Apple App Attest`), Distroless container images, and Cosign image signing.

### UX Design Requirements

- **UX-DR1:** Implement `flutter_shadcn` design system tokens (HSL color palette, dark mode glassmorphism `#0F172A`, accessible touch targets $\ge 48\text{dp}$).
- **UX-DR2:** Implement 0-FPS Night Mode screen lock state (`#000000` pitch black screen with dim pulsing green heartbeat dot).
- **UX-DR3:** Implement Tier-1 local alarm overlay (`MOB_TIER1_ALARM`) featuring high-contrast flashing red/yellow banner (`#FF3B30`), 120dB siren, haptics, 30s countdown, and 64dp button ("I'M SAFE - DISMISS ALARM").
- **UX-DR4:** Implement 2-stage thermal calibration wizard (`MOB_CALIBRATION_STAGE1` & `MOB_CALIBRATION_STAGE2`) with 10s circular progress ring and live thermal wave canvas.
- **UX-DR5:** Implement Morning Sleep Summary Dashboard (`MOB_SLEEP_SUMMARY`) with total sleep duration, AHI severity badge, quality score ring, and doctor share trigger.

### FR Coverage Map

- **FR-1.1:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.2:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.3:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.4:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.5:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.6:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.7:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.8:** Epic 2 (BLE Bluetooth Sensor Discovery & Thermal Calibration)
- **FR-1.9:** Epic 3 (Mode A Monitoring - MVP1) & Epic 7 (Modes B/C/D - UNPLANNED)
- **FR-1.10:** Epic 5 (Backoffice Hardware Provisioning - UNPLANNED)
- **FR-2.1:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-2.2:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-2.3:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-2.4:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-2.5:** Epic 8 (Cloud Big Data & AI Clinical Research Export - UNPLANNED)
- **FR-3.1:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-3.2:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-3.3:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-3.4:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-3.5:** Epic 3 (Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm)
- **FR-4.1:** Epic 4 (Morning Sleep Dashboard & Respiration Waveform Inspection)
- **FR-4.2:** Epic 4 (Morning Sleep Dashboard & Respiration Waveform Inspection)
- **FR-4.3:** Epic 4 (Morning Sleep Dashboard & Respiration Waveform Inspection)
- **FR-4.4:** Epic 4 (Morning Sleep Dashboard & Respiration Waveform Inspection)
- **FR-4.5:** Epic 8 (Cloud Big Data & AI Clinical Research Export - UNPLANNED)
- **FR-5.1:** Epic 1 (Mobile App Infrastructure & Biometric Passkey Onboarding)
- **FR-5.2:** Epic 1 (Mobile App Infrastructure & Biometric Passkey Onboarding)
- **FR-5.3:** Epic 6 (Clinic & Attending Physician Diagnostic Portal - UNPLANNED)
- **FR-5.4:** Epic 5 (Backoffice Hardware Provisioning - UNPLANNED)
- **FR-5.5:** Epic 1 (Mobile App Infrastructure & Biometric Passkey Onboarding)
- **FR-5.6:** Epic 1 (Mobile App Infrastructure & Biometric Passkey Onboarding)

## Epic List

### Epic 1: Mobile App Infrastructure, UI Kit & Biometric Passkey Onboarding (MVP1 - Active)
Patients can perform passwordless FIDO2 Passkey registration using native biometrics (Face ID / Touch ID), set up their medical baseline profile, navigate a responsive `flutter_shadcn` dark glassmorphic UI, access developer onboarding documentation, and access the Developer Options Page with interactive BLE signal simulation controls.
**FRs covered:** FR-5.1, FR-5.2, FR-5.5, FR-5.6 | **NFRs:** NFR-4.1, NFR-4.4, NFR-4.5 | **UX-DRs:** UX-DR1

### Epic 2: BLE Bluetooth Sensor Discovery, Pairing & Thermal Calibration (MVP1 - Active)
Patients can turn on their D-BAND thermal sensor array, auto-discover and pair via encrypted BLE (BLE 4.0, 4.1, 4.2, 5.0+), execute Stage 1 room noise ($N_{\text{idle}}$) and Stage 2 active breath ($V_{pp}$) calibration, transform thermal $\Delta T$ into volumetric airflow rates, and enforce wear verification guardrails.
**FRs covered:** FR-1.1, FR-1.2, FR-1.3, FR-1.4, FR-1.5, FR-1.6, FR-1.7, FR-1.8 | **NFRs:** NFR-1.1, NFR-6.5 | **UX-DRs:** UX-DR4

### Epic 3: Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm (MVP1 - Active)
Patients can initiate overnight sleep monitoring in low-power 0-FPS Night Mode (`#000000`), record 10Hz background bio-signals into a circular RAM buffer, trigger real-time AASM apnea breach evaluation, sound an instant local audio siren & haptic alert (<200ms), tap "I'm Safe" within 30s or auto-silence upon 5s breathing recovery, and escalate to cloud caregiver SMS/Voice calls upon unacknowledged alerts.
**FRs covered:** FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-3.1, FR-3.2, FR-3.3, FR-3.4, FR-3.5, FR-1.9 (Mode A) | **NFRs:** NFR-1.2, NFR-2.1, NFR-2.2, NFR-3.1, NFR-3.2, NFR-3.3, NFR-4.3 | **UX-DRs:** UX-DR2, UX-DR3

### Epic 4: Morning Sleep Dashboard & Respiration Waveform Inspection (MVP1 - Active)
Patients can review total sleep duration, overnight AHI score, intervention count, and quality score ring, inspect interactive 60 FPS Skia GPU respiration waveforms (`fl_chart`) and 256-point FFT spectral graphs, filter historical sessions by date range, and read educational respiratory content.
**FRs covered:** FR-4.1, FR-4.2, FR-4.3, FR-4.4 | **NFRs:** NFR-5.1, NFR-5.2, NFR-5.3, NFR-5.4 | **UX-DRs:** UX-DR5

---

### 🛑 UNPLANNED EPICS (Deferred Until Further Instruction - Post-MVP1)

### Epic 5: Backoffice Hardware Provisioning, Sensor Lost & Remote Wipe Operations (UNPLANNED)
Administrative backoffice operations for unbinding lost D-BAND hardware serials, revoking paired BLE MAC addresses, managing WebAuthn session revocations, and executing cryptographic remote wipes.
**FRs covered:** FR-1.10, FR-5.4 | **Status:** UNPLANNED

### Epic 6: Clinic & Attending Physician Diagnostic Portal (UNPLANNED)
Dedicated physician web portal for reviewing patient AHI trends, signing digital diagnostic notes, locking clinical charts, and exporting HL7 FHIR JSON reports.
**FRs covered:** FR-5.3 | **Status:** UNPLANNED

### Epic 7: Multi-Mode Respiratory Applications (Athletic, Health Check, Meditation) (UNPLANNED)
Expanded Flutter application modes for Athletic Respiration Training (Mode B), Individual Respiratory Health Check (Mode C), and Meditation Rhythms (Mode D).
**FRs covered:** FR-1.9 (Modes B, C, D) | **Status:** UNPLANNED

### Epic 8: Cloud Big Data Analytics & De-Identified Clinical Research Export (UNPLANNED)
Cloud big data pipeline for de-identified PHI data exports, clinical trial research integration (PolyU/CUHK), and cloud-side neural network re-classification.
**FRs covered:** FR-2.5, FR-4.5 | **Status:** UNPLANNED

---

## Detailed User Stories (MVP1 Active Epics)

### Epic 1: Mobile App Infrastructure, UI Kit & Biometric Passkey Onboarding

#### Story 1.1: Passkey FIDO2/WebAuthn Biometric Authentication
As a patient,  
I want to authenticate passwordlessly using my device biometrics (Face ID / Touch ID / Android BiometricPrompt),  
So that my PHI health data is securely encrypted under HIPAA §164.312 without requiring vulnerable passwords.

**Acceptance Criteria:**
- **Given** the app launches on `LoginPage`,
- **When** I tap "Sign in with Passkey",
- **Then** `AuthBloc` dispatches `AuthPasskeySubmitted` and triggers native OS biometric authentication.
- **And** upon success, the state transitions to `AuthAuthenticated` and navigates to `MainContainerPage`.
- **And** UI is composed of `BrandHeaderOrganism`, `PasskeyAuthCardOrganism`, and `SecurityBadgeOrganism`.

#### Story 1.2: Patient Health Baseline & Demographics Setup
As a patient,  
I want to enter and edit my physical demographics (Age, Weight, Height) and Caregiver Emergency Phone Number,  
So that the system can calculate my baseline BMI and alert my caregiver during nocturnal apnea emergencies.

**Acceptance Criteria:**
- **Given** I am on `ProfilePage`,
- **When** I update my weight or height input fields,
- **Then** `HealthDemographicsOrganism` dynamically recalculates and displays my computed BMI ($Weight / Height^2$).
- **And** `EmergencyContactOrganism` preserves my caregiver emergency phone number.
- **And** `UserHeaderOrganism` renders my custom persona title and dynamic initials avatar fallback.

#### Story 1.3: App Navigation & Bottom Navigation Tab Bar
As a patient,  
I want to navigate between Home, Sleep Measurement, Morning Summary, and Settings screens via a bottom navigation bar,  
So that I can quickly access monitoring tools and application options.

**Acceptance Criteria:**
- **Given** I am on `MainContainerPage`,
- **When** I tap Tab 4 (Gear icon),
- **Then** the page inline renders `SettingsPage`.
- **And** `SettingsGroupCardOrganism` renders Profile and Advanced options card sections.

#### Story 1.4: Mobile App Documentation & Developer Setup Guide
As a developer or contributor,  
I want a comprehensive `flutter/README.md` document covering project background, quick start, developer mode, debugging mode, and release build workflows,  
So that I can quickly set up my local development environment and build production APKs without ambiguity.

**Acceptance Criteria:**
- **Given** the repository is cloned,
- **When** a developer opens `flutter/README.md`,
- **Then** it provides clear instructions for:
  1. Product Overview & Architecture Summary (D-BAND Integrated Platform).
  2. Quick Start setup commands (`flutter pub get`, `flutter test`, `flutter run`).
  3. How to enable Developer Mode (`--dart-define=DEV_MODE=true` compile-time flag).
  4. How to enable Debugging Mode (`debuggingEnabled: true` flag / `kDebugMode`).
  5. How to build production release APKs (`flutter build apk --debug / --release`).

#### Story 1.5: Developer Options Page & BLE Signal Simulator Controls
As a developer or tester,  
I want to navigate to a dedicated `DeveloperOptionsPage` when Developer Mode (`DEV_MODE=true`) is enabled,  
So that I can trigger interactive BLE signal simulation controls to test the calibration lifecycle and nocturnal sleep apnea alarm cycles without requiring physical hardware.

**Acceptance Criteria:**
- **Given** Developer Mode (`DEV_MODE=true`) is enabled,
- **When** I view `SettingsPage` under the Advanced section (`SettingsGroupCardOrganism`),
- **Then** the "Developer" menu row (`SettingsMenuRow`) is displayed.
- **And** tapping "Developer" navigates to `DeveloperOptionsPage`.
- **And** `DeveloperOptionsPage` renders `BleSimulatorOrganism` with controls for:
  1. **Calibration Lifecycle Simulation**: Triggering ambient idle noise ($N_{\text{idle}}$) and active breathing baseline ($V_{pp}$).
  2. **Sleep Cycle Simulation**: Triggering normal 16 bpm respiration streams, $\ge 10\text{s}$ apnea breathing stop alerts, and 5s patient recovery signals.

---

### Epic 2: BLE Bluetooth Sensor Discovery, Pairing & Thermal Calibration

#### Story 2.1: Encrypted BLE Sensor Auto-Discovery & Cloud Device Binding
As a patient,  
I want the app to automatically discover and pair with my D-BAND thermal sensor array over encrypted BLE 5.0+,  
So that telemetry data can be securely streamed to my device.

**Acceptance Criteria:**
- **Given** I am on `MeasurementPage`,
- **When** the app scans for `0x180D` GATT service,
- **Then** `BleSensorStatusOrganism` displays connection status ("D-BAND Sensor Connected ✓" vs "Scanning...").
- **And** `BleSensorDriver` establishes AES-128 link security.

#### Story 2.2: 2-Stage Thermal Sensor Baseline Calibration
As a patient,  
I want to perform a 2-stage calibration (Stage 1 ambient noise $N_{\text{idle}}$ and Stage 2 active breath $V_{pp}$),  
So that the zero-airflow apnea threshold ($0.10 \times V_{pp}$) is accurately established for my session.

**Acceptance Criteria:**
- **Given** I start sensor positioning on `MeasurementPage`,
- **When** `ThermalCalibrationWizard` samples 10 seconds of idle ambient data,
- **Then** it computes room thermal noise floor $N_{\text{idle}}$.
- **And** following 10 seconds of active breathing, it sets apnea threshold to $0.10 \times V_{pp}$.

#### Story 2.3: Airflow Volumetric Transformation & Wear Guardrails
As a patient,  
I want the system to verify sensor placement before recording,  
So that invalid or unattached sensor readings do not produce false apnea readings.

**Acceptance Criteria:**
- **Given** active breath calibration is completed,
- **When** active breathing delta $\Delta V < 1.5 \times N_{\text{idle}}$,
- **Then** the system blocks sleep recording initiation and displays a sensor wear warning.

---

### Epic 3: Nocturnal Sleep Apnea Monitoring & Tier-1 Local Emergency Alarm

#### Story 3.1: Low-Power Background Airflow Monitoring & 0-FPS Night Mode
As a high-risk nocturnal apnea patient,  
I want continuous 10Hz background sleep logging in a 0-FPS pitch-black screen state,  
So that my phone battery is conserved (<8% consumption) while my breathing is continuously monitored overnight.

**Acceptance Criteria:**
- **Given** active monitoring is launched,
- **When** Night Mode activates,
- **Then** the screen throttles to 0-FPS pitch black (`#000000`) with dim pulsing heartbeat indicator.
- **And** 10Hz respiratory data is written into a 1-hour circular RAM buffer.

#### Story 3.2: Real-Time AASM Apnea Event Evaluation
As a patient,  
I want the app to evaluate net airflow against my calibrated baseline every 100ms,  
So that obstructive apnea events ($\ge 90\%$ drop for $\ge 10$ seconds) are immediately flagged.

**Acceptance Criteria:**
- **Given** continuous 10Hz airflow data is streaming,
- **When** net volumetric airflow drops below threshold continuously for $\ge 10$ seconds,
- **Then** `ApneaEvaluator` flags an obstructive apnea breach event and transitions state to `breachAlert`.

#### Story 3.3: Tier-1 Local Emergency Siren & Escalating Alarm Overlay
As a patient,  
I want an escalating local siren ($40\text{dB} \to 75+\text{dB}$) and full-screen haptic vibration pulse within <200ms of an apnea breach,  
So that I am immediately awakened to resume breathing.

**Acceptance Criteria:**
- **Given** `ApneaEvaluator` flags a breach event,
- **When** `ApneaAlertOverlay` renders within <200ms,
- **Then** high-contrast red/yellow warning banner flashes with escalating siren tone.
- **And** tapping "I'M SAFE" within 30 seconds silences the alarm and restores normal monitoring.
- **And** continuous normal breathing for 5 seconds automatically silences the alarm.

#### Story 3.4: Caregiver Emergency Dispatch Payload
As a patient,  
I want the app to transmit an emergency dispatch payload to designated caregivers if I do not respond within 30 seconds,  
So that emergency assistance can be dispatched if I am unresponsive.

**Acceptance Criteria:**
- **Given** an apnea alarm has been sounding for 30 seconds,
- **When** no "I'm Safe" tap or breathing restoration occurs,
- **Then** the app transmits a Tier-2 emergency payload via cloud SMS/Voice call API to caregiver contacts.

---

### Epic 4: Morning Sleep Dashboard & Respiration Waveform Inspection

#### Story 4.1: Morning Sleep Summary Dashboard
As a patient,  
I want a morning sleep summary displaying my overnight AHI score, total monitoring duration, and quality score,  
So that I can quickly assess my sleep health upon waking.

**Acceptance Criteria:**
- **Given** I open `SummaryScreenPage`,
- **When** the page loads,
- **Then** `ReportHeaderOrganism` displays session date and report title.
- **And** `SleepScoreOrganism` renders the 0–100 score ring (`92`) and AHI score badge (`3.2 Normal`).
- **And** `SummaryMetricsGridOrganism` renders total apnea stops and safety tap metrics.

#### Story 4.2: Respiration Waveform & Spectral Graphs
As a patient,  
I want to inspect overnight respiration waveforms rendered at 60 FPS via GPU,  
So that I can visually review breathing patterns and apnea episodes.

**Acceptance Criteria:**
- **Given** I view `SummaryScreenPage`,
- **When** rendering waveform graphs,
- **Then** `LiveWaveformChart` renders smooth GPU-accelerated Skia line plots (`fl_chart`).

#### Story 4.3: Historical Sessions & Educational Insights
As a patient,  
I want to filter historical sleep sessions by date and read educational articles on sleep apnea,  
So that I can track long-term health progress and improve mask compliance.

**Acceptance Criteria:**
- **Given** I am on `HomePage`,
- **When** I view the dashboard,
- **Then** `WeeklyCalendarOrganism` supports date selection.
- **And** `HealthInsightsOrganism` provides article cards ("Mask Use & Health" & "Understanding SpO2").

#### Story 4.4: Signed Physician Report Export
As a patient,  
I want to export a signed FHIR JSON / PDF clinical report of my sleep session,  
So that I can share verified health data with my attending physician.

**Acceptance Criteria:**
- **Given** I am on `SummaryScreenPage`,
- **When** I tap "Export Signed Report for Physician",
- **Then** the app compiles encrypted FHIR JSON and PDF clinical summary payloads for doctor sharing.
