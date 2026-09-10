import 'package:flutter_bloc/flutter_bloc.dart';
import 'history_event.dart';
import 'history_state.dart';

/// Owns the session-history filter selection, the seed session list and the
/// derived filtered list + AI-severity banding — the domain logic lifted out of
/// `_HistoryFilterPageState` unchanged.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc() : super(const HistoryState()) {
    on<HistoryFilterSelected>(
      (event, emit) =>
          emit(state.copyWith(selectedFilterIndex: event.index)),
    );
  }
}
