import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generateInvoiceBytes({
    required String invoiceNumber,
    required String farmerName,
    required String farmerVillage,
    required String farmerDistrict,
    required String farmerPhone,
    required String buyerName,
    required String buyerAddress,
    required String buyerPhone,
    required String cropName,
    required String variety,
    required int packSizeKg,
    required int quantityPacks,
    required double pricePerKg,
    required double deliveryFee,
    required String paymentMode,
  }) async {
    final pdf = pw.Document();

    final totalKg = packSizeKg * quantityPacks;
    final produceTotal = totalKg * pricePerKg;
    final grandTotal = produceTotal + deliveryFee;
    final formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32.0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'UPAJO (उपजो)',
                        style: pw.TextStyle(fontSize: 24.0, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                      ),
                      pw.Text(
                        'Direct Farmer-to-Consumer Platform',
                        style: const pw.TextStyle(fontSize: 10.0, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FARM PRODUCE INVOICE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.0)),
                      pw.Text('Invoice #: $invoiceNumber', style: const pw.TextStyle(fontSize: 10.0)),
                      pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 10.0)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.green800),
              pw.SizedBox(height: 14.0),

              // Parties details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FARMER (SELLER):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11.0, color: PdfColors.green900)),
                        pw.SizedBox(height: 3.0),
                        pw.Text(farmerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12.0)),
                        pw.Text('Village: $farmerVillage, $farmerDistrict'),
                        pw.Text('Phone: +91 $farmerPhone'),
                        pw.Text('GST Category: Agricultural Exempt (Sec 23 CGST)'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BUYER (CUSTOMER):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11.0, color: PdfColors.green900)),
                        pw.SizedBox(height: 3.0),
                        pw.Text(buyerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12.0)),
                        pw.Text('Address: $buyerAddress'),
                        pw.Text('Phone: +91 $buyerPhone'),
                        pw.Text('Payment Mode: $paymentMode'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20.0),

              // Line Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.0),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _th('Produce Description'),
                      _th('Pack Size'),
                      _th('Qty'),
                      _th('Rate (Rs/kg)'),
                      _th('Amount (Rs)'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _td('$cropName - $variety\nDirect Farmgate Harvest'),
                      _td('$packSizeKg kg'),
                      _td('$quantityPacks'),
                      _td('Rs ${pricePerKg.toStringAsFixed(2)}'),
                      _td('Rs ${produceTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14.0),

              // Totals breakdown
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 220.0,
                  child: pw.Column(
                    children: [
                      _summaryRow('Produce Subtotal:', 'Rs ${produceTotal.toStringAsFixed(2)}'),
                      _summaryRow('Delivery Charges:', 'Rs ${deliveryFee.toStringAsFixed(2)}'),
                      _summaryRow('Platform Commission:', 'Rs 0.00 (0% Promo)'),
                      pw.Divider(thickness: 1.0),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Paid:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.0)),
                          pw.Text('Rs ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.0, color: PdfColors.green800)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // Footer with farmer declaration
              pw.Container(
                padding: const pw.EdgeInsets.all(10.0),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6.0)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Declaration:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    pw.Text(
                      'This is a digitally generated invoice for direct agricultural produce. No GST is applicable under Section 23 of the Central Goods and Services Tax Act. 100% of the produce value is credited directly to the farmer.',
                      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12.0),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Verified by Upajo Digital Trust', style: const pw.TextStyle(fontSize: 9.0, color: PdfColors.grey600)),
                  pw.Text('Authorized Farmer Signature', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6.0),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
    );
  }

  static pw.Widget _td(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6.0),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5)),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10.0, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10.0, color: PdfColors.black)),
        ],
      ),
    );
  }

  static Future<void> printOrShareInvoice({
    required String invoiceNumber,
    required String farmerName,
    required String farmerVillage,
    required String farmerDistrict,
    required String farmerPhone,
    required String buyerName,
    required String buyerAddress,
    required String buyerPhone,
    required String cropName,
    required String variety,
    required int packSizeKg,
    required int quantityPacks,
    required double pricePerKg,
    required double deliveryFee,
    required String paymentMode,
  }) async {
    final pdfBytes = await generateInvoiceBytes(
      invoiceNumber: invoiceNumber,
      farmerName: farmerName,
      farmerVillage: farmerVillage,
      farmerDistrict: farmerDistrict,
      farmerPhone: farmerPhone,
      buyerName: buyerName,
      buyerAddress: buyerAddress,
      buyerPhone: buyerPhone,
      cropName: cropName,
      variety: variety,
      packSizeKg: packSizeKg,
      quantityPacks: quantityPacks,
      pricePerKg: pricePerKg,
      deliveryFee: deliveryFee,
      paymentMode: paymentMode,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_$invoiceNumber.pdf',
    );
  }
}

