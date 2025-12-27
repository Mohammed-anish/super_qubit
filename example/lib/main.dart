import 'package:flutter/material.dart';
import 'package:super_qubit/super_qubit.dart';
import 'qubits/cart_super_qubit.dart';
import 'qubits/load_qubit.dart';
import 'qubits/cart_items_qubit.dart';
import 'qubits/cart_filter_qubit.dart';
import 'events/cart_events.dart';
import 'states/cart_states.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return QubitProvider<CartSuperQubit>(
      superQubit: CartSuperQubit(),
      superStates: [LoadQubit(), CartItemsQubit(), CartFilterQubit()],
      child: MaterialApp(
        title: 'State Management Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const CartPage(),
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Shopping Cart Example'),
      ),
      body: Column(
        children: [
          // Loading indicator using QubitBuilder
          QubitBuilder<LoadQubit, LoadState>(
            superQubitType: CartSuperQubit,
            builder: (context, state) {
              if (state.isLoading) {
                return const LinearProgressIndicator();
              }
              return const SizedBox(height: 4);
            },
          ),

          // Filter section using QubitConsumer (combines builder + listener)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: QubitConsumer<CartFilterQubit, CartFilterState>(
              superQubitType: CartSuperQubit,
              listener: (context, state) {
                // Show snackbar when filter changes
                if (state.filter != 'all') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Filter changed to: ${state.filter}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: state.filter == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<CartSuperQubit, CartFilterQubit>().add(
                            SetFilterEvent('all'),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Expensive'),
                      selected: state.filter == 'expensive',
                      onSelected: (selected) {
                        if (selected) {
                          context.read<CartSuperQubit, CartFilterQubit>().add(
                            SetFilterEvent('expensive'),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Cart items list using QubitBuilder with QubitListener for side effects
          Expanded(
            child: QubitListener<CartItemsQubit, CartItemsState>(
              superQubitType: CartSuperQubit,
              listener: (context, state) {
                // Show snackbar when item is added (state has more items than before)
                // This demonstrates QubitListener for side effects
              },
              child: QubitBuilder<CartItemsQubit, CartItemsState>(
                superQubitType: CartSuperQubit,
                builder: (context, state) {
                  if (state.isEmpty) {
                    return const Center(
                      child: Text(
                        'Cart is empty\nAdd some items!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return ListTile(
                              leading: CircleAvatar(child: Text(item.name[0])),
                              title: Text(item.name),
                              subtitle: Text(
                                '\$${item.price.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  context
                                      .read<CartSuperQubit, CartItemsQubit>()
                                      .add(RemoveItemEvent(item.id));
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${state.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddItemDialog(context),
            tooltip: 'Add Item',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'clear',
            onPressed: () {
              context.read<CartSuperQubit, CartItemsQubit>().add(
                ClearCartEvent(),
              );
            },
            tooltip: 'Clear Cart',
            child: const Icon(Icons.clear_all),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'load',
            onPressed: () {
              context
                  .readSuper<CartSuperQubit>()
                  .dispatch<LoadQubit, LoadTriggerEvent>(LoadTriggerEvent());
            },
            tooltip: 'Trigger Load',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (name.isNotEmpty && price > 0) {
                context.read<CartSuperQubit, CartItemsQubit>().add(
                  AddItemEvent(name: name, price: price),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
