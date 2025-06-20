// lib/models/models.dart
import 'package:hive/hive.dart';

part 'models.g.dart'; // This line is crucial for Hive generation

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id; // Unique ID for the product
  @HiveField(1)
  late String name;
  @HiveField(2)
  late double currentStock; // Represents the current quantity in stock
  @HiveField(3)
  late double unitPrice; // Selling price
  @HiveField(6) // Assign a new typeId
  late String unit;
  @HiveField(7) // Assign a new typeId
  late double purchasePrice;

  Product({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.unitPrice,
    required this.unit,
    required this.purchasePrice,
  });
}

@HiveType(typeId: 4) // Assign a unique typeId
class CashTransaction extends HiveObject {
  @HiveField(0)
  late String description;
  @HiveField(1)
  late double amount;
  @HiveField(2)
  late String type; // 'Inflow' or 'Outflow'
  @HiveField(3)
  late DateTime date;
  @HiveField(4)
  late String category;

  CashTransaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
  });
}

@HiveType(typeId: 1)
class Purchase extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String productId; // Link to the product via its ID
  @HiveField(2)
  late String productName; // For display convenience
  @HiveField(3)
  late double quantity;
  @HiveField(4)
  late double unitPrice;
  @HiveField(5)
  late double totalAmount; // Consistent with the new logic
  @HiveField(6)
  late DateTime purchaseDate; // Consistent with the new logic
  @HiveField(7)
  String? supplierId; // Optional: Link to a Party ID

  Purchase({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.purchaseDate,
    this.supplierId,
  });
}

@HiveType(typeId: 2)
class Party extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String type; // e.g., 'customer', 'supplier'
  @HiveField(3)
  late String contactNumber;
  @HiveField(4)
  late String address;
  @HiveField(5) // Added GST number field
  late String gstNumber; // New field for GST Number
  // Add other fields as needed, e.g., outstanding balance

  Party({
    required this.id,
    required this.name,
    required this.type,
    required this.contactNumber,
    required this.address,
    required this.gstNumber,
  });
}

@HiveType(typeId: 3)
class Sale extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late String productId;
  @HiveField(2)
  late String productName;
  @HiveField(3)
  late double quantity;
  @HiveField(4)
  late double unitPrice;
  @HiveField(5)
  late double totalAmount; // Consistent with the new logic
  @HiveField(6)
  late DateTime saleDate; // Consistent with the new logic
  @HiveField(7)
  String? customerId; // Optional: Link to Party ID

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
    this.customerId,
  });
}

@HiveType(typeId: 5) // Assign a unique typeId
class Expense extends HiveObject {
  @HiveField(0)
  late String description;
  @HiveField(1)
  late double amount;
  @HiveField(2)
  late DateTime date;
  @HiveField(3)
  late String category;

  Expense({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });
}
