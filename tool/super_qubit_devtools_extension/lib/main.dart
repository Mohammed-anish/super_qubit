import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SuperQubitDevToolsExtension());
}

class SuperQubitDevToolsExtension extends StatelessWidget {
  const SuperQubitDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: SuperQubitDevToolsScreen());
  }
}

/// Model representing a single log entry (Event or State Change).
class LogEntry {
  final String kind;
  final String type;
  final String data;
  final DateTime timestamp;

  LogEntry({
    required this.kind,
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Model representing a Qubit (Child).
class QubitInfo {
  @override
  final int hashCode;
  final String type;
  final List<LogEntry> logs = [];

  QubitInfo({required this.hashCode, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QubitInfo && other.hashCode == hashCode;
  }
}

/// Model representing a SuperQubit (Parent).
class SuperQubitInfo {
  @override
  final int hashCode;
  final String type;
  final List<QubitInfo> children = [];

  SuperQubitInfo({required this.hashCode, required this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuperQubitInfo && other.hashCode == hashCode;
  }
}

class SuperQubitDevToolsScreen extends StatefulWidget {
  const SuperQubitDevToolsScreen({super.key});

  @override
  State<SuperQubitDevToolsScreen> createState() =>
      _SuperQubitDevToolsScreenState();
}

class _SuperQubitDevToolsScreenState extends State<SuperQubitDevToolsScreen> {
  // Data Store
  final Map<String, SuperQubitInfo> _superQubits = {};
  final Map<String, QubitInfo> _qubits = {};
  final Map<String, String> _qubitParentMap =
      {}; // childHashCode -> parentHashCode

  // Selection
  String? _selectedQubitHashCode;

  // Debug
  int _eventCount = 0;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initListener();
  }

  void _initListener() {
    final service = serviceManager.service;
    if (service != null) {
      _subscribe(service);
    } else {
      serviceManager.connectedState.addListener(_connectionListener);
    }
  }

  void _connectionListener() {
    if (serviceManager.connectedState.value.connected) {
      _subscribe(serviceManager.service!);
      serviceManager.connectedState.removeListener(_connectionListener);
    }
  }

  void _subscribe(dynamic service) {
    _subscription = service.onExtensionEvent.listen((event) {
      if (event.extensionKind?.startsWith('super_qubit') ?? false) {
        _processEvent(event);
      }
    });
  }

  void _processEvent(dynamic event) {
    setState(() {
      _eventCount++;
      final kind = event.extensionKind as String;
      final data = event.extensionData?.data ?? {};
      final timestamp = DateTime.parse(
        data['timestamp'] ?? DateTime.now().toIso8601String(),
      );

      if (kind == 'super_qubit.super_qubit_created') {
        final code = data['hashCode'].toString();
        final type = data['type'].toString();
        _superQubits.putIfAbsent(
          code,
          () => SuperQubitInfo(hashCode: int.tryParse(code) ?? 0, type: type),
        );
      } else if (kind == 'super_qubit.qubit_created') {
        final code = data['hashCode'].toString();
        final type = data['type'].toString();
        _qubits.putIfAbsent(
          code,
          () => QubitInfo(hashCode: int.tryParse(code) ?? 0, type: type),
        );
      } else if (kind == 'super_qubit.qubit_registered') {
        final parentCode = data['parentHashCode'].toString();
        final childCode = data['childHashCode'].toString();
        final parentType = data['parentType'].toString();
        final childType = data['childType'].toString();

        // Ensure models exist
        final parent = _superQubits.putIfAbsent(
          parentCode,
          () => SuperQubitInfo(
            hashCode: int.tryParse(parentCode) ?? 0,
            type: parentType,
          ),
        );
        final child = _qubits.putIfAbsent(
          childCode,
          () => QubitInfo(
            hashCode: int.tryParse(childCode) ?? 0,
            type: childType,
          ),
        );

        // Link
        if (!_qubitParentMap.containsKey(childCode)) {
          _qubitParentMap[childCode] = parentCode;
          if (!parent.children.contains(child)) {
            parent.children.add(child);
          }
        }
      } else if (kind == 'super_qubit.event' ||
          kind == 'super_qubit.state_change') {
        final qubitCode = data['qubitHashCode'].toString();
        final qubitType = data['qubitType'].toString();

        // Ensure qubit exists (sometimes event comes before creation log)
        final qubit = _qubits.putIfAbsent(
          qubitCode,
          () => QubitInfo(
            hashCode: int.tryParse(qubitCode) ?? 0,
            type: qubitType,
          ),
        );

        final logEntry = LogEntry(
          kind: kind == 'super_qubit.event' ? 'Event' : 'State',
          type: kind == 'super_qubit.event'
              ? data['eventType'].toString()
              : data['stateType'].toString(),
          data: kind == 'super_qubit.event'
              ? data['eventData'].toString()
              : data['stateData'].toString(),
          timestamp: timestamp,
        );
        qubit.logs.insert(0, logEntry);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    serviceManager.connectedState.removeListener(_connectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine orphans: Qubits that are not in the parent map
    final orphanQubits = _qubits.values
        .where((q) => !_qubitParentMap.containsKey(q.hashCode.toString()))
        .toList();

    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: const [0.3, 0.7],
      children: [
        // Left Panel: Hierarchy List
        RoundedOutlinedBorder(
          child: Column(
            children: [
              AreaPaneHeader(
                title: Text('Qubits (Events: $_eventCount)'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() {
                      _superQubits.clear();
                      _qubits.clear();
                      _qubitParentMap.clear();
                      _selectedQubitHashCode = null;
                      _eventCount = 0;
                    }),
                    tooltip: 'Clear',
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (_superQubits.isNotEmpty)
                      ..._superQubits.values.map((superQubit) {
                        return ExpansionTile(
                          initiallyExpanded: true,
                          leading: const Icon(Icons.share, size: 16),
                          title: Text(
                            superQubit.type,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: superQubit.children
                              .map((qubit) => _buildQubitTile(qubit))
                              .toList(),
                        );
                      }),
                    if (orphanQubits.isNotEmpty)
                      ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.question_mark, size: 16),
                        title: const Text(
                          'Other Qubits',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        children: orphanQubits
                            .map((qubit) => _buildQubitTile(qubit))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right Panel: Details
        RoundedOutlinedBorder(
          child: Column(
            children: [
              AreaPaneHeader(title: Text(_getSelectedQubitName())),
              Expanded(child: _buildLogList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQubitTile(QubitInfo qubit) {
    final isSelected = _selectedQubitHashCode == qubit.hashCode.toString();
    return ListTile(
      selected: isSelected,
      selectedTileColor: Theme.of(context).focusColor,
      leading: const Icon(Icons.bolt, size: 16),
      title: Text(qubit.type),
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      onTap: () => setState(() {
        _selectedQubitHashCode = qubit.hashCode.toString();
      }),
    );
  }

  String _getSelectedQubitName() {
    if (_selectedQubitHashCode == null) return 'Select a Qubit';
    final qubit = _qubits[_selectedQubitHashCode];
    return qubit?.type ?? 'Unknown Qubit';
  }

  Widget _buildLogList() {
    if (_selectedQubitHashCode == null) {
      return const Center(child: Text('Select a Qubit to view logs.'));
    }

    final qubit = _qubits[_selectedQubitHashCode];
    if (qubit == null || qubit.logs.isEmpty) {
      return const Center(
        child: Text('No events or state changes recorded for this Qubit.'),
      );
    }

    return ListView.builder(
      itemCount: qubit.logs.length,
      itemBuilder: (context, index) {
        final log = qubit.logs[index];
        final isEvent = log.kind == 'Event';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              isEvent ? Icons.arrow_forward : Icons.sync,
              color: isEvent ? Colors.amber : Colors.blue,
            ),
            title: Text('${log.kind}: ${log.type}'),
            subtitle: Text(
              log.data,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            trailing: Text(
              '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}.${log.timestamp.millisecond}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
