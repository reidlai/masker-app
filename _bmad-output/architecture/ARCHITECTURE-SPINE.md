---
title: Enterprise Architecture Specification — C4 Models, BPMN & Conceptual Data Architecture
status: final
version: 4.0.0
created: 2026-08-31
updated: 2026-08-31
author: Winston (System Architect) & Mary (Business Analyst)
---

# 🏛️ Enterprise Architecture Specification
## Sleep Apnea Detection App & Emergency Command Platform

> **Architecture Framework:** C4 Model (Context & Container) + BPMN 2.0 Process Modeling + Conceptual Data Architecture  
> **Target Scope:** Global Platform Scaling to Millions of Concurrent Devices  

---

## 1. C4 Architecture Model

### 1.1 C4 Level 1: System Context Diagram

The System Context diagram illustrates the high-level boundary of the **Sleep Apnea Detection Platform** and its interactions with human actors and external enterprise systems.

```mermaid
C4Context
    title C4 Level 1: System Context Diagram — Sleep Apnea Detection Platform

    Person(patient, "Patient / At-Home User", "Wears small breathing device at home during sleep; authenticates via Passkey.")
    Person(caregiver, "Caregiver / Family Member", "Receives Tier-2 emergency SMS/Voice calls when patient apnea alarm is unacknowledged.")
    Person(dispatcher, "Emergency Center Dispatcher", "Monitors 24/7 real-time emergency dashboard for unacknowledged 30s apnea alerts.")
    Person(doctor, "Attending Physician / Clinic", "Reviews morning AHI scores, respiration wave graphs, and clinical sleep health summaries.")

    System(system, "Sleep Apnea Detection System", "Monitors nocturnal breathing airflow, executes 2-stage calibration, triggers Tier-1 local alarms, and dispatches Tier-2 cloud emergency alerts.")

    System_Ext(telecom, "External Telecom & SMS Gateway", "Twilio / AWS SNS SMS and automated voice call dispatch platform.")
    System_Ext(ehr, "External Clinic EHR / EMR Platform", "HL7 FHIR compliant Electronic Health Record systems.")

    Rel(patient, system, "Interfaces via BLE & Mobile App (Passkey, Calibration, 'I'm Safe' Tap)")
    Rel(system, caregiver, "Sends Tier-2 Emergency SMS & Voice Alerts", "HTTPS / Telephony")
    Rel(system, dispatcher, "Broadcasts Sub-1.5s High-Priority Apnea Alarms", "WSS / SSE WebSockets")
    Rel(system, doctor, "Delivers Morning Sleep Summaries & Clinical Reports", "HTTPS / HL7 FHIR")
    Rel(system, telecom, "Triggers Automated SMS & Voice Payloads", "REST API")
    Rel(system, ehr, "Synchronizes Health Records & AHI Trends", "HL7 FHIR API")
```

---

### 1.2 C4 Level 2: Container Diagram

The Container diagram decomposes the system into executable applications, data stores, stream processing workers, and web portals.

```mermaid
C4Container
    title C4 Level 2: Container Diagram — Sleep Apnea Detection System

    Person(patient, "Patient", "At-home user.")
    Person(dispatcher, "Emergency Dispatcher", "24/7 monitoring operator.")
    Person(doctor, "Physician", "Sleep specialist.")

    Container(hardware, "Small Breathing Device", "Embedded Firmware", "Captures raw airflow differential pressure; streams 100ms GATT packets via BLE.")
    
    Container(mobile_app, "Mobile Application", "Flutter (iOS & Android)", "Handles Passkey auth, 2-stage calibration, 100ms signal evaluation, 0-FPS locked display, and Tier-1 audio/haptic alarms.")

    Container(firebase_auth, "Firebase Auth", "FIDO2 / WebAuthn Service", "Manages passwordless Passkey tokens and JWT session verification.")

    Container(pubsub, "Cloud Pub/Sub Webhook Gateway", "GCP Cloud Pub/Sub", "Ingests 10s telemetry batches and high-priority emergency webhook payloads scaling to millions of devices.")

    Container(stream_workers, "Stream Processing Workers", "GCP Cloud Run (Go / Dart)", "Processes incoming telemetry streams, computes moving averages, and evaluates AASM apnea/hypopnea rules.")

    ContainerDb(bigtable, "Bio-Signal Time-Series Store", "GCP Cloud Bigtable", "Stores compressed, encrypted high-frequency bio-signal streams (AES-256).")

    ContainerDb(firestore, "Application Database", "Firebase Cloud Firestore", "Stores user profiles, health baselines, device bindings, sleep metrics, and alert queues (AES-256).")

    Container(command_portal, "Emergency Center Web Portal", "React / Next.js Web App", "Real-time WebSocket dashboard displaying unacknowledged apnea stops, patient GPS, and caregiver contact info.")

    Container(clinic_portal, "Clinic & Physician Portal", "React / Next.js Web App", "Web dashboard rendering morning sleep scores, AHI trends, and PDF graph exports.")

    Rel(hardware, mobile_app, "Streams Raw Telemetry Packets (100ms)", "BLE / AES-128")
    Rel(patient, mobile_app, "Interacts via Touch UI & Passkey Biometrics")
    Rel(mobile_app, firebase_auth, "Authenticates Session & WebAuthn Credentials", "HTTPS / TLS 1.3")
    Rel(mobile_app, pubsub, "Posts Telemetry Webhook Batches & Emergency Payloads", "HTTPS / TLS 1.3")
    Rel(pubsub, stream_workers, "Pushes Ingested Webhook Stream Messages", "gRPC / Push")
    Rel(stream_workers, bigtable, "Writes Compressed Bio-Signal Time Series", "gRPC")
    Rel(stream_workers, firestore, "Updates Sleep Session Metrics & Alert Queues", "gRPC")
    Rel(firestore, command_portal, "Pushes High-Priority Unacknowledged Alerts", "WSS / WebSockets")
    Rel(firestore, clinic_portal, "Syncs Morning Sleep Reports & AHI Graphs", "HTTPS / REST")
    Rel(dispatcher, command_portal, "Manages Real-Time Emergency Escalations")
    Rel(doctor, clinic_portal, "Reviews Patient AHI Trends & Sleep Summaries")
```

