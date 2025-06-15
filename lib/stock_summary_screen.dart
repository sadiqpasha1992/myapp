import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import 'package:myapp/data/app_data.dart'; // Import AppData for product data
import 'package:myapp/product_detail_screen.dart'; // We'll create this next for edit/delete

// StockSummaryScreen is now a StatefulWidget to handle search functionality.
class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  // Controller for the search input field
  final TextEditingController _searchController = TextEditingController();
  // State variable to hold the current search query
  String _searchQuery = '';

  // TextEditingControllers for adding new product fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for changes in the search input field
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // Method to save a new product to Hive
  void _saveProduct() async {
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
        quantity < 0 ||
        purchasePrice == null ||
        purchasePrice < 0 ||
        sellingPrice == null ||
        sellingPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid positive numbers for Quantity, Purchase Price, and Selling Price!',
          ),
        ),
      );
      return;
    }

    // Check for duplicate product name before adding
    final existingProducts = AppData.productsBox.values.toList();
    if (existingProducts.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product with this name already exists!')),
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
    await AppData.addProduct(newProduct);

    // Check if the widget is still mounted after the async operation
    if (!mounted) return;

    // Clear text fields after saving
    _productNameController.clear();
    _quantityController.clear();
    _unitController.clear();
    _purchasePriceController.clear();
    _sellingPriceController.clear();

    // Now it's safe to use context
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully!')),
    );
  }

  // Method to delete a product from Hive
  void _deleteProduct(int index, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete product "$productName"? This action cannot be undone and will affect related transactions (though transactions themselves won\'t be deleted).',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Capture the context before the async operation
                final currentContext = context;
                await AppData.deleteProduct(index);
                // Check if the widget is still mounted after the async operation
                if (currentContext.mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully!'),
                    ),
                  );
                }
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
            // --- Section: Add New Product ---
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

            // Unit Text Field
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

            // --- Section: Search Products ---
            const Text(
              'Search Products:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Product Name',
                hintText: 'e.g., Laptop',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.search),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 32),

            // --- Section: Displaying Stored Products ---
            ValueListenableBuilder(
              valueListenable: AppData.productsBox.listenable(),
              builder: (context, Box<Product> box, _) {
                // Get all products and apply search filter
                List<Product> products = box.values.toList();
                if (_searchQuery.isNotEmpty) {
                  products =
                      products
                          .where(
                            (product) => product.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Current Stock (${products.length})',
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
                              'No products match your search or no products added yet.',
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
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              // Get the actual Hive key for this product for editing/deleting
                              final int hiveIndex = box.keyAt(
                                box.values.toList().indexOf(product),
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
                                  onTap: () {
                                    // Navigate to ProductDetailScreen for editing/viewing
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProductDetailScreen(
                                              product: product,
                                              productIndex: hiveIndex,
                                            ),
                                      ),
                                    );
                                  },
                                  leading: Icon(
                                    Icons.inventory,
                                    color:
                                        product.quantity < 10
                                            ? Colors.red
                                            : Colors.teal,
                                  ),
                                  title: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          product.quantity < 10
                                              ? Colors.red
                                              : Colors.black, // Low stock alert
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Stock: ${product.quantity} ${product.unit}',
                                      ),
                                      Text(
                                        'Purchase Price: ₹ ${product.purchasePrice.toStringAsFixed(2)}',
                                      ),
                                      Text(
                                        'Selling Price: ₹ ${product.sellingPrice.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.grey,
                                    ),
                                    onPressed:
                                        () => _deleteProduct(
                                          hiveIndex,
                                          product.name,
                                        ),
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
