import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/app_button.dart';

class BleSimulatorOrganism extends StatefulWidget {
  final ValueChanged<bool>? onSimulatorToggled;
  final VoidCallback? onSimulateIdleNoise;
  final VoidCallback? onSimulateActiveBreath;
  final VoidCallback? onSimulateNormalBreathing;
  final VoidCallback? onSimulateApneaAlert;
  final VoidCallback? onSimulateRecovery;

  const BleSimulatorOrganism({
    super.key,
    this.onSimulatorToggled,
    this.onSimulateIdleNoise,
    this.onSimulateActiveBreath,
    this.onSimulateNormalBreathing,
    this.onSimulateApneaAlert,
    this.onSimulateRecovery,
  });

  @override
  State<BleSimulatorOrganism> createState() => _BleSimulatorOrganismState();
}

class _BleSimulatorOrganismState extends State<BleSimulatorOrganism> {
  bool _isSimulatorEnabled = true;
  String _activeStatus = "Ready";

  void _setStatus(String status) {
    setState(() {
      _activeStatus = status;
    });
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
              Row(
                children: const [
                  Icon(Icons.tune, color: AppColors.accentGreen, size: 24),
                  SizedBox(width: 10),
                  Text(
                    "BLE Signal Simulator",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isSimulatorEnabled,
                activeThumbColor: AppColors.accentGreen,
                onChanged: (val) {
                  setState(() {
                    _isSimulatorEnabled = val;
                  });
                  widget.onSimulatorToggled?.call(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Active Status: $_activeStatus",
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24, color: AppColors.cardBorder),

          // Calibration Section
          const Text(
            "1. Calibration Lifecycle Simulation",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Simulate Idle Noise (N_idle)",
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSimulatorEnabled
                      ? () {
                          _setStatus("Sampling Ambient Idle Noise Floor (Stage 1)");
                          widget.onSimulateIdleNoise?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Simulate Active Baseline (V_pp)",
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSimulatorEnabled
                      ? () {
                          _setStatus("Sampling Active Breathing Baseline (Stage 2)");
                          widget.onSimulateActiveBreath?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sleep Cycle Section
          const Text(
            "2. Nocturnal Sleep Cycle Simulation",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.purpleAnalytics),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Simulate Normal Respiration (16 bpm)",
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSimulatorEnabled
                      ? () {
                          _setStatus("Streaming Normal Respiration Waveform");
                          widget.onSimulateNormalBreathing?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Simulate Apnea Stop Alert (>10s)",
                  variant: AppButtonVariant.primary,
                  onPressed: _isSimulatorEnabled
                      ? () {
                          _setStatus("Apnea Breach Alert Triggered (>10s Drop)");
                          widget.onSimulateApneaAlert?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: "Simulate Patient Recovery (5s)",
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSimulatorEnabled
                      ? () {
                          _setStatus("Breathing Restored (5s Auto-Silence)");
                          widget.onSimulateRecovery?.call();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
