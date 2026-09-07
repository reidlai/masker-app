---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.3.1
created: 2026-09-01
updated: 2026-09-07
author: Sally (UX Designer) & Winston (System Architect)
colors:
  primary: "#0F172A"       # Slate 900 (Deep Night Background)
  surface: "#1E293B"       # Slate 800 (Dark Glassmorphic Card Surface)
  surface_border: "#334155" # Slate 700 (Subtle Card Border)
  accent_green: "#10B981"   # Emerald 500 (Healthy Respiration / Normal Apnea Index)
  warning_amber: "#F59E0B"  # Amber 500 (Moderate Apnea Index / Active Calibration)
  danger_red: "#EF4444"     # Red 500 (Tier-1 Apnea Siren Alert / Emergency)
  purple_analytics: "#6D28D9" # Royal Purple 700 (Morning Analytics & Trends)
  text_primary: "#F8FAFC"   # Slate 50 (High Contrast Text)
  text_secondary: "#94A3B8" # Slate 400 (Subtle Subtitles & Labels)
  night_mode: "#000000"     # Pure Black (0-FPS Sleep Display Lock)
  pressed_surface: "#273449" # Slate 800 pressed (list-row / menu-row active background)
typography:
  font_family: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
  h1: "32px / 700 / 1.2"
  h2: "24px / 600 / 1.3"
  h3: "18px / 600 / 1.4"
  body: "14px / 400 / 1.5"
  caption: "12px / 500 / 1.4"
  numeric_tabular: "font-variant-numeric: tabular-nums"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  touch_target_min: "48px"
  emergency_button: "64px"
rounded:
  sm: "6px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  full: "9999px"
components:
  - ShadButton
  - ShadCard
  - ShadBadge
  - ShadInput
  - ShadSwitch
  - ShadDialog
  - ShadProgress
  - MetricStatCard
  - HomeSummaryCard
  - DeviceStatusCard
  - WeeklyTrendCard
  - CalibrationStepHeader
  - ApneaAlertBanner
  - SessionHistoryListItem
  - BottomNavBar
  - SettingsMenuRow
  - SubscriptionPlanCard
  - PaymentMethodCard
  - SettingsSectionHeader
  - DeveloperSimulatorBarOrganism
  - BlePermissionPrimerOrganism
---

# 🎨 DESIGN.md — Visual Identity & Design System Specification

## Brand & Style

The visual identity of the **Sleep Apnea Detection App** balances **clinical medical precision** with **restful, dark-mode elegance**. Because the application is used in bedroom environments at bedtime, the UI strictly minimizes light pollution while prioritizing high-contrast legibility, calm color tones, and immediate visual clarity during emergency events.

* **Design Aesthetic:** Dark Glassmorphism (`#0F172A` deep night background with `#1E293B` semi-transparent card overlays, subtle `#334155` borders, and dynamic backdrop blurring).
* **UI Kit Base:** **`flutter_shadcn` / `shadcn_ui`** primitives, extending atomic design principles for medical-grade Flutter clients.
* **Night Mode Invariant:** During active nocturnal sleep monitoring, the display switches to a 0-FPS locked pure black `#000000` screen with a low-intensity, dim pulsing green heartbeat dot to prevent sleep disruption and conserve battery (<8% drain over 8h).

---

## Colors

