---
title: Enterprise Architecture Specification — BPMN.js XML & PlantUML Data Architecture
status: final
version: 10.0.0
created: 2026-08-31
updated: 2026-08-31
author: Winston (System Architect) & Mary (Business Analyst)
---

# 🏛️ Enterprise Architecture Specification
## Sleep Apnea Detection App & Emergency Command Platform

> **Diagramming Standard:** Standard **BPMN 2.0 XML (BPMN.js / Camunda compatible)** for Section 2 Process Modeling + **PlantUML** for C4 Context, C4 Container & Conceptual Data Models.  
> **Target Scope:** Global Platform Scaling to Millions of Concurrent Devices  

---

## 1. 📐 C4 Architecture Model (PlantUML)

### 1.1 C4 Level 1: System Context Diagram

```plantuml
@startuml C4_Level1_System_Context
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

LAYOUT_WITH_LEGEND()

title C4 Level 1: System Context Diagram — Sleep Apnea Detection Platform

Person(patient, "Patient / At-Home User", "Wears small breathing device at home during sleep; authenticates via Passkey.")
Person(caregiver, "Caregiver / Family Member", "Receives Tier-2 emergency SMS/Voice calls when patient apnea alarm is unacknowledged.")
Person(dispatcher, "Emergency Center Dispatcher", "Monitors 24/7 real-time emergency dashboard for unacknowledged 30s apnea alerts.")
Person(doctor, "Attending Physician / Clinic", "Reviews morning AHI scores, respiration wave graphs, and clinical sleep health summaries.")

System(system, "Sleep Apnea Detection System", "Monitors nocturnal breathing airflow, executes 2-stage calibration, triggers Tier-1 local alarms, and dispatches Tier-2 cloud emergency alerts.")

System_Ext(telecom, "External Telecom Gateway", "Twilio / AWS SNS SMS and automated voice call dispatch platform.")
System_Ext(ehr, "External EHR / EMR System", "HL7 FHIR compliant Electronic Health Record systems.")

Rel(patient, system, "Interfaces via BLE & Mobile App (Passkey, Calibration, 'I'm Safe' Tap)", "BLE / HTTPS")
Rel(system, caregiver, "Sends Tier-2 Emergency SMS & Voice Alerts", "HTTPS / Telephony")
Rel(system, dispatcher, "Broadcasts Sub-1.5s High-Priority Apnea Alarms", "WSS / WebSockets")
Rel(system, doctor, "Delivers Morning Sleep Summaries & Clinical Reports", "HTTPS / HL7 FHIR")
Rel(system, telecom, "Triggers Automated SMS & Voice Payloads", "REST API")
Rel(system, ehr, "Synchronizes Health Records & AHI Trends", "HL7 FHIR API")

@enduml
```

---

### 1.2 C4 Level 2: Container Diagram

```plantuml
@startuml C4_Level2_Container_Diagram
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

LAYOUT_WITH_LEGEND()

title C4 Level 2: Container Diagram — Sleep Apnea Detection System

Person(patient, "Patient", "At-home user wearing breathing device.")
Person(dispatcher, "Emergency Dispatcher", "24/7 monitoring operator.")
Person(doctor, "Physician / Specialist", "Attending sleep clinician.")

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

@enduml
```

---

## 2. 🔄 BPMN 2.0 Business Process Model (BPMN.js XML Standard)

