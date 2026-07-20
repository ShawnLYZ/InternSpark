import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai/ai_client.dart';
import '../ai/supabase_ai_client.dart';
import '../data/auth_repository.dart';
import '../data/profile_repository.dart';
import '../data/student_repository.dart';
import '../data/employer_repository.dart';
import '../data/university_repository.dart';
import '../data/verification_repository.dart';
import '../data/deck_repository.dart';
import '../data/application_repository.dart';
import '../data/job_repository.dart';
import '../data/applicants_repository.dart';
import '../data/resume_repository.dart';
import '../data/leaderboard_repository.dart';
import '../data/roi_repository.dart';
import '../data/review_repository.dart';
import '../data/report_repository.dart';
import '../data/chat_repository.dart';
import '../data/credit_repository.dart';
import '../data/sandbox_repository.dart';
import '../models/profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)));
final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => SupabaseProfileRepository(ref.watch(supabaseClientProvider)));
final studentRepositoryProvider = Provider<StudentRepository>(
    (ref) => SupabaseStudentRepository(ref.watch(supabaseClientProvider)));
final employerRepositoryProvider = Provider<EmployerRepository>(
    (ref) => SupabaseEmployerRepository(ref.watch(supabaseClientProvider)));
final universityRepositoryProvider = Provider<UniversityRepository>(
    (ref) => SupabaseUniversityRepository(ref.watch(supabaseClientProvider)));
final aiClientProvider = Provider<AiClient>(
    (ref) => SupabaseAiClient(ref.watch(supabaseClientProvider)));

/// Emits on every auth change so dependents refresh.
final authStateProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// The signed-in user's profile (null when signed out). Tests override this directly.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateProvider); // recompute on sign-in / sign-out
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
});

final deckRepositoryProvider = Provider<DeckRepository>(
    (ref) => SupabaseDeckRepository(ref.watch(supabaseClientProvider)));
final applicationRepositoryProvider = Provider<ApplicationRepository>(
    (ref) => SupabaseApplicationRepository(ref.watch(supabaseClientProvider)));
final jobRepositoryProvider = Provider<JobRepository>(
    (ref) => SupabaseJobRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
final applicantsRepositoryProvider = Provider<ApplicantsRepository>(
    (ref) => SupabaseApplicantsRepository(ref.watch(supabaseClientProvider)));
final resumeRepositoryProvider = Provider<ResumeRepository>(
    (ref) => SupabaseResumeRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
    (ref) => SupabaseLeaderboardRepository(ref.watch(supabaseClientProvider)));
final roiRepositoryProvider = Provider<RoiRepository>(
    (ref) => SupabaseRoiRepository(ref.watch(supabaseClientProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => SupabaseReviewRepository(ref.watch(supabaseClientProvider)));
final reportRepositoryProvider = Provider<ReportRepository>(
    (ref) => SupabaseReportRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
final chatRepositoryProvider = Provider<ChatRepository>(
    (ref) => SupabaseChatRepository(ref.watch(supabaseClientProvider)));
final creditRepositoryProvider = Provider<CreditRepository>(
    (ref) => SupabaseCreditRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
final sandboxRepositoryProvider = Provider<SandboxRepository>(
    (ref) => SupabaseSandboxRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
final verificationRepositoryProvider = Provider<VerificationRepository>(
    (ref) => SupabaseVerificationRepository(ref.watch(supabaseClientProvider), ref.watch(aiClientProvider)));
