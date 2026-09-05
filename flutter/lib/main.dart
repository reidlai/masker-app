import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/ble/ble_receiver_service.dart';
import 'core/bloc/auth/auth_bloc.dart';
import 'core/permissions/ble_permission_service.dart';
import 'core/theme/app_theme.dart';
import 'ui/atoms/app_button.dart';
import 'ui/pages/ble_permission_primer_page.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/main_container_page.dart';

void main() {
  // Ensure the Flutter Engine C++ bridge and native platform channels (BLE/MethodChannels)
  // are fully initialized before running background services or async setup prior to runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate and boot the background BLE receiver service singleton on app launch.
  // This starts listening to physical BLE hardware / simulation drivers and exposes a central
  // RxDart BehaviorSubject<double> reactive stream for downstream calibration & sleep monitoring.
  BleReceiverService();

  runApp(const MaskerApp());
}

/// The post-login flow gate: a login success does not jump straight to the
/// tab shell — it first checks live Bluetooth permission status and, if not
/// yet granted, routes through the one-time priming screen. Gating is always
/// a live status check, never a persisted "seen it" flag, so a later
/// revocation is caught on the next login.
enum _AppFlowState { loggedOut, checkingPermission, permissionCheckFailed, needsPrimer, ready }

class MaskerApp extends StatefulWidget {
  final BlePermissionService? permissionService;

  const MaskerApp({super.key, this.permissionService});

  @override
  State<MaskerApp> createState() => _MaskerAppState();
}

class _MaskerAppState extends State<MaskerApp> {
  late final BlePermissionService _permissionService;
  _AppFlowState _flowState = _AppFlowState.loggedOut;

  @override
  void initState() {
    super.initState();
    _permissionService = widget.permissionService ?? const BlePermissionService();
  }

  Future<void> _handleLoginSuccess() async {
    // Re-entrancy guard: a duplicate login-success signal (e.g. a stray
    // AuthBloc state emission) must not restart an in-flight or completed
    // check.
    if (_flowState != _AppFlowState.loggedOut) return;

    setState(() {
      _flowState = _AppFlowState.checkingPermission;
    });

    try {
      final status = await _permissionService.checkPermission();
      if (!mounted) return;
      setState(() {
        _flowState = status.isGranted ? _AppFlowState.ready : _AppFlowState.needsPrimer;
      });
    } catch (_) {
      // Never hang on the spinner forever if the platform channel throws —
      // surface a retry instead.
      if (!mounted) return;
      setState(() {
        _flowState = _AppFlowState.permissionCheckFailed;
      });
    }
  }

  void _retryPermissionCheck() {
    setState(() {
      _flowState = _AppFlowState.loggedOut;
    });
    _handleLoginSuccess();
  }

  void _handlePrimerComplete() {
    setState(() {
      _flowState = _AppFlowState.ready;
    });
  }

  Widget _buildHome() {
    switch (_flowState) {
      case _AppFlowState.loggedOut:
        return LoginPage(
          onLoginSuccess: () {
            _handleLoginSuccess();
          },
        );
      case _AppFlowState.checkingPermission:
        // Brief native-call wait — a minimal spinner, not a full loading screen.
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      case _AppFlowState.permissionCheckFailed:
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
                      onPressed: _retryPermissionCheck,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case _AppFlowState.needsPrimer:
        return BlePermissionPrimerPage(
          permissionService: _permissionService,
          onPrimed: _handlePrimerComplete,
        );
      case _AppFlowState.ready:
        return const MainContainerPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(),
      child: MaterialApp(
        title: 'Sleep Apnea Detection App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: _buildHome(),
      ),
    );
  }
}
