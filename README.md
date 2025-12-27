# SuperQubit

A hierarchical state management library for Flutter with **SuperQubit** and **Qubit** support.

## Features

✅ **Zero External Dependencies** - Uses only core Dart and Flutter SDK  
✅ **Hierarchical State Management** - One SuperQubit manages multiple Qubits  
✅ **Flexible Event Handling** - Both parent and child can handle events  
✅ **Cross-Qubit Communication** - Easy communication between Qubits via `dispatch` and `listenTo`  
✅ **Event Propagation Control** - Use flags to control when parent/child handlers execute  
✅ **Type-Safe** - Full generic type support  
✅ **Stream-Based** - Native Dart streams for state changes  

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  super_qubit:
    path: ../super_qubit  # or your path
```

## Quick Start

### 1. Define States and Events

```dart
// States
class LoadState {
  final bool isLoading;
  const LoadState({this.isLoading = false});
}

class CartItemsState {
  final List<Item> items;
  const CartItemsState({this.items = const []});
}

// Events
class LoadEvent {}
class AddItemEvent {
  final Item item;
  AddItemEvent(this.item);
}
```

### 2. Create Qubits

```dart
import 'package:super_qubit/super_qubit.dart';

class LoadQubit extends Qubit<LoadState> {
  LoadQubit() : super(LoadState()) {
    on<LoadEvent>((event, emit) async {
      emit(LoadState(isLoading: true));
      // Fetch data...
      emit(LoadState(isLoading: false));
    });
  }
}

class CartItemsQubit extends Qubit<CartItemsState> {
  CartItemsQubit() : super(CartItemsState()) {
    on<AddItemEvent>((event, emit) {
      final newItems = [...state.items, event.item];
      emit(CartItemsState(items: newItems));
    });
  }
}
```

### 3. Create SuperQubit

```dart
class CartSuperQubit extends SuperQubit {
  CartSuperQubit() {
    // Cross-Qubit communication
    listenTo<CartItemsQubit>((state) {
      if (state.items.isEmpty) {
        dispatch<LoadQubit>(LoadEvent());
      }
    });
    
    // Parent-level event handler
    on<CartItemsQubit, AddItemEvent>((event) async {
      print('Item added: ${event.item.name}');
    });
  }
  
  // Convenience getters
  LoadQubit get load => getQubit<LoadQubit>();
  CartItemsQubit get items => getQubit<CartItemsQubit>();
}
```

### 4. Provide to Widget Tree

```dart
void main() {
  runApp(
    QubitProvider<CartSuperQubit>(
      superQubit: CartSuperQubit(),
      superStates: [
        LoadQubit(),
        CartItemsQubit(),
      ],
      child: MyApp(),
    ),
  );
}
```

### 5. Use in Widgets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access SuperQubit
    final cart = context.read<CartSuperQubit>();
    
    // Listen to specific Qubit state
    return StreamBuilder<CartItemsState>(
      stream: cart.items.stream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? CartItemsState();
        
        return Column(
          children: [
            Text('Items: ${state.items.length}'),
            ElevatedButton(
              onPressed: () {
                cart.items.add(AddItemEvent(Item('New Item')));
              },
              child: Text('Add Item'),
            ),
          ],
        );
      },
    );
  }
}
```

## Core Concepts

### Event Propagation Flags

Control when parent and child handlers execute:

#### `ignoreWhenParentDefines()`
Use in **child** Qubit to skip execution if parent has a handler:

```dart
class LoadQubit extends Qubit<LoadState> {
  LoadQubit() : super(LoadState()) {
    on<LoadEvent>((event, emit) {
      // Only runs if parent doesn't handle it
    }, ignoreWhenParentDefines());
  }
}
```

#### `ignoreWhenChildDefines<T>()`
Use in **parent** SuperQubit to skip execution if child has a handler:

```dart
class CartSuperQubit extends SuperQubit {
  CartSuperQubit() {
    on<LoadQubit, LoadEvent>((event) async {
      // Only runs if LoadQubit doesn't handle it
    }, ignoreWhenChildDefines<LoadQubit>());
  }
}
```

#### Default Behavior (No Flag)
Both parent and child execute in sequence:
1. Child handler executes first
2. Parent handler executes after

### Cross-Qubit Communication

#### `dispatch<T>(event)`
Send an event to a specific child Qubit:

```dart
dispatch<LoadQubit>(LoadEvent());
```

#### `listenTo<T>(callback)`
Listen to state changes from a child Qubit:

```dart
listenTo<CartItemsQubit>((state) {
  if (state.items.isEmpty) {
    dispatch<LoadQubit>(LoadEvent());
  }
});
```

### Accessing Child Qubits

```dart
// Get Qubit instance
final loadQubit = superQubit.getQubit<LoadQubit>();

// Get current state
final loadState = superQubit.getState<LoadQubit, LoadState>();

// Or use convenience getters
LoadQubit get load => getQubit<LoadQubit>();
```

## Example App

See the `example/` directory for a complete shopping cart application demonstrating:
- ✅ Multiple Qubits (Load, CartItems, CartFilter)
- ✅ SuperQubit orchestration
- ✅ Cross-Qubit communication
- ✅ Parent and child event handlers
- ✅ Event propagation flags
- ✅ UI integration with StreamBuilder

Run the example:

```bash
cd example
flutter pub get
flutter run -d chrome  # or macos, ios, android
```

## API Reference

### Qubit<State>

Base class for state management.

**Methods:**
- `on<Event>(handler, [config])` - Register event handler
- `add(event)` - Add event to be processed
- `close()` - Close and clean up

**Properties:**
- `state` - Current state
- `stream` - Stream of state changes
- `isClosed` - Whether Qubit is closed

### SuperQubit

Container for managing multiple child Qubits.

**Methods:**
- `registerQubits(qubits)` - Register child Qubits
- `on<ChildQubit, Event>(handler, [config])` - Register parent event handler
- `dispatch<T>(event)` - Dispatch event to child Qubit
- `listenTo<T>(callback)` - Listen to child state changes
- `getQubit<T>()` - Get child Qubit by type
- `getState<T, S>()` - Get child Qubit state
- `close()` - Close SuperQubit and all children

### QubitProvider<T>

Widget that provides SuperQubit to descendants.

**Parameters:**
- `superQubit` - SuperQubit instance
- `superStates` - List of child Qubits
- `child` - Widget tree

**Static Methods:**
- `QubitProvider.of<T>(context)` - Get SuperQubit from context

### Context Extensions

- `context.read<T>()` - Get SuperQubit without listening
- `context.watch<T>()` - Get SuperQubit and listen
- `context.watchQubit<T, Q, S>()` - Watch specific child Qubit
- `context.select<T, R>(selector)` - Select specific value

## Advantages

### vs. Regular Cubit/Bloc
- ✅ Group related state managers together
- ✅ Built-in cross-communication
- ✅ Single provider for multiple states
- ✅ Hierarchical event handling

### vs. MultiBlocProvider
- ✅ Less boilerplate
- ✅ Type-safe cross-communication
- ✅ Shared event handling logic

### vs. Riverpod
- ✅ More explicit event flow
- ✅ Familiar Cubit/Bloc patterns
- ✅ Better for complex state machines

## License

MIT License

## Contributing

Contributions welcome! Please open an issue or PR.
