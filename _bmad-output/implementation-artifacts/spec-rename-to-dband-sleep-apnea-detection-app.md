---
title: "Spec: Rename App to D-BAND Sleep Apnea Detection App"
status: done
created: 2026-09-10
updated: 2026-09-10
---

# Spec: Rename App to D-BAND Sleep Apnea Detection App

## Goal
Update the user-facing application title and branding text across the Flutter codebase (`main.dart`, `BrandHeaderOrganism`, widget tests, and documentation) from "Sleep Apnea App" / "Sleep Apnea Detection App" to **"D-BAND Sleep Apnea Detection App"**.

## User Review Required
> [!NOTE]
> This update aligns the Flutter mobile app title directly with the rebranded **D-BAND Platform** product brief and PRD specifications.

## Proposed Changes

### Flutter Mobile App (`flutter/`)

#### [MODIFY] [main.dart](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/lib/main.dart)
- Update `MaterialApp` title property to `'D-BAND Sleep Apnea Detection App'`.

#### [MODIFY] [brand_header_organism.dart](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/lib/ui/organisms/brand_header_organism.dart)
- Update default `title` parameter in `BrandHeaderOrganism` constructor to `"D-BAND Sleep Apnea Detection App"`.

#### [MODIFY] [brand_header_organism_test.dart](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/test/ui/brand_header_organism_test.dart)
- Update expected title text assertion in test to `"D-BAND Sleep Apnea Detection App"`.

#### [MODIFY] [login_page_test.dart](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/test/ui/login_page_test.dart)
- Update expected title text assertion in test to `"D-BAND Sleep Apnea Detection App"`.

#### [MODIFY] [widget_test.dart](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/test/widget_test.dart)
- Update expected title text assertion in test to `'D-BAND Sleep Apnea Detection App'`.

#### [MODIFY] [README.md](file:///c:/Users/reidl/GitLocal/dband-platform/flutter/README.md)
- Update main header to `# D-BAND Sleep Apnea Detection App 🫁📱`.

---

## Code Map

- `flutter/lib/main.dart`: Line 160 (`MaterialApp` title parameter)
- `flutter/lib/ui/organisms/brand_header_organism.dart`: Line 11 (`BrandHeaderOrganism` default title)
- `flutter/test/ui/brand_header_organism_test.dart`: Line 15 (Widget test expectation)
- `flutter/test/ui/login_page_test.dart`: Line 29 (Login page test expectation)
- `flutter/test/widget_test.dart`: Line 16 (Widget test expectation)
- `flutter/README.md`: Line 1 (Readme header)

---

## Verification Plan

### Automated Tests
- Execute `flutter test` from the `flutter/` directory to ensure all unit & widget tests pass clean.

```bash
cd flutter
flutter test
```
