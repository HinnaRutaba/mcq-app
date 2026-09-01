import '../../models/chalaan.dart';
import '../../models/seal_record.dart';
import '../../config/theme/app_colors.dart';

/// Maps domain status enums to an [AppTone] — kept here (not on the
/// generic `AppStatusBadge` widget) so the widget itself stays domain-free.
class StatusStyle {
  StatusStyle._();

  static AppTone chalaanTone(ChalaanStatus status) {
    switch (status) {
      case ChalaanStatus.paid:
        return AppTone.success;
      case ChalaanStatus.overdue:
        return AppTone.danger;
      case ChalaanStatus.upcoming:
        return AppTone.info;
    }
  }

  static AppTone sealTone(SealStatus status) {
    switch (status) {
      case SealStatus.sealed:
        return AppTone.danger;
      case SealStatus.readyToUnseal:
        return AppTone.warning;
      case SealStatus.removed:
        return AppTone.neutral;
    }
  }
}
