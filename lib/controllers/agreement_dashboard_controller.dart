import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/agreement_repository.dart';
import '../models/agreement_dashboard.dart';
import '../models/agreement_requests.dart';
import '../models/auth_user.dart';
import '../models/mobile_access.dart';
import 'auth_controller.dart';

/// The days the dated blocks are counted over. `my_actions` and `register`
/// follow it; `waiting` and `returned_by_me` are about now and never do.
enum IntakePeriod {
  allTime('All time', null),
  week('Last 7', 7),
  month('Last 30', 30),
  quarter('Last 90', 90);

  const IntakePeriod(this.label, this.days);

  final String label;
  final int? days;
}

/// The CMO's and the Administrator's home: what is waiting for them, what they
/// did, and the register they may list.
class AgreementDashboardController extends GetxController {
  AgreementDashboardController({
    AgreementRepository? agreementRepository,
    AuthController? authController,
  }) : _agreements = agreementRepository ?? Get.find<AgreementRepository>(),
       _auth = authController ?? Get.find<AuthController>();

  final AgreementRepository _agreements;
  final AuthController _auth;

  final Rxn<AgreementDashboard> dashboard = Rxn<AgreementDashboard>();

  /// All time by default: no `from`/`to` goes on the wire at all.
  final Rx<IntakePeriod> period = Rx<IntakePeriod>(IntakePeriod.allTime);

  final RxBool isLoading = RxBool(false);
  final RxnString errorMessage = RxnString();

  int _sequence = 0;

  AuthUser? get officer => _auth.officer.value;
  MobileAccess? get access => _auth.access.value;

  bool get hasData => dashboard.value != null;

  /// Today in the officer's day. The server counts in Asia/Karachi, which is
  /// the handset's own zone in the field.
  DateTime? get from {
    final int? days = period.value.days;
    if (days == null) return null;
    return DateUtils.dateOnly(
      DateTime.now(),
    ).subtract(Duration(days: days - 1));
  }

  DateTime? get to =>
      period.value.days == null ? null : DateUtils.dateOnly(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Safe to call again — the pull-to-refresh and the resume refresh.
  Future<void> load() async {
    final int ticket = ++_sequence;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final AgreementDashboard result = await _agreements.dashboard(
        from: from,
        to: to,
      );
      if (ticket != _sequence) return;
      dashboard.value = result;
    } on ApiException catch (error) {
      if (ticket != _sequence) return;
      // A 403 means the role moved; the session says what is left.
      if (error.failure == ApiFailure.forbidden) await _auth.refreshAccess();
      errorMessage.value = error.message;
    } finally {
      if (ticket == _sequence) isLoading.value = false;
    }
  }

  Future<void> setPeriod(IntakePeriod value) async {
    if (value == period.value) return;
    period.value = value;
    await load();
  }

  /// The list a tile counted: its own scope, and this dashboard's dates where
  /// the scope is dated, so the two always agree.
  IntakeListQuery queryFor(IntakeTile tile, {required String label}) {
    final bool dated = IntakeScope.isDated(tile.scope);
    return IntakeListQuery(
      scope: tile.scope,
      status: tile.status,
      label: dated && period.value.days != null
          ? '$label · ${period.value.label.toLowerCase()}'
          : label,
      from: dated ? from : null,
      to: dated ? to : null,
    );
  }

  /// Re-reads after an act, if the dashboard has been built at all.
  static Future<void> reloadIfOpened() async {
    if (!Get.isRegistered<AgreementDashboardController>() ||
        Get.isPrepared<AgreementDashboardController>()) {
      return;
    }
    await Get.find<AgreementDashboardController>().load();
  }
}
