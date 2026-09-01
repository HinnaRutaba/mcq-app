import 'package:get/get.dart';

import '../../core/services/visit_reminder_service.dart';
import '../../data/api/repositories/enforcement_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enforcement/enforcement_case.dart';
import 'async_state.dart';
import 'offline_queue_controller.dart';

enum CaseFilter {
  /// Visit overdue — the field officer's queue.
  overdue,
  open,
  all;

  String get labelKey => switch (this) {
        CaseFilter.overdue => 'cases.filterOverdue',
        CaseFilter.open => 'cases.filterOpen',
        CaseFilter.all => 'cases.filterAll',
      };

  /// The `status` query parameter, or none. Exact match on the enum value —
  /// a value the enum does not have is a 422 on a filter the app offered.
  String? get statusValue => this == CaseFilter.open ? 'open' : null;
}

/// The list of enforcement cases in the officer's areas.
class CasesController extends GetxController with AsyncState {
  CasesController({
    required EnforcementRepository enforcement,
    required OfflineQueueController queue,
    required VisitReminderService reminders,
    this.assignedToMe = false,
  })  : _enforcement = enforcement,
        _queue = queue,
        _reminders = reminders;

  factory CasesController.resolve({bool assignedToMe = false}) =>
      CasesController(
        assignedToMe: assignedToMe,
        enforcement: Get.find(),
        queue: Get.find(),
        reminders: Get.find(),
      );

  /// Cases the **taxation branch** assigned to this officer. MCQ asked for
  /// these to arrive in the app; the `assigned_to_me` beat tile is where
  /// they land, and this is the list behind it.
  final bool assignedToMe;

  final EnforcementRepository _enforcement;
  final OfflineQueueController _queue;
  final VisitReminderService _reminders;

  final RxList<EnforcementCase> cases = <EnforcementCase>[].obs;
  final Rx<CaseFilter> filter = CaseFilter.overdue.obs;
  final RxBool hasMore = false.obs;
  final RxInt page = 1.obs;
  final RxString search = ''.obs;

  Worker? _landedWorker;

  @override
  void onInit() {
    super.onInit();
    reload();
    // A queued write that lands changes the case it belongs to, so the list
    // must not keep showing what the officer saw before it synced.
    _landedWorker = ever<int>(_queue.landed, (_) => reload(refreshing: true));
  }

  @override
  void onClose() {
    _landedWorker?.dispose();
    super.onClose();
  }

  void setFilter(CaseFilter next) {
    filter.value = next;
    reload();
  }

  void setSearch(String value) {
    search.value = value;
    reload();
  }

  Future<void> reload({bool refreshing = false}) => load(
        () async {
          page.value = 1;
          final fetched = await _enforcement.cases(
            status: filter.value.statusValue,
            search: search.value.trim().isEmpty ? null : search.value.trim(),
            // visit_overdue is the field officer's queue: ask the server to
            // sort by it so the app and the web application agree.
            sort: '-visit_overdue',
            assignedToMe: assignedToMe,
          );
          cases.assignAll(_applyLocalFilter(fetched.value.items));
          hasMore.value = fetched.value.hasMore;
          markFetched(fetched.fetchedAt, fromCache: fetched.fromCache);
          _scheduleReminders();
        },
        refreshing: refreshing,
      );

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;
    final next = page.value + 1;
    await load(() async {
      final fetched = await _enforcement.cases(
        status: filter.value.statusValue,
        search: search.value.trim().isEmpty ? null : search.value.trim(),
        sort: '-visit_overdue',
        assignedToMe: assignedToMe,
        page: next,
      );
      page.value = next;
      cases.addAll(_applyLocalFilter(fetched.value.items));
      hasMore.value = fetched.value.hasMore;
    }, refreshing: true);
  }

  /// "Visit overdue" is a server-computed flag, not a status, so it is
  /// filtered here rather than sent as a `status` parameter the enum does
  /// not have.
  List<EnforcementCase> _applyLocalFilter(List<EnforcementCase> items) {
    if (filter.value != CaseFilter.overdue) return items;
    return items.where((item) => item.visitOverdue).toList();
  }

  /// There is no server push, so the handset schedules its own reminders
  /// from `next_visit_date`.
  Future<void> _scheduleReminders() async {
    try {
      await _reminders.scheduleFor(
        cases,
        title: (item) => t('cases.recordAction'),
        body: (item) =>
            '${item.property.label} — ${item.allottee.name}',
      );
    } on Object {
      // A handset that refuses to schedule a reminder must not take the
      // case list down with it.
    }
  }
}
