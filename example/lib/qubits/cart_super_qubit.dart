import 'package:super_qubit/super_qubit.dart';
import 'load_qubit.dart';
import 'cart_items_qubit.dart';
import 'cart_filter_qubit.dart';
import '../events/cart_events.dart';
import '../states/cart_states.dart';

/// SuperQubit that manages all cart-related Qubits.
///
/// Demonstrates:
/// - Cross-Qubit communication
/// - Parent-level event handling
/// - State listening between Qubits
class CartSuperQubit extends SuperQubit {
  CartSuperQubit();

  /// Initialize handlers after Qubits are registered.
  /// This is called automatically by QubitProvider.
  void init() {
    // Cross-Qubit communication: When cart becomes empty, trigger reload
    listenTo<CartItemsQubit>((dynamic state) {
      if (state is CartItemsState && state.isEmpty) {
        print('[CartSuperQubit] Cart is empty, triggering load...');
        dispatch<LoadQubit, LoadTriggerEvent>(LoadTriggerEvent());
      }
    });

    // Parent-level event handler: Log all add item events
    // This runs AFTER the child handler (CartItemsQubit)
    on<CartItemsQubit, AddItemEvent>((event, emit) async {
      print('[CartSuperQubit] Analytics: Item "${event.name}" added to cart');
      // Could send analytics, update recommendations, etc.
    });

    // Parent-level event handler with flag: Only runs if child doesn't handle it
    // This demonstrates the ignoreWhenChildDefines flag
    on<LoadQubit, LoadTriggerEvent>((event, emit) async {
      print(
        '[CartSuperQubit] Parent handling load (this should not print if child handles it)',
      );
      // Example of emitting state from parent:
      // emit(LoadState.loading());
    }, config: ignoreWhenChildDefines<LoadQubit>());
  }

  // Convenience getters for accessing child Qubits
  LoadQubit get load => getQubit<LoadQubit>();
  CartItemsQubit get items => getQubit<CartItemsQubit>();
  CartFilterQubit get filter => getQubit<CartFilterQubit>();
}
