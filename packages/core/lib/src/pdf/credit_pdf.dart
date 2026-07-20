import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/credit.dart';

/// Pre-filled compliance PDF for credit-to-career sync (shared renderer family).
Future<Uint8List> buildCreditPdf({
  required String jobTitle,
  required String studentName,
  required CreditMapping mapping,
}) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Credit Compliance Mapping', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text('Student: $studentName'),
      pw.Text('Internship: $jobTitle'),
      pw.SizedBox(height: 12),
      if (mapping.summary.isNotEmpty) pw.Text(mapping.summary),
      pw.SizedBox(height: 12),
      pw.Text('Satisfied requirements', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      for (final s in mapping.satisfied)
        pw.Bullet(text: '${s.skill}${s.evidence.isEmpty ? '' : ' — ${s.evidence}'}'),
      pw.SizedBox(height: 24),
      pw.Text('Approved by: ____________________   Date: ____________'),
    ]),
  ));
  return doc.save();
}
