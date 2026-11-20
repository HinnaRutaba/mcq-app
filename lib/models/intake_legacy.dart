import '../core/utils/json_parse.dart';

/// `legacy`: the shop's row in the imported legacy register, if it has one.
class IntakeLegacy {
  const IntakeLegacy({this.entry});

  /// Null when the shop has no row in the register.
  final IntakeLegacyEntry? entry;

  static IntakeLegacy? maybe(Object? source) {
    if (source is! Map) return null;
    final Map<String, dynamic>? entry = Json.mapOrNull(
      Json.map(source)['entry'],
    );
    return IntakeLegacy(
      entry: entry == null ? null : IntakeLegacyEntry.fromJson(entry),
    );
  }
}

/// `legacy.entry`, values exactly as sent.
class IntakeLegacyEntry {
  const IntakeLegacyEntry({
    this.id,
    this.versionNo,
    this.allotteeName,
    this.fatherName,
    this.cnic,
    this.mobileNo,
    this.monthlyRent,
    this.openingArrears,
    this.arrearsUpTo,
    this.sourceReference,
    this.sheetRow,
  });

  final String? id;
  final int? versionNo;
  final String? allotteeName;
  final String? fatherName;
  final String? cnic;
  final String? mobileNo;
  final String? monthlyRent;
  final String? openingArrears;

  /// `YYYY-MM-DD`.
  final String? arrearsUpTo;

  /// The spreadsheet and row it was imported from.
  final String? sourceReference;
  final int? sheetRow;

  factory IntakeLegacyEntry.fromJson(Map<String, dynamic> json) =>
      IntakeLegacyEntry(
        id: Json.string(json['id']),
        versionNo: Json.integer(json['version_no']),
        allotteeName: Json.string(json['allottee_name']),
        fatherName: Json.string(json['father_name']),
        cnic: Json.string(json['cnic']),
        mobileNo: Json.string(json['mobile_no']),
        monthlyRent: Json.string(json['monthly_rent']),
        openingArrears: Json.string(json['opening_arrears']),
        arrearsUpTo: Json.string(json['arrears_up_to']),
        sourceReference: Json.string(json['source_reference']),
        sheetRow: Json.integer(json['sheet_row']),
      );
}

/// How a case field reads against the legacy register.
enum LegacyMatch {
  same,
  differs,

  /// One side is blank, so there is nothing to compare.
  unchecked,
}

/// One field of the case beside the same field in the legacy register.
class LegacyCheck {
  const LegacyCheck({
    required this.label,
    required this.match,
    this.caseValue,
    this.legacyValue,
  });

  final String label;
  final LegacyMatch match;

  /// Display text; null when that side is blank.
  final String? caseValue;
  final String? legacyValue;
}
