import 'package:flutter/widgets.dart';
import 'super_qubit.dart';
import 'qubit.dart';

/// A widget that provides a [SuperQubit] to its descendants.
///
/// This widget manages the lifecycle of the SuperQubit and its child Qubits,
/// disposing them when the widget is removed from the tree.
///
/// Example:
/// ```dart
/// QubitProvider<CartSuperQubit>(
///   superQubit: CartSuperQubit(),
///   superStates: [LoadQubit(), CartItemsQubit(), CartFilterQubit()],
///   child: MyApp(),
/// )
/// ```
class QubitProvider<T extends SuperQubit> extends StatefulWidget {
  /// The SuperQubit instance to provide.
  final T superQubit;

  /// The list of child Qubits to register with the SuperQubit.
  final List<BaseQubit> superStates;

  /// The widget below this widget in the tree.
  final Widget child;

  const QubitProvider({
    super.key,
    required this.superQubit,
    required this.superStates,
    required this.child,
  });

  @override
  State<QubitProvider<T>> createState() => _QubitProviderState<T>();

  /// Get the SuperQubit from the context.
  ///
  /// Set [listen] to false to get the SuperQubit without establishing a dependency.
  /// This is useful for dispatching events or calling methods without causing rebuilds.
  ///
  /// This will throw if no QubitProvider is found in the widget tree.
  static T of<T extends SuperQubit>(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      final provider = context
          .dependOnInheritedWidgetOfExactType<InheritedQubitProvider<T>>();
      if (provider == null) {
        throw StateError('No QubitProvider<$T> found in context');
      }
      return provider.superQubit;
    } else {
      final element = context
          .getElementForInheritedWidgetOfExactType<InheritedQubitProvider<T>>();
      if (element == null) {
        throw StateError('No QubitProvider<$T> found in context');
      }
      return (element.widget as InheritedQubitProvider<T>).superQubit;
    }
  }
}

class _QubitProviderState<T extends SuperQubit>
    extends State<QubitProvider<T>> {
  @override
  void initState() {
    super.initState();
    // Register child Qubits with the SuperQubit
    widget.superQubit.registerQubits(widget.superStates);
  }

  @override
  void dispose() {
    // Close the SuperQubit and all child Qubits
    widget.superQubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedQubitProvider<T>(
      superQubit: widget.superQubit,
      superQubitType: T,
      child: widget.child,
    );
  }
}

/// Internal InheritedWidget for providing the SuperQubit.
class InheritedQubitProvider<T extends SuperQubit> extends InheritedWidget {
  final T superQubit;
  final Type superQubitType;

  const InheritedQubitProvider({
    required this.superQubit,
    required this.superQubitType,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedQubitProvider<T> oldWidget) {
    return superQubit != oldWidget.superQubit;
  }
}
