---
name: Sleep Apnea Detection App (D-BAND Integrated Platform)
status: final
version: 1.3.1
created: 2026-09-01
updated: 2026-09-07
author: Sally (UX Designer) & Winston (System Architect)
---

# 🧠 EXPERIENCE.md — Information Architecture & User Experience Specification

## Foundation

* **Target Form-Factor:** Mobile Smartphones (iOS 15+ & Android 10+).
* **Design System & UI Framework:** Built using **Flutter (Dart)** with **`flutter_shadcn` / `shadcn_ui`** atomic UI primitives and **`fl_chart`** Skia GPU chart rendering.
* **Visual Identity Reference:** All color tokens, typography scales, spacing units, and element shapes reference [`DESIGN.md`](./DESIGN.md) (`{colors.primary}`, `{colors.surface}`, `{colors.accent_green}`, `{colors.danger_red}`, `{spacing.emergency_button}`).

---

## Information Architecture

### Screen Navigation & Flow Map

```
[ App Launch / Passkey Prompt (MOB_PASSKEY_AUTH) ]
                        |
                        v
[ User Medical Profile Setup (MOB_USER_PROFILE) ]
   ├── Patient Identification (HIPAA Level 1 PHI): Patient Full Name, Email Address, Phone Number
   ├── Health Demographics: Age (years), Weight (kg), Height (cm), Computed BMI
   ├── Caregiver Contact: Caregiver Name, Caregiver Phone Number (Tier-2 Emergency SMS/Voice)
   └── HIPAA/FDA Safeguards: Passkey auth gate (§164.312a), AES-256 encryption at rest (§164.312a2iv), TLS 1.3 in transit (§164.312e1), Minimum Necessary payload (§164.502b), non-blocking audit logging (§164.312b)
                        |
                        v
[ Bluetooth Access Priming (MOB_BLE_PERMISSION_PRIMER) ]  ← first run only
                        |
                        v
[ BLE Sensor Discovery & Pairing (MOB_DEVICE_PAIRING) ]
                        |
                        v
[ Sensor Baseline Drift & Noise Floor Envelope Calibration Wizard (MOB_CALIBRATION) ]
   ├── Idle sample: worn + still ~10s → records running min/max = Noise Floor Envelope
   └── Wear check: breathe normally → app confirms ≥2 valid envelope-excursion cycles
                        |
                        v
[ Nocturnal Sleep Monitoring - 0-FPS Night Mode (MOB_SLEEP_MONITOR) ]
         │                                       │
         │ (Normal Breathing)                    │ (Apnea Breach >10s)
         v                                       v
[ Morning Sleep Summary ]            [ Tier-1 Local Mobile Alarm (MOB_TIER1_ALARM) ]
(MOB_SLEEP_SUMMARY)                             │
   ├── Interactive Waveform (MOB_GRAPH_WAVEFORM) │ (Tap "I'm Safe" / 5s Breathing Restore)
   ├── Calendar History (MOB_HISTORY_FILTER)    v
   └── Doctor Report Export (MOB_EXPORT_DOCTOR) [ Alarm Silenced / Return to Monitor ]
```

**Post-onboarding landing.** The map above is the *first-run* path: it ends by dropping the user straight onto `MOB_SLEEP_MONITOR` (they just finished setup to monitor tonight). On **every subsequent app launch** the app opens on **`MOB_HOME`** (the tab-1 default), not back into the onboarding chain — onboarding screens are gated on state (passkey session, permission grant, stored calibration) and are skipped once satisfied. From Home the user starts each night's session by switching to the **Monitor** tab.

**Clickable prototype:** every screen above, plus `MOB_HOME` and the Settings sub-screens (`MOB_SETTINGS`, `MOB_LANGUAGE_REGION`, `MOB_BILLING`, `MOB_PAYMENT_METHOD`), exists as a wired Penpot board. Two flows, each a single linear click-through (one forward tap per board):

- **"Home (daily use)"** — the default; play opens here. `MOB_HOME` → `MOB_SLEEP_SUMMARY` → `MOB_GRAPH_WAVEFORM` → `MOB_HISTORY_FILTER` → `MOB_EXPORT_DOCTOR` → `MOB_SETTINGS` → `MOB_LANGUAGE_REGION` → `MOB_BILLING` → `MOB_PAYMENT_METHOD` ▪ end. This is the everyday path: land on the dashboard, review last night, dig into history/export, adjust settings.
- **"First-run onboarding"** — from the flow picker. `MOB_PASSKEY_AUTH` → `MOB_USER_PROFILE` → `MOB_BLE_PERMISSION_PRIMER` → `MOB_DEVICE_PAIRING` → `MOB_CALIBRATION` → `MOB_SLEEP_MONITOR` → `MOB_TIER1_ALARM` → `MOB_HOME`. The `MOB_SLEEP_MONITOR` → `MOB_TIER1_ALARM` step stands in for a breathing-pause event during the night; `MOB_TIER1_ALARM`'s "I'm Safe" dismissal returns to monitoring, which ends the walkthrough on `MOB_HOME` (the morning after). *(Penpot board "06 - Calibration Stage 2" has been deleted; "05" is now "05 - Sensor Baseline Drift & Noise Floor Envelope Calibration" and links straight to the sleep monitor.)*

