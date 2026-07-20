import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('commentGate', () {
    test('warns when the company has filed no report about this student', () {
      final r = commentGate(studentId: 's1', companyId: 'c1', reports: const []);
      expect(r.warn, isTrue);
    });

    test('does not warn when a matching report exists', () {
      final r = commentGate(
        studentId: 's1', companyId: 'c1',
        reports: const [ReportRef(studentId: 's1', companyId: 'c1')],
      );
      expect(r.warn, isFalse);
    });

    test('a report about a different student/company still warns', () {
      final r = commentGate(
        studentId: 's1', companyId: 'c1',
        reports: const [
          ReportRef(studentId: 's2', companyId: 'c1'),
          ReportRef(studentId: 's1', companyId: 'c9'),
        ],
      );
      expect(r.warn, isTrue);
    });
  });
}
