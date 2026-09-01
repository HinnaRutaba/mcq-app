import 'package:get/get.dart';

import '../../../data/api/repositories/enforcement_repository.dart';
import '../../../models/property/property_summary.dart';

/// What a write screen needs to know about the thing it is writing against.
///
/// Carried as go_router `extra` from the screen the officer came from, so
/// the destructive confirmation can name the shop and the allottee without
/// a round trip — and so it still works with no signal, which is exactly
/// when a visit gets recorded.
///
/// Fetched only as a fallback, for a cold deep link.
class CaseWriteArgs {
  const CaseWriteArgs({
    required this.shopLabel,
    required this.allotteeName,
    this.caseId,
    this.sealId,
    this.propertyId,
    this.actionType,
  });

  final String shopLabel;
  final String allotteeName;
  final int? caseId;
  final int? sealId;
  final int? propertyId;

  /// Set when the officer chose the action from the sheet rather than from
  /// a dropdown — "Take a promise to pay" arrives here as
  /// `payment_promised`, and the form drops the dropdown entirely.
  ///
  /// This is what makes taking a promise two taps instead of five, which
  /// is the difference between a feature an officer uses at a shop front
  /// and one he does not.
  final String? actionType;

  CaseWriteArgs withActionType(String type) => CaseWriteArgs(
        shopLabel: shopLabel,
        allotteeName: allotteeName,
        caseId: caseId,
        sealId: sealId,
        propertyId: propertyId,
        actionType: type,
      );

  static Future<CaseWriteArgs> forCase(int caseId) async {
    final item = await Get.find<EnforcementRepository>().caseById(caseId);
    return CaseWriteArgs(
      shopLabel: item.property.label,
      allotteeName: item.allottee.name,
      caseId: caseId,
      sealId: item.sealId,
      propertyId: item.property.id,
    );
  }

  static Future<CaseWriteArgs> forSeal(int sealId) async {
    final seal = await Get.find<EnforcementRepository>().sealById(sealId);
    return CaseWriteArgs(
      shopLabel: seal.property.label,
      allotteeName: seal.allottee.name,
      caseId: seal.caseId,
      sealId: sealId,
      propertyId: seal.property.id,
    );
  }

  static CaseWriteArgs forProperty(PropertySummary property) => CaseWriteArgs(
        shopLabel: property.label,
        allotteeName: property.allottee.exists ? property.allottee.name : '',
        propertyId: property.id,
      );
}
