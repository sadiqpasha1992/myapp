import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import 'package:myapp/data/app_data.dart'; // Import our shared data file
import 'package:myapp/models/models.dart'; // Import Expense class

// ExpenseScreen is now a StatefulWidget because its content (form fields and the list of expenses)
// will change over time based on user interaction.

// ExpenseScreen is now a StatefulWidget because its content (form fields and the list of expenses)
// will change over time based on user interaction.
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

// This is the "State" class that holds the changeable data for ExpenseScreen.
class _ExpenseScreenState extends State<ExpenseScreen> {
  // TextEditingControllers for expense input fields
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // We no longer need a local List<Expense> here, as data will come directly from Hive.
  // final List<Expense> _expensesList = [];

  // Variable to hold the selected date for the expense
  DateTime _selectedDate = DateTime.now(); // Defaults to today's date

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

  // Method to save a new expense
  void _saveExpense() {
    final String description = _descriptionController.text.trim();
    final String amountString = _amountController.text.trim();
    final String category = _categoryController.text.trim();

    // Basic validation: Check if fields are not empty
    if (description.isEmpty || amountString.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all expense details!')),
      );
      return; // Stop the function if validation fails
    }

    // Parse amount to double, handle potential errors
    final double amount = double.tryParse(amountString) ?? 0.0;

    // Create a new Expense object
    final newExpense = Expense(
      description: description,
      amount: amount,
      category: category,
      date: _selectedDate, // Use the selected date
    );

    // Add to the Hive Box using AppData
    AppData.addExpense(newExpense)
        .then((_) {
          // Check if the widget is still mounted before using context
          if (!mounted) return;

          // Clear text fields after saving
          _descriptionController.clear();
          _amountController.clear();
          _categoryController.clear();
          _selectedDate = DateTime.now(); // Reset date to today

          // Show a confirmation message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense saved successfully!')),
          );
        })
        .catchError((error) {
          // Check if the widget is still mounted before using context
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save expense: $error')),
          );
        });
  }

  // Method to delete an expense
  void _deleteExpense(int index) {
    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          // Access expense details directly from the box for the dialog content
          content: Text(
            'Are you sure you want to delete the expense for "${AppData.expensesBox.getAt(index)?.description}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog before the async delete operation
                Navigator.of(dialogContext).pop();

                // Delete from the Hive Box using AppData
                AppData.deleteExpense(index)
                    .then((_) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expense deleted successfully!'),
                        ),
                      );
                    })
                    .catchError((error) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete expense: $error'),
                        ),
                      );
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red color for delete button
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
        title: const Text('Add Expense'),
        backgroundColor: Colors.red, // Distinct color for Expense
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Make the form and list scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align fields to the left
          children: [
            const Text(
              'Enter Expense Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24), // Space
            // Date Picker Field
            ListTile(
              title: Text(
                'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context), // Call date picker method
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

            // Expense Description Text Field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Office Rent for June',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.description),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Expense Amount Text Field
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'e.g., 15000.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number, // Suggests a numeric keyboard
            ),
            const SizedBox(height: 16),

            // Expense Category Text Field (for now, simple text input)
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Utilities, Salaries, Marketing',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.category),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),

            // Save Expense Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveExpense,
                icon: const Icon(Icons.save),
                label: const Text('Save Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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

            // --- Section: Displaying Saved Expenses ---
            // Use ValueListenableBuilder to automatically rebuild when Hive box changes
            ValueListenableBuilder(
              valueListenable:
                  AppData.expensesBox
                      .listenable(), // Listen for changes in the 'expenses' box
              builder: (context, Box<Expense> box, _) {
                // Get the current list of expenses from the box
                final List<Expense> expenses = box.values.toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Expenses (${expenses.length})', // Shows count of expenses from Hive
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    expenses.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No expenses recorded yet. Add your first expense above!',
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
                            maxHeight:
                                MediaQuery.of(context).size.height *
                                0.5, // Max height of the list
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount:
                                expenses.length, // Use the list from Hive
                            itemBuilder: (context, index) {
                              final expense =
                                  expenses[index]; // Use the expense from Hive

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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.description,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Amount: ₹ ${expense.amount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Category: ${expense.category}',
                                            ),
                                            Text(
                                              'Date: ${expense.date.day}/${expense.date.month}/${expense.date.year}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteExpense(index),
                                        tooltip: 'Delete Expense',
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
