// lib/parties_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/add_party_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        // Use a Column to place search bar above the list
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search parties...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
            ),
          ),
          Expanded(
            // Expanded to make sure the list takes remaining space
            child: ValueListenableBuilder(
              valueListenable: AppData.partiesBox.listenable(),
              builder: (context, Box<Party> box, _) {
                // Filter parties based on search query
                final List<Party> allParties = box.values.toList();
                final List<Party> filteredParties =
                    allParties.where((party) {
                      final query =
                          _searchQuery; // Already lowercased in _onSearchChanged

                      return party.name.toLowerCase().contains(query) ||
                          party.type.toLowerCase().contains(query) ||
                          (party.phone?.toLowerCase().contains(query) ??
                              false) ||
                          (party.address?.toLowerCase().contains(query) ??
                              false) ||
                          (party.email?.toLowerCase().contains(query) ??
                              false) || // Check email
                          (party.gstNumber?.toLowerCase().contains(query) ??
                              false); // Check GST
                    }).toList();

                if (filteredParties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No parties added yet.'
                              : 'No matching parties found.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty)
                          Text(
                            'Tap the + button to add a new party.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: filteredParties.length,
                  itemBuilder: (context, index) {
                    final party = filteredParties[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              party.type == 'Customer'
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent,
                          child: Icon(
                            party.type == 'Customer'
                                ? Icons.person
                                : Icons.business,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          party.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${party.type}'),
                            if (party.email != null && party.email!.isNotEmpty)
                              Text('Email: ${party.email!}'), // Display Email
                            if (party.phone != null && party.phone!.isNotEmpty)
                              Text('Phone: ${party.phone!}'),
                            if (party.address != null &&
                                party.address!.isNotEmpty)
                              Text('Address: ${party.address!}'),
                            if (party.gstNumber != null &&
                                party.gstNumber!.isNotEmpty)
                              Text(
                                'GST: ${party.gstNumber!}',
                              ), // Display GST Number
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Navigate to AddPartyScreen for editing
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddPartyScreen(
                                          partyToEdit: party,
                                          // Pass the original index from the unfiltered list for Hive.putAt
                                          partyIndex: allParties.indexOf(party),
                                        ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Implement delete confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: const Text('Delete Party'),
                                      content: Text(
                                        'Are you sure you want to delete ${party.name}?',
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () {
                                            // Delete using the original index to avoid issues with filtered list
                                            box.deleteAt(
                                              allParties.indexOf(party),
                                            );
                                            Navigator.of(dialogContext).pop();
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${party.name} deleted.',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          // Optionally view party details more comprehensively
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPartyScreen()),
          );
        },
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