File: [`Sleep Apnea App — Mockup Flow`](http://localhost:9001/#/workspace?team-id=05a22000-b411-8052-8008-9712fb8b998e&file-id=aeeec736-5c79-81d3-8008-9719456b8880&page-id=aeeec736-5c79-81d3-8008-9719456b8881) in Reid's self-hosted Penpot instance (`docker compose up -d` in `_bmad-output/ux/penpot/` if it's not already running). Static reference: `mockups/*.html` in this folder.

---

### Onboarding: Bluetooth Background-Access Priming (`MOB_BLE_PERMISSION_PRIMER`)

**First run only.** Appears exactly once, after Profile Setup (`MOB_USER_PROFILE`) and before BLE Sensor Discovery (`MOB_DEVICE_PAIRING`). Once the OS Bluetooth permission is granted, this screen is skipped on every subsequent launch — the app checks permission state at boot, not a "seen it" flag alone.

* **Purpose:** Architecture invariant AD-12 starts the BLE receiver's Foreground Service at app boot on every future launch. On Android 12+, a `connectedDevice`-type foreground service requires `BLUETOOTH_CONNECT` already granted before it can start — so this screen exists to get that permission with context, before the bare native dialog fires, rather than after it fires.
* **Content:** Full-screen, same dark glassmorphic surface as onboarding. Headline + reassuring body copy (for example *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access"*), and a single primary CTA button, for example **"Allow Bluetooth Access."** No skip or decline path — the app cannot monitor without this permission, so the framing matches the Passkey auth screen's single-path pattern rather than offering an alternate route.
* **Handoff:** Tapping the CTA triggers the native OS permission flow (Android: `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`, shown as **sequential dialogs, not one** — the CTA hands off to whichever the OS presents first; iOS: the system `bluetooth-central` background-mode disclosure, surfaced automatically the first time the app touches CoreBluetooth). On full grant, the app proceeds to `MOB_DEVICE_PAIRING` and the AD-12 receiver service becomes eligible to start on this and all future boots.
* **Prior-denial check:** Before acting, the CTA checks each platform's permission-status API. If a prior denial means the OS itself won't reissue its dialog (iOS CoreBluetooth's one-shot behavior after a first denial; Android's "Don't ask again"), the CTA routes straight to the "Open Settings" deep-link instead of re-tapping a dialog that cannot fire — a silent no-op here would be a dead end for an anxious patient.
* `[NOTE FOR UX/ARCH]` Android manifest must declare the `neverForLocation` flag on `BLUETOOTH_SCAN` so the OS dialog doesn't fold in unrelated location-permission language that would contradict this screen's Bluetooth-only framing. Cross-check with architecture at build.
* **Denial / partial-grant recovery:** See State Patterns #11 `State_BlePermissionDenied` and #12 `State_BlePermissionPartial` for the full behavior — in short, `MOB_DEVICE_PAIRING` blocks with an "Open Settings" recovery CTA naming the missing permission.

---

### Primary Navigation — Persistent Bottom Nav Bar (Post-Onboarding)

Once onboarding completes, the app shell presents a persistent 4-tab bottom navigation bar (`PrimaryNavBarOrganism`). Tabs, left to right:

| # | Tab | Icon | Destination |
| :- | :- | :- | :- |
| 1 | Home | house (outlined) | `MOB_HOME` — daytime dashboard; the default tab on every app launch. See §Home Screen below. |
| 2 | Monitor | moon (outlined) | `MOB_SLEEP_MONITOR` — also holds the nightly **Start Sleep Monitoring** entry point (see §Home Screen note). |
| 3 | Summary | bar-chart (outlined) | `MOB_SLEEP_SUMMARY` |
| 4 | **Settings** | **gear / `settings` (outlined)** | **`MOB_SETTINGS`** — replaces the former "Profile" tab (was: person icon → `MOB_USER_PROFILE`). |

`MOB_USER_PROFILE` loses its direct tab: post-onboarding it is reachable **only** through the Settings list, with no other entry points.

### Home Screen (`MOB_HOME`)

Tab-1 destination and the app's default landing on every launch after onboarding. A **read-only dashboard** — a vertical scroll of status cards, no controls that start or stop anything. It answers, in one screen: *how did last night go, is my sensor ready for tonight, and am I trending the right way.*

```
[ Home  (header: "Good morning" · streak line) ]  ── scroll ──
   1  Greeting + monitoring streak
   2  Last-night summary card ────────tap──►  MOB_SLEEP_SUMMARY
   3  D-BAND device-status card ──tap (when actionable)──►  MOB_DEVICE_PAIRING blocked state
   4  7-night Apnea Index trend card ──tap──►  MOB_HISTORY_FILTER
```

* **1 — Greeting + streak** — a time-of-day greeting (*"Good morning"* / *"Good evening"*, no name) in `{typography.h2}` and a `{typography.caption}` `{colors.text_secondary}` streak line: *"12 nights monitored"* (consecutive nights with a finalized session; resets on a missed night, shows *"First night tonight"* before any session). Purely a flourish — never the primary read.
* **2 — Last-night summary card** (`HomeSummaryCardOrganism`, hero) — label row (`"LAST NIGHT"` + session date), hero **Apnea Index (AI)** value (`{typography.h1}`, tabular-nums) with a trailing `ShadBadge` status pill — `{colors.accent_green}` "Normal" for AI < 5, `{colors.warning_amber}` "Moderate" for 5–29, `{colors.danger_red}` "Severe" for AI ≥ 30 — and a two-stat row: **Duration** (`7h 45m`) and **Apnea events**. Whole card is one hit target with a trailing chevron → `MOB_SLEEP_SUMMARY` for that session. Light haptic, `{colors.pressed_surface}` pressed background. **Apnea-only metric:** the score is an *Apnea Index*, not a full AHI — the D-BAND does not score hypopneas — so the severity bands are the standard AHI bands applied to apnea events only; the full caveat line lives on `MOB_SLEEP_SUMMARY` (see that section), not repeated on the compact Home card.
* **3 — D-BAND device-status card** (`DeviceStatusCardOrganism`) — the "will tonight work" answer. Nominal state: a `{colors.accent_green}` dot + *"D-BAND connected"*, battery percentage, and *"Last sync 7:02 AM"*; not tappable, no chevron. **Actionable states**: sensor unreachable → `{colors.danger_red}` dot + *"D-BAND not found"* + a chevron; battery ≤ 15% → `{colors.warning_amber}` dot + *"Battery low — 12%"*; Bluetooth permission missing/revoked → `{colors.danger_red}` + *"Bluetooth access needed"*. In any actionable state the card becomes a tap target routing to `MOB_DEVICE_PAIRING`'s blocked/recovery state (or the Settings deep-link per the prior-denial check). This card reads its data from the AD-12 receiver service state, not a live scan.
* **4 — 7-night Apnea Index trend card** (`WeeklyTrendCardOrganism`) — title *"Apnea Index — last 7 nights"*, a 7-bar mini chart (`fl_chart`, bars in `{colors.accent_green}`, the most recent night at full opacity and the rest at 60%, a missed night rendered as a hollow slot), and a plain-language delta line: *"3.4 average · down from 4.1 last week"* (`{colors.accent_green}` when improving, `{colors.text_secondary}` when flat, `{colors.warning_amber}` when worsening). Tap → `MOB_HISTORY_FILTER`. **Not a diagnosis** — the copy states the trend, never an interpretation ("your apnea is improving" is out of bounds; "your Apnea Index is trending down" is fine).
* **No quick-links row.** History and Doctor Export are **not** surfaced on Home — History is reached from the `MOB_SLEEP_SUMMARY` header action and Export from the `MOB_SLEEP_SUMMARY` body, so Home would only duplicate them. The trend card's tap-through to `MOB_HISTORY_FILTER` is the one history affordance Home carries.
* **No start control.** Starting a night's session lives on the **Monitor** tab, not Home — Home is something you read, not act from. `MOB_SLEEP_MONITOR` gains a pre-session **"Start Sleep Monitoring"** state distinct from its Night Mode lock; tapping it goes straight to active monitoring, with `NoiseFloorEnvelopeCalibrationWizardOrganism` re-running only on the first session or when the stored Noise Floor Envelope is stale/invalid. `[NOTE FOR UX]` `mob_sleep_monitor.html` still renders only the active Night Mode state; the pre-session Start state is specified but pending a mockup pass.
* **Bottom nav** — `PrimaryNavBarOrganism`, tab 1 (Home) active in `{colors.accent_green}`.
* **Empty variants** — see `State_HomeEmpty` (no finalized session yet) and `State_HomeNoDevice` (no sensor paired). Cards that have no data render their own quiet placeholder in place; the dashboard frame (greeting, card order) does not collapse.
* **Accessibility** — each card exposes one composite label, not per-stat fragments ("Last night: Apnea Index 3.2, Normal, 7 hours 45 minutes, 2 apnea events. Opens full summary." / "D-BAND connected, battery 84 percent, last synced 7:02 AM." / "Apnea Index last 7 nights: 3.4 average, down from 4.1 last week. Opens history."). Any card in an actionable/alert state is announced with its role as a button and its alert text first. The trend chart carries a text alternative equal to the delta line — the bars are decorative.

### Settings Screen (`MOB_SETTINGS`)

Full-screen destination pushed from tab 4, with a standard app bar: back affordance (‹) and title "Settings". Content is a vertical list of menu rows (`SettingsMenuRow`) organised into labelled groups, each group on its own glassmorphic surface card under a `SettingsSectionHeader`.

```
[ Settings  (app bar: ‹ back · title "Settings") ]
  ── Account ─────────────────────────────────────────
     └── Profile ─────────────────────►  MOB_USER_PROFILE      (navigable)
  ── Preferences ─────────────────────────────────────
     └── Language & Region ───────────►  MOB_LANGUAGE_REGION   (navigable; trailing value "English")
  ── Subscription ────────────────────────────────────
     ├── Billing & subscription ──────►  MOB_BILLING           (navigable; trailing value "Premium")
     └── Payment method ──────────────►  MOB_PAYMENT_METHOD    (navigable; trailing value "Visa ·· 4242")
  ── Advanced ──  shown only if (debuggingMode OR developerMode) ──
     ├── Debugging  ── shown if debuggingMode ── (inert, no action)
     └── Developer  ── shown if developerMode ── (inert, no action)
```

* **Account / Profile row** — always visible. Leading person icon, label "Profile", trailing chevron. Tap → `MOB_USER_PROFILE`. Back from there returns to `MOB_SETTINGS`; back again returns to the tab the user came from.
* **Preferences / Language & Region row** — always visible. Leading globe icon, label "Language & Region", a trailing **value string** ("English") before the chevron per `SettingsMenuRow`'s value variant. Tap → `MOB_LANGUAGE_REGION`.
* **Subscription / Billing & subscription row** — always visible. Leading receipt icon, label "Billing & subscription", trailing value = current plan name ("Premium" / "Free"). Tap → `MOB_BILLING`.
* **Subscription / Payment method row** — always visible. Leading card icon, label "Payment method", trailing value = card brand + last 4 ("Visa ·· 4242") or "None" when no card is on file. Tap → `MOB_PAYMENT_METHOD`.
* **Section headers** — "Account", "Preferences", and "Subscription" always render (each has ≥ 1 permanent row). "Advanced" still renders **only when** `debuggingMode` **or** `developerMode` is enabled — a production build with both off shows the first three groups and no "Advanced" header. (`State_SettingsDefault` updated accordingly — it is no longer "Profile row only".)
* **Debugging / Developer rows** — each visible only when its own flag is enabled; both inert for now (no destination, tap is a no-op). `[ASSUMPTION]` final behavior TBD at build or architecture.
* `debuggingMode` and `developerMode` are **two independent booleans**. `[ASSUMPTION]` — `debuggingMode` follows Flutter `kDebugMode`; `developerMode` follows a `--dart-define=DEV_MODE=true` build flag. Confirm the mechanism during architecture or build.

> `[NOTE FOR UX]` — `MOB_USER_PROFILE` is specified as an onboarding "Setup" step (Save & Continue advances the wizard); reached from Settings it is an **edit-existing-profile** context (Save persists; back returns). Two open items tracked:
> - The Profile screen likely needs a first-run vs. edit mode distinction.
> - It depends on the planned **Units** preference: the Weight/Height fields and BMI output follow the selected measurement system (default metric).

#### Rows: shipped vs planned

This iteration ships **Profile**, **Language & Region**, **Billing & subscription**, and **Payment method** (plus the conditional Advanced section). The table below is the full intended list; rows not marked *shipped* are still future work.

| Group | Rows | Notes |
| :- | :- | :- |
| Account | **Profile** *(shipped)* · Account · Caregiver contacts | Caregiver contacts currently captured inline on `MOB_USER_PROFILE`; may migrate to its own row. |
| Preferences | **Language & Region** *(shipped)* · Notifications · Units | **Region** (on `MOB_LANGUAGE_REGION`) sets the date/number format and the **default** for Units. **Units** = metric ↔ imperial (kg/lb, cm/ft-in); governs the Weight/Height entry fields on `MOB_USER_PROFILE` and the BMI computation. Default metric. Units gets its own row in a later iteration; until then the Region default stands. |
| Subscription | **Billing & subscription** *(shipped)* · **Payment method** *(shipped)* | Direct billing (Stripe-style). Free vs Premium, one paid tier. See the two screen sections below. |
| Advanced *(conditional)* | Debugging · Developer | Gated on build flags; see above. |
| — | About | Standalone, near the bottom. |
| — | Sign out | Destructive treatment (red label, confirm dialog); bottom of the list. |

### Language & Region (`MOB_LANGUAGE_REGION`)

Pushed from the Preferences group. App bar: ‹ back + title "Language & Region". Two grouped rows on one surface card. **Minimal / forward-looking** — no translated content ships in this iteration; the screen exists so the setting has a home and the Region → format/units link is explicit.

* **App language row** — label "App language", trailing value "English", chevron. Tap opens a single-select sheet: **English** (selected, check mark) above a dimmed, non-selectable group — *"More languages coming soon"* — with a few locale names greyed out. Selecting English is a no-op today; the sheet exists so the control is real, not a dead row.
* **Region row** — label "Region", trailing value ("United States"), chevron. Tap opens a searchable single-select country/region list. Region drives two things, stated in a caption below the card: **(1)** date and number formatting app-wide; **(2)** the **default** measurement system for the Units preference (US / Liberia / Myanmar → imperial default; everywhere else → metric). Changing Region after onboarding shows a confirm: *"Change region to United Kingdom? Date format and default units will update. Your saved profile values aren't converted."*
* **Caption** — `{typography.caption}` `{colors.text_secondary}`, below the card: *"Region sets your date format and default units. You can override units later in Preferences."*
* **No bottom nav** — pushed detail screen, not a tab root (same as `MOB_USER_PROFILE` from Settings). Back → `MOB_SETTINGS`.

### Billing & Subscription (`MOB_BILLING`)

Pushed from the Subscription group. App bar: ‹ back + title "Billing & Subscription". Direct billing — the app owns the plan state and renders it in full (no deferral to an OS subscription sheet).

* **Current-plan card** (`SubscriptionPlanCardOrganism`) — the hero. Canonical state `State_SubscriptionPremium`: plan name **"Premium"** with an `{colors.accent_green}` status pill "Active", price + cycle (**"$12.99 / month"** — `[ASSUMPTION]` placeholder price, confirm with product), and **"Renews 6 Oct 2026"** in `{colors.text_secondary}`. `State_SubscriptionFree`: plan name "Free", no pill, no renewal line, and the card's primary action is **"Upgrade to Premium"** instead of the management actions below.
* **What Premium includes** — a short checklist under the card (`{colors.accent_green}` check glyphs): *Doctor report export · Full night-by-night history · Trend analytics*. On the Free plan this same list renders with muted checks as a value preview.
* **Payment method summary row** — a `SettingsMenuRow` (value variant): card icon, "Payment method", trailing "Visa ·· 4242", chevron → `MOB_PAYMENT_METHOD`. On Free with no card: trailing "None".
* **Billing history row** — "View invoices", chevron. `[NOTE FOR UX]` destination (`MOB_INVOICES`) not specified this iteration; row present so the affordance exists.
* **Cancel subscription** — a plainly-labelled `{colors.danger_red}` text button near the bottom (not hidden in a menu), Premium only. Tap → confirm dialog naming the paid-through date: *"Cancel Premium? You'll keep Premium features until 6 Oct 2026, then move to the Free plan."* No retention interstitial, no dark pattern — one confirm, done.
* **No bottom nav.** Back → `MOB_SETTINGS`.

### Payment Method (`MOB_PAYMENT_METHOD`)

Pushed from the Subscription group (and cross-linked from `MOB_BILLING`). App bar: ‹ back + title "Payment Method". A **management** screen for the card on file — **never a card-entry form**.

* **Card-on-file card** (`PaymentMethodCardOrganism`) — canonical state `State_PaymentMethodOnFile`: card-brand mark (Visa), masked number shown only as **"·· ·· ·· 4242"**, **"Expires 08 / 27"**, and the cardholder name. The app displays **only** brand + last 4 + expiry — never the full PAN, never the CVC.
* **Replace card** — primary `ShadButton`. Tap launches the **platform / Stripe PaymentSheet** (the hosted native sheet), not an in-app form — see Interaction Primitives "Hosted Payment Sheet Hand-off". On success: sheet dismisses, the card-on-file card updates in place, and a transient confirmation appears — *"Card updated"*.
* **Remove card** — `{colors.danger_red}` text button. Tap → confirm dialog that states the consequence: *"Remove this card? Premium can't renew without a payment method and will move to Free on 6 Oct 2026."* Removing is allowed (the user may be switching cards out of band) but never silent about the effect.
* **Empty state** `State_PaymentMethodEmpty` — no card on file (e.g. Free plan, or card just removed). The card area is replaced by a quiet placeholder — card glyph + *"No payment method on file."* — and a single primary **"Add card"** button that opens the same PaymentSheet.
* **No bottom nav.** Back → wherever the user entered from (`MOB_SETTINGS` or `MOB_BILLING`).

### Sleep Summary Screen (`MOB_SLEEP_SUMMARY`)

The **Summary** tab root (nav tab 3) and also the screen shown right after a session finalises (`State_MorningSummary`). Scrolling body, `PrimaryNavBarOrganism` docked (Summary active), **no back affordance** — it's a tab root. It shows the most recent session and is the hub for that session's three drill-downs.

```
[ Summary  (header: "Morning Sleep Summary" · date · [📅 History] ) ]
   • Session score card — AI ring + clinical line + status badge (MetricStatCard-family)
   • Apnea-only caveat line
   • Respiration Waveform card ──tap──►  MOB_GRAPH_WAVEFORM      ("View details ›")
   • Metrics: Total Apnea Stops · Safety Taps
   • "Export Signed Report for Physician" ──►  MOB_EXPORT_DOCTOR
   • Header action  [📅 History] ──────────►  MOB_HISTORY_FILTER
```

* **Session score card** — the same two-signal logic as `HomeSummaryCardOrganism` (Component Pattern #10): the badge normally reads the **Apnea Index (AI)** band (`{colors.accent_green}` "Normal range" / amber "Moderate" / red "Severe"), but when the session logged ≥ 1 Tier-1 apnea alarm it switches to the amber **alarm-fired** treatment — amber AI ring, `"N APNEA ALERT"` badge, and the AI band demoted to the clinical line (`"AI 3.2 · normal range"` + `"7h 45m monitoring · 1 'I'm Safe' tap"`). Home and Summary read consistently: if one shows the amber alert, so does the other.
* **Apnea-only caveat line** — a `{typography.caption}` `{colors.text_secondary}` line directly under the score card, always present, in the exact wording defined in §Voice and Tone ("The nightly metric"). It is not an error or warning treatment — plain secondary text. The same sentence is carried into the doctor report (`MOB_EXPORT_DOCTOR`).
* **Header History action** — a calendar-icon pill button top-right, beside the session date. Tap → `MOB_HISTORY_FILTER` (the calendar/date-range list of all past nights). This is the only route to History from the Summary tab — there is no History tab of its own. Back from `MOB_HISTORY_FILTER` returns here.
* **Respiration Waveform card** — a mini plot of the night's **raw bio-signal** with the two **Noise Floor Envelope** bounds drawn as horizontal reference lines; breaths show as excursions past the lines, apneas as flat stretches held between them. It is a **single tap target** (trailing "View details ›" in `{colors.accent_green}`, whole card is the hit area) → `MOB_GRAPH_WAVEFORM` for the pinch/pan interactive timeline and FFT. No litres-per-second axis. The card footnote names the affordance so it doesn't read as a static image.
* **Export button** → `MOB_EXPORT_DOCTOR` (unchanged). On the Free plan this is gated per `MOB_BILLING` (Premium feature) — the button shows a lock and routes to `MOB_BILLING`.
* `MOB_GRAPH_WAVEFORM`, `MOB_HISTORY_FILTER`, and `MOB_EXPORT_DOCTOR` are **pushed detail screens** — `‹` back affordance, **no** bottom nav — each returning to this screen.
* **Accessibility** — the score card is one composite label; the waveform card announces as a button ("Respiration waveform, apnea stop at 12 seconds. Opens interactive timeline."); the History pill announces as "History, opens all sessions".

---

## Voice and Tone

* **Brand Persona:** Reassuring, clear, clinical yet accessible, and empowering.
* **Microcopy Rules:**
  * **Onboarding & Setup:** Encouraging and straightforward (*"Secure your account with native biometrics in seconds"*; *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access"*).
  * **Background Monitoring Notification:** Reassuring and status-oriented, same bucket as onboarding — confirms protection is active rather than reading as generic system chrome. Title *"Sleep Monitoring Ready"*, body *"D-BAND connection active — you're covered tonight."*
  * **Not-Protected Notification:** Same reassuring register, urgency dialed toward "fix this," not toward alarm. Title *"Bluetooth Permission Needed"*, body *"Sleep monitoring can't start until Bluetooth access is granted. Tap to fix."*
  * **iOS System Permission String (`NSBluetoothAlwaysUsageDescription`):** The one native-dialog string this team authors directly — same reassuring register as the primer, since it appears inside Apple's own system alert verbatim: *"This app uses Bluetooth to connect to your D-BAND sensor and monitor your breathing while you sleep."*
  * **Calibration Instructions:** Unambiguous and direct. Idle sample (worn): *"Put on your D-BAND, sit still, and breathe gently for 10 seconds."* Wear check: *"Now take a few normal breaths so we can check the fit."* Wear-check success: *"Calibration Complete — Ready for Sleep ✓"*. Wear-check failure toast: *"Sensor not detecting breathing — check the fit."* with a **Retry** button.
  * **Sleep Monitoring (active):** Calming and quiet — the distinct beat *after* the session has started (Night Mode), not the calibration-complete confirmation above: *"Sleep monitoring is now active."*
  * **Emergency Alerts:** Urgent, high-contrast, and action-oriented (*"BREATHING PAUSE DETECTED — TAP 'I'M SAFE' TO DISMISS"*).
  * **Morning-after alarm recap:** factual, past-tense, not alarming in hindsight. State that it happened and that the person acted — *"1 apnea alert"*, *"you tapped 'I'm Safe' once"* — never *"DANGER"*, *"CRITICAL"*, or a fresh warning tone. It's a record, not a live alert: the night is over and the user is safe. Pair it with the clinical read so the number isn't scary out of context (*"AI 3.2 · normal range"*).
  * **The nightly metric:** always call it the **"Apnea Index"** — spell it out on first use on each screen; "AI" alone only after that. Never "AHI" — the D-BAND scores apnea events only, not hypopneas. Severity words ("Normal range" / "Moderate" / "Severe") are kept. Wherever the score is shown to the user or a clinician, carry this exact caveat verbatim: *"This is an apnea-only screen. A full sleep study also counts shallow-breathing (hypopnea) events and may score higher."* Never imply the number is a diagnosis.
  * **Settings & Navigation:** Plain and utilitarian — no marketing voice. Tab label "Settings"; screen title "Settings"; keep row labels short ("Profile", "Debugging", "Developer"); multi-word only when the concept needs it ("Language & Region", "Billing & subscription", "Payment method"); section headers "Account", "Preferences", "Subscription", "Advanced". Sentence case, no trailing punctuation.
  * **Billing & Subscription:** Direct and non-manipulative — state the price, the billing cycle, and the exact next-charge date in plain words; never a countdown-timer or "limited offer" framing. "Cancel" is a literal, visible label, never softened ("Manage plan" hiding a cancel is a dark pattern — don't). Every irreversible or money-moving action carries a confirm dialog that names the consequence and the date ("You'll keep Premium until 6 Oct 2026, then move to Free").
  * **Payment Method:** Reassuring about security without jargon. Refer to the card by brand + last four only ("your Visa ending 4242"). Never display or ask for a full card number, CVC, or billing address in app copy — those live in the platform payment sheet. Success is quiet and factual: *"Card updated"*, not *"Success! 🎉"*.

---

## Component Patterns (Behavioral Specifications)

### 1. `LiveSignalMonitorOrganism`
*(was `LiveAirflowMonitorOrganism` — renamed v1.3.0; it renders the raw signal, not an airflow rate.)*
* **Behavior:** Renders the continuous 10Hz **raw bio-signal** trace with the two **Noise Floor Envelope** bounds (`lower_bound`, `upper_bound`) drawn as horizontal reference lines. A valid breath reads visually as the trace rising above the upper line (inhale) and dipping below the lower line (exhale); an apnea reads as the trace held flat *between* the two lines. No litres-per-second conversion — the y-axis is the raw signal in sensor units. When display is active, animates smooth cubic-spline curves at 60 FPS. When app enters Night Mode, locks display to pure black `{colors.night_mode}` (`#000000`) with zero frame rendering, reducing power consumption. Even though nothing renders visually in Night Mode, the screen's root semantics node still carries a persistent accessible label — *"Sleep monitoring active — D-BAND connected"* — so a screen-reader user who opens the app mid-session gets immediate confirmation without needing to background the app and read the notification shade.

### 2. `NoiseFloorEnvelopeCalibrationWizardOrganism`
* **Behavior:** A single screen (`MOB_CALIBRATION`) with two sequential steps:
  1. **Idle sample (`State_CalibratingNoiseFloorEnvelope`)** — the D-BAND is **worn**; the app asks the user to hold still and breathe gently for ~10s. It records the running **minimum and maximum** of the raw bio-signal over the window; the result is the **Sensor Baseline Drift & Noise Floor Envelope** `[lower_bound, upper_bound]`. A circular progress ring counts the window down; the live trace shows the envelope tightening.
  2. **Wear check (`State_WearCheck`)** — the app asks the user to take a few normal breaths and must observe **≥ 2 valid envelope-excursion cycles** (the signal rising above `upper_bound` *and* falling below `lower_bound`) before **"Start Sleep Monitoring"** unlocks. If it sees fewer than two within the check window, it holds the gate and shows the toast *"Sensor not detecting breathing — check the fit."* with a **Retry** button.
* Replaces the former two-stage wizard. There is no active-breath *training* step and no `V_pp` / volumetric baseline — the Sensor Baseline Drift & Noise Floor Envelope is the only calibrated reference, and the apnea condition is defined directly against it (signal held inside the envelope).
* On success the screen shows *"Calibration Complete — Ready for Sleep ✓"* and the primary action becomes **"Start Sleep Monitoring"**.

### 3. `ApneaAlertBannerOrganism`
* **Behavior:** Triggered upon 10s breathing stop. Immediately launches full-screen overlay, overrides system volume to maximum (40 dB $\rightarrow$ 75+ dB siren), and pulses device haptic motor. Renders 30s countdown timer. If user taps *"I'M SAFE"*, silences audio immediately and sends safety packet to cloud.

### 4. `PrimaryNavBarOrganism`
* **Behavior:** Persistent bottom navigation across the 4 post-onboarding tabs. Tapping a tab switches the shell's active destination without a page-push animation; the active tab shows `{colors.accent_green}` icon + label, inactive tabs `{colors.text_secondary}`. Tab 4 ("Settings", gear icon) activates `MOB_SETTINGS`. Per-tab navigation state is preserved across switches. Hidden entirely during onboarding and during `State_MonitoringActive` (Night Mode).

### 5. `SettingsMenuRowOrganism`
* **Behavior:** Full-width tappable list row, minimum 48dp height (`{spacing.touch_target_min}`). **Navigable** rows (Profile) show a trailing right chevron and, on tap, push their destination with a light haptic. **Inert** rows (Debugging, Developer) render with no trailing chevron and a `{colors.text_secondary}` label; tap is a no-op. Conditional rows evaluate their build-flag gate at screen-build time — a flag flip takes effect on the next entry to `MOB_SETTINGS`, not live. The "Advanced" `SettingsSectionHeader` and its rows are omitted from the widget tree (not merely hidden) when both `debuggingMode` and `developerMode` are false.

### 6. `DeveloperSimulatorBarOrganism`
* **Behavior:** Controlled by the master **BLE Telemetry Simulator** toggle switch under Settings (`MOB_SETTINGS` / `DeveloperOptionsPage`). When enabled, the app continuously simulates Sensor Baseline Drift & Noise Floor Envelope detection and active nocturnal monitoring (`State_MonitoringActive` on `MOB_SLEEP_MONITOR`). During active monitoring, defaults to `Normal Breathing during sleep` and renders two simulator action buttons (`Stop Breathing during sleep`, `Normal Breathing during sleep`) alongside a live **Detection Mechanism Stage Monitor** card detailing the current stage (Stage 1 Normal Excursions, Stage 2 In-Envelope Flatline Duration, Stage 3 Apnea Breach Siren Countdown).

### 7. `BlePermissionPrimerOrganism`
* **Behavior:** Gated on a permission-state check performed at boot (see §Onboarding above — a revoked permission re-triggers this flow, not just a local "seen it" flag). Single primary CTA ("Allow Bluetooth Access") triggers the native OS permission request directly. On grant, navigates forward to `MOB_DEVICE_PAIRING` and unblocks the AD-12 app-boot receiver Foreground Service for this and all future launches. On denial or partial grant, `MOB_DEVICE_PAIRING` renders `State_BlePermissionDenied` / `State_BlePermissionPartial` instead of its scan UI.

### 8. `BleReceiverForegroundNotification`
* **Behavior:** OS-level chrome, not a Flutter widget — appears the moment the AD-12 receiver's Foreground Service starts (every app boot once permission is granted). Marked "ongoing" (Android): not swipe-dismissible while the service is resident, matching AD-12's "queue survives for next session" invariant. Small monochrome status-bar icon per platform convention (not the full-color launcher icon). Tapping opens the app to its current screen — `MOB_SLEEP_MONITOR` if a session is active, otherwise the last foregrounded screen. This is a **user-initiated** tap-to-open; it does not conflict with the DESIGN.md Do/Don't against notification-initiated screen wake (no heads-up alert, no sound, no auto-opening) — see that entry's cross-reference.

### 9. `BleNotProtectedNotification`
* **Behavior:** The inverse of `BleReceiverForegroundNotification`, and the state's only accessible confirmation. If the AD-12 receiver service fails to start at boot — permission missing, revoked, or only partially granted — the app posts this persistent notification rather than simply omitting the "Sleep Monitoring Ready" one. **Absence of a notification is not an accessible or noticeable cue on its own**, so the negative state gets its own positive, persistent signal, per Voice and Tone's Not-Protected Notification copy. Tapping routes to `MOB_DEVICE_PAIRING`'s blocked state (or straight to the Settings deep-link, per the prior-denial check above). Same "ongoing" / non-swipe-dismissible treatment as its counterpart.

### 10. `HomeSummaryCardOrganism`
* **Behavior:** The hero card on the `MOB_HOME` dashboard. Reads the most recently *finalized* session (`State_MorningSummary` output) and renders its Apnea Index (AI), duration, apnea-event count, and date. If no finalized session exists it renders its empty variant in place (see `State_HomeEmpty`) — decided from session-store state, not a flag — while the rest of the dashboard (greeting, device-status, trend) stays put. The populated card is a single tap target → `MOB_SLEEP_SUMMARY` for that session, light haptic, `{colors.pressed_surface}` pressed background. Does **not** poll; refreshes on tab entry. No loading spinner for the common case — session data is local; a cold read shows the empty variant briefly rather than a skeleton.
* **Alarm-awareness (key behaviour):** the card carries **two independent signals** — *clinical severity* (the Apnea Index band) and *did the alarm fire*. If the session recorded ≥ 1 Tier-1 apnea alarm (`State_ApneaBreach` was reached, whether dismissed by an "I'm Safe" tap or by auto-silence), the card switches to its **alarm-fired override** (DESIGN.md #1a): amber `"N apnea alert(s)"` pill in place of the AI-severity pill, the severity word demoted to a caption, the apnea-events stat in amber. **This is a product-awareness signal, not a clinical one** — a patient whose siren went off in the night must see that on opening the app the next morning, even when the night's AI is squarely in the normal range. The override never *upgrades* a genuinely severe night's pill down; if both apply (severe AI *and* an alarm) the pill reads the alarm and the caption states the severe AI. Screen-reader label leads with the alarm ("Last night: 1 apnea alert. You tapped I'm Safe once. Apnea Index 3.2, normal range…").

### 10a. `DeviceStatusCardOrganism`
* **Behavior:** The "ready for tonight" card on `MOB_HOME`. Reads its data from the **AD-12 receiver service state** (connection, last-known battery level, last sync timestamp, permission state) — never triggers a fresh BLE scan on Home entry (that belongs to `MOB_DEVICE_PAIRING`). Nominal state is inert: green dot, "D-BAND connected", battery %, "Last sync {time}", no chevron, not focusable as a button. It flips to an **actionable** state — red/amber dot, alert text, chevron, button role — on any of: sensor unreachable for > N minutes, battery ≤ 15%, or `BLUETOOTH_CONNECT` missing/revoked. Tapping an actionable card routes to `MOB_DEVICE_PAIRING`'s blocked/recovery state, or to the OS Settings deep-link when the prior-denial check says the OS dialog can't re-fire. Battery percentage is last-known, not live — it shows a "as of {time}" implicitly via the sync line and never animates.

### 10b. `WeeklyTrendCardOrganism`
* **Behavior:** The 7-night Apnea Index trend on `MOB_HOME`. Pulls the last 7 finalized sessions from the local store, renders a 7-slot mini bar chart (`fl_chart`; most recent night full opacity, older nights 60%, a night with no session as a hollow slot) and a computed delta line comparing this 7-day mean to the prior 7-day mean. Delta phrasing is **descriptive only** — "{mean} average · {down/up/level} from {prior} last week" — with colour following direction (`{colors.accent_green}` down, `{colors.text_secondary}` level, `{colors.warning_amber}` up). Fewer than 2 nights of data → the card shows "Not enough data yet — check back after a few nights" and no chart. Tap → `MOB_HISTORY_FILTER`. Never renders a clinical interpretation, a target line, or a "goal" — it reports the number's movement, nothing more (see DESIGN.md Do/Don't on non-diagnostic framing).

### 11. `SubscriptionPlanCardOrganism`
* **Behavior:** The hero card on `MOB_BILLING`. Reads the account's billing state (plan, price, cycle, renewal timestamp, `cancelPending` flag) and renders one of: `State_SubscriptionPremium` (plan + "Active" pill + price/cycle + "Renews {date}"; if `cancelPending`, the pill reads "Ends {date}" in `{colors.warning_amber}` and the Cancel button is replaced by "Resume Premium"), or `State_SubscriptionFree` (plan "Free", no renewal line, primary action "Upgrade to Premium"). Billing state is fetched on screen entry; while in flight the card shows its own inline skeleton (this is a network read, unlike the local session read in #10). The "what Premium includes" checklist is static copy, not fetched. **Upgrade** and **Resume** both route through the same PaymentSheet hand-off as Component Pattern #12 when no valid card is on file; if a card exists, they apply immediately and re-fetch state. Never optimistically show "Premium" before the server confirms.

### 12. `PaymentMethodCardOrganism`
* **Behavior:** Renders the card on file for `MOB_PAYMENT_METHOD` and the summary row on `MOB_BILLING`. Displays **only** the tokenised brand, last four, and expiry returned by the billing backend — the app never receives, stores, or renders the full PAN or CVC. **Add / Replace** invokes the platform payment sheet (see Interaction Primitives "Hosted Payment Sheet Hand-off"); the app passes a client secret to the sheet and gets back a payment-method token, nothing more. On the sheet's success callback the organism re-fetches and updates in place, then shows a transient *"Card updated"* confirmation (no full-screen success state). **Remove** calls the backend detach endpoint only after the consequence-naming confirm dialog resolves; on success the organism drops to `State_PaymentMethodEmpty`. Sheet dismissal without completion is a no-op — no error toast, the existing card stands.

---

## State Patterns

1. **`State_Idle`:** App launched, awaiting Passkey authentication or sensor connection.
2. **`State_CalibratingNoiseFloorEnvelope`:** D-BAND worn, user still; sampling ~10s to record the running min/max of the raw bio-signal → the Sensor Baseline Drift & Noise Floor Envelope `[lower_bound, upper_bound]`.
3. **`State_WearCheck`:** User takes a few normal breaths; the app waits for ≥ 2 valid envelope-excursion cycles before unlocking "Start Sleep Monitoring". On failure: blocked with the *"Sensor not detecting breathing — check the fit."* toast + Retry.
4. **`State_MonitoringActive`:** 0-FPS Night Mode `#000000`, 10Hz background stream active into circular RAM buffer.
5. **`State_ApneaBreach`:** Airflow dropped $\ge 90\%$ for $\ge 10\text{s}$. Escalating local mobile siren & haptics active.
6. **`State_PatientSafe`:** Alarm acknowledged via "I'm Safe" tap or 5s breathing recovery. Siren silenced.
7. **`State_MorningSummary`:** Session finalized, rendering the Apnea Index (AI) score, duration, and interactive Skia GPU charts. If the session reached `State_ApneaBreach` at least once, both this screen's score card and the `MOB_HOME` last-night card carry the **alarm-fired** treatment (amber `"N apnea alert(s)"` badge/pill, AI band demoted to a caption) regardless of the AI band — see Component Pattern #10 and DESIGN.md #1a.
8. **`State_SettingsDefault`:** `MOB_SETTINGS` open with `debuggingMode == false && developerMode == false`. Renders the **Account** (Profile), **Preferences** (Language & Region), and **Subscription** (Billing & subscription, Payment method) groups with their headers — no "Advanced" header, no section.
9. **`State_SettingsAdvanced`:** `MOB_SETTINGS` open with `debuggingMode || developerMode`. Renders everything in `State_SettingsDefault` plus an "Advanced" section header and whichever of the Debugging / Developer rows are individually enabled.
10. **`State_BlePermissionPriming`:** `MOB_BLE_PERMISSION_PRIMER` shown, first run only, before the native OS Bluetooth permission dialog fires.
11. **`State_BlePermissionDenied`:** The OS-level Bluetooth permission was fully denied (or the platform's dialog can no longer fire after a prior denial). `MOB_DEVICE_PAIRING` renders a blocked state (no scan UI) with an "Open Settings" recovery CTA in place of the normal pairing flow.
12. **`State_BlePermissionPartial`:** Android only. One of `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` was granted and the other denied — the OS presents these as separate sequential dialogs, so a partial outcome is possible. Treated the same as `State_BlePermissionDenied` for `MOB_DEVICE_PAIRING` purposes (same blocked state and "Open Settings" CTA, since the receiver needs both), but the blocked-state copy names the specific missing permission.
13. **`State_BleNotProtected`:** The AD-12 receiver service is not running while the app would otherwise expect to monitor (permission missing, revoked, or partially granted). Surfaced via `BleNotProtectedNotification` — a positive, persistent, accessible signal, not merely the absence of `BleReceiverForegroundNotification`.
14. **`State_HomeDefault`:** `MOB_HOME` open with a paired sensor and ≥ 1 finalized session. Full dashboard: greeting + streak, populated `HomeSummaryCardOrganism`, nominal `DeviceStatusCardOrganism`, `WeeklyTrendCardOrganism` with a chart. Tab-1 nav active. Default screen on every launch after onboarding.
15. **`State_HomeEmpty`:** `MOB_HOME` open with a paired sensor but no finalized session yet (e.g. reopened after an aborted first night). Dashboard frame intact; the summary card shows its placeholder (*"No sleep data yet. Start tonight's session from the Monitor tab."*), the trend card shows *"Not enough data yet"*, streak reads *"First night tonight"*. The device-status card still renders normally. Resolves to `State_HomeDefault` after the first session finalizes.
15a. **`State_HomeNoDevice`:** `MOB_HOME` with no D-BAND paired (sensor unpaired in Settings, or a factory-reset device). The device-status card shows `{colors.danger_red}` + *"No sensor paired"* + chevron → `MOB_DEVICE_PAIRING`. Other cards behave per their own data. Distinct from `State_HomeEmpty` because the fix is different (pair a sensor, not run a session).
15b. **`State_HomeDeviceAlert`:** `MOB_HOME` where the device-status card is in an actionable state (unreachable / battery ≤ 15% / permission missing) while the rest of the dashboard is normal. The card carries the alert styling and button role described in Component Pattern #10a; nothing else on the screen changes.
16. **`State_LanguageRegionDefault`:** `MOB_LANGUAGE_REGION` open. App language row shows "English"; Region row shows the stored region ("United States" by default). The language sheet, when opened, lists English selected above a dimmed "coming soon" group.
17. **`State_SubscriptionPremium`:** `MOB_BILLING` for an account on the paid tier. `SubscriptionPlanCardOrganism` shows "Premium" + "Active" pill + price/cycle + "Renews {date}"; management actions (payment method row, Cancel subscription) visible. If `cancelPending`, pill reads "Ends {date}" and "Cancel" becomes "Resume Premium".
18. **`State_SubscriptionFree`:** `MOB_BILLING` for a Free account. Card shows "Free", no renewal line, primary action "Upgrade to Premium"; the "what Premium includes" list renders as a muted preview; payment-method row reads "None" if no card is on file.
19. **`State_PaymentMethodOnFile`:** `MOB_PAYMENT_METHOD` with a card on file. `PaymentMethodCardOrganism` shows brand + "·· ·· ·· {last4}" + "Expires {mm} / {yy}" + cardholder; actions "Replace card" (primary) and "Remove card" (destructive).
20. **`State_PaymentMethodEmpty`:** `MOB_PAYMENT_METHOD` with no card (Free account, or card just removed). Placeholder — card glyph + *"No payment method on file."* — with a single "Add card" button that opens the payment sheet.

---

## Interaction Primitives

* **Pinch-to-Zoom & Pan:** Interactive 60 FPS gesture controls on `MOB_GRAPH_WAVEFORM` allowing patients to zoom into 8-hour overnight respiration timelines and inspect 256-point FFT spectral peaks.
* **Single-Tap Emergency Dismiss:** Prominent 64dp primary action button on `MOB_TIER1_ALARM` enabling single-tap alarm cancellation without requiring fine motor precision in dark rooms.
* **Auto-Silence Recovery:** Automatic alarm cancellation if natural breathing resumes continuously for 5 seconds ($V_{\text{net}} > \text{Threshold}_{\text{normal}}$).
* **List-Row Navigation & Back Stack:** Tapping a navigable `SettingsMenuRow` pushes its destination with the platform-standard slide transition; the pushed screen carries an app-bar back affordance (‹). Back from `MOB_USER_PROFILE` (entered via Settings) returns to `MOB_SETTINGS`; a second back returns to the originating tab.
* **OS Permission Hand-off:** The app never layers its own dialog on top of the OS's — see Component Pattern #7 and §Onboarding "Handoff" for the full sequencing.
* **Hosted Payment Sheet Hand-off:** All card capture happens in the platform / Stripe payment sheet, never an in-app form. The app requests a client secret from its billing backend, presents the sheet, and receives back only a payment-method token — it never touches the PAN, CVC, or billing address (keeps the client outside PCI-DSS scope). Same principle as the OS permission hand-off: the app frames *why* first (the Payment Method screen's context), then hands the sensitive step to the trusted system UI. Sheet cancellation is a silent no-op; sheet success triggers a re-fetch, not an optimistic UI update.

---

## Accessibility Floor

* **Visual Contrast:** All text meets or exceeds WCAG 2.1 AA contrast ratio ($\ge 4.5:1$) against dark surfaces `{colors.surface}` (`#1E293B`).
* **Touch Targets:** Minimum height $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) for standard controls; $64\text{dp}$ (`{spacing.emergency_button}`) for emergency dismiss buttons.
* **Multi-Sensory Feedback:** Emergency alerts combine high-contrast flashing red overlays (`#FF3B30`), 120dB audio sirens, and strong haptic vibration patterns for users with hearing or visual impairments.
* **Navigation Labels:** Every bottom-nav tab and every `SettingsMenuRow` exposes a text label (never icon-only) to assistive tech. Inert rows (Debugging, Developer) are announced with a dimmed, not-actionable state rather than being silently unfocusable. The "Settings" tab and screen share the accessible name "Settings". A `SettingsMenuRow` with a trailing value string exposes label + value as one accessible name ("Language & Region, English"); the value is not a separately-focusable node.
* **Payment Data Exposure:** The card-on-file view and its accessible label expose only card brand, last four digits, and expiry ("Visa ending 4242, expires August 2027") — never a full card number, and never read digit-by-digit. This is a security floor as much as an accessibility one: there is no UI state, anywhere, that renders a full PAN or CVC.
* **Section Header Semantics:** "Account", "Preferences", "Subscription", and "Advanced" are exposed as heading-level semantics (not plain text), so screen-reader users can navigate the Settings list by group.
* **Settings Touch Targets:** Each `SettingsMenuRow` is $\ge 48\text{dp}$ tall (`{spacing.touch_target_min}`) with the full row width as the hit area.
* **Permission Priming Touch Target:** The `MOB_BLE_PERMISSION_PRIMER` primary CTA meets the $\ge 48\text{dp}$ (`{spacing.touch_target_min}`) minimum. Screen-reader traversal order alone doesn't guarantee reading order for a touch-exploring user (VoiceOver/TalkBack "explore by touch" lands wherever the finger first touches) — so when the screen appears, initial accessibility focus is set programmatically to the headline/rationale text, not left to tree order alone, ensuring the rationale is announced before the CTA regardless of where the user first touches.
* **Night Mode Accessible State:** `State_MonitoringActive` renders zero pixels by design, but its root semantics node still carries the persistent accessible label described under `LiveSignalMonitorOrganism` — a screen-reader user is never left with literally nothing to query.
* **Notification Text:** Both `BleReceiverForegroundNotification` and `BleNotProtectedNotification` expose their full title and body as accessible text (never icon-only), consistent with the Navigation Labels bullet above. Together they ensure "am I protected right now" always has a positive, accessible answer — never inferred from the absence of a notification.

---

## Key Flows (Named Protagonist Journey)

### Protagonist: David (Age 48, At-Home High-Risk Sleep Apnea Patient)

1. **10:15 PM — Bedtime Passkey Login (`MOB_PASSKEY_AUTH`):**  
   David opens the app at bedtime. He authenticates instantly using Face ID / Touch ID via passwordless FIDO2 Passkey (`{colors.primary}` background).
2. **10:20 PM — Bluetooth Access Priming (`MOB_BLE_PERMISSION_PRIMER`, first run only):**  
   On his very first night with the app, David sees one extra screen: *"To find your D-BAND sensor and keep monitoring active overnight, allow Bluetooth access."* He taps *"Allow Bluetooth Access"* and grants the native OS prompt that follows. On every future night, this step no longer appears.
3. **10:25 PM — D-BAND Sensor Discovery (`MOB_DEVICE_PAIRING`):**  
   David powers on his ductless D-BAND sensor. The app auto-discovers and pairs via BLE (BLE 4.0, 4.1, 4.2, 5.0+), rendering a green checkmark badge (`{colors.accent_green}`).
4. **10:30 PM — Sensor Baseline Drift & Noise Floor Envelope Calibration (`MOB_CALIBRATION`):**  
   With the D-BAND on, David holds still for ~10s while the app learns its **Sensor Baseline Drift & Noise Floor Envelope** (the min/max of the resting signal). Then he takes a few normal breaths; the app confirms it can see them cross both envelope lines and the screen displays *"Calibration Complete — Ready for Sleep ✓"*. David taps *"Start Sleep Monitoring"*.
5. **10:31 PM — Night Mode Display Lock (`MOB_SLEEP_MONITOR`):**  
   The screen switches to 0-FPS pitch black `{colors.night_mode}` (`#000000`) with a dim pulsing green dot. In the notification shade, a quiet *"Sleep Monitoring Ready — D-BAND connection active"* notification confirms the receiver is running, without lighting up his screen.
6. **02:15 AM — Apnea Breach & Emergency Siren (`MOB_TIER1_ALARM`):**  
   David suffers a 12-second airway blockage. The app immediately triggers an escalating 75+ dB audio siren and full-screen flashing red overlay (`{colors.danger_red}`).
7. **02:15 AM — Safety Dismissal:**  
   Awakened by the alarm, David taps the large 64dp *"I'M SAFE"* button. The siren silences instantly, logging a safety event.
8. **07:00 AM — Morning Sleep Summary (`MOB_SLEEP_SUMMARY`):**  
   David taps *"End Sleep Session"*, viewing his morning Apnea Index (`AI 3.2 · Normal`), duration (7h 45m), and the raw-signal waveform with its Noise Floor Envelope lines. A caption notes it's an apnea-only screen.
9. **07:02 AM — Back to Home (`MOB_HOME`):**  
   He backs out to the Home tab — the dashboard he'll open every day now. *"Good morning · 12 nights monitored."* Below it: last night's card (**AI 3.2 · Normal**, 7h 45m, 2 events); then *"D-BAND connected · 84% · Last sync 7:02 AM"* in calm green — the sensor's already back on the charger and reporting; then the 7-night Apnea Index trend, *"3.4 average · down from 4.1 last week."* He reads it in four seconds, taps nothing, and puts the phone down. (Tonight he'll start the next session from the **Monitor** tab.)

### Secondary Flow: David corrects his weight (`MOB_SETTINGS` → `MOB_USER_PROFILE`)

1. **08:10 AM — Opening Settings:**  
   Over coffee on the Home tab, David remembers he weighed in lighter this week. He taps the **Settings** tab (gear icon, tab 4). The Settings screen slides in — grouped: **Account** (Profile), **Preferences** (Language & Region), **Subscription** (Billing & subscription · Payment method). No "Advanced" section — his build has neither debugging nor developer mode on.
2. **08:10 AM — Into the Profile:**  
   He taps **Profile** under Account. `MOB_USER_PROFILE` pushes in, pre-filled with his saved baseline.
3. **08:11 AM — The edit (climax beat):**  
   David changes Weight to `82`. The Computed BMI field updates live to **25.9** — the number ticking down is the small, satisfying confirmation that the app already knows him. He taps **Save**.
4. **08:11 AM — Back out:**  
   One back tap returns him to Settings; a second returns him to the Home tab he started from.

### Secondary Flow: David replaces an expiring card (`MOB_SETTINGS` → `MOB_BILLING` → `MOB_PAYMENT_METHOD`)

1. **09:40 PM — A quiet nudge:**  
   A week before his card expires, David's Home screen is unchanged, but the **Payment method** row in Settings now shows a small amber dot. He opens **Settings** → **Subscription** and sees "Payment method — Visa ·· 4242" with the dot.
2. **09:40 PM — Into Billing:**  
   He taps **Billing & subscription** first out of habit. `MOB_BILLING` shows **Premium · Active**, *$12.99 / month*, *Renews 6 Oct 2026*, and the same payment-method row with the amber dot. He taps it.
3. **09:41 PM — Payment Method:**  
   `MOB_PAYMENT_METHOD` shows his Visa ending 4242, *Expires 08 / 27*. He taps **Replace card**.
4. **09:41 PM — The hand-off (climax beat):**  
   The platform payment sheet slides up — Apple Pay at the top, a card field below. David double-clicks the side button to confirm with Face ID. The sheet dismisses. The card on file flips to *Visa ·· 8813, Expires 05 / 29*, and a small *"Card updated"* note fades in and out. The amber dot is gone. He never typed a card number into the app.
5. **09:41 PM — Back out:**  
   Two back taps: `MOB_PAYMENT_METHOD` → `MOB_BILLING` → Settings. Renewal date unchanged — nothing about his plan moved, only the card behind it.
