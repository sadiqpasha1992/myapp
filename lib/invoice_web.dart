import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pdf/widgets.dart' as pw;

import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:myapp/data/app_data.dart'; // Import Sale model

Future<void> saveAndLaunchInvoice(
    BuildContext context, pw.Document pdf, Sale selectedSale) async {
  final bytes = await pdf.save(); // Get PDF bytes (Uint8List)

  // Create an empty JSArray of BlobPart
  final JSArray<web.BlobPart> jsBlobParts = JSArray<web.BlobPart>();

  // Add the Uint8List to the JSArray, casting it to BlobPart
  jsBlobParts.add(bytes as web.BlobPart);

  // Create a Blob from the JSArray
  final blob = web.Blob(
    jsBlobParts,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  // Create a URL for the Blob using web.URL
  final url = web.URL.createObjectURL(blob);
  final String filename = 'invoice_${selectedSale.customerName}_${selectedSale.date.millisecondsSinceEpoch}.pdf';

  // Create a temporary anchor element and click it to trigger download
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.setAttribute('download', filename);
  anchor.click();
  web.URL.revokeObjectURL(url); // Clean up the URL after download is initiated

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invoice "$filename" download initiated! Check your downloads.')),
  );
}
