/// The three InternSpark personas; mirrors the Postgres `user_role` enum
/// and the `profiles.role` column.
enum UserRole {
  student,
  employer,
  university;

  /// Parses the wire value stored in `profiles.role`.
  static UserRole fromWire(String value) => switch (value) {
        'student' => UserRole.student,
        'employer' => UserRole.employer,
        'university' => UserRole.university,
        _ => throw ArgumentError('Unknown user_role: $value'),
      };

  /// The wire value as stored in Postgres.
  String get wire => name;
}
