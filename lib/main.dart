// lib/main.dart
import 'package:flutter/material.dart';

import 'package:myapp/data/app_data.dart';
// Ensure this is imported

// CORE SCREENS (used in bottom navigation)
// IMPORTANT: These must ONLY return their body content, NO Scaffold or AppBar.
import 'package:myapp/dashboard_screen.dart';
import 'package:myapp/sales_screen.dart';
import 'package:myapp/purchase_screen.dart';
import 'package:myapp/stock_summary_screen.dart'; // Your StockSummaryScreen with search
import 'package:myapp/parties_screen.dart';
import 'package:myapp/reports_screen.dart';

// QUICK ACTION SCREENS (navigated to via FAB - these CAN have their own Scaffold/AppBar)
import 'package:myapp/expense_screen.dart';
import 'package:myapp/invoice_screen.dart';
import 'package:myapp/edit_sale_screen.dart'; // If this is your add/edit sale form
import 'package:myapp/edit_purchase_screen.dart'; // If this is your add/edit purchase form
import 'package:myapp/product_detail_screen.dart'; // If this is your add/edit product form
// NEW IMPORTS FOR RETURNS
import 'package:myapp/returns_screen.dart'; // General returns overview (can be body-only or have Scaffold)
import 'package:myapp/sales_return_screen.dart'; // Specific sales return entry (should have Scaffold)
import 'package:myapp/purchase_return_screen.dart'; // Specific purchase return entry (should have Scaffold)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppData.initializeHive(); // Ensure Hive is initialized
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  static const List<String> _appBarTitles = <String>[
    'Dashboard',
    'Sales',
    'Purchases',
    'Stock Summary',
    'Parties',
    'Reports',
  ];

  // These are the screens that go into the BODY of the ONE main Scaffold.
  // They MUST NOT have their own Scaffold or AppBar.
  static const List<Widget> _widgetBodies = <Widget>[
    DashboardScreen(),
    SalesScreen(),
    PurchaseScreen(),
    StockSummaryScreen(), // This should be your StockSummaryScreen
    PartiesScreen(),
    ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Quick Actions Modal - now with correct navigation for returns
  void _showQuickActionsModal(BuildContext contextForModal) {
    showModalBottomSheet(
      context: contextForModal,
      builder: (BuildContext bc) {
        return SafeArea(
          // SafeArea ensures content is not hidden by notches/status bar
          child: Wrap(
            // Wrap widget helps manage multiple children in a flexible layout
            children: <Widget>[
              // Example Quick Action ListTile for adding a Sale
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.green),
                title: const Text('Add New Sale'),
                onTap: () {
                  Navigator.pop(bc); // Close bottom sheet
                  // Navigate to the screen for adding a new sale (e.g., EditSaleScreen without existing data)
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const EditSaleScreen(sale: null, saleIndex: null),
                    ),
                  );
                },
              ),
              // Example Quick Action ListTile for adding a Purchase
              ListTile(
                leading: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.orange,
                ),
                title: const Text('Add New Purchase'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the screen for adding a new purchase
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder:
                          (context) => const EditPurchaseScreen(
                            purchase: null,
                            purchaseIndex: null,
                          ),
                    ),
                  );
                },
              ),
              // Example Quick Action ListTile for adding a Party
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.purple),
                title: const Text('Add New Party'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the screen for adding a new party (assuming PartiesScreen itself has an add form or it navigates to one)
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const PartiesScreen(),
                    ),
                  );
                },
              ),
              // Example Quick Action ListTile for adding a Product
              ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.blue),
                title: const Text('Add New Product'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the screen for adding a new product
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder:
                          (context) => const ProductDetailScreen(
                            product: null,
                            productId: null, // Changed from productIndex
                          ),
                    ),
                  );
                },
              ),
              // Example Quick Action ListTile for adding an Expense
              ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('Add New Expense'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the screen for adding a new expense
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseScreen(),
                    ),
                  );
                },
              ),
              // Example Quick Action ListTile for generating an Invoice
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.teal),
                title: const Text('Generate Invoice'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the Invoice screen
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const InvoiceScreen(),
                    ),
                  );
                },
              ),
              // --- RETURN FEATURES ---
              // Add Sales Return
              ListTile(
                leading: const Icon(
                  Icons.assignment_return,
                  color: Colors.lightBlue,
                ),
                title: const Text('Add Sales Return'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the specific Sales Return form
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const SalesReturnScreen(),
                    ),
                  );
                },
              ),
              // Add Purchase Return
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.brown),
                title: const Text('Add Purchase Return'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the specific Purchase Return form
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseReturnScreen(),
                    ),
                  );
                },
              ),
              // View All Returns (General overview)
              ListTile(
                leading: const Icon(Icons.view_list, color: Colors.indigo),
                title: const Text('View All Returns'),
                onTap: () {
                  Navigator.pop(bc);
                  // Navigate to the general Returns overview screen
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const ReturnsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // The FAB is universal and always present
  FloatingActionButton? _getFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // This Builder ensures we get a context that is a descendant of the Scaffold
        // and thus has access to MaterialLocalizations, preventing previous errors.
        Builder(
          builder: (innerContext) {
            _showQuickActionsModal(innerContext);
            return const SizedBox.shrink(); // This builder doesn't render anything visible
          },
        );
      },
      backgroundColor: Colors.blueAccent, // Consistent FAB color
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizFlow App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        // THE ONE AND ONLY SCAFFOLD FOR THE MAIN NAVIGATION
        appBar: AppBar(
          title: Text(
            _appBarTitles[_selectedIndex],
          ), // Dynamic title based on selected tab
          backgroundColor: Colors.blueAccent, // Consistent app bar color
          foregroundColor: Colors.white,
        ),
        body: _widgetBodies.elementAt(
          _selectedIndex,
        ), // Display the body content of the selected screen
        floatingActionButton: _getFloatingActionButton(context),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Sales',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_shopping_cart),
              label: 'Purchases',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warehouse),
              label: 'Stock',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Parties'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
