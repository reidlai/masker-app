import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => const [];
}

/// A severity filter chip was tapped.
class HistoryFilterSelected extends HistoryEvent {
  final int index;
  const HistoryFilterSelected(this.index);

  @override
  List<Object?> get props => [index];
}
