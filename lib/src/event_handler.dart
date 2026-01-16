import 'dart:async';

/// Signature for event mappers used in transformers.
typedef EventMapper<Event> = Stream<dynamic> Function(Event event);

/// Signature for event transformers.
typedef EventTransformer<Event> =
    Stream<dynamic> Function(Stream<Event> events, EventMapper<Event> mapper);

/// Signature for event handlers.
///
/// [event] is the event being handled.
/// [emit] is the emitter used to emit new states.
typedef EventHandler<Event, State> =
    FutureOr<void> Function(Event event, Emitter<State> emit);

/// Signature for parent-level event handlers.
/// These handlers take the event and an emitter to allow modifying the child's state.
typedef ParentEventHandler<Event, State> =
    FutureOr<void> Function(Event event, Emitter<State> emit);

/// Configuration for event handlers.
class EventHandlerConfig {
  /// Whether to ignore this handler when parent defines a handler for the same event.
  final bool ignoreWhenParentDefines;

  /// The child Qubit type to check. If specified, ignore this parent handler
  /// when the specified child Qubit defines a handler for the same event.
  final Type? ignoreWhenChildDefines;

  /// The transformer to use for this event handler.
  final EventTransformer<dynamic>? transformer;

  const EventHandlerConfig({
    this.ignoreWhenParentDefines = false,
    this.ignoreWhenChildDefines,
    this.transformer,
  });

  /// Creates a copy of this config with a transformer.
  EventHandlerConfig withTransformer<E>(EventTransformer<E> transformer) {
    return EventHandlerConfig(
      ignoreWhenParentDefines: ignoreWhenParentDefines,
      ignoreWhenChildDefines: ignoreWhenChildDefines,
      transformer: (events, mapper) {
        return transformer(events.cast<E>(), (e) => mapper(e));
      },
    );
  }
}

/// Creates a configuration that ignores the handler when parent defines one.
///
/// Use this in child Qubit event handlers to skip execution if the parent
/// SuperQubit has defined a handler for the same event.
EventHandlerConfig ignoreWhenParentDefines() {
  return const EventHandlerConfig(ignoreWhenParentDefines: true);
}

/// Creates a configuration that ignores the handler when the specified child defines one.
///
/// Use this in parent SuperQubit event handlers to skip execution if the specified
/// child Qubit has defined a handler for the same event.
///
/// Example:
/// ```dart
/// on<LoadQubit, LoadEvent>((event, emit) {
///   // This won't run if LoadQubit has a handler for LoadEvent
/// }, ignoreWhenChildDefines<LoadQubit>());
/// ```
EventHandlerConfig ignoreWhenChildDefines<T>() {
  return EventHandlerConfig(ignoreWhenChildDefines: T);
}

/// Emitter for emitting new states.
///
/// This is passed to event handlers to allow them to emit new states.
class Emitter<State> {
  final void Function(State) _emit;
  bool _isClosed = false;

  Emitter(this._emit);

  /// Emit a new state.
  void call(State state) {
    if (_isClosed) return;
    _emit(state);
  }

  /// Closes the emitter, preventing further state emissions.
  void close() => _isClosed = true;

  /// Whether the emitter is closed.
  bool get isClosed => _isClosed;
}

/// Internal class to store event handler information.
/// Uses dynamic for Event type to avoid casting issues.
class EventHandlerEntry<State> {
  final Function handler;
  final EventHandlerConfig config;

  EventHandlerEntry(this.handler, this.config);
}

/// Built-in event transformers.
class Transformers {
  /// Processes events one at a time (sequential).
  static EventTransformer<E> sequential<E>() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  /// Processes events concurrently.
  static EventTransformer<E> concurrent<E>() {
    return (events, mapper) => events.flatMap(mapper);
  }

  /// Processes only the latest event, cancelling previous ones.
  static EventTransformer<E> restartable<E>() {
    return (events, mapper) => events.switchMap(mapper);
  }

  /// Drops events that occur while an event is being processed.
  static EventTransformer<E> droppable<E>() {
    return (events, mapper) => events.exhaustMap(mapper);
  }

  /// Debounces events for the given [duration].
  static EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  /// Throttles events for the given [duration].
  static EventTransformer<E> throttle<E>(Duration duration) {
    return (events, mapper) => events.throttle(duration).switchMap(mapper);
  }
}

/// Extension to provide common stream transformations if not using stream_transform package.
extension _StreamTransformerExtension<T> on Stream<T> {
  Stream<R> flatMap<R>(Stream<R> Function(T) mapper) {
    final controller = StreamController<R>.broadcast();
    listen(
      (event) {
        mapper(event).listen(controller.add, onError: controller.addError);
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return controller.stream;
  }

  Stream<R> switchMap<R>(Stream<R> Function(T) mapper) {
    StreamSubscription<R>? subscription;
    final controller = StreamController<R>.broadcast();
    listen(
      (event) {
        subscription?.cancel();
        subscription = mapper(
          event,
        ).listen(controller.add, onError: controller.addError);
      },
      onError: controller.addError,
      onDone: () {
        subscription?.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  Stream<R> exhaustMap<R>(Stream<R> Function(T) mapper) {
    bool isProcessing = false;
    final controller = StreamController<R>.broadcast();
    listen(
      (event) {
        if (!isProcessing) {
          isProcessing = true;
          mapper(event).listen(
            controller.add,
            onError: controller.addError,
            onDone: () => isProcessing = false,
          );
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return controller.stream;
  }

  Stream<T> debounce(Duration duration) {
    Timer? timer;
    final controller = StreamController<T>.broadcast();
    listen(
      (event) {
        timer?.cancel();
        timer = Timer(duration, () => controller.add(event));
      },
      onError: controller.addError,
      onDone: () {
        timer?.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  Stream<T> throttle(Duration duration) {
    bool isThrottled = false;
    final controller = StreamController<T>.broadcast();
    listen(
      (event) {
        if (!isThrottled) {
          isThrottled = true;
          controller.add(event);
          Timer(duration, () => isThrottled = false);
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return controller.stream;
  }
}
