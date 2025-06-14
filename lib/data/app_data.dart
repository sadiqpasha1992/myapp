// This file will hold shared data that multiple screens need to access.

import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter for annotations and Box operations
import 'package:logger/logger.dart';

part 'app_data.g.dart'; // Ensure this line is present and exactly as shown.

// Important: Every class you want to store in Hive needs a unique @HiveType(typeId: ...)
// The typeId must be a unique integer between 0 and 223.

// Define the Party class for Hive.
@HiveType(typeId: 0) // Unique ID for Party class
class Party {
  @HiveField(0) // Unique ID for each field within this class
  final String name;
  @HiveField(1)
  final String gstNumber;
  @HiveField(2)
  final String address;
  @HiveField(3)
  final String contact;
  @HiveField(4)
  final String type; // 'Customer' or 'Supplier'

  Party({
    required this.name,
    required this.gstNumber,
    required this.address,
    required this.contact,
    required this.type,
  });
}

// Define the Product class for Hive.
@HiveType(
  typeId: 1,
) // Unique ID for Product class (must be different from Party's ID)
class Product {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final double quantity; // Using double for quantity to allow fractional units
  @HiveField(2)
  final String unit;
  @HiveField(3)
  final double purchasePrice;
  @HiveField(4)
  final double sellingPrice;

  Product({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
  });
}

// Define the Sale class for Hive.
@HiveType(typeId: 2) // Unique ID for Sale class
class Sale {
  @HiveField(0)
  final String customerName;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final double quantity;
  @HiveField(3)
  final double saleAmount;
  @HiveField(4) // NEW: Date of sale
  final DateTime date;

  Sale({
    required this.customerName,
    required this.productName,
    required this.quantity,
    required this.saleAmount,
    required this.date, // NEW: Require date
  });
}

// Define the Expense class for Hive.
@HiveType(typeId: 3) // Unique ID for Expense class
class Expense {
  @HiveField(0)
  final String description;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final DateTime date;

  Expense({
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });
}

// Define the Purchase class for Hive.
@HiveType(typeId: 4) // Unique ID for Purchase class
class Purchase {
  @HiveField(0)
  final String supplierName;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final double quantity;
  @HiveField(3)
  final double purchaseAmount;
  @HiveField(4) // NEW: Date of purchase
  final DateTime date;

  Purchase({
    required this.supplierName,
    required this.productName,
    required this.quantity,
    required this.purchaseAmount,
    required this.date, // NEW: Require date
  });
}

// Define the CashTransaction class for Hive.
@HiveType(typeId: 5) // Unique ID for CashTransaction class
class CashTransaction {
  @HiveField(0)
  final String description;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String type; // 'Inflow' or 'Outflow'
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String category; // e.g., 'Sales Payment', 'Loan', 'Electricity Bill'

  CashTransaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
  });
}

// This class will now manage our Hive Boxes for data persistence.
class AppData {
  static final logger = Logger();
  static late Box<Party> partiesBox;
  static late Box<Product> productsBox;
  static late Box<Sale> salesBox;
  static late Box<Expense> expensesBox;
  static late Box<Purchase> purchasesBox;
  static late Box<CashTransaction> cashTransactionsBox;

  // This method will be called once when the app starts to open all our Hive boxes.
  static Future<void> init() async {
    logger.i('AppData.init: Starting Hive box opening...');
    partiesBox = await Hive.openBox<Party>('parties');
    productsBox = await Hive.openBox<Product>('products');
    salesBox = await Hive.openBox<Sale>('sales');
    expensesBox = await Hive.openBox<Expense>('expenses');
    purchasesBox = await Hive.openBox<Purchase>('purchases');
    cashTransactionsBox = await Hive.openBox<CashTransaction>(
      'cashTransactions',
    );
    logger.i('AppData.init: All Hive boxes opened.');
  }

  // --- Party Operations ---
  static List<Party> getParties() {
    return partiesBox.values.toList();
  }

  static Future<void> addParty(Party party) async {
    await partiesBox.add(party);
  }

  static Future<void> deleteParty(int index) async {
    await partiesBox.deleteAt(index);
  }

  // --- Product Operations ---
  static List<Product> getProducts() {
    return productsBox.values.toList();
  }

  static Future<void> addProduct(Product product) async {
    await productsBox.add(product);
  }

  static Future<void> deleteProduct(int index) async {
    await productsBox.deleteAt(index);
  }

  // --- Sale Operations ---
  static List<Sale> getSales() {
    return salesBox.values.toList();
  }

  static Future<void> addSale(Sale sale) async {
    await salesBox.add(sale);
  }

  // --- Expense Operations ---
  static List<Expense> getExpenses() {
    return expensesBox.values.toList();
  }

  static Future<void> addExpense(Expense expense) async {
    await expensesBox.add(expense);
  }

  static Future<void> deleteExpense(int index) async {
    await expensesBox.deleteAt(index);
  }

  // --- Purchase Operations ---
  static List<Purchase> getPurchases() {
    return purchasesBox.values.toList();
  }

  static Future<void> addPurchase(Purchase purchase) async {
    await purchasesBox.add(purchase);
  }

  static Future<void> deletePurchase(int index) async {
    await purchasesBox.deleteAt(index);
  }

  // --- CashTransaction Operations ---
  static List<CashTransaction> getCashTransactions() {
    return cashTransactionsBox.values.toList();
  }

  static Future<void> addCashTransaction(CashTransaction transaction) async {
    await cashTransactionsBox.add(transaction);
  }

  static Future<void> deleteCashTransaction(int index) async {
    await cashTransactionsBox.deleteAt(index);
  }
}
