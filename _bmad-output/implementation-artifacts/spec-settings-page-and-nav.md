---
title: 'Settings page and bottom-nav Profile→Settings swap'
type: 'feature'
created: '2026-09-02'
status: 'done'
baseline_commit: 'bf9fbea93ef7184ebe76105453ada48b87dcb7d2'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Medical Profile screen occupies bottom-nav tab 4 directly, so the app has no home for settings and no place to surface build-gated developer affordances. EXPERIENCE.md v1.1.0 defines a Settings surface to fill that gap.

**Approach:** Replace tab 4 (Profile / person icon) with Settings (gear icon). Tab 4 renders a new `SettingsPage` inline, like the other tabs. `SettingsPage` shows a "Profile" row that pushes the existing `ProfilePage`, plus a conditional "Advanced" section holding inert "Debugging" (when `kDebugMode`) and "Developer" (when `--dart-define=DEV_MODE=true`) rows. The "Advanced" header renders only when at least one of those rows is present.

## Boundaries & Constraints

**Always:**
- Tab 4 stays inline in the existing `IndexedStack`; only the Profile row pushes (`MaterialPageRoute` → `const ProfilePage()`).
- Debugging and Developer rows are inert: rendered, no `onTap`, no chevron, `AppColors.textSecondary` label.
- Flags: `kDebugMode` (`package:flutter/foundation.dart`) and `bool.fromEnvironment('DEV_MODE', defaultValue: false)`, both overridable via `SettingsPage` constructor params (null → real flag) so every state is testable.
- Reuse `AppColors` tokens and the existing card idiom (surface fill, `AppColors.cardBorder`, `BorderRadius.circular(16)`).
- `flutter analyze` stays clean; all new widgets covered by widget tests.

**Ask First:**
- Any change to `ProfilePage` itself (fields, modes, copy).
- Adding a routing package or named routes.
- Wiring real behavior into the Debugging / Developer rows.

**Never:**
- No first-run vs. edit-mode split, no Units preference, none of the other planned rows (Notifications, Account, Sign out, About, Caregiver contacts) — all roadmap.
- Do not restyle or reorder the other three tabs; do not delete `profile_page.dart` or its test.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior |
|----------|--------------|---------------------------|
| Settings tab | Tap bottom-nav tab 4 | `SettingsPage` renders inline; nav item is gear icon + "Settings"; no "Profile" tab |
| Open Profile | Tap "Profile" row | Pushes `ProfilePage` (AppBar "Medical Profile"); back returns to `SettingsPage`, nav still on tab 4 |
| Both flags off | `kDebugMode` false, `DEV_MODE` unset | Only "Profile" row; no "Advanced" header |
| Debugging on | `debuggingEnabled` true only | "Profile" + "Advanced" header + inert "Debugging"; no "Developer" |
| Developer on | `developerEnabled` true only | "Profile" + "Advanced" header + inert "Developer"; no "Debugging" |
| Tap inert row | Tap "Debugging" or "Developer" | No navigation, no state change |

</frozen-after-approval>

## Code Map

- `flutter/lib/ui/pages/main_container_page.dart` -- bottom-nav host. `_pages` (lines 18-23) index 3 = `ProfilePage()`; `items` (lines 49-70) index 3 = person icon + "Profile". Swap both to `SettingsPage()` / `Icons.settings_outlined`+`Icons.settings` + "Settings"; fix imports.
- `flutter/lib/ui/pages/profile_page.dart` -- READ-ONLY. Already a self-contained `Scaffold`+`AppBar` (lines 34-51), so `Navigator.push` yields a back arrow for free.
- `flutter/lib/core/theme/app_theme.dart` -- `AppColors` (lines 4-22). Add `static const Color pressedSurface = Color(0xFF273449);` (DESIGN.md `colors.pressed_surface`).
- `flutter/lib/ui/molecules/history_tile.dart` -- reference for the card idiom (Container + BoxDecoration, `cardBg`, radius 16, `cardBorder`).
- `flutter/test/ui/profile_page_test.dart` -- reference for the widget-test idiom (`MaterialApp(home:)`, `find.text`, `tester.tap` / `pump`).
- No `Navigator.push`, `kDebugMode`, or `bool.fromEnvironment` exists in `lib/` yet — this is the first.

## Tasks & Acceptance

