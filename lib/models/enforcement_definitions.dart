import '../core/utils/json_parse.dart';
import 'api_refs.dart';

/// Every drop-down in the enforcement module, in one payload.
///
/// Fetch it once at sign-in and cache it — see `DefinitionsRepository`. Do not
/// copy the fine types or the action types into the app: they are rows MCQ can
/// rename, reorder and switch off, and a hardcoded copy is a list that
/// silently stops matching the register.
///
/// The four status vocabularies come through as [LabelledValue] like every
/// other status in the system, so a filter chip built from them is coloured by
/// the same `tone` the server puts on the record itself.
class EnforcementDefinitions {
  const EnforcementDefinitions({
    this.fineTypes = const <FineTypeDefinition>[],
    this.actionTypes = const <ActionTypeDefinition>[],
    this.caseStatuses = const <LabelledValue>[],
    this.casePriorities = const <LabelledValue>[],
    this.sealStatuses = const <LabelledValue>[],
    this.fineStatuses = const <LabelledValue>[],
  });

  /// The offences a fine can be raised for, each with the provision to quote
  /// and an amount to start the officer off.
  final List<FineTypeDefinition> fineTypes;

  /// Everything that can appear on a case timeline — including the entries the
  /// server writes itself. See [ActionTypeDefinition.fields] before drawing a
  /// form for one.
  final List<ActionTypeDefinition> actionTypes;

  /// e.g. Open, Notice served, Sealed, Settled.
  final List<LabelledValue> caseStatuses;

  /// e.g. Low, Normal, High, Urgent.
  final List<LabelledValue> casePriorities;

  /// e.g. Sealed, Cleared for reopening, Reopened, Seal cancelled.
  final List<LabelledValue> sealStatuses;

  /// e.g. Imposed, Added to a challan, Paid, Waived, Cancelled.
  final List<LabelledValue> fineStatuses;

  factory EnforcementDefinitions.fromJson(Map<String, dynamic> json) =>
      EnforcementDefinitions(
        fineTypes: Json.list(
          json['fine_types'],
        ).map(FineTypeDefinition.fromJson).toList(),
        actionTypes: Json.list(
          json['action_types'],
        ).map(ActionTypeDefinition.fromJson).toList(),
        caseStatuses: _labels(json['case_statuses']),
        casePriorities: _labels(json['case_priorities']),
        sealStatuses: _labels(json['seal_statuses']),
        fineStatuses: _labels(json['fine_statuses']),
      );

  static List<LabelledValue> _labels(Object? source) =>
      Json.list(source).map(LabelledValue.fromJson).toList();

  /// The offence with this code, e.g. `encroachment`. Null when MCQ has
  /// switched it off since the app last cached the definitions.
  FineTypeDefinition? fineType(String code) {
    for (final type in fineTypes) {
      if (type.code == code) return type;
    }
    return null;
  }

