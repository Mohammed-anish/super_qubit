/// Model class for a cart item.
class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  CartItem copyWith({String? id, String? name, double? price, int? quantity}) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  double get total => price * quantity;

  @override
  String toString() =>
      'CartItem(id: $id, name: $name, price: \$$price, qty: $quantity)';
}
