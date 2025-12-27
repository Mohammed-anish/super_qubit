import '../models/cart_item.dart';

/// State for Load Qubit
class LoadState {
  final bool isLoading;
  final String? error;

  const LoadState({this.isLoading = false, this.error});

  factory LoadState.initial() => const LoadState();
  factory LoadState.loading() => const LoadState(isLoading: true);
  factory LoadState.loaded() => const LoadState(isLoading: false);

  LoadState copyWith({bool? isLoading, String? error}) {
    return LoadState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'LoadState(isLoading: $isLoading, error: $error)';
}

/// State for CartItems Qubit
class CartItemsState {
  final List<CartItem> items;

  const CartItemsState({this.items = const []});

  CartItemsState copyWith({List<CartItem>? items}) {
    return CartItemsState(items: items ?? this.items);
  }

  double get total => items.fold(0, (sum, item) => sum + item.total);

  bool get isEmpty => items.isEmpty;

  @override
  String toString() =>
      'CartItemsState(items: ${items.length}, total: \$$total)';
}

/// State for CartFilter Qubit
class CartFilterState {
  final String filter;

  const CartFilterState({this.filter = 'all'});

  CartFilterState copyWith({String? filter}) {
    return CartFilterState(filter: filter ?? this.filter);
  }

  @override
  String toString() => 'CartFilterState(filter: $filter)';
}
