// lib/sales_screen.dart (Corrected)
import 'package:flutter/material.dart';
// Import other necessary files like app_data.dart, models.dart, etc.
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart';
import 'package:uuid/uuid.dart'; // If you use Uuid for IDs
import 'package:hive_flutter/hive_flutter.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
  }); // Remove the old constructor if it took sale/saleIndex

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // ... (Keep all your existing controllers, methods like _saveSale, etc.) ...
  final _formKey = GlobalKey<FormState>(); // Example if you use a Form
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  Product? _selectedProduct; // To store the selected product for calculations

  @override
  void initState() {
    super.initState();
    // Initialize fields if editing an existing sale, otherwise leave empty
    // For 'Add New Sale', these will be empty.
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  // Example for handling product selection and updating unit price
  void _onProductSelected(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _unitPriceController.text = product.unitPrice.toStringAsFixed(2);
      } else {
        _unitPriceController.clear();
      }
    });
  }

  void _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product.')));
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    final totalAmount = quantity * unitPrice;

    if (quantity <= 0 || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity and Unit Price must be positive numbers.'),
        ),
      );
      return;
    }

    // Check if enough stock is available
    if (_selectedProduct!.currentStock < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient stock for ${_selectedProduct!.name}. Available: ${_selectedProduct!.currentStock}.',
          ),
        ),
      );
      return;
    }

    final newSale = Sale(
      id: const Uuid().v4(), // Generate a unique ID for the sale
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      saleDate: DateTime.now(),
      // customerId: _customerNameController.text.isNotEmpty ? _customerNameController.text : null, // If you link to Party
    );

    try {
      AppData.addSale(newSale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale saved successfully! Stock updated.'),
          ),
        );
        // Clear fields after successful save
        _customerNameController.clear();
        _productNameController.clear(); // Clear product name field
        _quantityController.clear();
        _unitPriceController.clear();
        setState(() {
          _selectedProduct = null; // Clear selected product
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save sale: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- IMPORTANT: REMOVED Scaffold and AppBar here! ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        // Wrap your content in a Form if you're using GlobalKey<FormState>
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Sale',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Your Customer Name field (if directly entered, not from Parties list)
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),

            // Product Selection (using DropdownButtonFormField as an example)
            // You'll need to fetch products from AppData.productsBox
            // Example:
            ValueListenableBuilder<Box<Product>>(
              valueListenable: AppData.productsBox.listenable(),
              builder: (context, box, _) {
                final products = box.values.toList();
                return DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  value: _selectedProduct,
                  hint: const Text('Select a product'),
                  onChanged: _onProductSelected,
                  items:
                      products.map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text(product.name),
                        );
                      }).toList(),
                  validator:
                      (value) =>
                          value == null ? 'Please select a product' : null,
                );
              },
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _unitPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
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
              readOnly:
                  _selectedProduct !=
                  null, // Make it read-only if product is selected
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (double.tryParse(value) == null ||
                    double.tryParse(value)! <= 0) {
                  return 'Please enter a valid positive number';
                }
                if (_selectedProduct != null &&
                    double.tryParse(value)! > _selectedProduct!.currentStock) {
                  return 'Only ${_selectedProduct!.currentStock} in stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSale,
                icon: const Icon(Icons.save),
                label: const Text('Save Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display recent sales (optional, can be a separate widget/screen)
            const Text(
              'Recent Sales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<Box<Sale>>(
              valueListenable: AppData.salesBox.listenable(),
              builder: (context, box, _) {
                final sales =
                    box.values
                        .toList()
                        .reversed
                        .take(5)
                        .toList(); // Show last 5 sales
                if (sales.isEmpty) {
                  return const Center(child: Text('No sales yet.'));
                }
                return ListView.builder(
                  shrinkWrap: true, // Important for nested list views
                  physics:
                      const NeverScrollableScrollPhysics(), // Important for nested list views
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${sale.productName} - ${sale.quantity} Qty',
                        ),
                        subtitle: Text(
                          '₹${sale.totalAmount.toStringAsFixed(2)} on ${sale.saleDate.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
