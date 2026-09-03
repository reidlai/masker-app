---
status: ready-for-dev
date: 2026-09-03
---

# Spec: BloC & RxDart Event-Driven State Management Decoupling

## Goal
Decouple Flutter UI components from imperative local state management (`setState` and `Future.delayed`) by introducing `flutter_bloc` and `rxdart` event-driven streams.

## Code Map
- `flutter/pubspec.yaml` - Add `flutter_bloc` and `rxdart`
- `flutter/lib/core/bloc/auth/auth_event.dart` - Auth event definitions
- `flutter/lib/core/bloc/auth/auth_state.dart` - Auth state definitions
- `flutter/lib/core/bloc/auth/auth_bloc.dart` - Auth BLoC with Rx event stream transformer
- `flutter/lib/ui/pages/login_page.dart` - UI widget refactoring using `BlocConsumer`
- `flutter/lib/main.dart` - Root `BlocProvider` injection

## Acceptance Criteria
- Given `pubspec.yaml`, when `flutter pub get` is run, dependencies resolve cleanly.
- Given `LoginPage`, when the passkey button is tapped, an `AuthPasskeySubmitted` event is dispatched to `AuthBloc`.
- Given `AuthBloc`, RxDart `throttleTime` prevents rapid multi-click event spamming.
- Given `AuthBloc`, state transitions cleanly from `AuthInitial` -> `AuthInProgress` -> `AuthAuthenticated`.
- Given `flutter test`, all core and UI tests pass clean.
