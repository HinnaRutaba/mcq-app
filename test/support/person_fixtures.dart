import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/data/repositories/person_repository.dart';
import 'package:mcq_app/models/person_lookup.dart';

/// `GET enforcement/field/person?cnic=…` for a CNIC on the property register,
/// as the published document captured it.
Map<String, dynamic> personLookupJson(String cnic) => <String, dynamic>{
  'searched': cnic,
  'cnic': cnic,
  'known': true,
  'allottees': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '1',
      'allottee_code': 'ALT-00001',
      'name': 'Haji Abdul Rauf Kakar',
      'father_name': 'Abdul Ghafoor Kakar',
      'mobile_no': '03368359506',
      'cnic': cnic,
      'status': 'active',
    },
  ],
  'trade_licences': <Map<String, dynamic>>[],
  'previous_fines': <Map<String, dynamic>>[],
  'fine_count': 0,
  'suggested': <String, dynamic>{
    'name': 'Haji Abdul Rauf Kakar',
    'father_name': 'Abdul Ghafoor Kakar',
    'mobile_no': '03368359506',
    'source': 'allottee',
  },
};

/// Answers the CNIC search from memory, and remembers what was asked.
class FakePersonRepository implements PersonRepository {
  FakePersonRepository({this.failure, this.fineCount = 0, this.known = true});

  /// Thrown instead of answering, for the bazaar with no signal.
  final ApiException? failure;

  /// How many fines the person already holds — the figure the card leads with
  /// when it is above zero.
  final int fineCount;

  /// Whether any register holds this CNIC. False comes back as a lookup with
  /// nothing to suggest — a person nobody has written up before.
  bool known;

  final List<String> searched = <String>[];

  @override
  Future<PersonLookup> byCnic(String cnic) async {
    searched.add(cnic);
    final ApiException? thrown = failure;
    if (thrown != null) throw thrown;
    if (!known) {
      return PersonLookup.fromJson(<String, dynamic>{
        'searched': cnic,
        'cnic': cnic,
        'known': false,
        'allottees': <Map<String, dynamic>>[],
        'trade_licences': <Map<String, dynamic>>[],
        'previous_fines': <Map<String, dynamic>>[],
        'fine_count': 0,
      });
    }
    return PersonLookup.fromJson(<String, dynamic>{
      ...personLookupJson(cnic),
      'fine_count': fineCount,
    });
  }
}
