abstract class IBLESensorDriver {
  Stream<double> get thermalStream;
  double get apneaThreshold;

  Future<bool> scanAndConnect();
  void startTelemetryLogging();
  void stopTelemetryLogging();
  void disconnect();
}
