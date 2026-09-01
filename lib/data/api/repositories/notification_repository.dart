import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/utils/json_reader.dart';

/// The `/notification` module.
///
/// There is no device-registration endpoint and no push integration, so
/// the app polls this and schedules its own local reminders from
/// `next_visit_date` (see `VisitReminderService`). Whether local
/// notifications are enough for the first release is an open question for
/// MCQ — see QUESTIONS.md.
class NotificationRepository {
  NotificationRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<AppNotification>> unread({int perPage = 20}) async {
    final envelope = await _client.get(
      ApiConstants.notifications,
      query: {ApiConstants.qPerPage: perPage},
    );
    return envelope.list
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }
}

/// A notification row. [title] and [body] arrive already translated.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json.strOr('id'),
        title: json.strOr('title'),
        body: json.str('body') ?? json.strOr('message'),
        readAt: json.date('read_at'),
        createdAt: json.date('created_at'),
      );

  bool get isUnread => readAt == null;
}
