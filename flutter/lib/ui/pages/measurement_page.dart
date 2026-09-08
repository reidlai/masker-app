import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/ble_receiver_service.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../../core/bloc/monitoring/sleep_monitoring_bloc.dart';
import '../../core/bloc/monitoring/sleep_monitoring_event.dart';
import '../../core/bloc/monitoring/sleep_monitoring_state.dart';
import '../../core/bloc/simulator/simulator_bloc.dart';
import '../../core/permissions/ble_permission_service.dart';
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

class _MeasurementPageState extends State<MeasurementPage>
    with WidgetsBindingObserver {
  late final BlePermissionService _permissionService;
  late final IBLESensorDriver _bleDriver;
  late final SleepMonitoringBloc _bloc;

  /// The single unified-queue driver (AD-12): the app-wide provided
  /// [IBLESensorDriver] when a composition root is above this page, otherwise
  /// the process-wide [BleReceiverService] singleton itself (same instance).
  IBLESensorDriver _injectedDriver() {
    try {
      return context.read<IBLESensorDriver>();
    } catch (_) {
      return BleReceiverService();
    }
  }

  /// Drives the bloc's **permission-gate bypass** only — deliberately permissive
  /// (the driver fallback lets a sim-active receiver bypass the OS gate even with
  /// no `SimulatorBloc` in scope). Dev-UI *visibility* is gated separately and
  /// strictly on `SimulatorBloc.isSimulatorActive` (see `_buildMonitoring`).
  bool get _isDevMode {
    if (widget.developerEnabled != null) return widget.developerEnabled!;
    try {
      return context.read<SimulatorBloc>().state.isSimulatorActive;
    } catch (_) {
      final d = widget.sensorDriver ?? _injectedDriver();
      return d is BleReceiverService && d.isSimulatorActive;
    }
  }

  /// Fires once per developer/QA scenario change — used by the bloc to reset the
  /// evaluator mid-session. Null when no [SimulatorBloc] is in scope.
  Stream<void>? _scenarioResetStream() {
    try {
      return context
          .read<SimulatorBloc>()
          .stream
          .map((s) => s.currentScenario)
          .distinct()
          .map<void>((_) {});
    } catch (_) {
      return null;
    }
  }

  /// Fires on every developer/QA simulator on/off toggle — the bloc re-runs the
  /// connect flow so the BLE status tracks the swapped driver. Null when a test
  /// forces [MeasurementPage.developerEnabled] (that override wins, so the
  /// stream must not fight it) or when no [SimulatorBloc] is in scope.
  Stream<bool>? _simulatorActiveStream() {
    if (widget.developerEnabled != null) return null;
    try {
      return context
          .read<SimulatorBloc>()
          .stream
          .map((s) => s.isSimulatorActive)
          .distinct();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionService =
        widget.permissionService ?? const BlePermissionService();
    // AD-11 / AD-12: the one boot-time BleReceiverService is injected as the
    // single IBLESensorDriver. No per-widget driver construction here.
    _bleDriver = widget.sensorDriver ?? _injectedDriver();
    _bloc = SleepMonitoringBloc(
      driver: _bleDriver,
      permissionService: _permissionService,
      isDevMode: _isDevMode,
      scenarioResetStream: _scenarioResetStream(),
      simulatorActiveStream: _simulatorActiveStream(),
    )..add(const SleepMonitoringStarted());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission live on resume (e.g. returning from Settings) so the
    // blocked state clears without an app restart — never gated on a persisted
    // flag.
    if (state == AppLifecycleState.resumed) {
      _bloc.add(const SleepMonitoringAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  List<FlSpot> _liveFlSpots(List<double> buffer) {
    if (buffer.isEmpty) {
      return const [FlSpot(0, 0.3), FlSpot(1, 0.3)];
    }
    return List.generate(
      buffer.length,
      (index) => FlSpot(index.toDouble(), buffer[index]),
    );
  }

  Widget _buildPermissionBlockedState(SleepMonitoringState state) {
    final names =
        state.permissionStatus?.missingPermissionNames ?? const ['Bluetooth'];
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
                  child: const Icon(Icons.bluetooth_disabled,
                      color: AppColors.dangerRed, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Bluetooth Permission Needed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  "$missing $verb required to connect to your D-BAND sensor and monitor your breathing while you sleep.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
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
                        const SnackBar(
                            content: Text(
                                "Couldn't open Settings — please open it manually.")),
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
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: "Retry",
                  variant: AppButtonVariant.primary,
                  onPressed: () =>
                      _bloc.add(const SleepMonitoringPermissionRetried()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _devStagePanel(SleepMonitoringState state, bool isStopBreathingDetected) {
    return Container(
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
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGreen),
          ),
          const SizedBox(height: 6),
          Text(
            "• Noise Floor Envelope: ${state.idleBand != null ? "[${state.idleBand!.lower.toStringAsFixed(3)}, ${state.idleBand!.upper.toStringAsFixed(3)}]" : "Calibrated"}",
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            state.showAlertOverlay
                ? "• Stage 3: 🚨 Apnea Breach Alert (>10s Flatline) — Siren Countdown: ${state.alertCountdown}s"
                : isStopBreathingDetected
                    ? "• Stage 2: Stop Breathing Detected (In-Envelope: ${state.inBandDuration.toStringAsFixed(1)}s / 10.0s threshold)"
                    : "• Stage 1: Normal Breathing Active (Signal Excursions Detected)",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: state.showAlertOverlay
                  ? AppColors.dangerRed
                  : isStopBreathingDetected
                      ? AppColors.warningAmber
                      : AppColors.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoring(SleepMonitoringState state) {
    final bool isStopBreathingDetected = state.inBandDuration > 0.5;
    final bool isSignalInNoiseFloor = state.idleBand != null &&
        state.idleBand!.isInBand(state.latestSignalValue);

    return Scaffold(
      backgroundColor: AppColors.nightMode,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Developer-only: toolbar + stage panel. Visible when the explicit
              // `developerEnabled` demo flag is set, OR (in normal builds) when
              // the live SimulatorBloc says the simulator is on — hide/show
              // tracks the toggle instantly. No SimulatorBloc in scope and no
              // demo flag ⟹ hidden (never a stale-driver "show"). The organism
              // gets the same `forced` flag so it doesn't self-gate under a demo.
              Builder(builder: (context) {
                final bool forced = widget.developerEnabled == true;
                bool active = forced;
                if (!active) {
                  try {
                    active = context.select<SimulatorBloc, bool>(
                        (b) => b.state.isSimulatorActive);
                  } catch (_) {
                    active = false;
                  }
                }
                if (!active) return const SizedBox.shrink();
                return Column(
                  children: [
                    DeveloperSimulatorBarOrganism(showEvenIfInactive: forced),
                    _devStagePanel(state, isStopBreathingDetected),
                  ],
                );
              }),
              // Live Telemetry Signal Level & Waveform Monitor Organism
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                Icon(Icons.sensors,
                                    size: 14, color: AppColors.accentGreen),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "LIVE TELEMETRY LEVEL",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${state.latestSignalValue.toStringAsFixed(3)} V",
                              style: AppTheme.tabularTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSignalInNoiseFloor
                                    ? AppColors.warningAmber
                                    : AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isSignalInNoiseFloor
                                    ? AppColors.warningAmber
                                    : AppColors.accentGreen)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isSignalInNoiseFloor
                                    ? AppColors.warningAmber
                                    : AppColors.accentGreen,
                                width: 1.0),
                          ),
                          child: Text(
                            isSignalInNoiseFloor
                                ? "IN-NOISE-FLOOR"
                                : "NORMAL EXCURSION",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSignalInNoiseFloor
                                  ? AppColors.warningAmber
                                  : AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: LiveWaveformChart(
                  points: _liveFlSpots(state.recentSignalBuffer),
                  showApneaMarkers: true,
                ),
              ),
              InkWell(
                onLongPress: () =>
                    _bloc.add(const SleepMonitoringSessionStopped()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 16.0),
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
                                color: AppColors.accentGreen
                                    .withValues(alpha: 0.6),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Night Mode Active (Battery Saver)",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Long-press anywhere to wake & finish session",
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10),
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

  Widget _buildSetup(SleepMonitoringState state) {
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
              BleSensorStatusOrganism(isConnected: state.isBleConnected),
              const SizedBox(height: 24),

              // Calibration Wizard
              const Text("Sensor Baseline & Noise Envelope Calibration",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              IdleBandCalibrationWizard(
                key: ValueKey(state.connectGeneration),
                bleDriver: _bleDriver,
                isConnected: state.isBleConnected,
                onCalibrationComplete: (band) => _bloc
                    .add(SleepMonitoringCalibrationCompleted(band)),
              ),
              const SizedBox(height: 32),

              // Step 3: Sleep Launcher Button — disabled (null onPressed) until a
              // valid IDLE Band exists, not just a "calibration complete" flag.
              AppButton(
                label: "Step 3: Start Nocturnal Sleep Monitoring",
                variant: AppButtonVariant.primary,
                icon: const Icon(Icons.nightlight_round, color: Colors.white),
                onPressed: state.canStartMonitoring
                    ? () => _bloc.add(const SleepMonitoringSessionStarted())
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SleepMonitoringBloc, SleepMonitoringState>(
      bloc: _bloc,
      listenWhen: (prev, curr) =>
          prev.status == SleepMonitoringStatus.monitoring &&
          curr.status == SleepMonitoringStatus.setup,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Sleep session saved — Morning summary ready ✓"),
              backgroundColor: AppColors.accentGreen),
        );
      },
      builder: (context, state) {
        if (state.showAlertOverlay) {
          return Scaffold(
            body: ApneaAlertOverlay(
              countdownSeconds: state.alertCountdown,
              onPatientSafe: () =>
                  _bloc.add(const SleepMonitoringPatientSafeAcknowledged()),
            ),
          );
        }

        if (state.status == SleepMonitoringStatus.monitoring) {
          return _buildMonitoring(state);
        }

        if (state.status == SleepMonitoringStatus.checkingPermission) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == SleepMonitoringStatus.permissionCheckFailed) {
          return _buildPermissionCheckFailedState();
        }

        if (state.status == SleepMonitoringStatus.permissionBlocked) {
          return _buildPermissionBlockedState(state);
        }

        return _buildSetup(state);
      },
    );
  }
}
