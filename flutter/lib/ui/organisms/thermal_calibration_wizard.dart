import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/ble_sensor_driver.dart';
import '../atoms/app_button.dart';

class ThermalCalibrationWizard extends StatefulWidget {
  final BLESensorDriver bleDriver;
  final VoidCallback onCalibrationComplete;

  const ThermalCalibrationWizard({
    super.key,
    required this.bleDriver,
    required this.onCalibrationComplete,
  });

  @override
  State<ThermalCalibrationWizard> createState() => _ThermalCalibrationWizardState();
}

class _ThermalCalibrationWizardState extends State<ThermalCalibrationWizard> {
  int _currentStep = 1;
  bool _isCalibrating = false;
  double _progress = 0.0;
  String _statusText = "Place D-BAND on bedside table for room noise sampling";

  void _runStage1() async {
    setState(() {
      _isCalibrating = true;
      _progress = 0.3;
      _statusText = "Sampling ambient room noise floor (N_idle)...";
    });

    await widget.bleDriver.calibrateStage1NoiseFloor();

    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _progress = 0.5;
        _currentStep = 2;
        _statusText = "Attach D-BAND to face & breathe normally for active training";
      });
    }
  }

  void _runStage2() async {
    setState(() {
      _isCalibrating = true;
      _progress = 0.8;
      _statusText = "Measuring active inhale/exhale thermal deviation (ΔT)...";
    });

    await widget.bleDriver.calibrateStage2ActiveBreath();

    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _progress = 1.0;
        _statusText = "Calibration Verified ✓ — Apnea Threshold: ${widget.bleDriver.apneaThreshold.toStringAsFixed(2)} L/s";
      });
      widget.onCalibrationComplete();
    }
  }

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.accentGreen),
                ),
                child: Text(
                  "STEP $_currentStep OF 2",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                ),
              ),
              Text(
                "${(_progress * 100).toInt()}%",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.background,
            color: AppColors.accentGreen,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStep == 1 ? "Stage 1: Ambient Room Noise Floor" : "Stage 2: Active Thermal Breath Baseline",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _statusText,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_currentStep == 1)
            AppButton(
              label: "Start Stage 1 Calibration",
              isLoading: _isCalibrating,
              variant: AppButtonVariant.primary,
              onPressed: _runStage1,
            )
          else
            AppButton(
              label: "Start Stage 2 Calibration",
              isLoading: _isCalibrating,
              variant: AppButtonVariant.primary,
              onPressed: _runStage2,
            ),
        ],
      ),
    );
  }
}
