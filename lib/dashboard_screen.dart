import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import 'sales_screen.dart';
import 'purchase_screen.dart';
import 'invoice_screen.dart';
import 'expense_screen.dart';
import 'stock_summary_screen.dart';
import 'parties_screen.dart';
import 'cash_book_screen.dart';
import 'reports_screen.dart';
import 'data/app_data.dart'; // Import our shared data file
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'dart:math'; // Explicitly import dart:math for min and max

// DashboardScreen is now a StatefulWidget to manage the selected tab index
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Current selected tab index

  // List of widgets (screens) for the bottom navigation bar
  final List<Widget> _widgetOptions = <Widget>[
    const _DashboardContent(), // Our actual dashboard UI
    const SalesScreen(), // Sales screen as a main tab
    const StockSummaryScreen(), // Stock Summary screen
    const PartiesScreen(), // Parties screen
    const ReportsScreen(), // Reports screen as a main tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BizFlow'), // Changed app title for main screen
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack( // Efficiently switches between widgets without rebuilding
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // The FloatingActionButton is still there, but we've added more quick actions
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a modal bottom sheet with quick add options
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column take minimum space
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Quick Add',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.add_shopping_cart, color: Colors.green),
                      title: const Text('New Sale'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.shopping_basket, color: Colors.orange),
                      title: const Text('New Purchase'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PurchaseScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt, color: Colors.purple),
                      title: const Text('Generate Invoice'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InvoiceScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.money_off, color: Colors.red),
                      title: const Text('Add Expense'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExpenseScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.blueGrey),
                      title: const Text('Cash Book'),
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CashBookScreen()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        tooltip: 'Quick Add Menu',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), // Sales icon
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory), // Stock icon
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // Parties icon
            label: 'Parties',
          ),
          BottomNavigationBarItem( // Reports tab
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex, // Highlights the currently selected tab
        selectedItemColor: Colors.blueAccent, // Color for the selected icon/label
        unselectedItemColor: Colors.grey, // Color for unselected icons/labels
        onTap: _onItemTapped, // Calls our method when a tab is tapped
        type: BottomNavigationBarType.fixed, // Ensures all labels are always visible
      ),
    );
  }
}

