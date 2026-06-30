import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/clients/domain/models/client_model.dart';
import '../../features/jobs/domain/models/job_model.dart';
import '../../features/payments/domain/models/payment_model.dart';

class PdfGenerator {
  // Fetch Cairo Arabic Font dynamically from Github or Google CDN
  static Future<pw.Font> _loadArabicFont() async {
    try {
      final response = await http.get(Uri.parse(
          'https://github.com/google/fonts/raw/main/ofl/cairo/Cairo-Regular.ttf'));
      if (response.statusCode == 200) {
        return pw.Font.ttf(ByteData.view(response.bodyBytes.buffer));
      }
    } catch (_) {}
    
    // Offline fallback: Use standard Helvetica (No Arabic shaping support, but compiles without crash)
    return pw.Font.helvetica();
  }

  static Future<void> generateAndShareStatement({
    required ClientModel client,
    required List<JobModel> jobs,
    required List<PaymentModel> payments,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();

    // Consolidate jobs and payments into a single list of transactions sorted by date
    final List<Map<String, dynamic>> transactions = [];
    
    for (var job in jobs) {
      transactions.add({
        'date': job.date,
        'type': 'Job',
        'desc': job.description,
        'debit': job.cost, // Customer owes money
        'credit': 0.0,
      });
    }

    for (var pay in payments) {
      transactions.add({
        'date': pay.date,
        'type': 'Payment',
        'desc': pay.notes.isEmpty ? 'Payment Received' : pay.notes,
        'debit': 0.0,
        'credit': pay.amount, // Customer paid money
      });
    }

    // Sort by date ascending
    transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Calculate running balances
    double runningBalance = 0.0;
    final List<List<String>> tableData = [];
    
    // Add header row (in English/Arabic depending on shaping)
    tableData.add(['Date', 'Description', 'Type', 'Debit (+)', 'Credit (-)', 'Balance']);

    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var tx in transactions) {
      runningBalance += tx['debit'] - tx['credit'];
      tableData.add([
        dateFormat.format(tx['date'] as DateTime),
        tx['desc'],
        tx['type'],
        tx['debit'] > 0 ? '${tx['debit']} EGP' : '-',
        tx['credit'] > 0 ? '${tx['credit']} EGP' : '-',
        '$runningBalance EGP',
      ]);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
        ),
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
                        'Workshop Account Statement',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Client: ${client.name}',
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                      pw.Text(
                        'Phone: ${client.phone}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date: ${dateFormat.format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Remaining Balance: ${client.currentBalance} EGP',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Financial Summary Table
              pw.TableHelper.fromTextArray(
                headers: tableData[0],
                data: tableData.sublist(1),
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Thank you for your business! - Workshop Manager',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save and Share PDF
    final Uint8List bytes = await pdf.save();
    
    // Save to temp file to share
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Statement_${client.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
