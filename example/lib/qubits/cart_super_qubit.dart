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
  CartSuperQubit() {
    // Cross-Qubit communication: When cart becomes empty, trigger reload
    listenTo<CartItemsQubit>((dynamic state) {
      if (state is CartItemsState && state.isEmpty) {
        print('[CartSuperQubit] Cart is empty, triggering load...');
        dispatch<LoadQubit, LoadTriggerEvent>(LoadTriggerEvent());
      }
    });

    // Sibling-to-Sibling Communication: Sync filter changes to items
    listenTo<CartFilterQubit>((dynamic state) {
      if (state is CartFilterState) {
        print('[CartSuperQubit] Syncing filter to items: ${state.filter}');
        dispatch<CartItemsQubit, FilterItemsEvent>(
          FilterItemsEvent(state.filter),
        );
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

    // Parent to Child Communication: Intercept SearchEvent at parent level
    // This demonstrates the parent can also use transformers
    on<CartItemsQubit, SearchEvent>(
      (event, emit) async {
        print(
          '[CartSuperQubit] Parent intercepted SearchEvent: "${event.query}"',
        );

        // We can also use the emitter of the child directly from the parent
        // for forceful updates if needed (Parent-to-Child)
        if (event.query == 'force_reset') {
          print(
            '[CartSuperQubit] Force resetting cart items via direct emitter',
          );
          getQubit<CartItemsQubit>().emitter(const CartItemsState(items: []));
        }
      },
      config: EventHandlerConfig(
        transformer: Transformers.debounce(const Duration(milliseconds: 1000)),
      ),
    );
  }

  // Convenience getters for accessing child Qubits
  LoadQubit get load => getQubit<LoadQubit>();
  CartItemsQubit get items => getQubit<CartItemsQubit>();
  CartFilterQubit get filter => getQubit<CartFilterQubit>();
}
