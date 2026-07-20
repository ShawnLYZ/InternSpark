import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';

void main() {
  test('FakeStudentRepository returns configured values', () async {
    final repo = FakeStudentRepository(
      studentProfile: const StudentProfile(profileId: 'u1', universityId: 'x', fullName: 'Sam Rivera'),
      jobCount: 5,
    );
    expect((await repo.fetchMyStudentProfile())?.fullName, 'Sam Rivera');
    expect(await repo.countAvailableJobs(), 5);
  });

  test('FakeEmployerRepository + FakeUniversityRepository echo their data', () async {
    final emp = FakeEmployerRepository(company: const Company(id: 'c1', name: 'Nimbus'), jobCount: 3);
    final uni = FakeUniversityRepository(university: const University(id: 'v1', name: 'Springfield'), studentCount: 1);
    expect((await emp.fetchMyCompany())?.name, 'Nimbus');
    expect(await emp.countMyJobs(), 3);
    expect((await uni.fetchMyUniversity())?.name, 'Springfield');
    expect(await uni.countMyStudents(), 1);
  });
}
