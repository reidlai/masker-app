import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../ble/ble_receiver_service.dart';
import '../../ble/ble_simulator_driver.dart';
import '../../ble/flutter_blue_sensor_driver.dart';
import '../../ble/i_ble_sensor_driver.dart';
import 'simulator_event.dart';
import 'simulator_state.dart';

/// BLoC managing the active state and scenarios of the BLE Telemetry Simulator.
/// Bridges RxDart streams from [BleSimulatorDriver] into reactive
/// [SimulatorState] for UI widgets.
///
/// Standard `Bloc` idiom: UI dispatches [SimulatorEvent]s; the driver's own
/// `isSimulatorStream` / `scenarioStream` are piped back in via the internal
/// [SimulatorDriverStateChanged] event (never `emit`-from-`listen`).
class SimulatorBloc extends Bloc<SimulatorEvent, SimulatorState> {
  final BleSimulatorDriver _driver;

  /// The single boot-time unified queue (AD-12). When present, enabling /
  /// disabling the simulator swaps the receiver's active [IBLESensorDriver]
  /// through [BleReceiverService.setActiveDriver] so every downstream consumer
  /// keeps its one subscription (AD-11). Optional so the display-only fallback
  /// providers in the widget tree can still construct a bare `SimulatorBloc()`.
  final BleReceiverService? _receiver;

  /// The driver the receiver was bound to at construction — restored when the
  /// simulator is switched back off. When the receiver booted on the simulator
  /// (a `DEV_MODE` build) this is itself a [BleSimulatorDriver], which is not a
  /// usable restore target — see [_restoreTarget].
  final IBLESensorDriver? _fallbackDriver;

  /// Builds a real (non-simulator) driver to bind on disable when the captured
  /// [_fallbackDriver] is absent or is itself the simulator. Injectable so tests
  /// avoid `flutter_blue_plus` platform contact; production uses the default.
  final IBLESensorDriver Function() _hardwareDriverFactory;

  /// Lazily-built, reused restore driver (never one per disable).
  IBLESensorDriver? _hardwareFallback;

  /// The last explicit enable/disable the user asked for. A driver-stream value
  /// that contradicts this is treated as spurious and ignored (a residual
  /// `scanAndConnect` / `startSimulationScenario` on the singleton must not
  /// override the toggle).
  bool _intendedEnabled;

  StreamSubscription<bool>? _isSimSubscription;
  StreamSubscription<SimulatorScenario>? _scenarioSubscription;

  SimulatorBloc({
    BleSimulatorDriver? driver,
    BleReceiverService? receiver,
    IBLESensorDriver Function()? hardwareDriverFactory,
  })  : _driver = driver ?? BleSimulatorDriver.instance,
        _receiver = receiver,
        _fallbackDriver = receiver?.activeDriver,
        _hardwareDriverFactory =
            hardwareDriverFactory ?? FlutterBlueSensorDriver.new,
        _intendedEnabled =
            (driver ?? BleSimulatorDriver.instance).isSimulatorActive,
        super(SimulatorState(
          isSimulatorActive:
              (driver ?? BleSimulatorDriver.instance).isSimulatorActive,
          currentScenario:
              (driver ?? BleSimulatorDriver.instance).currentScenario,
        )) {
    on<SimulatorToggled>(_onToggled);
    on<SimulatorEnabledSet>(_onEnabledSet);
    on<SimulatorScenarioStarted>(_onScenarioStarted);
    on<SimulatorStopped>(_onStopped);
    on<SimulatorDriverStateChanged>(_onDriverStateChanged);

    // Pipe RxDart streams into reactive BLoC state updates via an internal
    // event. `.skip(1)` drops each BehaviorSubject's replayed current value —
    // the initial state above already reflects it — so only genuine driver-side
    // changes pump events (mirrors BleSimulatorDriver's own `.skip(1)` idiom).
    _isSimSubscription = _driver.isSimulatorStream.skip(1).listen((isSim) {
      if (!isClosed) {
        add(SimulatorDriverStateChanged(isSimulatorActive: isSim));
      }
    });

    _scenarioSubscription = _driver.scenarioStream.skip(1).listen((scenario) {
      if (!isClosed) {
        add(SimulatorDriverStateChanged(currentScenario: scenario));
      }
    });
  }

  void _onToggled(SimulatorToggled event, Emitter<SimulatorState> emit) {
    _setEnabled(!state.isSimulatorActive, emit);
  }

  void _onEnabledSet(SimulatorEnabledSet event, Emitter<SimulatorState> emit) {
    _setEnabled(event.enabled, emit);
  }

  /// The non-simulator driver to bind on disable. Prefers the driver the
  /// receiver actually booted on; falls back to a real hardware driver when that
  /// is absent or is itself the simulator (the `DEV_MODE` case).
  IBLESensorDriver _restoreTarget() {
    final captured = _fallbackDriver;
    if (captured != null && captured is! BleSimulatorDriver) return captured;
    return _hardwareFallback ??= _hardwareDriverFactory();
  }

  void _setEnabled(bool enabled, Emitter<SimulatorState> emit) {
    _intendedEnabled = enabled;
    // Centralize the simulator <-> hardware swap on the one unified queue
    // (AD-11 / AD-12): bind the simulator as the receiver's active driver on
    // enable, a real driver on disable so "simulator off" genuinely leaves the
    // simulator. No-op when this bloc has no receiver (display-only fallback
    // providers).
    if (enabled) {
      _receiver?.setActiveDriver(_driver);
    } else if (_receiver != null) {
      _receiver!.setActiveDriver(_restoreTarget());
    }
    _driver.setSimulatorEnabled(enabled);
    if (state.isSimulatorActive != enabled) {
      emit(state.copyWith(isSimulatorActive: enabled));
    }
  }

  void _onScenarioStarted(
    SimulatorScenarioStarted event,
    Emitter<SimulatorState> emit,
  ) {
    _driver.startSimulationScenario(event.scenario);
    if (state.currentScenario != event.scenario) {
      emit(state.copyWith(currentScenario: event.scenario));
    }
  }

  void _onStopped(SimulatorStopped event, Emitter<SimulatorState> emit) {
    _driver.stopSimulation();
    if (state.currentScenario != SimulatorScenario.none) {
      emit(state.copyWith(currentScenario: SimulatorScenario.none));
    }
  }

  void _onDriverStateChanged(
    SimulatorDriverStateChanged event,
    Emitter<SimulatorState> emit,
  ) {
    var next = state;
    // Only honour a driver-stream active flag that agrees with the user's last
    // explicit choice — a residual `scanAndConnect` / `startSimulationScenario`
    // on the singleton must not flip the toggle back.
    if (event.isSimulatorActive != null &&
        event.isSimulatorActive == _intendedEnabled &&
        next.isSimulatorActive != event.isSimulatorActive) {
      next = next.copyWith(isSimulatorActive: event.isSimulatorActive);
    }
    if (event.currentScenario != null &&
        next.currentScenario != event.currentScenario) {
      next = next.copyWith(currentScenario: event.currentScenario);
    }
    if (next != state) emit(next);
  }

  @override
  Future<void> close() {
    _isSimSubscription?.cancel();
    _scenarioSubscription?.cancel();
    return super.close();
  }
}
