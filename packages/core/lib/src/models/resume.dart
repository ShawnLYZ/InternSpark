/// A structured, grounded resume. `name` is redactable; everything else is the
/// student's reordered/emphasized **entered** experience — never invented.
class ResumeJson {
  const ResumeJson({
    required this.name,
    this.headline = '',
    this.summary = '',
    this.sections = const [],
  });

  final String name;
  final String headline;
  final String summary;
  final List<ResumeSection> sections;

  ResumeJson copyWith({String? name, String? headline, String? summary, List<ResumeSection>? sections}) =>
      ResumeJson(
        name: name ?? this.name,
        headline: headline ?? this.headline,
        summary: summary ?? this.summary,
        sections: sections ?? this.sections,
      );

  factory ResumeJson.fromJson(Map<String, dynamic> j) => ResumeJson(
        name: (j['name'] as String?) ?? 'Candidate',
        headline: (j['headline'] as String?) ?? '',
        summary: (j['summary'] as String?) ?? '',
        sections: ((j['sections'] as List?) ?? const [])
            .map((s) => ResumeSection.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'headline': headline,
        'summary': summary,
        'sections': [for (final s in sections) s.toJson()],
      };
}

class ResumeSection {
  const ResumeSection({required this.title, this.bullets = const []});
  final String title;
  final List<String> bullets;

  factory ResumeSection.fromJson(Map<String, dynamic> j) => ResumeSection(
        title: (j['title'] as String?) ?? '',
        bullets: ((j['bullets'] as List?) ?? const []).map((b) => '$b').toList(),
      );

  Map<String, dynamic> toJson() => {'title': title, 'bullets': bullets};
}
