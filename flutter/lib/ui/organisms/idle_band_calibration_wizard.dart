import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../../core/monitoring/drift_and_noise_floor_envelope.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

/// `MOB_CALIBRATION` — the two-step IDLE Band calibration wizard
/// (`IdleBandCalibrationWizardOrganism`, AD-04 / AD-05).
///
///  1. **Idle sample** — worn + still ~10 s → running `min`/`max` = IDLE Band.
///  2. **Wear check** — breathe normally → the gate stays blocked until
///     [kRequiredValidCycles] valid band-excursion cycles are observed within
///     [kWearCheckWindow]; on timeout the gate is held with a retry toast,
///     never auto-advanced, never silently retried.
class IdleBandCalibrationWizard extends StatefulWidget {
  final IBLESensorDriver bleDriver;
  final void Function(IdleBand) onCalibrationComplete;

  const IdleBandCalibrationWizard({
    super.key,
    required this.bleDriver,
    required this.onCalibrationComplete,
  });

  @override
  State<IdleBandCalibrationWizard> createState() =>
      _IdleBandCalibrationWizardState();
}

enum _WizardStep { idleSample, wearCheck, complete }

class _IdleBandCalibrationWizardState extends State<IdleBandCalibrationWizard> {
  _WizardStep _step = _WizardStep.idleSample;

  // Step 1 — idle sample.
  bool _sampling = false;
  bool _idleError = false;
  IdleBand? _liveBand;
  IdleBand? _band;
  StreamSubscription<double>? _idleReadoutSub;

  // Step 2 — wear check.
  StreamSubscription<double>? _wearCheckSub;
  Timer? _wearCheckTimer;
  int _wearCheckRunId = 0;
  int _validCycles = 0;
  bool _wearCheckFailed = false;
  bool _wearCheckRunning = false;

  @override
  void dispose() {
    _idleReadoutSub?.cancel();
    _wearCheckSub?.cancel();
    _wearCheckTimer?.cancel();
    super.dispose();
  }

  // --- Step 1: idle sample ---------------------------------------------------

  Future<void> _startIdleSample() async {
    setState(() {
      _sampling = true;
      _idleError = false;
      _liveBand = null;
    });

    final acc = IdleBandAccumulator();
    unawaited(_idleReadoutSub?.cancel());
    _idleReadoutSub = widget.bleDriver.signalStream.listen(
      (v) {
        acc.add(v);
        if (mounted) setState(() => _liveBand = acc.band);
      },
      onError: (_) {},
    );

    try {
      final band =
          await widget.bleDriver.sampleIdleBand(window: kIdleSampleWindow);
      unawaited(_idleReadoutSub?.cancel());
      if (!mounted) return;
      setState(() {
        _band = band;
        _sampling = false;
        _step = _WizardStep.wearCheck;
      });
      _runWearCheck();
    } catch (_) {
      // Catch *any* failure — a StateError (silent stream) or a real BLE
      // fault (PlatformException / disconnection) — so the spinner never
      // hangs forever.
      unawaited(_idleReadoutSub?.cancel());
      if (!mounted) return;
      setState(() {
        _sampling = false;
        _idleError = true;
      });
    }
  }

  // --- Step 2: wear check --------------------------------------------------

  void _runWearCheck() {
    final band = _band;
    if (band == null) return;

    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    final int runId = ++_wearCheckRunId;
    final detector = BreathExcursionDetector(band);

    setState(() {
      _wearCheckRunning = true;
      _wearCheckFailed = false;
      _validCycles = 0;
    });

    _wearCheckSub = widget.bleDriver.signalStream.listen(
      (v) {
        if (runId != _wearCheckRunId) return;
        detector.add(v);
        if (detector.validCycleCount != _validCycles && mounted) {
          setState(() => _validCycles = detector.validCycleCount);
        }
        if (detector.validCycleCount >= kRequiredValidCycles) {
          _passWearCheck(runId);
        }
      },
      onError: (_) => _failWearCheck(runId, connectionLost: true),
      onDone: () => _failWearCheck(runId, connectionLost: true),
    );

    _wearCheckTimer = Timer(kWearCheckWindow, () {
      if (runId != _wearCheckRunId) return; // a newer run owns the gate now
      _failWearCheck(runId);
    });
  }

