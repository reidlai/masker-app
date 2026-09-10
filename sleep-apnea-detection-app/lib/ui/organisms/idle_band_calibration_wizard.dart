import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../../core/bloc/calibration/calibration_bloc.dart';
import '../../core/bloc/calibration/calibration_event.dart';
import '../../core/bloc/calibration/calibration_state.dart';
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
///
/// The wizard is a `BlocConsumer` over [CalibrationBloc] — all sampling /
/// wear-check orchestration lives in the bloc; the widget adds only the
/// [isConnected] gate on the "start sampling" actions.
class IdleBandCalibrationWizard extends StatefulWidget {
  final IBLESensorDriver bleDriver;
  final void Function(IdleBand) onCalibrationComplete;

  /// Whether the D-BAND is connected. When `false`, every "start sampling"
  /// action is disabled — there is no sensor to sample from. `true` in
  /// dev/simulator mode (the simulator reports itself connected).
  final bool isConnected;

  const IdleBandCalibrationWizard({
    super.key,
    required this.bleDriver,
    required this.onCalibrationComplete,
    required this.isConnected,
  });

  @override
  State<IdleBandCalibrationWizard> createState() =>
      _IdleBandCalibrationWizardState();
}

class _IdleBandCalibrationWizardState extends State<IdleBandCalibrationWizard> {
  late final CalibrationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CalibrationBloc(bleDriver: widget.bleDriver);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  /// A tap handler for a "start sampling" action, or `null` when there is no
  /// connected sensor to sample from — so every such button disables together.
  VoidCallback? _whenConnected(CalibrationEvent event) =>
      widget.isConnected ? () => _bloc.add(event) : null;

  void _onStateChanged(BuildContext context, CalibrationState state) {
    if (state.step == CalibrationStep.complete && state.band != null) {
      widget.onCalibrationComplete(state.band!);
    }
    if (state.wearCheckFailed) {
      final msg = state.wearCheckConnectionLost
          ? "D-BAND connection lost — check the fit and try again."
          : "Sensor not detecting breathing — check the fit.";
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.dangerRed),
      );
    }
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
    return BlocConsumer<CalibrationBloc, CalibrationState>(
      bloc: _bloc,
      listenWhen: (prev, curr) =>
          (curr.step == CalibrationStep.complete &&
              prev.step != CalibrationStep.complete) ||
          (curr.wearCheckFailed && !prev.wearCheckFailed),
      listener: _onStateChanged,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: switch (state.step) {
              CalibrationStep.idleSample => _buildIdleSample(state),
              CalibrationStep.wearCheck => _buildWearCheck(state),
              CalibrationStep.complete => _buildComplete(state),
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildIdleSample(CalibrationState state) {
    return [
      _stepBadge("STEP 1 OF 3: NOISE FLOOR SAMPLING"),
      const SizedBox(height: 12),
      const Text("Sensor Baseline & Noise Envelope",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(
        widget.isConnected
            ? "Put on your D-BAND, sit still, and breathe gently for 10 seconds to calibrate the sensor baseline drift & noise floor envelope."
            : "Connect your D-BAND to begin noise floor sampling.",
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      if (state.sampling) ...[
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accentGreen),
            ),
            const SizedBox(width: 12),
            _bandReadout(state.liveBand),
          ],
        ),
      ] else if (state.idleError) ...[
        const Text(
          "No signal from your D-BAND — check the connection.",
          style: TextStyle(fontSize: 13, color: AppColors.dangerRed),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: "Retry",
          variant: AppButtonVariant.primary,
          onPressed: _whenConnected(const CalibrationIdleSampleStarted()),
        ),
      ] else ...[
        AppButton(
          label: "Start Noise Floor Sampling",
          variant: AppButtonVariant.primary,
          onPressed: _whenConnected(const CalibrationIdleSampleStarted()),
        ),
      ],
    ];
  }

  List<Widget> _buildWearCheck(CalibrationState state) {
    return [
      _stepBadge("STEP 2 OF 3: WORN SAMPLING"),
      const SizedBox(height: 12),
      const Text("Sensor Fit & Breathing Check",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(
        widget.isConnected
            ? "Noise floor calibrated! When you are ready, tap below and take 2 full, deep breaths so we can verify sensor fit."
            : "Connect your D-BAND to continue the fit & breathing check.",
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      _bandReadout(state.band),
      const SizedBox(height: 16),
      if (!state.wearCheckRunning && !state.wearCheckFailed) ...[
        AppButton(
          label: "I'm Ready — Start Breathing Check",
          variant: AppButtonVariant.primary,
          onPressed: _whenConnected(const CalibrationWearCheckStarted()),
        ),
      ] else if (state.wearCheckFailed) ...[
        const Text(
          "Sensor not detecting breathing — check the fit and try again.",
          style: TextStyle(fontSize: 13, color: AppColors.dangerRed),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: "Retry Breathing Check",
          variant: AppButtonVariant.primary,
          onPressed: _whenConnected(const CalibrationWearCheckStarted()),
        ),
      ] else if (state.wearCheckRunning) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.air, color: AppColors.accentGreen, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "🫁 Inhale Deeply & Exhale Fully...",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Valid breath cycles: ${state.validCycles} / $kRequiredValidCycles",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const LinearProgressIndicator(
                color: AppColors.accentGreen,
                backgroundColor: AppColors.cardBorder,
              ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildComplete(CalibrationState state) {
    return [
      _stepBadge("CALIBRATION COMPLETE ✓"),
      const SizedBox(height: 12),
      const Text(
        "Baseline & Fit Verified — Ready for Step 3 ✓",
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGreen),
      ),
      const SizedBox(height: 6),
      _bandReadout(state.band),
    ];
  }
}
