// lib/models/models.dart
import 'package:hive/hive.dart';

part 'models.g.dart'; // This line generates the adapter code

// === Sale Model ===
@HiveType(typeId: 0) // Ensure typeId is unique across all models
class Sale extends HiveObject {
  @HiveField(0)
  String id; // Add ID field
  @HiveField(1)
  String customerId; // Add customer ID field
  @HiveField(2)
  String productId; // Add product ID field
  @HiveField(3)
  int quantity; // Add quantity field
  @HiveField(4)
  double saleUnitPrice; // Add sale unit price field
  @HiveField(5)
  double totalAmount;
  @HiveField(6)
  DateTime saleDate;

  Sale({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.quantity,
    required this.saleUnitPrice,
    required this.totalAmount,
    required this.saleDate,
  });
}

// === Expense Model ===
@HiveType(typeId: 5) // Ensure this typeId is unique
class Expense extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String description;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String category; // Add category field

  Expense({
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
  });
}

// === Purchase Model ===
@HiveType(typeId: 1) // Ensure typeId is unique
class Purchase extends HiveObject {
  @HiveField(0)
  String id; // Add ID field
  @HiveField(1)
  String supplierId; // Add supplier ID field
  @HiveField(2)
  String productId; // Add product ID field
  @HiveField(3)
  int quantity; // Add quantity field
  @HiveField(4)
  double purchaseUnitPrice; // Add purchase unit price field
  @HiveField(5)
  double totalAmount;
  @HiveField(6)
  DateTime purchaseDate;
  @HiveField(7) // Add new field for product name
  String productName;

  Purchase({
    required this.id,
    required this.supplierId,
    required this.productId,
    required this.quantity,
    required this.purchaseUnitPrice,
    required this.totalAmount,
    required this.purchaseDate,
    required this.productName, // Add to constructor
  });
}

// === Product Model ===
@HiveType(typeId: 2) // Ensure typeId is unique
class Product extends HiveObject {
  @HiveField(0)
  String id; // Add ID field
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  double purchasePrice; // Add purchase price field
  @HiveField(4)
  double unitPrice; // Add unit price field (sale price)
  @HiveField(5)
  int currentStock; // Add current stock field
  @HiveField(6)
  String? unit; // e.g., 'kg', 'piece', 'liter'

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.purchasePrice,
    required this.unitPrice,
    required this.currentStock,
    this.unit,
  });
}

// === CashTransaction Model (for Cash Book) ===
@HiveType(typeId: 3) // Ensure typeId is unique
class CashTransaction extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String description;
  @HiveField(2)
  double amount;
  @HiveField(3)
  String type; // 'Credit' or 'Debit' (or 'Income' / 'Expense')

  CashTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}

// === Party Model === (Modified: email field added)
@HiveType(typeId: 4) // Ensure this typeId is unique
class Party extends HiveObject {
  @HiveField(0)
  String id; // Add ID field
  @HiveField(1)
  String name;
  @HiveField(2)
  String type; // 'Customer' or 'Vendor'
  @HiveField(3)
  String? phone; // This seems to be the contact number field
  @HiveField(4)
  String? address;
  @HiveField(5) // This field is for GST Number, as confirmed by you.
  String? gstNumber;
  @HiveField(
    6,
  ) // NEW FIELD for Email. Ensure this typeId is unique and sequential.
  String? email;

  Party({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.address,
    this.gstNumber,
    this.email, // Add to constructor
  });
}
