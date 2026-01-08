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
