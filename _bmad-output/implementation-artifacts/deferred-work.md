# Deferred Work

Findings surfaced during build reviews that were intentionally not addressed in their originating story. Append-only.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Inert Settings rows (Debugging / Developer) are not announced to assistive tech as disabled / not-actionable.
  evidence: EXPERIENCE.md v1.1.0 Accessibility Floor requires inert rows be "announced with a dimmed, not-actionable state rather than being silently unfocusable." `SettingsMenuRow`'s inert variant renders a plain `Row` with no `Semantics(enabled: false)`. The whole app currently has zero `Semantics` usage, so this is an app-wide accessibility gap, not a regression from this change — worth a focused a11y pass.

- source_spec: `spec-settings-page-and-nav.md`
  summary: Row dividers in the Settings list are handled ad hoc in `settings_page.dart`, not by the `SettingsMenuRow` component.
  evidence: DESIGN.md §6 specifies a "1px #334155 divider between rows (never after the last)." This build only has the single Profile row plus a manual `Divider` between Debugging/Developer, so it is not yet a defect. When the planned rows (Notifications, Account, Sign out, About, Caregiver contacts) land, divider handling should move into the component or a shared list wrapper.
