import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('buildCreditPdf renders the mapping to valid PDF bytes', () async {
    const mapping = CreditMapping(
      summary: 'This internship satisfies 2 core data requirements.',
      satisfied: [
        CreditSatisfied(skill: 'SQL', evidence: 'Built production dashboards.'),
        CreditSatisfied(skill: 'Statistics', evidence: 'Owned a weekly metric.'),
      ],
    );
    final bytes = await buildCreditPdf(
      jobTitle: 'Data Analyst Intern', studentName: 'Sam Rivera', mapping: mapping);
    expect(bytes.length, greaterThan(800));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
