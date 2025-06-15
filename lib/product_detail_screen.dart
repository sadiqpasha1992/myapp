import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import AppData for product model and box operations

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final int productIndex; // Index in Hive box for updating/deleting

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productIndex,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;

  bool _isEditing = false; // State to toggle between view and edit mode

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(
      text: widget.product.quantity.toString(),
    );
    _unitController = TextEditingController(text: widget.product.unit);
    _purchasePriceController = TextEditingController(
      text: widget.product.purchasePrice.toStringAsFixed(2),
    );
    _sellingPriceController = TextEditingController(
      text: widget.product.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // Helper for displaying details in view mode
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

  // Helper for creating editable fields
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

  // Method to handle product deletion
  void _deleteProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete product "${widget.product.name}"? This action cannot be undone and will affect related transactions (though transactions themselves won\'t be deleted).',
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
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await AppData.deleteProduct(
                  widget.productIndex,
                ); // Delete by index
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully!'),
                    ),
                  );
                  navigator.pop(); // Go back to Stock Summary screen
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

  // Method to save edited product details
  void _saveEditedProduct() async {
    final String newName = _nameController.text.trim();
    final String newQuantityStr = _quantityController.text.trim();
    final String newUnit = _unitController.text.trim();
    final String newPurchasePriceStr = _purchasePriceController.text.trim();
    final String newSellingPriceStr = _sellingPriceController.text.trim();

    // Basic validation
    if (newName.isEmpty ||
        newQuantityStr.isEmpty ||
        newUnit.isEmpty ||
        newPurchasePriceStr.isEmpty ||
        newSellingPriceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields for the edited product!'),
        ),
      );
      return;
    }

    final double? newQuantity = double.tryParse(newQuantityStr);
    final double? newPurchasePrice = double.tryParse(newPurchasePriceStr);
    final double? newSellingPrice = double.tryParse(newSellingPriceStr);

    if (newQuantity == null ||
        newQuantity < 0 ||
        newPurchasePrice == null ||
        newPurchasePrice < 0 ||
        newSellingPrice == null ||
        newSellingPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid positive numbers for Quantity, Purchase Price, and Selling Price!',
          ),
        ),
      );
      return;
    }

    // Handle potential product name change and check for duplicates (excluding current product)
    if (newName.toLowerCase() != widget.product.name.toLowerCase()) {
      final existingProducts = AppData.productsBox.values.toList();
      if (existingProducts.any(
        (p) => p.name.toLowerCase() == newName.toLowerCase(),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Product with this new name already exists! Choose a unique name.',
            ),
          ),
        );
        return;
      }
    }

    // Create updated Product object
    final updatedProduct = Product(
      name: newName,
      quantity: newQuantity,
      unit: newUnit,
      purchasePrice: newPurchasePrice,
      sellingPrice: newSellingPrice,
    );

    // Update the product in Hive at its original index
    await AppData.productsBox.putAt(widget.productIndex, updatedProduct);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
      setState(() {
        _isEditing = false; // Switch back to view mode
        // Update controllers with saved data to reflect changes immediately
        _nameController.text = newName;
        _quantityController.text = newQuantity.toStringAsFixed(2);
        _unitController.text = newUnit;
        _purchasePriceController.text = newPurchasePrice.toStringAsFixed(2);
        _sellingPriceController.text = newSellingPrice.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the product details to display based on whether we are editing
    final displayProduct =
        _isEditing
            ? Product(
              name: _nameController.text,
              quantity: double.tryParse(_quantityController.text) ?? 0.0,
              unit: _unitController.text,
              purchasePrice:
                  double.tryParse(_purchasePriceController.text) ?? 0.0,
              sellingPrice:
                  double.tryParse(_sellingPriceController.text) ?? 0.0,
            )
            : widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Product Details'),
        backgroundColor: Colors.teal, // Consistent with Stock Summary color
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
              tooltip: 'Edit Product',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(context), // Call delete method
            tooltip: 'Delete Product',
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
                        _nameController,
                        'Product Name',
                        Icons.inventory_2,
                        TextInputType.text,
                      ),
                      _buildEditableField(
                        _quantityController,
                        'Current Stock',
                        Icons.numbers,
                        TextInputType.number,
                      ),
                      _buildEditableField(
                        _unitController,
                        'Unit',
                        Icons.square_foot,
                        TextInputType.text,
                      ),
                      _buildEditableField(
                        _purchasePriceController,
                        'Purchase Price',
                        Icons.currency_rupee,
                        TextInputType.number,
                      ),
                      _buildEditableField(
                        _sellingPriceController,
                        'Selling Price',
                        Icons.sell,
                        TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveEditedProduct, // Call save method
                          icon: const Icon(Icons.save),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
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
                        'Product: ${displayProduct.name}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      _buildDetailRow(
                        'Current Stock:',
                        '${displayProduct.quantity} ${displayProduct.unit}',
                        Icons.storage,
                      ),
                      _buildDetailRow(
                        'Purchase Price:',
                        '₹ ${displayProduct.purchasePrice.toStringAsFixed(2)}',
                        Icons.arrow_downward,
                      ),
                      _buildDetailRow(
                        'Selling Price:',
                        '₹ ${displayProduct.sellingPrice.toStringAsFixed(2)}',
                        Icons.arrow_upward,
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade400,
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
