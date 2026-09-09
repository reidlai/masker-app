import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/ble/ble_receiver_service.dart';
import 'core/ble/i_ble_sensor_driver.dart';
import 'core/bloc/app_flow/app_flow_bloc.dart';
import 'core/bloc/app_flow/app_flow_event.dart';
import 'core/bloc/app_flow/app_flow_state.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/bloc/ble/ble_bloc.dart';
import 'core/bloc/simulator/simulator_bloc.dart';
import 'core/config/passkey_simulator_config.dart';
import 'core/permissions/ble_permission_service.dart';
import 'core/profile/profile_session.dart';
import 'core/theme/app_theme.dart';
import 'ui/atoms/app_button.dart';
import 'ui/pages/ble_permission_primer_page.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/main_container_page.dart';
import 'ui/pages/onboarding_wizard_page.dart';

void main() {
  // Ensure the Flutter Engine C++ bridge and native platform channels (BLE/MethodChannels)
  // are fully initialized before running background services or async setup prior to runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Configure google_fonts configuration (can disable runtime network fetching if offline assets are bundled)
  // GoogleFonts.config.allowRuntimeFetching = false;

  // Instantiate and boot the background BLE receiver service singleton on app launch.
  // This starts listening to physical BLE hardware / simulation drivers and exposes a central
  // RxDart BehaviorSubject<double> reactive stream for downstream calibration & sleep monitoring.
  BleReceiverService();

  runApp(const MaskerApp());
}

class MaskerApp extends StatefulWidget {
  final BlePermissionService? permissionService;

  const MaskerApp({super.key, this.permissionService});

  @override
  State<MaskerApp> createState() => _MaskerAppState();
}

class _MaskerAppState extends State<MaskerApp> {
  late final BlePermissionService _permissionService;
  late final AppFlowBloc _appFlowBloc;

  @override
  void initState() {
    super.initState();
    _permissionService = widget.permissionService ?? const BlePermissionService();
    _appFlowBloc = AppFlowBloc(permissionService: _permissionService);
  }

  @override
  void dispose() {
    _appFlowBloc.close();
    super.dispose();
  }

  Widget _buildHome(AppFlowState flow) {
    switch (flow.stage) {
      case AppFlowStage.loggedOut:
        return LoginPage(
          onLoginSuccess: () async {
            // Pull the user + device profile into the reactive stores before
            // the tab shell mounts. A cleanly-absent profile (not a fetch
            // error) → route to the onboarding wizard.
            final needsOnboarding = await ProfileSession.hydrate();
            _appFlowBloc
                .add(AppFlowLoginSucceeded(needsOnboarding: needsOnboarding));
          },
        );
      case AppFlowStage.onboarding:
        return const OnboardingWizardPage();
      case AppFlowStage.checkingPermission:
        // Brief native-call wait — a minimal spinner, not a full loading screen.
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      case AppFlowStage.permissionCheckFailed:
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Couldn't check Bluetooth permission",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: "Retry",
                      variant: AppButtonVariant.primary,
                      onPressed: () => _appFlowBloc
                          .add(const AppFlowPermissionRetryRequested()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case AppFlowStage.needsPrimer:
        return BlePermissionPrimerPage(
          permissionService: _permissionService,
          onPrimed: () => _appFlowBloc.add(const AppFlowPrimerCompleted()),
        );
      case AppFlowStage.ready:
        return const MainContainerPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Composition root (AD-11 / AD-12): the single boot-time BleReceiverService
    // is the one IBLESensorDriver, provided here and injected by Constructor DI
    // into every bio-signal consumer bloc.
    return RepositoryProvider<IBLESensorDriver>(
      create: (_) => BleReceiverService(),
      child: MultiBlocProvider(
        providers: [
          // Owned by this State; provided here so descendants (e.g. the Settings
          // "Log out" row) can dispatch AppFlowLogoutRequested.
          BlocProvider<AppFlowBloc>.value(value: _appFlowBloc),
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              // Passkey Simulator flag is honored wherever the toggle is shown
              // (kDebugMode or DEV_MODE); release builds always fall through to
              // the real auth path.
              isPasskeySimulatorEnabled: () => passkeySimulatorActive(
                developerBuild: kDebugMode ||
                    const bool.fromEnvironment('DEV_MODE', defaultValue: false),
              ),
            ),
          ),
          BlocProvider<SimulatorBloc>(
            create: (ctx) {
              final driver = ctx.read<IBLESensorDriver>();
              return SimulatorBloc(
                receiver: driver is BleReceiverService ? driver : null,
              );
            },
          ),
          BlocProvider<BleBloc>(
            create: (ctx) =>
                BleBloc(telemetryService: ctx.read<IBLESensorDriver>()),
          ),
        ],
        child: MaterialApp(
          title: 'Sleep Apnea Detection App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: BlocBuilder<AppFlowBloc, AppFlowState>(
            bloc: _appFlowBloc,
            builder: (context, flow) => _buildHome(flow),
          ),
        ),
      ),
    );
  }
}
