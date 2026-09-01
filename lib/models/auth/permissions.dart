/// The permission strings the API gates on.
///
/// A Municipal Magistrate holds exactly these 25 — that is the app's whole
/// surface. Note what is absent: no `billing.*` writes, no
/// `payment.record`, no `accounting.*`. A magistrate does not take money
/// and does not amend a bill; if a screen would let them, the screen is
/// wrong.
class Permissions {
  Permissions._();

  /// An Administrator's permission list is the single entry `*`.
  static const String all = '*';

  static const String allotmentView = 'allotment.view';
  static const String allotteeView = 'allottee.view';
  static const String challanView = 'billing.challan.view';
  static const String actionRecord = 'enforcement.action.record';
  static const String actionView = 'enforcement.action.view';
  static const String caseManage = 'enforcement.case.manage';
  static const String caseView = 'enforcement.case.view';
  static const String fineImpose = 'enforcement.fine.impose';
  static const String fineView = 'enforcement.fine.view';
  static const String sealApply = 'enforcement.seal.apply';
  static const String sealRelease = 'enforcement.seal.release';
  static const String sealView = 'enforcement.seal.view';
  static const String legalCaseView = 'legal.case.view';
  static const String legalHearingView = 'legal.hearing.view';
  static const String postingView = 'location.posting.view';
  static const String locationView = 'location.view';
  static const String notificationView = 'notification.view';
  static const String documentView = 'property.document.view';
  static const String inspectionRecord = 'property.inspection.record';
  static const String inspectionView = 'property.inspection.view';
  static const String propertyView = 'property.view';
  static const String paymentView = 'payment.view';
  static const String dashboardView = 'reporting.dashboard.view';
  static const String enforcementReportView = 'reporting.enforcement.view';

  /// Granted to the MAGISTRATE role so the full, area-scoped defaulters
  /// register can be opened (`GET /reporting/reports/defaulters`).
  static const String operationalReportView = 'reporting.operational.view';
}