**Execution:**
- [x] `flutter/lib/core/theme/app_theme.dart` -- add `AppColors.pressedSurface` (`0xFF273449`) -- token for the menu-row pressed state.
- [x] `flutter/lib/ui/molecules/settings_menu_row.dart` -- new `SettingsMenuRow({required IconData leadingIcon, required String label, VoidCallback? onTap})`. `onTap != null`: `InkWell` (highlight `AppColors.pressedSurface`), `textPrimary` label, trailing `Icons.chevron_right`. `onTap == null`: not tappable, `textSecondary` label, no chevron. Min height 48.
- [x] `flutter/lib/ui/molecules/settings_section_header.dart` -- new `SettingsSectionHeader(this.label)`: caption text, `textSecondary`, `EdgeInsets.only(top: 24, left: 4, bottom: 8)`, `letterSpacing: 0.4`.
- [x] `flutter/lib/ui/pages/settings_page.dart` -- new `SettingsPage({bool? debuggingEnabled, bool? developerEnabled})`; resolve nulls to `kDebugMode` / `bool.fromEnvironment('DEV_MODE')`. `Scaffold` (no AppBar) → in-body "Settings" heading → `SafeArea` → scroll view → grouped surface card(s): always "Profile" (`Icons.person_outline`, pushes `const ProfilePage()`); when either flag, `SettingsSectionHeader('Advanced')` then inert "Debugging" (`Icons.bug_report_outlined`) if debugging and inert "Developer" (`Icons.code`) if developer.
- [x] `flutter/lib/ui/pages/main_container_page.dart` -- index 3 → `SettingsPage()`; nav item → gear icon + "Settings"; swap the `profile_page.dart` import for `settings_page.dart`.
- [x] `flutter/test/ui/settings_page_test.dart` -- new; via injected flags cover the I/O matrix: both false → only Profile, no "Advanced"; debugging true → "Advanced" + "Debugging", no "Developer"; developer true → "Developer"; tap "Profile" → pushes ProfilePage and `pageBack` returns to Settings; tap "Debugging" → still on Settings.
- [x] `flutter/test/ui/main_container_page_test.dart` -- new (added during impl for I/O-matrix row 1 coverage); asserts nav item 4 is gear + "Settings", no "Profile" tab, and activating tab 4 shows `SettingsPage` inline. Drains the pre-existing `MeasurementPage` BLE-scan timers that `IndexedStack` mounts.

**Acceptance Criteria:**
- Given the main container, when the user views the bottom nav, then tab 4 is a gear icon labelled "Settings" and no "Profile" tab exists.
- Given `SettingsPage` is visible, when the user taps "Profile", then `ProfilePage` is pushed and back returns to `SettingsPage` with the bottom nav still on tab 4.
- Given both flags are off, when `SettingsPage` renders, then only "Profile" shows and no "Advanced" header appears.
- Given the inert rows are visible, when the user taps "Debugging" or "Developer", then nothing happens.
- Given the suite, when `flutter analyze` and `flutter test` run, then both pass clean.

## Design Notes

Flag resolution + testability pattern for `settings_page.dart`:

```dart
class SettingsPage extends StatelessWidget {
  final bool? debuggingEnabled;
  final bool? developerEnabled;
  const SettingsPage({super.key, this.debuggingEnabled, this.developerEnabled});

  bool get _debug => debuggingEnabled ?? kDebugMode;
  bool get _dev => developerEnabled ?? const bool.fromEnvironment('DEV_MODE');
  bool get _showAdvanced => _debug || _dev;
}
```

`MainContainerPage` uses `const SettingsPage()` so production reads the real flags. Card radius stays `16` to match every other card in the app rather than DESIGN.md's 8px `{rounded.md}`; the app already diverges there and realigning one card would look worse. Flag for a later token cleanup, out of scope here.

## Verification

**Commands:**
- `cd flutter && flutter analyze` -- expected: "No issues found!"
- `cd flutter && flutter test` -- expected: all pass, including `settings_page_test.dart`.

**Manual checks:**
- `flutter run` (debug): tab 4 reads "Settings" with a gear icon; the list shows Profile + Advanced(Debugging); tapping Profile opens the Medical Profile screen with a working back arrow to Settings.

## Suggested Review Order

**Build-flag gating & screen composition** — start here for design intent

- Flag resolution: constructor overrides fall back to `kDebugMode` / `DEV_MODE`, keeping every state testable.
  [`settings_page.dart:23`](../../flutter/lib/ui/pages/settings_page.dart#L23)
- The whole Advanced section (header + rows) is omitted from the tree unless a flag is set; each row is individually gated.
  [`settings_page.dart:68`](../../flutter/lib/ui/pages/settings_page.dart#L68)
- The only navigation in the change: Profile row pushes the untouched `ProfilePage`, which supplies its own back arrow.
  [`settings_page.dart:60`](../../flutter/lib/ui/pages/settings_page.dart#L60)

**Row component (navigable vs inert)**

- One widget, two variants keyed off `onTap == null`: inert = no `InkWell`, no chevron, muted label.
  [`settings_menu_row.dart:23`](../../flutter/lib/ui/molecules/settings_menu_row.dart#L23)
- Inert rows return the bare row; navigable rows wrap it in `Material`+`InkWell` with the pressed-surface highlight.
  [`settings_menu_row.dart:54`](../../flutter/lib/ui/molecules/settings_menu_row.dart#L54)

**Navigation swap**

- `IndexedStack` slot 3 goes from `ProfilePage` to `SettingsPage` — the tab stays inline, no pushed-route tab.
  [`main_container_page.dart:22`](../../flutter/lib/ui/pages/main_container_page.dart#L22)
- Nav item 3: person icon + "Profile" → gear icon + "Settings".
  [`main_container_page.dart:66`](../../flutter/lib/ui/pages/main_container_page.dart#L66)

**Supporting**

- New color token for the menu-row pressed state (`#273449`, DESIGN.md `colors.pressed_surface`).
  [`app_theme.dart:15`](../../flutter/lib/core/theme/app_theme.dart#L15)
- `SettingsSectionHeader` — presentational caption, rendered only above a non-empty section.
  [`settings_section_header.dart:10`](../../flutter/lib/ui/molecules/settings_section_header.dart#L10)
- Conditional-visibility matrix, chevron contract, Profile push + back.
  [`settings_page_test.dart:21`](../../flutter/test/ui/settings_page_test.dart#L21)
- Nav item + inline-body assertions; drains the pre-existing `MeasurementPage` BLE timers.
  [`main_container_page_test.dart:7`](../../flutter/test/ui/main_container_page_test.dart#L7)
