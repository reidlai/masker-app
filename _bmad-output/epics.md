---
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
status: complete
inputDocuments:
  - _bmad-output/prd/prd.md  # v3.0.0
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md  # v22.0.0
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/DESIGN.md  # v1.3.0
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md  # v1.3.0
revision: "2026-09-10 D-BAND Platform Rebranding Reconciliation — Reconciled against PRD v3.0.0, ARCHITECTURE-SPINE.md v22.0.0, and UX DESIGN/EXPERIENCE specs v1.3.0."
---

# D-BAND Platform (Bio-Telemetry & Hardware Integration Suite) - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for **D-BAND Platform (Bio-Telemetry & Hardware Integration Suite)**, decomposing the requirements from PRD v3.0.0 and Architecture v22.0.0 into actionable, implementable stories.

> [!IMPORTANT]
> **MVP1 Scope & Implementation Directive:**  
> In accordance with product owner strategy, **MVP1 focuses exclusively on the Mobile Application (Flutter) and Bluetooth Device Connection (BLE 4.0, 4.1, 4.2, and 5.0+)** for at-home nocturnal sleep apnea monitoring (Epics 1–4, via `masker-app`). All web portal backoffice, physician EHR sync, multi-mode athletic/meditation applications, and cloud big data exports (Epics 5–8) are categorized as **UNPLANNED** and will remain deferred until further instruction.

## Requirements Inventory

> **Reconciled against PRD v3.0.0 + EXPERIENCE.md/DESIGN.md v1.3.0 + ARCHITECTURE-SPINE.md v22.0.0.** Aligned with the rebranded **D-BAND Platform** for generic thermal/ink sensor telemetry, maintaining full traceability across all Functional Requirements (FR-1.1–FR-6.10) and Non-Functional Requirements (NFR-1–NFR-6.4).

### Functional Requirements

