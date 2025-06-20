// lib/purchase_return_screen.dart
import 'package:flutter/material.dart';

class PurchaseReturnScreen extends StatelessWidget {
  const PurchaseReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // This one needs a Scaffold as it's a new "page" navigated to
      appBar: AppBar(
        title: const Text('Add Purchase Return'),
        backgroundColor: Colors.orangeAccent, // Distinct color
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Purchase Return Entry Form\n(To be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}