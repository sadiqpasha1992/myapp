import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import 'package:myapp/data/app_data.dart'; // Import our shared data file
import 'package:myapp/purchase_detail_screen.dart'; // Import PurchaseDetailScreen

// Purchase class is defined in app_data.dart

// PurchaseScreen is now a StatefulWidget because its content (form fields and the list of purchases)
// will change over time based on user interaction.
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

// This is the "State" class that holds the changeable data for PurchaseScreen.
class _PurchaseScreenState extends State<PurchaseScreen> {
  // TextEditingControllers for purchase input fields
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchaseAmountController =
      TextEditingController();

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _supplierNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _purchaseAmountController.dispose();
    super.dispose();
  }

  // Method to save a new purchase
  void _savePurchase() async {
    // Made async to await stock update
    final String supplierName = _supplierNameController.text.trim();
    final String productName = _productNameController.text.trim();
    final String quantityStr = _quantityController.text.trim(); // Get as string
    final String purchaseAmount = _purchaseAmountController.text.trim();

    // Basic validation: Check if fields are not empty
    if (supplierName.isEmpty ||
        productName.isEmpty ||
        quantityStr.isEmpty ||
        purchaseAmount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
      return;
    }

    final double? purchasedQuantity = double.tryParse(quantityStr);
    if (purchasedQuantity == null || purchasedQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive quantity!'),
        ),
      );
      return;
    }

    // --- Stock Management: Increment product quantity or add new product ---
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int productIndex = productsInStock.indexWhere(
      (p) => p.name.toLowerCase() == productName.toLowerCase(),
    );

    if (productIndex != -1) {
      // Product found, update its quantity
      final Product existingProduct = productsInStock[productIndex];
      final updatedProduct = Product(
        name: existingProduct.name,
        quantity:
            existingProduct.quantity + purchasedQuantity, // Increment quantity
        unit: existingProduct.unit, // Keep existing unit
        purchasePrice:
            existingProduct.purchasePrice, // Keep existing purchase price
        sellingPrice:
            existingProduct.sellingPrice, // Keep existing selling price
      );
      // Update the product in Hive
      await AppData.productsBox.putAt(productIndex, updatedProduct);
    } else {
      // Product not found, add it to stock with the purchased quantity
      final newProduct = Product(
        name: productName,
        quantity: purchasedQuantity,
        unit: 'Pcs', // Default unit for new product
        purchasePrice:
            double.tryParse(purchaseAmount) ??
            0.0, // Use purchase amount as initial purchase price
        sellingPrice:
            (double.tryParse(purchaseAmount) ?? 0.0) *
            1.2, // Example: 20% markup for selling price
      );
      await AppData.productsBox.add(newProduct);
    }
    // --- End Stock Management ---

    // Create a new Purchase object
    final newPurchase = Purchase(
      supplierName: supplierName,
      productName: productName,
      quantity: purchasedQuantity, // Use the parsed double quantity
      purchaseAmount: double.tryParse(purchaseAmount) ?? 0.0,
      date: DateTime.now(), // Record the current date and time
    );

    // Add to the Hive Box using AppData
    AppData.addPurchase(newPurchase)
        .then((_) {
          if (!mounted) return;

          // Clear text fields after saving
          _supplierNameController.clear();
          _productNameController.clear();
          _quantityController.clear();
          _purchaseAmountController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase saved successfully! Stock updated.'),
            ),
          );
        })
        .catchError((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save purchase: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        backgroundColor: Colors.orange, // Distinct color for Purchase
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Make the form and list scrollable
        padding: const EdgeInsets.all(16.0),
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
            TextField(
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
            ),
            const SizedBox(height: 16), // Space between fields
            // Product Name Text Field
            TextField(
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
            ),
            const SizedBox(height: 16),

            // Quantity Text Field
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 50',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number, // Suggests a numeric keyboard
            ),
            const SizedBox(height: 16),

            // Purchase Amount Text Field
            TextField(
              controller: _purchaseAmountController,
              decoration: const InputDecoration(
                labelText: 'Purchase Amount',
                hintText: 'e.g., 5000.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                ), // Or Icons.attach_money for dollar
              ),
              keyboardType: TextInputType.number, // Suggests a numeric keyboard
            ),
            const SizedBox(height: 24), // Space before button
            // Save Purchase Button
            SizedBox(
              // Use SizedBox to give the button a specific width
              width: double.infinity, // Makes the button take full width
              child: ElevatedButton.icon(
                onPressed: _savePurchase, // Call our save function when pressed
                icon: const Icon(Icons.save),
                label: const Text('Save Purchase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Button background color
                  foregroundColor: Colors.white, // Button text/icon color
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ), // Vertical padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Rounded corners for button
                  ),
                  textStyle: const TextStyle(fontSize: 18), // Text size
                ),
              ),
            ),

            const SizedBox(height: 32), // Space before the list of purchases
            // --- Section: Displaying Saved Purchases ---
            // Use ValueListenableBuilder to automatically rebuild when Hive box changes
            ValueListenableBuilder(
              valueListenable:
                  AppData.purchasesBox
                      .listenable(), // Listen for changes in the 'purchases' box
              builder: (context, Box<Purchase> box, _) {
                // Get the current list of purchases from the box
                final List<Purchase> purchases = box.values.toList();
                // Sort by date (most recent first)
                purchases.sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Purchases (${purchases.length})', // Shows count of purchases from Hive
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
                        : Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height *
                                0.5, // Max height of the list
                          ),
                          child: ListView.builder(
                            shrinkWrap:
                                true, // Makes ListView take only necessary space
                            physics:
                                const ClampingScrollPhysics(), // Allows inner scrolling without issues
                            itemCount:
                                purchases.length, // Use the list from Hive
                            itemBuilder: (context, index) {
                              // For each item in purchases, build a Card
                              final purchase =
                                  purchases[index]; // Use the purchase from Hive
                              // Get the actual Hive key/index for this item
                              final int hiveIndex = AppData.purchasesBox.keyAt(
                                index,
                              );

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  // Changed from Padding/Row to ListTile for tap
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => PurchaseDetailScreen(
                                              purchase: purchase,
                                              purchaseIndex:
                                                  hiveIndex, // NEW: Pass the Hive index
                                            ),
                                      ),
                                    );
                                  },
                                  leading: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    '${purchase.supplierName} - ${purchase.productName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Qty: ${purchase.quantity} | Amount: ₹ ${purchase.purchaseAmount} | Date: ${purchase.date.day}/${purchase.date.month}/${purchase.date.year}',
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
