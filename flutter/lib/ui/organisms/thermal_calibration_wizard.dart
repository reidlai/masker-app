import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/i_ble_sensor_driver.dart';
import '../atoms/app_button.dart';

class ThermalCalibrationWizard extends StatefulWidget {
  final IBLESensorDriver bleDriver;
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
  bool _isCalibrating = false;
  double _progress = 0.0;
  String _statusText = "Place D-BAND on bedside table for ambient noise ceiling sampling";

  void _runNoiseCeilingCalibration() async {
    setState(() {
      _isCalibrating = true;
      _progress = 0.5;
      _statusText = "Sampling ambient room noise ceiling (N_idle)...";
    });

    await widget.bleDriver.calibrateStage1NoiseCeiling();

    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _progress = 1.0;
        _statusText = "Calibration Complete ✓ — Signal Threshold Set: ${widget.bleDriver.signalThreshold.toStringAsFixed(2)} L/s";
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
                  color: AppColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: AppColors.accentGreen),
                ),
                child: const Text(
                  "AUTOMATIC CALIBRATION",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
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
          const Text(
            "Ambient Noise Ceiling Calibration",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _statusText,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: "Calibrate Noise Ceiling",
            isLoading: _isCalibrating,
            variant: AppButtonVariant.primary,
            onPressed: _runNoiseCeilingCalibration,
          ),
        ],
      ),
    );
  }
}