// New helper widget to encapsulate the original Dashboard body content
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  // Helper method to build a consistent metric card
  Widget _buildMetricCardLocal(BuildContext context, String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a consistent action button
  Widget _buildActionButtonLocal(BuildContext context, String title, IconData icon, Color color, Widget? targetScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (targetScreen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetScreen),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Section 1: Welcome Message ---
          Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 24),

          // --- Section 2: Key Metrics Overview (Now Dynamic) ---
          Text(
            'Your Business Snapshot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dynamic Total Sales
              ValueListenableBuilder(
                valueListenable: AppData.salesBox.listenable(),
                builder: (context, Box<Sale> box, _) {
                  final double totalSales = box.values.fold(0.0, (sum, sale) {
                    return sum + sale.saleAmount;
                  });
                  return _buildMetricCardLocal(context, 'Total Sales', '₹ ${totalSales.toStringAsFixed(2)}', Colors.green);
                },
              ),
              // Dynamic Total Purchases
              ValueListenableBuilder(
                valueListenable: AppData.purchasesBox.listenable(),
                builder: (context, Box<Purchase> box, _) {
                  final double totalPurchases = box.values.fold(0.0, (sum, purchase) {
                    return sum + purchase.purchaseAmount;
                  });
                  return _buildMetricCardLocal(context, 'Total Purchases', '₹ ${totalPurchases.toStringAsFixed(2)}', Colors.orange);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dynamic Cash Balance (Now calculated from Cash Transactions)
              ValueListenableBuilder(
                valueListenable: AppData.cashTransactionsBox.listenable(),
                builder: (context, Box<CashTransaction> box, _) {
                  double totalInflow = box.values
                      .where((t) => t.type == 'Inflow')
                      .fold(0.0, (sum, t) => sum + t.amount);
                  double totalOutflow = box.values
                      .where((t) => t.type == 'Outflow')
                      .fold(0.0, (sum, t) => sum + t.amount);
                  final double cashBalance = totalInflow - totalOutflow;
                  return _buildMetricCardLocal(context, 'Cash Balance', '₹ ${cashBalance.toStringAsFixed(2)}', Colors.blue);
                },
              ),
              // Dynamic Low Stock Items
              ValueListenableBuilder(
                valueListenable: AppData.productsBox.listenable(),
                builder: (context, Box<Product> box, _) {
                  final int lowStockCount = box.values.where((product) => product.quantity < 10).length;
                  return _buildMetricCardLocal(context, 'Low Stock Items', lowStockCount.toString(), Colors.red);
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- Section 3: Performance Overview (Now with Charts) ---
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 16),
          // Sales Trend Chart
          Container(
            height: 250, // Height for the chart
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ValueListenableBuilder(
              valueListenable: AppData.salesBox.listenable(),
              builder: (context, Box<Sale> salesBox, _) {
                final Map<int, double> salesByDay = {}; // Initialize as mutable map
                final DateTime now = DateTime.now();
                const int daysToShow = 7; // Last 7 days

                // Initialize sales for last 'daysToShow' to 0
                for (int i = 0; i < daysToShow; i++) {
                  final DateTime date = now.subtract(Duration(days: i));
                  salesByDay[date.day] = 0.0;
                }

                // Aggregate sales data for the last 'daysToShow' days
                for (final sale in salesBox.values) {
                  // Use the actual sale date for aggregation
                  final int saleDay = sale.date.day;
                  // Only include sales within the last 'daysToShow' period
                  if (now.difference(sale.date).inDays < daysToShow) {
                    salesByDay.update(
                      saleDay,
                      (value) => value + sale.saleAmount,
                      ifAbsent: () => sale.saleAmount,
                    );
                  }
                }

                // Convert sales data to FlSpot list for the LineChart
                final List<FlSpot> spots = [];
                for (int i = 0; i < daysToShow; i++) {
                  final DateTime date = now.subtract(Duration(days: daysToShow - 1 - i));
                  spots.add(FlSpot(i.toDouble(), salesByDay[date.day] ?? 0.0));
                }

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final int dayIndex = value.toInt();
                            if (dayIndex >= 0 && dayIndex < daysToShow) {
                              final DateTime date = now.subtract(Duration(days: daysToShow - 1 - dayIndex));
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('₹ ${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    minX: 0,
                    maxX: (daysToShow - 1).toDouble(),
                    minY: 0,
                    maxY: salesByDay.values.isEmpty ? 100 : (salesByDay.values.reduce(max) * 1.2).ceilToDouble(), // Dynamic max Y
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.green, // Sales color
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withAlpha(77),
                              Colors.green.withAlpha(0),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: true),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Cash Flow Chart
          Container(
            height: 250, // Height for the chart
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ValueListenableBuilder(
              valueListenable: AppData.cashTransactionsBox.listenable(),
              builder: (context, Box<CashTransaction> cashBox, _) {
                final Map<int, double> netCashByDay = {};
                final DateTime now = DateTime.now();
                const int daysToShow = 7;

                // Initialize net cash for last 'daysToShow' to 0
                for (int i = 0; i < daysToShow; i++) {
                  final DateTime date = now.subtract(Duration(days: i));
                  netCashByDay[date.day] = 0.0;
                }

                // Aggregate cash transaction data
                for (final transaction in cashBox.values) {
                  final int transactionDay = transaction.date.day;
                  if (now.difference(transaction.date).inDays < daysToShow) { // Only consider transactions in last 7 days
                    if (transaction.type == 'Inflow') {
                      netCashByDay[transactionDay] = (netCashByDay[transactionDay] ?? 0.0) + transaction.amount;
                    } else if (transaction.type == 'Outflow') {
                      netCashByDay[transactionDay] = (netCashByDay[transactionDay] ?? 0.0) - transaction.amount;
                    }
                  }
                }

                // Convert net cash data to FlSpot list for the LineChart
                final List<FlSpot> spots = [];
                double runningBalance = 0.0; // Start with 0 balance for chart
                for (int i = 0; i < daysToShow; i++) {
                  final DateTime date = now.subtract(Duration(days: daysToShow - 1 - i));
                  runningBalance += netCashByDay[date.day] ?? 0.0;
                  spots.add(FlSpot(i.toDouble(), runningBalance));
                }

                // Determine min/max Y values for scaling
                double minY = spots.map((spot) => spot.y).reduce(min);
                double maxY = spots.map((spot) => spot.y).reduce(max);
                if (minY == maxY) { // Prevent division by zero if all values are same
                  minY -= 100;
                  maxY += 100;
                }

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final int dayIndex = value.toInt();
                            if (dayIndex >= 0 && dayIndex < daysToShow) {
                              final DateTime date = now.subtract(Duration(days: daysToShow - 1 - dayIndex));
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text('₹ ${value.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    minX: 0,
                    maxX: (daysToShow - 1).toDouble(),
                    minY: minY * 1.1, // Extend min/max for better visualization
                    maxY: maxY * 1.1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blue, // Cash flow color
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withAlpha(77),
                              Colors.blue.withAlpha(0),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<FlSpot> touchedSpots) {
                          return touchedSpots.map((FlSpot touchedSpot) {
                            return LineTooltipItem(
                              '₹ ${touchedSpot.y.toStringAsFixed(2)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),


          // --- Section 4: Quick Actions ---
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionButtonLocal(context, 'New Sale', Icons.add_shopping_cart, Colors.greenAccent, const SalesScreen()),
              _buildActionButtonLocal(context, 'New Purchase', Icons.shopping_basket, Colors.lightBlueAccent, const PurchaseScreen()),
              _buildActionButtonLocal(context, 'Generate Invoice', Icons.receipt, Colors.purpleAccent, const InvoiceScreen()),
              _buildActionButtonLocal(context, 'Add Expense', Icons.money_off, Colors.redAccent, const ExpenseScreen()),
              _buildActionButtonLocal(context, 'Cash Book', Icons.account_balance_wallet, Colors.blueGrey, const CashBookScreen()),
            ],
          ),
          const SizedBox(height: 24),

          // --- Section 5: Recent Activity ---
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 16),
          // Use ValueListenableBuilder to react to changes in relevant boxes
          ValueListenableBuilder(
            valueListenable: AppData.salesBox.listenable(),
            builder: (context, Box<Sale> salesBox, _) {
              return ValueListenableBuilder(
                valueListenable: AppData.purchasesBox.listenable(),
                builder: (context, Box<Purchase> purchasesBox, __) {
                  return ValueListenableBuilder(
                    valueListenable: AppData.cashTransactionsBox.listenable(),
                    builder: (context, Box<CashTransaction> cashBox, ___) {
                      // Get sales, purchases, and cash transactions
                      final List<Sale> sales = salesBox.values.toList();
                      final List<Purchase> purchases = purchasesBox.values.toList();
                      final List<Expense> expenses = AppData.expensesBox.values.toList();
                      final List<CashTransaction> cashTransactions = cashBox.values.toList();


                      // Combine all recent activities
                      final List<Map<String, dynamic>> allRecentActivities = [];
                      // Now using actual 'date' field from Sale and Purchase models
                      allRecentActivities.addAll(sales.map((s) => {'type': 'Sale', 'data': s, 'date': s.date}));
                      allRecentActivities.addAll(purchases.map((p) => {'type': 'Purchase', 'data': p, 'date': p.date}));
                      allRecentActivities.addAll(expenses.map((e) => {'type': 'Expense', 'data': e, 'date': e.date}));
                      allRecentActivities.addAll(cashTransactions.map((c) => {'type': 'Cash Transaction', 'data': c, 'date': c.date}));

                      // Sort descending by date (most recent first)
                      allRecentActivities.sort((a, b) {
                        return (b['date'] as DateTime).compareTo(a['date'] as DateTime);
                      });


                      const int displayLimit = 7; // Increased limit for more activity
                      final List<dynamic> recentActivities = allRecentActivities.take(displayLimit).toList();

                      if (recentActivities.isEmpty) {
                        return Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No recent activity. Add some sales, purchases, expenses, or cash transactions!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      } else {
                        return Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: recentActivities.length,
                            itemBuilder: (context, index) {
                              final activity = recentActivities[index];
                              final type = activity['type'];
                              final data = activity['data'];

                              // Display based on type
                              if (type == 'Sale') {
                                Sale sale = data as Sale;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: const Icon(Icons.trending_up, color: Colors.green),
                                    title: Text('Sale to ${sale.customerName}'),
                                    subtitle: Text('${sale.productName} (Qty: ${sale.quantity}) | Date: ${sale.date.day}/${sale.date.month}/${sale.date.year}'),
                                    trailing: Text('₹ ${sale.saleAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                );
                              } else if (type == 'Purchase') {
                                Purchase purchase = data as Purchase;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: const Icon(Icons.shopping_basket, color: Colors.orange),
                                    title: Text('Purchase from ${purchase.supplierName}'),
                                    subtitle: Text('${purchase.productName} (Qty: ${purchase.quantity}) | Date: ${purchase.date.day}/${purchase.date.month}/${purchase.date.year}'),
                                    trailing: Text('₹ ${purchase.purchaseAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ),
                                );
                              } else if (type == 'Expense') {
                                Expense expense = data as Expense;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: const Icon(Icons.money_off, color: Colors.red),
                                    title: Text('Expense: ${expense.description}'),
                                    subtitle: Text('Category: ${expense.category} | Date: ${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                                    trailing: Text('₹ ${expense.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                                  ),
                                );
                              } else if (type == 'Cash Transaction') {
                                CashTransaction transaction = data as CashTransaction;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: Icon(
                                      transaction.type == 'Inflow' ? Icons.account_balance_wallet : Icons.money_off_csred,
                                      color: transaction.type == 'Inflow' ? Colors.blue : Colors.deepOrange,
                                    ),
                                    title: Text('${transaction.type}: ${transaction.description}'),
                                    subtitle: Text('Category: ${transaction.category} | Date: ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}'),
                                    trailing: Text(
                                      '₹ ${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: transaction.type == 'Inflow' ? Colors.blue : Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
