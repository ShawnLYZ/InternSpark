/// One row of `my_chat_threads()`.
class ChatThread {
  const ChatThread({
    required this.threadId,
    required this.studentName,
    required this.companyName,
    required this.universityName,
  });
  final String threadId;
  final String studentName;
  final String companyName;
  final String universityName;

  factory ChatThread.fromJson(Map<String, dynamic> j) => ChatThread(
        threadId: j['thread_id'] as String,
        studentName: (j['student_name'] as String?) ?? 'Student',
        companyName: (j['company_name'] as String?) ?? '',
        universityName: (j['university_name'] as String?) ?? '',
      );
}

/// One row of `chat_messages` (streamed live).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderProfileId,
    required this.body,
    this.createdAt,
  });
  final String id;
  final String threadId;
  final String senderProfileId;
  final String body;
  final DateTime? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        threadId: j['thread_id'] as String,
        senderProfileId: j['sender_profile_id'] as String,
        body: (j['body'] as String?) ?? '',
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}
