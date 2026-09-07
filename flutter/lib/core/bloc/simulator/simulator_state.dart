import '../../ble/ble_simulator_driver.dart';

class SimulatorState {
  final bool isSimulatorActive;
  final SimulatorScenario currentScenario;

  const SimulatorState({
    required this.isSimulatorActive,
    required this.currentScenario,
  });

  SimulatorState copyWith({
    bool? isSimulatorActive,
    SimulatorScenario? currentScenario,
  }) {
    return SimulatorState(
      isSimulatorActive: isSimulatorActive ?? this.isSimulatorActive,
      currentScenario: currentScenario ?? this.currentScenario,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimulatorState &&
          runtimeType == other.runtimeType &&
          isSimulatorActive == other.isSimulatorActive &&
          currentScenario == other.currentScenario;

  @override
  int get hashCode => isSimulatorActive.hashCode ^ currentScenario.hashCode;
}
