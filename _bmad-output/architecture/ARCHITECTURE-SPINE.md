---
title: Technical Architecture Spine — Sleep Apnea Detection App
status: final
version: 1.3.0
created: 2026-08-31
updated: 2026-08-31
author: Winston (System Architect)
---

# 🏛️ Technical Architecture Spine: Sleep Apnea Detection App

> **Architecture Paradigm:** Reactive BLoC + Worker Isolate Stream Pipeline + Atomic UI Design System  
> **Target Scope:** Cross-Platform Flutter Mobile Application & BLE Bio-Signal Telemetry Gateway  

---

## 1. Core Architectural Paradigm & Invariants

```mermaid
graph TD
    subgraph Layer0 ["🔐 Passkey Auth & HIPAA Security Layer (45 CFR § 164.312)"]
        Passkey[Passkey FIDO2 / WebAuthn Engine] -->|Secure Enclave Token| AuthBloc[Auth & Profile BLoC]
        AuthBloc -->|Auto Lock 5min Inactivity| SessionGuard[Session Timeout Guard]
        AuthBloc -->|Health Profile: Age, Weight, Height, BMI| ProfileRepo[Health Profile Repository]
        ProfileRepo -->|AES-256 SQLCipher Encrypted Storage| LocalDB[(Local Encrypted Database)]
    end

    subgraph Layer1 ["📟 Hardware Interface & Device Binding Layer"]
        BLE_Dev[Small Breathing Device] -->|GATT Stream 100ms (AES-128 Transit)| BLE_Plugin[flutter_reactive_ble Plugin]
        BLE_Plugin -->|BLE Pair Success| DeviceBinding[Device Binding Repository]
        DeviceBinding -->|TLS 1.3 Cert Pinned POST| CloudGateway[Cloud Device Binding Gateway]
    end

    subgraph Layer2 ["⚡ Background Isolate Engine (Non-UI Thread)"]
        BLE_Plugin -->|Raw Telemetry Stream| RingBuf[1-Hour Local RAM Circular Buffer]
        RingBuf -->|Stage 1 Subtraction V_raw - N_idle| Filter[Bandpass Filter 0.1Hz - 0.5Hz]
        Filter -->|Stage 2 Net Airflow V_net| FFT[FFT Spectral Engine & BPM Peak Detector]
        FFT -->|Net Signal < Apnea Threshold| Evaluator[10s Apnea Evaluator]
    end

    subgraph Layer3 ["📱 Application State & Alert Controller (BLoC Layer)"]
        Evaluator -->|Apnea Breached >10s| AlertManager[Emergency Alert Manager]
        AlertManager -->|Trigger Tier-1 Audio/Haptics <200ms| LocalAlert[Primary Mobile Alarm & Haptics]
        AlertManager -->|Start 30s Token Timer| TokenTimer[Cancellation Token Timer]
        
        TokenTimer -->|Option A: Tap I'm Safe| CancelCloud[Cancel Pending Dispatch & Log Safe]
        TokenTimer -->|Option B: Timeout >30s| CloudEmergency[Send Tier-2 Emergency Payload <1.5s]
    end

    subgraph Layer4 ["🎨 UI & Rendering Layer (OLED 0-FPS Throttled)"]
        Filter -->|Screen Active: 60 FPS Spline| ChartWidget[Skia Live Waveform Canvas]
        Filter -->|Screen Locked: 0 FPS Throttled| DisplaySaver[OLED Pure Black Power Saver]
        ProfileRepo -->|Export HIPAA Encrypted Payload| DoctorShareUI[Doctor Profile Sharing Module]
    end
```

---

## 2. Architectural Decisions (ADs) & Structural Rules

### AD-1: BLE Telemetry Gateway & Connection Management
* **Binds:** `lib/core/ble/ble_manager.dart`
* **Rule:** Singleton `BleManager` handles scanning, MTU size negotiation (247 bytes), exponential auto-reconnect (<3.0s), and a 1-hour circular RAM ring buffer.

### AD-2: Two-Stage Pre-Sleep Calibration & Baseline Engine
* **Binds:** `lib/core/signal/calibration_engine.dart`
* **Rule:** Stage 1 ($N_{\text{idle}}$ subtraction) + Stage 2 ($V_{pp}$ 10% peak-to-trough threshold binding). Wear verification guardrail blocks start if $\Delta V < \text{Threshold}_{\min}$.

### AD-3: Signal Offloading & Background Worker Isolates
* **Binds:** `lib/core/signal/signal_processor_isolate.dart`
* **Rule:** Bandpass filtering, $N_{\text{idle}}$ subtraction, and FFT peak calculations execute in background Dart Isolates (`compute()`).

