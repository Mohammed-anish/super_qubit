import 'package:flutter/material.dart';
import 'product_page_ui.dart';

/// Run this file to see the Product Page Demo in action!
///
/// To run:
/// flutter run -t lib/product_demo_main.dart -d chrome
///
/// Watch the console output to see the cross-communication happening!
void main() {
  runApp(const ProductDemoApp());
}

class ProductDemoApp extends StatelessWidget {
  const ProductDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperQubit Product Page Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductPageDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}
