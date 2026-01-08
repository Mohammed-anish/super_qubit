import 'dart:developer' as developer;
import 'qubit.dart';
import 'super_qubit.dart';

/// DevTools integration for SuperQubit.
///
/// Use [SuperQubitDevTools.enable()] to start logging events to the Dart VM Service.
/// This allows external tools (like Flutter DevTools) to inspect the state and events.
class SuperQubitDevTools {
  static bool _enabled = false;

  /// Enable DevTools integration.
  ///
  /// This should be called in your main function, preferably only in debug mode.
  /// ```dart
  /// void main() {
  ///   if (kDebugMode) {
  ///     SuperQubitDevTools.enable();
  ///   }
  ///   runApp(MyApp());
  /// }
  /// ```
  static void enable() {
    _enabled = true;
    developer.postEvent('super_qubit.connected', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Whether DevTools integration is enabled.
  static bool get isEnabled => _enabled;

  /// Log the creation of a SuperQubit.
  static void onSuperQubitCreated(SuperQubit superQubit) {
    if (!_enabled) return;
    developer.postEvent('super_qubit.super_qubit_created', {
      'type': superQubit.runtimeType.toString(),
      'hashCode': superQubit.hashCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log the registration of a child Qubit to a SuperQubit.
  static void onQubitRegistered(SuperQubit parent, BaseQubit child) {
    if (!_enabled) return;
    developer.postEvent('super_qubit.qubit_registered', {
      'parentType': parent.runtimeType.toString(),
      'parentHashCode': parent.hashCode,
      'childType': child.runtimeType.toString(),
      'childHashCode': child.hashCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log the creation of a Qubit.
  static void onQubitCreated(BaseQubit qubit) {
    if (!_enabled) return;
    developer.postEvent('super_qubit.qubit_created', {
      'type': qubit.runtimeType.toString(),
      'hashCode': qubit.hashCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log an event being processed by a Qubit.
  static void onEvent(BaseQubit qubit, dynamic event) {
    if (!_enabled) return;

    // Attempt to serialize event if possible, otherwise use toString
    String eventData;
    try {
      // We can't easily check for toJson on dynamic without reflection or interface,
      // using toString for now as per minimal requirement.
      eventData = event.toString();
    } catch (e) {
      eventData = 'Error serializing event: $e';
    }

    developer.postEvent('super_qubit.event', {
      'qubitType': qubit.runtimeType.toString(),
      'qubitHashCode': qubit.hashCode,
      'eventType': event.runtimeType.toString(),
      'eventData': eventData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log a state change in a Qubit.
  static void onStateChange(BaseQubit qubit, dynamic state) {
    if (!_enabled) return;

    String stateData;
    try {
      stateData = state.toString();
    } catch (e) {
      stateData = 'Error serializing state: $e';
    }

    developer.postEvent('super_qubit.state_change', {
      'qubitType': qubit.runtimeType.toString(),
      'qubitHashCode': qubit.hashCode,
      'stateType': state.runtimeType.toString(),
      'stateData': stateData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log the closure of a Qubit.
  static void onQubitClosed(BaseQubit qubit) {
    if (!_enabled) return;
    developer.postEvent('super_qubit.qubit_closed', {
      'qubitType': qubit.runtimeType.toString(),
      'qubitHashCode': qubit.hashCode,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
