import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// End-to-end golden path on the REAL stack and seed data:
/// student swipes right → employer matches + offers → student accepts → placed.
///
/// Run:
///   flutter test integration_test/golden_path_test.dart -d chrome \
///     --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…
///
/// NOTE: mutates seed state — the hero swipes the Nimbus job and it is driven to `placed`.
/// Afterward run `node supabase/reset_golden_path.mjs` (a service-role reset that deletes the
/// consumed Nimbus application + its internship). `seed.mjs` only upserts and cannot un-swipe it,
/// so a second run would otherwise find no Nimbus card in the deck.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;

  setUpAll(() async {
    // FIX 1: use publishableKey (not the deprecated anonKey parameter name),
    // mirroring app_mobile/lib/main.dart exactly. The VALUE is still
    // SupabaseConfig.anonKey — only the named parameter changed.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    client = Supabase.instance.client;
  });

  Future<void> signIn(String email) async {
    await client.auth.signOut();
    await client.auth.signInWithPassword(
      email: email,
      password: 'Passw0rd!demo',
    );
  }

  testWidgets('onboard→swipe→match→offer→accept→placed', (tester) async {
    // 1) Student: find a Nimbus deck candidate and swipe right.
    await signIn('student@internspark.demo');
    final deck = await client.rpc('deck_candidates') as List;
    expect(
      deck,
      isNotEmpty,
      reason: 'deck must be non-empty on seed (run seed embeddings)',
    );

    // FIX 2: pick the Nimbus job deterministically.
    // employer@internspark.demo owns the Nimbus company
    // (company_id 22222222-2222-2222-2222-222222222221).
    // employer_swipe asserts company ownership, so selecting any non-Nimbus
    // job would throw "Not your application". deck_candidates() returns
    // company_id in each row, so we filter here.
    final nimbus = deck.cast<Map>().firstWhere(
      (c) => c['company_id'] == '22222222-2222-2222-2222-222222222221',
      orElse: () => throw StateError(
        'no Nimbus job in the deck — reseed with SUPABASE_ANON_KEY set',
      ),
    );
    final jobId = nimbus['job_id'] as String;

    final app = await client.rpc(
      'swipe_job',
      params: {'p_job': jobId, 'p_direction': 'right'},
    );
    final appId = (app as Map)['id'] as String;
    expect(app['status'], 'applied');

    // 2) Employer of that job: match → offer.
    await signIn('employer@internspark.demo');
    final matched = await client.rpc(
      'employer_swipe',
      params: {'p_application': appId, 'p_direction': 'right'},
    );
    expect((matched as Map)['status'], 'matched');
    final offered = await client.rpc(
      'make_offer',
      params: {'p_application': appId},
    );
    expect((offered as Map)['status'], 'offer');

    // 3) Student: accept → placed (internship created).
    await signIn('student@internspark.demo');
    final accepted = await client.rpc(
      'accept_offer',
      params: {'p_application': appId},
    );
    expect((accepted as Map)['status'], 'accepted');
    final intern = await client
        .from('internships')
        .select('id')
        .eq('application_id', appId)
        .maybeSingle();
    expect(intern, isNotNull, reason: 'acceptance must create the internship (placed)');

    await client.auth.signOut();
  });
}
