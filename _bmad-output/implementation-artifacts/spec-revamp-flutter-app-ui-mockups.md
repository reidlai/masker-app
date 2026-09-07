---
title: 'Revamp Flutter App UI to Match BMAD-UX Mockups'
type: 'refactor'
created: '2026-09-06'
status: 'done'
baseline_commit: '130d4c638c2153ec9fbb677ba858c404bcdaf6e7'
review_loop_iteration: 0
context:
  - '_bmad-output/ux/ux-design-masker-app-2026-09-01/DESIGN.md'
  - '_bmad-output/ux/ux-design-masker-app-2026-09-01/EXPERIENCE.md'
---

## Intent

**Problem:** The current Flutter codebase contains basic placeholder UI screens and component structures that do not match the medical-grade dark glassmorphism design system (`DESIGN.md`) or the complete 16-screen mockup specifications (`EXPERIENCE.md` / `mockups/*.html`) produced by `bmad-ux`.

**Approach:** Revamp the design system token implementation, UI atoms/molecules/organisms, and page screens in `flutter/lib` to match the exact visual layout, colors (`#0F172A`, `#1E293B`, `#10B981`, `#F59E0B`, `#EF4444`), typography (`Inter`, tabular numbers), navigation flow, and interactive components defined in the `bmad-ux` mockups.

## Boundaries & Constraints

**Always:**
- Use exact HSL/Hex color tokens from `DESIGN.md` (`#0F172A` background, `#1E293B` surface, `#334155` border, `#10B981` green accent, `#F59E0B` amber warning, `#EF4444` red alert, `#6D28D9` purple analytics).
- Implement tabular figures (`tabular-nums` / font features) on live bio-signal displays, countdown timers, and Apnea Index scores.
- Preserve business logic, BLE streaming integration (`BleReceiverService`), RxDart streams, BLoC handlers, and IDLE band calibration flow while upgrading UI presentation.
- Follow the 4-tab persistent bottom navigation bar (`Home`, `Monitor`, `Summary`, `Settings`).

**Ask First:**
- Modifying underlying BLE hardware/simulator architecture contracts or BLoC state schemas.

**Never:**
- Use bright white `#FFFFFF` scaffold backgrounds or unstyled default Material components.
- Hardcode static pixel multipliers when computing container layout heights; calculate bounds dynamically.

## Code Map

