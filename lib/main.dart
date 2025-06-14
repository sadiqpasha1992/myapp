import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/app_data.dart'; // Import your AppData

void main() async {
  // Ensures that Flutter's binding is initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters for your data models.
  Hive.registerAdapter(PartyAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(PurchaseAdapter()); // NEW: Register PurchaseAdapter
  Hive.registerAdapter(CashTransactionAdapter());

  // Initialize AppData (open Hive boxes)
  await AppData.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizFlow App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
