import 'dart:async';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../data/auth_repository.dart';
import '../models/chat.dart';
import '../data/chat_repository.dart';
import '../models/company.dart';
import '../models/profile.dart';
import '../models/student_profile.dart';
import '../models/university.dart';
import '../models/verification.dart';
import '../data/profile_repository.dart';
import '../data/student_repository.dart';
import '../data/employer_repository.dart';
import '../data/university_repository.dart';
import '../data/verification_repository.dart';
import '../models/application.dart';
import '../models/applicant_row.dart';
import '../models/deck_candidate.dart';
import '../models/job.dart';
import '../data/deck_repository.dart';
import '../data/application_repository.dart';
import '../data/job_repository.dart';
import '../data/applicants_repository.dart';
import '../models/resume.dart';
import '../domain/resume_builder.dart';
import '../data/resume_repository.dart';
import '../models/company_ghost_stats.dart';
import '../data/leaderboard_repository.dart';
import '../models/skill.dart';
import '../data/roi_repository.dart';
import '../models/review.dart';
import '../data/review_repository.dart';
import '../domain/comment_gate.dart';
import '../models/report.dart';
import '../data/report_repository.dart';
import '../models/credit.dart';
import '../data/credit_repository.dart';
import '../models/sandbox.dart';
import '../data/sandbox_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);
  final Profile? profile;
  @override
  Future<Profile?> fetchMyProfile() async => profile;
}

class FakeStudentRepository implements StudentRepository {
  FakeStudentRepository({this.studentProfile, this.jobCount = 0, this.verifiedSkills = const []});
  final StudentProfile? studentProfile;
  final int jobCount;
  final List<VerifiedSkill> verifiedSkills;
  @override
  Future<StudentProfile?> fetchMyStudentProfile() async => studentProfile;
  @override
  Future<int> countAvailableJobs() async => jobCount;
  @override
  Future<List<VerifiedSkill>> fetchMyVerifiedSkills() async => verifiedSkills;
}

class FakeEmployerRepository implements EmployerRepository {
  FakeEmployerRepository({this.company, this.jobCount = 0});
  final Company? company;
  final int jobCount;
  @override
  Future<Company?> fetchMyCompany() async => company;
  @override
  Future<int> countMyJobs() async => jobCount;
}

class FakeUniversityRepository implements UniversityRepository {
  FakeUniversityRepository({this.university, this.studentCount = 0, this.universities = const []});
  final University? university;
  final int studentCount;
  final List<University> universities;
  @override
  Future<University?> fetchMyUniversity() async => university;
  @override
  Future<int> countMyStudents() async => studentCount;
  @override
  Future<List<University>> listUniversities() async => universities;
}

class FakeDeckRepository implements DeckRepository {
  FakeDeckRepository({List<DeckCandidate>? deck}) : _deck = [...?deck];
  final List<DeckCandidate> _deck;
  final List<(String, String)> swipes = [];
  String? lastUndone;

  @override
  Future<List<DeckCandidate>> fetchDeck() async => _deck;
  @override
  Future<String?> swipe({required String jobId, required String direction}) async {
    swipes.add((jobId, direction));
    _deck.removeWhere((c) => c.jobId == jobId);
    return direction == 'right' ? 'app-$jobId' : null;
  }
  @override
  Future<String?> undoLast() async {
    if (swipes.isEmpty) return null;
    final (jobId, _) = swipes.removeLast();
    return lastUndone = jobId;
  }
}

class FakeApplicationRepository implements ApplicationRepository {
  FakeApplicationRepository({List<Application>? apps}) : _apps = [...?apps];
  final List<Application> _apps;
  final List<String> accepted = [];
  final List<String> declined = [];
  @override
  Future<List<Application>> myApplications() async => _apps;
  @override
  Future<void> acceptOffer(String id) async => accepted.add(id);
  @override
  Future<void> declineOffer(String id) async => declined.add(id);
}

class FakeJobRepository implements JobRepository {
  FakeJobRepository({List<Job>? jobs}) : _jobs = [...?jobs];
  final List<Job> _jobs;
  Map<String, dynamic>? lastUpsert;
  String? videoSetFor;
  @override
  Future<List<Job>> myJobs() async => _jobs;
  @override
  Future<Job?> fetchJob(String id) async => _jobs.where((j) => j.id == id).firstOrNull;
  @override
  Future<String> upsertJob(Map<String, dynamic> values) async {
    lastUpsert = values;
    return 'job-new';
  }
  @override
  Future<String> draftGrowthText(String title, String description) async => 'Draft growth blurb for $title.';
  @override
  Future<void> setJobVideo({required String jobId, required Uint8List bytes, required String fileName}) async {
    videoSetFor = jobId;
  }
}

class FakeApplicantsRepository implements ApplicantsRepository {
  FakeApplicantsRepository({List<ApplicantRow>? rows}) : _rows = [...?rows];
  final List<ApplicantRow> _rows;
  final List<(String, String)> swipes = [];
  final List<String> offered = [];
  @override
  Future<List<ApplicantRow>> applicants(String jobId) async => _rows;
  @override
  Future<void> employerSwipe({required String applicationId, required String direction}) async =>
      swipes.add((applicationId, direction));
  @override
  Future<void> requestInterview({
    required String applicationId, required String email, required String link, required DateTime date,
  }) async {}
  @override
  Future<void> makeOffer(String id) async => offered.add(id);
  @override
  Future<void> pass(String id) async {}
}

