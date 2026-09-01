import '../../models/chalaan.dart';
import '../../models/seal_record.dart';
import '../../widgets/common/app_status_badge.dart';

/// Maps domain status enums to an [AppStatusTone] — kept here (not on the
/// generic [AppStatusBadge] widget) so the widget itself stays domain-free.
class StatusStyle {
  StatusStyle._();

  static AppStatusTone chalaanTone(ChalaanStatus status) {
    switch (status) {
      case ChalaanStatus.paid:
        return AppStatusTone.success;
      case ChalaanStatus.overdue:
        return AppStatusTone.danger;
      case ChalaanStatus.upcoming:
        return AppStatusTone.info;
    }
  }

  static AppStatusTone sealTone(SealStatus status) {
    switch (status) {
      case SealStatus.sealed:
        return AppStatusTone.danger;
      case SealStatus.readyToUnseal:
        return AppStatusTone.warning;
      case SealStatus.removed:
        return AppStatusTone.neutral;
    }
  }
}
