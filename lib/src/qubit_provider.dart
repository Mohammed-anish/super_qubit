import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'super_qubit.dart';
import 'qubit.dart';

/// A widget that provides a [SuperQubit] to its descendants.
///
/// This widget manages the lifecycle of the SuperQubit and its child Qubits,
/// disposing them when the widget is removed from the tree.
///
/// Example:
/// ```dart
/// SuperQubitProvider<CartSuperQubit>(
///   superQubit: CartSuperQubit(),
///   qubits: [LoadQubit(), CartItemsQubit(), CartFilterQubit()],
///   child: MyApp(),
/// )
/// ```
class SuperQubitProvider<T extends SuperQubit> extends SingleChildStatefulWidget {
  /// The SuperQubit instance to provide.
  final T superQubit;

  /// The list of child Qubits to register with the SuperQubit.
  final List<BaseQubit> qubits;

  const SuperQubitProvider({
    super.key,
    required this.superQubit,
    required this.qubits,
    super.child,
  });

  @override
  SingleChildState<SuperQubitProvider<T>> createState() =>
      _SuperQubitProviderState<T>();

  /// Get the SuperQubit from the context.
  ///
  /// Set [listen] to false to get the SuperQubit without establishing a dependency.
  /// This is useful for dispatching events or calling methods without causing rebuilds.
  ///
  /// This will throw if no SuperQubitProvider is found in the widget tree.
  static T of<T extends SuperQubit>(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      final provider = context
          .dependOnInheritedWidgetOfExactType<InheritedSuperQubitProvider<T>>();
      if (provider == null) {
        throw StateError('No SuperQubitProvider<$T> found in context');
      }
      return provider.superQubit;
    } else {
      final element = context
          .getElementForInheritedWidgetOfExactType<InheritedSuperQubitProvider<T>>();
      if (element == null) {
        throw StateError('No SuperQubitProvider<$T> found in context');
      }
      return (element.widget as InheritedSuperQubitProvider<T>).superQubit;
    }
  }
}

class _SuperQubitProviderState<T extends SuperQubit>
    extends SingleChildState<SuperQubitProvider<T>> {
  @override
  void initState() {
    super.initState();
    // Register child Qubits with the SuperQubit
    widget.superQubit.registerQubits(widget.qubits);
  }

  @override
  void dispose() {
    // Close the SuperQubit and all child Qubits
    widget.superQubit.close();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return InheritedSuperQubitProvider<T>(
      superQubit: widget.superQubit,
      superQubitType: T,
      child: child ?? const SizedBox.shrink(),
    );
  }
}

/// Internal InheritedWidget for providing the SuperQubit.
class InheritedSuperQubitProvider<T extends SuperQubit> extends InheritedWidget {
  final T superQubit;
  final Type superQubitType;

  const InheritedSuperQubitProvider({
    required this.superQubit,
    required this.superQubitType,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedSuperQubitProvider<T> oldWidget) {
    return superQubit != oldWidget.superQubit;
  }
}

/// A widget that provides multiple [SuperQubit]s to its descendants.
///
/// This is a convenience widget that uses the `nested` package to nest
/// multiple [SuperQubitProvider]s cleanly without deep indentation.
///
/// Example:
/// ```dart
/// MultiSuperQubitProvider(
///   providers: [
///     SuperQubitProvider<CartSuperQubit>(
///       superQubit: CartSuperQubit(),
///       qubits: [LoadQubit(), CartItemsQubit()],
///     ),
///     SuperQubitProvider<UserSuperQubit>(
///       superQubit: UserSuperQubit(),
///       qubits: [AuthQubit(), ProfileQubit()],
///     ),
///   ],
///   child: MyApp(),
/// )
/// ```
class MultiSuperQubitProvider extends Nested {
  /// Creates a [MultiSuperQubitProvider] that nests multiple [SuperQubitProvider]s.
  MultiSuperQubitProvider({
    super.key,
    required List<SuperQubitProvider> providers,
    required Widget child,
  }) : super(children: providers, child: child);
}
