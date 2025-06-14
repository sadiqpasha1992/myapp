import 'package:flutter/material.dart';
import 'package:myapp/data/app_data.dart'; // Import AppData for sales data
import 'package:hive_flutter/hive_flutter.dart'; // Import for ValueListenableBuilder
import 'package:pdf/pdf.dart'; // Import for PDF color definitions
import 'package:pdf/widgets.dart' as pw; // Import 'pdf/widgets.dart' with alias 'pw'
import 'invoice_web.dart' if (dart.library.io) 'invoice_nonweb.dart'; // Platform-specific import

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Sale? _selectedSale; // Holds the currently selected sale for invoice generation

  // Function to generate the PDF invoice
  Future<void> _generateInvoicePdf() async {
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sale to generate an invoice.')),
      );
      return;
    }

    final pdf = pw.Document(); // Create a new PDF document

    // Add content to the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Standard A4 paper size
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('INVOICE', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 20),

              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BizFlow Business', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('123 Business Lane'),
                      pw.Text('City, State, Zip Code'),
                      pw.Text('Email: info@bizflow.com'),
                      pw.Text('Phone: +91 98765 43210'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Invoice Date: ${_selectedSale!.date.day}/${_selectedSale!.date.month}/${_selectedSale!.date.year}'),
                      pw.Text('Invoice No: #${_selectedSale!.date.millisecondsSinceEpoch.toString().substring(5, 10)}'), // Simple invoice number
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Bill To Section
              pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_selectedSale!.customerName),
              // Add more customer details if available in Party model and linked
              pw.SizedBox(height: 20),

              // Item Details Table
              pw.TableHelper.fromTextArray(
                headers: ['Product', 'Quantity', 'Unit Price', 'Total'],
                data: [
                  [_selectedSale!.productName, _selectedSale!.quantity, '₹ ${_selectedSale!.saleAmount}', '₹ ${_selectedSale!.saleAmount}'],
                  // Add more items if your sale could contain multiple products
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueAccent),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                border: pw.TableBorder.all(color: PdfColors.blueGrey200),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
              ),
              pw.SizedBox(height: 20),

              // Totals
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Divider(),
                    pw.Text('Subtotal: ₹ ${_selectedSale!.saleAmount}'),
                    pw.Text('Tax (0%): ₹ 0.00'), // Placeholder for tax
                    pw.Text('Discount (0%): ₹ 0.00'), // Placeholder for discount
                    pw.Divider(),
                    pw.Text('GRAND TOTAL: ₹ ${_selectedSale!.saleAmount}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              pw.Center(
                child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    // Save or launch the PDF using platform-specific implementation
    if (context.mounted) {
      await saveAndLaunchInvoice(context, pdf, _selectedSale!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Sale to Generate Invoice:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Dropdown to select a sale
            ValueListenableBuilder(
              valueListenable: AppData.salesBox.listenable(),
              builder: (context, Box<Sale> salesBox, _) {
                final List<Sale> sales = salesBox.values.toList();
                sales.sort((a, b) => b.date.compareTo(a.date)); // Sort by most recent first

                // Ensure _selectedSale is still in the list if it was previously selected
                // This prevents "value not in items" error if data was cleared.
                if (_selectedSale != null && !sales.contains(_selectedSale)) {
                  _selectedSale = null; // Clear selection if it's no longer valid
                }


                return DropdownButtonFormField<Sale>(
                  decoration: const InputDecoration(
                    labelText: 'Select Sale',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                  value: _selectedSale,
                  hint: const Text('Choose a sale'),
                  items: sales.map((sale) {
                    return DropdownMenuItem<Sale>(
                      value: sale,
                      child: Text('${sale.customerName} - ${sale.productName} (₹ ${sale.saleAmount}) on ${sale.date.day}/${sale.date.month}/${sale.date.year}'),
                    );
                  }).toList(),
                  onChanged: (Sale? newValue) {
                    setState(() {
                      _selectedSale = newValue;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Display selected sale details
            if (_selectedSale != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Sale Details:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
                      ),
                      const Divider(),
                      Text('Customer: ${_selectedSale!.customerName}'),
                      Text('Product: ${_selectedSale!.productName}'),
                      Text('Quantity: ${_selectedSale!.quantity}'),
                      Text('Amount: ₹ ${_selectedSale!.saleAmount}'),
                      Text('Date: ${_selectedSale!.date.day}/${_selectedSale!.date.month}/${_selectedSale!.date.year}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Generate Invoice Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateInvoicePdf, // Call PDF generation function
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Invoice PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
