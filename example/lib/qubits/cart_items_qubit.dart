import 'package:super_qubit/super_qubit.dart';
import '../events/cart_events.dart';
import '../states/cart_states.dart';
import '../models/cart_item.dart';

/// Qubit for managing cart items.
class CartItemsQubit extends Qubit<CartItemsEvent, CartItemsState> {
  CartItemsQubit() : super(const CartItemsState()) {
    // Register event handlers
    on<AddItemEvent>((event, emit) {
      final newItem = CartItem(
        id: DateTime.now().toString(),
        name: event.name,
        price: event.price,
      );
      emit(CartItemsState(items: [...state.items, newItem]));
    });

    on<RemoveItemEvent>((event, emit) {
      emit(
        CartItemsState(
          items: state.items.where((item) => item.id != event.id).toList(),
        ),
      );
    });

    on<ClearCartEvent>((event, emit) {
      emit(const CartItemsState(items: []));
      print('[CartItemsQubit] Cart cleared');
    });
  }
}
