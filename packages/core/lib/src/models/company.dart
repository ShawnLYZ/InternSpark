/// A row of `companies`.
class Company {
  const Company({required this.id, required this.name});
  final String id;
  final String name;

  factory Company.fromJson(Map<String, dynamic> json) =>
      Company(id: json['id'] as String, name: json['name'] as String);
}
