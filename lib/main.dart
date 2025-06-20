// lib/main.dart (Quick Actions Text Modified)
import 'package:flutter/material.dart';

import 'package:myapp/data/app_data.dart';
// Ensure this is imported

// CORE SCREENS (used in bottom navigation) - MUST BE BODY-ONLY
import 'package:myapp/dashboard_screen.dart';
import 'package:myapp/sales_screen.dart';
import 'package:myapp/purchase_screen.dart';
import 'package:myapp/stock_summary_screen.dart';
import 'package:myapp/reports_screen.dart';

// QUICK ACTION SCREENS (navigated to via FAB - these CAN have their own Scaffold/AppBar)
import 'package:myapp/expense_screen.dart';
import 'package:myapp/invoice_screen.dart';
import 'package:myapp/edit_sale_screen.dart';
import 'package:myapp/edit_purchase_screen.dart';
import 'package:myapp/product_detail_screen.dart';
import 'package:myapp/returns_screen.dart';
import 'package:myapp/sales_return_screen.dart';
import 'package:myapp/purchase_return_screen.dart';
import 'package:myapp/parties_screen.dart';

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
    'Reports',
  ];

  static const List<Widget> _widgetBodies = <Widget>[
    DashboardScreen(),
    SalesScreen(),
    PurchaseScreen(),
    StockSummaryScreen(),
    ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index >= _widgetBodies.length) {
      _selectedIndex = 0;
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Quick Actions Modal function - Text updated
  void _showQuickActionsModal(BuildContext contextForModal) {
    showModalBottomSheet(
      context: contextForModal,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.green),
                title: const Text('Sale'), // Text changed
                onTap: () {
                  Navigator.pop(bc);
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
              ListTile(
                leading: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.orange,
                ),
                title: const Text('Purchase'), // Text changed
                onTap: () {
                  Navigator.pop(bc);
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
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.purple),
                title: const Text('Party'), // Text changed
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder: (context) => const PartiesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.blue),
                title: const Text('Product'), // Text changed
                onTap: () {
                  Navigator.pop(bc);
                  Navigator.push(
                    contextForModal,
                    MaterialPageRoute(
                      builder:
                          (context) => const ProductDetailScreen(
                            product: null,
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('Expense'), // Text changed
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
                title: const Text(
                  'Generate Invoice',
                ), // Text not changed, as 'Generate' is part of the action
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
                title: const Text('Sales Return'), // Text changed
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
                title: const Text('Purchase Return'), // Text changed
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
                title: const Text(
                  'View All Returns',
                ), // Text not changed, as 'View All' is part of the action
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
        appBar: AppBar(
          title: Text(_appBarTitles[_selectedIndex]),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: _widgetBodies.elementAt(_selectedIndex),
        floatingActionButton: Builder(
          builder: (contextForFab) {
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
