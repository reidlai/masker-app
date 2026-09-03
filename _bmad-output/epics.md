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

## Epic List

### Epic 1: Mobile App Infrastructure, UI Kit & Biometric Passkey Onboarding (MVP1 - Active)
Patients can perform passwordless FIDO2 Passkey registration using native biometrics (Face ID / Touch ID), set up their medical baseline profile, and navigate a responsive `flutter_shadcn` dark glassmorphic UI.
**FRs covered:** FR-5.1, FR-5.2 | **NFRs:** NFR-4.1, NFR-4.4, NFR-4.5 | **UX-DRs:** UX-DR1

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

