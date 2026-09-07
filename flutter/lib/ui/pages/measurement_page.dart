import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/ble_simulator_driver.dart';
import '../../core/ble/flutter_blue_sensor_driver.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../../core/monitoring/apnea_evaluator.dart';
import '../../core/monitoring/drift_and_noise_floor_envelope.dart';
import '../../core/permissions/ble_permission_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../organisms/idle_band_calibration_wizard.dart';
import '../organisms/apnea_alert_overlay.dart';
import '../organisms/ble_sensor_status_organism.dart';
import '../organisms/developer_simulator_bar_organism.dart';
import '../organisms/live_waveform_chart.dart';
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
  late IBLESensorDriver _bleDriver;
  late final BlePermissionService _permissionService;
  ApneaEvaluator? _apneaEvaluator;
  StreamSubscription<double>? _telemetrySub;
  StreamSubscription<ApneaState>? _evaluatorStateSub;
  StreamSubscription<int>? _countdownSub;
  StreamSubscription<SimulatorScenario>? _scenarioSub;
  StreamSubscription<bool>? _simulatorSub;

  bool _isBleConnected = false;
  bool _isCalibrationComplete = false;
  bool _isMonitoringActive = false;
  bool _showAlertOverlay = false;
  int _alertCountdown = 30;
  double _latestSignalValue = 0.0;
  final List<double> _recentSignalBuffer = [];

  List<FlSpot> get _liveFlSpots {
    if (_recentSignalBuffer.isEmpty) {
      return const [FlSpot(0, 0.3), FlSpot(1, 0.3)];
    }
    return List.generate(
      _recentSignalBuffer.length,
      (index) => FlSpot(index.toDouble(), _recentSignalBuffer[index]),
    );
  }

  int _connectGeneration = 0;
  IdleBand? _idleBand;

  bool _isCheckingPermission = true;
  bool _permissionCheckFailed = false;
  BlePermissionStatus? _permissionStatus;

  bool get _isDevMode =>
      widget.developerEnabled ?? BleSimulatorDriver().isSimulatorActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionService = widget.permissionService ?? const BlePermissionService();
    // SOLID Dependency Injection: Inject real Bluetooth HW driver in production, simulator in dev mode
    _bleDriver = widget.sensorDriver ??
        (_isDevMode ? BleSimulatorDriver() : FlutterBlueSensorDriver());

    _simulatorSub = BleSimulatorDriver().isSimulatorStream.listen((isSim) {
      if (mounted && widget.sensorDriver == null) {
        setState(() {
          _bleDriver = isSim ? BleSimulatorDriver() : FlutterBlueSensorDriver();
        });
        _checkPermissionThenConnect();
      }
    });

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
        _permissionCheckFailed = false;
        _permissionStatus = const BlePermissionStatus(BlePermissionResult.granted, []);
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
    if (_isDevMode) {
      if (!_isBleConnected) {
        _connectBle();
      }
      return;
    }
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
    // A fresh connection invalidates any prior calibration — the band is
    // per-session and a re-worn sensor must re-run the wizard.
    setState(() {
      _idleBand = null;
      _isCalibrationComplete = false;
      _connectGeneration++;
    });
    bool success = await _bleDriver.scanAndConnect();
    if (mounted) {
      setState(() {
        _isBleConnected = success;
      });
    }
  }

  void _startSleepMonitoring() {
    if (!mounted) return;
    if (_idleBand == null) return;

    _apneaEvaluator = ApneaEvaluator(idleBand: _idleBand!);

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

    _countdownSub = _apneaEvaluator!.countdownStream.listen((seconds) {
      if (mounted) {
        setState(() {
          _alertCountdown = seconds;
        });
      }
    });

    _recentSignalBuffer.clear();
    _latestSignalValue = 0.0;

    if (_bleDriver is BleSimulatorDriver) {
      _scenarioSub = (_bleDriver as BleSimulatorDriver).scenarioStream.skip(1).listen((scenario) {
        _apneaEvaluator?.reset();
        if (mounted) {
          setState(() {
            _showAlertOverlay = false;
          });
        }
      });
    }

    // The one unified signalStream (AD-12) is the only source feeding the
    // evaluator — never a second live source (double-tick to evaluateSignal).
    _telemetrySub = _bleDriver.signalStream.listen((signal) {
      _apneaEvaluator?.evaluateSignal(signal);
      if (mounted) {
        setState(() {
          _latestSignalValue = signal;
          _recentSignalBuffer.add(signal);
          if (_recentSignalBuffer.length > 20) {
            _recentSignalBuffer.removeAt(0);
          }
        });
      }
    });

    setState(() {
      _isMonitoringActive = true;
    });

    _bleDriver.startMonitoringSession();
  }

  void _stopSleepMonitoring() {
    _scenarioSub?.cancel();
    _telemetrySub?.cancel();
    _evaluatorStateSub?.cancel();
    _countdownSub?.cancel();
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
    _simulatorSub?.cancel();
    _scenarioSub?.cancel();
    _telemetrySub?.cancel();
    _evaluatorStateSub?.cancel();
    _countdownSub?.cancel();
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
      final bool isStopBreathingDetected = _apneaEvaluator != null && _apneaEvaluator!.inBandDuration > 0.5;
      final bool isSignalInNoiseFloor = _idleBand != null && _idleBand!.isInBand(_latestSignalValue);

      return Scaffold(
        backgroundColor: AppColors.nightMode,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_isDevMode) ...[
                  DeveloperSimulatorBarOrganism(),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "📊 DETECTION MECHANISM STAGE MONITOR",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "• Noise Floor Envelope: ${_idleBand != null ? "[${_idleBand!.lower.toStringAsFixed(3)}, ${_idleBand!.upper.toStringAsFixed(3)}]" : "Calibrated"}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _showAlertOverlay
                              ? "• Stage 3: 🚨 Apnea Breach Alert (>10s Flatline) — Siren Countdown: ${_alertCountdown}s"
                              : isStopBreathingDetected
                                  ? "• Stage 2: Stop Breathing Detected (In-Envelope: ${_apneaEvaluator!.inBandDuration.toStringAsFixed(1)}s / 10.0s threshold)"
                                  : "• Stage 1: Normal Breathing Active (Signal Excursions Detected)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _showAlertOverlay
                                ? AppColors.dangerRed
                                : isStopBreathingDetected
                                    ? AppColors.warningAmber
                                    : AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Live Telemetry Signal Level & Waveform Monitor Organism
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.sensors, size: 14, color: AppColors.accentGreen),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "LIVE TELEMETRY LEVEL",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_latestSignalValue.toStringAsFixed(3)} V",
                                style: AppTheme.tabularTextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSignalInNoiseFloor ? AppColors.warningAmber : AppColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isSignalInNoiseFloor ? AppColors.warningAmber : AppColors.accentGreen).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSignalInNoiseFloor ? AppColors.warningAmber : AppColors.accentGreen, width: 1.0),
                            ),
                            child: Text(
                              isSignalInNoiseFloor ? "IN-NOISE-FLOOR" : "NORMAL EXCURSION",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSignalInNoiseFloor ? AppColors.warningAmber : AppColors.accentGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: LiveWaveformChart(
                    points: _liveFlSpots,
                    showApneaMarkers: true,
                  ),
                ),
                InkWell(
                  onLongPress: _stopSleepMonitoring,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGreen.withValues(alpha: 0.6),
                                  blurRadius: 14,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Night Mode Active (Battery Saver)",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Long-press anywhere to wake & finish session",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
              // BLE Status Organism
              BleSensorStatusOrganism(isConnected: _isBleConnected),
              const SizedBox(height: 24),

              // Calibration Wizard
              const Text("Sensor Baseline & Noise Envelope Calibration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              IdleBandCalibrationWizard(
                key: ValueKey(_connectGeneration),
                bleDriver: _bleDriver,
                onCalibrationComplete: (band) {
                  if (mounted) {
                    setState(() {
                      _idleBand = band;
                      _isCalibrationComplete = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Step 3: Sleep Launcher Button — disabled (null onPressed) until a
              // valid IDLE Band exists, not just a "calibration complete" flag.
              AppButton(
                label: "Step 3: Start Nocturnal Sleep Monitoring",
                variant: AppButtonVariant.primary,
                icon: const Icon(Icons.nightlight_round, color: Colors.white),
                onPressed: (_idleBand != null && _isCalibrationComplete)
                    ? _startSleepMonitoring
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
