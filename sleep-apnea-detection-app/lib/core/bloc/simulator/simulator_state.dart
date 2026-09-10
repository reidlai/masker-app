import 'package:equatable/equatable.dart';
import '../../ble/ble_simulator_driver.dart';

class SimulatorState extends Equatable {
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
  List<Object?> get props => [isSimulatorActive, currentScenario];
}
