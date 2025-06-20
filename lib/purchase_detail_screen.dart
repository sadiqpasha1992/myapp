import 'package:flutter/material.dart';
import 'package:myapp/models/models.dart'; // Import your Purchase model
import 'package:myapp/data/app_data.dart'; // Import AppData

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
    _supplierNameController = TextEditingController(text: widget.purchase.supplierId ?? ''); // Assuming supplierId is used for display or linking
    _productNameController = TextEditingController(text: widget.purchase.productName);
    _quantityController = TextEditingController(text: widget.purchase.quantity.toString()); // Keep as string for text field
    _purchaseAmountController = TextEditingController(text: widget.purchase.totalAmount.toString()); // Use totalAmount
    _selectedDate = widget.purchase.purchaseDate; // Use purchaseDate
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
          Icon(icon, size: 20, color: Colors.grey),
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
          content: Text('Are you sure you want to delete the purchase of "${widget.purchase.productName}"? This action cannot be undone and will affect stock levels.'), // Removed supplierName as it's not directly on Purchase
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
                    id: existingProduct.id,
                    name: existingProduct.name,
                    currentStock: existingProduct.currentStock - purchasedQuantity,
                    unit: existingProduct.unit,
                    purchasePrice: existingProduct.purchasePrice,
                    unitPrice: existingProduct.unitPrice,
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

    final double oldQuantity = widget.purchase.quantity; // quantity is already double
    final double? newQuantity = double.tryParse(newQuantityStr);

    if (newQuantity == null || newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive quantity for the edited purchase!')),
      );
      return;
    }

    // --- Stock Management for Edit Operation ---
    // Calculate the change in quantity
    double quantityDifference = newQuantity - oldQuantity;

    // Find the product in stock (old and new product names)
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int oldProductIndex = productsInStock.indexWhere((p) => p.name.toLowerCase() == widget.purchase.productName.toLowerCase());
    final int newProductIndex = productsInStock.indexWhere((p) => p.name.toLowerCase() == newProductName.toLowerCase());

    // Revert old product stock if product name changed or quantity increased (because it's a purchase)
    if (oldProductIndex != -1 && (widget.purchase.productName.toLowerCase() != newProductName.toLowerCase() || quantityDifference > 0)) {
      final Product oldProduct = productsInStock[oldProductIndex];
      final double quantityToRevert = widget.purchase.productName.toLowerCase() != newProductName.toLowerCase()
          ? oldQuantity // Revert full old quantity if product name changed
          : quantityDifference; // Revert only the increase if product name is same
      final updatedOldProduct = Product(
          id: oldProduct.id,
          name: oldProduct.name,
          currentStock: oldProduct.currentStock - quantityToRevert,
          unit: oldProduct.unit,
          purchasePrice: oldProduct.purchasePrice,
          unitPrice: oldProduct.unitPrice,
      );
      await AppData.productsBox.putAt(oldProductIndex, updatedOldProduct);
    }

    // Apply new product stock update
    if (newProductIndex != -1) {
      final Product newProduct = productsInStock[newProductIndex];
      // Only update if product name is the same OR if it's a new product for this entry
      if (widget.purchase.productName.toLowerCase() == newProductName.toLowerCase()) {
         final updatedNewProduct = Product(
          id: newProduct.id,
          name: newProduct.name,
          currentStock: newProduct.currentStock + quantityDifference,
          unit: newProduct.unit,
          purchasePrice: newProduct.purchasePrice,
          unitPrice: newProduct.unitPrice,
        );
        await AppData.productsBox.putAt(newProductIndex, updatedNewProduct);
      } else {
        // New product name, increment stock for this new product
        // This case seems incorrect for an *edit* operation. If the product name changes,
        // we should update the existing product entry if it exists, or add a new one.
        // The original code seems to add a new product even if one with the new name exists.
        // Let's assume the intention is to update the existing product with the new name if it exists,
        // or add a new one if it doesn't.
        // Reverting the old product stock was handled above. Now, add the new quantity to the new product.
         final updatedNewProduct = Product(
          id: newProduct.id,
          name: newProduct.name,
          currentStock: newProduct.currentStock + newQuantity,
          unit: newProduct.unit,
          purchasePrice: newProduct.purchasePrice,
          unitPrice: newProduct.unitPrice,
        );
        await AppData.productsBox.putAt(newProductIndex, updatedNewProduct); // Update existing product
      }

    } else {
      // New product name not found in stock, auto-add it with the new quantity
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a simple unique ID
        name: newProductName,
        currentStock: newQuantity.toDouble(),
        unit: 'Pcs', // Default unit for new product
        purchasePrice: double.tryParse(newPurchaseAmountStr) ?? 0.0,
        unitPrice: (double.tryParse(newPurchaseAmountStr) ?? 0.0) * 1.2, // Use unitPrice (selling price)
      );
      await AppData.productsBox.add(newProduct);
    }
    // --- End Stock Management for Edit ---

    // Create an updated Purchase object
    final updatedPurchase = Purchase(
      id: widget.purchase.id, // Keep the original ID
      productId: widget.purchase.productId, // Keep the original product ID or update if needed? Assuming keep for now.
      productName: newProductName,
      quantity: newQuantity, // Use the parsed double quantity
      unitPrice: widget.purchase.unitPrice, // Keep original unit price or calculate? Assuming keep.
      totalAmount: double.tryParse(newPurchaseAmountStr) ?? 0.0, // Use totalAmount
      purchaseDate: _selectedDate, // Use purchaseDate
      supplierId: newSupplierName, // Assuming supplierName input is used for supplierId
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
                      const SizedBox(), // Added to break potential const context
                      const Text(
                        'Purchase Details', // Changed title as supplierName might not be directly available
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      _buildDetailRow('Product Name:', widget.purchase.productName, Icons.inventory_2),
                      _buildDetailRow('Quantity:', widget.purchase.quantity.toString(), Icons.numbers),
                      _buildDetailRow('Total Amount:', '₹ ${widget.purchase.totalAmount}', Icons.currency_rupee), // Use totalAmount
                      _buildDetailRow('Purchase Date:', '${widget.purchase.purchaseDate.day}/${widget.purchase.purchaseDate.month}/${widget.purchase.purchaseDate.year}', Icons.calendar_today), // Use purchaseDate
                      // Optionally display supplierId if needed
                      if (widget.purchase.supplierId != null && widget.purchase.supplierId!.isNotEmpty)
                         _buildDetailRow('Supplier ID:', widget.purchase.supplierId!, Icons.local_shipping),
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
