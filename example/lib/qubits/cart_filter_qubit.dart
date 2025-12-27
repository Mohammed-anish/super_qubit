import 'package:super_qubit/super_qubit.dart';
import '../events/cart_events.dart';
import '../states/cart_states.dart';

/// Qubit for managing cart filter.
class CartFilterQubit extends Qubit<CartFilterEvent, CartFilterState> {
  CartFilterQubit() : super(const CartFilterState(filter: 'all')) {
    on<SetFilterEvent>((event, emit) {
      emit(CartFilterState(filter: event.filter));
    });
  }
}
