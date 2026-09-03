abstract class IBLESensorDriver {
  Stream<double> get thermalStream;
  double get apneaThreshold;

  Future<bool> scanAndConnect();
  Future<double> calibrateStage1NoiseFloor();
  Future<double> calibrateStage2ActiveBreath();
  void startTelemetryLogging();
  void stopTelemetryLogging();
  void disconnect();
}