class FakeLeaderboardRepository implements LeaderboardRepository {
  FakeLeaderboardRepository({List<CompanyGhostStats>? stats, this.mine}) : _stats = [...?stats];
  final List<CompanyGhostStats> _stats;
  final CompanyGhostStats? mine;
  @override
  Future<List<CompanyGhostStats>> leaderboard() async => _stats;
  @override
  Future<CompanyGhostStats?> myCompanyStat() async => mine;
}

class FakeRoiRepository implements RoiRepository {
  FakeRoiRepository({RoiSummary? summary, List<Skill>? all, List<Skill>? curriculum})
      : _summary = summary, _all = [...?all], _curriculum = [...?curriculum];
  final RoiSummary? _summary;
  final List<Skill> _all;
  final List<Skill> _curriculum;
  final List<String> added = [];
  final List<String> removed = [];

  @override
  Future<RoiSummary> fetchRoi() async =>
      _summary ?? const RoiSummary(placementRate: 0, demand: [], gap: []);
  @override
  Future<List<Skill>> allSkills() async => _all;
  @override
  Future<List<Skill>> curriculumSkills() async => _curriculum;
  @override
  Future<void> addCurriculumSkill(String skillId) async => added.add(skillId);
  @override
  Future<void> removeCurriculumSkill(String skillId) async => removed.add(skillId);
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({List<Review>? reviews, List<CompanyMentorship>? scores, List<ReportRef>? reportRefs})
      : _reviews = [...?reviews], _scores = [...?scores], _reportRefs = [...?reportRefs];
  final List<Review> _reviews;
  final List<CompanyMentorship> _scores;
  final List<ReportRef> _reportRefs;
  Map<String, dynamic>? posted;
  String? deleted;

  @override
  Future<List<Review>> companyReviews(String companyId) async => _reviews;
  @override
  Future<Review?> myReview(String companyId) async => null;
  @override
  Future<void> postReview({
    required String companyId, required int mentorship, required int workload,
    required int psychSafety, String? comment,
  }) async {
    posted = {'companyId': companyId, 'mentorship': mentorship, 'comment': comment};
  }
  @override
  Future<void> deleteReview(String companyId) async => deleted = companyId;
  @override
  Future<List<CompanyMentorship>> mentorshipScores() async => _scores;
  @override
  Future<List<ReportRef>> myReportRefs() async => _reportRefs;
}

class FakeResumeRepository implements ResumeRepository {
  FakeResumeRepository({ResumeJson? generated}) : _generated = generated;
  final ResumeJson? _generated;
  ResumeJson? attached;
  String? attachedTo;

  @override
  Future<ResumeJson> generateResume(String jobId) async =>
      _generated ?? const ResumeJson(name: 'Sam Rivera', headline: 'Aspiring analyst');
  @override
  Future<void> attachResume({required String applicationId, required ResumeJson resume}) async {
    attachedTo = applicationId;
    attached = resume;
  }
  @override
  Future<ResumeJson?> applicantResume(String applicationId) async =>
      _generated == null ? null : redactName(_generated);
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({List<ChatThread>? threads}) : _threads = [...?threads];
  final List<ChatThread> _threads;
  final _controller = StreamController<List<ChatMessage>>.broadcast();
  final List<ChatMessage> _messages = [];
  final List<String> sent = [];

  /// Test helper: push a new message into the live stream.
  void emit(ChatMessage m) {
    _messages.add(m);
    _controller.add(List.unmodifiable(_messages));
  }

  @override
  Future<List<ChatThread>> myThreads() async => _threads;
  @override
  Stream<List<ChatMessage>> messages(String threadId) {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_messages)));
    return _controller.stream;
  }
  @override
  Future<void> sendMessage({required String threadId, required String body}) async => sent.add(body);
}

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({List<ReportableStudent>? students, List<Report>? reports})
      : _students = [...?students], _reports = [...?reports];
  final List<ReportableStudent> _students;
  final List<Report> _reports;
  Map<String, dynamic>? filed;

  @override
  Future<List<ReportableStudent>> reportableStudents() async => _students;
  @override
  Future<String> draftNarrative({
    required String studentName, required int reliability, required int skill, required int communication,
  }) async => 'Drafted narrative for $studentName.';
  @override
  Future<void> fileReport({
    required String studentId, required String studentName, required String companyName,
    required int reliability, required int skill, required int communication, String? narrative,
  }) async {
    filed = {'studentId': studentId, 'reliability': reliability, 'narrative': narrative};
  }
  @override
  Future<List<Report>> universityReports() async => _reports;
}

class FakeCreditRepository implements CreditRepository {
  FakeCreditRepository({List<CreditRequest>? requests}) : _requests = [...?requests];
  final List<CreditRequest> _requests;
  CreditMapping? attached;
  Map<String, String>? approved;