The standard BPMN 2.0 process specification below is written in **BPMN 2.0 XML schema** for rendering via **BPMN.js** (Camunda / bpmn.io toolkit):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
                  id="Definitions_SleepApneaProcess"
                  targetNamespace="http://bpmn.io/schema/bpmn"
                  exporter="BPMN.js Model Platform"
                  exporterVersion="11.0.0">

  <!-- Collaboration: 4 Organizational Pools -->
  <bpmn:collaboration id="Collaboration_SleepApnea">
    <bpmn:participant id="Participant_Patient" name="Patient at Home" processRef="Process_Patient" />
    <bpmn:participant id="Participant_MobileApp" name="Mobile Application Engine" processRef="Process_MobileApp" />
    <bpmn:participant id="Participant_CloudEngine" name="GCP / Firebase Cloud Engine" processRef="Process_CloudEngine" />
    <bpmn:participant id="Participant_EmergencyCenter" name="24/7 Emergency Command Center &amp; Clinic" processRef="Process_EmergencyCenter" />
    
    <!-- Inter-Pool Message Flows -->
    <bpmn:messageFlow id="Flow_BLE_Stream" sourceRef="Participant_Patient" targetRef="Participant_MobileApp" name="100ms BLE Telemetry Stream" />
    <bpmn:messageFlow id="Flow_Webhook_Stream" sourceRef="Participant_MobileApp" targetRef="Participant_CloudEngine" name="10s Batch Telemetry Webhook" />
    <bpmn:messageFlow id="Flow_Emergency_Dispatch" sourceRef="Participant_MobileApp" targetRef="Participant_CloudEngine" name="High-Priority Emergency Payload" />
    <bpmn:messageFlow id="Flow_Command_WSS" sourceRef="Participant_CloudEngine" targetRef="Participant_EmergencyCenter" name="Sub-1.5s WSS Dashboard Alert" />
  </bpmn:collaboration>

  <!-- Process 1: Patient at Home -->
  <bpmn:process id="Process_Patient" isExecutable="true">
    <bpmn:startEvent id="Start_Bedtime" name="Start: Bedtime Onboarding">
      <bpmn:outgoing>Flow_P1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:userTask id="Task_PasskeyAuth" name="1.1 Authenticate via Passkey (FIDO2)">
      <bpmn:incoming>Flow_P1</bpmn:incoming>
      <bpmn:outgoing>Flow_P2</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:userTask id="Task_Stage1Cal" name="1.2 Execute Stage 1 Idle Noise Calibration">
      <bpmn:incoming>Flow_P2</bpmn:incoming>
      <bpmn:outgoing>Flow_P3</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:userTask id="Task_Stage2Cal" name="1.3 Execute Stage 2 Active Breath Calibration">
      <bpmn:incoming>Flow_P3</bpmn:incoming>
      <bpmn:outgoing>Flow_P4</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:userTask id="Task_SleepMonitoring" name="1.4 Sleep with Device Attached">
      <bpmn:incoming>Flow_P4</bpmn:incoming>
      <bpmn:outgoing>Flow_P5</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:exclusiveGateway id="Gateway_Tier1Alarm" name="Tier-1 Mobile Alarm Triggered?">
      <bpmn:incoming>Flow_P5</bpmn:incoming>
      <bpmn:outgoing>Flow_AlarmNo</bpmn:outgoing>
      <bpmn:outgoing>Flow_AlarmYes</bpmn:outgoing>
    </bpmn:exclusiveGateway>
    <bpmn:sequenceFlow id="Flow_AlarmNo" sourceRef="Gateway_Tier1Alarm" targetRef="Task_SleepMonitoring" />
    <bpmn:exclusiveGateway id="Gateway_PatientAwake" name="Patient Awake within 30s?">
      <bpmn:incoming>Flow_AlarmYes</bpmn:incoming>
      <bpmn:outgoing>Flow_AwakeYes</bpmn:outgoing>
      <bpmn:outgoing>Flow_AwakeNo</bpmn:outgoing>
    </bpmn:exclusiveGateway>
    <bpmn:userTask id="Task_TapSafe" name="1.5 Tap 'I'm Safe' Button">
      <bpmn:incoming>Flow_AwakeYes</bpmn:incoming>
      <bpmn:outgoing>Flow_P6</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:userTask id="Task_EndSession" name="1.6 Tap 'End Sleep Session'">
      <bpmn:incoming>Flow_P6</bpmn:incoming>
      <bpmn:outgoing>Flow_P7</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:endEvent id="End_SessionComplete" name="End: Session Complete">
      <bpmn:incoming>Flow_P7</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_P1" sourceRef="Start_Bedtime" targetRef="Task_PasskeyAuth" />
    <bpmn:sequenceFlow id="Flow_P2" sourceRef="Task_PasskeyAuth" targetRef="Task_Stage1Cal" />
    <bpmn:sequenceFlow id="Flow_P3" sourceRef="Task_Stage1Cal" targetRef="Task_Stage2Cal" />
    <bpmn:sequenceFlow id="Flow_P4" sourceRef="Task_Stage2Cal" targetRef="Task_SleepMonitoring" />
    <bpmn:sequenceFlow id="Flow_P5" sourceRef="Task_SleepMonitoring" targetRef="Gateway_Tier1Alarm" />
    <bpmn:sequenceFlow id="Flow_P6" sourceRef="Task_TapSafe" targetRef="Task_EndSession" />
    <bpmn:sequenceFlow id="Flow_P7" sourceRef="Task_EndSession" targetRef="End_SessionComplete" />
  </bpmn:process>

  <!-- Process 2: Mobile Application Engine -->
  <bpmn:process id="Process_MobileApp" isExecutable="true">
    <bpmn:serviceTask id="Task_RegisterSession" name="2.1 Register Session &amp; Baseline Payload" />
    <bpmn:serviceTask id="Task_StreamWebhooks" name="2.2 Stream 10s Respiratory Webhook Batches" />
    <bpmn:exclusiveGateway id="Gateway_AirflowBreach" name="Airflow Stop &gt; 10s?" />
    <bpmn:serviceTask id="Task_TriggerAlarm" name="2.3 Trigger Tier-1 Audio &amp; Haptics (&lt;200ms)" />
    <bpmn:serviceTask id="Task_SpawnTimer" name="2.4 Spawn 30s Cancellation Token Timer" />
    <bpmn:serviceTask id="Task_SendEmergencyWebhook" name="2.5 Transmit High-Priority Emergency Payload" />
  </bpmn:process>

  <!-- Process 3: GCP / Firebase Cloud Engine -->
  <bpmn:process id="Process_CloudEngine" isExecutable="true">
    <bpmn:serviceTask id="Task_PubSubIngest" name="3.1 GCP Pub/Sub Webhook Ingestion" />
    <bpmn:serviceTask id="Task_CloudRunWorker" name="3.2 Cloud Run Stream Processing Worker" />
    <bpmn:serviceTask id="Task_WriteBigtable" name="3.3 Write Bio-Signals to Bigtable &amp; Firestore" />
    <bpmn:serviceTask id="Task_QueueEmergency" name="3.4 Queue High-Priority Emergency Alert" />
    <bpmn:serviceTask id="Task_BroadcastCommand" name="3.5 Broadcast Sub-1.5s WSS to Command Center" />
  </bpmn:process>

  <!-- Process 4: Emergency Center & Clinic Endpoint -->
  <bpmn:process id="Process_EmergencyCenter" isExecutable="true">
    <bpmn:userTask id="Task_DashboardAlert" name="4.1 Command Center Dashboard Alert Pop-up" />
    <bpmn:userTask id="Task_VerifyGPS" name="4.2 Dispatcher Verifies Location &amp; Patient GPS" />
    <bpmn:serviceTask id="Task_CaregiverCall" name="4.3 Trigger Voice Call &amp; SMS to Caregiver" />
    <bpmn:serviceTask id="Task_DoctorSync" name="4.4 Push Notification Payload to Attending Physician" />
    <bpmn:exclusiveGateway id="Gateway_EMSDispatch" name="Caregiver / Patient Responds?" />
    <bpmn:serviceTask id="Task_DispatchEMS" name="4.5 Dispatch Local EMS / 911 Responders" />
    <bpmn:endEvent id="End_EventResolved" name="End: Emergency Resolved &amp; Documented" />
  </bpmn:process>

