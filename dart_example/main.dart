import 'dart:async';
import 'package:super_qubit/super_qubit.dart';

// ============================================================================
// Events
// ============================================================================

class LoadEvent {}

class AddItemEvent extends CartItemsEvent {
  final String name;
  final double price;
  AddItemEvent(this.name, this.price);
}

class RemoveItemEvent extends CartItemsEvent {
  final String id;
  RemoveItemEvent(this.id);
}

class ClearCartEvent extends CartItemsEvent {}

abstract class CartItemsEvent {}

// ============================================================================
// States
// ============================================================================

class LoadState {
  final bool isLoading;
  final String? error;

  const LoadState({this.isLoading = false, this.error});

  factory LoadState.initial() => const LoadState();

  @override
  String toString() => 'LoadState(isLoading: $isLoading, error: $error)';
}

class CartItem {
  final String id;
  final String name;
  final double price;

  CartItem(this.id, this.name, this.price);

  @override
  String toString() => 'CartItem($name, \$$price)';
}

class CartItemsState {
  final List<CartItem> items;

  const CartItemsState({this.items = const []});

  factory CartItemsState.initial() => const CartItemsState();

  bool get isEmpty => items.isEmpty;
  double get total => items.fold(0, (sum, item) => sum + item.price);

  @override
  String toString() => 'CartItemsState(${items.length} items, total: \$$total)';
}

// ============================================================================
// Qubits
// ============================================================================

class LoadQubit extends Qubit<LoadEvent, LoadState> {
  LoadQubit() : super(LoadState.initial()) {
    on<LoadEvent>((event, emit) async {
      print('  [LoadQubit] Loading started...');
      emit(const LoadState(isLoading: true));

      // Simulate loading
      await Future.delayed(const Duration(milliseconds: 500));

      emit(const LoadState(isLoading: false));
      print('  [LoadQubit] Loading completed');
    });
  }
}

class CartItemsQubit extends Qubit<CartItemsEvent, CartItemsState> {
  CartItemsQubit() : super(CartItemsState.initial()) {
    on<AddItemEvent>((event, emit) {
      final newItem = CartItem(
        DateTime.now().millisecondsSinceEpoch.toString(),
        event.name,
        event.price,
      );

      final updatedItems = [...state.items, newItem];
      emit(CartItemsState(items: updatedItems));
      print('  [CartItemsQubit] Added: ${newItem.name} (\$${newItem.price})');
    });

    on<RemoveItemEvent>((event, emit) {
      final updatedItems = state.items
          .where((item) => item.id != event.id)
          .toList();
      emit(CartItemsState(items: updatedItems));
      print('  [CartItemsQubit] Removed item: ${event.id}');
    });

    on<ClearCartEvent>((event, emit) {
      emit(const CartItemsState(items: []));
      print('  [CartItemsQubit] Cart cleared');
    });
  }
}

// ============================================================================
// SuperQubit
// ============================================================================

class CartSuperQubit extends SuperQubit {
  CartSuperQubit() {
    print('[CartSuperQubit] Created');
  }

  /// Initialize handlers after Qubits are registered.
  /// Must be called after registerQubits().
  void init() {
    print('[CartSuperQubit] Initializing handlers...');

    // Cross-Qubit communication: When cart becomes empty, trigger reload
    listenTo<CartItemsQubit>((dynamic state) async {
      if (state is CartItemsState && state.isEmpty) {
        print('  [CartSuperQubit] Cart is empty, triggering load...');
        await dispatch<LoadQubit, LoadEvent>(LoadEvent());
      }
    });

    // Parent-level event handler: Log all add item events
    on<CartItemsQubit, AddItemEvent>((event, emit) async {
      print('[CartSuperQubit] Parent handling AddItemEvent: ${event.name}');
      // Parent can emit state for child!
      // emit(CartItemsState([])); // Clear cart example
    });

    // Parent handler with flag: Only runs if child doesn't handle it
    on<LoadQubit, LoadEvent>((event, emit) async {
      print('[CartSuperQubit] Parent handling LoadEvent');
    }, config: ignoreWhenChildDefines<LoadQubit>());

    print('[CartSuperQubit] Initialized\n');
  }

