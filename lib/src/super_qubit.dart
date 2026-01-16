import 'dart:async';
import 'qubit.dart';
import 'event_handler.dart';
import 'devtools.dart';

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
///   CartSuperQubit() {
///     // Listen to child events
///     on<LoadQubit, LoadEvent>((event, emit) {
///       print('Parent handling load event');
///     }, ignoreWhenChildDefines<LoadQubit>());
///
///     // Cross-Qubit communication
///     listenTo<CartItemsQubit>((state) {
///       if (state.items.isEmpty) {
///         dispatch<LoadQubit, LoadEvent>(LoadEvent());
///       }
///     });
///   }
/// }
/// ```
abstract class SuperQubit {
  /// Map of child Qubits by type.
  final Map<Type, BaseQubit> _qubits = {};

  SuperQubit() {
    if (SuperQubitDevTools.isEnabled) {
      SuperQubitDevTools.onSuperQubitCreated(this);
    }
  }

  /// Map of parent event handlers.
  /// Key: (ChildQubitType, EventType)
  final Map<_HandlerKey, List<_ParentEventHandlerEntry>> _parentHandlers = {};

  /// Map of state listeners for child Qubits.
  final Map<Type, List<StreamSubscription>> _stateListeners = {};

  /// Controllers for transformed parent event streams.
  final Map<_ParentEventHandlerEntry, StreamController<dynamic>>
  _parentEventStreams = {};

  /// Pending actions to be executed once child Qubits are registered.
  final List<void Function()> _pendingActions = [];

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

      if (SuperQubitDevTools.isEnabled) {
        SuperQubitDevTools.onQubitRegistered(this, qubit);
      }
    }

    // Execute any pending actions that were called in the constructor
    for (final action in _pendingActions) {
      action();
    }
    _pendingActions.clear();
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
    final actualConfig = config ?? const EventHandlerConfig();
    final entry = _ParentEventHandlerEntry(handler, actualConfig);
    _parentHandlers[key]!.add(entry);

    if (actualConfig.transformer != null) {
      final controller = StreamController<dynamic>.broadcast();
      _parentEventStreams[entry] = controller;

      final transformer = actualConfig.transformer!;
      final stream = transformer(
        controller.stream,
        (event) => _runParentHandler(entry, ChildQubit, event),
      );
      stream.listen(null); // Just start the stream
    }
  }

  Stream<dynamic> _runParentHandler(
    _ParentEventHandlerEntry entry,
    Type childType,
    dynamic event,
  ) {
    final controller = StreamController<dynamic>();
    final childQubit = _qubits[childType];
    final emitter = childQubit!.emitter; // This actually creates a new Emitter

    controller.onCancel = () {
      emitter.close();
    };

    Future.sync(() => entry.handler(event, emitter))
        .then((_) {
          if (!controller.isClosed) controller.close();
        })
        .catchError((Object e, StackTrace s) {
          if (!controller.isClosed) {
            controller.addError(e, s);
            controller.close();
          }
        });

    return controller.stream;
  }

  Future<void> _executeParentHandler(
    _ParentEventHandlerEntry entry,
    Type childType,
    dynamic event,
  ) async {
    final childQubit = _qubits[childType];
    final result = entry.handler(event, childQubit!.emitter);
    if (result is Future) await result;
  }

  /// Dispatch an event to a specific child Qubit.
  ///
  /// Example:
  /// ```dart
  /// dispatch<LoadQubit, LoadEvent>(LoadEvent());
  /// ```
  Future<void> dispatch<T extends BaseQubit, E>(E event) async {
    if (!_qubits.containsKey(T)) {
      final completer = Completer<void>();
      _pendingActions.add(() async {
        try {
          final qubit = getQubit<T>();
          await qubit.add(event);
          completer.complete();
        } catch (e, s) {
          completer.completeError(e, s);
        }
      });
      return completer.future;
    }
    final qubit = getQubit<T>();
    return qubit.add(event);
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
    if (!_qubits.containsKey(T)) {
      _pendingActions.add(() => listenTo<T>(callback));
      return;
    }
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

        if (entry.config.transformer != null) {
          _parentEventStreams[entry]?.add(event);
        } else {
          await _executeParentHandler(entry, childType, event);
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

    // Close all parent event streams
    for (final controller in _parentEventStreams.values) {
      await controller.close();
    }
    _parentEventStreams.clear();
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
