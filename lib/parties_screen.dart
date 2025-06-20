// lib/parties_screen.dart (Corrected - Body Only + Data Logic Fixes)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart'; // Import our shared data file
import 'package:myapp/models/models.dart'; // Import models.dart for Party
import 'package:uuid/uuid.dart'; // For generating unique IDs

// PartiesScreen is now a StatefulWidget because its content (form fields and the list of parties)
// will change over time based on user interaction.
class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

// This is the "State" class that holds the changeable data for PartiesScreen.
class _PartiesScreenState extends State<PartiesScreen> {
  final _formKey = GlobalKey<FormState>(); // Added a Form key for validation
  // TextEditingControllers for party input fields
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController(); // Renamed for consistency with model

  // Variable to hold the selected party type (Customer or Supplier)
  String _selectedPartyType = 'Customer'; // Default value

  // Dispose controllers to free up memory when the widget is removed
  @override
  void dispose() {
    _partyNameController.dispose();
    _gstNumberController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose(); // Dispose correct controller
    super.dispose();
  }

  // Method to save a new party
  void _saveParty() async {
    // Made async to await AppData.addParty
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }

    final String name = _partyNameController.text.trim();
    final String gstNumber = _gstNumberController.text.trim();
    final String address = _addressController.text.trim();
    final String contactNumber =
        _contactNumberController.text.trim(); // Use contactNumber

    // Check for duplicate party name before adding
    final bool partyExists = AppData.partiesBox.values.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );

    if (partyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party with this name already exists!')),
      );
      return;
    }
  
    // Create new Party object
    final newParty = Party(
      id: const Uuid().v4(), // Generate unique ID
      name: name,
      type: _selectedPartyType,
      contactNumber: contactNumber,
      address: address.isNotEmpty ? address : 'N/A', // Store N/A if empty
      gstNumber:
          gstNumber.isNotEmpty
              ? gstNumber
              : 'N/A', // Add gstNumber to the model
    );

    try {
      await AppData.addParty(newParty); // Use await
      if (!mounted) return;

      // Clear text fields after saving
      _partyNameController.clear();
      _gstNumberController.clear();
      _addressController.clear();
      _contactNumberController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Party added successfully!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add party: $e')));
      }
    }
  }

  // Method to delete a party by its ID
  void _deleteParty(String partyId, String partyName) {
    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete "$partyName"? This action cannot be undone.',
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
                // Made async to await AppData.deleteParty
                Navigator.of(dialogContext).pop();
                final currentContext = context; // Capture context
                try {
                  await AppData.deleteParty(partyId); // Delete by ID
                  if (currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Party deleted successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (currentContext.mounted) {
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      SnackBar(content: Text('Failed to delete party: $e')),
                    );
                  }
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

  @override
  Widget build(BuildContext context) {
    // --- IMPORTANT: Scaffold and AppBar have been REMOVED! ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        // Wrap with Form for validation
        key: _formKey,
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
            TextFormField(
              // Changed to TextFormField for validation
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter party name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // GST Number Text Field
            TextFormField(
              // Changed to TextFormField for validation
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
              // No validator for optional field
            ),
            const SizedBox(height: 16),

            // Address Text Field
            TextFormField(
              // Changed to TextFormField for validation
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
              maxLines: 2,
              // No validator for optional field
            ),
            const SizedBox(height: 16),

            // Contact Number Text Field
            TextFormField(
              // Changed to TextFormField for validation
              controller: _contactNumberController, // Use correct controller
              decoration: const InputDecoration(
                labelText: 'Contact Number', // Changed label
                hintText: 'e.g., +91 9876543210',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                prefixIcon: Icon(Icons.contact_phone),
              ),
              keyboardType: TextInputType.phone, // Changed to phone
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact number';
                }
                // Basic regex for phone number validation (optional, can be more complex)
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Please enter a valid number';
                }
                return null;
              },
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
            ValueListenableBuilder<Box<Party>>(
              // Explicitly define Box type
              valueListenable: AppData.partiesBox.listenable(),
              builder: (context, Box<Party> box, _) {
                final List<Party> parties = box.values.toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Parties (${parties.length})',
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
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: parties.length,
                            itemBuilder: (context, index) {
                              final party = parties[index];

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
                                            Text(
                                              'Contact: ${party.contactNumber}',
                                            ), // Use contactNumber
                                            if (party.gstNumber !=
                                                'N/A') // Conditionally display GSTIN
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
                                              party
                                                  .id, // Pass the party's ID for deletion
                                              party.name,
                                            ),
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
