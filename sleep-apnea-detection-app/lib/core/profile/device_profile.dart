import 'package:equatable/equatable.dart';

/// The bound D-BAND sensor, as held by [DeviceProfileService].
///
/// Fields mirror the `DeviceBinding` entity in the architecture spine. Nothing
/// populates this in the current slice — the store only ever holds `null`
/// (empty) or a value set by a later fetch path.
class DeviceProfile extends Equatable {
  final String bindingId;
  final String deviceHardwareId;
  final String bleMacAddress;
  final String status;
  final DateTime? boundAt;

  const DeviceProfile({
    required this.bindingId,
    this.deviceHardwareId = '',
    this.bleMacAddress = '',
    this.status = '',
    this.boundAt,
  });

  @override
  List<Object?> get props =>
      [bindingId, deviceHardwareId, bleMacAddress, status, boundAt];
}
