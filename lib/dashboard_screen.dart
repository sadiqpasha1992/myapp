// lib/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart'; // Import models.dart for access to Product, Sale, Purchase, CashTransaction

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Helper method to build dashboard cards
  Widget _buildDashboardCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: This screen is "body-only". It does NOT return a Scaffold or AppBar directly.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 25),
          const Text(
            'Your Business Snapshot',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true, // Use shrinkWrap for GridView inside SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2, // Adjust card aspect ratio
            children: [
              // Total Sales Card
              ValueListenableBuilder<Box<Sale>>(
                valueListenable: AppData.salesBox.listenable(),
                builder: (context, box, _) {
                  final double totalSales = box.values.fold(0.0, (sum, sale) => sum + sale.totalAmount);
                  return _buildDashboardCard(
                    'Total Sales',
                    '₹${totalSales.toStringAsFixed(2)}',
                    Icons.shopping_cart,
                    Colors.green,
                  );
                },
              ),
              // Total Purchases Card
              ValueListenableBuilder<Box<Purchase>>(
                valueListenable: AppData.purchasesBox.listenable(),
                builder: (context, box, _) {
                  final double totalPurchases = box.values.fold(0.0, (sum, purchase) => sum + purchase.totalAmount);
                  return _buildDashboardCard(
                    'Total Purchases',
                    '₹${totalPurchases.toStringAsFixed(2)}',
                    Icons.add_shopping_cart,
                    Colors.orange,
                  );
                },
              ),
              // Cash Balance Card (Requires CashTransaction model and box)
              ValueListenableBuilder<Box<CashTransaction>>(
                valueListenable: AppData.cashTransactionsBox.listenable(),
                builder: (context, box, _) {
                  final double cashIn = box.values.where((t) => t.type == 'Cash In').fold(0.0, (sum, t) => sum + t.amount);
                  final double cashOut = box.values.where((t) => t.type == 'Cash Out').fold(0.0, (sum, t) => sum + t.amount);
                  final double cashBalance = cashIn - cashOut;
                  return _buildDashboardCard(
                    'Cash Balance',
                    '₹${cashBalance.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    cashBalance >= 0 ? Colors.blue : Colors.red, // Color based on balance
                  );
                },
              ),
              // Low Stock Items Card
              ValueListenableBuilder<Box<Product>>(
                valueListenable: AppData.productsBox.listenable(),
                builder: (context, box, _) {
                  final int lowStockItems = box.values.where((p) => p.currentStock < 10).length; // Example threshold: < 10 units
                  return _buildDashboardCard(
                    'Low Stock Items',
                    lowStockItems.toString(),
                    Icons.low_priority,
                    lowStockItems > 0 ? Colors.red : Colors.green, // Red if low, green if good
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // --- REMOVED: "Performance Overview" section and its content ---
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          // Placeholder for recent activity list
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              height: 150, // Adjust height as needed
              width: double.infinity,
              child: const Center(
                child: Text(
                  'Recent Sales/Purchases/Expenses\n(List of recent transactions here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
