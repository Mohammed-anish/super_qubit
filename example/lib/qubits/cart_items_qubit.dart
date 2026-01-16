import 'package:super_qubit/super_qubit.dart';
import 'load_qubit.dart';
import '../events/cart_events.dart';
import '../states/cart_states.dart';
import '../models/cart_item.dart';

/// Qubit for managing cart items.
class CartItemsQubit extends Qubit<CartItemsEvent, CartItemsState> {
  // Store the master list of items internally to allow filtering/searching
  // without losing the original data.
  final List<CartItem> _allItems = [];
  String _currentQuery = '';
  String _currentFilter = 'all';

  CartItemsQubit() : super(const CartItemsState()) {
    // Register event handlers
    on<AddItemEvent>((event, emit) {
      final newItem = CartItem(
        id: DateTime.now().toString(),
        name: event.name,
        price: event.price,
      );
      _allItems.add(newItem);
      _refreshDisplay(emit);
    });

    on<RemoveItemEvent>((event, emit) {
      _allItems.removeWhere((item) => item.id == event.id);
      _refreshDisplay(emit);
    });

    on<ClearCartEvent>((event, emit) {
      _allItems.clear();
      _currentQuery = '';
      _currentFilter = 'all';
      emit(const CartItemsState(items: []));
      print('[CartItemsQubit] Cart cleared');
    });

    // Debounced search handler
    on<SearchEvent>(
      (event, emit) async {
        _currentQuery = event.query;
        print('[CartItemsQubit] Searching for: ${_currentQuery}');

        // Sibling Communication: Trigger loading state in LoadQubit
        await dispatch<LoadQubit, LoadTriggerEvent>(LoadTriggerEvent());

        // Simulate API delay
        await Future.delayed(const Duration(milliseconds: 500));

        _refreshDisplay(emit);
      },
      config: EventHandlerConfig(
        transformer: Transformers.debounce(const Duration(milliseconds: 500)),
      ),
    );

    // Filter items handler
    on<FilterItemsEvent>((event, emit) {
      _currentFilter = event.filter;
      print('[CartItemsQubit] Applying filter: ${_currentFilter}');
      _refreshDisplay(emit);
    });
  }

  void _refreshDisplay(Emitter<CartItemsState> emit) {
    Iterable<CartItem> results = List.from(_allItems);

    // Apply search query
    if (_currentQuery.isNotEmpty) {
      results = results.where(
        (item) => item.name.toLowerCase().contains(_currentQuery.toLowerCase()),
      );
    }

    // Apply filter
    if (_currentFilter == 'expensive') {
      results = results.where((item) => item.price >= 30);
    }

    emit(CartItemsState(items: results.toList()));
  }
}
