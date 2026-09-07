---
title: 'Epic 1 Story 1.2: Health Baseline, Patient Identification & Caregiver Setup (units-aware & HIPAA/FDA compliant)'
type: 'feature'
created: '2026-09-07'
status: 'done'
baseline_commit: '93b8b3a2c80c2d0f2fe892007c455593f12b51b0'
review_loop_iteration: 0
context:
  - _bmad-output/implementation-artifacts/epic-1-context.md
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The patient profile setup on `MOB_USER_PROFILE` (`ProfilePage`) captures health baseline demographics (age, weight, height) and caregiver phone, but needs to explicitly present and capture Patient Identification (Full Name, Email Address, Phone Number) and Caregiver Name under HIPAA 45 CFR § 164.312 and FDA SaMD compliance rules so attending physicians and emergency dispatchers can identify the patient during an emergency.

**Approach:** Update `HealthDemographicsOrganism`, `EmergencyContactOrganism`, and `ProfilePage` to support Patient Identification (Full Name, Email Address, Phone Number) and Caregiver Contact details (Caregiver Name, Caregiver Phone Number). Enforce client-side RFC 5322 Email and formatted phone validation, live BMI recalculation, unit conversion readiness, and HIPAA Level 1 PHI data security principles.

## Boundaries & Constraints

**Always:**
- All code and commands run from the `flutter/` directory.
- Use constructor dependency injection for text controllers or models so widget tests can mock input states.
- Maintain 100% pass rate on `flutter test`.
- Full Name, Email, Phone, Age, Weight, Height, and Caregiver details are treated as Level 1 PHI (AES-256 encryption at rest, TLS 1.3 in transit, Passkey access gate, non-blocking `PhiAuditLog` audit logging).

**Ask First:**
- Modifying existing database persistence schemas or breaking existing `ProfilePage` widget tests.

**Never:**
- Store unencrypted PHI in plain text local preferences; bypass FIDO2 Passkey access controls.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Valid Patient Identity & Caregiver Contact | Name: `David Miller`, Email: `david.miller@example.com`, Phone: `(555) 019-8234`, Caregiver: `Maria Chen` `(555) 019-2244` | Inputs accepted, BMI computed live, Snackbar confirmation "Health profile saved ✓". | N/A |
| Live Weight/Height Recalculation | Weight: 85kg -> 90kg | BMI updates live from 26.8 to 28.4. | Invalid numeric input ignored |

</frozen-after-approval>

## Code Map

- `lib/ui/pages/profile_page.dart` -- ProfilePage StatefulWidget managing patient identification and caregiver text controllers and rendering UserHeaderOrganism, HealthDemographicsOrganism, and EmergencyContactOrganism.
- `lib/ui/organisms/health_demographics_organism.dart` -- Organism component rendering Patient Identification (Full Name, Email, Phone) and Health Baseline Demographics (Age, Weight, Height, Computed BMI).
- `lib/ui/organisms/emergency_contact_organism.dart` -- Organism component rendering Caregiver Name & Caregiver Phone Number inputs.
- `test/ui/profile_page_test.dart` -- Widget test suite verifying profile rendering, input field values, and live BMI computation.

## Tasks & Acceptance

**Execution:**
- [x] `lib/ui/organisms/health_demographics_organism.dart` -- Ensure Patient Full Name, Email Address, and Phone Number fields are integrated -- Enables patient identity capture for physician reports and emergency alerts.
- [x] `lib/ui/organisms/emergency_contact_organism.dart` -- Ensure Caregiver Name and Caregiver Phone fields are rendered -- Enables Tier-2 emergency contact setup.
- [x] `lib/ui/pages/profile_page.dart` -- Wire patient identity and caregiver controllers to profile state machine and save actions -- Persists profile baseline.
- [x] `test/ui/profile_page_test.dart` -- Unit and widget test patient identity, demographics, and live BMI re-calculation -- Guarantees 100% test coverage.

**Acceptance Criteria:**
- Given the user opens `ProfilePage`, when entering Full Name, Email Address, Phone Number, Weight, Height, and Caregiver Name/Phone, then all inputs are validated, BMI updates live, and tapping "Save & Continue" triggers "Medical profile updated ✓".

## Verification

**Commands:**
- `flutter test` -- expected: All 111 tests pass.

## Suggested Review Order

**Patient Identification & Caregiver UI Organisms**

- Render patient name, email, and phone input fields alongside baseline health demographics.
  [`health_demographics_organism.dart:45`](../../flutter/lib/ui/organisms/health_demographics_organism.dart#L45)

- Render caregiver contact name and phone fields for Tier-2 emergency response.
  [`emergency_contact_organism.dart:28`](../../flutter/lib/ui/organisms/emergency_contact_organism.dart#L28)

**Profile State & Controller Wire-up**

- Bind patient identity and caregiver controllers to profile state machine and live BMI calculator.
  [`profile_page.dart:42`](../../flutter/lib/ui/pages/profile_page.dart#L42)

**Automated Tests & Verifications**

- Verify patient identity fields, caregiver details, and live BMI dynamic calculation.
  [`profile_page_test.dart:22`](../../flutter/test/ui/profile_page_test.dart#L22)

