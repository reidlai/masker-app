abstract class BleState {
  const BleState();
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleTelemetryActiveState &&
          runtimeType == other.runtimeType &&
          currentSignal == other.currentSignal &&
          isSimulatorMode == other.isSimulatorMode &&
          estimatedBatteryDrainPercent == other.estimatedBatteryDrainPercent;

  @override
  int get hashCode =>
      currentSignal.hashCode ^
      isSimulatorMode.hashCode ^
      estimatedBatteryDrainPercent.hashCode;
}

class BleDisconnectedState extends BleState {
  const BleDisconnectedState();
}
