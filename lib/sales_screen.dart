import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import '../data/app_data.dart'; // Import our shared data file
import '../sale_detail_screen.dart'; // Import SaleDetailScreen

// Sale class is defined in app_data.dart

// SalesScreen is now a StatefulWidget because its content (form fields and the list of sales)
// will change over time based on user interaction.
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

// This is the "State" class that holds the changeable data for SalesScreen.
class _SalesScreenState extends State<SalesScreen> {
  // TextEditingController is like a special manager for a TextField.
  // It helps you get and set the text within the TextField.
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _saleAmountController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _customerNameController.dispose();
    _saleAmountController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // This method will be called when the "Save Sale" button is pressed.
  void _saveSale() async {
    // Made async to await stock update
    final String customerName = _customerNameController.text.trim();
    final String productName = _productNameController.text.trim();
    final String quantityStr = _quantityController.text.trim(); // Get as string
    final String saleAmountStr = _saleAmountController.text.trim(); // Get as string

    // Basic validation: Check if fields are not empty
    if (customerName.isEmpty ||
        productName.isEmpty ||
        quantityStr.isEmpty ||
        saleAmountStr.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
      return;
    }

    final double? soldQuantity = double.tryParse(quantityStr);
    if (soldQuantity == null || soldQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive quantity!'),
        ),
      );
      return;
    }

    final double? parsedSaleAmount = double.tryParse(saleAmountStr);
    if (parsedSaleAmount == null || parsedSaleAmount < 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive sale amount!'),
        ),
      );
      return;
    }

    // --- Stock Management: Decrement product quantity ---
    // Find the product in stock
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int productIndex = productsInStock.indexWhere(
      (p) => p.name.toLowerCase() == productName.toLowerCase(),
    );

    if (productIndex != -1) {
      final Product existingProduct = productsInStock[productIndex];
      if (existingProduct.quantity >= soldQuantity) {
        // Create an updated product with the new quantity
        final updatedProduct = Product(
          name: existingProduct.name,
          quantity:
              existingProduct.quantity - soldQuantity, // Decrement quantity
          unit: existingProduct.unit,
          purchasePrice: existingProduct.purchasePrice,
          sellingPrice: existingProduct.sellingPrice,
        );
        // Update the product in Hive
        await AppData.productsBox.putAt(productIndex, updatedProduct);
      } else {
        // Not enough stock
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock for $productName. Available: ${existingProduct.quantity} ${existingProduct.unit}',
            ),
          ),
        );
        return; // Stop sale if not enough stock
      }
    } else {
      // Product not found in stock
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Product "$productName" not found in stock. Please add it via Stock Summary first.',
          ),
        ),
      );
      return; // Stop sale if product not found
    }
    // --- End Stock Management ---

    // Create a new Sale object
    final newSale = Sale(
      customerName: customerName,
      productName: productName,
      quantity: soldQuantity, // Use the parsed double quantity
      saleAmount: parsedSaleAmount, // Use the parsed double sale amount
      date: DateTime.now(), // Record the current date and time
    );

    // Add to the Hive Box using AppData
    AppData.addSale(newSale)
        .then((_) {
          if (!mounted) return;

          // Clear text fields after saving
          _customerNameController.clear();
          _saleAmountController.clear();
          _productNameController.clear();
          _quantityController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale saved successfully! Stock updated.'),
            ),
          );
        })
        .catchError((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save sale: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Sale Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Customer Name Text Field
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'e.g., John Doe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Product Name Text Field
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Laptop Pro X1',
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
                hintText: 'e.g., 2',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Sale Amount Text Field
            TextField(
              controller: _saleAmountController,
              decoration: const InputDecoration(
                labelText: 'Sale Amount',
                hintText: 'e.g., 12500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Save Sale Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSale,
                icon: const Icon(Icons.save),
                label: const Text('Save Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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

            // --- Section: Displaying Saved Sales ---
            ValueListenableBuilder(
              valueListenable: AppData.salesBox.listenable(),
              builder: (context, Box<Sale> box, _) {
                final List<Sale> sales = box.values.toList();
                // Sort by date (most recent first)
                sales.sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Sales (${sales.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    sales.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No sales recorded yet. Add your first sale above!',
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
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              final sale = sales[index];
                              // Get the actual Hive key/index for this item
                              final int hiveIndex = AppData.salesBox.keyAt(
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SaleDetailScreen(
                                              sale: sale,
                                              saleIndex:
                                                  hiveIndex, // NEW: Pass the Hive index
                                            ),
                                      ),
                                    );
                                  },
                                  leading: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.green,
                                  ),
                                  title: Text(
                                    '${sale.customerName} - ${sale.productName}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Qty: ${sale.quantity} | Amount: ₹ ${sale.saleAmount} | Date: ${sale.date.day}/${sale.date.month}/${sale.date.year}',
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
