// lib/main.dart
import 'package:flutter/material.dart';

import 'package:myapp/data/app_data.dart';
// Ensure this is imported

// CORE SCREENS (used in bottom navigation) - These should be BODY-ONLY
import 'package:myapp/dashboard_screen.dart';
import 'package:myapp/sales_screen.dart'; // Make sure the path is correct if different from root
import 'package:myapp/purchase_screen.dart'; // Make sure the path is correct
import 'package:myapp/stock_summary_screen.dart';
import 'package:myapp/reports_screen.dart';

// QUICK ACTION SCREENS (navigated to via FAB - these CAN have their own Scaffold/AppBar)
import 'package:myapp/expense_screen.dart';
import 'package:myapp/invoice_screen.dart';
// Used for 'Sale' Quick Action
// Used for 'Purchase' Quick Action
import 'package:myapp/product_detail_screen.dart'; // Used for 'Product' Quick Action
import 'package:myapp/returns_screen.dart';
import 'package:myapp/sales_return_screen.dart';
import 'package:myapp/purchase_return_screen.dart';
// Used for 'Party' Quick Action
import 'package:myapp/add_party_screen.dart'; // Used when adding a new party

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
    'Reports', // This title corresponds to the 5th item in BottomNavigationBar
  ];

  // These widgets are now body-only and DO NOT have their own Scaffold.
  static final List<Widget> _widgetBodies = <Widget>[
    const DashboardScreen(),
    const SalesScreen(),
    const PurchaseScreen(), // Corrected from PurchaseScreen to PurchasesScreen as per bottom nav
    const StockSummaryScreen(),
    const ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    // Guard against index out of bounds, though it shouldn't happen with fixed items
    if (index >= _widgetBodies.length) {
      _selectedIndex = 0; // Default to Dashboard if invalid index
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Quick Actions Modal function - Now correctly removes "Sale" and "Purchase" ListTiles
  void _showQuickActionsModal(BuildContext contextForModal) {
    showModalBottomSheet(
      context: contextForModal,
      isScrollControlled: true, // Allows content to be scrollable if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          // Added padding for better modal appearance
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // Used Column for direct children control
            mainAxisSize: MainAxisSize.min, // Make it wrap content tightly
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // === "Sale" and "Purchase" ListTiles have been REMOVED from here ===
              // They are already in the main BottomNavigationBar
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.purple),
                title: const Text('Party'),
                onTap: () {
                  Navigator.pop(bc); // Close the modal
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const AddPartyScreen(),
                    ), // Navigates to AddPartyScreen to add new
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.inventory_2,
                  color: Colors.blue,
                ), // Changed icon for clarity
                title: const Text('Product'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder:
                          (context) => const ProductDetailScreen(
                            product: null,
                          ), // For adding new product
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('Expense'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.teal),
                title: const Text('Generate Invoice'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const InvoiceScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.assignment_return,
                  color: Colors.lightBlue,
                ),
                title: const Text('Sales Return'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const SalesReturnScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.brown),
                title: const Text('Purchase Return'),
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseReturnScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_list, color: Colors.indigo),
                title: const Text('View All Returns'),
                onTap: () {
                  Navigator.pop(bc);
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
        // This is the ONE main Scaffold for the app
        appBar: AppBar(
          title: Text(_appBarTitles[_selectedIndex]),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          // Removed the title for dashboard for simplicity
          // You can customize app bar based on selected index if needed
        ),
        body: IndexedStack(
          // Use IndexedStack to preserve state of tabs
          index: _selectedIndex,
          children: _widgetBodies,
        ),
        floatingActionButton: Builder(
          builder: (contextForFab) {
            // This is the ONE Floating Action Button for the app
            return FloatingActionButton(
              onPressed: () {
                _showQuickActionsModal(contextForFab);
              },
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            );
          },
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.endFloat, // Place FAB at bottom right
        bottomNavigationBar: BottomNavigationBar(
          // This is the ONE Bottom Navigation Bar for the app
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
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800], // Highlight selected item
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Ensures all labels are shown
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: true, // Show labels for unselected items
        ),
      ),
    );
  }
}
