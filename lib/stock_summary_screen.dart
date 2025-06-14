import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import '../data/app_data.dart'; // Import our shared data file

// Product class is defined in app_data.dart

// StockSummaryScreen is now a StatefulWidget because its content (form fields and the list of products)
// will change over time based on user interaction.
class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

// This is the "State" class that holds the changeable data for StockSummaryScreen.
class _StockSummaryScreenState extends State<StockSummaryScreen> {
  // TextEditingControllers for product input fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  // We no longer need a local List<Product> here, as data will come directly from Hive.
  // final List<Product> _productsList = [];

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // Method to save a new product
  void _saveProduct() {
    final String name = _productNameController.text.trim();
    final String quantityStr = _quantityController.text.trim();
    final String unit = _unitController.text.trim();
    final String purchasePriceStr = _purchasePriceController.text.trim();
    final String sellingPriceStr = _sellingPriceController.text.trim();

    // Basic validation
    if (name.isEmpty ||
        quantityStr.isEmpty ||
        unit.isEmpty ||
        purchasePriceStr.isEmpty ||
        sellingPriceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all product details!')),
      );
      return;
    }

    final double? quantity = double.tryParse(quantityStr);
    final double? purchasePrice = double.tryParse(purchasePriceStr);
    final double? sellingPrice = double.tryParse(sellingPriceStr);

    if (quantity == null ||
        purchasePrice == null ||
        sellingPrice == null ||
        quantity <= 0 ||
        purchasePrice <= 0 ||
        sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid positive numbers for quantity and prices!',
          ),
        ),
      );
      return;
    }

    // Create new Product object
    final newProduct = Product(
      name: name,
      quantity: quantity,
      unit: unit,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
    );

    // Add to the Hive Box using AppData
    AppData.addProduct(newProduct)
        .then((_) {
          // Check if the widget is still mounted before using context
          if (!mounted) return;

          // Clear text fields after saving
          _productNameController.clear();
          _quantityController.clear();
          _unitController.clear();
          _purchasePriceController.clear();
          _sellingPriceController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        })
        .catchError((error) {
          // Check if the widget is still mounted before using context
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: $error')),
          );
        });
  }

  // Method to delete a product
  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use dialogContext to avoid confusion
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          // Access product details directly from the box for the dialog content
          content: Text(
            'Are you sure you want to delete "${AppData.productsBox.getAt(index)?.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog before the async delete operation
                Navigator.of(dialogContext).pop();

                // Delete from the Hive Box using AppData
                AppData.deleteProduct(index)
                    .then((_) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product deleted successfully!'),
                        ),
                      );
                    })
                    .catchError((error) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete product: $error'),
                        ),
                      );
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Summary'),
        backgroundColor: Colors.teal, // Distinct color for Stock Summary
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Product:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Product Name Text Field
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Organic Coffee Beans',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Quantity Text Field
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Unit Text Field (for now, simple text input for unit)
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit (e.g., Pcs, Kg, Ltr)',
                hintText: 'e.g., Kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Purchase Price Text Field
            TextField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price (per unit)',
                hintText: 'e.g., 500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Selling Price Text Field
            TextField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price (per unit)',
                hintText: 'e.g., 750.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.sell),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Save Product Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.add_box),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Section: Displaying Stored Products ---
            // Use ValueListenableBuilder to automatically rebuild when Hive box changes
            ValueListenableBuilder(
              valueListenable:
                  AppData.productsBox
                      .listenable(), // Listen for changes in the 'products' box
              builder: (context, Box<Product> box, _) {
                // Get the current list of products from the box
                final List<Product> products = box.values.toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Current Stock (${products.length})', // Shows count of products from Hive
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    products.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No products added yet. Add your first product above!',
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
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount:
                                products.length, // Use the list from Hive
                            itemBuilder: (context, index) {
                              final product =
                                  products[index]; // Use the product from Hive

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Quantity: ${product.quantity} ${product.unit}',
                                            ),
                                            Text(
                                              'Purchase Price: ₹ ${product.purchasePrice.toStringAsFixed(2)}',
                                            ),
                                            Text(
                                              'Selling Price: ₹ ${product.sellingPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        // Delete icon button
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteProduct(
                                              index,
                                            ), // Call delete method
                                        tooltip: 'Delete Product',
                                      ),
                                    ],
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
