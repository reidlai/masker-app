import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ble/ble_simulator_driver.dart';
import 'simulator_state.dart';

/// BLoC Cubit managing the active state and scenarios of the BLE Telemetry Simulator.
/// Bridges RxDart streams from [BleSimulatorDriver] into reactive [SimulatorState] for UI widgets.
class SimulatorCubit extends Cubit<SimulatorState> {
  final BleSimulatorDriver _driver;
  StreamSubscription<bool>? _isSimSubscription;
  StreamSubscription<SimulatorScenario>? _scenarioSubscription;

  SimulatorCubit({BleSimulatorDriver? driver})
      : _driver = driver ?? BleSimulatorDriver(),
        super(SimulatorState(
          isSimulatorActive: (driver ?? BleSimulatorDriver()).isSimulatorActive,
          currentScenario: (driver ?? BleSimulatorDriver()).currentScenario,
        )) {
    // Pipe RxDart streams into reactive BLoC state updates
    _isSimSubscription = _driver.isSimulatorStream.listen((isSim) {
      if (!isClosed && state.isSimulatorActive != isSim) {
        emit(state.copyWith(isSimulatorActive: isSim));
      }
    });

    _scenarioSubscription = _driver.scenarioStream.listen((scenario) {
      if (!isClosed && state.currentScenario != scenario) {
        emit(state.copyWith(currentScenario: scenario));
      }
    });
  }

  void toggleSimulator() {
    setSimulatorEnabled(!state.isSimulatorActive);
  }

  void setSimulatorEnabled(bool enabled) {
    _driver.setSimulatorEnabled(enabled);
    if (!isClosed && state.isSimulatorActive != enabled) {
      emit(state.copyWith(isSimulatorActive: enabled));
    }
  }

  void startSimulationScenario(SimulatorScenario scenario) {
    _driver.startSimulationScenario(scenario);
    if (!isClosed && state.currentScenario != scenario) {
      emit(state.copyWith(currentScenario: scenario));
    }
  }

  void stopSimulation() {
    _driver.stopSimulation();
    if (!isClosed && state.currentScenario != SimulatorScenario.none) {
      emit(state.copyWith(currentScenario: SimulatorScenario.none));
    }
  }

  @override
  Future<void> close() {
    _isSimSubscription?.cancel();
    _scenarioSubscription?.cancel();
    return super.close();
  }
}
