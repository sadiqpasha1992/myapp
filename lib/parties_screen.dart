import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive for ValueListenableBuilder
import '../data/app_data.dart'; // Import our shared data file

// Party class is defined in app_data.dart

// PartiesScreen is now a StatefulWidget because its content (form fields and the list of parties)
// will change over time based on user interaction.
class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

// This is the "State" class that holds the changeable data for PartiesScreen.
class _PartiesScreenState extends State<PartiesScreen> {
  // TextEditingControllers for party input fields
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // We no longer need a local List<Party> here, as data will come directly from Hive.
  // final List<Party> _partiesList = [];

  // Variable to hold the selected party type (Customer or Supplier)
  String _selectedPartyType = 'Customer'; // Default value

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _partyNameController.dispose();
    _gstNumberController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // Method to save a new party
  void _saveParty() {
    final String name = _partyNameController.text.trim();
    final String gstNumber = _gstNumberController.text.trim();
    final String address = _addressController.text.trim();
    final String contact = _contactController.text.trim();

    // Basic validation
    if (name.isEmpty || contact.isEmpty) {
      // Name and contact are mandatory
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Party Name and Contact!')),
      );
      return;
    }

    // Create new Party object
    final newParty = Party(
      name: name,
      gstNumber: gstNumber.isNotEmpty ? gstNumber : 'N/A', // Store N/A if empty
      address: address.isNotEmpty ? address : 'N/A', // Store N/A if empty
      contact: contact,
      type: _selectedPartyType,
    );

    // Add to the Hive Box using AppData
    AppData.addParty(newParty)
        .then((_) {
          // Check if the widget is still mounted before using context
          if (!mounted) return; // FIX ADDED HERE

          // Clear text fields after saving
          _partyNameController.clear();
          _gstNumberController.clear();
          _addressController.clear();
          _contactController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party added successfully!')),
          );
        })
        .catchError((error) {
          // Check if the widget is still mounted before using context
          if (!mounted) return; // FIX ADDED HERE
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add party: $error')),
          );
        });
  }

  // Method to delete a party
  void _deleteParty(int index) {
    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use dialogContext to avoid confusion
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          // Access party details directly from the box for the dialog content
          content: Text(
            'Are you sure you want to delete "${AppData.partiesBox.getAt(index)?.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(); // Close the dialog using dialogContext
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close the dialog before the async delete operation
                Navigator.of(dialogContext).pop(); // Use dialogContext

                // Delete from the Hive Box using AppData
                AppData.deleteParty(index)
                    .then((_) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return; // FIX ADDED HERE
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Party deleted successfully!'),
                        ),
                      );
                    })
                    .catchError((error) {
                      // Check if the widget is still mounted before using context
                      if (!mounted) return; // FIX ADDED HERE
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete party: $error'),
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
        title: const Text('Parties (Customers/Suppliers)'),
        backgroundColor: Colors.indigo, // Distinct color for Parties
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Party:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Party Type Selector (Customer/Supplier)
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Customer'),
                    value: 'Customer',
                    groupValue: _selectedPartyType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPartyType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Supplier'),
                    value: 'Supplier',
                    groupValue: _selectedPartyType,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPartyType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Party Name Text Field
            TextField(
              controller: _partyNameController,
              decoration: const InputDecoration(
                labelText: 'Party Name',
                hintText: 'e.g., ABC Traders',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.business),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // GST Number Text Field
            TextField(
              controller: _gstNumberController,
              decoration: const InputDecoration(
                labelText: 'GST Number (Optional)',
                hintText: 'e.g., 29ABCDE1234F1Z5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Address Text Field
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (Optional)',
                hintText: 'e.g., 123 Main St, City, State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.streetAddress,
              maxLines: 2, // Allow multiple lines for address
            ),
            const SizedBox(height: 16),

            // Contact Text Field (Phone/Email)
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact (Phone or Email)',
                hintText: 'e.g., +91 9876543210 or example@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.contact_phone),
              ),
              keyboardType: TextInputType.text, // Can be phone or email
            ),
            const SizedBox(height: 24),

            // Save Party Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveParty,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Party'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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

            // --- Section: Displaying Stored Parties ---
            // Use ValueListenableBuilder to automatically rebuild when Hive box changes
            ValueListenableBuilder(
              valueListenable:
                  AppData.partiesBox
                      .listenable(), // Listen for changes in the 'parties' box
              builder: (context, Box<Party> box, _) {
                // Get the current list of parties from the box
                final List<Party> parties = box.values.toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Parties (${parties.length})', // Shows count of parties from Hive
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    parties.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No parties added yet. Add your first customer or supplier above!',
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
                            itemCount: parties.length, // Use the list from Hive
                            itemBuilder: (context, index) {
                              final party =
                                  parties[index]; // Use the party from Hive

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
                                              party.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Type: ${party.type}'),
                                            Text('Contact: ${party.contact}'),
                                            if (party.gstNumber != 'N/A')
                                              Text('GSTIN: ${party.gstNumber}'),
                                            if (party.address != 'N/A')
                                              Text('Address: ${party.address}'),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _deleteParty(
                                              index,
                                            ), // Call delete method
                                        tooltip: 'Delete Party',
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
