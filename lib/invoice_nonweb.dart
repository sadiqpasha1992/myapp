import 'dart:io'; // Import for File operations
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // Import for getting directory paths
import 'package:open_filex/open_filex.dart'; // Import for opening the file


import 'package:myapp/models/models.dart'; // Import Sale model

Future<void> saveAndLaunchInvoice(
    BuildContext context, pw.Document pdf, Sale selectedSale) async {
  try {
    final bytes = await pdf.save(); // Get PDF bytes

    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final String filename = 'invoice_${selectedSale.customerId}_${selectedSale.saleDate.millisecondsSinceEpoch}.pdf';
    final File file = File('${directory.path}/$filename');

    // Write the PDF bytes to the file
    await file.writeAsBytes(bytes);

    // Open the file
    await OpenFilex.open(file.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice "$filename" saved to ${directory.path} and opened.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving or opening invoice: $e')),
      );
    }
  }
}