</bpmn:definitions>
```

---

## 3. 🗄️ PlantUML Conceptual Data Model (BPMN Aligned)

```plantuml
@startuml Conceptual_Data_Model_PlantUML
skinparam classAttributeIconSize 0
skinparam backgroundColor #F9F9F9
skinparam class {
    BackgroundColor White
    ArrowColor #2C3E50
    BorderColor #2C3E50
}

package "BPMN Phase 1: Onboarding & Calibration" {
    class PatientUser << (E,#41B883) Level 1 PHI >> {
        + String user_id {PK}
        + String passkey_credential_id
        + String encrypted_full_name
        + String encrypted_phone
        + DateTime registered_at
    }

    class HealthBaseline << (E,#41B883) Level 1 PHI >> {
        + String baseline_id {PK}
        + String user_id {FK}
        + int age
        + String gender
        + double weight_kg
        + double height_cm
        + double computed_bmi
        + double idle_noise_floor
    }

    class DeviceBinding << (E,#3498DB) Level 2 PII >> {
        + String binding_id {PK}
        + String user_id {FK}
        + String device_hardware_id
        + String ble_mac_address
        + String status
        + DateTime bound_at
    }
}

package "BPMN Phase 2 & 3: Telemetry & Apnea Detection" {
    class SleepSession << (E,#41B883) Level 1 PHI >> {
        + String session_id {PK}
        + String user_id {FK}
        + DateTime start_time
        + DateTime end_time
        + double ahi_score
        + int total_apnea_events
        + int quality_score
    }

    class TelemetryStream << (E,#41B883) Level 1 PHI >> {
        + String stream_id {PK}
        + String session_id {FK}
        + int sequence_number
        + byte[] compressed_bio_signals
        + int battery_pct
        + DateTime timestamp
    }

    class ApneaEvent << (E,#E74C3C) Level 1 PHI >> {
        + String event_id {PK}
        + String session_id {FK}
        + DateTime triggered_at
        + int apnea_duration_seconds
        + double threshold_breach_margin
    }

    class EmergencyAlertQueue << (E,#E74C3C) Level 1 PHI >> {
        + String alert_id {PK}
        + String session_id {FK}
        + String cancellation_token_id
        + boolean patient_acknowledged
        + String alert_priority
        + DateTime timeout_at
    }
}

