import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('UserRole round-trips through its wire value', () {
    for (final role in UserRole.values) {
      expect(UserRole.fromWire(role.wire), role);
    }
  });

  test('UserRole.fromWire rejects unknown values', () {
    expect(() => UserRole.fromWire('admin'), throwsArgumentError);
  });
}
