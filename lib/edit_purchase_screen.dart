import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import your Purchase model


class EditPurchaseScreen extends StatefulWidget {
  final Purchase purchase;
  final int purchaseIndex;

  const EditPurchaseScreen({
    super.key,
    required this.purchase,
    required this.purchaseIndex,
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
    _supplierNameController = TextEditingController(text: widget.purchase.supplierName);
    _productNameController = TextEditingController(text: widget.purchase.productName);
    _quantityController = TextEditingController(text: widget.purchase.quantity.toString());
    _purchaseAmountController = TextEditingController(text: widget.purchase.purchaseAmount.toString());
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

      // Get old purchase details to revert stock changes
      final oldPurchase = AppData.purchasesBox.getAt(widget.purchaseIndex) as Purchase;

      // Revert stock changes from the old purchase
      await _updateStock(oldPurchase.productName, -oldPurchase.quantity);

      // Create the updated purchase object
      final updatedPurchase = Purchase(
        supplierName: _supplierNameController.text,
        productName: _productNameController.text,
        quantity: double.parse(_quantityController.text),
        purchaseAmount: double.parse(_purchaseAmountController.text),
        date: _selectedDate,
      );

      // Update stock changes for the new purchase
      await _updateStock(updatedPurchase.productName, updatedPurchase.quantity);

      // Save the updated purchase to Hive
      await AppData.purchasesBox.putAt(widget.purchaseIndex, updatedPurchase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase updated successfully!')),
        );
        Navigator.of(context).pop(); // Go back to detail screen
      }
    }
  }

  Future<void> _updateStock(String productName, double quantityChange) async {
    final List<Product> productsInStock = AppData.productsBox.values.toList();
    final int productIndex = productsInStock.indexWhere(
      (p) => p.name.toLowerCase() == productName.toLowerCase(),
    );

    if (productIndex != -1) {
      final Product existingProduct = productsInStock[productIndex];
      final updatedProduct = Product(
        name: existingProduct.name,
        quantity: existingProduct.quantity + quantityChange, // Add or subtract quantity
        unit: existingProduct.unit,
        purchasePrice: existingProduct.purchasePrice,
        sellingPrice: existingProduct.sellingPrice,
      );
      await AppData.productsBox.putAt(productIndex, updatedProduct);
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
        title: const Text('Edit Purchase'),
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
                decoration: const InputDecoration(labelText: 'Purchase Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchase amount';
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
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