package "BPMN Phase 4 & 5: Escalation & Doctor Sync" {
    class CareDispatchRecord << (E,#E74C3C) Level 1 PHI >> {
        + String dispatch_id {PK}
        + String alert_id {FK}
        + String dispatcher_id
        + String caregiver_phone
        + String gps_location
        + boolean ems_dispatched
        + DateTime dispatched_at
    }

    class ClinicDoctorAssignment << (E,#3498DB) Level 2 PII >> {
        + String assignment_id {PK}
        + String user_id {FK}
        + String clinic_id
        + String doctor_npi_number
        + String doctor_name
    }

    class PhiAuditLog << (E,#95A5A6) Audit Level 2 >> {
        + String audit_id {PK}
        + String user_id {FK}
        + String action_type
        + String accessed_entity
        + String ip_address
        + DateTime timestamp
    }
}

PatientUser "1" -- "1" HealthBaseline : possesses >
PatientUser "1" -- "*" DeviceBinding : owns >
PatientUser "1" -- "*" SleepSession : records >
SleepSession "1" -- "*" TelemetryStream : streams >
SleepSession "1" -- "*" ApneaEvent : flags >
SleepSession "1" -- "*" EmergencyAlertQueue : triggers >
EmergencyAlertQueue "1" -- "0..1" CareDispatchRecord : escalates >
PatientUser "1" -- "*" ClinicDoctorAssignment : assigned_to >
PatientUser "1" -- "*" PhiAuditLog : generates >

@enduml
```

---

### 3.1 Data Traceability Matrix: BPMN Process Data Requirements $\rightarrow$ PlantUML Entities

| BPMN Process Phase | Data Produced / Transformed in Workflow | Derived PlantUML Conceptual Entity | Key Data Attributes | HIPAA Safeguard Level |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1: Onboarding & Calibration** | Passkey FIDO2 token, age, weight, height, computed BMI, $N_{\text{idle}}$ noise floor, $V_{pp}$ breath baseline, BLE MAC address. | `PatientUser`, `HealthBaseline`, `DeviceBinding` | `user_id`, `passkey_credential_id`, `age`, `weight_kg`, `height_cm`, `computed_bmi`, `idle_noise_floor`, `device_hardware_id`. | **Level 1 (PHI)** — AES-256 Encryption at Rest. |
| **Phase 2: Overnight Telemetry** | 100ms raw airflow samples, 10s webhook stream batch, sequence number, heartbeats, battery level. | `SleepSession`, `TelemetryStream` | `session_id`, `user_id`, `start_time`, `sequence_number`, `compressed_bio_signals`, `battery_pct`. | **Level 1 (PHI)** — Compressed AES-256 Time-Series Blob. |
| **Phase 3: Apnea & Tier-1 Alarm** | Airflow stop timestamp, apnea duration (>10s), peak-to-trough breach margin, 30s cancellation token, "I'm Safe" tap timestamp. | `ApneaEvent`, `EmergencyAlertQueue` | `event_id`, `session_id`, `triggered_at`, `apnea_duration_seconds`, `patient_acknowledged`, `cancellation_token_id`. | **Level 1 (PHI)** — Real-Time Alert Event Queue. |
| **Phase 4: Emergency Center & Caregiver** | GPS coordinates, address, emergency contact phone, dispatcher action log, SMS/Voice call dispatch timestamp, EMS status. | `CareDispatchRecord`, `ClinicDoctorAssignment` | `dispatch_id`, `alert_id`, `dispatcher_id`, `caregiver_phone`, `gps_location`, `ems_dispatched`, `doctor_npi_number`. | **Level 1 (PHI)** — Role-Based Access Control (RBAC). |
| **Phase 5: Morning Analytics & Doctor** | Session end time, total sleep duration, final AHI score, total apnea stops, quality score (0–100), doctor share payload. | `SleepSession`, `ClinicDoctorAssignment` | `end_time`, `total_duration_hours`, `ahi_score`, `quality_score`, `doctor_npi_number`. | **Level 1 (PHI)** — HL7 FHIR Export Stream. |
| **All Phases** | User ID, action performed, accessed table/entity, IP address, timestamp. | `PhiAuditLog` | `audit_id`, `user_id`, `action_type`, `accessed_entity`, `ip_address`, `timestamp`. | **Level 2 (Audit)** — Immutable Write-Once Log. |

---

## 4. 🏁 Architectural Summary

* **Standard BPMN 2.0 XML (BPMN.js):** Section 2 is written in standard `<bpmn:definitions>` XML format, rendering natively with **BPMN.js** (Camunda / bpmn.io viewer).
* **PlantUML C4 & Conceptual Data Models:** Uses ```plantuml code blocks for C4 Level 1 System Context, C4 Level 2 Container, and Conceptual Data Architecture (`@startuml`).
* **100% Traceability:** Fully links business process requirements to data architecture entities under HIPAA Level 1 (PHI) vs. Level 2 (PII) security rules.
