---
title: Sprint Change Proposal — FR-1.11 / AD-12 Artifact Propagation Verification
date: 2026-09-04
author: Reid Lai (reidlai.ca@gmail.com)
status: proposed
---

# Sprint Change Proposal: FR-1.11 / AD-12 Artifact Propagation Verification

## 1. Issue Summary

`bmad-review` was run against the branch `ble-signal-rx-and-simulator`, and it was unclear whether that run had updated the PRD, architecture, UX, or epics artifacts. Verification (this session) found:

- `bmad-review` is a read-only critique skill — it never edits artifacts. It did not touch any planning document.
- The actual edits on this branch came from a separate **`bmad-architecture` update pass**, tracked in [`_bmad-output/architecture/.memlog.md`](architecture/.memlog.md), which folded PRD requirement **FR-1.11** ("App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue") into the architecture spine as new invariant **AD-12**.
- That pass left three explicit follow-ups unresolved, which is what this proposal verifies and closes out.

## 2. Impact Analysis

| Artifact | Impact |
|---|---|
| PRD (`prd.md`) | None needed — FR-1.11 already present, `version: 2.2.0`. Committed in `081fe68`. |
| PRD HTML (`prd.html`) | None needed — already re-rendered (uncommitted, +9/−6). |
| Architecture (`ARCHITECTURE-SPINE.md`) | None needed — AD-12 already fully authored (uncommitted, frontmatter `19.0.0 draft`). |
| Architecture HTML (`ARCHITECTURE-SPINE.html`) | **Stale.** `.md` changed substantially (+186/−178: new AD-12, amended AD-02 cross-ref, §1.2, C4 L3 + traceability, Sequence Diagram 4 Phase 0, §3.7.2, new §3.7.4, §5.2.2, §6); HTML not regenerated. |
| Epics (`epics.md`) | **Verified complete — no edit needed.** See Section 3. |
| UX (`DESIGN.md` / `EXPERIENCE.md`) | **Real gap found.** No coverage of the Android Foreground Service persistent notification or the OS "always allow Bluetooth" background-permission priming that AD-12/FR-1.11 requires at runtime. See Section 3. |
| Code (`flutter/lib/...`) | Not in scope of this proposal — tracked separately, see Section 3 item 3. |

## 3. Detailed Findings / Change Proposals

### 3.1 Epics — verified complete, no change

Checked `_bmad-output/epics.md` for FR-1.11 traceability:

- FR list: line 38 (full requirement text present).
- Traceability map: line 115, `FR-1.11 → Epic 2`.
- Epic 2 "FRs covered": line 146, includes `FR-1.11`.
- **[Story 2.4: App-Boot Background BLE Receiver & RxDart Reactive Streaming Queue](epics.md:282)** — full Given/When/Then acceptance criteria matching AD-12's shape (foreground service / `bluetooth-central` boot start, `BehaviorSubject<double>` queue, unified consumption by `MeasurementPage`, `ApneaEvaluator`, `BleBloc`). Already implemented per commit `d25dfbf`.

`epics.md` does not track architecture-decision IDs (`AD-n`) at all — by design it links Epics/Stories to FR/NFR/UX-DR only, and architecture rationale lives in the spine. The memlog's phrasing ("refresh epics.md ... with FR-1.11 → AD-12") is already satisfied by the existing FR-1.11 wiring; there is no structural field to add an AD-12 reference into.

**Recommendation:** No edit. Close this follow-up as verified.

### 3.2 Architecture HTML — deferred, out of scope (user decision 2026-09-04)

`ARCHITECTURE-SPINE.html` is not produced by any script in this repo — its markup carries the signature of a VS Code markdown-preview export extension, not a BMad skill step. **Reid has decided to ignore/skip regenerating it as part of this proposal.** The `.md` remains the source of truth and stays ahead of the `.html`; re-export is left entirely to Reid's discretion, whenever/if ever convenient. No action item, no handoff.

