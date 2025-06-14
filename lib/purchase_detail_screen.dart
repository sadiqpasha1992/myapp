import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import your Purchase model

class PurchaseDetailScreen extends StatefulWidget {
  final Purchase purchase; // The Purchase object to display
  final int purchaseIndex; // The index of the purchase in the Hive box

  const PurchaseDetailScreen({super.key, required this.purchase, required this.purchaseIndex});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  // Controllers for editing fields
  late TextEditingController _supplierNameController;
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _purchaseAmountController;
  late DateTime _selectedDate; // For date editing

  bool _isEditing = false; // State variable to toggle between view and edit mode

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current purchase data
    _supplierNameController = TextEditingController(text: widget.purchase.supplierName);
    _productNameController = TextEditingController(text: widget.purchase.productName);
    _quantityController = TextEditingController(text: widget.purchase.quantity.toString()); // Keep as string for text field
    _purchaseAmountController = TextEditingController(text: widget.purchase.purchaseAmount.toString()); // Keep as string for text field
    _selectedDate = widget.purchase.date;
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _purchaseAmountController.dispose();
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build editable text fields (for edit mode)
  Widget _buildEditableField(TextEditingController controller, String label, IconData icon, TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  // Method to handle purchase deletion
  void _deletePurchase(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the purchase of "${widget.purchase.productName}" from "${widget.purchase.supplierName}"? This action cannot be undone and will affect stock levels.'),
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
                final List<Product> productsInStock = AppData.productsBox.values.toList();
                final int productIndex = productsInStock.indexWhere((p) => p.name.toLowerCase() == widget.purchase.productName.toLowerCase());

                if (productIndex != -1) {
                  final Product existingProduct = productsInStock[productIndex];
                  final double purchasedQuantity = widget.purchase.quantity;
                  final updatedProduct = Product(
                    name: existingProduct.name,
                    quantity: existingProduct.quantity - purchasedQuantity, // Revert: Subtract quantity
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
                      SnackBar(content: Text('Product "${widget.purchase.productName}" not found in stock. Stock not reverted.')),
                    );
                  }
                }

                // 2. Delete the Purchase transaction from Hive
                await AppData.purchasesBox.deleteAt(widget.purchaseIndex);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase deleted successfully!')),
                  );
                  // After successful deletion, navigate back to the previous screen (PurchaseScreen)
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

  // Method to handle saving edited purchase details
  void _saveEditedPurchase() async {
    final String newSupplierName = _supplierNameController.text.trim();
    final String newProductName = _productNameController.text.trim();
    final String newQuantityStr = _quantityController.text.trim();
    final String newPurchaseAmountStr = _purchaseAmountController.text.trim();

    // Basic validation
    if (newSupplierName.isEmpty || newProductName.isEmpty || newQuantityStr.isEmpty || newPurchaseAmountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields for the edited purchase!')),
      );
      return;
    }

    final double? oldQuantity = double.tryParse(widget.purchase.quantity.toString());
    final double? newQuantity = double.tryParse(newQuantityStr);

