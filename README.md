# SuperQubit

A hierarchical state management library for Flutter with **SuperQubit** and **Qubit** support.

## Features

- ✅ **Minimal Dependencies** - Uses only Flutter SDK and the `nested` package
- ✅ **Hierarchical State Management** - One SuperQubit manages multiple Qubits
- ✅ **Flexible Event Handling** - Both parent and child can handle events
- ✅ **Cross-Qubit Communication** - Easy communication between Qubits via `dispatch` and `listenTo`
- ✅ **Event Propagation Control** - Use flags to control when parent/child handlers execute
- ✅ **Type-Safe** - Full generic type support
- ✅ **Stream-Based** - Native Dart streams for state changes
- ✅ **DevTools Integration** - Inspect Qubit hierarchy, events, and states directly in Flutter DevTools

## Why This Exists

As Flutter applications grow, managing multiple related pieces of state becomes complex. A single feature often requires **multiple states working together** - for example, a shopping cart needs loading state, items state, and filter state all coordinated under one domain.

Traditional approaches require you to:

- **Scatter related states** across multiple providers in the widget tree
- **Manually coordinate** state updates between separate managers
- **Write boilerplate** to enable communication between sibling state managers
- **Nest multiple providers** creating deep widget hierarchies

SuperQubit solves these challenges by introducing a hierarchical layer above individual state managers (Qubits). It allows you to:

- **Group multiple states** under a single feature domain (one SuperQubit manages many Qubits)
- **Coordinate automatically** with built-in communication via `dispatch` and `listenTo`
- **Handle events flexibly** at both parent and child levels with propagation control
- **Use one provider** for an entire feature instead of multiple nested providers

This makes it ideal for complex features like shopping carts, multi-step forms, or dashboards where multiple states need to work together seamlessly as a cohesive unit.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  super_qubit: ^0.1.0
```

Then run:

```bash
flutter pub get
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

// Define Event base class
abstract class LoadEventBase {}
class LoadEvent extends LoadEventBase {}

abstract class CartItemsEventBase {}
class AddItemEvent extends CartItemsEventBase {
  final Item item;
  AddItemEvent(this.item);
}

class LoadQubit extends Qubit<LoadEventBase, LoadState> {
  LoadQubit() : super(const LoadState()) {
    on<LoadEvent>((event, emit) async {
      emit(const LoadState(isLoading: true));
      // Fetch data...
      emit(const LoadState(isLoading: false));
    });
  }
}

