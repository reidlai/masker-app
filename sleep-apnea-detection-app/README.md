# D-BAND Sleep Apnea Detection App 🫁📱

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

### 🫁 Volumetric Airflow Baseline & Stream Seeding Rationale ($5.0\text{ L/s}$)
- **Physiological Baseline ($5.0\text{ L/s}$)**: In adult respiratory physiology ($V_{\text{volumetric}} = f(\Delta T)$), resting peak-to-peak tidal volume airflow deviation ($V_{pp}$) averages between **4.0 L/s and 6.0 L/s** (centered at **5.0 L/s**).
- **RxDart `BehaviorSubject` Seeding**: The background BLE receiver service (`BleReceiverService`) initializes its central RxDart `BehaviorSubject<double>` queue with a seeded baseline of `5.0 L/s` (`BehaviorSubject.seeded(5.0)`). This guarantees immediate valid baseline data to UI rendering widgets (`LiveWaveformChart`, `MeasurementPage`) upon subscription prior to receiving the first raw 10Hz BLE telemetry packet, eliminating zero-division or visual layout jump artifacts.
- **AASM Apnea Ratio ($0.10 \times V_{pp}$)**: Seeding `5.0 L/s` establishes an initial zero-airflow AASM Obstructive Apnea threshold at $0.10 \times 5.0 = \mathbf{0.5\text{ L/s}}$, providing a physically accurate threshold ratio ($0.5\text{ L/s} \ll 5.0\text{ L/s}$) during initial calibration.

### ⚡ BLE Signal Streaming Architecture: Native Dart Stream vs. RxDart

The app uses **both native Dart Streams and RxDart together** in a 3-step reactive pipeline:

```text
[ BLE Sensor Hardware ]
          │ (10 Hz Raw Packets)
          ▼
   1. DART STREAM  ───────► Receives raw Bluetooth packets from flutter_blue_plus
          │
          ▼
   2. RxDART       ───────► Caches latest sample in a BehaviorSubject
          │
          ▼
   3. RxDART       ───────► Throttles 10 Hz stream to 5 FPS (sampleTime)
          │
          ▼
   [ Flutter UI ]  ───────► Renders smooth waveform chart (conserving battery)
```

#### BLE Signal Pipeline & Layer Responsibilities

