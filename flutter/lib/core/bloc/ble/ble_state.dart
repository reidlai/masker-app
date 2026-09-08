import 'package:equatable/equatable.dart';

abstract class BleState extends Equatable {
  const BleState();

  @override
  List<Object?> get props => const [];
}

class BleInitialState extends BleState {
  const BleInitialState();
}

class BleTelemetryActiveState extends BleState {
  final double currentSignal;
  final bool isSimulatorMode;
  final double estimatedBatteryDrainPercent;

  const BleTelemetryActiveState({
    required this.currentSignal,
    this.isSimulatorMode = false,
    this.estimatedBatteryDrainPercent = 0.5,
  });

  @override
  List<Object?> get props =>
      [currentSignal, isSimulatorMode, estimatedBatteryDrainPercent];
}

class BleDisconnectedState extends BleState {
  const BleDisconnectedState();
}
