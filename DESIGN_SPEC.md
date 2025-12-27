# Multi-State Management System - Design Specification

## Overview
A hierarchical state management system where a single `SuperQubit` can manage multiple child `Qubit` instances, with flexible event handling and cross-Qubit communication.

## Core Concepts

### 1. SuperQubit
A container that manages multiple child Qubits and can intercept/handle their events.

### 2. Qubit
Individual state manager (equivalent to Cubit), handles a single state type.

### 3. Event Propagation Control
Both parent and child can listen to the same event with conditional execution control.

---

## API Design

### Basic Structure

```dart
class Cart extends SuperQubit {
  Cart() {
    // Parent-level event handler
    on<Load, LoadTriggerEvent>((event, emit) {
      // Handle event at parent level
      print('Parent handling LoadTriggerEvent');
    }, ignoreWhenChildDefines<Load>());
    
    // Cross-Qubit communication
    on<CartItems, ItemAddedEvent>((event, emit) {
      // When item is added, trigger load
      dispatch<Load>(LoadTriggerEvent());
    });
  }
  
  // Access child Qubits
  Load get load => getQubit<Load>();
  CartItems get items => getQubit<CartItems>();
  CartFilter get filter => getQubit<CartFilter>();
}

class Load extends Qubit<LoadState> {
  Load() : super(LoadState.initial());
  
  on<LoadTriggerEvent>((event, emit) {
    emit(LoadState.loading());
    // Fetch data...
    emit(LoadState.loaded(data));
  }, ignoreWhenParentDefines());
}

class CartItems extends Qubit<CartItemsState> {
  CartItems() : super(CartItemsState.empty());
  
  on<ItemAddedEvent>((event, emit) {
    final newItems = [...state.items, event.item];
    emit(state.copyWith(items: newItems));
  });
}

class CartFilter extends Qubit<CartFilterState> {
  CartFilter() : super(CartFilterState.all());
  
  on<FilterChangedEvent>((event, emit) {
    emit(CartFilterState(filter: event.filter));
  });
}
```

### Provider Setup

```dart
QubitProvider<Cart>(
  superQubit: Cart(),
  superStates: [Load(), CartItems(), CartFilter()],
  child: MaterialApp(...)
)
```

---

## Event Handling Flags

### `ignoreWhenChildDefines<T>()`
Used in **parent** handlers. Skips parent handler if the specified child Qubit has defined a handler for this event.

```dart
// In SuperQubit
on<Load, LoadTriggerEvent>((event, emit) {
  // Only runs if Load doesn't have a handler
}, ignoreWhenChildDefines<Load>());
```

### `ignoreWhenParentDefines()`
Used in **child** handlers. Skips child handler if the parent SuperQubit has defined a handler for this event.

```dart
// In Qubit
on<LoadTriggerEvent>((event, emit) {
  // Only runs if parent doesn't have a handler
}, ignoreWhenParentDefines());
```

### No Flag (Default Behavior)
Both parent and child handlers execute in sequence:
1. Child handler executes first
2. Parent handler executes after

```dart
// Both will execute
// In Load
on<LoadTriggerEvent>((event, emit) {
  print('Child handling');
});

// In Cart
on<Load, LoadTriggerEvent>((event, emit) {
  print('Parent handling');
});
// Output: "Child handling" then "Parent handling"
```

---

## Cross-Qubit Communication

### Dispatching Events to Specific Qubits

```dart
class Cart extends SuperQubit {
  Cart() {
    // Listen to CartItems events
    on<CartItems, ItemAddedEvent>((event, emit) {
      // Trigger event in Load Qubit
      dispatch<Load>(LoadTriggerEvent());
      
      // Or dispatch to multiple
      dispatchAll([
        QubitEvent<Load>(LoadTriggerEvent()),
        QubitEvent<CartFilter>(FilterChangedEvent(filter: 'new'))
      ]);
    });
  }
}
```

### Direct Qubit Access

```dart
class Cart extends SuperQubit {
  void addItemAndRefresh(Item item) {
    // Access child Qubits directly
    items.add(ItemAddedEvent(item));
    load.add(LoadTriggerEvent());
  }
  
  Load get load => getQubit<Load>();
  CartItems get items => getQubit<CartItems>();
}
```

### Listening to Child State Changes

```dart
class Cart extends SuperQubit {
  Cart() {
    // Listen to state changes from child Qubits
    listenTo<CartItems>((state) {
      if (state.items.isEmpty) {
        dispatch<Load>(LoadTriggerEvent());
      }
    });
    
    // Listen to multiple
    listenToMultiple<CartItems, CartFilter>((itemsState, filterState) {
      // React to combined state changes
    });
  }
}
```

