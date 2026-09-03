# Sleep Apnea Detection App (D-BAND Integrated Platform) 🫁📱

Cross-platform mobile application (Flutter / Dart) for at-home nocturnal sleep apnea monitoring, real-time AASM breathing event detection, thermal BLE sensor calibration, and HIPAA-compliant Passkey authentication.

---

## 🚀 Product Background & Architecture Summary

The **D-BAND Integrated Platform** captures continuous 10Hz respiratory thermal deviation data ($\Delta T = T_{\text{exhale}} - T_{\text{inhale}}$) streamed over encrypted Bluetooth Low Energy (BLE 5.0+, AES-128 link security). The application processes thermal signals into volumetric airflow estimates ($V_{\text{volumetric}}$) to detect obstructive sleep apnea episodes ($\ge 90\%$ drop for $\ge 10$ seconds) in real time.

### Key Capabilities (MVP1 Active Scope)
- **Passwordless FIDO2 / WebAuthn Biometrics**: Native OS biometric login (Face ID, Touch ID, Android BiometricPrompt) enforcing HIPAA 45 CFR § 164.312(a) technical access controls.
- **Atomic Design System Hierarchy**: Strict separation of concerns across UI Atoms, Molecules, 13 Organisms, and Page Templates.
- **BLoC & RxDart Unidirectional Data Flow**: Reactive event stream management (`flutter_bloc: ^8.1.3`, `rxdart: ^0.27.7`) using `throttleTime` (300ms) and `switchMap` event transformers.
- **2-Stage Thermal Sensor Calibration**: Stage 1 room noise floor ($N_{\text{idle}}$) and Stage 2 active breathing baseline ($V_{pp}$) calibration setting dynamic zero-airflow thresholds ($0.10 \times V_{pp}$).
- **Tier-1 Local Emergency Siren & Escalating Alarm**: Sub-200ms latency escalating siren tones ($40\text{dB} \to 75+\text{dB}$) and full-screen haptic vibration overlay with 30s countdown, "I'm Safe" manual tap, 5s auto-silence, and cloud caregiver dispatch.
- **0-FPS Night Mode**: Pitch-black (`#000000`) screen lock state conserving phone battery (<8.0% over 8+ hours) during overnight logging.
- **60 FPS GPU Waveform & Morning Summary**: Skia GPU-accelerated live line charts (`fl_chart`), 256-point FFT spectral graphs, AHI score rings, and signed FHIR JSON / PDF clinical report exports.

---

## 🛠️ Quick Start Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.27.0+ recommended)
- Dart SDK (v3.6.0+)
- Android Studio / Xcode for device emulators

### Installation & Launch

1. **Install Dependencies**:
   ```bash
   cd flutter
   flutter pub get
   ```

2. **Run Automated Test Suite**:
   ```bash
   flutter test
   ```

3. **Launch in Debug Mode**:
   ```bash
   flutter run
   ```

---

## ⚡ How to Start Developer Mode (`DEV_MODE`)

Developer Mode exposes developer menu rows, internal state inspection, and manual BLE simulation tools inside the **Settings** tab.

### Enabling via Compile-Time Flag (Recommended)

Pass the `DEV_MODE=true` environment flag when launching or building the Flutter application:

```bash
flutter run --dart-define=DEV_MODE=true
```

### Verification
1. Navigate to **Settings** (Tab 4 on the bottom navigation bar).
2. The **Advanced** section card (`SettingsGroupCardOrganism`) will automatically render the **Developer** (`Icons.code`) menu row.

---

## 🐛 How to Start Debugging Mode (`debuggingEnabled`)

Debugging Mode exposes internal diagnostic logs, BLE packet inspectors, and simulated apnea breach events.

### Enabling via CLI Flag

Run the Flutter app in debug mode (`kDebugMode` is true by default during `flutter run`):

```bash
flutter run --debug
```

### Enabling Programmatically

You can explicitly pass `debuggingEnabled: true` when instantiating `SettingsPage`:

```dart
const SettingsPage(
  debuggingEnabled: true,
  developerEnabled: true,
)
```

