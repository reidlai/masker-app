import 'package:equatable/equatable.dart';

abstract class BleEvent extends Equatable {
  const BleEvent();

  @override
  List<Object?> get props => const [];
}

class BleStartTelemetryRequested extends BleEvent {
  const BleStartTelemetryRequested();
}

class BleSignalSampleReceived extends BleEvent {
  final double signal;
  const BleSignalSampleReceived(this.signal);

  @override
  List<Object?> get props => [signal];
}

class BleStopTelemetryRequested extends BleEvent {
  const BleStopTelemetryRequested();
}