  LoadQubit get load => getQubit<LoadQubit>();
  CartItemsQubit get items => getQubit<CartItemsQubit>();
}

// ============================================================================
// Main Example
// ============================================================================

void main() async {
  print('='.padRight(70, '='));
  print('Multi-State Management Library - Dart Example');
  print('='.padRight(70, '='));
  print('');

  // Create SuperQubit and register child Qubits
  final cart = CartSuperQubit();
  cart.registerQubits([LoadQubit(), CartItemsQubit()]);

  // Initialize handlers AFTER registration
  cart.init();

  // Subscribe to state changes
  print('📡 Setting up state listeners...\n');

  cart.load.stream.listen((state) {
    print('  🔄 Load state changed: $state');
  });

  cart.items.stream.listen((state) {
    print('  🛒 Cart state changed: $state');
  });

  print('');

  // ========================================================================
  // Demo 1: Add items to cart
  // ========================================================================
  print('📦 Demo 1: Adding items to cart');
  print('-'.padRight(70, '-'));

  await cart.items.add(AddItemEvent('Laptop', 999.99));
  await Future.delayed(const Duration(milliseconds: 100));

  await cart.items.add(AddItemEvent('Mouse', 29.99));
  await Future.delayed(const Duration(milliseconds: 100));

  await cart.items.add(AddItemEvent('Keyboard', 79.99));
  await Future.delayed(const Duration(milliseconds: 100));

  print('\n✅ Current cart: ${cart.items.state}');
  print('');

  // ========================================================================
  await cart.dispatch<LoadQubit, LoadEvent>(LoadEvent());
  await Future.delayed(const Duration(milliseconds: 600));

  print('');

  // ========================================================================
  // Demo 3: Remove items
  // ========================================================================
  print('🗑️  Demo 3: Removing items');
  print('-'.padRight(70, '-'));

  final firstItemId = cart.items.state.items.first.id;
  await cart.items.add(RemoveItemEvent(firstItemId));
  await Future.delayed(const Duration(milliseconds: 100));

  print('\n✅ Current cart: ${cart.items.state}');
  print('');

  // ========================================================================
  // Demo 4: Clear cart (triggers cross-Qubit communication)
  // ========================================================================
  print('🧹 Demo 4: Clearing cart (watch for auto-load trigger)');
  print('-'.padRight(70, '-'));

  await cart.items.add(ClearCartEvent());
  await Future.delayed(const Duration(milliseconds: 700));

  print('\n✅ Cart is now empty: ${cart.items.state}');
  print('');

  // ========================================================================
  // Demo 5: Access child Qubits directly
  // ========================================================================
  print('🎯 Demo 5: Direct Qubit access');
  print('-'.padRight(70, '-'));

  final loadQubit = cart.getQubit<LoadQubit>();
  print('  Load Qubit current state: ${loadQubit.state}');

  final itemsQubit = cart.getQubit<CartItemsQubit>();
  print('  Items Qubit current state: ${itemsQubit.state}');
  print('');

  // ========================================================================
  // Demo 6: Event propagation flags
  // ========================================================================
  print('🚦 Demo 6: Event propagation (parent ignores if child handles)');
  print('-'.padRight(70, '-'));
  print(
    '  Note: Parent handler for LoadEvent has ignoreWhenChildDefines<LoadQubit>()',
  );
  print(
    '  Since LoadQubit handles LoadEvent, parent handler will NOT execute.',
  );
  await cart.dispatch<LoadQubit, LoadEvent>(LoadEvent());
  await Future.delayed(const Duration(milliseconds: 600));

  print('');

  // Cleanup
  print('🧹 Cleaning up...');
  await cart.close();

  print('');
  print('='.padRight(70, '='));
  print('✅ Example completed successfully!');
  print('='.padRight(70, '='));
}