  @override
  Future<List<CreditRequest>> queue() async => _requests;
  @override
  Future<CreditMapping> generateMapping(String jobId) async => const CreditMapping(
        summary: 'Satisfies 1 core requirement.',
        satisfied: [CreditSatisfied(skill: 'SQL', evidence: 'Built dashboards.')],
      );
  @override
  Future<void> attachMapping({
    required String requestId, required String jobTitle, required String studentName, required CreditMapping mapping,
  }) async => attached = mapping;
  @override
  Future<void> approve({required String requestId, required String signerName}) async =>
      approved = {'requestId': requestId, 'signer': signerName};
}

class FakeSandboxRepository implements SandboxRepository {
  FakeSandboxRepository({List<SandboxSubmission>? mine, List<SandboxSubmission>? jobSubs, this.task})
      : _mine = [...?mine], _jobSubs = [...?jobSubs];
  final List<SandboxSubmission> _mine;
  final List<SandboxSubmission> _jobSubs;
  final SandboxTask? task;
  String? draftSaved;
  String? submitted;
  Map<String, String?>? verdict;
  Map<String, dynamic>? configured;

  @override
  Future<List<SandboxSubmission>> mySandboxes() async => _mine;
  @override
  Future<void> saveDraft({required String submissionId, required String text, String? fileRef}) async => draftSaved = text;
  @override
  Future<void> submit(String submissionId) async => submitted = submissionId;
  @override
  Future<String> uploadFile({required String submissionId, required Uint8List bytes, required String fileName}) async => 'path/$fileName';
  @override
  Future<SandboxTask?> jobSandboxTask(String jobId) async => task;
  @override
  Future<String> generatePrompt(String jobId) async => 'Drafted try-out task for $jobId.';
  @override
  Future<void> configureSandbox({required String jobId, required String source, required String prompt, required bool approved}) async =>
      configured = {'jobId': jobId, 'source': source, 'approved': approved};
  @override
  Future<List<SandboxSubmission>> jobSubmissions(String jobId) async => _jobSubs;
  @override
  Future<String> assess(String submissionText) async => 'AI assessment: solid effort, clear writing.';
  @override
  Future<void> recordVerdict({required String submissionId, required String verdict, String? notes, String? aiAssessment}) async =>
      this.verdict = {'submissionId': submissionId, 'verdict': verdict};
}

class FakeAuthRepository implements AuthRepository {
  final List<(String, String)> signIns = [];
  final List<(String, String, String)> signUps = [];
  int signOutCount = 0;
  Object? signInError;
  Object? signUpError;
  Object? signOutError;
  final controller = StreamController<AuthState>.broadcast();

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
    signIns.add((email, password));
  }

  @override
  Future<void> signUp({required String email, required String password, required String fullName}) async {
    if (signUpError != null) throw signUpError!;
    signUps.add((email, password, fullName));
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
    signOutCount++;
  }

  @override
  Stream<AuthState> authStateChanges() => controller.stream;
}

class FakeVerificationRepository implements VerificationRepository {
  /// Queue-driven: each workflow call records itself into [calls] and returns
  /// the next scripted session (or the last one when the queue runs dry).
  FakeVerificationRepository({
    this.hasActive = false,
    List<VerificationSession>? sessions,
    this.certification,
  }) : _queue = [...?sessions];
  bool hasActive;
  final List<VerificationSession> _queue;
  final Certification? certification;
  VerificationSession? current;
  final List<Map<String, Object?>> calls = [];

  VerificationSession _next(String call, Map<String, Object?> args) {
    calls.add({'call': call, ...args});
    if (_queue.isNotEmpty) current = _queue.removeAt(0);
    return current!;
  }

  @override
  Future<bool> hasActiveSession() async => hasActive;
  @override
  Future<VerificationSession> startOrResume() async => _next('start', {});
  @override
  Future<VerificationSession> submitInput({
    required String sessionId, required String universityId,
    required String course, required int year, required int semester,
  }) async =>
      _next('submit_input', {'universityId': universityId, 'course': course, 'year': year, 'semester': semester});
  @override
  Future<VerificationSession> confirmProgram({
    required String sessionId, String? programId, required bool accept,
  }) async =>
      _next('confirm_program', {'programId': programId, 'accept': accept});
  @override
  Future<({VerificationSession session, Certification certification})> uploadCertificate({
    required String sessionId, required Uint8List bytes, required String filename,
  }) async {
    final s = _next('upload_certificate', {'filename': filename});
    return (
      session: s,
      certification: certification ?? const Certification(id: 'cert-1', status: CertificationStatus.pending),
    );
  }
  @override
  Future<VerificationSession> certificatesDone(String sessionId) async => _next('certificates_done', {});
  @override
  Future<VerificationSession> savePreferences({
    required String sessionId, required String growthStatement,
    DateTime? availabilityStart, int? durationWeeks, String? remotePref, int? salaryExpectation,
    List<String> roleInterests = const [], List<String> industryInterests = const [],
  }) async =>
      _next('save_preferences', {'growthStatement': growthStatement});
  @override
  Future<VerificationSession> complete(String sessionId) async => _next('complete', {});
}
