import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/bloc/auth/auth_bloc.dart';
import 'package:masker_app/core/bloc/auth/auth_event.dart';
import 'package:masker_app/core/bloc/auth/auth_state.dart';
import 'package:masker_app/core/bloc/simulator/simulator_bloc.dart';
import 'package:masker_app/ui/pages/developer_options_page.dart';

void main() {
  group('DeveloperOptionsPage Widget Tests', () {
    testWidgets('renders Onboarding & Reset Tools section and reset rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SimulatorBloc>(create: (_) => SimulatorBloc()),
              BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
            ],
            child: const DeveloperOptionsPage(),
          ),
        ),
      );

      expect(find.text("Developer Options"), findsOneWidget);
      expect(find.text("Onboarding & Reset Tools"), findsOneWidget);
      expect(find.text("Unbind BLE Sensor Device"), findsOneWidget);
      expect(find.text("Unregister User Account"), findsOneWidget);
    });

    testWidgets('tapping Unbind BLE Sensor Device opens confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SimulatorBloc>(create: (_) => SimulatorBloc()),
              BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
            ],
            child: const DeveloperOptionsPage(),
          ),
        ),
      );

      final finder = find.text("Unbind BLE Sensor Device");
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.text("Unbind BLE Sensor?"), findsOneWidget);
      expect(find.text("Confirm Reset"), findsOneWidget);
      expect(find.text("Cancel"), findsOneWidget);

      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();

      expect(find.text("Unbind BLE Sensor?"), findsNothing);
    });

    testWidgets('tapping Unregister User Account opens confirmation dialog', (tester) async {
      late AuthBloc authBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SimulatorBloc>(create: (_) => SimulatorBloc()),
              BlocProvider<AuthBloc>(
                create: (_) {
                  authBloc = AuthBloc();
                  return authBloc;
                },
              ),
            ],
            child: const DeveloperOptionsPage(),
          ),
        ),
      );

      final finder = find.text("Unregister User Account");
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.text("Unregister User Account?"), findsOneWidget);
      expect(find.text("Confirm Reset"), findsOneWidget);

      await tester.tap(find.text("Confirm Reset"));
      await tester.pumpAndSettle();

      expect(authBloc.state, isA<AuthInitial>());
    });
  });
}
