import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchMyProfile();
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<Profile?> fetchMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }
}