class CartItemsQubit extends Qubit<CartItemsEventBase, CartItemsState> {
  CartItemsQubit() : super(const CartItemsState()) {
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
  @override
  void init() {
    // Cross-Qubit communication
    listenTo<CartItemsQubit>((state) {
      if (state.items.isEmpty) {
        dispatch<LoadQubit, LoadEvent>(LoadEvent());
      }
    });

    // Parent-level event handler
    on<CartItemsQubit, AddItemEvent>((event, emit) async {
      // Handle at parent level (e.g., analytics)
      // Child handler will also execute if not using ignoreWhenParentDefines
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
    SuperQubitProvider<CartSuperQubit>(
      superQubit: CartSuperQubit(),
      qubits: [
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
    // Option 1: Using context extensions
    final cart = context.readSuper<CartSuperQubit>();

    return StreamBuilder<CartItemsState>(
      stream: cart.items.stream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const CartItemsState();

        return Column(
          children: [
            Text('Items: ${state.items.length}'),
            ElevatedButton(
              onPressed: () {
                cart.items.add(AddItemEvent(Item('New Item')));
              },
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }
}

// Option 2: Using QubitBuilder (recommended)
class MyWidgetWithBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QubitBuilder<CartItemsQubit, CartItemsState>(
      superQubitType: CartSuperQubit,
      builder: (context, state) {
        return Column(
          children: [
            Text('Items: ${state.items.length}'),
            ElevatedButton(
              onPressed: () {
                context
                    .read<CartSuperQubit, CartItemsQubit>()
                    .add(AddItemEvent(Item('New Item')));
              },
              child: const Text('Add Item'),
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
class LoadQubit extends Qubit<LoadEventBase, LoadState> {
  LoadQubit() : super(const LoadState()) {
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
  @override
  void init() {
    on<LoadQubit, LoadEvent>((event, emit) async {
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

#### `dispatch<T, E>(event)`
Send an event to a specific child Qubit:

```dart
dispatch<LoadQubit, LoadEvent>(LoadEvent());
```

#### `listenTo<T>(callback)`
Listen to state changes from a child Qubit:

```dart
listenTo<CartItemsQubit>((state) {
  if (state.items.isEmpty) {
    dispatch<LoadQubit, LoadEvent>(LoadEvent());
  }
});
```

#### Internal Communication
You can call `listenTo` or `dispatch` directly from a **Child Qubit** constructor. These calls are automatically queued and executed once the Qubit is registered with its parent `SuperQubit`.

```dart
class ProfileQubit extends Qubit<UserEvent, ProfileState> {
  ProfileQubit() : super(const ProfileState()) {
    // Safely listen to sibling Qubits in the constructor
    listenTo<AuthQubit>((authState) {
      if (!authState.isLoggedIn) {
        add(ClearProfileEvent());
      }
    });

    // Safely dispatch to sibling Qubits in the constructor
    dispatch<LoadQubit, RefreshEvent>(RefreshEvent());
  }
}
```

### Event Transformers

Control how events are processed (e.g., debouncing search or throttling clicks).

```dart
on<SearchEvent>(
  (event, emit) async {
    // ... search logic ...
  },
  config: EventHandlerConfig(
    transformer: Transformers.debounce(const Duration(milliseconds: 300)),
  ),
);
```

#### Built-in Transformers:
- `Transformers.sequential()`: Processes events one by one (default).
- `Transformers.concurrent()`: Processes multiple events at the same time.
- `Transformers.restartable()`: Cancels previous execution and starts the newest one.
- `Transformers.droppable()`: Ignores new events while an event is being processed.
- `Transformers.debounce(Duration)`: Waits for a quiet period before processing.
- `Transformers.throttle(Duration)`: Processes the first event and ignores others for a period.

### Accessing Child Qubits

```dart
// Get Qubit instance
final loadQubit = superQubit.getQubit<LoadQubit>();

// Get current state
final loadState = superQubit.getState<LoadQubit, LoadState>();

// Or use convenience getters
LoadQubit get load => getQubit<LoadQubit>();
```

## DevTools Integration
SuperQubit comes with a custom DevTools extension to help you debug your application. It allows you to:
- **Inspect Hierarchy**: View all registered SuperQubits and their child Qubits.
- **Track Events**: Real-time log of all events dispatched to specific Qubits.
- **Monitor State**: View state changes as they happen.

### Enabling DevTools
Calls to `SuperQubitDevTools.enable()` should be made in your `main()` function. It is recommended to wrap this in a `kDebugMode` check to ensure it only runs during development.

```dart
import 'package:flutter/foundation.dart';
import 'package:super_qubit/super_qubit.dart';

void main() {
  if (kDebugMode) {
    SuperQubitDevTools.enable();
  }
  runApp(const MyApp());
}
```

Once enabled, open Flutter DevTools and look for the **"SuperQubit"** tab.

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

### Qubit<Event, State>

Base class for state management.

**Type Parameters:**
- `Event` - Base type for events this Qubit handles
- `State` - Type of state this Qubit manages

**Methods:**
- `on<E extends Event>(handler, {config})` - Register event handler
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
- `dispatch<T, E>(event)` - Dispatch event to child Qubit
- `listenTo<T>(callback)` - Listen to child state changes
- `getQubit<T>()` - Get child Qubit by type
- `getState<T, S>()` - Get child Qubit state
- `close()` - Close SuperQubit and all children

### SuperQubitProvider<T>

Widget that provides SuperQubit to descendants.

**Parameters:**
- `superQubit` - SuperQubit instance
- `qubits` - List of child Qubits
- `child` - Widget tree

**Static Methods:**
- `SuperQubitProvider.of<T>(context)` - Get SuperQubit from context

### MultiSuperQubitProvider

Widget that provides multiple SuperQubits to descendants.

Convenience widget built on the `nested` package that nests multiple SuperQubitProviders cleanly without deep indentation.

**Example:**
```dart
MultiSuperQubitProvider(
  providers: [
    SuperQubitProvider<CartSuperQubit>(
      superQubit: CartSuperQubit(),
      qubits: [LoadQubit(), CartItemsQubit()],
    ),
    SuperQubitProvider<UserSuperQubit>(
      superQubit: UserSuperQubit(),
      qubits: [AuthQubit(), ProfileQubit()],
    ),
    SuperQubitProvider<SettingsSuperQubit>(
      superQubit: SettingsSuperQubit(),
      qubits: [ThemeQubit()],
    ),
  ],
  child: MyApp(),
)
```

**Parameters:**
- `providers` - List of SuperQubitProvider instances
- `child` - Widget tree

### Context Extensions

**For SuperQubit access:**
- `context.readSuper<T>()` - Get SuperQubit without listening
- `context.watchSuper<T>()` - Get SuperQubit and listen

**For child Qubit access:**
- `context.read<T, Q>()` - Get child Qubit without listening
- `context.watch<T, Q>()` - Get child Qubit and listen
- `context.watchState<T, Q, S>()` - Watch specific child Qubit state
- `context.select<T, Q, S, R>(selector)` - Select specific value from state

## License

MIT License

## Contributing

Contributions welcome! Please open an issue or PR.
