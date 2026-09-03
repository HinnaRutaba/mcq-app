import '../../core/network/api_config.dart';
import '../../core/network/api_service.dart';
import '../../models/person_lookup.dart';

/// Who is this? — the CNIC search an officer makes before writing a fine.
///
/// Four registers are answered separately and deliberately not merged. MCQ has
/// no single person register, so a screen built on this must show what each
/// register holds rather than presenting one identity the server never
/// asserted.
abstract class PersonRepository {
  /// Looks a person up by CNIC.
  ///
  /// Read `PersonLookup.fineCount` before opening the fine form: a first
  /// offence and a fifth are different conversations to have at a counter.
  /// `PersonLookup.suggested` is the block to pre-fill the form with — see
  /// `FineOffender.fromSuggestion`.
  ///
  /// A CNIC nobody has on record is not an error: it comes back with
  /// `known` false, and the fine form then has to collect every identity field
  /// by hand.
  Future<PersonLookup> byCnic(String cnic);
}

class ApiPersonRepository implements PersonRepository {
  ApiPersonRepository({required this._api});

  final ApiService _api;

  @override
  Future<PersonLookup> byCnic(String cnic) async {
    final response = await _api.get(
      ApiPaths.person,
      query: <String, dynamic>{'cnic': cnic},
    );
    return PersonLookup.fromJson(response.dataMap);
  }
}
