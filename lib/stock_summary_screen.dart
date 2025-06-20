// lib/stock_summary_screen.dart (Corrected - Body Only + Data Logic Fixes)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart'; // Import models.dart for Product
import 'package:myapp/product_detail_screen.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  final _formKey = GlobalKey<FormState>(); // Added a Form key for validation
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController(); // Add description controller
  final TextEditingController _currentStockController =
      TextEditingController(); // Renamed to currentStock
  final TextEditingController _unitPriceController =
      TextEditingController(); // Renamed to unitPrice (replaces purchase/selling price)
  final TextEditingController _unitController = TextEditingController(); // Add unit controller
  final TextEditingController _purchasePriceController = TextEditingController(); // Add purchase price controller

  @override
  void initState() {
    super.initState();
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
    _descriptionController.dispose(); // Dispose description controller
    _currentStockController.dispose(); // Dispose correct controller
    _unitPriceController.dispose(); // Dispose correct controller
    _unitController.dispose(); // Dispose unit controller
    _purchasePriceController.dispose(); // Dispose purchase price controller
    super.dispose();
  }

  // Method to save a new product to Hive
  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    final String name = _productNameController.text.trim();
    final String description = _descriptionController.text.trim(); // Get description value
    final double? currentStockDouble = double.tryParse( // Parse as double first
      _currentStockController.text.trim(),
    );
    final double? unitPrice = double.tryParse(_unitPriceController.text.trim());
    final String unit = _unitController.text.trim(); // Get unit value
    final double? purchasePrice = double.tryParse(_purchasePriceController.text.trim()); // Get purchase price value


    if (description.isEmpty) { // Validate description
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the description!'),
        ),
      );
      return;
    }

    if (currentStockDouble == null || currentStockDouble < 0) { // Check double parse result
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid non-negative number for Current Stock!',
          ),
        ),
      );
      return;
    }

    if (unitPrice == null || unitPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid non-negative number for Unit Price!',
          ),
        ),
      );
      return;
    }

    if (unit.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the unit!'),
        ),
      );
      return;
    }

     if (purchasePrice == null || purchasePrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid non-negative number for Purchase Price!',
          ),
        ),
      );
      return;
    }

    // Check for duplicate product name before adding
    final bool productExists = AppData.productsBox.values.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );

    if (productExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product with this name already exists! Consider editing it.',
          ),
        ),
      );
      return; // Return if product exists
    }
  
    final int currentStock = currentStockDouble.toInt(); // Convert to int

    // Create new Product object
    final newProduct = Product(
      id: const Uuid().v4(), // Generate unique ID
      name: name,
      description: description, // Pass description
      currentStock: currentStock, // Pass converted int
      unitPrice: unitPrice,
      unit: unit, // Pass unit
      purchasePrice: purchasePrice, // Pass purchasePrice
    );

    try {
      await AppData.addProduct(newProduct); // Use await
      if (!mounted) return;

      // Clear text fields after saving
      _productNameController.clear();
      _currentStockController.clear();
      _unitPriceController.clear();
      _unitController.clear();
      _purchasePriceController.clear();


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
      }
    }
  }

  // Method to delete a product from Hive by its ID
  void _deleteProduct(String productId, String productName) {
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
                final currentContext = context; // Capture context
                try {
                  await AppData.deleteProduct(productId); // Delete by ID
                  if (currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Product deleted successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text('Failed to delete product: $e')),
                    );
                  }
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
    // --- IMPORTANT: Scaffold and AppBar have been REMOVED! ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        // Wrap with Form for validation
        key: _formKey,
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
            TextFormField(
              // Changed to TextFormField for validation
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Text Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., High-quality Arabica beans',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.description),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16), // Space

            // Current Stock Text Field
            TextFormField(
              // Changed to TextFormField for validation
              controller: _currentStockController,
              decoration: const InputDecoration(
                labelText: 'Current Stock',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter current stock';
                }
                if (double.tryParse(value) == null ||
                    double.tryParse(value)! < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Unit Price Text Field (replaces purchase/selling price)
            TextFormField(
              // Changed to TextFormField for validation
              controller: _unitPriceController,
              decoration: const InputDecoration(
                labelText:
                    'Unit Price (Current Selling Price)', // Clarified label
                hintText: 'e.g., 750.00',
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
                    double.tryParse(value)! < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16), // Space

            // Unit Text Field
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g., kg, pcs, liters',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter unit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16), // Space

            // Purchase Price Text Field
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                hintText: 'e.g., 500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.arrow_downward),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter purchase price';
                }
                 if (double.tryParse(value) == null ||
                    double.tryParse(value)! < 0) {
                  return 'Please enter a valid non-negative number';
                }
                return null;
              },
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
            ValueListenableBuilder<Box<Product>>(
              valueListenable: AppData.productsBox.listenable(),
              builder: (context, Box<Product> box, _) {
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
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            // For passing to ProductDetailScreen, pass the product object directly,
                            // or its ID if ProductDetailScreen retrieves it from Hive by ID.
                            // For deletion, use product.id.
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
                                          (context) => ProductDetailScreen(
                                            product: product,
                                            // We don't need `productIndex` if ProductDetailScreen works with ID
                                            // but if you implemented it to use index, you'd need `box.keyAt(index)` or `index` if it's based on filtered list index.
                                            // For now, removing `productIndex` from here assumes ProductDetailScreen takes `Product` object.
                                            // If ProductDetailScreen expects an int index for direct Hive access, you'll need to rethink its implementation.
                                          ),
                                    ),
                                  );
                                },
                                leading: Icon(
                                  Icons.inventory,
                                  color:
                                      product.currentStock < 10
                                          ? Colors.red
                                          : Colors.teal,
                                ),
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        product.currentStock < 10
                                            ? Colors.red
                                            : Colors.black, // Low stock alert
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Stock: ${product.currentStock}',
                                    ), // Corrected field name
                                    Text(
                                      'Unit Price: ₹ ${product.unitPrice.toStringAsFixed(2)}',
                                    ), // Corrected field name
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.grey,
                                  ),
                                  onPressed:
                                      () => _deleteProduct(
                                        product
                                            .id, // Pass the product's ID for deletion
                                        product.name,
                                      ),
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
