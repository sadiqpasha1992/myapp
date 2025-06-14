import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart'; // Import AppData for accessing Hive boxes
import 'package:intl/intl.dart'; // For date formatting (add this to pubspec.yaml if not there)

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for Sales and Purchase reports
  late TabController _tabController;

  // Date range filters
  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 30),
  ); // Default to last 30 days
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // 2 tabs: Sales, Purchases
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to select a date range
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Up to a year in future
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blueGrey, // Distinct color for reports
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sales Report', icon: Icon(Icons.trending_up)),
            Tab(text: 'Purchase Report', icon: Icon(Icons.shopping_basket)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter by Date: ${DateFormat('dd/MMM/yyyy').format(_startDate)} - ${DateFormat('dd/MMM/yyyy').format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDateRange(context),
                  tooltip: 'Select Date Range',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sales Report Tab
                _SalesReportTab(startDate: _startDate, endDate: _endDate),
                // Purchase Report Tab
                _PurchaseReportTab(startDate: _startDate, endDate: _endDate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sales Report Tab Content ---
class _SalesReportTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _SalesReportTab({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.salesBox.listenable(),
      builder: (context, Box<Sale> salesBox, _) {
        final List<Sale> sales = salesBox.values.toList();

        // Filter sales by date range
        final List<Sale> filteredSales =
            sales.where((sale) {
              final saleDate = DateTime(
                sale.date.year,
                sale.date.month,
                sale.date.day,
              ); // Normalize date to compare
              final start = DateTime(
                startDate.year,
                startDate.month,
                startDate.day,
              );
              final end = DateTime(endDate.year, endDate.month, endDate.day);
              return (saleDate.isAfter(
                    start.subtract(const Duration(days: 1)),
                  ) &&
                  saleDate.isBefore(end.add(const Duration(days: 1))));
            }).toList();

        // Sort filtered sales by date (most recent first)
        filteredSales.sort((a, b) => b.date.compareTo(a.date));

        // Calculate Total Sales Amount for the filtered period
        final double totalSalesAmount = filteredSales.fold(
          0.0,
          (sum, sale) => sum + sale.saleAmount,
        );

        // Declare the display variable here
        final String displaySalesAmount = '₹ ${totalSalesAmount.toStringAsFixed(2)}';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                color: Colors.green.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Sales in Period:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        displaySalesAmount, // Use the variable here
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  filteredSales.isEmpty
                      ? const Center(
                        child: Text(
                          'No sales recorded for this period.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long,
                                color: Colors.green,
                              ),
                              title: Text(
                                '${sale.customerName} - ${sale.productName}',
                              ),
                              subtitle: Text(
                                'Qty: ${sale.quantity} | Date: ${DateFormat('dd/MMM/yyyy').format(sale.date)}',
                              ),
                              trailing: Text(
                                '₹ ${sale.saleAmount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

// --- Purchase Report Tab Content ---
class _PurchaseReportTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const _PurchaseReportTab({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppData.purchasesBox.listenable(),
      builder: (context, Box<Purchase> purchasesBox, _) {
        final List<Purchase> purchases = purchasesBox.values.toList();

        // Filter purchases by date range
        final List<Purchase> filteredPurchases =
            purchases.where((purchase) {
              final purchaseDate = DateTime(
                purchase.date.year,
                purchase.date.month,
                purchase.date.day,
              ); // Normalize date to compare
              final start = DateTime(
                startDate.year,
                startDate.month,
                startDate.day,
              );
              final end = DateTime(endDate.year, endDate.month, endDate.day);
              return (purchaseDate.isAfter(
                    start.subtract(const Duration(days: 1)),
                  ) &&
                  purchaseDate.isBefore(end.add(const Duration(days: 1))));
            }).toList();

        // Sort filtered purchases by date (most recent first)
        filteredPurchases.sort((a, b) => b.date.compareTo(a.date));

        // Calculate Total Purchase Amount for the filtered period
        final double totalPurchaseAmount = filteredPurchases.fold(
          0.0,
          (sum, purchase) => sum + purchase.purchaseAmount,
        );

        // Declare the display variable here
        final String displayPurchaseAmount = '₹ ${totalPurchaseAmount.toStringAsFixed(2)}';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Card(
                color: Colors.orange.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Purchases in Period:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        displayPurchaseAmount, // Use the variable here
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  filteredPurchases.isEmpty
                      ? const Center(
                        child: Text(
                          'No purchases recorded for this period.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredPurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = filteredPurchases[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long,
                                color: Colors.orange,
                              ),
                              title: Text(
                                '${purchase.supplierName} - ${purchase.productName}',
                              ),
                              subtitle: Text(
                                'Qty: ${purchase.quantity} | Date: ${DateFormat('dd/MMM/yyyy').format(purchase.date)}',
                              ),
                              trailing: Text(
                                '₹ ${purchase.purchaseAmount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
