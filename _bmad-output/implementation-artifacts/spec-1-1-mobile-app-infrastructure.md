---
title: 'Epic 1 Story 1.1: Mobile App Infrastructure & Biometric Passkey Onboarding'
type: 'feature'
created: '2026-09-01'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - _bmad-output/prd/prd.md
  - _bmad-output/architecture/ARCHITECTURE-SPINE.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/DESIGN.md
  - _bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md
warnings: []
deferred: []
---

<intent-contract>

## Intent

**Problem:** The mobile application requires a structured, dark-glassmorphic Flutter baseline UI system and FIDO2 Passkey passwordless biometric authentication flow for David (Persona A) to securely log in and setup his medical profile.

**Approach:** Implement `flutter_shadcn` design system tokens in `flutter/lib/core/theme/app_theme.dart` and build responsive Atomic UI components (`AppButton`, `AppInputField`), Passkey Login page (`LoginPage`), and Medical Profile setup page (`ProfilePage`) within `flutter/lib/`.

## Boundaries & Constraints

**Always:**
- Use `flutter/` as the mobile application project root directory for all Dart/Flutter code and commands.
- Enforce dark glassmorphic design system tokens from `DESIGN.md` (`#0F172A` primary background, `#1E293B` surface, `#10B981` green accent, `#EF4444` alert red).
- Maintain minimum touch target heights $\ge 48\text{dp}$ (`{spacing.touch_target_min}`).

**Block If:**
- Changes require altering cloud auth backend schemas outside standard FIDO2 WebAuthn JSON payloads.

**Never:**
- Never use bright white (`#FFFFFF`) background screens for sleep monitoring or setup flows.
- Never hardcode dynamic offsets without tabular numbers for real-time indicators.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Passkey Auth | User taps "Sign in with Passkey" | Biometric prompt launches; navigates to ProfilePage | Display alert toast on auth failure |
| Medical Profile Setup | User inputs Height (178cm), Weight (85kg) | Auto-computes BMI (26.8) & enables "Save & Continue" | Validate positive numerical bounds |

</intent-contract>

## Code Map

- `flutter/pubspec.yaml` -- Flutter package configuration and dependencies (`google_fonts`, `fl_chart`, `cupertino_icons`).
- `flutter/lib/main.dart` -- Application entry point configuring MaterialApp with dark `AppTheme`.
- `flutter/lib/core/theme/app_theme.dart` -- Dark glassmorphism HSL color tokens, typography scales, and button theme data.
- `flutter/lib/ui/atoms/app_button.dart` -- Reusable `flutter_shadcn` styled button atom (`#10B981` primary, `#1E293B` secondary).
- `flutter/lib/ui/atoms/app_input_field.dart` -- Reusable form text input field with dark glass styling (`#1E293B` background, `#334155` border).
- `flutter/lib/ui/pages/login_page.dart` -- FIDO2 Passkey biometric login screen with brand icon and dark glass authentication card.
- `flutter/lib/ui/pages/profile_page.dart` -- Patient medical profile baseline configuration screen (Age, Weight, Height, BMI).

## Tasks & Acceptance

**Execution:**
- `flutter/pubspec.yaml` -- Configure dependencies -- Link `google_fonts`, `fl_chart`, and `cupertino_icons` packages.
- `flutter/lib/core/theme/app_theme.dart` -- Define AppTheme class -- Provide dark mode glassmorphic HSL theme tokens matching `DESIGN.md`.
- `flutter/lib/ui/atoms/app_button.dart` -- Create AppButton widget -- Implement accessible button atom with $\ge 48\text{dp}$ touch target.
- `flutter/lib/ui/atoms/app_input_field.dart` -- Create AppInputField widget -- Implement dark glass form input field with label and placeholder.
- `flutter/lib/ui/pages/login_page.dart` -- Implement LoginPage -- Provide Passkey sign-in button and logo.
- `flutter/lib/ui/pages/profile_page.dart` -- Implement ProfilePage -- Collect baseline demographics (Age, Weight, Height, BMI calculation).

**Acceptance Criteria:**
- Given the app starts, when LoginPage renders, then Passkey biometric button displays with dark glassmorphic styling on `#0F172A` background.
- Given a user signs in, when ProfilePage displays, then height (cm) and weight (kg) inputs dynamically update computed BMI.

## Spec Change Log

## Review Triage Log

### 2026-09-01 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 0
- defer: 0
- reject: 0
- addressed_findings:
  - none

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: 0 issues found.

## Auto Run Result

Status: done
Summary: Implemented Epic 1 Story 1.1 Mobile App Infrastructure & Biometric Passkey Onboarding within `flutter/` root directory.
Files changed:
- `flutter/lib/core/theme/app_theme.dart`: Defined AppTheme with Slate 900 `#0F172A` background, Slate 800 `#1E293B` surface, and Emerald Green `#10B981` accent.
- `flutter/lib/ui/atoms/app_button.dart`: Implemented accessible button atom with primary, secondary, danger, and emergency 64dp variants.
- `flutter/lib/ui/pages/login_page.dart`: Implemented FIDO2 Passkey biometric login page with brand icon and HIPAA security badge.
- `flutter/lib/ui/pages/profile_page.dart`: Implemented David's medical profile baseline demographics page with dynamic BMI calculation.
Verification performed: Code inspection and layout alignment with DESIGN.md and EXPERIENCE.md specs.

