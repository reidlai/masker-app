import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:masker_app/core/ble/ble_receiver_service.dart';
import 'package:masker_app/core/ble/ble_simulator_driver.dart';
import 'package:masker_app/core/ble/i_ble_sensor_driver.dart';
import 'package:masker_app/core/bloc/simulator/simulator_bloc.dart';
import 'package:masker_app/core/bloc/simulator/simulator_event.dart';
import 'package:masker_app/core/bloc/simulator/simulator_state.dart';
import 'package:masker_app/core/monitoring/drift_and_noise_floor_envelope.dart';

class _MockSimDriver extends Mock implements BleSimulatorDriver {}

/// Stand-in for the boot-time hardware driver the receiver is bound to before
/// the simulator is switched on.
class _FakeHardwareDriver implements IBLESensorDriver {
  final StreamController<double> _signal = StreamController<double>.broadcast();
  @override
  Stream<double> get signalStream => _signal.stream;
  @override
  SensorMonitoringPhase get currentPhase => SensorMonitoringPhase.disconnected;
  @override
  Stream<SensorMonitoringPhase> get phaseStream => const Stream.empty();
  @override
  Future<bool> scanAndConnect() async => true;
  @override
  Future<IdleBand> sampleIdleBand({Duration window = kIdleSampleWindow}) async =>
      const IdleBand(lower: 0.2, upper: 0.4);
  @override
  void startMonitoringSession() {}
  @override
  void stopMonitoringSession() {}
  @override
  void disconnect() {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(SimulatorScenario.none);
  });

  late _MockSimDriver driver;
  late BehaviorSubject<bool> isSim;
  late BehaviorSubject<SimulatorScenario> scenario;
  late BehaviorSubject<double> signal;

  setUp(() {
    driver = _MockSimDriver();
    isSim = BehaviorSubject<bool>.seeded(false);
    scenario = BehaviorSubject<SimulatorScenario>.seeded(SimulatorScenario.none);
    signal = BehaviorSubject<double>.seeded(0.3);

    when(() => driver.isSimulatorActive).thenReturn(false);
    when(() => driver.currentScenario).thenReturn(SimulatorScenario.none);
    when(() => driver.isSimulatorStream).thenAnswer((_) => isSim);
    when(() => driver.scenarioStream).thenAnswer((_) => scenario);
    when(() => driver.signalStream).thenAnswer((_) => signal);

    // Faithful to BleSimulatorDriver: the concrete driver mirrors every command
    // back onto its own RxDart subjects.
    when(() => driver.setSimulatorEnabled(any())).thenAnswer((inv) {
      isSim.add(inv.positionalArguments.first as bool);
    });
    when(() => driver.startSimulationScenario(any())).thenAnswer((inv) {
      isSim.add(true);
      scenario.add(inv.positionalArguments.first as SimulatorScenario);
    });
    when(() => driver.stopSimulation()).thenAnswer((_) {
      scenario.add(SimulatorScenario.none);
    });
  });

  tearDown(() async {
    await isSim.close();
    await scenario.close();
    await signal.close();
  });

  test('initial state mirrors the injected driver', () {
    final bloc = SimulatorBloc(driver: driver);
    expect(
      bloc.state,
      const SimulatorState(
        isSimulatorActive: false,
        currentScenario: SimulatorScenario.none,
      ),
    );
    bloc.close();
  });

  blocTest<SimulatorBloc, SimulatorState>(
    'SimulatorEnabledSet(true) enables the driver and emits active state',
    build: () => SimulatorBloc(driver: driver),
    act: (bloc) => bloc.add(const SimulatorEnabledSet(true)),
    expect: () => const [
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
    ],
    verify: (_) => verify(() => driver.setSimulatorEnabled(true)).called(1),
  );

  blocTest<SimulatorBloc, SimulatorState>(
    'SimulatorToggled flips the active flag',
    build: () => SimulatorBloc(driver: driver),
    act: (bloc) => bloc.add(const SimulatorToggled()),
    expect: () => const [
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
    ],
    verify: (_) => verify(() => driver.setSimulatorEnabled(true)).called(1),
  );

  blocTest<SimulatorBloc, SimulatorState>(
    'SimulatorScenarioStarted forwards to the driver and emits the scenario',
    build: () => SimulatorBloc(driver: driver),
    act: (bloc) async {
      bloc.add(const SimulatorEnabledSet(true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(
          const SimulatorScenarioStarted(SimulatorScenario.normalRespiration));
    },
    expect: () => const [
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.normalRespiration,
      ),
    ],
    verify: (_) => verify(() =>
            driver.startSimulationScenario(SimulatorScenario.normalRespiration))
        .called(1),
  );

  blocTest<SimulatorBloc, SimulatorState>(
    'SimulatorStopped resets the scenario to none',
    build: () => SimulatorBloc(driver: driver),
    act: (bloc) async {
      bloc.add(const SimulatorEnabledSet(true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const SimulatorScenarioStarted(SimulatorScenario.recovery));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const SimulatorStopped());
    },
    expect: () => const [
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.recovery,
      ),
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
    ],
    verify: (_) => verify(() => driver.stopSimulation()).called(1),
  );

  blocTest<SimulatorBloc, SimulatorState>(
    'scenario-stream pushes are pumped in via the internal event',
    build: () => SimulatorBloc(driver: driver),
    act: (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      scenario.add(SimulatorScenario.idleBandSample);
    },
    expect: () => const [
      SimulatorState(
        isSimulatorActive: false,
        currentScenario: SimulatorScenario.idleBandSample,
      ),
    ],
  );

  blocTest<SimulatorBloc, SimulatorState>(
    'a driver active-flag push that contradicts the last explicit toggle is ignored',
    build: () => SimulatorBloc(driver: driver),
    act: (bloc) async {
      bloc.add(const SimulatorEnabledSet(true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const SimulatorEnabledSet(false));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      isSim.add(true); // residual scanAndConnect / startSimulationScenario
      await Future<void>.delayed(const Duration(milliseconds: 10));
    },
    expect: () => const [
      SimulatorState(
        isSimulatorActive: true,
        currentScenario: SimulatorScenario.none,
      ),
      SimulatorState(
        isSimulatorActive: false,
        currentScenario: SimulatorScenario.none,
      ),
      // isSim.add(true) yields no further state — the toggle stays off.
    ],
  );

  test(
      'with a receiver: enable binds the simulator as the active driver; '
      'disable restores the driver captured at construction', () async {
    final fallback = _FakeHardwareDriver();
    final receiver = BleReceiverService.withDriver(fallback);
    addTearDown(receiver.dispose);

    final bloc = SimulatorBloc(driver: driver, receiver: receiver);
    addTearDown(bloc.close);

    // Captured at construction.
    expect(receiver.activeDriver, same(fallback));

    bloc.add(const SimulatorEnabledSet(true));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(driver),
        reason: 'enable -> BleReceiverService.setActiveDriver(simulator)');

    bloc.add(const SimulatorEnabledSet(false));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(fallback),
        reason: 'disable -> _fallbackDriver restored');
  });

  test(
      'disable leaves the simulator even when the boot driver WAS the simulator '
      '(DEV_MODE): rebinds a hardware-factory driver', () async {
    final receiver = BleReceiverService.withDriver(BleSimulatorDriver());
    addTearDown(receiver.dispose);
    addTearDown(() => BleSimulatorDriver().resetForTest());
    final hw = _FakeHardwareDriver();

    final bloc = SimulatorBloc(
      driver: driver,
      receiver: receiver,
      hardwareDriverFactory: () => hw,
    );
    addTearDown(bloc.close);
    expect(receiver.activeDriver, isA<BleSimulatorDriver>());

    bloc.add(const SimulatorEnabledSet(false));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(receiver.activeDriver, same(hw),
        reason: 'no usable captured fallback -> hardware factory driver');
    expect(bloc.state.isSimulatorActive, isFalse);
  });

  test('re-enable after such a disable rebinds the simulator', () async {
    final receiver = BleReceiverService.withDriver(BleSimulatorDriver());
    addTearDown(receiver.dispose);
    addTearDown(() => BleSimulatorDriver().resetForTest());
    final hw = _FakeHardwareDriver();

    final bloc = SimulatorBloc(
      driver: driver,
      receiver: receiver,
      hardwareDriverFactory: () => hw,
    );
    addTearDown(bloc.close);

    bloc.add(const SimulatorEnabledSet(false));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(hw));

    bloc.add(const SimulatorEnabledSet(true));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(driver),
        reason: 're-enable -> simulator rebound');
    expect(bloc.state.isSimulatorActive, isTrue);
  });

  test('SimulatorToggled from active applies the restore target too', () async {
    final receiver = BleReceiverService.withDriver(BleSimulatorDriver());
    addTearDown(receiver.dispose);
    addTearDown(() => BleSimulatorDriver().resetForTest());
    final hw = _FakeHardwareDriver();

    final bloc = SimulatorBloc(
      driver: driver,
      receiver: receiver,
      hardwareDriverFactory: () => hw,
    );
    addTearDown(bloc.close);

    bloc.add(const SimulatorEnabledSet(true));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(driver));

    bloc.add(const SimulatorToggled()); // active -> off
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(receiver.activeDriver, same(hw));
    expect(bloc.state.isSimulatorActive, isFalse);
  });

  test('the hardware-factory driver is built once and reused across disables',
      () async {
    final receiver = BleReceiverService.withDriver(BleSimulatorDriver());
    addTearDown(receiver.dispose);
    addTearDown(() => BleSimulatorDriver().resetForTest());
    var builds = 0;
    final hw = _FakeHardwareDriver();

    final bloc = SimulatorBloc(
      driver: driver,
      receiver: receiver,
      hardwareDriverFactory: () {
        builds++;
        return hw;
      },
    );
    addTearDown(bloc.close);

    bloc.add(const SimulatorEnabledSet(false));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const SimulatorEnabledSet(true));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const SimulatorEnabledSet(false));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(builds, 1);
    expect(receiver.activeDriver, same(hw));
  });
}
