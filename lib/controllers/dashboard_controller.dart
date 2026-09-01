import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/defaulters_repository.dart';
import '../models/auth_user.dart';
import '../models/field_activity.dart';
import '../models/field_beat.dart';
import '../models/round_group.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  DashboardController({
    DashboardRepository? dashboardRepository,
    DefaultersRepository? defaultersRepository,
    AuthController? authController,
  }) : _dashboard = dashboardRepository ?? Get.find<DashboardRepository>(),
       _defaulters = defaultersRepository ?? Get.find<DefaultersRepository>(),
       _auth = authController ?? Get.find<AuthController>();

  final DashboardRepository _dashboard;
  final DefaultersRepository _defaulters;
  final AuthController _auth;

  static const List<int> activityWindows = <int>[7, 30, 90];

  final Rxn<FieldBeat> beat = Rxn<FieldBeat>();
  final Rxn<FieldActivity> activity = Rxn<FieldActivity>();

  final RxList<RoundGroup> round = RxList<RoundGroup>();

  final RxInt activityDays = RxInt(30);

  final RxBool isLoading = RxBool(false);
  final RxBool isReloadingActivity = RxBool(false);

  final RxnString errorMessage = RxnString();

  AuthUser? get officer => _auth.officer.value;

  bool get hasData =>
      beat.value != null || activity.value != null || round.isNotEmpty;

  List<RoundGroup> get bazaarsByArrears => List<RoundGroup>.of(round)
    ..sort((RoundGroup a, RoundGroup b) => _amount(b).compareTo(_amount(a)));

  int get brokenPromises => _sum((RoundGroup g) => g.brokenPromises);

  int get neverPaid => _sum((RoundGroup g) => g.neverPaid);

  int get sealedInRound => _sum((RoundGroup g) => g.sealed);

  bool get hasDefaulterBreakdown => round.isNotEmpty;

  int _sum(int Function(RoundGroup group) field) =>
      round.fold<int>(0, (int total, RoundGroup g) => total + field(g));

  static double _amount(RoundGroup group) =>
      double.tryParse(group.outstanding.trim()) ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Fetches both halves. Safe to call again — this is the pull-to-refresh.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    await Future.wait(<Future<void>>[
      _loadBeat(),
      _loadActivity(),
      _loadRound(),
    ]);
    isLoading.value = false;
  }

  /// Puts [activity] over a different window. The beat is untouched.
  Future<void> setActivityWindow(int days) async {
    if (days == activityDays.value) return;
    activityDays.value = days;
    isReloadingActivity.value = true;
    errorMessage.value = null;
    await _loadActivity();
    isReloadingActivity.value = false;
  }

  Future<void> _loadRound() async {
    try {
      round.value = await _defaulters.round();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadBeat() async {
    try {
      beat.value = await _dashboard.beat();
    } on ApiException catch (error) {
      _report(error);
    }
  }

  Future<void> _loadActivity() async {
    try {
      activity.value = await _dashboard.activity(days: activityDays.value);
    } on ApiException catch (error) {
      _report(error);
    }
  }

  void _report(ApiException error) {
    errorMessage.value ??= error.message;
  }
}
