/// A row of `interview_schedules`.
class InterviewSchedule {
  const InterviewSchedule({this.contactEmail, this.meetingLink, this.meetingDate});
  final String? contactEmail;
  final String? meetingLink;
  final DateTime? meetingDate;

  factory InterviewSchedule.fromJson(Map<String, dynamic> j) => InterviewSchedule(
        contactEmail: j['contact_email'] as String?,
        meetingLink: j['meeting_link'] as String?,
        meetingDate: j['meeting_date'] == null ? null : DateTime.parse(j['meeting_date'] as String),
      );
}