### 3.3 UX — gap confirmed, routed to UX designer

`DESIGN.md` and `EXPERIENCE.md` were searched for `notification|permission|foreground|background|bluetooth`. The only hit is a generic "Notifications" preferences toggle (push/caregiver alerts) — unrelated to AD-12. Neither doc addresses:

- The Android **Foreground Service** persistent notification (icon, title/body copy, tap target) that AD-12 requires to run legally in the background.
- An **OS Bluetooth background-permission priming step** (Android 12+ `BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN`, iOS `bluetooth-central` background mode disclosure) that a patient will see once, likely during onboarding.

This is small in surface area (no new screen — OS-level chrome plus possibly one priming dialog) but is a genuine product/UX decision (notification copy, whether a priming screen is needed, iconography), not something to improvise into the design doc unreviewed.

**Recommendation:** Route to `bmad-agent-ux-designer` / `bmad-ux` for a short addendum to `EXPERIENCE.md` (persistent-notification spec + permission-priming flow, if any) before this ships to a device that enforces the OS-level prompts.

### 3.4 Open item carried forward from the architecture pass (not new)

The architecture memlog itself flagged one still-unconfirmed reading of FR-1.11: the spine assumes the **radio connection is lazy** (established when a bound D-BAND is in range or first needed) while the **receiver service + queue are eager** (start at boot). The alternative reading is a truly always-on radio link from launch. This determines whether AD-12/Story 2.4 as implemented is correct, and is why the spine is deliberately left `status: draft`.

**Recommendation:** You (Reid) confirm the intended reading; then the architecture skill flips the spine to `final`.

### 3.5 Known code gap (tracked, out of scope here)

Also logged in the architecture memlog, for `bmad-build` to pick up separately: `FlutterBlueSensorDriver.disconnect()` currently calls `_thermalStreamController.close()`, which contradicts AD-12 ("queue survives for next session"). Not touched by this proposal.

## 4. Recommended Approach

**Direct Adjustment** — no rollback, no MVP scope change. Two of the three flagged follow-ups are already satisfied (epics, PRD); the remaining two are small, well-scoped tasks:

- Architecture HTML regen: mechanical, owned by you (editor export).
- UX notification/permission addendum: a short UX design task.

No epic/story rework, no architecture rework required beyond your FR-1.11 interpretation confirmation (3.4).

## 5. Implementation Handoff

| Item | Scope | Owner | Action |
|---|---|---|---|
| 3.1 Epics traceability | Verified, no-op | — | Close out. |
| 3.2 Architecture HTML | **Dropped** | — | Explicitly out of scope per Reid, 2026-09-04. |
| 3.3 UX notification/permission spec | **Closed** | `bmad-agent-ux-designer` / `bmad-ux` | Done 2026-09-04. `DESIGN.md` + `EXPERIENCE.md` bumped 1.1.0 → 1.2.0 (status stays `final`): new `MOB_BLE_PERMISSION_PRIMER` screen, `BleReceiverForegroundNotification` + `BleNotProtectedNotification`, 4 new states, plus accessibility fixes surfaced by the reviewer gate (partial-permission-grant state, Night Mode accessible label, iOS one-shot-dialog handling, `NSBluetoothAlwaysUsageDescription` copy). See `.memlog.md` in the UX workspace for full decision trail. |
| 3.4 FR-1.11 interpretation confirmation | Moderate (blocks spine finalization) | You (Reid) | Confirm lazy-radio/eager-queue reading; architecture skill then flips spine `draft → final`. |
| 3.5 `disconnect()` close() fix + `main.dart` bootstrap + FGS/bluetooth-central plumbing | Minor–Moderate | `bmad-build` / Developer agent | Separate build task, not part of this proposal. |

**Success criteria:** spine reaches `status: final`, and `EXPERIENCE.md` documents the FGS notification + any permission-priming flow — at which point FR-1.11 is fully propagated across PRD, architecture, epics, and UX (HTML regen intentionally excluded).
