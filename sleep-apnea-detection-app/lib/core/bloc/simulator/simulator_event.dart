import 'package:equatable/equatable.dart';
import '../../ble/ble_simulator_driver.dart';

/// Events for [SimulatorBloc]. Public events are dispatched by Developer
/// Options / Settings UI; [SimulatorDriverStateChanged] is internal, added
/// only from the bloc's own `StreamSubscription`s on the driver streams.
abstract class SimulatorEvent extends Equatable {
  const SimulatorEvent();

  @override
  List<Object?> get props => const [];
}

/// Flip the simulator between active / inactive (toggle).
class SimulatorToggled extends SimulatorEvent {
  const SimulatorToggled();
}

/// Explicitly enable (`true`) or disable (`false`) the simulator.
class SimulatorEnabledSet extends SimulatorEvent {
  final bool enabled;
  const SimulatorEnabledSet(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Start a specific developer / QA telemetry scenario.
class SimulatorScenarioStarted extends SimulatorEvent {
  final SimulatorScenario scenario;
  const SimulatorScenarioStarted(this.scenario);

  @override
  List<Object?> get props => [scenario];
}

/// Stop the running scenario (returns to [SimulatorScenario.none]).
class SimulatorStopped extends SimulatorEvent {
  const SimulatorStopped();
}

/// Internal: the driver's own `isSimulatorStream` / `scenarioStream` pushed a
/// new value. Never dispatched from UI.
class SimulatorDriverStateChanged extends SimulatorEvent {
  final bool? isSimulatorActive;
  final SimulatorScenario? currentScenario;
  const SimulatorDriverStateChanged({
    this.isSimulatorActive,
    this.currentScenario,
  });

  @override
  List<Object?> get props => [isSimulatorActive, currentScenario];
}