| Step & Layer | Component | Stream Technology | Purpose & Rationale |
| :--- | :--- | :--- | :--- |
| **1. Raw BLE Ingestion** | [`flutter_blue_sensor_driver.dart`](lib/core/ble/flutter_blue_sensor_driver.dart#L49) | **Native Dart `Stream`** (`StreamController`) | Standard Flutter Bluetooth plugins (`flutter_blue_plus`) emit GATT notifications as native Dart `Stream`s. The abstract [`IBLESensorDriver`](lib/core/ble/i_ble_sensor_driver.dart#L22) contract uses native `Stream<double>` to keep domain interfaces decoupled from third-party libraries. |
| **2. Central App Queue** | [`ble_receiver_service.dart`](lib/core/ble/ble_receiver_service.dart#L24) | **RxDart `BehaviorSubject`** (`ValueStream`) | Wraps the raw stream in a `BehaviorSubject` seeded with `0.3` / `5.0 L/s`. Caches the latest thermal value so late-subscribing widgets immediately read cached data (`_thermalSubject.value`) without rendering `null` layout jumps. |
| **3. UI Throttling** | [`ble_bloc.dart`](lib/core/bloc/ble/ble_bloc.dart#L20-L27) | **RxDart Stream Operators** (`sampleTime`) | Throttles high-frequency 10 Hz telemetry down to **200 ms (5 FPS)** before updating BLoC state, cutting UI re-draw overhead by 50% and keeping overnight battery consumption under 8.0%. |

#### Key Technical Implementation Details

1. **High-Frequency BLE Throttling (Battery Optimization)**:
   - **Problem**: The BLE sensor streams raw thermal telemetry at **10 Hz** (10 samples/sec). Updating Flutter BLoC states and triggering UI widget re-renders at 10 Hz creates heavy CPU/GPU overhead and drains battery during overnight sleep monitoring.
   - **Solution**: In [`ble_bloc.dart`](lib/core/bloc/ble/ble_bloc.dart#L20-L27), an RxDart stream transformer with `sampleTime` and `distinct` caps event delivery to **200 ms (5 FPS)**:
     ```dart
     on<BleSignalSampleReceived>(
       _onSignalSampleReceived,
       transformer: (events, mapper) => events
           .sampleTime(const Duration(milliseconds: 200)) // Throttle 10 Hz BLE stream to 5 FPS
           .distinct()                                    // Deduplicate unchanged readings
           .switchMap(mapper),
     );
     ```
   - **Impact**: Cuts UI rebuild frequency by **50%** (from 10 FPS to 5 FPS) while preserving continuous waveform visualization and keeping overnight battery consumption under **8.0%** across 8+ hours.

2. **State Persistence & Immediate UI Hydration (`BehaviorSubject`)**:
   - **Problem**: Standard Dart `StreamController`s do not cache past values. Late-subscribing widgets receive `null` or must wait for the next packet, causing layout shifts or rendering errors.
   - **Solution**: In [`ble_receiver_service.dart`](lib/core/ble/ble_receiver_service.dart#L24), `BleReceiverService` maintains a global `BehaviorSubject<double>` seeded with an initial resting value (`BehaviorSubject<double>.seeded(0.3)`):
     ```dart
     BehaviorSubject<double> _thermalSubject = BehaviorSubject<double>.seeded(0.3);
     ValueStream<double> get reactiveStream => _thermalSubject.stream;
     ```
   - **Impact**: Provides late-subscribing widgets with immediate access to the latest cached sample (`_thermalSubject.value`) as a `ValueStream`, preventing null states and layout jumps.

### 📡 BLE Telemetry & GATT Architecture (`0x180D` / `0x2A37`)
- **Service UUID (`0x180D`)**: Standard Bluetooth SIG Heart Rate Service (HRS).
- **Characteristic UUID (`0x2A37`)**: Standard Bluetooth SIG Heart Rate Measurement.
- **iOS Background Scanning Priority**: Official 16-bit Bluetooth SIG UUIDs receive high-priority background BLE discovery and fast auto-reconnection in iOS `CoreBluetooth` during overnight sleep monitoring.
- **Firmware Off-the-Shelf Stack**: Utilizes pre-baked GATT notification drivers on Nordic Semiconductor (nRF52) hardware.
- **10Hz Bio-Signal Payload**: The 10Hz raw thermal inhale/exhale ADC signal is stream-multiplexed inside standard `0x2A37` notification payload packets.
- **Device Filtering Safeguard**: Because `0x180D` is shared with consumer heart rate straps, `BleReceiverService` filters discovery using the device broadcast name prefix (`D-BAND-*`).

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

## 💡 Troubleshooting & Platform Setup

### 1. Android Virtual Device (AVD) Graphics Acceleration
When running on Android Emulators, set the AVD **Graphics Acceleration** to **Software - GLES 2.0** (Software rendering) in Android Studio's AVD Device Manager. Hardware acceleration on certain host GPUs can cause viewport initialization delays, zero-width bounds errors (`Width is zero`), or skipped frames.

### 2. Google Fonts Loading Failure & Network Permission
If `google_fonts` throws dynamic font loading exceptions (`SocketException: Failed host lookup: 'fonts.gstatic.com'`):
- **Root Cause**: The main Android manifest is missing the network permission required to fetch Google Fonts at runtime.
- **Fix**: Ensure `<uses-permission android:name="android.permission.INTERNET" />` is declared in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <manifest xmlns:android="http://schemas.android.com/apk/res/android">
      <uses-permission android:name="android.permission.INTERNET" />
      ...
  </manifest>
  ```
- **Offline Fonts (Optional)**: For offline environments, set `GoogleFonts.config.allowRuntimeFetching = false;` in `lib/main.dart` (in Dart code inside `main()`, not in `pubspec.yaml`) and bundle the TTF font files directly in your `pubspec.yaml` assets.

### 3. Windows Flutter Font Lock Workaround
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