---

## State Access in UI

### Option 1: Watch Entire SuperQubit
```dart
Widget build(BuildContext context) {
  final cart = context.watch<Cart>();
  final loadState = cart.getState<Load>();
  final itemsState = cart.getState<CartItems>();
  
  return Column(
    children: [
      if (loadState.isLoading) CircularProgressIndicator(),
      ...itemsState.items.map((item) => ItemWidget(item)),
    ],
  );
}
```

### Option 2: Watch Specific Child Qubit
```dart
Widget build(BuildContext context) {
  final loadState = context.watchQubit<Cart, Load>();
  final itemsState = context.watchQubit<Cart, CartItems>();
  
  return Column(
    children: [
      if (loadState.isLoading) CircularProgressIndicator(),
      ...itemsState.items.map((item) => ItemWidget(item)),
    ],
  );
}
```

### Option 3: Selector for Performance
```dart
Widget build(BuildContext context) {
  final isLoading = context.select<Cart, bool>(
    (cart) => cart.getState<Load>().isLoading
  );
  
  return isLoading ? CircularProgressIndicator() : ContentWidget();
}
```

---

## Stream Architecture

### Individual Streams
Each Qubit maintains its own stream:
```dart
class Qubit<State> {
  final _controller = StreamController<State>.broadcast();
  Stream<State> get stream => _controller.stream;
}
```

### Combined Stream in SuperQubit
```dart
class SuperQubit {
  Stream<Map<Type, dynamic>> get stream {
    // Merge all child streams
    return Rx.combineLatestList(
      _qubits.values.map((q) => q.stream)
    ).map((states) {
      return Map.fromIterables(_qubits.keys, states);
    });
  }
  
  // Or get specific stream
  Stream<T> streamOf<T extends Qubit>() {
    return getQubit<T>().stream;
  }
}
```

---

## Implementation Details

### Event Handler Signature

```dart
typedef EventHandler<Event, State> = FutureOr<void> Function(
  Event event,
  Emitter<State> emit,
);

class EventHandlerConfig {
  final bool ignoreWhenParentDefines;
  final Type? ignoreWhenChildDefines;
  
  const EventHandlerConfig({
    this.ignoreWhenParentDefines = false,
    this.ignoreWhenChildDefines,
  });
}
```

### Event Dispatching

```dart
class SuperQubit {
  final Map<Type, Qubit> _qubits = {};
  
  void dispatch<T extends Qubit>(dynamic event) {
    final qubit = getQubit<T>();
    qubit.add(event);
  }
  
  void dispatchAll(List<QubitEvent> events) {
    for (final event in events) {
      dispatch(event.event, target: event.qubitType);
    }
  }
  
  T getQubit<T extends Qubit>() {
    return _qubits[T] as T;
  }
}
```

### Event Routing Logic

```dart
class EventRouter {
  Future<void> routeEvent(dynamic event, Type targetQubit) async {
    final childHandlers = _getChildHandlers(targetQubit, event.runtimeType);
    final parentHandlers = _getParentHandlers(targetQubit, event.runtimeType);
    
    // Check flags
    final shouldRunChild = !_shouldIgnoreChild(childHandlers, parentHandlers);
    final shouldRunParent = !_shouldIgnoreParent(childHandlers, parentHandlers);
    
    // Execute in order
    if (shouldRunChild) {
      await _executeHandlers(childHandlers, event);
    }
    
    if (shouldRunParent) {
      await _executeHandlers(parentHandlers, event);
    }
  }
  
  bool _shouldIgnoreChild(List handlers, List parentHandlers) {
    return handlers.any((h) => 
      h.config.ignoreWhenParentDefines && parentHandlers.isNotEmpty
    );
  }
  
  bool _shouldIgnoreParent(List childHandlers, List handlers) {
    return handlers.any((h) => 
      h.config.ignoreWhenChildDefines != null && childHandlers.isNotEmpty
    );
  }
}
```

---

## Usage Examples

### Example 1: Shopping Cart