- **FR-1.1:** The application shall automatically scan for, identify, and establish a low-energy Bluetooth (BLE 4.0, 4.1, 4.2, and 5.0+, AES-128 link security) connection with the D-BAND sensor array (`0x180D` service / `0x2A37` characteristic @ 10Hz).
- **FR-1.2:** Upon successful BLE pairing, the application shall execute the Cloud Device Binding API (`POST /api/v1/devices/bind`), transmitting an encrypted payload containing `user_profile_id`, `device_hardware_id`, `ble_mac_address`, and `binding_timestamp`.
- **FR-1.3:** If the device is paired without active internet connectivity, the application shall queue the device binding payload locally in an encrypted buffer and retry transmission upon network restoration.
- **FR-1.4 (Sensor Baseline Drift & Noise Floor Envelope Calibration):** With the D-BAND worn and the patient still, the application shall sample the raw bio-signal for ~10 seconds (`[ASSUMPTION]` window, tunable 5–30 s), tracking the running **minimum** and **maximum** of the stream. Those two values are the session **Sensor Baseline Drift & Noise Floor Envelope** — `lower_bound` / `upper_bound` — the resting reference for all breath detection and apnea evaluation. Each sample only widens the envelope within the window; it is never narrowed.
- **FR-1.5:** *Removed in PRD v2.5.0 — the former "Stage-2 Active Thermal Breath Training" step is eliminated (awake seated breathing is not a valid reference for sleep breathing). The IDLE Band (FR-1.4) is the only calibrated reference. ID retired, not reused.*
- **FR-1.6 (Breath Excursion Definition):** A **valid breath** is a cycle in which the raw signal rises to/above `upper_bound` (inhale) **and** falls to/below `lower_bound` (exhale). A phase that fails to cross its bound is a **"stop-breathing" sample**. The app works in raw signal units — **no** thermal-to-volumetric (L/s) transformation, **no** `V_pp` peak-to-peak baseline.
- **FR-1.7 (Apnea Condition Binding):** A sample is a **"stop-breathing"** sample whenever the signal lies within `[lower_bound, upper_bound]` (no excursion beyond either bound). No `0.10 × V_pp` threshold.
- **FR-1.8 (Wear Verification Guardrail):** Immediately after the IDLE Band sample, the application shall run a **wear check** — the patient breathes normally and "Start Sleep Monitoring" stays blocked until the app observes **≥ 2 valid breath excursion cycles** (FR-1.6) within a bounded window (`[ASSUMPTION]` ~15 s). On failure: *"Sensor not detecting breathing — check the fit."* + retry.
- **FR-1.9:** The application shall support multi-mode operating frameworks: Mode A (Nocturnal Sleep Apnea Monitoring), Mode B (Athletic Respiration Training), Mode C (Individual Respiratory Health Check), Mode D (Meditation & Breath Control).
- **FR-1.10:** The application and web portal shall provide a "Report D-BAND Sensor Lost" workflow. Upon invocation, the cloud gateway shall execute `POST /api/v1/devices/unbind`, mark hardware serial as `DEPRECATED/LOST`, revoke BLE MAC binding, and allow pairing of a replacement sensor without losing cloud history.
- **FR-1.11:** Upon application launch, the BLE background receiver service shall automatically start in the background (via Android Foreground Service / iOS `bluetooth-central` mode) and listen for incoming BLE packets (physical hardware or `BleTelemetryService` simulator). Incoming signals MUST be pushed into a reactive `BehaviorSubject<double>` queue using RxDart `.add()` (`next`) so downstream consumers (the Measure Page's IDLE Band idle calibration, the wear check, and 8+ hour sleep monitoring cycles) consume from a single unified reactive stream.
- **FR-2.1:** The application shall log the continuous 10Hz raw respiratory signal throughout an 8+ hour sleep window in a low-power background state.
- **FR-2.2:** The application shall evaluate the real-time raw signal against the session IDLE Band every 100 milliseconds, classifying each interval as a valid breath excursion (FR-1.6) or a "stop-breathing" interval (FR-1.7).
- **FR-2.3:** An apnea event shall be flagged whenever **no valid IDLE-Band breath excursion occurs for $\ge 10$ seconds continuously** (the AASM 10-second duration standard is retained).
- **FR-2.4:** Telemetry packets shall be timestamped locally and buffered in hardware-encrypted storage during temporary signal interruptions.
- **FR-2.5 — `PREMIUM`:** The cloud platform shall ingest compressed telemetry streams and execute AI waveform classification algorithms to refine apnea event detection and flag anomalous breathing patterns. Gated to Premium (FR-6); Free-tier sessions run the on-device IDLE-Band evaluator (FR-2.2/2.3) only and are not streamed to the cloud AI pipeline.
- **FR-3.1:** Upon flagging a critical apnea event (>10s no valid excursion), the smartphone application shall trigger high-priority escalating audio tones (40 dB → 75+ dB) and full-screen haptic vibration pulses (<200ms latency).
- **FR-3.2:** The application shall render a prominent, large touch target button ("I'm Safe / I'm Awake") on the screen during an alarm event.
- **FR-3.3 — `MVP1` · `PREMIUM` · `[OPEN — legal/regulatory/clinical sign-off]`:** On an "I'm Safe" tap within 30 s, or on an unacknowledged 30-second timeout, the application shall transmit the corresponding status signal to the cloud, where it is **logged with no outbound action**. Cloud transmission is gated to Premium (FR-6); on Free the event is written to a **local-only** trace. Paywalling a safety-critical acknowledgement carries liability / SaMD / IEC 60601-1-8 exposure — must clear sign-off before billing build.
- **FR-3.4:** If valid IDLE-Band breath excursions resume (FR-1.6) continuously for 5 seconds without a manual tap, the app shall auto-silence the alarm.
- **FR-3.5 — `MVP2` · `PREMIUM` · `[OPEN — legal/regulatory/clinical sign-off]`:** *Deferred to MVP2.* When built: on an unacknowledged >30 s event the platform shall dispatch priority SMS/voice to designated caregiver contacts and — routed by patient country/location, not US-911-only — the appropriate regional EMS CAD gateway. **MVP1 behaviour:** no outbound contact of any kind; the Tier-1 local alarm continues and FR-3.3 records the event.
- **FR-4.1 (Morning Sleep Summary):** Displays Total Sleep Duration, Overnight **Apnea Index (AI)** — apnea events/hour — Intervention Count, and Quality Score (0–100). Every surface that shows the AI carries an **apnea-only caveat** (*"apnea-only screen; a full sleep study also counts shallow-breathing events and may score higher"*). Severity bands (Normal <5 / Moderate 5–29.9 / Severe ≥30) are the standard AHI bands applied to the AI. **Alarm-fired awareness:** when the persisted `alarm_fired` / `apnea_alarm_count` signal is true for the night, the Summary score card **and** the Home hero card (FR-4.6) both switch to an amber alert treatment — the two surfaces read the same single persisted field so they cannot disagree.
- **FR-4.2 — `PREMIUM`:** The interactive overnight **raw-signal** wave graph with the IDLE Band bounds drawn as horizontal reference lines, pinch/zoom/pan, a 256-point FFT view (computed on the raw signal for BPM), and color-coded markers for apnea episodes and safety acknowledgements. Apnea reads as a flat trace between the band lines. Free-tier users see FR-4.1 metrics + a non-interactive thumbnail.
- **FR-4.3 (Calendar & History Filter):** Date-filtered historical sessions. **Free:** rolling **7-day** window, on-device only, no cloud backup / no archive — older sessions discarded. **Premium:** unlimited night-by-night history + cloud backup/archive; the local last-N window stays the offline read model (AD-15).
- **FR-4.4:** Educational Library containing integrated articles and instructional videos. *(Free and Premium.)*
- **FR-4.5:** Big Data Platform & Clinical Research Export — a secure, de-identified big data export interface for clinical research. *(Platform-side; not a user-tier feature. Only Premium sessions, which stream to the cloud, contribute.)*
- **FR-4.6 (Home Dashboard) — NEW:** A **read-only** Home dashboard as the post-onboarding landing surface: greeting + monitoring streak; a **last-night hero card** (`HomeSummaryCardOrganism` — AI + alarm-fired override, taps through to the Morning Sleep Summary); a **D-BAND device-status card** (`DeviceStatusCardOrganism` — nominal / actionable, reads AD-12 receiver-service state only); a **7-night Apnea Index trend** card (`WeeklyTrendCardOrganism` — 7-slot mini chart + descriptive, non-diagnostic delta line; <2 nights → "not enough data"). Pure consumer of already-computed state — reads the local last-N `SessionSummary` cache (AD-15) + the AD-12 receiver state; opens **no** BLE subscription and issues **no** network read on load.
- **FR-5.1:** Passkey FIDO2/WebAuthn authentication — passwordless login via native OS biometrics (Face ID, Touch ID, Android BiometricPrompt) and hardware secure enclave tokens.
- **FR-5.2:** Health Profile Management — Patient Full Name (`full_name`), Patient Email (`email`), Patient Phone Number (`phone_number`), Weight, Height, Age, Gender, computed BMI, Caregiver Name (`caregiver_name`), and Caregiver Emergency Phone Number (`caregiver_phone`). Weight/Height are captured, stored, and displayed in the units selected in FR-5.7 (kg/lb, cm/ft-in); a single canonical unit is persisted server-side and converted for display. Protected under HIPAA 45 CFR § 164.312 & FDA SaMD rules (AES-256 encryption at rest, TLS 1.3 in transit, Passkey access gate, and `PhiAuditLog` audit logging).
- **FR-5.3 — `PREMIUM` · `[OPEN — legal sign-off, HIPAA § 164.524]`:** "Share Profile with Doctor" UI module + extensible JSON export engine formatted for future EHR/EMR physician integrations. Gated to Premium. **`bmad-build` must NOT ship the gate** until Privacy/Legal sign-off; standing fallback = a **free basic signed-FHIR/PDF export always available**, Premium gating only enhancements (trend analytics, date-range/bulk export, richer formatting).
- **FR-5.4:** Mobile Device Lost & Remote Session Revocation — a WebAuthn-backed self-service Web Portal to report a lost phone; the cloud invalidates active JWT tokens, revokes refresh tokens, and issues a cryptographic remote wipe signal.
- **FR-5.5:** Application Documentation & Developer Setup Guide — a comprehensive developer README (project summary, product background, quick start, developer mode, debugging mode, release build workflows). *(Epic-derived, not a PRD FR; retained.)*
- **FR-5.6:** Developer Options Page & BLE Signal Simulator — interactive controls to simulate the IDLE Band idle calibration, the wear check, and nocturnal sleep cycles (normal 16 bpm streams crossing both band lines, $\ge 10\text{s}$ in-band [no-excursion] stretches firing an apnea alert, 5s recovery). Rendered only when `DEV_MODE=true`.
- **FR-5.7 (Locale & Units) — NEW:** A **Language & Region** screen: user-selectable app display language and measurement units for weight (kg/lb) and height (cm/ft-in). Persists per user, applies immediately app-wide, governs FR-5.2 rendering. A canonical unit + IETF language tag are stored server-side; conversion/formatting happen at display time.
- **FR-5.8 (Settings Surface) — NEW:** A single grouped **Settings** screen as the navigation home for account/app configuration — **Account** (Health Profile, Passkey/device security, Mobile Device Lost), **Preferences** (Language & Region, notifications, Developer Options when enabled), **Subscription** (current plan, Billing, Payment Method — FR-6). A pushed detail surface reached from Home, not a primary nav tab.
- **FR-6.1 (Two-Tier Entitlement Model) — NEW:** Exactly two tiers — **Free** and **Premium** — one paid subscription product. Every account is Free by default; Premium is an opt-in paid upgrade. **No free trial** — the Free tier is the always-available entry experience.
- **FR-6.2 (Safety-Critical Local Path Is Always Free) — NEW:** Overnight monitoring + the 100 ms on-device apnea evaluator (FR-2.1–2.4), the local Tier-1 alarm + auto-silence (FR-3.1, 3.4), "I'm Safe" + local event trace (FR-3.2 local path), IDLE Band calibration + wear check (FR-1.4–1.8), the Morning Sleep Summary of the just-finished night (FR-4.1), the 7-day on-device history (FR-4.3 Free), the Home dashboard (FR-4.6), and passkey auth / health profile / device pairing & loss (FR-5.1/5.2/5.4, FR-1.10) shall remain fully functional on Free and shall never be gated, degraded, or time-limited by subscription state.
- **FR-6.3 (Tier Boundary) — NEW:** A defined Free-vs-Premium capability table (see PRD §3.6). Premium-only: cloud safety-signal logging (FR-3.3) `[OPEN]`; Tier-2 outbound dispatch (FR-3.5, MVP2) `[OPEN]`; history beyond 7 days + cloud backup/archive (FR-4.3); Doctor Report export (FR-5.3) `[OPEN — §164.524]`; cloud AI analytics (FR-2.5); interactive respiration timeline + FFT (FR-4.2).
- **FR-6.4 (Payment Processor & Card Data Scope) — NEW:** All card capture occurs **only** inside the Stripe-hosted PaymentSheet / Elements surface. No platform component receives, processes, or stores a PAN or CVC — the platform persists only a display triplet (brand, last4, expiry) + an opaque `stripe_payment_method_id`. Keeps the platform at **PCI-DSS SAQ-A** (architecture AD-14).
- **FR-6.5 (Backend-Owned Subscription Lifecycle) — NEW:** The backend Billing service is the sole source of truth for subscription state, mutated **only** by HMAC-SHA256-verified Stripe webhook events (`customer.subscription.*`, `invoice.*`). The client never asserts entitlement to the backend. Stripe executes payment only (architecture AD-13).
- **FR-6.6 (Server-Verified Entitlement + Bounded Offline Grace) — NEW:** The client gates Premium capabilities on a **signed entitlement claim** issued by the backend; it may honor a cached claim through a bounded connectivity grace window when the backend is unreachable — **fail-open for transport failure, fail-closed for a known-expired plan**. Loss of connectivity shall never disable any FR-6.2 safety-critical capability.
- **FR-6.7 (Pricing Structure) — NEW:** Premium offered as a **monthly** plan and a **discounted annual** plan. `[ASSUMPTION]` No price points set; the PRD carries no currency amounts — a business decision to record before billing build.
- **FR-6.8 (Pre-Paid Term & Cancel-at-Period-End Lapse) — NEW:** Premium is pre-paid. On cancellation or failed renewal the account retains Premium until the end of the paid period, then transitions to Free — no mid-period downgrade, no separate post-expiry grace beyond FR-6.6. On lapse, cloud-archived history beyond the 7-day window is retained but not user-visible until re-subscription `[ASSUMPTION — retention/deletion policy pending legal]`.
- **FR-6.9 (Subscription Management UI) — NEW:** Under Settings → Subscription (FR-5.8): a **Billing** screen (current plan, renewal date, plan-change / cancel actions) and a **Payment Method** screen (card-on-file display triplet; update launches the Stripe-hosted surface per FR-6.4). Invoice history is deferred.
- **FR-6.10 (Downgrade Transparency) — NEW:** Before a downgrade or cancellation completes, the app shall disclose in plain language which capabilities are lost and when, and confirm that all FR-6.2 safety-critical local capabilities remain unaffected.

### NonFunctional Requirements

- **NFR-1.1:** Auto-Reconnect BLE connection within 3.0 seconds of signal loss.
- **NFR-1.2:** Data Recovery via a 1-hour local circular RAM ring buffer for telemetry data preservation.
- **NFR-2.1:** Primary mobile alarm triggers locally within < 200 milliseconds of apnea threshold breach.
- **NFR-2.2:** The Tier-2 cloud safety-signal payload (FR-3.3) transmits within < 1.5 seconds on an available connection. (When Tier-2 outbound dispatch ships in MVP2, the same budget applies to the dispatch payload.)
- **NFR-3.1:** Continuous 8-to-10 hour background sleep logging consumes < 8.0% total phone battery.
- **NFR-3.2:** 0-FPS display throttling (Night Mode `#000000` locked black display) during active sleep monitoring.
- **NFR-3.3:** Signal processing and 256-point FFT math offloaded to background Dart Isolates for zero UI thread jank.
- **NFR-4.1:** Technical Access Control & Passkey Enforcement (HIPAA 45 CFR § 164.312(a)) with 5-minute inactivity mobile auto-lock and 15-minute portal idle timeout.
- **NFR-4.2:** Audit Controls & Tamper-Evident Logs (`phi_audit_logs` / `PhiAuditLog`) capturing all PHI access, doctor exports, and alert dispatches.
- **NFR-4.3:** Sub-1s automated cryptographic remote zeroization protocol deleting local SQLCipher databases, Hive stores, and Secure Enclave master keys upon remote wipe signal or 10 failed auth retries.
- **NFR-4.4:** Encryption in Transit & Certificate Pinning (AES-128 BLE, HTTPS TLS 1.3 with SSL Certificate Pinning, gRPC mTLS internal service mesh).
- **NFR-4.5:** Encryption at Rest (AES-256 SQLCipher local database encryption + Cloud KMS master key envelope encryption for Level 1 PHI fields).
- **NFR-4.6:** SOLID Dependency Inversion Principle (`IBLESensorDriver` polymorphism across `BLESensorDriver`, `BleTelemetryService`, and `FlutterBlueSensorDriver` with Constructor Dependency Injection).
- **NFR-5.1:** CHART-01 Live Raw-Signal Line Chart (`fl_chart` / Skia GPU, 60 FPS active / 0 FPS locked) — raw bio-signal with the IDLE Band `lower_bound` / `upper_bound` drawn as horizontal reference lines.
- **NFR-5.2:** CHART-02 FFT Frequency Spectrum Graph (256-point FFT magnitude vs Hz, computed on the raw signal for respiration rate).
- **NFR-5.3:** CHART-03 Circular Progress Metric Rings (Animated stroke fill for calibration & sleep quality score).
- **NFR-5.4:** CHART-04 Multi-Axis Historical Session Chart (Interactive overnight **Apnea Index** events, SpO2, and respiratory amplitude curves).
- **NFR-6.1:** AASM **Duration** Standard Alignment — an apnea event is "no valid IDLE-Band breath excursion for $\ge 10\text{s}$" (the 10-second minimum-duration standard retained; the ≥90% airflow-reduction criterion expressed as "no excursion beyond the calibrated resting band"). **Hypopnea is not scored** in MVP1 (requires SpO₂ desaturation or EEG arousal the airflow-only D-BAND cannot measure). The nightly metric is an **Apnea Index (AI)**, not a full AHI; standard AHI severity bands applied to the AI; every surface showing it carries the apnea-only caveat.
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
- **AD-13 — Subscription State & Server-Verified Entitlement:** the backend `BillingService` is the sole source of truth for subscription state, mutated only by HMAC-SHA256-verified Stripe webhook events; the Flutter `BillingBloc` / `SubscriptionRepository` / `EntitlementService` hold a **signed entitlement claim** and re-check server-side per gated action, falling back to the cached claim within a bounded grace window (fail-open for transport, never for a known-expired plan). Stripe executes payment only. New backend components: `BillingService`, `StripeWebhookReceiver` (edge, HMAC-verified, sole writer, webhook audit log).
- **AD-14 — Cardholder-Data Scope Containment (PCI-DSS SAQ-A):** card capture occurs only inside Stripe's hosted PaymentSheet (mobile) / Elements (web); the platform persists/renders only `brand` + `last4` + `exp` + opaque `stripe_payment_method_id`. `StripePaymentSheetGateway` returns an opaque token only; "remove card" detaches it via `BillingService`. No platform component enters the cardholder-data environment.
- **AD-15 — Local `SessionSummary` Read Model:** on session finalization a `SessionSummary` `{date, ai_score, quality_score, total_duration, apnea_alarm_count, safety_tap_count, alarm_fired}` is written to the cloud Isolated Data Zone (1:1 with `SleepSession`, Level 1 PHI) as source of truth, with the device holding a local rolling last-N (N ≥ 7) cache. `HomeDashboardBloc` assembles `MOB_HOME` from that cache + the AD-12 receiver-service state, opening no BLE subscription of its own. `alarm_fired` / `apnea_alarm_count` is the single persisted field both summary cards read.
- **Isolated Billing datastore:** a dedicated relational Billing store (`Subscription`, `PaymentMethodRef`, `Invoice`, `Entitlement` — **Level 3 Financial PII**, references `user_id` only, **no PHI, no cardholder data**) on a separate Cloud SQL instance / VPC in the App Core zone — **not** the PHI Isolated Data Zone. `StripeWebhookReceiver` runs behind Cloud Armor (Cloud Functions v2 / Cloud Run); egress allowlist adds `api.stripe.com`.
- **IDLE Band signal model (PRD v2.5.0 · ARCHITECTURE-SPINE.md v21.0.0 `AD-04`/`AD-05`):** the on-device evaluator works in **raw signal units** against a per-session `[lower_bound, upper_bound]` learned at calibration (running min/max of a worn ~10 s idle sample); a valid breath crosses both bounds; a stop-breathing sample stays inside them; apnea = no valid excursion for ≥ 10 s. No thermal-to-volumetric (L/s) transform, no `V_pp` baseline. IDLE Band persisted on `SleepSession` (`idle_band_lower`/`idle_band_upper`).

### UX Design Requirements

- **UX-DR1:** Implement `flutter_shadcn` design system tokens (HSL color palette, dark mode glassmorphism `#0F172A`, accessible touch targets $\ge 48\text{dp}$).
- **UX-DR2:** Implement 0-FPS Night Mode screen lock state (`#000000` pitch black screen with dim pulsing green heartbeat dot).
- **UX-DR3:** Implement Tier-1 local alarm overlay (`MOB_TIER1_ALARM`) featuring high-contrast flashing red/yellow banner (`#FF3B30`), 120dB siren, haptics, 30s countdown, and 64dp button ("I'M SAFE - DISMISS ALARM").
- **UX-DR4:** Implement the single-stage **IDLE Band Calibration** wizard (`MOB_CALIBRATION`, `IdleBandCalibrationWizardOrganism`): step 1 **idle sample** (`State_CalibratingIdleBand` — D-BAND worn, patient still, ~10s, running min/max readout, circular progress ring); step 2 **wear check** (`State_WearCheck` — patient breathes normally; unlock "Start Sleep Monitoring" only after ≥ 2 valid band-excursion cycles; failure toast *"Sensor not detecting breathing — check the fit."* + retry). No Stage-2 / active-breath-training step. `CalibrationStepHeader` reads "STEP 1 OF 2".
- **UX-DR5:** Implement Morning Sleep Summary (`MOB_SLEEP_SUMMARY`): **Apnea Index (AI)** score ring + clinical line + status badge with the **alarm-fired amber override** (two independent signals — AI band vs `"N APNEA ALERT"`, consistent with `HomeSummaryCardOrganism`); an **apnea-only caveat line** always present under the score card (carried into the doctor report); header **History pill** → `MOB_HISTORY_FILTER` (the only route to History from the Summary tab); **Respiration Waveform card** as a single tap target ("View details ›") → `MOB_GRAPH_WAVEFORM`, rendering the **raw signal + IDLE Band bounds** (no L/s axis); **Export** button Free-gated (lock glyph → `MOB_BILLING`). `MOB_GRAPH_WAVEFORM` / `MOB_HISTORY_FILTER` / `MOB_EXPORT_DOCTOR` are pushed detail screens (‹ back, no bottom nav).
- **UX-DR6:** Implement Bluetooth background-access priming (`MOB_BLE_PERMISSION_PRIMER`, first-run only) with native OS permission hand-off (Android sequential `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT` dialogs, iOS `bluetooth-central` disclosure), denial and partial-grant recovery on `MOB_DEVICE_PAIRING`, and the `BleReceiverForegroundNotification` / `BleNotProtectedNotification` persistent-notification pair confirming monitoring status.
- **UX-DR7 (Home Dashboard) — NEW:** Implement `MOB_HOME` — a read-only vertical scroll of status cards, tab-1 default landing on every launch after onboarding. Blocks: greeting + monitoring-streak line; `HomeSummaryCardOrganism` (hero — AI value + severity pill / alarm-fired amber override, Duration + Apnea-events stats, whole card taps → `MOB_SLEEP_SUMMARY`); `DeviceStatusCardOrganism` (nominal inert green / actionable red-amber states — reads AD-12 receiver-service state, never a fresh scan; actionable card routes to `MOB_DEVICE_PAIRING` blocked state or the OS Settings deep-link); `WeeklyTrendCardOrganism` (7-slot `fl_chart` mini bar strip + descriptive-only delta line, non-diagnostic; <2 nights → "Not enough data yet"; tap → `MOB_HISTORY_FILTER`). No start control, no quick-links row. States: `State_HomeDefault` / `State_HomeEmpty` / `State_HomeNoDevice` / `State_HomeDeviceAlert`. Each card exposes one composite accessibility label.
- **UX-DR8 (Settings surface) — NEW:** Implement `MOB_SETTINGS` as a grouped list — `SettingsSectionHeader` + `SettingsMenuRow` (value variant) — with **Account** (Profile), **Preferences** (Language & Region, trailing value "English"), **Subscription** (Billing & subscription → plan name; Payment method → "Visa ·· 4242" / "None"). The three headers always render; **Advanced** (Debugging / Developer) renders only when `debuggingMode || developerMode`, its rows omitted from the widget tree otherwise. Pushed full-screen destination from tab 4 with a ‹ back app bar. States `State_SettingsDefault` / `State_SettingsAdvanced`.
- **UX-DR9 (Language & Region) — NEW:** Implement `MOB_LANGUAGE_REGION` (pushed, ‹ back, no bottom nav): **App language** row (single-select sheet — English selected above a dimmed "More languages coming soon" group); **Region** row (searchable country/region list — drives date/number format app-wide and the **default** for the Units preference; changing region after onboarding shows a confirm noting saved profile values aren't converted); a caption stating the Region → format/units link. `State_LanguageRegionDefault`.
- **UX-DR10 (Billing & Subscription) — NEW:** Implement `MOB_BILLING` (pushed, ‹ back, no bottom nav): `SubscriptionPlanCardOrganism` hero — `State_SubscriptionPremium` (plan "Premium" + accent-green "Active" pill + price/cycle + "Renews {date}"; if `cancelPending`, amber "Ends {date}" pill and a "Resume Premium" action) vs `State_SubscriptionFree` (plan "Free", no renewal line, primary "Upgrade to Premium"); a "what Premium includes" checklist (muted preview on Free); a payment-method summary row → `MOB_PAYMENT_METHOD`; a "View invoices" row (destination deferred); a plainly-labelled `{colors.danger_red}` **Cancel subscription** text button (Premium only) with a consequence-and-date confirm dialog, no retention interstitial. Billing state is fetched on entry with an inline skeleton; never optimistically render "Premium" before the server confirms.
- **UX-DR11 (Payment Method) — NEW:** Implement `MOB_PAYMENT_METHOD` (pushed, ‹ back, no bottom nav) — a **management** screen, never a card-entry form. `PaymentMethodCardOrganism`: `State_PaymentMethodOnFile` shows brand mark + "·· ·· ·· {last4}" + "Expires mm / yy" + cardholder — brand + last4 + expiry only, never PAN/CVC. **Replace card** (primary) launches the hosted Stripe PaymentSheet; on success the card updates in place with a transient "Card updated". **Remove card** (`{colors.danger_red}` text) → consequence-naming confirm → backend detach → `State_PaymentMethodEmpty` ("No payment method on file." + "Add card"). Sheet dismissal without completion is a no-op.
- **UX-DR12 (Hosted Payment Sheet Hand-off) — NEW:** Implement the interaction primitive — the app passes a client secret to Stripe's hosted PaymentSheet and receives back only an opaque payment-method token; there is no in-app PAN/CVC form anywhere in the product; success is quiet and factual ("Card updated"), not a full-screen success state.
- **UX-DR13 (Alarm-fired override) — NEW:** Implement the shared two-signal treatment on `HomeSummaryCardOrganism` and the `MOB_SLEEP_SUMMARY` score card (DESIGN.md #1a): when the session recorded ≥ 1 Tier-1 apnea alarm, the amber `"N apnea alert(s)"` pill replaces the AI-severity pill, the severity word drops to a caption, the apnea-events stat and (Summary) the score ring turn amber. Fires regardless of AI band. Screen-reader label leads with the alarm. Copy register is factual past-tense ("Morning-after alarm recap" Voice&Tone rule). Both cards read the single persisted `alarm_fired` / `apnea_alarm_count` field.
- **UX-DR14 (Navigation model) — NEW:** Tab roots (Home / Monitor / Summary / Settings) carry `PrimaryNavBarOrganism` and no back arrow; pushed detail screens (Profile, Language & Region, Billing, Payment Method, Waveform, History, Export) carry a ‹ back affordance and **no** bottom nav; the Monitor Night Mode lock (`State_MonitoringActive`) is pure black with neither. `PrimaryNavBarOrganism` is hidden during onboarding and Night Mode.
- **UX-DR15 (Monitor pre-session state) — NEW `[NOTE FOR UX]`:** `MOB_SLEEP_MONITOR` gains a pre-session **"Start Sleep Monitoring"** state distinct from its Night Mode lock; tapping it goes straight to active monitoring, with the calibration wizard re-running only on the first session or when the stored IDLE Band is stale/invalid. Specified in EXPERIENCE.md; mockup pending.
- **UX-DR16 (Apnea Index terminology) — NEW:** Every user- or clinician-facing surface that shows the nightly metric calls it the **"Apnea Index"** (abbrev. "AI" only after it's spelled out on that surface), never "AHI", and carries the apnea-only caveat. Severity words ("Normal range" / "Moderate" / "Severe") are kept; the number is never framed as a diagnosis. (Voice&Tone rule.)

### FR Coverage Map

> Approved epic structure (step-02). Every FR maps to exactly one epic; FR-1.5 is removed; FR-5.3 and FR-5.4 are split MVP1 / UNPLANNED with the split stated.

- **FR-1.1:** Epic 2 — BLE auto-discovery + encrypted link
- **FR-1.2:** Epic 2 — Cloud Device Binding API
- **FR-1.3:** Epic 2 — offline device-binding queue
- **FR-1.4:** Epic 2 — IDLE Band idle sample (running min/max)
- **FR-1.5:** *Removed (PRD v2.5.0) — no coverage needed*
- **FR-1.6:** Epic 2 — breath-excursion definition (inhale ≥ upper AND exhale ≤ lower)
- **FR-1.7:** Epic 2 — apnea condition binding (in-band = stop-breathing)
- **FR-1.8:** Epic 2 — wear-check guardrail (≥ 2 valid excursion cycles)
- **FR-1.9:** Epic 3 *(Mode A — MVP1)* & Epic 9 *(Modes B/C/D — UNPLANNED)*
- **FR-1.10:** Epic 7 *(Backoffice — UNPLANNED)*
- **FR-1.11:** Epic 2 — app-boot BLE receiver + unified RxDart queue
- **FR-2.1:** Epic 3 — continuous 10 Hz raw-signal logging
- **FR-2.2:** Epic 3 — 100 ms raw-signal-vs-IDLE-Band evaluator
- **FR-2.3:** Epic 3 — apnea event flag (no valid excursion ≥ 10 s)
- **FR-2.4:** Epic 3 — session data integrity / buffering
- **FR-2.5:** Epic 10 *(Cloud AI — UNPLANNED)*; the Premium **entitlement gate** for it → Epic 5
- **FR-3.1:** Epic 3 — Tier-1 escalating local siren + haptics
- **FR-3.2:** Epic 3 — "I'm Safe" acknowledgement button
- **FR-3.3:** Epic 3 — cloud safety-signal **log only**, Premium-gated `[OPEN — sign-off]`; gate via Epic 5 `EntitlementService`
- **FR-3.4:** Epic 3 — auto-silence on resumed band excursions
- **FR-3.5:** Epic 6 *(Tier-2 Outbound Dispatch — MVP2)* `[OPEN]`; the MVP1 no-outbound behaviour lives in Epic 3
- **FR-4.1:** Epic 4 — Morning Sleep Summary (Apnea Index + caveat + alarm-fired awareness)
- **FR-4.2:** Epic 4 — interactive raw-signal + IDLE-Band timeline + FFT, **Premium-gated** (gate via Epic 5)
- **FR-4.3:** Epic 4 — history filter (Free 7-day local); Premium unlimited + cloud archive gated via Epic 5
- **FR-4.4:** Epic 4 — Educational Library
- **FR-4.5:** Epic 10 *(De-identified Research Export — UNPLANNED, platform-side)*
- **FR-4.6:** Epic 4 — Home Dashboard (`HomeDashboardBloc`, AD-15 `SessionSummary` cache, 3 card organisms)
- **FR-5.1:** Epic 1 — Passkey FIDO2/WebAuthn authentication
- **FR-5.2:** Epic 1 — health profile; unit rendering per FR-5.7
- **FR-5.3:** Epic 4 — in-app "Share with Doctor" export module, **Premium-gated** `[OPEN — §164.524]`, free-basic-export fallback (gate via Epic 5); full EHR/physician portal → Epic 8 *(UNPLANNED)*
- **FR-5.4:** Epic 1 — on-device zeroization execution (NFR-4.3); self-service **portal** → Epic 7 *(UNPLANNED)*
- **FR-5.5:** Epic 1 — developer README / setup guide
- **FR-5.6:** Epic 1 — Developer Options page + IDLE Band signal simulator
- **FR-5.7:** Epic 1 — Language & Region (`MOB_LANGUAGE_REGION`, `UserPreferences`)
- **FR-5.8:** Epic 1 — grouped Settings surface (`MOB_SETTINGS`)
- **FR-6.1:** Epic 5 — two-tier entitlement model, no free trial
- **FR-6.2:** Epic 5 — safety-critical local path always free (assertion + guard tests)
- **FR-6.3:** Epic 5 — tier boundary table; per-feature gates consumed by Epics 3–4
- **FR-6.4:** Epic 5 — Stripe hosted PaymentSheet card capture (`StripePaymentSheetGateway`, PCI SAQ-A / AD-14)
- **FR-6.5:** Epic 5 — backend-owned lifecycle (`BillingService`, `StripeWebhookReceiver`, HMAC / AD-13)
- **FR-6.6:** Epic 5 — server-verified entitlement + bounded offline grace (`EntitlementService`)
- **FR-6.7:** Epic 5 — monthly + discounted-annual pricing `[ASSUMPTION — price points]`
- **FR-6.8:** Epic 5 — pre-paid / cancel-at-period-end lapse `[ASSUMPTION — retention policy]`
- **FR-6.9:** Epic 5 — Billing + Payment Method management screens
- **FR-6.10:** Epic 5 — downgrade transparency disclosure

## Epic List

> Renumbered this reconciliation so MVP1-active epics (1–5) lead, MVP2 follows (6), and the deferred epics (7–10) trail. Detailed User Stories below cover Epics 1–5.

### Epic 1: Mobile App Foundation, Settings & Biometric Passkey Onboarding (MVP1 - Active)
Patients register passwordlessly with FIDO2 Passkey biometrics (Face ID / Touch ID / BiometricPrompt), set up a units-aware health baseline profile with Patient Identification (Full Name, Email Address, Phone Number) and Caregiver Contact details (Caregiver Name & Phone) under HIPAA §164.312 & FDA SaMD compliance rules, navigate the `flutter_shadcn` dark glassmorphic shell and its four tabs, open a grouped **Settings** surface (Account / Preferences / Subscription / conditional Advanced), choose **Language & Region** and measurement units, and reach the Developer Options page. Includes the on-device sub-1-second cryptographic zeroization routine and the developer README.
**FRs covered:** FR-5.1, FR-5.2, FR-5.5, FR-5.6, FR-5.7, FR-5.8, FR-5.4 *(on-device wipe execution only — portal → Epic 7)* | **NFRs:** NFR-4.1, NFR-4.3, NFR-4.4, NFR-4.5 | **UX-DRs:** UX-DR1, UX-DR8, UX-DR9, UX-DR14, UX-DR16
**Standalone:** complete auth + shell + settings; enables every later epic, requires none.

### Epic 2: BLE Sensor Discovery, Pairing & IDLE Band Calibration (MVP1 - Active)
Patients grant Bluetooth background access via a one-time priming screen, auto-discover and pair the D-BAND over encrypted BLE (4.0/4.1/4.2/5.0+), bind it to the cloud with an offline retry queue, then run the single-stage **IDLE Band** calibration — a worn ~10-second idle sample that learns the running min/max `[lower_bound, upper_bound]`, followed by a wear check that requires ≥ 2 valid band-excursion breath cycles before "Start Sleep Monitoring" unlocks. No active-breath training stage.
**FRs covered:** FR-1.1, FR-1.2, FR-1.3, FR-1.4, FR-1.6, FR-1.7, FR-1.8, FR-1.11 *(FR-1.5 removed in PRD v2.5.0)* | **NFRs:** NFR-1.1, NFR-4.6, NFR-6.5 | **UX-DRs:** UX-DR4, UX-DR6
**Standalone:** uses auth (Epic 1); produces the paired device + IDLE Band that Epic 3 consumes.

### Epic 3: Nocturnal IDLE-Band Monitoring & Tier-1 Local Alarm (MVP1 - Active)
Patients monitor overnight in low-power 0-FPS Night Mode (`#000000`); the app logs the 10 Hz raw signal into a circular RAM buffer, evaluates it against the session IDLE Band every 100 ms, flags an apnea event on ≥ 10 s with no valid excursion, fires the escalating Tier-1 local siren + haptics (< 200 ms), accepts the "I'm Safe" tap (local trace always; cloud safety-signal log if Premium), and auto-silences on 5 s of resumed band excursions. No outbound dispatch in MVP1 — an unacknowledged event keeps the local siren escalating.
**FRs covered:** FR-1.9 *(Mode A)*, FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-3.1, FR-3.2, FR-3.3 *(cloud log-only, Premium-gated, `[OPEN]`)*, FR-3.4 | **NFRs:** NFR-1.2, NFR-2.1, NFR-2.2, NFR-3.1, NFR-3.2, NFR-3.3, NFR-6.1, NFR-6.2 | **UX-DRs:** UX-DR2, UX-DR3
**Standalone:** delivers the complete MVP1 safety loop; the Premium cloud-log path degrades to local-only without Epic 5.

### Epic 4: Home Dashboard, Morning Analytics & Respiration Waveform (MVP1 - Active)
Patients land on a read-only **Home dashboard** (last-night hero card, D-BAND device-status card, 7-night Apnea Index trend, monitoring streak), open the **Morning Sleep Summary** (Apnea Index + severity band + always-on apnea-only caveat + alarm-fired amber override), inspect the interactive raw-signal + IDLE-Band waveform and 256-point FFT, filter session history (7-day local window on Free), read the Educational Library, and generate a signed doctor report.
**FRs covered:** FR-4.1, FR-4.2 *(Premium)*, FR-4.3 *(Free 7-day local / Premium unlimited + cloud)*, FR-4.4, FR-4.6, FR-5.3 *(in-app "Share with Doctor" export module; gate `[OPEN — §164.524]`, free-basic-export fallback)* | **NFRs:** NFR-5.1, NFR-5.2, NFR-5.3, NFR-5.4 | **UX-DRs:** UX-DR5, UX-DR7, UX-DR13
**Standalone:** reads the `SessionSummary` written by Epic 3; renders Free behavior with no dependency on Epic 5.

### Epic 5: Subscription, Billing & Entitlement (MVP1 - Active)
Patients see their current plan, upgrade to **Premium** through Stripe's hosted PaymentSheet, manage the card on file (brand + last 4 + expiry only), and cancel at period end. The backend `BillingService` is the sole source of truth for subscription state, mutated only by HMAC-SHA256-verified Stripe webhooks; the client `EntitlementService` holds a signed entitlement claim with a bounded offline grace window and never disables an FR-6.2 safety-critical path. The Free/Premium gates on Epics 3–4 consume this epic's `EntitlementService`.
**FRs covered:** FR-6.1, FR-6.2, FR-6.3, FR-6.4, FR-6.5, FR-6.6, FR-6.7, FR-6.8, FR-6.9, FR-6.10 | **Additional:** AD-13, AD-14, isolated Billing datastore | **UX-DRs:** UX-DR10, UX-DR11, UX-DR12
**Standalone:** depends only on Epic 1 (auth). Every gated feature runs in Free mode without it — no earlier epic requires it.
**Build phase-blockers (do not block story creation):** FR-6.7 price points, FR-6.8 post-downgrade retention policy, FR-3.3 and FR-5.3 legal/regulatory/clinical sign-off.

---

### 📅 MVP2 EPICS (Planned — post-MVP1)

### Epic 6: Tier-2 Outbound Emergency Dispatch (MVP2 - Planned)
On an unacknowledged > 30-second breathing-stop event, the platform dispatches priority SMS / voice to designated caregiver contacts and — routed by the patient's country / location, not US-911-only — the appropriate regional EMS Computer-Aided-Dispatch gateway. Premium-gated. MVP1 ships only the FR-3.3 cloud safety-signal log; caregiver contacts are already captured at onboarding.
**FRs covered:** FR-3.5 `[OPEN — legal/regulatory/clinical sign-off]` | **Status:** MVP2

---

### 🛑 UNPLANNED EPICS (Deferred Until Further Instruction)

### Epic 7: Backoffice Hardware Provisioning, Sensor Lost & Remote Wipe Operations (UNPLANNED)
Administrative backoffice for unbinding lost D-BAND serials, revoking paired BLE MAC bindings, managing WebAuthn session revocations, and driving the remote-wipe workflow (the on-device zeroization execution ships in Epic 1).
**FRs covered:** FR-1.10, FR-5.4 *(self-service portal)* | **Status:** UNPLANNED

### Epic 8: Clinic & Attending Physician Diagnostic Portal (UNPLANNED)
Dedicated physician web portal for reviewing patient Apnea Index trends, signing digital diagnostic notes, locking clinical charts, and full HL7 FHIR EHR/EMR synchronization — beyond the in-app "Share with Doctor" export module that ships in Epic 4.
**FRs covered:** FR-5.3 *(full EHR/portal integration)* | **Status:** UNPLANNED

### Epic 9: Multi-Mode Respiratory Applications (Athletic, Health Check, Meditation) (UNPLANNED)
Expanded Flutter application modes: Athletic Respiration Training (Mode B), Individual Respiratory Health Check (Mode C), Meditation & Breath Control (Mode D).
**FRs covered:** FR-1.9 *(Modes B, C, D)* | **Status:** UNPLANNED

### Epic 10: Cloud Big Data Analytics, Cloud AI & De-Identified Research Export (UNPLANNED)
Cloud big-data pipeline for de-identified research exports, PolyU/CUHK clinical-trial integration, and the Premium cloud AI respiration-waveform analytics engine (FR-2.5, which the client gates but does not build in MVP1).
**FRs covered:** FR-2.5, FR-4.5 | **Status:** UNPLANNED

---

## Detailed User Stories (MVP1 Active Epics — Epics 1–5)

> Regenerated this reconciliation against PRD v2.5.0 + EXPERIENCE.md/DESIGN.md v1.3.0. Cross-epic rule: every Premium-gated capability in Epics 3–4 ships its **Free behaviour by default**; Epic 5 Story 5.4 wires the `EntitlementService` gate that flips it to Premium when a valid claim is present. No epic requires a later epic to function.

### Epic 1: Mobile App Foundation, Settings & Biometric Passkey Onboarding

#### Story 1.1: Passkey FIDO2/WebAuthn Biometric Authentication
As a patient,
I want to authenticate passwordlessly using my device biometrics (Face ID / Touch ID / Android BiometricPrompt),
So that my PHI is protected under HIPAA §164.312 without a vulnerable password.

**Acceptance Criteria:**
- **Given** the app launches on `LoginPage`,
- **When** I tap "Sign in with Passkey",
- **Then** `AuthBloc` dispatches `AuthPasskeySubmitted` and triggers native OS biometric authentication (FIDO2/WebAuthn, hardware secure-enclave token).
- **And** on success the state transitions to `AuthAuthenticated` and navigates to `MainContainerPage`.
- **And** after 5 minutes of inactivity the session locks and re-authentication is required (NFR-4.1).
- **And** the screen is composed of `BrandHeaderOrganism`, `PasskeyAuthCardOrganism`, `SecurityBadgeOrganism`.

#### Story 1.2: Health Baseline, Patient Identification & Caregiver Setup (units-aware & HIPAA/FDA compliant)
As a patient,
I want to enter and edit my Full Name, Email Address, Phone Number, Age, Weight, Height, Gender, and Caregiver Contact details (Caregiver Name & Phone Number),
So that attending physicians and emergency dispatchers can identify me and reach my designated caregiver during a nocturnal apnea emergency under HIPAA §164.312 & FDA SaMD compliance rules.

**Acceptance Criteria:**
- **Given** I am on `MOB_USER_PROFILE` (first-run setup or Settings edit mode),
- **When** I enter Patient Identification details (Full Name, Email Address, Phone Number),
- **Then** the fields are validated (RFC 5322 Email regex, formatted phone regex) and stored in `PatientUser` as Level 1 PHI (`encrypted_full_name`, `encrypted_email`, `encrypted_phone`).
- **And** `HealthDemographicsOrganism` renders Weight and Height in the units selected in Story 1.5 (kg/lb, cm/ft-in) and recomputes BMI live.
- **And** `EmergencyContactOrganism` captures and preserves the Caregiver Name (`Maria Chen`) and Caregiver Phone Number (`(555) 019-2244`) stored in `HealthBaseline` (`encrypted_caregiver_name`, `encrypted_caregiver_phone`).
- **And** all profile data is protected under HIPAA 45 CFR § 164.312 technical safeguards (Passkey auth gate, AES-256 local SQLCipher & cloud KMS encryption at rest, TLS 1.3 in transit, non-blocking `PhiAuditLog` audit logging upon save).
- **And** first-run "Save & Continue" advances the onboarding wizard; from Settings, "Save" persists and back returns to `MOB_SETTINGS`.

#### Story 1.3: App Shell, 4-Tab Navigation & Nav Model
As a patient,
I want to move between Home, Monitor, Summary and Settings from a persistent bottom bar,
So that I can reach every part of the app in one tap.

**Acceptance Criteria:**
- **Given** I am authenticated on `MainContainerPage`,
- **When** I tap a tab in `PrimaryNavBarOrganism`,
- **Then** the shell switches destination without a page-push animation, the active tab shows `{colors.accent_green}`, and per-tab navigation state is preserved.
- **And** the bottom bar is **hidden** during onboarding and during `State_MonitoringActive` (Night Mode).
- **And** pushed detail screens (Profile, Language & Region, Billing, Payment Method, Waveform, History, Export) show a ‹ back affordance and **no** bottom bar (UX-DR14).
- **And** on every launch after onboarding the app lands on `MOB_HOME` (tab 1); first-run continues the onboarding chain instead.

#### Story 1.4: Grouped Settings Surface
As a patient,
I want a single Settings screen that groups my account, preferences and subscription controls,
So that everything configurable is in one predictable place.

**Acceptance Criteria:**
- **Given** I tap the Settings tab,
- **When** `MOB_SETTINGS` opens,
- **Then** it renders `SettingsSectionHeader` + `SettingsMenuRowOrganism` groups: **Account** (Profile), **Preferences** (Language & Region — trailing value "English"), **Subscription** (Billing & subscription — trailing plan name; Payment method — trailing "Visa ·· 4242" / "None").
- **And** the three headers always render; the **Advanced** section (Debugging / Developer rows) is omitted from the widget tree unless `debuggingMode || developerMode` (`State_SettingsDefault` vs `State_SettingsAdvanced`).
- **And** a build-flag change takes effect on the next entry to `MOB_SETTINGS`, not live.
- **And** navigable rows push their destination with a light haptic; inert rows have no chevron and a no-op tap.

#### Story 1.5: Language & Region + Measurement Units
As a patient,
I want to pick my app language, region and measurement units,
So that dates, numbers and my weight/height read the way I expect.

**Acceptance Criteria:**
- **Given** I open `MOB_LANGUAGE_REGION` from Preferences,
- **When** I open the App language sheet,
- **Then** English is selected above a dimmed, non-selectable "More languages coming soon" group (no translations ship this release).
- **And** the Region row opens a searchable country/region list; the choice drives app-wide date/number formatting and the **default** measurement system (US / Liberia / Myanmar → imperial; else metric).
- **And** changing Region after onboarding shows a confirm: "Date format and default units will update. Your saved profile values aren't converted."
- **And** the selected units + an IETF language tag persist per user server-side and apply immediately across all surfaces (governs Story 1.2 rendering).

#### Story 1.6: Developer README & Setup Guide
As a developer or contributor,
I want a `flutter/README.md` covering setup, dev/debug modes and release builds,
So that I can build and run the app without tribal knowledge.

**Acceptance Criteria:**
- **Given** the repository is cloned,
- **When** a developer opens `flutter/README.md`,
- **Then** it documents: product/architecture summary; quick start (`flutter pub get` / `flutter test` / `flutter run`); enabling Developer Mode (`--dart-define=DEV_MODE=true`); enabling Debugging Mode (`kDebugMode` / `debuggingEnabled`); and release APK builds.

#### Story 1.7: Developer Options Page & IDLE Band Signal Simulator
As a developer or tester,
I want simulator controls that reproduce the IDLE Band lifecycle and apnea cycles without hardware,
So that I can exercise calibration and the Tier-1 alarm end-to-end on any device.

**Acceptance Criteria:**
- **Given** `DEV_MODE=true`,
- **When** I open `MOB_SETTINGS` → Advanced → Developer → `DeveloperOptionsPage`,
- **Then** `DeveloperSimulatorBarOrganism` renders scenario chips: `IDLE Band Sample`, `Normal 16 bpm`, `In-Band (no excursion) >10s`, `Recovery 5s`.
- **And** tapping a chip emits a simulated stream into the process-wide `BehaviorSubject<double>` (via `BleTelemetryService`) so calibration, the IDLE-Band evaluator and the Night-Mode alarm can be triggered anywhere in the app.
- **And** the bar also renders at the top of `MeasurementPage` when `DEV_MODE=true`.

#### Story 1.8: On-Device Cryptographic Zeroization
As a patient whose phone is lost or under attack,
I want the app to wipe all local PHI on command or after repeated auth failure,
So that my sleep data cannot be recovered from the device.

**Acceptance Criteria:**
- **Given** the app receives a cloud session-revocation signal **or** 10 consecutive failed Passkey attempts occur,
- **When** the zeroization routine runs,
- **Then** it deletes all local SQLCipher database files and Hive key-value stores and destroys cached encryption keys in the OS secure enclave / Android Keystore within < 1 second (NFR-4.3).
- **And** the app returns to `LoginPage` with no cached session.
- *(The self-service web portal that originates the revocation is Epic 7 / UNPLANNED; this story covers only the on-device execution.)*

#### Story 1.9: First-Run Onboarding Wizard & Fresh-User Routing
As a new patient,
I want a guided multi-step setup after my first passkey sign-in,
So that my account, medical profile, and passkey exist before I reach the dashboard.

**Acceptance Criteria:**
- **Given** login succeeds and `ProfileRepository.fetchUserProfile()` returns `null` (new or just-unregistered user), **when** `AppFlowBloc` resolves, **then** it enters a new `AppFlowStage.onboarding` rendering `OnboardingWizardPage` — **not** `MainContainerPage`.
- **Given** a `UserProfile` exists (returning user), **when** login succeeds, **then** the app goes straight to `ready` / `MOB_HOME` (current behaviour); onboarding is skipped.
- **Given** the wizard, **then** it renders an ordered stepper — (1) Register, (2) Medical Profile, (3) Passkey Enrollment, (4) Ready — with a progress indicator and **no** bottom nav (UX-DR14); the ‹ back affordance moves between steps.
- **Given** a step's "Save & Continue", **then** the wizard persists that step and advances; "Back" returns to the previous step without losing entered data.
- **Given** the "Ready" step completes, **then** `AppFlowBloc` transitions to `ready` and the app lands on `MOB_HOME`.
- **Given** the app is killed mid-onboarding and relaunched, **then** login returns the user to the first incomplete step (onboarding is resumable).
- **Given** `SettingsActions.unregisterAccount` has run (or a first-ever launch), **then** `SimulatedProfileRepository` tracks the account as unregistered so `fetchUserProfile()` returns `null` — the demo `demoUserProfile` payload is returned only for a "seeded returning user" test fixture, never by default. This replaces the current G2 behaviour where `ProfileSession.hydrate()` always re-seeds the demo profile.
- **Depends on:** Story 1.1 (auth), Story 1.2 (profile form), Story 1.10, Story 1.12.

#### Story 1.10: Patient Account Registration (`Task_PatientRegister`)
As a new patient,
I want to create my account identity as onboarding step 1,
So that a `PatientUser` record exists to attach my profile and passkey to.

**Acceptance Criteria:**
- **Given** onboarding step 1, **when** I accept the HIPAA §164.312 consent and confirm, **then** `ProfileRepository.registerUser()` (new — simulated: returns a `UserProfile` with a fresh `userId` and empty PHI) is called, `UserProfileService.instance.set()` stores it, and the wizard advances to Medical Profile.
- **Given** `registerUser()` fails, **then** an error is shown and the step does not advance.
- **Given** a returning user (Story 1.9 routed them past onboarding), this step never renders.

#### Story 1.11: Medical Profile — First-Run Mode
As a new patient,
I want onboarding step 2 to be the `MOB_USER_PROFILE` form in first-run mode,
So that I set my identity, demographics, and caregiver contact before monitoring.

**Acceptance Criteria:**
- **Given** onboarding step 2, **then** it renders the Story 1.2 profile form in first-run mode: primary CTA "Save & Continue" (advances the wizard), no AppBar tick, no back-to-Settings.
- **Given** "Save & Continue", **then** the entered profile is saved via `ProfileRepository.saveUserProfile()` and the wizard advances to Passkey Enrollment.
- **Given** required fields are empty or invalid (RFC 5322 email, formatted phone), **then** "Save & Continue" is blocked with inline errors.
- **Note:** this is the first-run half of Story 1.2; the Settings edit-mode half already ships (with `_save` persistence).

#### Story 1.12: Passkey Enrollment Step (`Task_RegisterPasskey`)
As a new patient,
I want to enroll a FIDO2 passkey during onboarding,
So that later sign-ins use my device biometrics.

**Acceptance Criteria:**
- **Given** onboarding step 3, **when** I tap "Create Passkey" with the **Passkey Simulator** flag ON (dev), **then** a simulated enrollment succeeds after a brief delay; with the flag OFF, real WebAuthn registration runs (the FIDO path the Passkey Simulator toggle scaffolds).
- **Given** enrollment succeeds, **then** `ProfileRepository.enrollPasskey()` (new — simulated) records `passkey_credential_id` on `PatientUser` and the wizard advances to "Ready".
- **Given** enrollment fails or the biometric prompt is cancelled, **then** the step shows a retry and does not advance.
- **Given** a returning user, this step never renders.

---

### Epic 2: BLE Sensor Discovery, Pairing & IDLE Band Calibration

#### Story 2.1: Bluetooth Background-Access Priming & Permission Recovery
As a patient,
I want to understand why the app needs Bluetooth before the OS asks, with a clear recovery path if I decline,
So that the background receiver gets the permission it depends on and a denial doesn't leave me on a broken screen.

**Acceptance Criteria:**
- **Given** the first app launch after Profile Setup,
- **When** the user reaches `MOB_BLE_PERMISSION_PRIMER`,
- **Then** it shows reassuring rationale copy and one primary CTA ("Allow Bluetooth Access"), no skip path.
- **And** the CTA hands off to the native OS flow (Android: sequential `BLUETOOTH_SCAN` then `BLUETOOTH_CONNECT`; iOS: `bluetooth-central` disclosure).
- **And** on full grant the app proceeds to `MOB_DEVICE_PAIRING` and the receiver service (Story 2.2) becomes eligible to start on this and all future boots.
- **And** on denial or partial grant, `MOB_DEVICE_PAIRING` renders a blocked state naming the missing permission with an "Open Settings" deep-link in place of the scan UI (`State_BlePermissionDenied` / `State_BlePermissionPartial`).
- **And** when the OS will not reissue its dialog (iOS one-shot, Android "Don't ask again"), the primer CTA routes straight to the "Open Settings" deep-link.

#### Story 2.2: App-Boot BLE Receiver Service & Unified RxDart Queue
As the background monitoring service,
I want a single process-wide bio-signal queue started at app boot,
So that calibration, the wear check and 8-hour monitoring all consume one stream regardless of source.

**Acceptance Criteria:**
- **Given** the app completes boot with Bluetooth permission granted,
- **When** the BLE background receiver service starts (Android Foreground Service `connectedDevice`/`dataSync` with persistent notification; iOS `UIBackgroundModes: bluetooth-central`),
- **Then** exactly one `IBLESensorDriver` is bound by constructor DI and every inbound sample — physical GATT notification **or** `BleTelemetryService` tick — is pushed via RxDart `.add()` into a single process-wide `BehaviorSubject<double>` exposed as a `ValueStream<double>`.
- **And** no consumer opens its own BLE subscription or second queue; the queue identity is stable across a driver swap.
- **And** the service and queue survive `EndSession` (which calls `stopTelemetryLogging()` only) so they are ready for the next session.
- **And** a persistent `BleReceiverForegroundNotification` ("Sleep Monitoring Ready — D-BAND connection active, you're covered tonight") is shown while the service runs; a `BleNotProtectedNotification` ("Bluetooth Permission Needed — Tap to fix.") is shown instead when it cannot start — never left to be inferred from a missing notification.
- **And** during `State_MonitoringActive` the root semantics node carries "Sleep monitoring active — D-BAND connected".

#### Story 2.3: Encrypted BLE Discovery, Pairing & Cloud Device Binding
As a patient,
I want the app to find and pair my D-BAND and register it with the cloud,
So that my sensor is bound to my account and its data is trusted.

**Acceptance Criteria:**
- **Given** Bluetooth permission is granted and I am on `MOB_DEVICE_PAIRING`,
- **When** the app scans for the `0x180D` service / `0x2A37` characteristic,
- **Then** it auto-discovers and pairs the D-BAND with an AES-128-secured link and `BleSensorStatusOrganism` shows "D-BAND connected ✓" (vs "Scanning…").
- **And** on pairing the app calls `POST /api/v1/devices/bind` with an encrypted payload (`user_profile_id`, `device_hardware_id`, `ble_mac_address`, `binding_timestamp`).
- **And** the physical radio link may be established lazily and is then held alive by the Foreground Service for the session (preserving the < 8% / 8h battery budget).

#### Story 2.4: Offline Device-Binding Queue
As a patient pairing without connectivity,
I want the binding to complete later automatically,
So that a weak signal at bedtime doesn't block me from monitoring.

**Acceptance Criteria:**
- **Given** pairing succeeds but there is no internet,
- **When** `POST /api/v1/devices/bind` cannot be sent,
- **Then** the encrypted payload is queued in a local encrypted buffer and the UI proceeds (pairing is not blocked on the bind call).
- **And** on network restoration the queued payload is transmitted and acknowledged, and a duplicate bind is idempotent.

#### Story 2.5: Sensor Baseline Drift & Noise Floor Envelope Calibration & Wear Check
As a patient,
I want a short calibration that learns my resting signal band and confirms the sensor is on me,
So that the night's apnea detection has a valid per-session reference.

**Acceptance Criteria:**
- **Given** I am on `MOB_CALIBRATION` with the D-BAND worn,
- **When** step 1 (`State_CalibratingIdleBand`) runs, the app asks me to sit still and breathe gently for ~10 s and tracks the running **minimum** and **maximum** of the raw signal,
- **Then** it stores the session **IDLE Band** `[lower_bound, upper_bound]` (each sample only widens the band within the window).
- **And** step 2 (`State_WearCheck`) asks me to take a few normal breaths and requires **≥ 2 valid breath-excursion cycles** — signal ≥ `upper_bound` on inhale **and** ≤ `lower_bound` on exhale — before "Start Sleep Monitoring" unlocks.
- **And** if fewer than 2 cycles are seen within the check window it holds the gate and shows the toast "Sensor not detecting breathing — check the fit." with a Retry.
- **And** on success the screen shows "Calibration Complete — Ready for Sleep ✓".
- **And** there is no active-breath training step, no `V_pp` and no litres-per-second transform anywhere in the flow.
- **And** the stored IDLE Band is reused on later sessions and re-run only on the first session or when it is stale/invalid.

---

### Epic 3: Nocturnal Sensor Baseline Drift & Noise Floor Envelope Monitoring & Tier-1 Local Alarm

#### Story 3.1: Pre-Session "Start Sleep Monitoring" State
As a patient starting a night,
I want a clear Start control on the Monitor tab that is distinct from the sleeping lock screen,
So that beginning a session is deliberate and obvious.

**Acceptance Criteria:**
- **Given** I switch to the Monitor tab with no active session,
- **When** `MOB_SLEEP_MONITOR` renders its pre-session state,
- **Then** it shows a primary "Start Sleep Monitoring" action (distinct from the Night Mode lock).
- **And** tapping it runs the Story 2.5 calibration only if there is no valid stored IDLE Band, then goes straight to active monitoring.
- **And** this state is visually separate from `State_MonitoringActive`.

#### Story 3.2: Low-Power 0-FPS Night Mode & Continuous Raw-Signal Logging
As a high-risk nocturnal apnea patient,
I want continuous 10 Hz logging behind a pitch-black 0-FPS screen,
So that my breathing is watched all night without draining my phone.

**Acceptance Criteria:**
- **Given** active monitoring is launched,
- **When** Night Mode activates,
- **Then** the screen throttles to 0-FPS pure black (`#000000`) with a dim pulsing indicator and `PrimaryNavBarOrganism` is hidden.
- **Then** the 10 Hz raw signal is logged continuously into a 1-hour circular RAM ring buffer, and timestamped packets are buffered in hardware-encrypted storage across brief signal gaps (FR-2.4).
- **And** total consumption over an 8–10 h session stays < 8.0% phone battery; FFT/heavy math runs on background Dart Isolates (NFR-3.x).
- **And** BLE auto-reconnects within 3.0 s of a drop (NFR-1.1).

#### Story 3.3: 100 ms Noise Floor Envelope Apnea Evaluator
As a patient,
I want the app to test every 100 ms whether I'm actually taking breaths,
So that a real breathing stop is caught within seconds.

**Acceptance Criteria:**
- **Given** the raw signal is streaming and a session IDLE Band exists,
- **When** the evaluator runs every 100 ms,
- **Then** it classifies each interval as a **valid breath excursion** (signal ≥ `upper_bound` on inhale AND ≤ `lower_bound` on exhale within a cycle) or a **"stop-breathing" interval** (signal stays inside `[lower_bound, upper_bound]`).
- **And** when no valid excursion occurs for **≥ 10 s continuously**, `ApneaEvaluator` flags an apnea event and transitions to `breachAlert` (the AASM 10-second duration standard; NFR-6.1).
- **And** the evaluator consumes the Story 2.2 shared stream only and opens no BLE subscription of its own.

#### Story 3.4: Tier-1 Local Siren, "I'm Safe" Tap & Auto-Silence
As a patient,
I want an escalating local alarm on an apnea event, a big dismiss button, and automatic silence when I recover,
So that I'm woken to breathe and not left with a blaring phone once I have.

**Acceptance Criteria:**
- **Given** `ApneaEvaluator` flags an apnea event,
- **When** `ApneaAlertBannerOrganism` renders within **< 200 ms** (NFR-2.1),
- **Then** it shows a full-screen high-contrast overlay, overrides volume to an escalating 40 dB → 75+ dB siren, pulses the haptic motor, and runs a 30 s countdown.
- **And** the alarm priority follows IEC 60601-1-8: medium for 10–20 s, high for > 20 s (NFR-6.2).
- **And** tapping the 64 dp "I'M SAFE" button silences the siren immediately and writes a local safety-tap event to the session trace.
- **And** if valid Noise Floor Envelope breath excursions resume continuously for 5 s with no tap, the alarm auto-silences (FR-3.4).
- **And** `apnea_alarm_count` / `alarm_fired` for the session is incremented/set the first time `State_ApneaBreach` is reached.

#### Story 3.5: Cloud Safety-Signal Log (Premium, log-only)
As a patient on Premium,
I want my "Patient Awake & Safe" and unacknowledged-timeout events recorded in the cloud,
So that there is a server-side record of the night's events (no one is contacted in MVP1).

**Acceptance Criteria:**
- **Given** an "I'm Safe" tap within 30 s, **or** an unacknowledged 30 s timeout,
- **When** the client holds a valid Premium entitlement claim (Epic 5 Story 5.3),
- **Then** it transmits the corresponding status signal to the cloud within < 1.5 s on an available connection (NFR-2.2), where it is **logged with no outbound action**.
- **And** on the Free tier (no claim) the event is written to the **local trace only** and nothing is transmitted.
- **And** on a transport failure the client does not block, retry aggressively, or alter the local alarm behaviour.
- **And** this story ships gated to Free behaviour by default; Epic 5 Story 5.4 supplies the claim check. `[OPEN — legal/regulatory/clinical sign-off before the Premium gate ships]`.

---

### Epic 4: Home Dashboard, Morning Analytics & Respiration Waveform

#### Story 4.1: SessionSummary Write on Finalization
As the platform,
I want a compact per-night rollup written when a session ends,
So that the dashboard and history read from one authoritative record, not raw telemetry.

**Acceptance Criteria:**
- **Given** a session is finalized (`Task_EndSession` / `State_MorningSummary`),
- **When** the rollup is computed,
- **Then** a `SessionSummary` `{date, ai_score, quality_score, total_duration, apnea_alarm_count, safety_tap_count, alarm_fired}` is written to the cloud Isolated Data Zone (1:1 with `SleepSession`, Level 1 PHI) as source of truth (AD-15).
- **And** the device keeps a local rolling cache of the last N (N ≥ 7) summaries for offline reads.
- **And** `alarm_fired` is written once at finalization from whether `State_ApneaBreach` was reached, and is never re-derived at read time.

#### Story 4.2: Morning Sleep Summary — Apnea Index, Caveat & Alarm-Fired Awareness
As a patient,
I want a morning summary that shows my apnea score honestly and flags a night my alarm went off,
So that I understand what happened without being misled or alarmed after the fact.

**Acceptance Criteria:**
- **Given** I open `MOB_SLEEP_SUMMARY` (Summary tab root, or right after a session),
- **When** it renders from the Story 4.1 `SessionSummary`,
- **Then** the score card shows the **Apnea Index (AI)** ring, a severity badge (Normal < 5 / Moderate 5–29.9 / Severe ≥ 30 — standard AHI bands applied to the AI), and Total Sleep Duration, Intervention Count, Quality Score.
- **And** an always-present apnea-only caveat line appears under the score card, in the exact wording defined in EXPERIENCE.md §Voice and Tone, and is carried into the doctor report.
- **And** when `apnea_alarm_count ≥ 1` the card switches to the alarm-fired override: an amber "N apnea alert(s)" pill replaces the severity pill, the severity word drops to the clinical caption, the apnea-events stat and score ring turn amber — regardless of AI band; the screen-reader label leads with the alarm.
- **And** the header carries a History pill → `MOB_HISTORY_FILTER`, the Respiration Waveform card is a single tap target ("View details ›") → `MOB_GRAPH_WAVEFORM`, and the "Export Signed Report" button routes per Story 4.6.

#### Story 4.3: Home Dashboard
As a patient,
I want a read-only home screen that tells me how last night went, whether my sensor is ready, and my trend,
So that I get the whole picture in a few seconds without touching anything.

**Acceptance Criteria:**
- **Given** I open the app after onboarding,
- **When** `MOB_HOME` renders,
- **Then** `HomeDashboardBloc` assembles the view from the local last-N `SessionSummary` cache (AD-15) and the Story 2.2 receiver-service state only — it opens **no** BLE subscription and issues **no** network read on load.
- **And** it shows: a greeting + monitoring-streak line; `HomeSummaryCardOrganism` (last-night AI + severity pill / alarm-fired override, Duration + Apnea-events stats, whole card taps → `MOB_SLEEP_SUMMARY`); `DeviceStatusCardOrganism` (nominal inert green / actionable red-amber for unreachable, battery ≤ 15%, or permission missing — actionable card routes to `MOB_DEVICE_PAIRING` blocked state or the Settings deep-link); `WeeklyTrendCardOrganism` (7-slot `fl_chart` bar strip + descriptive-only delta line, non-diagnostic; < 2 nights → "Not enough data yet"; tap → `MOB_HISTORY_FILTER`).
- **And** the states `State_HomeDefault` / `State_HomeEmpty` / `State_HomeNoDevice` / `State_HomeDeviceAlert` render per EXPERIENCE.md; each card exposes one composite accessibility label.
- **And** there is no start control and no quick-links row on Home.

#### Story 4.4: Session History Filter (Free 7-day local)
As a patient,
I want to browse and date-filter my past sessions,
So that I can see how I've been trending.

**Acceptance Criteria:**
- **Given** I open `MOB_HISTORY_FILTER` from the Summary header,
- **When** the list renders,
- **Then** each row is a `SessionHistoryListItem` (date, duration, colour-coded "AI n.n Normal/Moderate/Severe" badge, chevron) and a calendar/date-range control filters the list.
- **And** on the **Free** tier only the rolling **7-day** on-device window is shown; sessions older than 7 days are discarded locally with no cloud backup or archive.
- **And** unlimited history + cloud backup/archive is the Premium behaviour, wired by Epic 5 Story 5.4; absent a claim this screen shows the 7-day window.
- **And** `MOB_HISTORY_FILTER` is a pushed detail screen (‹ back, no bottom nav), returning to `MOB_SLEEP_SUMMARY`.

#### Story 4.5: Educational Library
As a patient,
I want short articles and videos about sleep-disordered breathing,
So that I can understand my results and the condition.

**Acceptance Criteria:**
- **Given** I open the Educational Library,
- **When** it renders,
- **Then** `HealthInsightsOrganism` lists article/video cards with titles and thumbnails, opening a reader/player view on tap.
- *(Free and Premium.)*

#### Story 4.6: Interactive Waveform + FFT (Premium) with Free Thumbnail
As a patient,
I want to scrub my overnight breathing trace and see its rhythm,
So that I can look closely at the apnea episodes.

**Acceptance Criteria:**
- **Given** I tap the Respiration Waveform card,
- **When** `MOB_GRAPH_WAVEFORM` opens **with** a valid Premium claim,
- **Then** it renders the raw bio-signal at 60 FPS (`fl_chart` / Skia) with the Noise Floor Envelope `lower_bound` / `upper_bound` as horizontal reference lines, pinch/zoom/pan, a 256-point FFT view (computed on the raw signal for BPM), and colour-coded apnea/safety markers; an apnea shows as a flat trace held between the band lines.
- **And** **without** a claim (Free), the card shows a non-interactive current-night thumbnail and the summary metrics only.
- **And** the screen carries no litres-per-second axis anywhere.
- **And** it is a pushed detail screen (‹ back, no bottom nav).

#### Story 4.7: Doctor Report Export (free basic + Premium enhancements)
As a patient,
I want to send a signed report of my sleep data to my doctor,
So that they can review it — without a paywall on my own health record.

**Acceptance Criteria:**
- **Given** I tap "Export Signed Report for Physician" on `MOB_SLEEP_SUMMARY`,
- **When** `MOB_EXPORT_DOCTOR` runs,
- **Then** a **basic signed FHIR JSON + PDF** of the selected session (AI, metrics, apnea-only caveat, waveform image) is generated, HIPAA-audited (`action_type = "EXPORT_DOCTOR_REPORT"`), and handed to the native OS share sheet — **available on Free and Premium**.
- **And** Premium **enhancements** (multi-visit trend analytics, date-range / bulk export, richer formatting) are gated via Epic 5 Story 5.4; on Free the enhancement controls show a lock and route to `MOB_BILLING`.
- **And** `[OPEN — legal sign-off, HIPAA §164.524]`: `bmad-build` must not ship any gate that blocks a patient's basic access to their own PHI until Privacy/Legal sign-off; this story's default (basic export always free) is the standing fallback.
- **And** `MOB_EXPORT_DOCTOR` is a pushed detail screen (‹ back, no bottom nav).

---

### Epic 5: Subscription, Billing & Entitlement

#### Story 5.1: Backend Billing Service & Isolated Billing Datastore
As the platform,
I want subscription state owned by one backend service in an isolated store,
So that entitlement has a single source of truth and no billing data mixes with PHI.

**Acceptance Criteria:**
- **Given** the backend platform,
- **When** the Billing subsystem is provisioned,
- **Then** a `BillingService` and a dedicated relational **Billing datastore** hold `Subscription`, `PaymentMethodRef`, `Invoice`, `Entitlement` (Level 3 Financial PII, referencing `user_id` only) on a separate instance / VPC in the App Core zone — **not** the PHI Isolated Data Zone (AD-13).
- **And** the store contains **no PHI and no cardholder data**; `PaymentMethodRef` holds only `brand` + `last4` + `exp_month`/`exp_year` + opaque `stripe_payment_method_id` (AD-14).
- **And** `BillingService` exposes read APIs for plan + card-on-file display triplet + invoice list, and issues **signed entitlement claims**; it never executes payment (Stripe does).
- **And** egress is allowlisted to add `api.stripe.com`.

#### Story 5.2: Stripe Webhook Receiver (HMAC-verified, sole writer)
As the platform,
I want subscription state changed only by verified Stripe events,
So that a forged request cannot grant Premium.

**Acceptance Criteria:**
- **Given** `StripeWebhookReceiver` deployed at the edge behind the WAF/CDN (Cloud Functions v2 / Cloud Run behind Cloud Armor),
- **When** a `customer.subscription.*` or `invoice.*` event arrives,
- **Then** it verifies the `Stripe-Signature` (HMAC-SHA256) against the endpoint secret, checks timestamp tolerance, and enforces idempotency-key replay protection before forwarding.
- **And** it is the **only** writer of subscription state into the Billing datastore; the client can never mutate it.
- **And** every processed event is mirrored to a webhook audit log (`id`, `type`, `signature-verified`, `applied-at`).
- **And** an event that fails verification is rejected with no state change and is logged.

#### Story 5.3: Client Entitlement Service — Signed Claim + Bounded Offline Grace
As the client,
I want a cached, signed proof of the user's plan that degrades safely offline,
So that Premium gates are correct without ever blocking a safety-critical path.

**Acceptance Criteria:**
- **Given** `EntitlementService` on the client,
- **When** it fetches the entitlement claim from `BillingService`,
- **Then** it stores the **signed, short-TTL** claim and exposes `isPremium(feature)` to gate consumers.
- **And** a gated action re-checks entitlement server-side; on a **transport failure** it falls back to the cached claim within a **bounded grace window** (fail-open for connectivity), but a **known-expired** claim fails closed.
- **And** loss of connectivity or an expired claim shall **never** disable any FR-6.2 safety-critical capability (monitoring, evaluator, Tier-1 alarm, "I'm Safe" local trace, auto-silence, calibration, Morning Summary of the just-finished night, 7-day history, Home dashboard, auth/profile/pairing).
- **And** the client never derives entitlement from raw Stripe objects.

#### Story 5.4: Tier Model & Free/Premium Feature Gates
As a patient,
I want the app to behave correctly for my plan,
So that Free is fully usable and Premium unlocks the extras.

**Acceptance Criteria:**
- **Given** the tier model (Free by default; single paid Premium product; **no free trial**),
- **When** a gated capability is invoked,
- **Then** the gate consults `EntitlementService` (Story 5.3): Premium-only = cloud safety-signal log (Story 3.5), interactive waveform + FFT (Story 4.6), history beyond 7 days + cloud archive (Story 4.4), doctor-report enhancements (Story 4.7), cloud AI analytics entitlement (FR-2.5), advanced trend analytics.
- **And** with no claim every one of those falls back to its Free behaviour already built in Epics 3–4 — no crash, no dead UI.
- **And** an automated guard-test suite asserts that on a Free build the Tier-1 alarm, evaluator, "I'm Safe" local trace, auto-silence, calibration and Morning Summary all fire on true apnea stops regardless of subscription state (FR-6.2).

#### Story 5.5: Billing & Subscription Screen
As a patient,
I want to see my plan, price, renewal date and a plain Cancel control,
So that I always know what I'm paying for and can stop without a maze.

**Acceptance Criteria:**
- **Given** I open `MOB_BILLING` from Settings → Subscription,
- **When** it renders,
- **Then** `SubscriptionPlanCardOrganism` shows `State_SubscriptionPremium` (plan "Premium" + "Active" pill + price/cycle + "Renews {date}"; if `cancelPending`, amber "Ends {date}" pill and a "Resume Premium" action) or `State_SubscriptionFree` (plan "Free", no renewal line, primary "Upgrade to Premium").
- **And** a "what Premium includes" checklist renders (muted preview on Free), a payment-method summary row → `MOB_PAYMENT_METHOD`, and a "View invoices" row (destination deferred).
- **And** billing state is fetched on entry with an inline skeleton; the UI never optimistically shows "Premium" before the server confirms.
- **And** it is a pushed detail screen (‹ back, no bottom nav).

#### Story 5.6: Payment Method Management via Hosted PaymentSheet
As a patient,
I want to add or replace my card without ever typing it into this app,
So that my card data stays with Stripe and the app stays PCI SAQ-A.

**Acceptance Criteria:**
- **Given** I open `MOB_PAYMENT_METHOD`,
- **When** a card is on file (`State_PaymentMethodOnFile`),
- **Then** `PaymentMethodCardOrganism` shows brand mark + "·· ·· ·· {last4}" + "Expires mm / yy" + cardholder — **never** the full PAN or CVC.
- **And** "Replace card" / "Add card" launches Stripe's **hosted PaymentSheet**; the app passes a client secret and receives back only a payment-method token (no PAN/CVC crosses into the app — AD-14); on success the card updates in place with a transient "Card updated".
- **And** "Remove card" (`{colors.danger_red}` text) shows a consequence-naming confirm ("Premium can't renew… will move to Free on {date}"), then calls the backend detach endpoint → `State_PaymentMethodEmpty` ("No payment method on file." + "Add card").
- **And** dismissing the sheet without completing is a no-op — the existing card stands.

#### Story 5.7: Upgrade to Premium
As a Free patient,
I want to upgrade to Premium in a few taps,
So that I get the cloud and analytics features.

**Acceptance Criteria:**
- **Given** I tap "Upgrade to Premium" on `MOB_BILLING` (or a Free feature-gate route),
- **When** no valid card is on file,
- **Then** the flow routes through the Story 5.6 hosted PaymentSheet, then creates the subscription via `BillingService`; when a card exists it applies immediately.
- **And** the client re-fetches entitlement and does not show "Premium" until the `StripeWebhookReceiver` (Story 5.2) has confirmed the state server-side.
- **And** monthly and discounted-annual plan options are presented `[ASSUMPTION — price points pending]`.

#### Story 5.8: Cancel-at-Period-End & Downgrade Transparency
As a patient cancelling,
I want to keep what I paid for until the period ends and know exactly what I'll lose,
So that cancelling is honest and predictable.

**Acceptance Criteria:**
- **Given** I tap "Cancel subscription" on `MOB_BILLING`,
- **When** the confirm dialog appears,
- **Then** it names the paid-through date ("You'll keep Premium until {date}, then move to Free") with no retention interstitial and no dark pattern — one confirm.
- **And** before the cancellation (or any downgrade) completes, the app discloses in plain language which capabilities are lost and when — cloud safety-signal log, history beyond 7 days, doctor-report enhancements, cloud AI analytics, interactive timeline; and Tier-2 dispatch once it ships in MVP2 — and confirms all FR-6.2 safety-critical local capabilities are unaffected.
- **And** on confirm the account keeps Premium entitlement until `current_period_end` (driven by the Story 5.2 webhook), then transitions to Free — no mid-period downgrade.
- **And** on transition to Free, cloud-archived history beyond the 7-day window is retained but not user-visible until re-subscription `[ASSUMPTION — retention/deletion policy pending legal]`.