---

## 2. BPMN 2.0 Business Process Model

The business process maps the end-to-end operational lifecycle from bedtime setup to morning doctor report delivery across 5 distinct phases.

```mermaid
sequenceDiagram
    autonumber
    actor Patient as 👤 Patient at Home
    participant Mobile as 📱 Mobile App (Flutter)
    participant Cloud as ☁️ GCP / Firebase Cloud Pipeline
    participant Command as 🏢 Emergency Command Center
    actor Doctor as 🩺 Clinic / Physician

    Note over Patient, Mobile: Phase 1: Onboarding, Passkey Auth & 2-Stage Calibration
    Patient->>Mobile: Opens App & Authenticates via Passkey (FIDO2)
    Mobile->>Cloud: Authenticates Session via Firebase Auth
    Patient->>Mobile: Executes Stage 1 (Idle Noise) & Stage 2 (Active Breath) Calibration
    Mobile->>Cloud: Webhook: Register Session & Device Baseline (POST /api/v1/sessions/start)

    Note over Patient, Mobile: Phase 2: Overnight Sleep Monitoring & Continuous Telemetry
    loop Every 10 Seconds
        Mobile->>Cloud: Telemetry Webhook: Batch Respiratory Stream & Heartbeat (GCP Pub/Sub)
        Cloud->>Cloud: Stream Processor evaluates AASM Apnea/Hypopnea thresholds
    end

    Note over Patient, Command: Phase 3: Nocturnal Apnea Event & Tier-1 Local Alarm
    Mobile->>Mobile: Detects Airflow Stop >10s -> Triggers Tier-1 Escalating Alarm (<200ms)
    Mobile->>Mobile: Spawns 30-Second Cancellation Token Timer
    
    alt Option A: Patient Taps "I'm Safe" (within 30s)
        Patient->>Mobile: Taps "I'm Safe" Button
        Mobile->>Cloud: Webhook: Cancel Emergency Dispatch Payload
        Cloud->>Cloud: Logs "Patient Safe & Awake" (No Emergency Dispatch)
    else Option B: Unacknowledged (>30s Timeout)
        Mobile->>Cloud: High-Priority Emergency Webhook: Apnea Alert Breach
        Cloud->>Command: Real-Time SSE/WSS Broadcast to Emergency Dashboard (<1.5s)
        
        rect rgb(255, 230, 230)
            Note over Command, Doctor: Phase 4: Emergency Center & Clinic Escalation
            Command->>Command: Dispatcher verifies Alert & Location Metadata
            Command->>Patient: Automated High-Priority Voice Call & SMS Alert to Caregiver
            Command->>Doctor: Dispatches Clinical Notification Payload to Attending Physician
            Command->>Command: Optional EMS / 911 Dispatch if Unresponsive
        end
    end

    Note over Patient, Doctor: Phase 5: Morning Analytics & Doctor Report Export
    Patient->>Mobile: Taps "End Sleep Session"
    Mobile->>Cloud: Webhook: Close Session & Compute Final AHI
    Cloud-->>Doctor: Syncs Morning Sleep Summary & Respiration Graph to Clinic Portal
```

---

## 3. BPMN-Derived High-Level Conceptual Data Model

To guarantee that every data requirement generated throughout the BPMN process workflow is fulfilled, the conceptual data model maps directly to each process phase:

```mermaid
erDiagram
    PATIENT_USER ||--o| HEALTH_BASELINE : "Phase_1_Onboarding"
    PATIENT_USER ||--o{ DEVICE_BINDING : "Phase_1_Device_Pairing"
    PATIENT_USER ||--o{ SLEEP_SESSION : "Phase_2_Overnight_Logging"
    SLEEP_SESSION ||--o{ TELEMETRY_STREAM : "Phase_2_Continuous_Webhook"
    SLEEP_SESSION ||--o{ APNEA_EVENT : "Phase_3_Apnea_Detection"
    SLEEP_SESSION ||--o{ EMERGENCY_ALERT_QUEUE : "Phase_3_Tier1_and_Tier2_Trigger"
    EMERGENCY_ALERT_QUEUE ||--o| CARE_DISPATCH_RECORD : "Phase_4_Emergency_Center_Escalation"
    PATIENT_USER ||--o| CLINIC_DOCTOR_ASSIGNMENT : "Phase_4_and_5_Doctor_Sync"
    PATIENT_USER ||--o{ PHI_AUDIT_LOG : "All_Phases_HIPAA_Audit"
```

---

### 3.1 Traceability Matrix: BPMN Process Data Requirements $\rightarrow$ Conceptual Entities

| BPMN Process Phase | Data Produced / Transformed in Workflow | Derived Conceptual Entity | Key Data Attributes | HIPAA Safeguard Level |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1: Onboarding & Calibration** | Passkey FIDO2 token, age, weight, height, computed BMI, $N_{\text{idle}}$ noise floor, $V_{pp}$ breath baseline, BLE MAC address. | `PATIENT_USER`, `HEALTH_BASELINE`, `DEVICE_BINDING` | `user_id`, `passkey_credential_id`, `age`, `weight_kg`, `height_cm`, `computed_bmi`, `idle_noise_floor`, `device_hardware_id`, `ble_mac`. | **Level 1 (PHI)** — AES-256 Encryption at Rest. |
| **Phase 2: Overnight Telemetry** | 100ms raw airflow samples, 10s webhook stream batch, sequence number, heartbeats, battery level. | `SLEEP_SESSION`, `TELEMETRY_STREAM` | `session_id`, `user_id`, `start_time`, `sequence_num`, `net_airflow_samples`, `compressed_bio_signals`, `battery_pct`. | **Level 1 (PHI)** — Compressed AES-256 Time-Series Blob. |
| **Phase 3: Apnea & Tier-1 Alarm** | Airflow stop timestamp, apnea duration (>10s), peak-to-trough breach margin, 30s cancellation token, "I'm Safe" tap timestamp. | `APNEA_EVENT`, `EMERGENCY_ALERT_QUEUE` | `event_id`, `session_id`, `triggered_at`, `apnea_duration_seconds`, `patient_acknowledged`, `cancellation_token_id`. | **Level 1 (PHI)** — Real-Time Alert Event Queue. |
| **Phase 4: Emergency Center & Caregiver** | GPS coordinates, address, emergency contact phone, dispatcher action log, SMS/Voice call dispatch timestamp, EMS status. | `CARE_DISPATCH_RECORD`, `CLINIC_DOCTOR_ASSIGNMENT` | `dispatch_id`, `alert_id`, `dispatcher_id`, `caregiver_phone`, `gps_lat_long`, `ems_dispatched`, `doctor_npi`. | **Level 1 (PHI)** — Role-Based Access Control (RBAC). |
| **Phase 5: Morning Analytics & Doctor** | Session end time, total sleep duration, final AHI score, total apnea stops, quality score (0–100), doctor share payload. | `SLEEP_SESSION`, `CLINIC_DOCTOR_ASSIGNMENT` | `end_time`, `total_duration_hours`, `ahi_score`, `quality_score`, `doctor_share_token_id`. | **Level 1 (PHI)** — HL7 FHIR Export Stream. |
| **All Phases** | User ID, action performed, accessed table/entity, IP address, timestamp. | `PHI_AUDIT_LOG` | `audit_id`, `user_id`, `action_type`, `accessed_entity`, `ip_address`, `timestamp`. | **Level 2 (Audit)** — Immutable Write-Once Log. |

---

## 4. Architectural Summary

* **C4 Architecture Model:** Fully articulates C4 Level 1 (System Context) and C4 Level 2 (Container Diagram) showing Flutter App, BLE Hardware, Firebase Auth, GCP Pub/Sub, Cloud Run, Bigtable, Firestore, Emergency Center Web Portals, and Clinic Portals.
* **BPMN 2.0 Process Model:** Complete 5-phase operational workflow linking Patient $\rightarrow$ Mobile App $\rightarrow$ GCP Cloud $\rightarrow$ 24/7 Command Center $\rightarrow$ Doctor.
* **Conceptual Data Model:** 100% traceable to every data requirement generated across the BPMN process workflow, fully categorized under HIPAA Level 1 (PHI) and Level 2 (PII) safeguards.
