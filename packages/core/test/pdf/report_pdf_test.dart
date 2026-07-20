import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('buildReportPdf produces valid PDF bytes', () async {
    final bytes = await buildReportPdf(
      studentName: 'Sam Rivera', companyName: 'Nimbus Analytics',
      reliability: 5, skill: 4, communication: 5,
      narrative: 'Owned a metric end to end and communicated clearly each week.',
    );
    expect(bytes.length, greaterThan(800));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
