import 'package:equatable/equatable.dart';

/// The post-login flow gate. A login success does not jump straight to the tab
/// shell — it first checks live Bluetooth permission status and, if not yet
/// granted, routes through the one-time priming screen. Gating is always a live
/// status check, never a persisted "seen it" flag, so a later revocation is
/// caught on the next login.
enum AppFlowStage {
  loggedOut,
  checkingPermission,
  permissionCheckFailed,
  needsPrimer,
  ready,
}

class AppFlowState extends Equatable {
  final AppFlowStage stage;

  const AppFlowState({this.stage = AppFlowStage.loggedOut});

  AppFlowState copyWith({AppFlowStage? stage}) =>
      AppFlowState(stage: stage ?? this.stage);

  @override
  List<Object?> get props => [stage];
}
