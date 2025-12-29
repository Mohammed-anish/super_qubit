import 'package:flutter/material.dart';
import 'package:super_qubit/super_qubit.dart';
import 'qubits/cart_super_qubit.dart';
import 'qubits/load_qubit.dart';
import 'qubits/cart_items_qubit.dart';
import 'qubits/cart_filter_qubit.dart';
import 'qubits/user_super_qubit.dart';
import 'qubits/auth_qubit.dart';
import 'qubits/profile_qubit.dart';
import 'qubits/settings_super_qubit.dart';
import 'qubits/theme_qubit.dart';
import 'events/cart_events.dart';
import 'events/user_events.dart';
import 'events/settings_events.dart';
import 'states/cart_states.dart';
import 'states/user_states.dart';
import 'states/settings_states.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using MultiSuperQubitProvider to provide 3 independent SuperQubits
    return MultiSuperQubitProvider(
      providers: [
        SuperQubitProvider<CartSuperQubit>(
          superQubit: CartSuperQubit(),
          qubits: [LoadQubit(), CartItemsQubit(), CartFilterQubit()],
        ),
        SuperQubitProvider<UserSuperQubit>(
          superQubit: UserSuperQubit(),
          qubits: [AuthQubit(), ProfileQubit()],
        ),
        SuperQubitProvider<SettingsSuperQubit>(
          superQubit: SettingsSuperQubit(),
          qubits: [ThemeQubit()],
        ),
      ],
      child: const AppWithTheme(),
    );
  }
}

class AppWithTheme extends StatelessWidget {
  const AppWithTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return QubitBuilder<ThemeQubit, ThemeState>(
      superQubitType: SettingsSuperQubit,
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Multi SuperQubit Example',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: themeState.isDark ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CartPage(),
    const UserPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
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
        title: const Text('Shopping Cart (SuperQubit 1)'),
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

// UserPage - demonstrates UserSuperQubit with Auth and Profile
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('User Profile (SuperQubit 2)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Auth Status
            QubitBuilder<AuthQubit, AuthState>(
              superQubitType: UserSuperQubit,
              builder: (context, authState) {
                if (authState.isLoggingIn) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (!authState.isLoggedIn) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Not Logged In',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showLoginDialog(context),
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          'Logged in as ${authState.username}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<UserSuperQubit, AuthQubit>().add(LogoutEvent());
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Profile Info
            QubitBuilder<ProfileQubit, ProfileState>(
              superQubitType: UserSuperQubit,
              builder: (context, profileState) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${profileState.displayName ?? "Not set"}'),
                        Text('Email: ${profileState.email ?? "Not set"}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Text(
              'This demonstrates cross-Qubit communication: when you login, the ProfileQubit is automatically updated!',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
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
              final username = usernameController.text;
              final password = passwordController.text;

              if (username.isNotEmpty && password.isNotEmpty) {
                context.read<UserSuperQubit, AuthQubit>().add(
                  LoginEvent(username: username, password: password),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// SettingsPage - demonstrates SettingsSuperQubit with Theme
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings (SuperQubit 3)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    QubitBuilder<ThemeQubit, ThemeState>(
                      superQubitType: SettingsSuperQubit,
                      builder: (context, themeState) {
                        return SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: Text(
                            themeState.isDark ? 'Enabled' : 'Disabled',
                          ),
                          value: themeState.isDark,
                          onChanged: (value) {
                            context.read<SettingsSuperQubit, ThemeQubit>().add(
                              ToggleThemeEvent(),
                            );
                          },
                          secondary: Icon(
                            themeState.isDark ? Icons.dark_mode : Icons.light_mode,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This demonstrates the SettingsSuperQubit controlling the entire app theme!',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
