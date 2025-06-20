// lib/dashboard_screen.dart
import 'package:flutter/material.dart';

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

  // Helper method for the "Performance Overview" if you want to keep it.
  // If you don't want "Performance Overview", remove this method and its call below.
  Widget _buildPerformanceOverview() {
    // This is just a placeholder for the graph/chart area.
    // Replace with your actual charting library (e.g., fl_chart, charts_flutter)
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 200, // Adjust height as needed
        width: double.infinity,
        child: const Center(
          child: Text(
            'Performance Chart Area\n(Data Visualization Here)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- IMPORTANT: NO Scaffold or AppBar here! ---
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
              // You'll fetch actual data from AppData boxes
              _buildDashboardCard(
                'Total Sales',
                '₹0.00', // Replace with actual calculated total sales
                Icons.shopping_cart,
                Colors.green,
              ),
              _buildDashboardCard(
                'Total Purchases',
                '₹0.00', // Replace with actual calculated total purchases
                Icons.add_shopping_cart,
                Colors.orange,
              ),
              _buildDashboardCard(
                'Cash Balance',
                '₹0.00', // Replace with actual calculated cash balance
                Icons.account_balance_wallet,
                Colors.blue,
              ),
              _buildDashboardCard(
                'Low Stock Items',
                '0', // Replace with actual count of low stock items
                Icons.low_priority,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Performance Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildPerformanceOverview(), // Call the method to build the chart area
          const SizedBox(height: 20),
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