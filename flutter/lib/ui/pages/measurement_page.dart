import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ble/ble_sensor_driver.dart';
import '../organisms/thermal_calibration_wizard.dart';
import '../atoms/app_button.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  final BLESensorDriver _bleDriver = BLESensorDriver();
  bool _isBleConnected = false;
  bool _isCalibrationComplete = false;
  bool _isMonitoringActive = false;

  @override
  void initState() {
    super.initState();
    _connectBle();
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
    setState(() {
      _isMonitoringActive = true;
    });
    _bleDriver.startTelemetryLogging();
  }

  void _stopSleepMonitoring() {
    _bleDriver.stopTelemetryLogging();
    if (mounted) {
      setState(() {
        _isMonitoringActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sleep session saved — Morning summary ready ✓"), backgroundColor: AppColors.accentGreen),
      );
    }
  }

  @override
  void dispose() {
    _bleDriver.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          color: AppColors.accentGreen.withOpacity(0.6),
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
              // BLE Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isBleConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                      color: _isBleConnected ? AppColors.accentGreen : AppColors.warningAmber,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBleConnected ? "D-BAND Sensor Connected ✓" : "Scanning for D-BAND (BLE 5.0+)...",
                          style: TextStyle(
                            color: _isBleConnected ? AppColors.accentGreen : AppColors.warningAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Service: 0x180D · AES-128 Encrypted",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calibration Wizard
              const Text("Bedtime Sensor Calibration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              ThermalCalibrationWizard(
                bleDriver: _bleDriver,
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
