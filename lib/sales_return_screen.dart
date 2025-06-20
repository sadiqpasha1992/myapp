// lib/sales_return_screen.dart
import 'package:flutter/material.dart';

class SalesReturnScreen extends StatelessWidget {
  const SalesReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // This one needs a Scaffold as it's a new "page" navigated to
      appBar: AppBar(
        title: const Text('Add Sales Return'),
        backgroundColor: Colors.redAccent, // Distinct color
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Sales Return Entry Form\n(To be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}