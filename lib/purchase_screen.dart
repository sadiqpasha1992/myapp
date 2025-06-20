// lib/purchase_screen.dart (Corrected - Body Only + Data Logic Fixes)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart'; // Ensure models.dart is imported for Product and Purchase
import 'package:myapp/purchase_detail_screen.dart'; // Import PurchaseDetailScreen
import 'package:uuid/uuid.dart'; // For generating unique IDs

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>(); // Added a Form key for validation
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController =
      TextEditingController(); // Changed from purchaseAmountController

  @override
  void dispose() {
    _supplierNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose(); // Dispose the correct controller
    super.dispose();
  }

  // Method to save a new purchase
  void _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    final String supplierName = _supplierNameController.text.trim();
    final String productName = _productNameController.text.trim();
    final int? quantity = int.tryParse(_quantityController.text.trim()); // Change to int
    final double? unitPrice = double.tryParse(_unitPriceController.text.trim());

    if (quantity == null || quantity <= 0) { // Check for valid positive int
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive quantity!'),
        ),
      );
      return;
    }
    if (unitPrice == null || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive unit price!'),
        ),
      );
      return;
    }

    // --- Stock Management: Increment product quantity or add new product ---
    Product? existingProduct;
    try {
      existingProduct = AppData.productsBox.values.firstWhere(
        (p) => p.name.toLowerCase() == productName.toLowerCase(),
      );
    } catch (e) {
      // Product not found, existingProduct remains null
    }

    if (existingProduct != null) {
      // Product found, update its currentStock and unitPrice
      existingProduct.currentStock += quantity; // Add quantity to stock
      existingProduct.unitPrice = unitPrice; // Update unit price with latest purchase price
      await existingProduct.save(); // Save changes to the existing HiveObject
    } else {
      // Product not found, create a new one
      final newProduct = Product(
        id: const Uuid().v4(), // Generate unique ID for the product
        name: productName,
        description: productName, // Add required description
        currentStock: quantity, // quantity is now int, use ! as validated
        unitPrice: unitPrice, // Add required unitPrice (sale price), use ! as validated
        purchasePrice: unitPrice, // Add required purchasePrice, use ! as validated
        unit: '', // Assuming a default empty string for unit
      );
      await AppData.productsBox.put(newProduct.id, newProduct); // Add new product to box
      existingProduct = newProduct; // Use the new product for the purchase link
    }
    // --- End Stock Management ---

    // Create a new Purchase object
    final newPurchase = Purchase(
      id: const Uuid().v4(), // Generate unique ID for the purchase
      productId: existingProduct.id, // Link to the product ID
      productName: productName, // Add required productName
      quantity: quantity, // quantity is now int, use ! as validated
      purchaseUnitPrice: unitPrice, // Add required purchaseUnitPrice, use ! as validated
      totalAmount: quantity * unitPrice, // Use int quantity and double unitPrice, use ! as validated
      purchaseDate: DateTime.now(),
      supplierId:
          supplierName.isNotEmpty
              ? supplierName
              : '', // Assign empty string if supplierName is empty
    );

    try {
      await AppData.addPurchase(
        newPurchase,
      ); // Use await since addPurchase updates Hive
      if (mounted) {
        // Clear text fields after saving
        _supplierNameController.clear();
        _productNameController.clear();
        _quantityController.clear();
        _unitPriceController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase saved successfully! Stock updated.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save purchase: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- IMPORTANT: Scaffold and AppBar have been REMOVED! ---
    return SingleChildScrollView(
      // Make the form and list scrollable
      padding: const EdgeInsets.all(16.0),
      child: Form(
        // Wrap with Form for validation
        key: _formKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align fields to the left
          children: [
            const Text(
              'Enter Purchase Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24), // Space
            // Supplier Name Text Field
            TextFormField(
              // Changed to TextFormField for validation
              controller: _supplierNameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name',
                hintText: 'e.g., Global Supplies Inc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.local_shipping),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter supplier name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16), // Space between fields
            // Product Name Text Field (You might want to make this a Product picker later)
            TextFormField(
              // Changed to TextFormField for validation
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Raw Material A',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity Text Field
            TextFormField(
              // Changed to TextFormField for validation
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 50',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (int.tryParse(value) == null || // Check for int
                    int.tryParse(value)! <= 0) { // Check for positive int
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Unit Price Text Field (was Purchase Amount)
            TextFormField(
              // Changed to TextFormField for validation
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Unit Price (Per Item)', // Clarified label
                hintText: 'e.g., 100.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter unit price';
                }
                if (double.tryParse(value) == null ||
                    double.tryParse(value)! <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24), // Space before button
            // Save Purchase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _savePurchase,
                icon: const Icon(Icons.save),
                label: const Text('Save Purchase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 32), // Space before the list of purchases
            // --- Section: Displaying Saved Purchases ---
            ValueListenableBuilder<Box<Purchase>>(
              valueListenable: AppData.purchasesBox.listenable(),
              builder: (context, Box<Purchase> box, _) {
                final List<Purchase> purchases = box.values.toList();
                purchases.sort(
                  (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
                ); // Corrected date field name

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Purchases (${purchases.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    purchases.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No purchases recorded yet. Add your first purchase above!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: purchases.length,
                          itemBuilder: (context, index) {
                            final purchase = purchases[index];
                            // For Hive objects, the key is what we used when putting it, or the object's index if added without a key.
                            // If using purchase.id as key, you can retrieve it with purchase.key.
                            // If you want the list index, it's just 'index'.
                            // For `PurchaseDetailScreen`, if it uses a Hive index, you might need to find the key or use a different approach.
                            // For simplicity, let's pass the purchase object directly.
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PurchaseDetailScreen(
                                            purchase: purchase,
                                            purchaseIndex:
                                                index, // Pass list index, PurchaseDetailScreen should handle this
                                          ),
                                    ),
                                  );
                                },
                                leading: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  '${purchase.supplierId} - ${purchase.productName}', // Use supplierId now
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Qty: ${purchase.quantity} | Amount: ₹ ${purchase.totalAmount.toStringAsFixed(2)} | Date: ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}', // Use totalAmount and purchaseDate
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
