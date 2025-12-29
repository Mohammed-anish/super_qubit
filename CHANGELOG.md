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
