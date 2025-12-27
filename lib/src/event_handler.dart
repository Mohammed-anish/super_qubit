import 'dart:async';

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

  const EventHandlerConfig({
    this.ignoreWhenParentDefines = false,
    this.ignoreWhenChildDefines,
  });
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

  Emitter(this._emit);

  /// Emit a new state.
  void call(State state) => _emit(state);
}

/// Internal class to store event handler information.
/// Uses dynamic for Event type to avoid casting issues.
class EventHandlerEntry<State> {
  final Function handler;
  final EventHandlerConfig config;

  EventHandlerEntry(this.handler, this.config);
}
