import 'dart:async';
import 'qubit.dart';
import 'event_handler.dart';

/// A SuperQubit manages multiple child Qubits and can intercept their events.
///
/// SuperQubit provides:
/// - Child Qubit registration and management
/// - Parent-level event handlers with `on<ChildQubit, Event>()`
/// - Cross-Qubit communication via `dispatch<T>(event)`
/// - Listen to child state changes via `listenTo<T>(callback)`
/// - Access child Qubits via `getQubit<T>()`
///
/// Example:
/// ```dart
/// class CartSuperQubit extends SuperQubit {
///   CartSuperQubit() {
///     // Listen to child events
///     on<LoadQubit, LoadEvent>((event, emit) {
///       print('Parent handling load event');
///     }, ignoreWhenChildDefines<LoadQubit>());
///
///     // Cross-Qubit communication
///     listenTo<CartItemsQubit>((state) {
///       if (state.items.isEmpty) {
///         dispatch<LoadQubit>(LoadEvent());
///       }
///     });
///   }
/// }
/// ```
abstract class SuperQubit {
  /// Map of child Qubits by type.
  final Map<Type, BaseQubit> _qubits = {};

  /// Map of parent event handlers.
  /// Key: (ChildQubitType, EventType)
  final Map<_HandlerKey, List<_ParentEventHandlerEntry>> _parentHandlers = {};

  /// Map of state listeners for child Qubits.
  final Map<Type, List<StreamSubscription>> _stateListeners = {};

  /// Whether this SuperQubit has been closed.
  bool _isClosed = false;

  /// Register child Qubits.
  ///
  /// This should be called with the list of child Qubits to manage.
  /// Typically called from QubitProvider.
  void registerQubits(List<BaseQubit> qubits) {
    for (final qubit in qubits) {
      final type = qubit.runtimeType;
      _qubits[type] = qubit;
      qubit.setParent(this);
    }
  }

  /// Register a parent-level event handler for events targeting a specific child Qubit.
  ///
  /// [ChildQubit] is the type of the child Qubit.
  /// [E] is the type of the event, which must inherit from the child Qubit's event type.
  ///
  /// Example:
  /// ```dart
  /// on<LoadQubit, LoadEvent>((event, emit) {
  ///   // Handle event at parent level
  /// }, ignoreWhenChildDefines<LoadQubit>());
  /// ```
  void on<ChildQubit extends BaseQubit, Event>(
    ParentEventHandler<Event, dynamic> handler, {
    EventHandlerConfig? config,
  }) {
    final key = _HandlerKey(ChildQubit, Event);
    if (!_parentHandlers.containsKey(key)) {
      _parentHandlers[key] = [];
    }
    _parentHandlers[key]!.add(
      _ParentEventHandlerEntry(handler, config ?? const EventHandlerConfig()),
    );
  }

  /// Dispatch an event to a specific child Qubit.
  ///
  /// Example:
  /// ```dart
  /// dispatch<LoadQubit, LoadEvent>(LoadEvent());
  /// ```
  Future<void> dispatch<T extends BaseQubit, E>(E event) async {
    final qubit = getQubit<T>();
    qubit.add(event);
  }

  /// Listen to state changes from a specific child Qubit.
  ///
  /// The [callback] will be called whenever the child Qubit's state changes.
  ///
  /// Example:
  /// ```dart
  /// listenTo<CartItemsQubit>((state) {
  ///   if (state.items.isEmpty) {
  ///     dispatch<LoadQubit, LoadEvent>(LoadEvent());
  ///   }
  /// });
  /// ```
  void listenTo<T extends BaseQubit>(void Function(dynamic state) callback) {
    final qubit = getQubit<T>();
    final subscription = qubit.stream.listen(callback);

    if (!_stateListeners.containsKey(T)) {
      _stateListeners[T] = [];
    }
    _stateListeners[T]!.add(subscription);
  }

  /// Get a child Qubit by type.
  ///
  /// Throws [StateError] if the Qubit is not registered.
  ///
  /// Example:
  /// ```dart
  /// final loadQubit = getQubit<LoadQubit>();
  /// final currentState = loadQubit.state;
  /// ```
  T getQubit<T extends BaseQubit>() {
    final qubit = _qubits[T];
    if (qubit == null) {
      throw StateError('Qubit of type $T is not registered');
    }
    return qubit as T;
  }

  /// Get the state of a specific child Qubit.
  ///
  /// This is a convenience method equivalent to `getQubit<T>().state`.
  S getState<T extends BaseQubit, S>() {
    return getQubit<T>().state;
  }

  /// Check if parent has a handler for a specific child Qubit and event type.
  /// Used internally by child Qubits.
  bool hasParentHandlerForChild(Type childType, Type eventType) {
    final key = _HandlerKey(childType, eventType);
    return _parentHandlers.containsKey(key);
  }

  /// Handle an event from a child Qubit.
  /// Used internally by child Qubits.
  Future<void> handleChildEvent(Type childType, dynamic event) async {
    final eventType = event.runtimeType;
    final key = _HandlerKey(childType, eventType);
    final handlers = _parentHandlers[key];

    if (handlers != null) {
      final childQubit = _qubits[childType];
      final childHasHandler = childQubit?.hasHandler(eventType) ?? false;

      for (final entry in handlers) {
        // Check if we should skip this parent handler
        if (entry.config.ignoreWhenChildDefines != null && childHasHandler) {
          continue; // Skip parent handler
        }

        // Execute parent handler using dynamic invocation
        final result = entry.handler(event, childQubit!.emitter);
        if (result is Future) {
          await result;
        }
      }
    }
  }

  /// Close the SuperQubit and all child Qubits.
  ///
  /// This will clean up all resources and close all child Qubits.
  Future<void> close() async {
    if (_isClosed) return;

    _isClosed = true;

    // Cancel all state listeners
    for (final subscriptions in _stateListeners.values) {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    _stateListeners.clear();

    // Close all child Qubits
    for (final qubit in _qubits.values) {
      await qubit.close();
    }
    _qubits.clear();
  }
}

/// Internal key for parent event handlers.
class _HandlerKey {
  final Type childType;
  final Type eventType;

  _HandlerKey(this.childType, this.eventType);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HandlerKey &&
          runtimeType == other.runtimeType &&
          childType == other.childType &&
          eventType == other.eventType;

  @override
  int get hashCode => childType.hashCode ^ eventType.hashCode;
}

/// Internal class to store parent event handler information.
class _ParentEventHandlerEntry {
  final Function handler;
  final EventHandlerConfig config;

  _ParentEventHandlerEntry(this.handler, this.config);
}
