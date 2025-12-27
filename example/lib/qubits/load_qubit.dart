import 'package:super_qubit/super_qubit.dart';
import '../events/cart_events.dart';
import '../states/cart_states.dart';

/// Qubit for managing load state.
class LoadQubit extends Qubit<LoadEvent, LoadState> {
  LoadQubit() : super(LoadState.initial()) {
    on<LoadTriggerEvent>((event, emit) async {
      emit(LoadState.loading());
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      emit(LoadState.loaded());
    });
  }
}
