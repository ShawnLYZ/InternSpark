import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('buildResumePdf produces non-empty PDF bytes with the %PDF header', () async {
    const r = ResumeJson(
      name: 'Sam Rivera', headline: 'Aspiring data analyst', summary: 'Builds dashboards.',
      sections: [ResumeSection(title: 'Experience', bullets: ['TA for CS101', 'Class dashboard'])],
    );
    final bytes = await buildResumePdf(r);
    expect(bytes.length, greaterThan(800));
    // PDF magic bytes: %PDF
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
