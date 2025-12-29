import 'dart:async';
import 'event_handler.dart';

/// Non-generic base class for Qubits to allow unified management.
abstract class BaseQubit {
  /// The current state.
  dynamic get state;

  /// Stream of state changes.
  Stream<dynamic> get stream;

  /// Whether this Qubit has been closed.
  bool get isClosed;

  /// Add an event to be processed.
  Future<void> add(dynamic event);

  /// Dispatch an event to another sibling Qubit via parent.
  Future<void> dispatch<T extends BaseQubit, E>(E event);

  /// Listen to state changes from another sibling Qubit via parent.
  void listenTo<T extends BaseQubit>(void Function(dynamic state) callback);

  /// Close the Qubit.
  Future<void> close();

  /// Internal methods for event routing.
  bool hasHandler(Type eventType);
  void setParent(dynamic parent);
  Emitter<dynamic> get emitter;
}

/// Base class for state management with event handling.
///
/// A [Qubit] manages a single state of type [State] and responds to events of type [Event].
/// Uses native Dart streams for state changes.
///
/// Example:
/// ```dart
/// abstract class MyEvent {}
/// class IncrementEvent extends MyEvent {}
///
/// class CounterQubit extends Qubit<MyEvent, int> {
///   CounterQubit() : super(0) {
///     on<IncrementEvent>((event, emit) => emit(state + 1));
///   }
/// }
/// ```
abstract class Qubit<Event, State> implements BaseQubit {
  /// The current state.
  State _state;

  /// Stream controller for state changes.
  late final StreamController<State> _stateController;

  /// Map of event handlers.
  final Map<Type, List<EventHandlerEntry<State>>> _eventHandlers = {};

  /// Whether this Qubit has been closed.
  bool _isClosed = false;

  /// Reference to parent SuperQubit if this is a child.
  dynamic _parent;

  /// Creates a [Qubit] with the given initial [state].
  Qubit(State initialState) : _state = initialState {
    _stateController = StreamController<State>.broadcast(
      onListen: () {
        // Emit current state to new listeners
        if (!_isClosed) {
          _stateController.add(_state);
        }
      },
    );
  }

  /// The current state.
  @override
  State get state => _state;

  /// Stream of state changes.
  ///
  /// This is a broadcast stream that emits the current state immediately
  /// to new listeners and all subsequent state changes.
  @override
  Stream<State> get stream => _stateController.stream;

  /// Whether this Qubit has been closed.
  @override
  bool get isClosed => _isClosed;

  /// Register an event handler for events of type [E] which must inherit from [Event].
  ///
  /// The [handler] will be called when an event of type [E] is added.
  /// Optionally provide a [config] to control event propagation behavior.
  void on<E extends Event>(
    EventHandler<E, State> handler, [
    EventHandlerConfig config = const EventHandlerConfig(),
  ]) {
    final eventType = E;
    if (!_eventHandlers.containsKey(eventType)) {
      _eventHandlers[eventType] = [];
    }
    _eventHandlers[eventType]!.add(EventHandlerEntry<State>(handler, config));
  }

  @override
  Future<void> add(dynamic event) async {
    if (_isClosed) {
      throw StateError('Cannot add event after Qubit is closed');
    }

    final Event typedEvent;
    try {
      typedEvent = event as Event;
    } catch (_) {
      throw ArgumentError(
        'Event of type ${event.runtimeType} is not a valid $Event for this Qubit',
      );
    }

    final eventType = typedEvent.runtimeType;

    // Execute handlers
    final handlers = _eventHandlers[eventType];
    if (handlers != null) {
      for (final entry in handlers) {
        // Check if we should skip this handler
        final isIgnoredByParent =
            entry.config.ignoreWhenParentDefines &&
            _hasParentHandler(eventType);
        if (isIgnoredByParent) continue;

        final result = entry.handler(typedEvent, Emitter<State>(_emit));
        if (result is Future) await result;
      }
    }

    // Notify parent
    if (_parent != null) {
      await _parent.handleChildEvent(runtimeType, typedEvent);
    }
  }

  bool _hasParentHandler(Type eventType) {
    if (_parent == null) return false;
    return _parent.hasParentHandlerForChild(runtimeType, eventType);
  }

  @override
  Future<void> dispatch<T extends BaseQubit, E>(E event) async {
    if (_parent == null) {
      throw StateError('Cannot dispatch to sibling: Qubit has no parent');
    }
    await _parent.dispatch<T, E>(event);
  }

  @override
  void listenTo<T extends BaseQubit>(void Function(dynamic state) callback) {
    if (_parent == null) {
      throw StateError('Cannot listen to sibling: Qubit has no parent');
    }
    _parent.listenTo<T>(callback);
  }

  /// The emitter used to emit new states.
  @override
  Emitter<State> get emitter => Emitter<State>(_emit);

  /// Emit a new state.
  void _emit(State newState) {
    if (_isClosed) {
      throw StateError('Cannot emit state after Qubit is closed');
    }

    _state = newState;
    _stateController.add(newState);
  }

  /// Set the parent SuperQubit.
  /// Used internally by SuperQubit.
  @override
  void setParent(dynamic parent) {
    _parent = parent;
  }

  @override
  bool hasHandler(Type eventType) {
    return _eventHandlers.containsKey(eventType);
  }

  /// Close the Qubit and clean up resources.
  ///
  /// After calling this, the Qubit can no longer be used.
  @override
  Future<void> close() async {
    if (_isClosed) return;

    _isClosed = true;
    await _stateController.close();
  }
}
