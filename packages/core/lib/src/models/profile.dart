import 'user_role.dart';

/// A row of `profiles` (1:1 with auth.users).
class Profile {
  const Profile({required this.id, required this.role});
  final String id;
  final UserRole role;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      Profile(id: json['id'] as String, role: UserRole.fromWire(json['role'] as String));
}
