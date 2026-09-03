abstract class BleEvent {
  const BleEvent();
}

class BleStartTelemetryRequested extends BleEvent {
  const BleStartTelemetryRequested();
}

class BleSignalSampleReceived extends BleEvent {
  final double signal;
  const BleSignalSampleReceived(this.signal);
}

class BleStopTelemetryRequested extends BleEvent {
  const BleStopTelemetryRequested();
}
