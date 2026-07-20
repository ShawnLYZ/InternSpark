import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Employer→University performance report PDF (same renderer family as the resume).
Future<Uint8List> buildReportPdf({
  required String studentName,
  required String companyName,
  required int reliability,
  required int skill,
  required int communication,
  String? narrative,
}) async {
  final doc = pw.Document();
  pw.Widget row(String label, int v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 160, child: pw.Text(label)),
          pw.Text('$v / 5', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ]),
      );
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Performance Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text('Student: $studentName'),
      pw.Text('From: $companyName'),
      pw.SizedBox(height: 12),
      row('Reliability', reliability),
      row('Skill', skill),
      row('Communication', communication),
      pw.SizedBox(height: 12),
      if (narrative != null && narrative.isNotEmpty) ...[
        pw.Text('Narrative', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(narrative),
      ],
    ]),
  ));
  return doc.save();
}