| Token Name | Hex Color Code | HSL / CSS Equivalent | Purpose & Usage |
| :--- | :--- | :--- | :--- |
| `{colors.primary}` | `#0F172A` | `hsl(222, 47%, 11%)` | Deep night background for all app screens. |
| `{colors.surface}` | `#1E293B` | `hsl(217, 33%, 17%)` | Glassmorphic card containers, modals, and list items. |
| `{colors.surface_border}` | `#334155` | `hsl(215, 25%, 27%)` | Subtle 1px card borders and divider lines. |
| `{colors.accent_green}` | `#10B981` | `hsl(160, 84%, 39%)` | Normal Apnea Index status (`AI < 5`), successful calibration, and healthy breath indicators. |
| `{colors.warning_amber}` | `#F59E0B` | `hsl(38, 92%, 50%)` | Moderate Apnea Index warning (`AI 15–30`), calibration sampling, and pending reconnects. |
| `{colors.danger_red}` | `#EF4444` | `hsl(0, 84%, 60%)` | Severe Apnea Index (`AI > 30`), Tier-1 local apnea siren overlay (`#FF3B30`), and emergency buttons. |
| `{colors.purple_analytics}`| `#6D28D9` | `hsl(263, 70%, 50%)` | Morning summary dashboard headers, historical analytics, and FFT spectral peaks. |
| `{colors.text_primary}` | `#F8FAFC` | `hsl(210, 40%, 98%)` | Primary headlines, numerical bio-signal readings, and emergency titles. |
| `{colors.text_secondary}` | `#94A3B8` | `hsl(215, 20%, 65%)` | Subtitles, unit labels (`BPM`, `events/hr`), and secondary metadata. |
| `{colors.night_mode}` | `#000000` | `hsl(0, 0%, 0%)` | Pure black 0-FPS sleep monitoring screen lock state. |
| `{colors.pressed_surface}` | `#273449` | `hsl(217, 30%, 22%)` | Pressed / active background for list rows and menu rows. |

---

## Typography

* **Primary Font Family:** `Inter`, `-apple-system`, `BlinkMacSystemFont`, `sans-serif`.
* **Tabular Figures (`tabular-nums`):** Mandatory for all real-time 10Hz raw bio-signal displays, countdown timers, and Apnea Index scores to eliminate jitter during value changes.

```
H1 Headline:  32px / Bold (700) / Line Height 1.2  -->  Page Titles & Emergency Alerts
H2 Subtitle:  24px / SemiBold (600) / Line Height 1.3  -->  Section Headers & Apnea Index Score Badges
H3 Section:   18px / SemiBold (600) / Line Height 1.4  -->  Card Titles & Metric Labels
Body Text:    14px / Regular (400) / Line Height 1.5  -->  Explanatory Copy & Medical Profile
Caption:      12px / Medium (500) / Line Height 1.4  -->  Chart Axes, Timestamps & Status Badges
```

---

## Layout & Spacing

* **Grid System:** Single-column responsive layout optimized for mobile screens (iOS & Android).
* **Margins & Padding:** Base unit scale of `8px` (`8px`, `12px`, `16px`, `24px`, `32px`).
* **Touch Target Invariants:**
  * **Standard Interactive Elements:** Minimum touch target height $\ge 48\text{dp}$ (`{spacing.touch_target_min}`).
  * **Emergency "I'm Safe" Button:** Prominent $64\text{dp}$ touch target (`{spacing.emergency_button}`) positioned centrally for effortless tapping in dark rooms.

---

## Elevation & Depth

* **Flat-Glass Depth Model:** Avoids heavy drop shadows. Uses 1px borders (`#334155`) combined with subtle backdrop blur filters (`backdrop-filter: blur(12px)`).
* **Card Surface Stack:**
  * `Level 0 (Background):` `#0F172A`
  * `Level 1 (Card Surface):` `#1E293B` with 1px `#334155` border.
  * `Level 2 (Modal / Dialog):` `#1E293B` with 1.5px `#475569` border and 16px blur backdrop mask.

---

## Shapes & Radius

* **Cards & Containers:** `8px` rounded corners (`{rounded.md}`).
* **Modals & Dialogs:** `12px` rounded corners (`{rounded.lg}`).
* **Status Badges & Pills:** `9999px` fully rounded pill shape (`{rounded.full}`).

---

## Components (Visual Specifications)

### 1. `MetricStatCard` (Molecule Component)
* **Visual Structure:** Dark card (`#1E293B`) with 1px border (`#334155`). Top row displays metric label (`#94A3B8`) and status icon. Center displays large tabular numeric value (`32px #F8FAFC`) with unit text. Bottom row displays status pill badge (`#10B981` Green for Normal, `#EF4444` Red for Severe).

