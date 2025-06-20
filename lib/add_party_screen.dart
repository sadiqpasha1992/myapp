// lib/add_party_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart';

class AddPartyScreen extends StatefulWidget {
  final Party? partyToEdit;
  final int? partyIndex;

  const AddPartyScreen({super.key, this.partyToEdit, this.partyIndex});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstNumberController;
  late TextEditingController _emailController;
  String? _selectedPartyType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.partyToEdit?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.partyToEdit?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.partyToEdit?.address ?? '',
    );
    _gstNumberController = TextEditingController(
      text: widget.partyToEdit?.gstNumber ?? '',
    );
    _emailController = TextEditingController(
      text: widget.partyToEdit?.email ?? '',
    );
    _selectedPartyType = widget.partyToEdit?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstNumberController.dispose();
    _emailController.dispose();
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
        id: widget.partyToEdit?.id ?? const Uuid().v4(), // Use existing ID if editing, otherwise generate new
        name: _nameController.text.trim(),
        type: _selectedPartyType!,
        phone:
            _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
        address:
            _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
        gstNumber:
            _gstNumberController.text.trim().isNotEmpty
                ? _gstNumberController.text.trim()
                : null,
        email:
            _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
      );

      try {
        if (widget.partyToEdit == null) {
          await AppData.partiesBox.add(newParty);
          if (!mounted) return; // Add mounted check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party added successfully!')),
          );
        } else {
          await AppData.partiesBox.putAt(widget.partyIndex!, newParty);
          if (!mounted) return; // Add mounted check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party updated successfully!')),
          );
        }
        if (!mounted) return; // Add mounted check
        Navigator.pop(context);
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
              // Party Type
              DropdownButtonFormField<String>(
                value: _selectedPartyType,
                decoration: InputDecoration(
                  // Use InputDecoration directly for DropdownButtonFormField
                  labelText: 'Party Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.category),
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
              const SizedBox(height: 20),
              // Party Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Party Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter party name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              // Address
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              // GST Number
              TextFormField(
                controller: _gstNumberController,
                decoration: InputDecoration(
                  labelText: 'GST Number (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded border
                  ),
                  prefixIcon: const Icon(Icons.business),
                ),
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
