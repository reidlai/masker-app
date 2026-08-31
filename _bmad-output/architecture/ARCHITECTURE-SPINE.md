---
title: Enterprise Business, Data & Cloud Architecture Specification — Sleep Apnea Detection App
status: final
version: 3.0.0
created: 2026-08-31
updated: 2026-08-31
author: Winston (System Architect) & Mary (Business Analyst)
---

# 🏛️ Enterprise Business, Data & Cloud Architecture Specification
## Sleep Apnea Detection App & Emergency Command Platform

> **Target Scope:** Global Enterprise Platform Scaling to Millions of Breathing Devices  
> **Cloud Provider & Infrastructure:** Google Cloud Platform (GCP) & Firebase Suite  
> **Integrations:** Real-Time Telemetry Webhooks, Emergency Response Command Centers, and Clinical Portals  

---

## 1. Business Architecture & BPMN Process Models

### 1.1 End-to-End BPMN 2.0 Business Process Workflow

The business process connects four primary participant pools: **Patient at Home**, **Mobile App Engine**, **GCP/Firebase Ingestion Engine**, and **Emergency Command Center & Clinic Specialists**.

```mermaid
sequenceDiagram
    autonumber
    actor Patient as 👤 Patient at Home
    participant Mobile as 📱 Mobile App (Flutter)
    participant Cloud as ☁️ GCP / Firebase Telemetry Pipeline
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

### 1.2 Business Capabilities Map (BC-1 to BC-7)

| Capability ID | Business Capability Name | Description | Key Business Service |
| :--- | :--- | :--- | :--- |
| **BC-1** | **Patient Identity Governance** | Manages passwordless Passkey (FIDO2) authentication and biometric access. | `AuthenticatePatientService` |
| **BC-2** | **Pre-Sleep Calibration** | Executes 2-stage noise floor ($N_{\text{idle}}$) & active breath peak ($V_{pp}$) calibration. | `CalibrateBaselineService` |
| **BC-3** | **Real-Time Telemetry Streaming** | Logs 100ms respiratory stream data and syncs webhooks to GCP Pub/Sub. | `StreamTelemetryService` |
| **BC-4** | **Two-Tier Emergency Response** | Controls Tier-1 mobile alarms (<200ms) and 30s "I'm Safe" cancellation tokens. | `ManageEmergencyAlertService` |
| **BC-5** | **Emergency Center Command Gateway** | Broadcasts high-priority alerts to 24/7 Monitoring Centers and Caregiver SMS. | `DispatchEmergencyCenterService` |
| **BC-6** | **Clinic & Doctor Integration** | Distributes sleep summaries, AHI trends, and health records to attending physicians. | `SyncDoctorClinicService` |
| **BC-7** | **Hardware Fleet Management** | Binds device hardware IDs to patient accounts and monitors air freight compliance. | `BindDeviceHardwareService` |

---

## 2. Process-Aligned Data Architecture

### 2.1 Conceptual Data Model (BPMN Aligned)

```mermaid
erDiagram
    PATIENT_USER ||--o| HEALTH_PROFILE : "has"
    PATIENT_USER ||--o{ DEVICE_BINDING : "owns"
    PATIENT_USER ||--o{ SLEEP_SESSION : "records"
    SLEEP_SESSION ||--o{ TELEMETRY_WEBHOOK_EVENT : "streams"
    SLEEP_SESSION ||--o{ APNEA_EVENT : "contains"
    SLEEP_SESSION ||--o{ EMERGENCY_ALERT_QUEUE : "triggers"
    EMERGENCY_ALERT_QUEUE ||--o| COMMAND_CENTER_DISPATCH : "escalates_to"
    PATIENT_USER ||--o| CLINIC_PROVIDER_PROFILE : "assigned_to"
    PATIENT_USER ||--o{ PHI_AUDIT_LOG : "generates"
```

---

### 2.2 Process Data Classification & HIPAA Governance Matrix

| Entity & Attribute | Classification Level | HIPAA Category | Storage & Transport Encryption | Access Control Policy |
| :--- | :--- | :--- | :--- | :--- |
| `user_profile.full_name` | **Level 1 — Direct PHI** | Identity | AES-256 (Rest) / TLS 1.3 (Transit) | Firestore Security Rules (`auth.uid == userId`) |
| `user_profile.phone` | **Level 1 — Direct PHI** | Endpoint | AES-256 (Rest) / TLS 1.3 (Transit) | Firestore Security Rules |
| `health_profile.*` | **Level 1 — Direct PHI** | Health Baseline | AES-256 Column Encryption | Firestore Rules + Doctor Share Token |
| `telemetry_webhook_event.payload` | **Level 1 — Direct PHI** | Bio-Signals | Compressed AES-256 Encrypted Blob | GCP Pub/Sub IAM + KMS Key |
| `emergency_alert_queue.location` | **Level 1 — Direct PHI** | GPS / Address | AES-256 Encryption | Emergency Center Role-Based Access (RBAC) |
| `clinic_provider.doctor_npi` | **Level 2 — PII** | Provider ID | Standard Database Column | Clinic Dashboard IAM |
| `command_center_dispatch.*` | **Level 2 — Operational** | Dispatch Audit | Immutable Write-Once Log | Compliance Administrator Only |

---

### 2.3 Application Data Model (Scale & Webhook Entities)

```mermaid
classDiagram
    class TelemetryWebhookPayload {
        +String session_id
        +String user_id
        +String device_hardware_id
        +int sequence_number
        +double current_net_airflow
        +int current_bpm
        +byte[] raw_samples_compressed
        +DateTime timestamp
    }

    class EmergencyAlertQueueEntity {
        +String alert_id
        +String session_id
        +String user_id
        +DateTime triggered_at
        +int duration_seconds
        +String alert_priority
        +boolean patient_acknowledged
        +String status
    }

    class CommandCenterDispatchEntity {
        +String dispatch_id
        +String alert_id
        +String dispatcher_id
        +String assigned_clinic_id
        +DateTime dispatched_at
        +String action_taken
    }

    class ClinicProviderEntity {
        +String clinic_id
        +String doctor_name
        +String doctor_npi_number
        +String clinic_phone
        +List~String~ assigned_patient_ids
    }

    TelemetryWebhookPayload "1" -- "1" EmergencyAlertQueueEntity
    EmergencyAlertQueueEntity "1" -- "1" CommandCenterDispatchEntity
    CommandCenterDispatchEntity "1" -- "1" ClinicProviderEntity
```

---

## 3. Application & GCP/Firebase Cloud Architecture (Scale to Millions)

To support **hundreds of thousands or millions of concurrent devices** streaming telemetry continuously overnight, the cloud architecture utilizes a highly scalable, serverless Google Cloud Platform (GCP) and Firebase infrastructure:

```mermaid
graph TD
    subgraph MobileApp ["📱 Mobile Application Layer (Flutter)"]
        BLE[Small Breathing Device] -->|GATT Stream 100ms| AppEngine[Flutter App Engine]
        AppEngine -->|1. Passkey Auth| FirebaseAuth[Firebase Auth & WebAuthn]
        AppEngine -->|2. 10s Telemetry Webhook| CloudPubSub[GCP Cloud Pub/Sub Topic: respiratory-telemetry-stream]
        AppEngine -->|3. High-Priority Alert Webhook| AlertPubSub[GCP Cloud Pub/Sub Topic: emergency-alerts-high-priority]
    end

    subgraph GCP_Core ["☁️ GCP Serverless Stream Processing Layer"]
        CloudPubSub -->|Push Subscription| CloudRunTelemetry[GCP Cloud Run Worker Pool]
        CloudRunTelemetry -->|Batch Write Compressed Stream| Bigtable[(GCP Cloud Bigtable / Firebase Firestore)]
        
        AlertPubSub -->|Immediate Event Push| CloudRunEmergency[GCP Cloud Run Emergency Dispatch Engine]
        CloudRunEmergency -->|Store Alert Record| FirestoreAlerts[(Firebase Cloud Firestore: emergency_alerts)]
        CloudRunEmergency -->|Trigger Webhook| Eventarc[GCP Eventarc / Cloud Tasks]
    end

    subgraph Alert_Dispatch ["🏢 Emergency Center & Clinic Distribution Engine"]
        Eventarc -->|Sub-1.5s WSS / SSE Broadcast| EmergencyDashboard[24/7 Emergency Command Center Web Portal]
        Eventarc -->|Twilio / AWS SNS API| CaregiverPhone[Caregiver SMS & Voice Phone Call]
        EmergencyDashboard -->|Direct EHR / HL7 FHIR Sync| ClinicPortal[Clinic & Physician Web Portal]
    end
```

---

### 3.1 Webhook & Telemetry Streaming Invariants

1. **High-Throughput Webhook Ingestion (GCP Cloud Pub/Sub):**
   - Telemetry batches are sent every 10 seconds per active app session via HTTPS POST webhooks (`POST /api/v1/telemetry/stream`) into GCP Cloud Pub/Sub topic `respiratory-telemetry-stream`.
   - Pub/Sub handles auto-scaling up to **10 million requests per second** with sub-100ms ingestion latency.
2. **Real-Time Database Tier (GCP Cloud Bigtable & Firebase Firestore):**
   - High-frequency bio-signal time series are stored in **GCP Cloud Bigtable** (optimized for massive time-series analytics).
   - Sleep session metrics, patient profiles, and emergency alert queues are stored in **Firebase Cloud Firestore** with real-time WebSocket listeners.
3. **Emergency Command Center Dashboard Integration:**
   - 24/7 Emergency Centers connect to the platform via WebSockets (`wss://emergency.sleepapnea.health/stream`).
   - Unacknowledged 30-second apnea alarms automatically pop up on command center maps with patient GPS coordinates, health profile, and emergency contacts.
4. **Clinic & Doctor Notification Pipeline:**
   - When an emergency dispatch occurs or a morning sleep report is generated, GCP Eventarc triggers a webhook notification to assigned clinic portals and physician email/SMS endpoints.

---

## 4. Summary of Architecture Invariants

* **Business Architecture:** Complete BPMN 2.0 5-phase workflow linking Patient $\rightarrow$ App $\rightarrow$ GCP $\rightarrow$ Emergency Command Center $\rightarrow$ Doctor.
* **Data Architecture:** Process-aligned data entities with explicit HIPAA Level 1 (PHI) vs. Level 2 (PII) data classification.
* **Cloud Architecture:** Fully decoupled, serverless **GCP & Firebase engine** built to scale to millions of devices using Cloud Pub/Sub, Cloud Run, Firestore, Bigtable, and real-time command center webhooks.
