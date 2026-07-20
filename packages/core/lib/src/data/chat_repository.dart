import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';

abstract interface class ChatRepository {
  Future<List<ChatThread>> myThreads();
  /// Live messages for a thread, ordered oldest→newest (the shared Realtime pattern).
  Stream<List<ChatMessage>> messages(String threadId);
  Future<void> sendMessage({required String threadId, required String body});
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ChatThread>> myThreads() async {
    final rows = await _client.rpc('my_chat_threads') as List;
    return rows.map((r) => ChatThread.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Stream<List<ChatMessage>> messages(String threadId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at')
        .map((rows) => rows.map((r) => ChatMessage.fromJson(r)).toList());
  }

  @override
  Future<void> sendMessage({required String threadId, required String body}) async =>
      _client.rpc('send_message', params: {'p_thread': threadId, 'p_body': body});
}
