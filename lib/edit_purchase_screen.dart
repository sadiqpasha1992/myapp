import 'package:flutter/material.dart';

import 'package:myapp/data/app_data.dart'; // Import your Purchase model
import 'package:myapp/models/models.dart'; // Import Purchase and Product models
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:collection/collection.dart'; // For firstWhereOrNull
// Import Hive for Box type


class EditPurchaseScreen extends StatefulWidget {
  final Purchase? purchase;
  final int? purchaseIndex;

  const EditPurchaseScreen({
    super.key,
    this.purchase,
    this.purchaseIndex,
  });

  @override
  EditPurchaseScreenState createState() => EditPurchaseScreenState();
}

class EditPurchaseScreenState extends State<EditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _supplierNameController;
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _purchaseAmountController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _supplierNameController = TextEditingController(text: widget.purchase?.supplierId ?? ''); // Use supplierId
    _productNameController = TextEditingController(text: widget.purchase?.productName ?? '');
    _quantityController = TextEditingController(text: widget.purchase?.quantity.toString() ?? '');
    _purchaseAmountController = TextEditingController(text: widget.purchase?.totalAmount.toString() ?? ''); // Use totalAmount
    _selectedDate = widget.purchase?.purchaseDate ?? DateTime.now(); // Use purchaseDate
  }

  @override
  void dispose() {
    _supplierNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _purchaseAmountController.dispose();
    super.dispose();
  }

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

  void _savePurchase() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Find the product to get its ID
      final Product? product = AppData.productsBox.values.firstWhereOrNull(
        (p) => p.name.toLowerCase() == _productNameController.text.trim().toLowerCase(),
      );

      if (product == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product "${_productNameController.text.trim()}" not found in stock. Cannot save purchase.',
              ),
            ),
          );
        }
        return; // Stop if product is not found
      }

      final newPurchase = Purchase(
        // Assuming Purchase model requires ID, generate one if adding
        id: widget.purchase?.id ?? const Uuid().v4(),
        productId: product.id, // Use the found product's ID
        supplierId: _supplierNameController.text, // Use supplierId
        productName: _productNameController.text,
        quantity: double.parse(_quantityController.text),
        unitPrice: double.parse(_purchaseAmountController.text), // Assuming purchaseAmount maps to unitPrice in Purchase model
        totalAmount: double.parse(_quantityController.text) * double.parse(_purchaseAmountController.text), // Calculate totalAmount
        purchaseDate: _selectedDate, // Use purchaseDate
        // customerId is not part of Purchase model
      );

      if (widget.purchaseIndex != null) {
        // Editing existing purchase
        // Get old purchase details to revert stock changes
        final oldPurchase = AppData.purchasesBox.getAt(widget.purchaseIndex!); // Handle potential null

        if (oldPurchase != null) {
           // Revert stock changes from the old purchase
          await _updateStock(oldPurchase.productName, -oldPurchase.quantity);
        }


        // Update stock changes for the new purchase
        await _updateStock(newPurchase.productName, newPurchase.quantity);

        // Save the updated purchase to Hive
        // Assuming AppData.updatePurchase exists and takes Purchase object
        // If not, need to use AppData.purchasesBox.put(newPurchase.id, newPurchase)
        // Based on app_data.dart, updatePurchase exists and takes Purchase object
        await AppData.updatePurchase(newPurchase);


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase updated successfully!')),
          );
        }
      } else {
        // Adding new purchase
        // Assuming AppData.addPurchase exists and takes Purchase object
        // Based on app_data.dart, addPurchase exists and takes Purchase object
        await AppData.addPurchase(newPurchase);
        await _updateStock(newPurchase.productName, newPurchase.quantity);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase added successfully!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Go back
      }
    }
  }

  Future<void> _updateStock(String productName, double quantityChange) async {
    final Product? existingProduct = AppData.productsBox.values.firstWhereOrNull(
      (p) => p.name.toLowerCase() == productName.toLowerCase(),
    );


    if (existingProduct != null) {
      // Create updated Product object using existing fields and new stock
      final updatedProduct = Product(
        id: existingProduct.id, // Use existing ID
        name: existingProduct.name,
        currentStock: existingProduct.currentStock + quantityChange, // Add or subtract quantity
        unit: existingProduct.unit,
        purchasePrice: existingProduct.purchasePrice,
        unitPrice: existingProduct.unitPrice, // Use unitPrice for selling price
      );
      // Update the product in Hive using its ID
      await AppData.productsBox.put(updatedProduct.id, updatedProduct);
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product "$productName" not found in stock. Stock not updated.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchaseIndex != null ? 'Edit Purchase' : 'Add New Purchase'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _supplierNameController,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter supplier name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _purchaseAmountController,
                decoration: const InputDecoration(labelText: 'Unit Price'), // Changed label
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit price';
                  }
                   if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(widget.purchaseIndex != null ? 'Save Changes' : 'Add Purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
