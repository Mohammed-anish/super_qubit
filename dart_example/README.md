# Pure Dart Example

This example demonstrates the state management library **without Flutter UI**, using only pure Dart.

## Running the Example

```bash
cd dart_example
dart main.dart
```

## What It Demonstrates

### ✅ Core Features

1. **Qubit Creation**
   - `LoadQubit` - Manages loading state
   - `CartItemsQubit` - Manages cart items

2. **SuperQubit**
   - `CartSuperQubit` - Orchestrates multiple Qubits
   - Registers child Qubits
   - Provides convenient getters

3. **Event Handling**
   - `on<Event>(handler)` - Register event handlers
   - `add(event)` - Dispatch events

4. **Cross-Qubit Communication**
   - `listenTo<T>(callback)` - Listen to child state changes
   - `dispatch<T>(event)` - Send events to specific Qubits
   - Automatic load trigger when cart becomes empty

5. **Event Propagation Flags**
   - `ignoreWhenChildDefines<T>()` - Parent skips if child handles
   - Demonstrates parent/child handler coordination

6. **State Streams**
   - Subscribe to state changes with `stream.listen()`
   - Reactive updates when state changes

7. **Direct Qubit Access**
   - `getQubit<T>()` - Access child Qubits
   - Read current state directly

## Example Output

```
======================================================================
Multi-State Management Library - Dart Example
======================================================================

[CartSuperQubit] Initializing...
[CartSuperQubit] Initialized

📡 Setting up state listeners...

📦 Demo 1: Adding items to cart
----------------------------------------------------------------------
  [CartItemsQubit] Added: Laptop ($999.99)
  [CartSuperQubit] Analytics: Item "Laptop" added to cart
  🛒 Cart state changed: CartItemsState(1 items, total: $999.99)
  ...

🔄 Demo 2: Triggering load manually
----------------------------------------------------------------------
  [LoadQubit] Loading started...
  🔄 Load state changed: LoadState(isLoading: true, error: null)
  [LoadQubit] Loading completed
  🔄 Load state changed: LoadState(isLoading: false, error: null)

🗑️  Demo 3: Removing items
----------------------------------------------------------------------
  [CartItemsQubit] Removed item: 1735295428123
  🛒 Cart state changed: CartItemsState(2 items, total: $109.98)

🧹 Demo 4: Clearing cart (watch for auto-load trigger)
----------------------------------------------------------------------
  [CartItemsQubit] Cart cleared
  🛒 Cart state changed: CartItemsState(0 items, total: $0.0)
  [CartSuperQubit] Cart is empty, triggering load...
  [LoadQubit] Loading started...
  🔄 Load state changed: LoadState(isLoading: true, error: null)
  [LoadQubit] Loading completed
  🔄 Load state changed: LoadState(isLoading: false, error: null)

✅ Example completed successfully!
```

## Key Demonstrations

### Cross-Qubit Communication

When the cart is cleared (becomes empty), the SuperQubit automatically triggers a load:

```dart
listenTo<CartItemsQubit>((dynamic state) {
  if (state is CartItemsState && state.isEmpty) {
    dispatch<LoadQubit>(LoadEvent());
  }
});
```

### Parent Event Handlers

Parent can intercept child events for analytics or logging:

```dart
on<CartItemsQubit, AddItemEvent>((event) async {
  print('Analytics: Item "${event.name}" added to cart');
});
```

### Event Propagation Flags

Parent handler only runs if child doesn't handle the event:

```dart
on<LoadQubit, LoadEvent>((event) async {
  // This won't execute because LoadQubit handles LoadEvent
}, ignoreWhenChildDefines<LoadQubit>());
```

## No Flutter Required

This example uses **zero Flutter dependencies** - just pure Dart with the core library!