- `flutter/lib/core/theme/app_theme.dart` -- Core color tokens (`AppColors`), typography, glassmorphic ThemeData.
- `flutter/lib/ui/atoms/shad_button.dart` -- Primary, outline, and emergency button primitives (`ShadButton`).
- `flutter/lib/ui/atoms/shad_badge.dart` -- Pill status badge primitive (`ShadBadge`).
- `flutter/lib/ui/molecules/home_summary_card.dart` -- Hero card on Home screen displaying last night's session summary and Apnea Index score badge.
- `flutter/lib/ui/molecules/device_status_card.dart` -- D-BAND sensor connection and battery status card.
- `flutter/lib/ui/molecules/weekly_trend_card.dart` -- 7-night Apnea Index trend bar chart card.
- `flutter/lib/ui/molecules/settings_menu_row.dart` -- Reusable settings list row item with value string and status dot support.
- `flutter/lib/ui/molecules/settings_section_header.dart` -- Uppercase section header label for settings groups.
- `flutter/lib/ui/molecules/subscription_plan_card.dart` -- Premium subscription plan details hero card.
- `flutter/lib/ui/molecules/payment_method_card.dart` -- Masked card-on-file payment method card.
- `flutter/lib/ui/organisms/primary_nav_bar.dart` -- 4-tab persistent bottom navigation bar with active green state.
- `flutter/lib/ui/organisms/apnea_alert_overlay.dart` -- Tier-1 local mobile alarm emergency siren overlay with 30s countdown and 64dp "I'M SAFE" button.
- `flutter/lib/ui/pages/main_container_page.dart` -- Main tab shell managing 4 primary tabs.
- `flutter/lib/ui/pages/home_page.dart` -- Daytime read-only dashboard (`MOB_HOME`).
- `flutter/lib/ui/pages/measurement_page.dart` -- Nocturnal sleep monitor screen (`MOB_SLEEP_MONITOR`).
- `flutter/lib/ui/pages/summary_screen_page.dart` -- Morning sleep summary screen (`MOB_SLEEP_SUMMARY`).
- `flutter/lib/ui/pages/graph_waveform_page.dart` -- Interactive respiration waveform & spectral graphs page (`MOB_GRAPH_WAVEFORM`).
- `flutter/lib/ui/pages/history_filter_page.dart` -- Session history calendar & list view (`MOB_HISTORY_FILTER`).
- `flutter/lib/ui/pages/export_doctor_page.dart` -- Signed physician report export page (`MOB_EXPORT_DOCTOR`).
- `flutter/lib/ui/pages/settings_page.dart` -- Grouped settings page (`MOB_SETTINGS`).
- `flutter/lib/ui/pages/language_region_page.dart` -- Language & region selection screen (`MOB_LANGUAGE_REGION`).
- `flutter/lib/ui/pages/billing_page.dart` -- Billing & subscription screen (`MOB_BILLING`).
- `flutter/lib/ui/pages/payment_method_page.dart` -- Payment method screen (`MOB_PAYMENT_METHOD`).
- `flutter/lib/ui/pages/login_page.dart` -- Passkey biometrics authentication screen (`MOB_PASSKEY_AUTH`).
- `flutter/lib/ui/pages/profile_page.dart` -- Patient baseline & health demographics setup/edit screen (`MOB_USER_PROFILE`).
- `flutter/lib/ui/pages/ble_permission_primer_page.dart` -- Bluetooth background access primer onboarding screen (`MOB_BLE_PERMISSION_PRIMER`).

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/theme/app_theme.dart` -- Update design system tokens to strictly match DESIGN.md (`#0F172A`, `#1E293B`, `#334155`, `#10B981`, `#F59E0B`, `#EF4444`, `#6D28D9`, `#273449`).
- [x] `flutter/lib/ui/atoms/shad_button.dart` -- Implement Shadcn-style button component (`ShadButton`) with primary green, secondary outline, and emergency red variants.
- [x] `flutter/lib/ui/atoms/shad_badge.dart` -- Implement Shadcn-style badge component (`ShadBadge`) for status pill indicators.
- [x] `flutter/lib/ui/molecules/home_summary_card.dart` -- Build HomeSummaryCard hero component matching MOB_HOME mockup layout.
- [x] `flutter/lib/ui/molecules/device_status_card.dart` -- Build DeviceStatusCard component matching MOB_HOME mockup layout.
- [x] `flutter/lib/ui/molecules/weekly_trend_card.dart` -- Build WeeklyTrendCard with 7-night fl_chart bar strip and delta line.
- [x] `flutter/lib/ui/molecules/settings_menu_row.dart` -- Enhance SettingsMenuRow with trailing value strings, status dots, and chevron support.
- [x] `flutter/lib/ui/molecules/subscription_plan_card.dart` -- Create SubscriptionPlanCard component for Billing screen.
- [x] `flutter/lib/ui/molecules/payment_method_card.dart` -- Create PaymentMethodCard component for Payment Method screen.
- [x] `flutter/lib/ui/pages/home_page.dart` -- Revamp Home dashboard screen with Greeting + streak, HomeSummaryCard, DeviceStatusCard, and WeeklyTrendCard.
- [x] `flutter/lib/ui/pages/summary_screen_page.dart` -- Revamp Summary dashboard screen with hero score badge, apnea-only caveat line, waveform section, metric grid, and navigation to history/export.
- [x] `flutter/lib/ui/pages/graph_waveform_page.dart` -- Create interactive waveform screen (`MOB_GRAPH_WAVEFORM`).
- [x] `flutter/lib/ui/pages/history_filter_page.dart` -- Create session history screen (`MOB_HISTORY_FILTER`).
- [x] `flutter/lib/ui/pages/export_doctor_page.dart` -- Create signed physician export screen (`MOB_EXPORT_DOCTOR`).
- [x] `flutter/lib/ui/pages/settings_page.dart` -- Revamp Settings screen with Account, Preferences, Subscription, and Advanced sections.
- [x] `flutter/lib/ui/pages/language_region_page.dart` -- Create Language & Region screen (`MOB_LANGUAGE_REGION`).
- [x] `flutter/lib/ui/pages/billing_page.dart` -- Create Billing & Subscription screen (`MOB_BILLING`).
- [x] `flutter/lib/ui/pages/payment_method_page.dart` -- Create Payment Method screen (`MOB_PAYMENT_METHOD`).
- [x] `flutter/lib/ui/pages/measurement_page.dart` -- Revamp Sleep Monitor page with pre-session "Start Sleep Monitoring" CTA, 0-FPS Night Mode, and developer simulator bar overlay.

