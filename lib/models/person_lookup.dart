import '../core/utils/json_parse.dart';
import 'api_refs.dart';
import 'trade_licence.dart';

/// Who is this? — the CNIC search an officer makes before writing a fine.
///
/// Four registers are answered **separately** and deliberately not merged: MCQ
/// has no single person register, and folding an allottee together with a trade
/// licence holder would assert an identity nobody verified. So do not present
/// this as one person: present what each register holds, and let the officer
/// decide.
///
/// Read [fineCount] before the form opens. A first offence and a fifth are
/// different conversations to have at a counter, and the count is the only
/// place that difference shows.
class PersonLookup {
  const PersonLookup({
    this.searched,
    this.cnic,
    this.known = false,
    this.allottees = const <AllotteeRef>[],
    this.tradeLicences = const <TradeLicence>[],
    this.previousFines = const <Map<String, dynamic>>[],
    this.fineCount = 0,
    this.suggested,
  });

  /// What was searched for, echoed back.
  final String? searched;

  /// The CNIC the server matched on.
  final String? cnic;

  /// Whether any register holds anything at all. False is not an error — it is
  /// a hawker nobody has written up before, and the fine form then has to
  /// collect every identity field by hand.
  final bool known;

  /// Tenancies on MCQ's own property register.
  final List<AllotteeRef> allottees;

  /// Licences MCQ issued to businesses it is not landlord to. A different
  /// register; see [TradeLicence].
  final List<TradeLicence> tradeLicences;

  /// Fines already on record against this CNIC, held as the raw payload: the
  /// published spec only ever captured this empty, so the row shape is not
  /// pinned down. Read [fineCount] for the number, and model this properly once
  /// a populated response is available.
  final List<Map<String, dynamic>> previousFines;

  /// How many fines this person already holds. The server's own count — do not
  /// take `previousFines.length` for it, which is however many rows this
  /// endpoint chose to return.
  final int fineCount;

  /// The best block to pre-fill the fine form with, and the register it came
  /// from. Null when nothing is known.
  final PersonSuggestion? suggested;

  factory PersonLookup.fromJson(Map<String, dynamic> json) => PersonLookup(
    searched: Json.string(json['searched']),
    cnic: Json.string(json['cnic']),
    known: Json.booleanOr(json['known']),
    allottees: Json.list(json['allottees']).map(AllotteeRef.fromJson).toList(),
    tradeLicences: Json.list(
      json['trade_licences'],
    ).map(TradeLicence.fromJson).toList(),
    previousFines: Json.list(json['previous_fines']),
    fineCount: Json.integerOr(json['fine_count']),
    suggested: PersonSuggestion.maybe(json['suggested']),
  );

  /// Fined before. Worth saying out loud on the form — it is the difference
  /// between a warning and a heavier amount.
  bool get isRepeatOffender => fineCount > 0;

  /// Holds an MCQ tenancy, so a fine on one of MCQ's units can be billed to
  /// them rather than collected as an offender's details.
  bool get isOnPropertyRegister => allottees.isNotEmpty;

  /// Holds a trade licence — which says nothing about whether it is still
  /// valid. Read `TradeLicence.isValid` for that.
  bool get isOnTradeRegister => tradeLicences.isNotEmpty;
}

/// The identity block to pre-fill a fine form with, and which register it was
/// taken from.
///
/// [source] matters: a name from `allottee` came off a signed agreement, and a
/// name from a trade licence came off an application. Show it, so the officer
/// knows how much the suggestion is worth before they read it back to the
/// person in front of them.
class PersonSuggestion {
  const PersonSuggestion({
    required this.name,
    this.fatherName,
    this.mobileNo,
    this.source,
  });

  final String name;
  final String? fatherName;
  final String? mobileNo;

  /// e.g. `allottee`. Server-defined, and a new register can appear without an
  /// app release.
  final String? source;

  factory PersonSuggestion.fromJson(Map<String, dynamic> json) =>
      PersonSuggestion(
        name: Json.stringOr(json['name']),
        fatherName: Json.string(json['father_name']),
        mobileNo: Json.string(json['mobile_no']),
        source: Json.string(json['source']),
      );

  static PersonSuggestion? maybe(Object? source) {
    if (source is! Map) return null;
    final suggestion = PersonSuggestion.fromJson(Json.map(source));
    return suggestion.name.isEmpty ? null : suggestion;
  }
}