```dart
// Events
class LoadCartEvent {}
class AddItemEvent { final Item item; AddItemEvent(this.item); }
class RemoveItemEvent { final String id; RemoveItemEvent(this.id); }
class ApplyFilterEvent { final String filter; ApplyFilterEvent(this.filter); }

// States
class LoadState {
  final bool isLoading;
  final String? error;
  LoadState({this.isLoading = false, this.error});
}

class CartItemsState {
  final List<Item> items;
  CartItemsState({this.items = const []});
}

class CartFilterState {
  final String filter;
  CartFilterState({this.filter = 'all'});
}

// Qubits
class Load extends Qubit<LoadState> {
  Load() : super(LoadState());
  
  on<LoadCartEvent>((event, emit) async {
    emit(LoadState(isLoading: true));
    try {
      // Fetch data
      await Future.delayed(Duration(seconds: 1));
      emit(LoadState(isLoading: false));
    } catch (e) {
      emit(LoadState(isLoading: false, error: e.toString()));
    }
  });
}

class CartItems extends Qubit<CartItemsState> {
  CartItems() : super(CartItemsState());
  
  on<AddItemEvent>((event, emit) {
    emit(CartItemsState(items: [...state.items, event.item]));
  });
  
  on<RemoveItemEvent>((event, emit) {
    emit(CartItemsState(
      items: state.items.where((i) => i.id != event.id).toList()
    ));
  });
}

class CartFilter extends Qubit<CartFilterState> {
  CartFilter() : super(CartFilterState());
  
  on<ApplyFilterEvent>((event, emit) {
    emit(CartFilterState(filter: event.filter));
  });
}

// SuperQubit
class Cart extends SuperQubit {
  Cart() {
    // When items change, check if we need to reload
    listenTo<CartItems>((state) {
      if (state.items.isEmpty) {
        dispatch<Load>(LoadCartEvent());
      }
    });
    
    // Parent can intercept add events for analytics
    on<CartItems, AddItemEvent>((event, emit) {
      print('Analytics: Item added - ${event.item.name}');
      // Child handler will also run (no ignore flag)
    });
  }
  
  Load get load => getQubit<Load>();
  CartItems get items => getQubit<CartItems>();
  CartFilter get filter => getQubit<CartFilter>();
}

// UI
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QubitProvider<Cart>(
      superQubit: Cart(),
      superStates: [Load(), CartItems(), CartFilter()],
      child: CartView(),
    );
  }
}

class CartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<Cart, bool>(
      (cart) => cart.getState<Load>().isLoading
    );
    final items = context.select<Cart, List<Item>>(
      (cart) => cart.getState<CartItems>().items
    );
    
    return Scaffold(
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => ItemTile(items[index]),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<Cart>().items.add(AddItemEvent(Item(...)));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Advantages Over Existing Solutions

### vs. Regular Cubit/Bloc
- ✅ Group related state managers together
- ✅ Easier cross-state communication
- ✅ Single provider for multiple states
- ✅ Hierarchical event handling

### vs. MultiBlocProvider
- ✅ Built-in cross-communication
- ✅ Shared event handling logic
- ✅ Less boilerplate
- ✅ Type-safe state access

### vs. Riverpod
- ✅ More explicit event flow
- ✅ Familiar Cubit/Bloc patterns
- ✅ Better for complex state machines
- ✅ Clearer parent-child relationships

---

## Testing Strategy

### Testing Individual Qubits
```dart
test('Load emits loading state', () {
  final load = Load();
  
  expectLater(
    load.stream,
    emitsInOrder([
      LoadState(isLoading: true),
      LoadState(isLoading: false),
    ]),
  );
  
  load.add(LoadCartEvent());
});
```

### Testing SuperQubit
```dart
test('Cart dispatches load when items empty', () {
  final cart = Cart();
  final load = Load();
  final items = CartItems();
  
  // Setup
  cart.registerQubits([load, items]);
  
  expectLater(
    load.stream,
    emits(LoadState(isLoading: true)),
  );
  
  items.add(RemoveItemEvent('last-item-id'));
});
```

### Testing Event Propagation
```dart
test('ignoreWhenChildDefines prevents parent execution', () {
  final cart = Cart();
  final load = Load();
  
  var parentCalled = false;
  var childCalled = false;
  
  // Both define handlers
  load.on<LoadCartEvent>((event, emit) {
    childCalled = true;
  });
  
  cart.on<Load, LoadCartEvent>((event, emit) {
    parentCalled = true;
  }, ignoreWhenChildDefines<Load>());
  
  cart.dispatch<Load>(LoadCartEvent());
  
  expect(childCalled, true);
  expect(parentCalled, false); // Ignored!
});
```

---

## Open Questions

1. **Async Event Handling**: Should parent wait for child handler to complete?
2. **Error Propagation**: If child throws, should parent handler still run?
3. **DevTools Integration**: How to visualize the state tree?
4. **Hot Reload**: How to preserve state during development?
5. **Performance**: Stream merging overhead with many Qubits?

---

## Next Steps

1. ✅ Design specification complete
2. ⏳ Prototype implementation
3. ⏳ Write comprehensive tests
4. ⏳ Create example app
5. ⏳ Performance benchmarks
6. ⏳ Documentation and tutorials
