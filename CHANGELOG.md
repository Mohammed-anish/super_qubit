## 1.2.0

- **Lazy Qubit Initialization**: Removed the need for an `init()` method in child Qubits. Calls to `listenTo` and `dispatch` in the `Qubit` constructor are now automatically queued and executed once the parent is assigned.
- **Improved Internal Communication**: Sibling communication is now safe to use directly in `Qubit` constructors thanks to the new queuing mechanism.
- **Resource Management**: Added cleanup for `_parentEventStreams` in `SuperQubit` to prevent memory leaks when disposing.
- **Enhanced Emitter Stability**: Fixed issues where parent handlers might not be executed correctly when transformers are involved.
- **Enhanced Examples**: Added a complex search and cart example demonstrating debounced search, sibling-to-sibling communication, and direct parent-to-child state control.
- **Bug Fix**: Resolved `StateError` when calling `listenTo` during Qubit construction.

## 1.1.0

- **Event Transformers**: Added support for event transformers in `Qubit` and `SuperQubit`.
- Built-in transformers: `sequential`, `concurrent`, `restartable`, `droppable`, `debounce`, and `throttle`.
- **API Standardization**: Changed `Qubit.on` config parameter to a named parameter for consistency with `SuperQubit.on`.
- **Emitter Cancellation**: Automatic cancellation of state emissions when a transformer cancels an event execution.

## 1.0.0

- **DevTools Integration**: Added DevTools extension for `super_qubit`.
- Logs `Qubit` and `SuperQubit` lifecycle events, events, and state changes.
- Custom "SuperQubit" tab in DevTools for inspecting the qubit hierarchy and event logs.
- New `SuperQubitDevTools.enable()` method.

## 0.1.3

- Enhanced MultiSuperQubitProvider implementation

## 0.1.2

- Added dispatcher functionality to Qubit for cross-qubit communication

## 0.1.1

- Dart Formatting fix

## 0.1.0

- Initial release of SuperQubit
- Hierarchical state management with SuperQubit and Qubit
- Event handling and propagation control with configurable flags
- Cross-Qubit communication via `dispatch` and `listenTo`
- Type-safe generic support for states and events
- Stream-based state updates
- `init()` lifecycle method for setting up handlers after child Qubits are registered
- Flutter widget integration with SuperQubitProvider, MultiSuperQubitProvider, QubitBuilder, QubitListener, and QubitConsumer
- Context extensions for convenient state access (readSuper, watchSuper, read, watch, etc.)
- MultiSuperQubitProvider built on the `nested` package for clean multi-provider setup
- Comprehensive documentation and examples