### Verification
1. Navigate to **Settings** (Tab 4).
2. The **Debugging** (`Icons.bug_report_outlined`) row will render under the **Advanced** section card.

---

## 📦 How to Build the Application APK (Debug & Release)

### 1. Build Debug APK with Developer Mode (Fast Dev Testing)
```bash
flutter build apk --debug --dart-define=DEV_MODE=true
```
*Output location*: `build/app/outputs/flutter-apk/app-debug.apk`

### 2. Build Release APK with Developer Mode (For Distribution to QA / Devs)
```bash
flutter build apk --release --dart-define=DEV_MODE=true
```
*Output location*: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Build Standard Production Release APK (No Dev Mode)
```bash
flutter build apk --release
```
*Output location*: `build/app/outputs/flutter-apk/app-release.apk`

### 4. Build Production App Bundle (For Google Play Store)
```bash
flutter build appbundle --release
```
*Output location*: `build/app/outputs/bundle/release/app-release.aab`

---

## 💡 Troubleshooting: Windows Flutter Font Lock Workaround

On Windows systems, if running `flutter run` or `flutter build apk` fails with a file lock error copying `MaterialIcons-Regular.otf`:

```text
Target debug_android_application failed: Error: Flutter failed to copy file from
"D:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf" to
"...\flutter_assets\fonts/MaterialIcons-Regular.otf". The flutter tool cannot access the file or directory.
```

**Solution**: Run `precache` and `doctor` to reset SDK artifact file locks:
```bash
flutter precache --force
flutter doctor
```

---

## 🧪 Running Unit & Widget Tests

Run the complete test suite across all 13 Atomic Design Organisms, BLoC state managers, and BLE driver logic:

```bash
flutter test
```

To run a specific test file:
```bash
flutter test test/ui/user_header_organism_test.dart
```

---

## 🏛️ Atomic Design Organism Index

| Organism | File Path | Purpose |
| :--- | :--- | :--- |
| `UserHeaderOrganism` | `lib/ui/organisms/user_header_organism.dart` | Initials avatar fallback ("D"/"DM"), custom persona title, card decoration. |
| `HealthDemographicsOrganism` | `lib/ui/organisms/health_demographics_organism.dart` | 2x2 demographics input grid and dynamic BMI calculation. |
| `EmergencyContactOrganism` | `lib/ui/organisms/emergency_contact_organism.dart` | Caregiver emergency phone input section. |
| `SleepScoreOrganism` | `lib/ui/organisms/sleep_score_organism.dart` | 0–100 score ring (`92`), AHI score (`3.2`), respiration status badge. |
| `WeeklyCalendarOrganism` | `lib/ui/organisms/weekly_calendar_organism.dart` | Interactive weekly/monthly calendar selection strip. |
| `HealthInsightsOrganism` | `lib/ui/organisms/health_insights_organism.dart` | Health articles and mask insight cards. |
| `BrandHeaderOrganism` | `lib/ui/organisms/brand_header_organism.dart` | Glowing app logo badge, title, platform subtitle. |
| `PasskeyAuthCardOrganism` | `lib/ui/organisms/passkey_auth_card_organism.dart` | Biometric fingerprint badge, passkey button, loading indicator. |
| `SecurityBadgeOrganism` | `lib/ui/organisms/security_badge_organism.dart` | HIPAA compliance and FIDO2 encryption footer badge. |
| `BleSensorStatusOrganism` | `lib/ui/organisms/ble_sensor_status_organism.dart` | BLE connection status badge card (`connected` vs `searching`). |
| `ReportHeaderOrganism` | `lib/ui/organisms/report_header_organism.dart` | Session report title and date header row. |
| `SummaryMetricsGridOrganism` | `lib/ui/organisms/summary_metrics_grid_organism.dart` | 2-column session metrics cards ("Total Apnea Stops" & "Safety Taps"). |
| `SettingsGroupCardOrganism` | `lib/ui/organisms/settings_group_card_organism.dart` | Rounded card containers with anti-aliasing clips and section headers. |
