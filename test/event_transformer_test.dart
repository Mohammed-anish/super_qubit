import 'dart:async';
import 'package:test/test.dart';
import 'package:super_qubit/super_qubit.dart';

abstract class TestEvent {}

class IncrementEvent extends TestEvent {}

class DelayedIncrementEvent extends TestEvent {
  final int delayMs;
  final int value;
  DelayedIncrementEvent(this.value, {this.delayMs = 10});
}

class TestQubit extends Qubit<TestEvent, int> {
  TestQubit() : super(0);

  void onSequential() {
    on<DelayedIncrementEvent>((event, emit) async {
      await Future.delayed(Duration(milliseconds: event.delayMs));
      emit(state + event.value);
    }, config: EventHandlerConfig(transformer: Transformers.sequential()));
  }

  void onConcurrent() {
    on<DelayedIncrementEvent>((event, emit) async {
      await Future.delayed(Duration(milliseconds: event.delayMs));
      emit(state + event.value);
    }, config: EventHandlerConfig(transformer: Transformers.concurrent()));
  }

  void onRestartable() {
    on<DelayedIncrementEvent>((event, emit) async {
      await Future.delayed(Duration(milliseconds: event.delayMs));
      emit(state + event.value);
    }, config: EventHandlerConfig(transformer: Transformers.restartable()));
  }

  void onDroppable() {
    on<DelayedIncrementEvent>((event, emit) async {
      await Future.delayed(Duration(milliseconds: event.delayMs));
      emit(state + event.value);
    }, config: EventHandlerConfig(transformer: Transformers.droppable()));
  }

  void onDebounce(Duration duration) {
    on<DelayedIncrementEvent>(
      (event, emit) async {
        emit(state + event.value);
      },
      config: EventHandlerConfig(transformer: Transformers.debounce(duration)),
    );
  }

  void onThrottle(Duration duration) {
    on<DelayedIncrementEvent>(
      (event, emit) async {
        emit(state + event.value);
      },
      config: EventHandlerConfig(transformer: Transformers.throttle(duration)),
    );
  }
}

void main() {
  group('Event Transformers', () {
    late TestQubit qubit;

    setUp(() {
      qubit = TestQubit();
    });

    tearDown(() async {
      await qubit.close();
    });

    test('sequential processes events one after another', () async {
      qubit.onSequential();
      qubit.add(DelayedIncrementEvent(1, delayMs: 20));
      qubit.add(DelayedIncrementEvent(2, delayMs: 10));

      // Wait for both to complete: 20 + 10 = 30ms
      await Future.delayed(Duration(milliseconds: 50));
      expect(qubit.state, 3);
    });

    test('concurrent processes events at the same time', () async {
      qubit.onConcurrent();
      qubit.add(DelayedIncrementEvent(1, delayMs: 20)); // Finishes at 20ms
      qubit.add(DelayedIncrementEvent(2, delayMs: 10)); // Finishes at 10ms

      await Future.delayed(Duration(milliseconds: 15));
      expect(qubit.state, 2); // Only second event finished

      await Future.delayed(Duration(milliseconds: 10));
      expect(qubit.state, 3); // Both finished
    });

    test('restartable cancels previous event and processes latest', () async {
      qubit.onRestartable();
      qubit.add(DelayedIncrementEvent(1, delayMs: 20));
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(2, delayMs: 10)); // Restarts

      await Future.delayed(Duration(milliseconds: 25));
      expect(qubit.state, 2); // 1 was cancelled, only 2 should be added
    });

    test('droppable ignores events while processing', () async {
      qubit.onDroppable();
      qubit.add(DelayedIncrementEvent(1, delayMs: 20));
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(2, delayMs: 10)); // Dropped

      await Future.delayed(Duration(milliseconds: 25));
      expect(qubit.state, 1); // 2 was dropped
    });

    test('debounce waits for quiet period', () async {
      qubit.onDebounce(Duration(milliseconds: 30));
      qubit.add(DelayedIncrementEvent(1));
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(2)); // Resets timer
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(3)); // Resets timer

      await Future.delayed(Duration(milliseconds: 20));
      expect(qubit.state, 0); // Not yet

      await Future.delayed(Duration(milliseconds: 20));
      expect(qubit.state, 3); // Finally!
    });

    test('throttle processes first and ignores others for period', () async {
      qubit.onThrottle(Duration(milliseconds: 30));
      qubit.add(DelayedIncrementEvent(1)); // Processes immediately
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(2)); // Ignored
      await Future.delayed(Duration(milliseconds: 10));
      qubit.add(DelayedIncrementEvent(3)); // Ignored

      await Future.delayed(Duration(milliseconds: 40));
      expect(qubit.state, 1);

      qubit.add(DelayedIncrementEvent(4)); // Processes (new period)
      await Future.delayed(
        Duration(milliseconds: 10),
      ); // Give it time to process
      expect(qubit.state, 5);
    });
  });
}
