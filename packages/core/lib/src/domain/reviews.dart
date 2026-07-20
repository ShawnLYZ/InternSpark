import '../domain/application_status.dart';
import '../models/application.dart';
import '../models/review.dart';

const Set<ApplicationStatus> _reviewEligible = {
  ApplicationStatus.matched,
  ApplicationStatus.interview,
  ApplicationStatus.offer,
  ApplicationStatus.accepted,
  ApplicationStatus.declined,
};

/// A student may review a company once they have a matched-or-beyond application
/// with it. (The `post_review` RPC enforces the same gate server-side.)
bool canReview({required String companyId, required List<Application> applications}) =>
    applications.any((a) => a.companyId == companyId && _reviewEligible.contains(a.status));

/// The headline Mentorship Score: mean of the mentorship dimension; 0 when empty.
double mentorshipScore(List<Review> reviews) => reviews.isEmpty
    ? 0
    : reviews.map((r) => r.mentorship).reduce((a, b) => a + b) / reviews.length;

/// Demo profanity wordlist — deterministic, local, whole-word (no AI call).
const Set<String> _profanity = {'damn', 'hell', 'crap', 'shit', 'ass', 'bastard'};

bool containsProfanity(String text) {
  final tokens = text.toLowerCase().split(RegExp(r'[^a-z]+')).where((t) => t.isNotEmpty);
  return tokens.any(_profanity.contains);
}