    if (newQuantity == null || newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive quantity for the edited purchase!')),
      );
      return;
    }

    // --- Stock Management for Edit Operation ---
    // Calculate the change in quantity
    double quantityDifference = newQuantity - (oldQuantity ?? 0.0);

    // Find the product in stock (old and new product names)
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int oldProductIndex = productsInStock.indexWhere((p) => p.name.toLowerCase() == widget.purchase.productName.toLowerCase());
    final int newProductIndex = productsInStock.indexWhere((p) => p.name.toLowerCase() == newProductName.toLowerCase());

    // Revert old product stock if product name changed or quantity increased (because it's a purchase)
    if (oldProductIndex != -1 && (widget.purchase.productName.toLowerCase() != newProductName.toLowerCase() || quantityDifference > 0)) {
      final Product oldProduct = productsInStock[oldProductIndex];
      final double quantityToRevert = widget.purchase.productName.toLowerCase() != newProductName.toLowerCase()
          ? (oldQuantity ?? 0.0) // Revert full old quantity if product name changed
          : quantityDifference; // Revert only the increase if product name is same
      final updatedOldProduct = Product(
          name: oldProduct.name,
          quantity: oldProduct.quantity - quantityToRevert, // Subtract quantity back for old product
          unit: oldProduct.unit, purchasePrice: oldProduct.purchasePrice, sellingPrice: oldProduct.sellingPrice,
      );
      await AppData.productsBox.putAt(oldProductIndex, updatedOldProduct);
    }

    // Apply new product stock update
    if (newProductIndex != -1) {
      final Product newProduct = productsInStock[newProductIndex];
      // Only update if product name is the same OR if it's a new product for this entry
      if (widget.purchase.productName.toLowerCase() == newProductName.toLowerCase()) {
         final updatedNewProduct = Product(
          name: newProduct.name,
          quantity: newProduct.quantity + quantityDifference, // Apply the net change (add)
          unit: newProduct.unit, purchasePrice: newProduct.purchasePrice, sellingPrice: newProduct.sellingPrice,
        );
        await AppData.productsBox.putAt(newProductIndex, updatedNewProduct);
      } else {
        // New product name, increment stock for this new product
        final updatedNewProduct = Product(
          name: newProduct.name,
          quantity: newProduct.quantity + newQuantity,
          unit: newProduct.unit, purchasePrice: newProduct.purchasePrice, sellingPrice: newProduct.sellingPrice,
        );
        await AppData.productsBox.add(updatedNewProduct); // Use add if it's a completely new product being introduced via purchase edit
      }

    } else {
      // New product name not found in stock, auto-add it with the new quantity
      final newProduct = Product(
        name: newProductName,
        quantity: newQuantity.toDouble(),
        unit: 'Pcs', // Default unit for new product
        purchasePrice: double.tryParse(newPurchaseAmountStr) ?? 0.0,
        sellingPrice: (double.tryParse(newPurchaseAmountStr) ?? 0.0) * 1.2,
      );
      await AppData.productsBox.add(newProduct);
    }
    // --- End Stock Management for Edit ---

    // Create an updated Purchase object
    final updatedPurchase = Purchase(
      supplierName: newSupplierName,
      productName: newProductName,
      quantity: double.tryParse(newQuantityStr) ?? 0.0,
      purchaseAmount: double.tryParse(newPurchaseAmountStr) ?? 0.0,
      date: _selectedDate,
    );

    // Update the purchase in Hive at its original index
    await AppData.purchasesBox.putAt(widget.purchaseIndex, updatedPurchase);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase updated successfully!')),
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
        title: Text(_isEditing ? 'Edit Purchase' : 'Purchase Details'),
        backgroundColor: Colors.orange, // Consistent with Purchases screen color
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
              tooltip: 'Edit Purchase',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deletePurchase(context), // Call delete method
            tooltip: 'Delete Purchase',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) // Show editable fields in edit mode
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditableField(_supplierNameController, 'Supplier Name', Icons.local_shipping, TextInputType.text),
                      _buildEditableField(_productNameController, 'Product Name', Icons.inventory_2, TextInputType.text),
                      _buildEditableField(_quantityController, 'Quantity', Icons.numbers, TextInputType.number),
                      _buildEditableField(_purchaseAmountController, 'Purchase Amount', Icons.currency_rupee, TextInputType.number),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveEditedPurchase, // Call save method
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        'Purchase from: ${widget.purchase.supplierName}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      _buildDetailRow('Product Name:', widget.purchase.productName, Icons.inventory_2),
                      _buildDetailRow('Quantity:', widget.purchase.quantity.toString(), Icons.numbers),
                      _buildDetailRow('Purchase Amount:', '₹ ${widget.purchase.purchaseAmount}', Icons.currency_rupee),
                      _buildDetailRow('Date:', '${widget.purchase.date.day}/${widget.purchase.date.month}/${widget.purchase.date.year}', Icons.calendar_today),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true; // Still offer edit from here if not in AppBar
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Purchase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
