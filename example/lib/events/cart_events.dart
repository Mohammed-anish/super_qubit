// Events for Load Qubit
abstract class LoadEvent {}

class LoadTriggerEvent extends LoadEvent {}

// Events for CartItems Qubit
abstract class CartItemsEvent {}

class AddItemEvent extends CartItemsEvent {
  final String name;
  final double price;

  AddItemEvent({required this.name, required this.price});
}

class RemoveItemEvent extends CartItemsEvent {
  final String id;

  RemoveItemEvent(this.id);
}

class ClearCartEvent extends CartItemsEvent {}

// Events for CartFilter Qubit
abstract class CartFilterEvent {}

class SetFilterEvent extends CartFilterEvent {
  final String filter;

  SetFilterEvent(this.filter);
}
