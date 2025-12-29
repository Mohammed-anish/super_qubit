import 'dart:async';
import 'package:flutter/widgets.dart';
import 'super_qubit.dart';
import 'qubit.dart';
import 'qubit_provider.dart';

/// A widget that listens to a Qubit and rebuilds when the state changes.
/// A Flutter widget that builds itself based on the latest state of a [Qubit].
///
/// [Q] is the type of the child Qubit.
/// [S] is the type of the state.
///
/// Example:
/// ```dart
/// QubitBuilder<LoadQubit, LoadState>(
///   builder: (context, state) {
///     if (state.isLoading) {
///       return CircularProgressIndicator();
///     }
///     return Text('Loaded');
///   },
/// )
/// ```
class QubitBuilder<Q extends BaseQubit, S> extends StatefulWidget {
  /// The type of the SuperQubit that contains the child Qubit.
  final Type superQubitType;

  /// The builder function that builds the widget tree.
  final Widget Function(BuildContext context, S state) builder;

  const QubitBuilder({
    super.key,
    required this.superQubitType,
    required this.builder,
  });

  @override
  State<QubitBuilder<Q, S>> createState() => _QubitBuilderState<Q, S>();
}

class _QubitBuilderState<Q extends BaseQubit, S>
    extends State<QubitBuilder<Q, S>> {
  Q? _qubit;
  StreamSubscription<S>? _subscription;
  S? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initQubit();
  }

  void _initQubit() {
    try {
      final superQubit = _getSuperQubit();
      final newQubit = superQubit.getQubit<Q>();

      if (newQubit != _qubit) {
        _subscription?.cancel();
        _qubit = newQubit;
        _state = newQubit.state;
        _subscription = newQubit.stream.cast<S>().listen((state) {
          if (mounted) {
            setState(() {
              _state = state;
            });
          }
        });
      }
    } catch (e) {
      // Error handling is done in build method which calls _getSuperQubit
      // and properly throws StateError if provider is missing
    }
  }

  SuperQubit _getSuperQubit() {
    SuperQubit? found;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedSuperQubitProvider) {
        if (widget.superQubitType == this.widget.superQubitType) {
          found = widget.superQubit;
          return false;
        }
      }
      return true;
    });

    if (found == null) {
      throw StateError(
        'No SuperQubitProvider<${widget.superQubitType}> found in context',
      );
    }
    return found!;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      // Re-run lookup to trigger StateError if provider is missing
      _getSuperQubit();
      return const SizedBox.shrink();
    }
    return widget.builder(context, state);
  }
}

/// A Flutter widget that listens to state changes in a [Qubit].
///
/// Use this for side effects like showing snackbars, navigating, etc.
///
/// Example:
/// ```dart
/// QubitListener<LoadQubit, LoadState>(
///   listener: (context, state) {
///     if (state.hasError) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Error occurred')),
///       );
///     }
///   },
///   child: MyWidget(),
/// )
/// ```
class QubitListener<Q extends BaseQubit, S> extends StatefulWidget {
  /// The type of the SuperQubit that contains the child Qubit.
  final Type superQubitType;

  /// The listener function that performs side effects.
  final void Function(BuildContext context, S state) listener;

  /// The widget below this widget in the tree.
  final Widget child;

  const QubitListener({
    super.key,
    required this.superQubitType,
    required this.listener,
    required this.child,
  });

  @override
  State<QubitListener<Q, S>> createState() => _QubitListenerState<Q, S>();
}

class _QubitListenerState<Q extends BaseQubit, S>
    extends State<QubitListener<Q, S>> {
  Q? _qubit;
  StreamSubscription<S>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initQubit();
  }

  void _initQubit() {
    try {
      final superQubit = _getSuperQubit();
      final newQubit = superQubit.getQubit<Q>();

      if (newQubit != _qubit) {
        _subscription?.cancel();
        _qubit = newQubit;
        _subscription = newQubit.stream.cast<S>().listen((state) {
          if (mounted) {
            widget.listener(context, state);
          }
        });
      }
    } catch (e) {
      // Error is intentionally ignored here; if provider is missing,
      // the build method doesn't show error but listener won't work
    }
  }

  SuperQubit _getSuperQubit() {
    SuperQubit? found;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedSuperQubitProvider) {
        if (widget.superQubitType == this.widget.superQubitType) {
          found = widget.superQubit;
          return false;
        }
      }
      return true;
    });

    if (found == null) {
      throw StateError(
        'No SuperQubitProvider<${widget.superQubitType}> found in context',
      );
    }
    return found!;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A Flutter widget that both builds and listens to a [Qubit].
///
/// Example:
/// ```dart
/// QubitConsumer<LoadQubit, LoadState>(
///   listener: (context, state) {
///     if (state.hasError) {
///       showDialog(...);
///     }
///   },
///   builder: (context, state) {
///     return Text(state.message);
///   },
/// )
/// ```
class QubitConsumer<Q extends BaseQubit, S> extends StatefulWidget {
  /// The type of the SuperQubit that contains the child Qubit.
  final Type superQubitType;

  /// The builder function that builds the widget tree.
  final Widget Function(BuildContext context, S state) builder;

  /// The listener function that performs side effects.
  final void Function(BuildContext context, S state) listener;

  const QubitConsumer({
    super.key,
    required this.superQubitType,
    required this.builder,
    required this.listener,
  });

  @override
  State<QubitConsumer<Q, S>> createState() => _QubitConsumerState<Q, S>();
}

class _QubitConsumerState<Q extends BaseQubit, S>
    extends State<QubitConsumer<Q, S>> {
  Q? _qubit;
  StreamSubscription<S>? _subscription;
  S? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initQubit();
  }

  void _initQubit() {
    try {
      final superQubit = _getSuperQubit();
      final newQubit = superQubit.getQubit<Q>();

      if (newQubit != _qubit) {
        _subscription?.cancel();
        _qubit = newQubit;
        _state = newQubit.state;
        _subscription = newQubit.stream.cast<S>().listen((state) {
          if (mounted) {
            widget.listener(context, state);
            setState(() {
              _state = state;
            });
          }
        });
      }
    } catch (e) {
      // Error handling is done in build method which calls _getSuperQubit
      // and properly throws StateError if provider is missing
    }
  }

  SuperQubit _getSuperQubit() {
    SuperQubit? found;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedSuperQubitProvider) {
        if (widget.superQubitType == this.widget.superQubitType) {
          found = widget.superQubit;
          return false;
        }
      }
      return true;
    });

    if (found == null) {
      throw StateError(
        'No SuperQubitProvider<${widget.superQubitType}> found in context',
      );
    }
    return found!;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      _getSuperQubit();
      return const SizedBox.shrink();
    }
    return widget.builder(context, state);
  }
}
