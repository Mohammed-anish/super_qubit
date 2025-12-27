import 'package:flutter/widgets.dart';
import 'super_qubit.dart';
import 'qubit.dart';
import 'qubit_provider.dart';

/// Extensions for single-type lookup (SuperQubit only).
extension QubitSingleContextExtensions on BuildContext {
  /// Read a SuperQubit from the context without listening to changes.
  ///
  /// Example:
  /// ```dart
  /// final cart = context.readSuper<CartSuperQubit>();
  /// cart.items.add(AddItemEvent(...));
  /// ```
  T readSuper<T extends SuperQubit>() {
    return QubitProvider.of<T>(this, listen: false);
  }

  /// Watch a SuperQubit and rebuild when any of its child Qubits change.
  ///
  /// Example:
  /// ```dart
  /// final cart = context.watchSuper<CartSuperQubit>();
  /// ```
  T watchSuper<T extends SuperQubit>() {
    return QubitProvider.of<T>(this, listen: true);
  }
}

/// Extensions for dual-type lookup (SuperQubit and child Qubit).
extension QubitDualContextExtensions on BuildContext {
  /// Read a specific child Qubit from a SuperQubit without listening to changes.
  ///
  /// Example:
  /// ```dart
  /// context.read<CartSuperQubit, CartItemsQubit>().add(AddItemEvent(...));
  /// ```
  Q read<T extends SuperQubit, Q extends BaseQubit>() {
    return QubitProvider.of<T>(this, listen: false).getQubit<Q>();
  }

  /// Watch a specific child Qubit and rebuild when its state changes.
  ///
  /// Example:
  /// ```dart
  /// final loadQubit = context.watch<CartSuperQubit, LoadQubit>();
  /// if (loadQubit.state.isLoading) { ... }
  /// ```
  Q watch<T extends SuperQubit, Q extends BaseQubit>() {
    return QubitProvider.of<T>(this, listen: true).getQubit<Q>();
  }
}

/// Additional helper extensions for state access.
extension QubitStateExtensions on BuildContext {
  /// Watch a specific child Qubit's state and rebuild when it changes.
  ///
  /// Example:
  /// ```dart
  /// final loadState = context.watchState<CartSuperQubit, LoadQubit, LoadState>();
  /// if (loadState.isLoading) { ... }
  /// ```
  S watchState<T extends SuperQubit, Q extends Qubit<dynamic, S>, S>() {
    return QubitProvider.of<T>(this, listen: true).getQubit<Q>().state;
  }

  /// Select a specific value from a child Qubit's state and rebuild only when that value changes.
  ///
  /// Example:
  /// ```dart
  /// final isLoading = context.select<CartSuperQubit, LoadQubit, LoadState, bool>(
  ///   (state) => state.isLoading,
  /// );
  /// ```
  R select<T extends SuperQubit, Q extends Qubit<dynamic, S>, S, R>(
    R Function(S state) selector,
  ) {
    final qubit = QubitProvider.of<T>(this, listen: true).getQubit<Q>();
    return selector(qubit.state);
  }
}
