import 'package:flutter/material.dart';
// Import Hive
import 'package:myapp/data/app_data.dart'; // Import AppData
import 'package:myapp/models/models.dart'; // Import Sale, Product, Party models
import 'package:collection/collection.dart'; // For firstWhereOrNull


class SaleDetailScreen extends StatefulWidget {
  final Sale sale; // The Sale object to display
  final int saleIndex; // The index of the sale in the Hive box

  const SaleDetailScreen({
    super.key,
    required this.sale,
    required this.saleIndex,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  // Controllers for editing fields
  late TextEditingController _customerNameController;
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _saleAmountController;
  late DateTime _selectedDate; // For date editing

  bool _isEditing =
      false; // State variable to toggle between view and edit mode

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current sale data
    // Retrieve customer name from Party using customerId
    final customer = AppData.partiesBox.get(widget.sale.customerId);
    _customerNameController = TextEditingController(
      text: customer?.name ?? 'Unknown Customer',
    );
    // Retrieve product name from Product using productId
    final product = AppData.productsBox.get(widget.sale.productId);
    _productNameController = TextEditingController(
      text: product?.name ?? 'Unknown Product', // Use product name, handle null
    );
    _quantityController = TextEditingController(text: widget.sale.quantity.toString());
    _saleAmountController = TextEditingController(text: widget.sale.totalAmount.toString()); // Use totalAmount
    _selectedDate = widget.sale.saleDate; // Use saleDate
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _saleAmountController.dispose();
    super.dispose();
  }

  // Method to show a date picker for editing
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper method to build consistent detail rows (for view mode)
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build editable text fields (for edit mode)
  Widget _buildEditableField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  // Method to handle sale deletion
  void _deleteSale(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the sale to "${_customerNameController.text}" for "${_productNameController.text}"? This action cannot be undone and will affect stock levels.', // Use controller text for product name
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog

                // 1. Revert Stock Change (Important for data integrity)
                // Fetch the product using productId from the sale object
                final Product? soldProduct = AppData.productsBox.get(widget.sale.productId);

                if (soldProduct != null) {
                  final int productIndex = AppData.productsBox.values.toList().indexWhere((p) => p.id == soldProduct.id);

                  if (productIndex != -1) {
                    final int soldQuantity = widget.sale.quantity; // Use int quantity from Sale model
                    final updatedProduct = Product(
                      id: soldProduct.id,
                      name: soldProduct.name,
                      description: soldProduct.description, // Keep existing description
                      currentStock: soldProduct.currentStock + soldQuantity, // Revert: Add quantity back (int arithmetic)
                      unit: soldProduct.unit,
                      purchasePrice: soldProduct.purchasePrice,
                      unitPrice: soldProduct.unitPrice,
                    );
                    await AppData.productsBox.putAt(productIndex, updatedProduct);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock quantity reverted.')),
                      );
                    }
                  } else {
                     if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Product with ID "${widget.sale.productId}" not found in stock by index. Stock not reverted.',
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Product with ID "${widget.sale.productId}" not found in stock. Stock not reverted.',
                        ),
                      ),
                    );
                  }
                }

                // 2. Delete the Sale transaction from Hive
                await AppData.salesBox.deleteAt(widget.saleIndex);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sale deleted successfully!')),
                  );
                  // After successful deletion, navigate back to the previous screen (SalesScreen)
                  Navigator.of(context).pop();
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

  // Method to handle saving edited sale details
  void _saveEditedSale() async {
    final String newCustomerName = _customerNameController.text.trim();
    final String newProductName = _productNameController.text.trim();
    final String newQuantityStr = _quantityController.text.trim();
    final String newSaleAmountStr = _saleAmountController.text.trim();

    // Basic validation
    if (newCustomerName.isEmpty ||
        newProductName.isEmpty ||
        newQuantityStr.isEmpty ||
        newSaleAmountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields for the edited sale!'),
        ),
      );
      return;
    }

    final int oldQuantity = widget.sale.quantity; // Use int quantity from Sale model
    final int? newQuantity = int.tryParse(newQuantityStr); // Parse as int

    if (newQuantity == null || newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid positive quantity for the edited sale!',
          ),
        ),
      );
      return;
    }

    // --- Stock Management for Edit Operation ---
    // Calculate the change in quantity
    int quantityDifference = newQuantity - oldQuantity; // Use int arithmetic

    // Find the product in stock (old and new product names)
    final List<Product> productsInStock = AppData.productsBox.values.toList();

    // Fetch the new product by name to get its details
    final Product? newProduct = productsInStock.firstWhereOrNull(
        (p) => p.name.toLowerCase() == newProductName.toLowerCase());

    // Find the old product by ID from the sale object
    final Product? oldProduct = AppData.productsBox.get(widget.sale.productId);


    // Revert old product stock if product changed or quantity decreased
    if (oldProduct != null) {
      final int oldProductIndex = productsInStock.indexWhere((p) => p.id == oldProduct.id);
      if (oldProductIndex != -1) {
        final int quantityToRevert = // Use int
            oldProduct.id != newProduct?.id // Revert full old quantity if product changed
                ? oldQuantity
                : (quantityDifference < 0 ? -quantityDifference : 0); // Revert only the decrease if product is same
        final updatedOldProduct = Product(
          id: oldProduct.id,
          name: oldProduct.name,
          description: oldProduct.description, // Keep existing description
          currentStock: oldProduct.currentStock + quantityToRevert, // Use int arithmetic
          unit: oldProduct.unit,
          purchasePrice: oldProduct.purchasePrice,
          unitPrice: oldProduct.unitPrice, // Use unitPrice
        );
        await AppData.productsBox.putAt(oldProductIndex, updatedOldProduct);
      }
    }

    // Apply new product stock update
    if (newProduct != null) {
      final int newProductIndex = productsInStock.indexWhere((p) => p.id == newProduct.id);
      if (newProductIndex != -1) {
         final updatedNewProduct = Product(
           id: newProduct.id,
           name: newProduct.name,
           description: newProduct.description, // Keep existing description
           currentStock: newProduct.currentStock - newQuantity, // Decrement new quantity (int arithmetic)
           unit: newProduct.unit,
           purchasePrice: newProduct.purchasePrice,
           unitPrice: newProduct.unitPrice,
         );
         await AppData.productsBox.putAt(newProductIndex, updatedNewProduct);
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(
                 'New product "$newProductName" found by name but not by ID. Stock not updated.',
               ),
             ),
           );
         }
      }

    } else {
      // New product name not found in stock, cannot proceed with sale.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'New product "$newProductName" not found in stock. Please add it first or check spelling.',
            ),
          ),
        );
        return; // Stop update if new product not found
      }
    }
    // --- End Stock Management for Edit ---

    // Find the new product to get its ID
    String updatedProductId = '';
    final Product? productForId = AppData.productsBox.values.firstWhereOrNull(
        (p) => p.name.toLowerCase() == newProductName.toLowerCase());

    if (productForId != null) {
        updatedProductId = productForId.id;
    } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error finding new product ID for "$newProductName".',
                    ),
                ),
            );
            return; // Stop update
        }
    }

    final double parsedTotalAmount = double.tryParse(newSaleAmountStr) ?? 0.0;
    // Calculate unit price based on new quantity and total amount
    final double calculatedSaleUnitPrice = newQuantity > 0 ? parsedTotalAmount / newQuantity : 0.0;


    // Create an updated Sale object
    final updatedSale = Sale(
      id: widget.sale.id, // Use existing ID
      customerId: widget.sale.customerId, // Use existing customer ID
      productId: updatedProductId, // Use updated product ID
      quantity: newQuantity, // Use parsed int
      saleUnitPrice: calculatedSaleUnitPrice, // Calculate sale unit price
      totalAmount: parsedTotalAmount, // Use parsed total amount
      saleDate: _selectedDate, // Use selected date
    );

    // Update the sale in Hive at its original index
    await AppData.salesBox.putAt(widget.saleIndex, updatedSale);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale updated successfully!')),
      );
      setState(() {
        _isEditing = false; // Switch back to view mode
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sale' : 'Sale Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing) // Show edit button when not editing
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true; // Toggle to edit mode
                });
              },
              tooltip: 'Edit Sale',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteSale(context), // Call delete method
            tooltip: 'Delete Sale',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) // Show editable fields in edit mode
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableField(
                        _customerNameController,
                        'Customer Name',
                        Icons.person,
                        TextInputType.text,
                      ),
                      _buildEditableField(
                        _productNameController,
                        'Product Name',
                        Icons.inventory_2,
                        TextInputType.text,
                      ),
                      _buildEditableField(
                        _quantityController,
                        'Quantity',
                        Icons.numbers,
                        TextInputType.number,
                      ),
                      _buildEditableField(
                        _saleAmountController,
                        'Sale Amount',
                        Icons.currency_rupee,
                        TextInputType.number,
                      ),
                      ListTile(
                        title: Text(
                          'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveEditedSale, // Call save method
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                else // Show static details in view mode
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale to: ${_customerNameController.text}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      _buildDetailRow(
                        'Product Name:',
                        _productNameController.text, // Use controller text
                        Icons.inventory_2,
                      ),
                      _buildDetailRow(
                        'Quantity:',
                        widget.sale.quantity.toString(), // Convert int to String for display
                        Icons.numbers,
                      ),
                      _buildDetailRow(
                        'Sale Amount:',
                        '₹ ${widget.sale.totalAmount.toStringAsFixed(2)}', // Format double to String for display
                        Icons.currency_rupee,
                      ),
                      _buildDetailRow(
                        'Date:',
                        '${widget.sale.saleDate.day}/${widget.sale.saleDate.month}/${widget.sale.saleDate.year}',
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing =
                                  true; // Still offer edit from here if not in AppBar
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Sale'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
