import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password, required String fullName});
  Future<void> signOut();
  Stream<AuthState> authStateChanges();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password, required String fullName}) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'student', 'full_name': fullName},
    );
    // Ops contract: email confirmation is disabled server-side so signup
    // returns a live session. Surface a plain error instead of hanging if
    // that dashboard step was missed (see docs/DEMO.md).
    if (res.session == null) {
      throw const AuthException(
          'Signup needs email confirmation disabled on the server (Supabase dashboard). See docs/DEMO.md.');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;
}