### AD-4: Emergency Response & Cancellation Token Pattern
* **Binds:** `lib/core/services/emergency_alert_manager.dart`
* **Rule:** Instant local mobile alarms (<200ms) + 30s Cancellation Token timer. Tapping "I'm Safe" cancels cloud dispatch; timeout fires Tier-2 payload (<1.5s).

### AD-5: Ultra-Low Power Architecture & 0-FPS Display Throttling
* **Binds:** `lib/ui/organisms/live_waveform_chart.dart`, `lib/main.dart`
* **Rule:** 0-FPS display throttling when screen locked, OLED pure black (`#000000`) theme, Android Foreground Service / iOS Bluetooth Central (<8% battery drain over 8h).

### AD-6: Full HIPAA Security Rule Architecture & PHI Safeguards (45 CFR § 164.312)
* **Binds:** `lib/core/security/crypto_util.dart`, `lib/core/network/api_client.dart`, `lib/data/datasources/encrypted_db_datasource.dart`
* **Prevents:** HIPAA non-compliance penalties, unencrypted PHI storage, MITM attacks, and unauthorized health record tampering.
* **Rule:**
  1. **Encryption at Rest (45 CFR § 164.312(e)):** All local mobile databases storing patient profiles or telemetry logs shall enforce **AES-256 encryption** (via Hive Encrypted Box / SQLCipher) with 256-bit master keys stored in iOS Keychain / Android Keystore. Plain-text health data caching is strictly forbidden.
  2. **Encryption in Transit & Certificate Pinning (45 CFR § 164.312(e)):** All BLE telemetry packets shall use AES-128 link encryption. All mobile-to-cloud HTTPS/WSS endpoints shall mandate **TLS 1.3** with SSL Certificate Pinning.
  3. **Automatic Session Timeout (45 CFR § 164.312(a)):** The app shall lock active views and require Passkey re-authentication after 5 minutes of inactivity.
  4. **Tamper-Evident Audit Logging (45 CFR § 164.312(b)):** Every PHI creation, modification, doctor export, or emergency alert event shall record a cryptographic, tamper-evident entry in `phi_audit_logs`.
  5. **Data Destruction (45 CFR § 164.312(c)):** Implements one-tap local PHI cache wipe upon user account logout or remote unpair command.

### AD-7: Hardware Air Freight & International Customs Compliance
* **Binds:** `hardware/specifications/customs_compliance_manifest.json`
* **Rule:** UN 38.3 & IATA PI 967 Section II battery capacity cap **< 2.7 Wh (<700 mAh)**, IEC 62133-2, ISO 10993 skin biocompatibility, and pre-certified 2.4 GHz BLE spectrum.

### AD-8: Passkey FIDO2/WebAuthn Authentication Architecture
* **Binds:** `lib/core/auth/passkey_authenticator.dart`, `lib/core/auth/secure_enclave_storage.dart`
* **Rule:** Passwordless FIDO2/WebAuthn authentication using native OS biometrics (Face ID, Touch ID, Android BiometricPrompt). Private keys stored inside hardware OS Secure Enclave.

### AD-9: Cloud Device Binding API & Doctor Sharing Framework Architecture
* **Binds:** `lib/data/repositories/device_binding_repository.dart`, `lib/data/models/health_profile.dart`
* **Rule:** Device pairing dispatches POST `/api/v1/devices/bind` JSON payload. Interface `DeviceBindingApiInterface` provides local `MockDeviceBindingApi` stub. Doctor export formats JSON under HL7 FHIR standards.

---

## 3. Technology Stack & Starter Dependency Invariants

```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  # Core BLE & Reactive Streams
  flutter_reactive_ble: ^5.0.2
  rxdart: ^0.27.7
  # State Management
  flutter_bloc: ^8.1.3
  # Passkey Auth & Secure Enclave
  passkeys: ^1.2.0
  flutter_secure_storage: ^9.0.0
  sqflite_sqlcipher: ^3.0.0
  # UI & GPU Chart Rendering
  fl_chart: ^0.68.0
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.6
  # Local Encrypted Storage & Ring Buffer
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  # Networking & Emergency Alerts
  dio: ^5.4.3+1
  web_socket_channel: ^3.0.0
  flutter_local_notifications: ^17.1.2
  vibration: ^2.0.1
```

---

## 4. Deferred Technical Decisions

1. **Cloud Backend Infrastructure:** AWS / GCP HIPAA-compliant BAA infrastructure.
2. **SMS Gateway Provider:** Twilio BAA vs. AWS SNS for Tier-2 Caregiver SMS Dispatch.
3. **Doctor PDF / HL7 FHIR Cloud Integration:** Direct EHR API synchronization.
