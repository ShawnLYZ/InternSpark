import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('Profile.fromJson maps id + role wire value', () {
    final p = Profile.fromJson({'id': 'u1', 'role': 'employer'});
    expect(p.id, 'u1');
    expect(p.role, UserRole.employer);
  });

  test('StudentProfile.fromJson maps snake_case columns', () {
    final s = StudentProfile.fromJson({
      'profile_id': 'u1', 'university_id': 'x', 'full_name': 'Sam Rivera', 'major': 'CS',
    });
    expect(s.profileId, 'u1');
    expect(s.universityId, 'x');
    expect(s.fullName, 'Sam Rivera');
    expect(s.major, 'CS');
  });

  test('Company + University fromJson map id + name', () {
    expect(Company.fromJson({'id': 'c1', 'name': 'Nimbus'}).name, 'Nimbus');
    expect(University.fromJson({'id': 'v1', 'name': 'Springfield'}).name, 'Springfield');
  });
}
