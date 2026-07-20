/// A row of the fixed `skills` taxonomy.
class Skill {
  const Skill({required this.id, required this.name, this.category = ''});
  final String id;
  final String name;
  final String category;

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] as String?) ?? '',
      );
}
