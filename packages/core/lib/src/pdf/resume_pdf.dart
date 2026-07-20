import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/resume.dart';

/// The single InternSpark PDF renderer (reused for Phase 3 reports + credit docs).
/// One clean template. Pure Dart — produces bytes with no platform plugins.
Future<Uint8List> buildResumePdf(ResumeJson r) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(r.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          if (r.headline.isNotEmpty) pw.Text(r.headline, style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 12),
          if (r.summary.isNotEmpty) pw.Text(r.summary),
          pw.SizedBox(height: 12),
          for (final s in r.sections) ...[
            pw.Text(s.title, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            for (final b in s.bullets) pw.Bullet(text: b),
            pw.SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
  return doc.save();
}