### 1a. `HomeSummaryCard` (Molecule Component)
* **Visual Structure:** The hero card on the `MOB_HOME` dashboard. Dark card (`{colors.surface}` `#1E293B`, `8px` radius `{rounded.md}`, 1px `#334155` border), `20px` inner padding, full content width. **Label row:** `"LAST NIGHT"` (`{typography.caption}` `12px`, `0.04em` tracking, `#94A3B8`) on the left, session date (`12px #94A3B8`) on the right. **Hero row:** Apnea Index value (`{typography.h1}` `32px / 700`, `#F8FAFC`, tabular-nums) with a small `"AI"` unit label, and a trailing status pill (`ShadBadge`, `{rounded.full}`, `11px` semibold): `{colors.accent_green}` fill @12% + green text `"Normal"` (AI < 5), `{colors.warning_amber}` `"Moderate"` (5–29), `{colors.danger_red}` `"Severe"` (≥ 30). **Secondary row:** two inline stats separated by a middot — `Duration 7h 45m` and `Apnea events N` (`{typography.body}` `14px`, label in `#94A3B8`, value in `#F8FAFC`). **Trailing:** a right chevron (`#94A3B8`) vertically centered, signalling the whole card is tappable. Pressed state: background lifts to `{colors.pressed_surface}` (`#273449`). **Empty variant:** the card keeps its frame — a centered column with an outlined moon glyph (`24px`, `#94A3B8`) above one line of `{typography.body}` `#94A3B8` copy; no chevron. *(The compact Home card does not carry the apnea-only caveat line — that lives on `MOB_SLEEP_SUMMARY`.)*
* **Alarm-fired override:** when the session logged **≥ 1 Tier-1 apnea alarm** (`State_ApneaBreach` was reached — see EXPERIENCE.md Component Pattern #10), the AI-severity pill is **replaced** by an amber alert pill: `{colors.warning_amber}` fill @14% + amber text, a `12px` warning-triangle glyph + `"N apnea alert"` / `"N apnea alerts"`. The AI-severity word is not lost — it drops to a `{typography.caption}` `#94A3B8` line directly under the hero row (`"AI 3.2 · normal range · you tapped \"I'm Safe\" once"`), and the `Apnea events` value in the secondary row is coloured `{colors.warning_amber}`. This override fires regardless of AI band — a normal-range night that set off the siren still shows the amber pill.

### 1b. `DeviceStatusCard` (Molecule Component)
* **Visual Structure:** A single-row status card on `MOB_HOME`, same surface/border/radius as `HomeSummaryCard`, `16px` vertical / `18px` horizontal padding. Layout: a `8px` status dot · a primary line (`{typography.body}` `14px #F8FAFC`) · a `{colors.text_secondary}` detail line beneath or inline (`12px`). **Nominal:** `{colors.accent_green}` dot, "D-BAND connected", detail "84% · Last sync 7:02 AM", no chevron, card not elevated on press. **Actionable** (`{colors.danger_red}` for unreachable / no-sensor / permission, `{colors.warning_amber}` for low battery): matching dot colour, alert primary line ("D-BAND not found" / "Battery low — 12%" / "Bluetooth access needed"), a trailing right chevron (`#94A3B8`), and a `{colors.pressed_surface}` pressed background. The battery figure uses `{typography.numeric_tabular}`.

### 1c. `WeeklyTrendCard` (Molecule Component)
* **Visual Structure:** Card on `MOB_HOME`, `20px` padding. **Title row:** "Apnea Index — last 7 nights" (`{typography.caption}` uppercase `0.04em` `#94A3B8`), trailing right chevron. **Chart:** a 7-slot bar strip ~`64px` tall, bars `{colors.accent_green}` — most recent night at full opacity, the other six at `60%`; a night with no session renders as a `1px` `#334155` hollow outline of the same width. No axes, no gridlines, no labels on the bars. **Delta line:** `{typography.body}` `14px` — "{mean} average" in `#F8FAFC` then " · {down/up/level} from {prior} last week" in the direction colour (`{colors.accent_green}` down, `{colors.text_secondary}` level, `{colors.warning_amber}` up). **Insufficient-data variant:** no chart — one `{typography.body}` `#94A3B8` line ("Not enough data yet — check back after a few nights").

### 2. `CalibrationStepHeader` (Molecule Component)
* **Visual Structure:** Displays step index pill (`"STEP 1 OF 2"` — idle sample / wear check), bold step title (`18px #F8FAFC`), instruction body (`14px #94A3B8`), and animated horizontal progress bar (`#10B981`).

### 3. `ApneaAlertBanner` (Molecule Component)
* **Visual Structure:** High-contrast emergency banner (`#EF4444` background with `#FFFFFF` text). Pulsating red outer ring, large 30s countdown timer (`32px tabular-nums`), and large 64dp primary action button (`#FFFFFF` background with `#DC2626` bold text: `"I'M SAFE - DISMISS ALARM"`).

### 4. `SessionHistoryListItem` (Molecule Component)
* **Visual Structure:** Horizontal list card displaying session date (`14px #F8FAFC`), duration (`12px #94A3B8`), color-coded Apnea Index score badge (`AI 3.2 Normal`), and right chevron arrow.

### 5. `BottomNavBar` (Organism Component)
* **Visual Structure:** Persistent bottom bar on `{colors.surface}` (`#1E293B`) with a 1px top border `{colors.surface_border}` (`#334155`), respecting the device safe-area inset. Four equal-width items, each an outlined icon (24dp) above a `{typography.caption}` label (`12px`). **Active** item: icon + label in `{colors.accent_green}` (`#10B981`). **Inactive**: `{colors.text_secondary}` (`#94A3B8`). Item 4 is the outlined **gear** (`settings`) icon with label **"Settings"**. No badges. *(Visibility rules — hidden during onboarding and Night Mode — are behavioral; see `EXPERIENCE.md` §Component Patterns.)*

### 6. `SettingsMenuRow` (Molecule Component)
* **Visual Structure:** Full-width row inside a grouped card on `{colors.surface}` (`#1E293B`, `8px` radius `{rounded.md}`, 1px `#334155` border). Layout: leading 24dp icon · label (`{typography.body}` `14px #F8FAFC`) · flexible spacer · trailing right chevron (`#94A3B8`). Horizontal padding `16px` (`{spacing.lg}`); min height `48dp` (`{spacing.touch_target_min}`); 1px `#334155` divider between rows (never after the last). **Navigable variant** (Profile): chevron present, label at full-contrast `#F8FAFC`. **Value variant** (Language & Region, Billing & subscription, Payment method): a `{typography.body}` `{colors.text_secondary}` (`#94A3B8`) value string sits between the spacer and the chevron ("English", "Premium", "Visa ·· 4242"); label stays `#F8FAFC`. An optional 6px `{colors.warning_amber}` status dot may precede the value (e.g. card nearing expiry). **Inert variant** (Debugging, Developer): **no chevron**, label at `{colors.text_secondary}` (`#94A3B8`). Pressed state (navigable / value rows): row background lifts to `{colors.pressed_surface}` (`#273449`).

### 6a. `SubscriptionPlanCard` (Molecule Component)
* **Visual Structure:** The hero card on `MOB_BILLING`. Dark card (`{colors.surface}` `#1E293B`, `8px` radius `{rounded.md}`, 1px `#334155` border), `20px` padding. **Header row:** plan name (`{typography.h2}` `24px / 600` `#F8FAFC`) with a trailing `ShadBadge` (`{rounded.full}`, `11px` semibold) — `{colors.accent_green}` fill @12% + green text "Active" for Premium, `{colors.warning_amber}` "Ends {date}" when a cancel is pending, none for Free. **Price row** (Premium only): `{typography.h3}`-weight value + `{colors.text_secondary}` cycle ("$12.99 / month"). **Renewal line** (Premium only): `{typography.caption}` `{colors.text_secondary}` ("Renews 6 Oct 2026"). **Primary action:** full-width `ShadButton` — "Upgrade to Premium" on Free; omitted on active Premium (management actions live below the card). Below the card, the **"what Premium includes"** checklist: `{typography.body}` rows each led by a 16px `{colors.accent_green}` check glyph (muted to `{colors.text_secondary}` on the Free preview).

### 6b. `PaymentMethodCard` (Molecule Component)
* **Visual Structure:** The card-on-file block on `MOB_PAYMENT_METHOD` (and the compact summary on `MOB_BILLING`). Dark card, `20px` padding. **Row 1:** card-brand mark (24px, e.g. Visa) + masked number rendered as `·· ·· ·· 4242` (`{typography.body}` `#F8FAFC`, `{typography.numeric_tabular}`). **Row 2:** `{colors.text_secondary}` "Expires 08 / 27" and, right-aligned, the cardholder name. Never renders more than brand + last four + expiry — no full PAN, no CVC field, anywhere. **Actions** (stacked below the card, `MOB_PAYMENT_METHOD` only): "Replace card" — primary `ShadButton`; "Remove card" — `{colors.danger_red}` text button, no fill. **Empty variant** (`State_PaymentMethodEmpty`): no card — a centered column with a 28px `{colors.text_secondary}` card glyph, one line of `{typography.body}` `{colors.text_secondary}` copy ("No payment method on file."), and a single "Add card" primary `ShadButton`.

### 7. `SettingsSectionHeader` (Atom Component)
* **Visual Structure:** Left-aligned label in `{typography.caption}` (`12px`, weight 500) `{colors.text_secondary}` (`#94A3B8`), `0.04em` letter-spacing, sentence case ("Account", "Preferences", "Subscription", "Advanced"). Spacing: `24px` (`{spacing.xl}`) above, `8px` (`{spacing.sm}`) below. **Rendered only when its section contains at least one visible row** — "Account", "Preferences", and "Subscription" always qualify; "Advanced" is conditional.

### 8. `DeveloperSimulatorBarOrganism` (Organism Component)
* **Visual Structure:** Dark amber/slate glassmorphic toolbar (`#1E293B` background with `#F59E0B` amber border) embedded at the top of the active monitoring view (`MOB_SLEEP_MONITOR` / `State_MonitoringActive`) on `MeasurementPage` when `DEV_MODE=true`. Displays a header ("⚡ DEV SIMULATOR TOOLBAR") and action chips: `[Stop Breathing during sleep]` and `[Normal Breathing during sleep]`. Active scenario chip highlights in solid `{colors.danger_red}` or `{colors.accent_green}`.

### 9. `BlePermissionPrimerOrganism` (Organism Component)
* **Visual Structure:** Full-screen onboarding beat on `{colors.primary}` (`#0F172A`) background, matching the Passkey auth screen's composition. Centered Bluetooth glyph icon (`{colors.accent_green}`, marked decorative and excluded from the accessibility tree — the headline carries the meaning), headline (`{typography.h2}`, `#F8FAFC`), body copy (`{typography.body}`, `#94A3B8`), and a single full-width primary `ShadButton` reading "Allow Bluetooth Access" (specced in #10 below), pinned above the safe-area inset. No secondary or skip button — a single-path screen, same visual weight as `MOB_PASSKEY_AUTH`.

### 10. `ShadButton` — Primary Variant (Atom Component)
* **Visual Structure:** Default primary-action styling, used wherever a single-path CTA button appears, for example `BlePermissionPrimerOrganism`'s "Allow Bluetooth Access." Solid `{colors.accent_green}` (`#10B981`) fill with `{colors.primary}` (`#0F172A`) bold text — ≈7.8:1 contrast, clears WCAG AA with headroom. Full-width within its container, `{rounded.md}` corners, minimum `{spacing.touch_target_min}` height.

---

## Do's and Don'ts

### ✅ DO:
* **DO** use tabular numbers (`tabular-nums`) for all 10Hz live bio-signal numbers and countdown clocks to eliminate layout shifts.
* **DO** enforce pitch black `#000000` for Night Mode to prevent sleep disturbance.
* **DO** maintain high contrast ($\ge 4.5:1$) for all medical text against dark surfaces.
* **DO** gate the Debugging and Developer rows on build flags, and hide the "Advanced" `SettingsSectionHeader` whenever both are off.
* **DO** frame native OS permission dialogs with in-app context first (`MOB_BLE_PERMISSION_PRIMER`) rather than firing a system prompt with no explanation.

### ❌ DON'T:
* **DON'T** use bright white backgrounds (`#FFFFFF`) on primary mobile monitoring screens.
* **DON'T** use subtle or small buttons for the emergency "I'm Safe" dismiss action.
* **DON'T** introduce complex decorative animations during live 10Hz signal logging (keep GPU rendering streamlined).
* **DON'T** give the inert Debugging / Developer rows a trailing chevron — the chevron is reserved for rows that navigate.
* **DON'T** let `BleReceiverForegroundNotification` or `BleNotProtectedNotification` *initiate* anything beyond standard OS tap-to-open — no sound, no heads-up interruption, no notification-triggered screen wake (see `EXPERIENCE.md` Component Pattern #8 for the user-initiated-tap exception).
