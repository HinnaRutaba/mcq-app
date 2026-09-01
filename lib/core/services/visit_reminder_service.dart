import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/enforcement/enforcement_case.dart';

/// Local reminders for the cases whose next visit is due.
///
/// There is no device-registration endpoint and no push integration on the
/// server, so `next_visit_date` on a case is scheduled on the handset
/// instead. Whether that is sufficient for the first release is an open
/// question for MCQ — see QUESTIONS.md.
class VisitReminderService {
  VisitReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _idBase = 71000;
  static const AndroidNotificationDetails _android =
      AndroidNotificationDetails(
    'mcq.visits',
    'Visit reminders',
    channelDescription: 'Reminds you when a case visit is due',
    importance: Importance.defaultImportance,
  );

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    // MCQ operates in Quetta. Fixing the zone keeps a reminder on the day
    // the case says, whatever the handset clock is set to.
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  /// Re-schedules reminders for [cases], replacing whatever was scheduled
  /// before — the server is the authority on when the next visit is.
  Future<void> scheduleFor(
    List<EnforcementCase> cases, {
    required String Function(EnforcementCase item) title,
    required String Function(EnforcementCase item) body,
    int hourOfDay = 9,
  }) async {
    await init();
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    for (final item in cases) {
      final due = item.nextVisitDate;
      if (due == null || !item.isLive) continue;

      var when = tz.TZDateTime(tz.local, due.year, due.month, due.day, hourOfDay);
      // A visit already overdue is worth saying today, not never.
      if (when.isBefore(now)) {
        when = now.add(const Duration(minutes: 5));
      }

      await _plugin.zonedSchedule(
        _idBase + item.id,
        title(item),
        body(item),
        when,
        const NotificationDetails(
          android: _android,
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact is deliberate: an exact alarm needs a special permission
        // on Android 13+, and a visit reminder does not need to be to the
        // minute.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${item.id}',
      );
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
