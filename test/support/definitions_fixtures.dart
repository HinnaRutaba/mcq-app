import 'package:mcq_app/data/repositories/definitions_repository.dart';
import 'package:mcq_app/models/enforcement_definitions.dart';

/// The enforcement module's master data, as `GET enforcement/definitions`
/// returns it — the offences a fine may be raised for, with the amount and the
/// section of law the register suggests for each.
///
/// Shared, so the fine form's tests and the previews pick from the same rows a
/// screen would.
const Map<String, dynamic> definitionsResponse = <String, dynamic>{
  'data': <String, dynamic>{
    'fine_types': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 3,
        'code': 'unauthorised_use',
        'name': 'Unauthorised use',
        'name_ur': 'غیر مجاز استعمال',
        'default_provision':
            'Section 96, Balochistan Local Government Act 2010',
        'suggested_amount': '10000.00',
      },
      <String, dynamic>{
        'id': 4,
        'code': 'encroachment',
        'name': 'Encroachment',
        'name_ur': 'تجاوزات',
        'default_provision':
            'Section 97, Balochistan Local Government Act 2010',
        'suggested_amount': '3000.00',
      },
    ],
    'action_types': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'code': 'site_visit',
        'name': 'Site visit',
        'fields': <String, dynamic>{
          'promise_date': false,
          'visit_date': false,
          'amount': false,
          'seal_no': false,
        },
      },
      <String, dynamic>{
        'id': 5,
        'code': 'payment_promised',
        'name': 'Payment promised',
        'fields': <String, dynamic>{
          'promise_date': true,
          'visit_date': false,
          'amount': false,
          'seal_no': false,
        },
      },
      <String, dynamic>{
        'id': 7,
        'code': 'fine_imposed',
        'name': 'Fine imposed',
        'fields': <String, dynamic>{
          'promise_date': false,
          'visit_date': false,
          'amount': true,
          'seal_no': false,
        },
      },
    ],
    'case_statuses': <Map<String, dynamic>>[
      <String, dynamic>{
        'value': 'warned',
        'label': 'Warned',
        'tone': 'warning',
      },
    ],
    'case_priorities': <Map<String, dynamic>>[
      <String, dynamic>{
        'value': 'critical',
        'label': 'Urgent',
        'tone': 'danger',
      },
    ],
    'seal_statuses': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'sealed', 'label': 'Sealed', 'tone': 'danger'},
    ],
    'fine_statuses': <Map<String, dynamic>>[
      <String, dynamic>{'value': 'paid', 'label': 'Paid', 'tone': 'success'},
    ],
  },
};

/// Answers with the fixture instead of the network, for a screen whose pickers
/// are drawn from the register.
class FakeDefinitionsRepository implements DefinitionsRepository {
  EnforcementDefinitions? _cached;

  @override
  EnforcementDefinitions? get cached => _cached;

  @override
  Future<EnforcementDefinitions> definitions({bool refresh = false}) async =>
      _cached ??= EnforcementDefinitions.fromJson(
        Map<String, dynamic>.from(definitionsResponse['data']! as Map),
      );

  @override
  void forget() => _cached = null;
}
