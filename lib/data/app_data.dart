// lib/data/app_data.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/models.dart'; // Import all your models

class AppData {
  // Static fields to hold references to your Hive boxes
  static late Box<Product> productsBox;
  static late Box<Purchase> purchasesBox;
  static late Box<Party> partiesBox;
  static late Box<Sale> salesBox;
  static late Box<CashTransaction> cashTransactionsBox; // Add CashTransaction box
  static late Box<Expense> expensesBox; // Add Expense box

  // Initialize all Hive boxes
  static Future<void> initializeHive() async {
    // Ensure Hive is initialized before opening boxes
    await Hive.initFlutter();

    // Register adapters for all your models
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(PurchaseAdapter());
    Hive.registerAdapter(PartyAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CashTransactionAdapter()); // Register CashTransaction adapter
    Hive.registerAdapter(ExpenseAdapter()); // Register Expense adapter

    // Open your boxes
    productsBox = await Hive.openBox<Product>('products');
    purchasesBox = await Hive.openBox<Purchase>('purchases');
    partiesBox = await Hive.openBox<Party>('parties');
    salesBox = await Hive.openBox<Sale>('sales');
    cashTransactionsBox = await Hive.openBox<CashTransaction>('cashTransactions'); // Open CashTransaction box
    expensesBox = await Hive.openBox<Expense>('expenses'); // Open Expense box
  }

  // --- Product Management ---
  static Future<void> addProduct(Product product) async {
    await productsBox.put(product.id, product); // Use product.id as the key
  }

  static Product? getProduct(String id) {
    return productsBox.get(id); // Retrieve by ID
  }

  static Future<void> updateProduct(Product product) async {
    // When you call .save() on a HiveObject, it automatically updates itself in its box.
    await product.save();
  }

  static Future<void> deleteProduct(String id) async {
    await productsBox.delete(id); // Delete by ID
  }

  // --- Purchase Management ---
  static Future<void> addPurchase(Purchase purchase) async {
    await purchasesBox.put(purchase.id, purchase); // Use purchase.id as the key
  }

  static Purchase? getPurchase(String id) {
    return purchasesBox.get(id); // Retrieve by ID
  }

  static Future<void> updatePurchase(Purchase purchase) async {
    await purchase.save();
  }

  static Future<void> deletePurchase(String id) async {
    await purchasesBox.delete(id); // Delete by ID
  }

  // --- Party Management ---
  static Future<void> addParty(Party party) async {
    await partiesBox.put(party.id, party);
  }

  static Future<void> deleteParty(String id) async { // Changed to accept String id
    await partiesBox.delete(id);
  }

  // --- Sale Management ---
  static Future<void> addSale(Sale sale) async {
    await salesBox.put(sale.id, sale);
  }

  static Future<void> deleteSale(String id) async {
    await salesBox.delete(id);
  }

  // --- Cash Transaction Management ---
  static Future<void> addCashTransaction(CashTransaction transaction) async {
    await cashTransactionsBox.add(transaction); // Use add for auto-incrementing key
  }

  static Future<void> deleteCashTransaction(int index) async {
    await cashTransactionsBox.deleteAt(index); // Delete by index
  }

  // --- Expense Management ---
  static Future<void> addExpense(Expense expense) async {
    await expensesBox.add(expense); // Use add for auto-incrementing key
  }

  static Future<void> deleteExpense(int index) async {
    await expensesBox.deleteAt(index); // Delete by index
  }
}
