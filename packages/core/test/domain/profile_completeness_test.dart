import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

ProfileFields _full() => ProfileFields(
      growthStatement: 'I want to grow into shipping real data products.',
      skillCount: 3,
      major: 'Computer Science',
      studyYear: 3,
      location: 'Remote',
      remotePref: 'remote',
      availabilityStart: DateTime(2026, 7, 1),
      durationWeeks: 12,
      salaryExpectation: 2500,
      roleInterests: ['Software Engineer'],
      industryInterests: ['Technology'],
    );

void main() {
  test('a fully-filled profile is 100% and unlocks the deck', () {
    final r = profileCompleteness(_full());
    expect(r.percent, 1.0);
    expect(r.missingCritical, isEmpty);
    expect(r.deckUnlocked, isTrue);
  });

  test('a blank growth statement is missing-critical and locks the deck', () {
    final r = profileCompleteness(ProfileFields(
      growthStatement: '   ',
      skillCount: 3,
      major: 'CS',
      studyYear: 3,
      location: 'Remote',
      remotePref: 'remote',
      availabilityStart: DateTime(2026, 7, 1),
      durationWeeks: 12,
      salaryExpectation: 2500,
    ));
    expect(r.deckUnlocked, isFalse);
    expect(r.missingCritical, contains('growth statement'));
  });

  test('zero skills locks the deck', () {
    final r = profileCompleteness(_full().copyWith(skillCount: 0));
    expect(r.deckUnlocked, isFalse);
    expect(r.missingCritical, contains('at least one skill'));
  });

  test('missing availability locks the deck', () {
    final r = profileCompleteness(_full().copyWith(availabilityStart: null));
    expect(r.deckUnlocked, isFalse);
    expect(r.missingCritical, contains('availability'));
  });

  test('salary is optional — absent salary still unlocks the deck', () {
    final r = profileCompleteness(_full().copyWith(salaryExpectation: null));
    expect(r.deckUnlocked, isTrue);
    expect(r.percent, lessThan(1.0)); // optional fields lower the percent but never gate
  });

  test('interests are optional — empty interests still unlock the deck, percent < 1.0', () {
    final r = profileCompleteness(_full().copyWith(roleInterests: const [], industryInterests: const []));
    expect(r.deckUnlocked, isTrue);
    expect(r.percent, lessThan(1.0));
  });
}
