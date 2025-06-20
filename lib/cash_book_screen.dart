import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import 'package:myapp/data/app_data.dart'; // Import our shared data file
import 'package:myapp/models/models.dart'; // Import CashTransaction class

// CashBookScreen is a StatefulWidget to manage the form inputs and transaction list.
class CashBookScreen extends StatefulWidget {
  const CashBookScreen({super.key});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

// This is the "State" class that holds the changeable data for CashBookScreen.
class _CashBookScreenState extends State<CashBookScreen> {
  // TextEditingControllers for cash transaction input fields
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Variable to hold the selected date for the transaction
  DateTime _selectedDate = DateTime.now(); // Defaults to today's date

  // Variable to hold the selected transaction type (Inflow or Outflow)
  String _selectedType = 'Inflow'; // Default to Inflow

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Method to show a date picker
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

  // Method to save a new cash transaction
  void _saveCashTransaction() {
    final String description = _descriptionController.text.trim();
    final String amountStr = _amountController.text.trim();
    final String category = _categoryController.text.trim();

    // Basic validation
    if (description.isEmpty || amountStr.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all transaction details!')),
      );
      return;
    }

    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount!')),
      );
      return;
    }

    // Create new CashTransaction object
    final newTransaction = CashTransaction(
      description: description,
      amount: amount,
      type: _selectedType,
      date: _selectedDate,
    );

    // Add to the Hive Box using AppData
    AppData.addCashTransaction(newTransaction)
        .then((_) {
          if (!mounted) return; // Check if the widget is still mounted

          // Clear text fields after saving
          _descriptionController.clear();
          _amountController.clear();
          _categoryController.clear();
          _selectedDate = DateTime.now(); // Reset date to today

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction saved successfully!')),
          );
        })
        .catchError((error) {
          if (!mounted) return; // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save transaction: $error')),
          );
        });
  }

  // Method to delete a cash transaction
  void _deleteCashTransaction(int index) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the transaction "${AppData.cashTransactionsBox.getAt(index)?.description}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Delete from the Hive Box using AppData
                AppData.deleteCashTransaction(index)
                    .then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction deleted successfully!'),
                        ),
                      );
                    })
                    .catchError((error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete transaction: $error'),
                        ),
                      );
                    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Book'),
        backgroundColor: Colors.blueGrey, // Distinct color for Cash Book
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Cash Transaction:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Transaction Type Selector (Inflow/Outflow)
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Inflow'),
                    value: 'Inflow',
                    groupValue: _selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Outflow'),
                    value: 'Outflow',
                    groupValue: _selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Picker Field
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
            const SizedBox(height: 16),

            // Description Text Field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Sales Payment from ABC Co.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.note),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Amount Text Field
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g., 5000.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Category Text Field
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText:
                    'e.g., Sales Payment, Loan Received, Rent, Electricity Bill',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.category),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),

            // Save Transaction Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCashTransaction,
                icon: const Icon(Icons.save),
                label: const Text('Save Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
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

            // --- Section: Displaying Stored Transactions ---
            // Use ValueListenableBuilder to automatically rebuild when Hive box changes
            ValueListenableBuilder(
              valueListenable:
                  AppData.cashTransactionsBox
                      .listenable(), // Listen for changes
              builder: (context, Box<CashTransaction> box, _) {
                final List<CashTransaction> transactions = box.values.toList();
                // Sort by date (most recent first)
                transactions.sort((a, b) => b.date.compareTo(a.date));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Transactions (${transactions.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    transactions.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No cash transactions recorded yet. Add one above!',
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
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        transaction.type == 'Inflow'
                                            ? Icons.arrow_circle_up
                                            : Icons.arrow_circle_down,
                                        color:
                                            transaction.type == 'Inflow'
                                                ? Colors.green
                                                : Colors.red,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction.description,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Date: ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹ ${transaction.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              transaction.type == 'Inflow'
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.grey,
                                        ),
                                        onPressed:
                                            () => _deleteCashTransaction(index),
                                        tooltip: 'Delete Transaction',
                                      ),
                                    ],
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
