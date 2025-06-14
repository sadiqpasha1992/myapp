import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import your Sale model

class EditSaleScreen extends StatefulWidget {
  final Sale sale;
  final int saleIndex;

  const EditSaleScreen({
    super.key,
    required this.sale,
    required this.saleIndex,
  });

  @override
  EditSaleScreenState createState() => EditSaleScreenState();
}

class EditSaleScreenState extends State<EditSaleScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(text: widget.sale.customerName);
    _amountController = TextEditingController(text: widget.sale.saleAmount.toString());
    _dateController = TextEditingController(text: widget.sale.date.toString());
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sale'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Edit screen for sale to ${widget.sale.customerName} (Index: ${widget.saleIndex})',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
