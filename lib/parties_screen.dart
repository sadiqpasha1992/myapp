// lib/parties_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for ValueListenableBuilder
import 'package:myapp/data/app_data.dart';
import 'package:myapp/models/models.dart'; // Ensure Party model is here
import 'package:myapp/add_party_screen.dart'; // Import the new screen

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: AppData.partiesBox.listenable(),
        builder: (context, Box<Party> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No parties added yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tap the + button to add a new party.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final party = box.getAt(index)!;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        party.type == 'Customer'
                            ? Colors.blueAccent
                            : Colors.orangeAccent,
                    child: Icon(
                      party.type == 'Customer' ? Icons.person : Icons.business,
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
                      if (party.contactNumber.isNotEmpty) // Check if contactNumber is not empty
                        Text('Phone: ${party.contactNumber}'), // Use contactNumber
                      if (party.address.isNotEmpty)
                        Text('Address: ${party.address}'),
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
                                    partyIndex: index,
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
                                      box.deleteAt(index);
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
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => PartyDetailViewScreen(party: party)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the AddPartyScreen when the FAB is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPartyScreen()),
          );
        },
        backgroundColor: Colors.purple, // Matching the app bar
        foregroundColor: Colors.white,
        child: const Icon(Icons.add), // Plus icon
      ),
    );
  }
}