**Acceptance Criteria:**
- Given the user launches the app post-onboarding, when navigating between Home, Monitor, Summary, and Settings tabs, then the UI displays cohesive dark glassmorphism styling (`#0F172A` background, `#1E293B` cards with `#334155` borders) with exact typography and layout matching `bmad-ux` mockups.
- Given a user taps on Home cards or Settings items, then appropriate drill-down screens (`MOB_SLEEP_SUMMARY`, `MOB_GRAPH_WAVEFORM`, `MOB_HISTORY_FILTER`, `MOB_EXPORT_DOCTOR`, `MOB_LANGUAGE_REGION`, `MOB_BILLING`, `MOB_PAYMENT_METHOD`) open seamlessly with back navigation.

## Verification

**Commands:**
- `flutter analyze` -- expected: 0 errors/warnings in lib/
- `flutter test` -- expected: All existing unit and widget tests pass clean

## Suggested Review Order

**Design System & Theme Tokens**

- Dark glassmorphism color palette and tabular figures font styling
  [`app_theme.dart:1`](../../flutter/lib/core/theme/app_theme.dart#L1)

**Atomic UI Primitives**

- Shadcn-style button component with primary, outline, and emergency variants
  [`shad_button.dart:1`](../../flutter/lib/ui/atoms/shad_button.dart#L1)

- Pill badge indicator component with status colors
  [`shad_badge.dart:1`](../../flutter/lib/ui/atoms/shad_badge.dart#L1)

**Dashboard & Hero Molecules**

- Last-night summary hero card with Apnea Index pill and stats
  [`home_summary_card.dart:1`](../../flutter/lib/ui/molecules/home_summary_card.dart#L1)

- D-BAND device status indicator card
  [`device_status_card.dart:1`](../../flutter/lib/ui/molecules/device_status_card.dart#L1)

- 7-night Apnea Index trend bar chart card
  [`weekly_trend_card.dart:1`](../../flutter/lib/ui/molecules/weekly_trend_card.dart#L1)

- Subscription plan hero card and payment method card
  [`subscription_plan_card.dart:1`](../../flutter/lib/ui/molecules/subscription_plan_card.dart#L1)
  [`payment_method_card.dart:1`](../../flutter/lib/ui/molecules/payment_method_card.dart#L1)

**Screen Pages & Navigation Shell**

- Main persistent 4-tab container shell
  [`main_container_page.dart:1`](../../flutter/lib/ui/pages/main_container_page.dart#L1)

- Read-only daytime dashboard screen (`MOB_HOME`)
  [`home_page.dart:1`](../../flutter/lib/ui/pages/home_page.dart#L1)

- Morning sleep summary screen (`MOB_SLEEP_SUMMARY`)
  [`summary_screen_page.dart:1`](../../flutter/lib/ui/pages/summary_screen_page.dart#L1)

- Grouped settings page (`MOB_SETTINGS`)
  [`settings_page.dart:1`](../../flutter/lib/ui/pages/settings_page.dart#L1)

- Drill-down sub-screens (Waveform, History Filter, Export Doctor, Language & Region, Billing, Payment Method)
  [`graph_waveform_page.dart:1`](../../flutter/lib/ui/pages/graph_waveform_page.dart#L1)
  [`history_filter_page.dart:1`](../../flutter/lib/ui/pages/history_filter_page.dart#L1)
  [`export_doctor_page.dart:1`](../../flutter/lib/ui/pages/export_doctor_page.dart#L1)
  [`language_region_page.dart:1`](../../flutter/lib/ui/pages/language_region_page.dart#L1)
  [`billing_page.dart:1`](../../flutter/lib/ui/pages/billing_page.dart#L1)
  [`payment_method_page.dart:1`](../../flutter/lib/ui/pages/payment_method_page.dart#L1)
