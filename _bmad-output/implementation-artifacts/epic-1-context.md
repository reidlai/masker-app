# Epic 1 Context: Mobile App Foundation, Settings & Biometric Passkey Onboarding

<!-- Compiled from planning artifacts (PRD v2.5.0, ARCHITECTURE-SPINE.md v21.0.0, EXPERIENCE.md/DESIGN.md v1.3.1, epics.md). Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Patients register passwordlessly with FIDO2 Passkey biometrics (Face ID / Touch ID / BiometricPrompt), set up a units-aware health baseline profile with Patient Identification (Full Name, Email Address, Phone Number) and Caregiver Contact details (Caregiver Name & Phone) under HIPAA §164.312 & FDA SaMD compliance rules, navigate the `flutter_shadcn` dark glassmorphic shell and its four tabs, open a grouped Settings surface (Account / Preferences / Subscription / conditional Advanced), choose Language & Region and measurement units, and reach the Developer Options page. Includes the on-device sub-1-second cryptographic zeroization routine and the developer README.

## Stories

- Story 1.1: Passkey FIDO2/WebAuthn Biometric Authentication
- Story 1.2: Health Baseline, Patient Identification & Caregiver Setup (units-aware & HIPAA/FDA compliant)
- Story 1.3: App Shell, 4-Tab Navigation & Nav Model
- Story 1.4: Grouped Settings Surface
- Story 1.5: Language & Region / Measurement Units

## Requirements & Constraints

- **FR-5.1:** Passkey FIDO2/WebAuthn authentication — passwordless login via native OS biometrics and hardware secure enclave tokens.
- **FR-5.2:** Health Profile Management — Patient Full Name (`full_name`), Patient Email (`email`), Patient Phone Number (`phone_number`), Weight, Height, Age, Gender, computed BMI, Caregiver Name (`caregiver_name`), and Caregiver Emergency Phone Number (`caregiver_phone`). Weight/Height are captured, stored, and displayed in the units selected in FR-5.7 (kg/lb, cm/ft-in); a single canonical unit is persisted server-side and converted for display. Protected under HIPAA 45 CFR § 164.312 & FDA SaMD rules (AES-256 encryption at rest, TLS 1.3 in transit, Passkey access gate, and `PhiAuditLog` audit logging).
- **FR-5.4:** On-device sub-1-second cryptographic remote zeroization protocol deleting local SQLCipher databases, Hive stores, and Secure Enclave master keys upon remote wipe signal or 10 failed auth retries.
- **FR-5.7:** Language & Region screen for app display language and measurement units (kg/lb, cm/ft-in).
- **FR-5.8:** Grouped Settings screen (Account, Preferences, Subscription, conditional Advanced).

## Technical Decisions

- **AD-01:** Atomic Design System Hierarchy across UI Atoms, Molecules, Organisms, and Page Templates.
- **AD-03:** FIDO2 / WebAuthn passwordless biometric authentication enforcing HIPAA 45 CFR § 164.312 access controls.
- **AD-09:** AES-256 SQLCipher local database encryption at rest, HTTPS TLS 1.3 in transit.
- **Level 1 PHI Data Model:** `PatientUser` (`encrypted_full_name`, `encrypted_email`, `encrypted_phone`), `HealthBaseline` (`age`, `weight_kg`, `height_cm`, `computed_bmi`, `encrypted_caregiver_name`, `encrypted_caregiver_phone`).

## UX & Interaction Patterns

- **`MOB_PASSKEY_AUTH`**: Login landing with FIDO2 passkey CTA.
- **`MOB_USER_PROFILE`**: Health Baseline & Patient Identification setup page. Input fields for Patient Full Name, Email, Phone, Age, Weight, Height (computed BMI live), and Caregiver Name & Phone Number.
- **`MOB_SETTINGS`**: Grouped Account, Preferences, and Subscription sections.

## Cross-Story Dependencies

- Story 1.1 provides the passkey session token.
- Story 1.2 relies on unit preferences from Story 1.5.
- Story 1.3 provides the shell navigation for Settings (Story 1.4).
