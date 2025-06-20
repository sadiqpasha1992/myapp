import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import AppData for product model and box operations
import 'package:myapp/models/models.dart'; // Import Product class
import 'package:uuid/uuid.dart'; // Import Uuid for generating IDs

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  // Using product ID instead of index for consistency with AppData methods
  final String? productId;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
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
    // Retrieve product by ID if productId is provided
    final initialProduct = widget.productId != null ? AppData.productsBox.get(widget.productId!) : null;

    _nameController = TextEditingController(text: initialProduct?.name ?? '');
    _quantityController = TextEditingController(
      text: initialProduct?.currentStock.toString() ?? '', // Use currentStock
    );
    _unitController = TextEditingController(text: initialProduct?.unit ?? '');
    _purchasePriceController = TextEditingController(
      text: initialProduct?.purchasePrice.toStringAsFixed(2) ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: initialProduct?.unitPrice.toStringAsFixed(2) ?? '', // Use unitPrice
    );
    // If product is null, we are adding a new product, so start in editing mode
    _isEditing = initialProduct == null;
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
    if (widget.productId == null) {
      // Cannot delete a product that hasn't been saved yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete unsaved product.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete product "${widget.product!.name}"? This action cannot be undone and will affect related transactions (though transactions themselves won\'t be deleted).',
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
                // Delete by ID instead of index
                await AppData.deleteProduct(widget.product!.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully!'),
                    ),
                  );
                }
                navigator.pop(); // Go back to Stock Summary screen
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

    // Handle potential product name change and check for duplicates (excluding current product if editing)
    final existingProducts = AppData.productsBox.values.toList();
    if (existingProducts.any(
      (p) =>
          p.name.toLowerCase() == newName.toLowerCase() &&
          (widget.productId == null || // If adding new, check all
              p.id != widget.productId), // If editing, exclude current product by ID
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product with this name already exists! Choose a unique name.',
          ),
        ),
      );
      return;
    }

    // Create Product object
    final productToSave = Product(
      // Generate new ID if adding, use existing if editing
      id: widget.productId ?? const Uuid().v4(),
      name: newName,
      currentStock: double.tryParse(_quantityController.text) ?? 0.0, // Use currentStock
      unitPrice: double.tryParse(_sellingPriceController.text) ?? 0.0, // Use unitPrice
      unit: newUnit, // Use unit
      purchasePrice: double.tryParse(newPurchasePriceStr) ?? 0.0, // Use purchasePrice
    );

    if (widget.productId != null) {
      // Update the product in Hive using its ID
      await AppData.productsBox.put(widget.productId!, productToSave);
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
    } else {
      // Add new product
      await AppData.addProduct(productToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.of(context).pop(); // Go back after adding
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the product details to display based on whether we are editing or adding
    // Need to retrieve the product by ID if viewing an existing one
    final displayProduct =
        _isEditing
            ? Product(
              id: widget.productId ?? const Uuid().v4(), // Placeholder ID if adding
              name: _nameController.text,
              currentStock: double.tryParse(_quantityController.text) ?? 0.0,
              unitPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
              unit: _unitController.text,
              purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
            )
            : (widget.productId != null ? AppData.productsBox.get(widget.productId!) : null); // Retrieve by ID if viewing existing

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? (_isEditing ? 'Edit Product' : 'Product Details') : 'Add New Product'),
        backgroundColor: Colors.teal, // Consistent with Stock Summary color
        foregroundColor: Colors.white,
        actions: [
          if (widget.productId != null && !_isEditing) // Show edit button only for existing products when not editing
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true; // Toggle to edit mode
                });
              },
              tooltip: 'Edit Product',
            ),
          if (widget.productId != null) // Show delete button only for existing products
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
                        'Current Stock', // Label based on model field
                        Icons.numbers,
                        TextInputType.number,
                      ),
                      _buildEditableField(
                        _unitController,
                        'Unit', // This field is not in the Product model
                        Icons.square_foot,
                        TextInputType.text,
                      ),
                      _buildEditableField(
                        _purchasePriceController,
                        'Purchase Price', // This field is not in the Product model
                        Icons.currency_rupee,
                        TextInputType.number,
                      ),
                      _buildEditableField(
                        _sellingPriceController,
                        'Selling Price', // Label based on model field (unitPrice)
                        Icons.sell,
                        TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _saveEditedProduct, // Call save method
                          icon: const Icon(Icons.save),
                          label: Text(widget.productId != null ? 'Save Changes' : 'Add Product'),
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
                else // Show static details in view mode (only for existing products)
                  if (displayProduct != null) // Ensure displayProduct is not null before showing details
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
                          // Assuming unit is stored elsewhere or needs to be added to model
                          '${displayProduct.currentStock} ${displayProduct.unit}', // Use unit
                          Icons.storage,
                        ),
                        _buildDetailRow(
                          'Purchase Price:',
                          '₹ ${displayProduct.purchasePrice.toStringAsFixed(2)}', // Use purchasePrice
                          Icons.arrow_downward,
                        ),
                        _buildDetailRow(
                          'Selling Price:',
                          '₹ ${displayProduct.unitPrice.toStringAsFixed(2)}', // Using unitPrice for selling price
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
