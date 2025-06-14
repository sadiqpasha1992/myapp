import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import your Sale model

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
    _customerNameController = TextEditingController(
      text: widget.sale.customerName,
    );
    _productNameController = TextEditingController(
      text: widget.sale.productName,
    );
    _quantityController = TextEditingController(text: widget.sale.quantity.toString());
    _saleAmountController = TextEditingController(text: widget.sale.saleAmount.toString());
    _selectedDate = widget.sale.date;
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
            'Are you sure you want to delete the sale to "${widget.sale.customerName}" for "${widget.sale.productName}"? This action cannot be undone and will affect stock levels.',
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
                final List<Product> productsInStock =
                    AppData.productsBox.values.toList();
                final int productIndex = productsInStock.indexWhere(
                  (p) =>
                      p.name.toLowerCase() ==
                      widget.sale.productName.toLowerCase(),
                );

                if (productIndex != -1) {
                  final Product existingProduct = productsInStock[productIndex];
                  final double soldQuantity = widget.sale.quantity; // quantity is already double
                  final updatedProduct = Product(
                    name: existingProduct.name,
                    quantity:
                        existingProduct.quantity +
                        soldQuantity, // Revert: Add quantity back
                    unit: existingProduct.unit,
                    purchasePrice: existingProduct.purchasePrice,
                    sellingPrice: existingProduct.sellingPrice,
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
                          'Product "${widget.sale.productName}" not found in stock. Stock not reverted.',
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

    final double oldQuantity = widget.sale.quantity; // quantity is already double
    final double? newQuantity = double.tryParse(newQuantityStr);

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
    double quantityDifference = newQuantity - oldQuantity;

    // Find the product in stock (old and new product names)
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int oldProductIndex = productsInStock.indexWhere(
      (p) => p.name.toLowerCase() == widget.sale.productName.toLowerCase(),
    );
    final int newProductIndex = productsInStock.indexWhere(
      (p) => p.name.toLowerCase() == newProductName.toLowerCase(),
    );

    // Revert old product stock if product name changed or quantity decreased
    if (oldProductIndex != -1 &&
        (widget.sale.productName.toLowerCase() !=
                newProductName.toLowerCase() ||
            quantityDifference < 0)) {
      final Product oldProduct = productsInStock[oldProductIndex];
      final double quantityToRevert =
          widget.sale.productName.toLowerCase() != newProductName.toLowerCase()
              ? oldQuantity // Revert full old quantity if product name changed
              : -quantityDifference; // Revert only the decrease if product name is same
      final updatedOldProduct = Product(
        name: oldProduct.name,
        quantity: oldProduct.quantity + quantityToRevert,
        unit: oldProduct.unit,
        purchasePrice: oldProduct.purchasePrice,
        sellingPrice: oldProduct.sellingPrice,
      );
      await AppData.productsBox.putAt(oldProductIndex, updatedOldProduct);
    }

    // Apply new product stock update
    if (newProductIndex != -1) {
      final Product newProduct = productsInStock[newProductIndex];
      // Only update if product name is the same OR if it's a new product for this entry
      if (widget.sale.productName.toLowerCase() ==
          newProductName.toLowerCase()) {
        final updatedNewProduct = Product(
          name: newProduct.name,
          quantity:
              newProduct.quantity - quantityDifference, // Apply the net change
          unit: newProduct.unit,
          purchasePrice: newProduct.purchasePrice,
          sellingPrice: newProduct.sellingPrice,
        );
        await AppData.productsBox.putAt(newProductIndex, updatedNewProduct);
      } else {
        // New product name, decrement stock for this product
        final updatedNewProduct = Product(
          name: newProduct.name,
          quantity: newProduct.quantity - newQuantity,
          unit: newProduct.unit,
          purchasePrice: newProduct.purchasePrice,
          sellingPrice: newProduct.sellingPrice,
        );
        await AppData.productsBox.putAt(newProductIndex, updatedNewProduct);
      }
    } else {
      // New product name not found in stock, cannot proceed with sale.
      // Or if it was a new product, it needs to exist to decrement.
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

    // Create an updated Sale object
    final updatedSale = Sale(
      customerName: newCustomerName,
      productName: newProductName,
      quantity: newQuantity, // Use parsed double
      saleAmount: double.tryParse(newSaleAmountStr) ?? 0.0, // Parse saleAmount to double
      date: _selectedDate,
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
                        'Sale to: ${widget.sale.customerName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      _buildDetailRow(
                        'Product Name:',
                        widget.sale.productName,
                        Icons.inventory_2,
                      ),
                      _buildDetailRow(
                        'Quantity:',
                        widget.sale.quantity.toString(), // Convert double to String for display
                        Icons.numbers,
                      ),
                      _buildDetailRow(
                        'Sale Amount:',
                        '₹ ${widget.sale.saleAmount.toStringAsFixed(2)}', // Format double to String for display
                        Icons.currency_rupee,
                      ),
                      _buildDetailRow(
                        'Date:',
                        '${widget.sale.date.day}/${widget.sale.date.month}/${widget.sale.date.year}',
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