  FineTypeDefinition? fineTypeById(int id) {
    for (final type in fineTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  ActionTypeDefinition? actionType(String code) {
    for (final type in actionTypes) {
      if (type.code == code) return type;
    }
    return null;
  }

  ActionTypeDefinition? actionTypeById(int id) {
    for (final type in actionTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// The labelled entry for a stored value, so a screen holding a bare
  /// `"part_recovered"` can print "Some money recovered" without a lookup
  /// table of its own.
  LabelledValue? caseStatus(String value) => _find(caseStatuses, value);

  LabelledValue? casePriority(String value) => _find(casePriorities, value);

  LabelledValue? sealStatus(String value) => _find(sealStatuses, value);

  LabelledValue? fineStatus(String value) => _find(fineStatuses, value);

  static LabelledValue? _find(List<LabelledValue> among, String value) {
    for (final entry in among) {
      if (entry.value == value) return entry;
    }
    return null;
  }

  bool get isEmpty => fineTypes.isEmpty && actionTypes.isEmpty;
}

/// One offence a fine can be raised for.
///
/// [defaultProvision] and [suggestedAmount] are what to pre-fill the fine form
/// with — the officer can change both, and the server has the final word on
/// whether the amount is within their field limit.
class FineTypeDefinition {
  const FineTypeDefinition({
    this.id,
    required this.code,
    required this.name,
    this.nameUr,
    this.description,
    this.defaultProvision,
    this.suggestedAmount,
  });

  /// What to send as `fine_type_id`.
  final int? id;

  /// What to send as `fine_type`, e.g. `non_payment`, `seal_violation`.
  final String code;

  /// e.g. "Breaking a seal".
  final String name;

  /// The Urdu wording, for an officer whose `locale` is `ur`.
  final String? nameUr;

  /// When this offence applies, in the server's own words. Worth showing: the
  /// difference between `unauthorised_use` and `encroachment` is which
  /// register the person is on, not how bad it was.
  final String? description;

  /// The section of law to quote, e.g. "Section 96, Balochistan Local
  /// Government Act 2010". Null on `other`, which is why the fine form still
  /// has to ask.
  final String? defaultProvision;

  /// A starting amount, as a string. Pre-fill the field with it; never do
  /// arithmetic on it.
  final String? suggestedAmount;

  factory FineTypeDefinition.fromJson(Map<String, dynamic> json) =>
      FineTypeDefinition(
        id: Json.integer(json['id']),
        code: Json.stringOr(json['code']),
        name: Json.stringOr(json['name'], Json.stringOr(json['code'])),
        // The published document renders this key both ways round; read both.
        nameUr: Json.string(Json.pick(json, <String>['name_ur', 'ur_name'])),
        description: Json.string(json['description']),
        defaultProvision: Json.string(json['default_provision']),
        suggestedAmount: Json.money(json['suggested_amount']),
      );
}

/// One kind of entry on a case timeline.
///
/// [fields] says which of the four optional inputs this action wants — draw the
/// form from it rather than from a `switch` on [code], so an action MCQ adds
/// later still gets the right form.
class ActionTypeDefinition {
  const ActionTypeDefinition({
    this.id,
    required this.code,
    required this.name,
    this.nameUr,
    this.description,
    this.fields = const ActionTypeFields(),
  });

  final int? id;

  /// e.g. `site_visit`, `payment_promised`.
  final String code;

  final String name;
  final String? nameUr;
  final String? description;

  /// Which optional inputs the action carries.
  final ActionTypeFields fields;

  factory ActionTypeDefinition.fromJson(Map<String, dynamic> json) =>
      ActionTypeDefinition(
        id: Json.integer(json['id']),
        code: Json.stringOr(json['code']),
        name: Json.stringOr(json['name'], Json.stringOr(json['code'])),
        nameUr: Json.string(Json.pick(json, <String>['name_ur', 'ur_name'])),
        description: Json.string(json['description']),
        fields: ActionTypeFields.fromJson(Json.map(json['fields'])),
      );
}

/// The form spec for an action type: which of the four optional inputs the
/// server expects alongside it.
///
/// An action whose flags are all false needs nothing but a date and remarks.
/// The two that carry a date are what put a shopkeeper on a follow-up list, so
/// they are not optional in practice — see
/// `EnforcementActionRequest`, which asserts on them.
class ActionTypeFields {
  const ActionTypeFields({
    this.promiseDate = false,
    this.visitDate = false,
    this.amount = false,
    this.sealNo = false,
  });

  /// Send `promised_payment_date` — the date that puts them on the follow-up
  /// list.
  final bool promiseDate;

  /// Send `next_visit_date`.
  final bool visitDate;

  /// The action carries a money figure. True on `fine_imposed`, which the fine
  /// endpoint raises — not something the app posts as an action.
  final bool amount;

  /// The action carries a seal number. True on `seal` and `unseal`, both of
  /// which the server records itself.
  final bool sealNo;

  factory ActionTypeFields.fromJson(Map<String, dynamic> json) =>
      ActionTypeFields(
        promiseDate: Json.booleanOr(json['promise_date']),
        visitDate: Json.booleanOr(json['visit_date']),
        amount: Json.booleanOr(json['amount']),
        sealNo: Json.booleanOr(json['seal_no']),
      );

  /// Whether this action needs anything beyond a date and remarks.
  bool get hasAny => promiseDate || visitDate || amount || sealNo;
}
