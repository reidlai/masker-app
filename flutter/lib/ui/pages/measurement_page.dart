import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/ble_sensor_driver.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/ble/flutter_blue_sensor_driver.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../../core/monitoring/apnea_evaluator.dart';
import '../../core/permissions/ble_permission_service.dart';
import '../organisms/thermal_calibration_wizard.dart';
import '../organisms/apnea_alert_overlay.dart';
import '../organisms/ble_sensor_status_organism.dart';
import '../organisms/developer_simulator_bar_organism.dart';
import '../atoms/app_button.dart';

class MeasurementPage extends StatefulWidget {
  final bool? developerEnabled;
  final IBLESensorDriver? sensorDriver;
  final BlePermissionService? permissionService;

  const MeasurementPage({
    super.key,
    this.developerEnabled,
    this.sensorDriver,
    this.permissionService,
  });

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> with WidgetsBindingObserver {
  late final IBLESensorDriver _bleDriver;
  late final BlePermissionService _permissionService;
  final BleSimulatorDriver _telemetryService = BleSimulatorDriver();
  ApneaEvaluator? _apneaEvaluator;
  StreamSubscription<double>? _telemetrySub;
  StreamSubscription<double>? _serviceTelemetrySub;
  StreamSubscription<ApneaState>? _evaluatorStateSub;

  bool _isBleConnected = false;
  bool _isCalibrationComplete = false;
  bool _isMonitoringActive = false;
  bool _showAlertOverlay = false;
  int _alertCountdown = 30;

  bool _isCheckingPermission = true;
  bool _permissionCheckFailed = false;
  BlePermissionStatus? _permissionStatus;

  bool get _isDevMode =>
      widget.developerEnabled ??
      const bool.fromEnvironment('DEV_MODE', defaultValue: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionService = widget.permissionService ?? const BlePermissionService();
    // SOLID Dependency Injection: Inject real Bluetooth HW driver in production, simulator in dev mode
    _bleDriver = widget.sensorDriver ??
        (_isDevMode ? BleSimulatorDriver() : FlutterBlueSensorDriver());
    _checkPermissionThenConnect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission live on resume (e.g. returning from Settings) so
    // the blocked state clears without an app restart — never gated on a
    // persisted flag.
    if (state == AppLifecycleState.resumed) {
      _recheckPermissionOnResume();
    }
  }

  Future<void> _checkPermissionThenConnect() async {
    // The simulator never touches real Bluetooth hardware or OS permissions
    // (Story 1.5's whole point is testing without physical hardware), so
    // DEV_MODE bypasses the live permission gate entirely.
    if (_isDevMode) {
      setState(() {
        _isCheckingPermission = false;
      });
      _connectBle();
      return;
    }

    try {
      final status = await _permissionService.checkPermission();
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
        _isCheckingPermission = false;
      });
      if (status.isGranted) {
        _connectBle();
      }
    } catch (_) {
      // Never hang on the spinner forever if the platform channel throws —
      // surface a retry instead.
      if (!mounted) return;
      setState(() {
        _isCheckingPermission = false;
        _permissionCheckFailed = true;
      });
    }
  }

  Future<void> _recheckPermissionOnResume() async {
    if (_isDevMode) return;
    final wasBlocked = _permissionStatus != null && !_permissionStatus!.isGranted;
    try {
      final status = await _permissionService.checkPermission();
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
      });
      if (wasBlocked && status.isGranted && !_isBleConnected) {
        _connectBle();
      }
    } catch (_) {
      // Leave existing state as-is on a transient resume-check failure —
      // the user stays on whatever screen they were already on (blocked
      // state still offers "Open Settings").
    }
  }

  void _connectBle() async {
    bool success = await _bleDriver.scanAndConnect();
    if (mounted) {
      setState(() {
        _isBleConnected = success;
      });
    }
  }

  void _startSleepMonitoring() {
    if (!mounted) return;

    _apneaEvaluator = ApneaEvaluator(threshold: _bleDriver.signalThreshold);

    _evaluatorStateSub = _apneaEvaluator!.stateStream.listen((state) {
      if (!mounted) return;
      if (state == ApneaState.breachAlert) {
        setState(() {
          _showAlertOverlay = true;
        });
      } else if (state == ApneaState.patientSafe) {
        setState(() {
          _showAlertOverlay = false;
        });
      }
    });

    _apneaEvaluator!.countdownStream.listen((seconds) {
      if (mounted) {
        setState(() {
          _alertCountdown = seconds;
        });
      }
    });

    // Listen to IBLESensorDriver signal stream (Real Hardware or Simulator)
    _telemetrySub = _bleDriver.signalStream.listen((signal) {
      _apneaEvaluator?.evaluateSignal(signal);
    });

    // Listen to global BleSimulatorDriver background stream
    _serviceTelemetrySub = _telemetryService.signalStream.listen((signal) {
      _apneaEvaluator?.evaluateSignal(signal);
    });

    setState(() {
      _isMonitoringActive = true;
    });

    _bleDriver.startMonitoringSession();
  }

  void _stopSleepMonitoring() {
    _telemetrySub?.cancel();
    _serviceTelemetrySub?.cancel();
    _evaluatorStateSub?.cancel();
    _apneaEvaluator?.dispose();
    _bleDriver.stopMonitoringSession();

    if (mounted) {
      setState(() {
        _isMonitoringActive = false;
        _showAlertOverlay = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sleep session saved — Morning summary ready ✓"), backgroundColor: AppColors.accentGreen),
      );
    }
  }

  void _handlePatientSafe() {
    _apneaEvaluator?.acknowledgePatientSafe();
    if (mounted) {
      setState(() {
        _showAlertOverlay = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _telemetrySub?.cancel();
    _serviceTelemetrySub?.cancel();
    _evaluatorStateSub?.cancel();
    _apneaEvaluator?.dispose();
    _bleDriver.disconnect();
    super.dispose();
  }

  Widget _buildPermissionBlockedState() {
    final names = _permissionStatus?.missingPermissionNames ?? const ['Bluetooth'];
    final missing = names.join(', ');
    final verb = names.length > 1 ? "permissions are" : "permission is";
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Sleep Apnea Monitoring"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  excludeSemantics: true,
                  child: const Icon(Icons.bluetooth_disabled, color: AppColors.dangerRed, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Bluetooth Permission Needed",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  "$missing $verb required to connect to your D-BAND sensor and monitor your breathing while you sleep.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: "Open Settings",
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.settings, color: AppColors.textPrimary),
                  onPressed: () async {
                    final opened = await _permissionService.openSettings();
                    if (!opened && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Couldn't open Settings — please open it manually.")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCheckFailedState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Sleep Apnea Monitoring"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Couldn't check Bluetooth permission",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: "Retry",
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    setState(() {
                      _permissionCheckFailed = false;
                      _isCheckingPermission = true;
                    });
                    _checkPermissionThenConnect();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showAlertOverlay) {
      return Scaffold(
        body: ApneaAlertOverlay(
          countdownSeconds: _alertCountdown,
          onPatientSafe: _handlePatientSafe,
        ),
      );
    }

    if (_isMonitoringActive) {
      // 0-FPS Night Mode Display Lock (#000000)
      return Scaffold(
        backgroundColor: AppColors.nightMode,
        body: SafeArea(
          child: InkWell(
            onLongPress: _stopSleepMonitoring,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Night Mode Active (0-FPS)",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Long-press anywhere to wake & finish session",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_permissionCheckFailed) {
      return _buildPermissionCheckFailedState();
    }

    if (_permissionStatus != null && !_permissionStatus!.isGranted) {
      return _buildPermissionBlockedState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Sleep Apnea Monitoring"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contextual Developer Simulator Bar (when DEV_MODE=true)
              if (_isDevMode) DeveloperSimulatorBarOrganism(),

              // BLE Status Organism
              BleSensorStatusOrganism(isConnected: _isBleConnected),
              const SizedBox(height: 24),

              // Calibration Wizard
              const Text("Bedtime Sensor Calibration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              ThermalCalibrationWizard(
                bleDriver: _bleDriver is BLESensorDriver ? (_bleDriver as BLESensorDriver) : BLESensorDriver(),
                onCalibrationComplete: () {
                  if (mounted) {
                    setState(() {
                      _isCalibrationComplete = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Sleep Launcher Button
              AppButton(
                label: "Start Nocturnal Sleep Monitoring",
                variant: AppButtonVariant.primary,
                icon: const Icon(Icons.nightlight_round, color: Colors.white),
                onPressed: _isCalibrationComplete ? _startSleepMonitoring : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
