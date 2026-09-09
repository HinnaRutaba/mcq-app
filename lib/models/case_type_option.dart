import '../core/utils/json_parse.dart';

/// One kind of case an officer can open from the field — what travels as
/// `case_type`.
///
/// Read through `EnforcementCaseRepository.caseTypes()` rather than switched
/// on in the form: MCQ is expected to publish these, and a copy written into
/// a screen is a picker that silently stops matching.
class CaseTypeOption {
  const CaseTypeOption({
    required this.code,
    required this.name,
    this.nameUr,
    this.description,
  });

  /// e.g. `unauthorised_use`.
  final String code;

  /// e.g. "Unauthorised use".
  final String name;

  /// The Urdu wording, where the register carries one.
  final String? nameUr;

  /// When this kind of case applies, in the register's own words.
  final String? description;

  /// Read either spelling: `code`/`name` as `enforcement/definitions`
  /// publishes its rows, `value`/`label` as the status vocabularies do.
  factory CaseTypeOption.fromJson(Map<String, dynamic> json) {
    final String code = Json.stringOr(
      Json.pick(json, <String>['code', 'value']),
    );
    return CaseTypeOption(
      code: code,
      name: Json.stringOr(Json.pick(json, <String>['name', 'label']), code),
      nameUr: Json.string(Json.pick(json, <String>['name_ur', 'ur_name'])),
      description: Json.string(json['description']),
    );
  }
}
