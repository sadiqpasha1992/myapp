// lib/add_party_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart'; // Ensure Party model is here
import 'package:uuid/uuid.dart'; // Import uuid package

class AddPartyScreen extends StatefulWidget {
  final Party? partyToEdit; // Optional: for editing existing parties
  final int? partyIndex; // Optional: index if editing

  const AddPartyScreen({super.key, this.partyToEdit, this.partyIndex});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstNumberController; // Controller for GST number
  String? _selectedPartyType; // 'Customer' or 'Vendor'

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.partyToEdit?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.partyToEdit?.contactNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.partyToEdit?.address ?? '',
    );
    _gstNumberController = TextEditingController( // Initialize GST number controller
      text: widget.partyToEdit?.gstNumber ?? '',
    );
    _selectedPartyType = widget.partyToEdit?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstNumberController.dispose(); // Dispose GST number controller
    super.dispose();
  }

  void _saveParty() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedPartyType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a party type (Customer/Vendor).'),
          ),
        );
        return;
      }

      final newParty = Party(
        id: widget.partyToEdit?.id ?? const Uuid().v4(), // Use existing ID or generate new
        name: _nameController.text.trim(),
        type: _selectedPartyType!,
        contactNumber: _phoneController.text.trim(), // Pass non-nullable string
        address: _addressController.text.trim(), // Pass non-nullable string
        gstNumber: _gstNumberController.text.trim(), // Pass GST number
      );

      try {
        if (widget.partyToEdit == null) {
          // Add new party
          await AppData.partiesBox.add(newParty);
          if (!mounted) return; // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party added successfully!')),
          );
        } else {
          // Update existing party
          await AppData.partiesBox.putAt(widget.partyIndex!, newParty);
          if (!mounted) return; // Check if the widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party updated successfully!')),
          );
        }
        Navigator.pop(context); // Go back to PartiesScreen
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save party: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.partyToEdit == null ? 'Add New Party' : 'Edit Party',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter party name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              TextFormField( // Add GST Number field
                controller: _gstNumberController,
                decoration: const InputDecoration(
                  labelText: 'GST Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedPartyType,
                decoration: const InputDecoration(
                  labelText: 'Party Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text('Select Party Type'),
                items:
                    <String>[
                      'Customer',
                      'Vendor',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPartyType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a party type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveParty,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.partyToEdit == null ? 'Save Party' : 'Update Party',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
