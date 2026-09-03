---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.1.0
created: 2026-09-01
updated: 2026-09-02
author: Sally (UX Designer) & Winston (System Architect)
colors:
  primary: "#0F172A"       # Slate 900 (Deep Night Background)
  surface: "#1E293B"       # Slate 800 (Dark Glassmorphic Card Surface)
  surface_border: "#334155" # Slate 700 (Subtle Card Border)
  accent_green: "#10B981"   # Emerald 500 (Healthy Respiration / Normal AHI)
  warning_amber: "#F59E0B"  # Amber 500 (Hypopnea Caution / Active Calibration)
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
  - CalibrationStepHeader
  - ApneaAlertBanner
  - SessionHistoryListItem
  - BottomNavBar
  - SettingsMenuRow
  - SettingsSectionHeader
  - DeveloperSimulatorBarOrganism
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
| `{colors.accent_green}` | `#10B981` | `hsl(160, 84%, 39%)` | Normal AHI status (`AHI < 5`), successful calibration, and healthy breath indicators. |
| `{colors.warning_amber}` | `#F59E0B` | `hsl(38, 92%, 50%)` | Moderate AHI warning (`AHI 15–30`), calibration sampling, and pending reconnects. |
| `{colors.danger_red}` | `#EF4444` | `hsl(0, 84%, 60%)` | Severe AHI (`AHI > 30`), Tier-1 local apnea siren overlay (`#FF3B30`), and emergency buttons. |
| `{colors.purple_analytics}`| `#6D28D9` | `hsl(263, 70%, 50%)` | Morning summary dashboard headers, historical analytics, and FFT spectral peaks. |
| `{colors.text_primary}` | `#F8FAFC` | `hsl(210, 40%, 98%)` | Primary headlines, numerical bio-signal readings, and emergency titles. |
| `{colors.text_secondary}` | `#94A3B8` | `hsl(215, 20%, 65%)` | Subtitles, unit labels (`L/s`, `BPM`, `events/hr`), and secondary metadata. |
| `{colors.night_mode}` | `#000000` | `hsl(0, 0%, 0%)` | Pure black 0-FPS sleep monitoring screen lock state. |
| `{colors.pressed_surface}` | `#273449` | `hsl(217, 30%, 22%)` | Pressed / active background for list rows and menu rows. |

---

## Typography

* **Primary Font Family:** `Inter`, `-apple-system`, `BlinkMacSystemFont`, `sans-serif`.
* **Tabular Figures (`tabular-nums`):** Mandatory for all real-time 10Hz thermal airflow displays, countdown timers, and AHI scores to eliminate jitter during value changes.

```
H1 Headline:  32px / Bold (700) / Line Height 1.2  -->  Page Titles & Emergency Alerts
H2 Subtitle:  24px / SemiBold (600) / Line Height 1.3  -->  Section Headers & AHI Score Badges
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

### 2. `CalibrationStepHeader` (Molecule Component)
* **Visual Structure:** Displays step index pill (`"STEP 1 OF 2"`), bold step title (`18px #F8FAFC`), instruction body (`14px #94A3B8`), and animated horizontal progress bar (`#10B981`).

### 3. `ApneaAlertBanner` (Molecule Component)
* **Visual Structure:** High-contrast emergency banner (`#EF4444` background with `#FFFFFF` text). Pulsating red outer ring, large 30s countdown timer (`32px tabular-nums`), and large 64dp primary action button (`#FFFFFF` background with `#DC2626` bold text: `"I'M SAFE - DISMISS ALARM"`).

### 4. `SessionHistoryListItem` (Molecule Component)
* **Visual Structure:** Horizontal list card displaying session date (`14px #F8FAFC`), duration (`12px #94A3B8`), color-coded AHI score badge (`AHI 3.2 Normal`), and right chevron arrow.

### 5. `BottomNavBar` (Organism Component)
* **Visual Structure:** Persistent bottom bar on `{colors.surface}` (`#1E293B`) with a 1px top border `{colors.surface_border}` (`#334155`), respecting the device safe-area inset. Four equal-width items, each an outlined icon (24dp) above a `{typography.caption}` label (`12px`). **Active** item: icon + label in `{colors.accent_green}` (`#10B981`). **Inactive**: `{colors.text_secondary}` (`#94A3B8`). Item 4 is the outlined **gear** (`settings`) icon with label **"Settings"**. No badges. *(Visibility rules — hidden during onboarding and Night Mode — are behavioral; see `EXPERIENCE.md` §Component Patterns.)*

### 6. `SettingsMenuRow` (Molecule Component)
* **Visual Structure:** Full-width row inside a grouped card on `{colors.surface}` (`#1E293B`, `8px` radius `{rounded.md}`, 1px `#334155` border). Layout: leading 24dp icon · label (`{typography.body}` `14px #F8FAFC`) · flexible spacer · trailing right chevron (`#94A3B8`). Horizontal padding `16px` (`{spacing.lg}`); min height `48dp` (`{spacing.touch_target_min}`); 1px `#334155` divider between rows (never after the last). **Navigable variant** (Profile): chevron present, label at full-contrast `#F8FAFC`. **Inert variant** (Debugging, Developer): **no chevron**, label at `{colors.text_secondary}` (`#94A3B8`). Pressed state (navigable rows): row background lifts to `{colors.pressed_surface}` (`#273449`).

### 7. `SettingsSectionHeader` (Atom Component)
* **Visual Structure:** Left-aligned label in `{typography.caption}` (`12px`, weight 500) `{colors.text_secondary}` (`#94A3B8`), `0.04em` letter-spacing, sentence case ("Advanced"). Spacing: `24px` (`{spacing.xl}`) above, `8px` (`{spacing.sm}`) below. **Rendered only when its section contains at least one visible row** — never shown above an empty section.

### 8. `DeveloperSimulatorBarOrganism` (Organism Component)
* **Visual Structure:** Dark amber/slate glassmorphic toolbar (`#1E293B` background with `#F59E0B` amber border) embedded at the top of `MeasurementPage` when `DEV_MODE=true`. Displays a header ("⚡ DEV MODE SIMULATOR") and horizontal scrolling action chips: `[Idle Noise]`, `[Active Baseline]`, `[Normal (16 bpm)]`, `[Apnea Drop (>10s)]`, and `[Recovery (5s)]`. Active scenario chip highlights in solid `{colors.warning_amber}` or `{colors.accent_green}`.

---

## Do's and Don'ts

### ✅ DO:
* **DO** use tabular numbers (`tabular-nums`) for all 10Hz live bio-signal numbers and countdown clocks to eliminate layout shifts.
* **DO** enforce pitch black `#000000` for Night Mode to prevent sleep disturbance.
* **DO** maintain high contrast ($\ge 4.5:1$) for all medical text against dark surfaces.
* **DO** gate the Debugging and Developer rows on build flags, and hide the "Advanced" `SettingsSectionHeader` whenever both are off.

### ❌ DON'T:
* **DON'T** use bright white backgrounds (`#FFFFFF`) on primary mobile monitoring screens.
* **DON'T** use subtle or small buttons for the emergency "I'm Safe" dismiss action.
* **DON'T** introduce complex decorative animations during live 10Hz signal logging (keep GPU rendering streamlined).
* **DON'T** give the inert Debugging / Developer rows a trailing chevron — the chevron is reserved for rows that navigate.