  void _passWearCheck(int runId) {
    if (runId != _wearCheckRunId) return;
    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    if (!mounted) return;
    setState(() {
      _wearCheckRunning = false;
      _step = _WizardStep.complete;
    });
    widget.onCalibrationComplete(_band!);
  }

  void _failWearCheck(int runId, {bool connectionLost = false}) {
    if (runId != _wearCheckRunId) return;
    _wearCheckTimer?.cancel();
    _wearCheckSub?.cancel();
    if (!mounted) return;
    setState(() {
      _wearCheckRunning = false;
      _wearCheckFailed = true;
    });
    final msg = connectionLost
        ? "D-BAND connection lost — check the fit and try again."
        : "Sensor not detecting breathing — check the fit.";
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.dangerRed),
    );
  }

  // --- UI ---------------------------------------------------------------------

  Widget _stepBadge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentGreen.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.accentGreen),
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGreen),
        ),
      );

  Widget _bandReadout(IdleBand? band) => Text(
        band == null
            ? "lower — · upper —"
            : "lower ${band.lower.toStringAsFixed(2)} · upper ${band.upper.toStringAsFixed(2)}",
        style: const TextStyle(
            fontSize: 13,
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.textSecondary),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: switch (_step) {
          _WizardStep.idleSample => _buildIdleSample(),
          _WizardStep.wearCheck => _buildWearCheck(),
          _WizardStep.complete => _buildComplete(),
        },
      ),
    );
  }

  List<Widget> _buildIdleSample() {
    return [
      _stepBadge("STEP 1 OF 2"),
      const SizedBox(height: 12),
      const Text("Sensor Baseline & Noise Envelope",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text(
        "Put on your D-BAND, sit still, and breathe gently for 10 seconds to calibrate the sensor baseline drift & noise floor envelope.",
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      if (_sampling) ...[
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentGreen),
            ),
            const SizedBox(width: 12),
            _bandReadout(_liveBand),
          ],
        ),
      ] else if (_idleError) ...[
        const Text(
          "No signal from your D-BAND — check the connection.",
          style: TextStyle(fontSize: 13, color: AppColors.dangerRed),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: "Retry",
          variant: AppButtonVariant.primary,
          onPressed: _startIdleSample,
        ),
      ] else ...[
        AppButton(
          label: "Start",
          variant: AppButtonVariant.primary,
          onPressed: _startIdleSample,
        ),
      ],
    ];
  }

  List<Widget> _buildWearCheck() {
    return [
      _stepBadge("STEP 2 OF 2"),
      const SizedBox(height: 12),
      const Text("Wear check",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      const Text(
        "Now take a few normal breaths so we can check the fit.",
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      _bandReadout(_band),
      const SizedBox(height: 6),
      Text(
        "Valid breath cycles: $_validCycles / $kRequiredValidCycles",
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGreen),
      ),
      if (_wearCheckFailed) ...[
        const SizedBox(height: 16),
        const Text(
          "Sensor not detecting breathing — check the fit.",
          style: TextStyle(fontSize: 13, color: AppColors.dangerRed),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: "Retry",
          variant: AppButtonVariant.primary,
          onPressed: _wearCheckRunning ? null : _runWearCheck,
        ),
      ] else if (_wearCheckRunning) ...[
        const SizedBox(height: 12),
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accentGreen),
        ),
      ],
    ];
  }

  List<Widget> _buildComplete() {
    return [
      _stepBadge("STEP 2 OF 2"),
      const SizedBox(height: 12),
      const Text(
        "Calibration Complete — Ready for Sleep ✓",
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGreen),
      ),
      const SizedBox(height: 6),
      _bandReadout(_band),
    ];
  }
}
