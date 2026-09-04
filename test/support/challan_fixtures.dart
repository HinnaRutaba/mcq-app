import 'package:mcq_app/data/repositories/challan_repository.dart';
import 'package:mcq_app/models/models.dart';

/// The billing module's payloads, for a preview or a screen test.
///
/// Shaped from `GET /api/v1/billing/challans` — a rent bill carries a billing
/// period, an allotment and a breakdown; a fine carries `is_single_charge` and
/// often no allottee at all, because it can be raised against somebody who is
/// not on the register.

Map<String, dynamic> _challan({
  required int id,
  required String challanNo,
  required String status,
  required String statusLabel,
  String? statusTone,
  bool fine = false,
  String? period,
  String? dueDate,
  bool overdue = false,
  int daysOverdue = 0,
  String? payableNow,
  String? balance,
  String? currentAmount,
  String? arrears,
  String? surcharge,
  String? other,
  String? allotteeName,
  String? mobileNo,
  String? payerName,
  String? payerMobileNo,
  String? unit,
  String? areaName,
  bool liveLink = false,
  String? remarks,
}) => <String, dynamic>{
  'id': id,
  'challan_no': challanNo,
  'challan_type': <String, dynamic>{
    'value': fine ? 'fine' : 'rent',
    'label': fine ? 'Fine' : 'Rent',
    'tone': fine ? 'warning' : 'neutral',
  },
  'is_single_charge': fine,
  'surcharge_exempt': false,
  'status': <String, dynamic>{
    'value': status,
    'label': statusLabel,
    'tone': statusTone,
  },
  'issue_date': '2026-08-01',
  'due_date': dueDate,
  'is_overdue': overdue,
  'days_overdue': daysOverdue,
  'amounts': <String, dynamic>{
    'previous_balance': '0.00',
    'current_amount': currentAmount ?? '0.00',
    'arrears_amount': arrears ?? '0.00',
    'surcharge_amount': surcharge ?? '0.00',
    'other_amount': other ?? '0.00',
    'adjustment_amount': '0.00',
    'total_amount': balance,
    'paid_amount': '0.00',
    'balance_amount': balance,
    'deferred_amount': '0.00',
    'payable_now': payableNow ?? balance,
  },
  'is_prorated': false,
  'is_edited': false,
  'remarks': remarks,
  'consumer_number': '0424${id.toString().padLeft(6, '0')}',
  'link_short_code': liveLink ? 'CH$id' : null,
  'has_live_link': liveLink,
  'can_defer': !fine,
  'billing_period': period == null
      ? null
      : <String, dynamic>{
          'id': id,
          'period_code': period,
          'fiscal_year': '2026-2027',
        },
  'allotment': allotteeName == null
      ? null
      : <String, dynamic>{'id': id, 'allotment_no': 'ALT-$id'},
  'allottee': allotteeName == null
      ? null
      : <String, dynamic>{
          'id': id,
          'allottee_code': 'ALE-$id',
          'full_name': allotteeName,
          'mobile_no': mobileNo,
          'cnic': '5440112233${id.toString().padLeft(3, '0')}',
        },
  'payer_name': payerName,
  'payer_mobile_no': payerMobileNo,
  'property': unit == null
      ? null
      : <String, dynamic>{
          'id': id,
          'property_code': 'P-$id',
          'display_name': unit,
        },
  'area': areaName == null
      ? null
      : <String, dynamic>{'id': 1, 'name': areaName, 'code': 'JR'},
  'created_at': '2026-08-01T06:00:00+00:00',
};

/// Two months of rent and two penalties — enough for the list to have to keep
/// the two apart.
final List<Challan> challansFixture = <Map<String, dynamic>>[
  _challan(
    id: 501,
    challanNo: 'CH-2026-08-0501',
    status: 'overdue',
    statusLabel: 'Overdue',
    statusTone: 'danger',
    period: '2026-08',
    dueDate: '2026-08-15',
    overdue: true,
    daysOverdue: 19,
    balance: '18450.00',
    currentAmount: '12000.00',
    arrears: '5200.00',
    surcharge: '1250.00',
    allotteeName: 'Abdul Karim',
    mobileNo: '0300 1234504',
    unit: 'Shop S-19, Liaquat Bazaar',
    areaName: 'Jinnah Road',
    liveLink: true,
  ),
  _challan(
    id: 502,
    challanNo: 'CH-2026-08-0502',
    status: 'dispatched',
    statusLabel: 'Sent out',
    statusTone: 'info',
    period: '2026-08',
    dueDate: '2026-09-15',
    balance: '9600.00',
    currentAmount: '9600.00',
    allotteeName: 'Noor Muhammad',
    mobileNo: '0333 9871122',
    unit: 'Shop S-04, Prince Road',
    areaName: 'Prince Road',
    liveLink: true,
  ),
  // A fine on somebody who is not on the register: no allottee, so `payer_name`
  // is the only name on the bill and the number to ring.
  _challan(
    id: 503,
    challanNo: 'CH-2026-08-0503',
    status: 'unpaid',
    statusLabel: 'Unpaid',
    statusTone: 'warning',
    fine: true,
    dueDate: '2026-08-20',
    overdue: true,
    daysOverdue: 14,
    balance: '5000.00',
    other: '5000.00',
    payerName: 'Gul Hassan',
    payerMobileNo: '0345 5540099',
    areaName: 'Jinnah Road',
    remarks: 'Encroachment onto the footpath, second warning.',
  ),
  _challan(
    id: 504,
    challanNo: 'CH-2026-08-0504',
    status: 'unpaid',
    statusLabel: 'Unpaid',
    statusTone: 'warning',
    fine: true,
    dueDate: '2026-09-01',
    balance: '2500.00',
    other: '2500.00',
    allotteeName: 'Shahid Iqbal',
    mobileNo: '0312 4477881',
    unit: 'Shop S-31, Liaquat Bazaar',
    areaName: 'Jinnah Road',
    liveLink: true,
    remarks: 'Trading past permitted hours.',
  ),
].map(Challan.fromJson).toList();

/// One row exactly as `billing/challans` sent it, keys and all.
///
/// Copied from a live response rather than the published spec, which is how
/// `challan_type: combined` and `allotment.allotment_type` came to light —
/// neither was in the document the models were written from.
final Map<String, dynamic> challanOffTheWireJson = <String, dynamic>{
  'id': 1377,
  'challan_no': 'MCQ-CH-2627-0000593',
  'challan_type': <String, dynamic>{
    'value': 'combined',
    'label': 'Everything owed',
    'tone': 'neutral',
  },
  'is_single_charge': false,
  'surcharge_exempt': false,
  'surcharge_exempt_reason': null,
  'status': <String, dynamic>{
    'value': 'draft',
    'label': 'Draft',
    'tone': 'neutral',
  },
  'issue_date': '2026-11-25',
  'due_date': '2026-12-05',
  'is_overdue': false,
  'days_overdue': 0,
  'amounts': <String, dynamic>{
    'previous_balance': '0.00',
    'current_amount': '40000.00',
    'arrears_amount': '22222.22',
    'surcharge_amount': '0.00',
    'other_amount': '0.00',
    'adjustment_amount': '0.00',
    'total_amount': '62222.22',
    'paid_amount': '0.00',
    'balance_amount': '62222.22',
    'deferred_amount': '0.00',
    'payable_now': '62222.22',
  },
  'is_prorated': false,
  'proration_days': null,
  'is_edited': false,
  'remarks': null,
  'consumer_number': null,
  'link_short_code': null,
  'link_expires_at': null,
  'has_live_link': false,
  'can_defer': false,
  'dispatched_at': null,
  'first_paid_at': null,
  'settled_at': null,
  'superseded_by_challan_id': null,
  'billing_period': <String, dynamic>{
    'id': 9,
    'period_code': '2026-11',
    'fiscal_year': '2026-2027',
  },
  'allotment': <String, dynamic>{
    'id': 210,
    'allotment_no': 'MCQ-AL-00210',
    'allotment_type': <String, dynamic>{
      'value': 'rent',
      'label': 'Rent',
      'tone': 'neutral',
    },
  },
  'allottee': <String, dynamic>{
    'id': 12,
    'allottee_code': 'ALT-00012',
    'name': 'Abdul Malik Pirkani',
    'mobile_no': '03301000011',
  },
  'payer_name': null,
  'payer_mobile_no': null,
  'property': <String, dynamic>{
    'id': 240,
    'property_code': 'MCQ-JR-0009',
    'display_name': 'Jinnah Parking, Kandahari Bazaar',
  },
  'area': <String, dynamic>{'id': 1, 'code': 'JR', 'name': 'Jinnah Road'},
  'created_at': '2026-09-02T12:42:51+00:00',
  'updated_at': '2026-09-02T12:42:51+00:00',
};

final Challan challanOffTheWire = Challan.fromJson(challanOffTheWireJson);

/// [count] bills, so a test can outrun a page. Every fourth is a fine, so the
/// type filter has something to find on the pages after the first.
List<Challan> challanRun(int count) => <Challan>[
  for (int i = 0; i < count; i++)
    Challan.fromJson(
      _challan(
        id: 900 + i,
        challanNo: 'CH-2026-08-${(900 + i).toString()}',
        status: 'unpaid',
        statusLabel: 'Unpaid',
        statusTone: 'warning',
        fine: i % 4 == 3,
        period: i % 4 == 3 ? null : '2026-08',
        dueDate: '2026-09-15',
        balance: '${1000 + i * 10}.00',
        allotteeName: 'Holder ${i + 1}',
        mobileNo: '0300 000${i.toString().padLeft(4, '0')}',
        unit: 'Shop S-${i + 1}, Liaquat Bazaar',
        areaName: 'Jinnah Road',
      ),
    ),
];

/// Pages and filters the way the endpoint does, so the controller's cursor is
/// exercised rather than mocked away.
class FakeChallanRepository implements ChallanRepository {
  FakeChallanRepository({List<Challan>? challans, this.failure})
    : _all = challans ?? challansFixture;

  /// Mutable so a test can let the signal come back and retry.
  Object? failure;

  final List<Challan> _all;

  int calls = 0;
  final List<int?> pagesAsked = <int?>[];
  final List<String?> typesAsked = <String?>[];

  @override
  Future<Paginated<Challan>> challans({
    int? page,
    int? perPage,
    String? challanType,
  }) async {
    calls++;
    pagesAsked.add(page);
    typesAsked.add(challanType);
    if (failure != null) throw failure!;

    final List<Challan> rows = challanType == null
        ? _all
        : _all
              .where((Challan c) => c.challanType?.value == challanType)
              .toList();

    final int size = perPage ?? (rows.isEmpty ? 1 : rows.length);
    final int current = page ?? 1;
    final int from = (current - 1) * size;
    final List<Challan> slice = from >= rows.length
        ? const <Challan>[]
        : rows.sublist(
            from,
            from + size > rows.length ? rows.length : from + size,
          );

    return Paginated<Challan>(
      items: slice,
      meta: PageMeta(
        currentPage: current,
        perPage: size,
        lastPage: rows.isEmpty ? 1 : (rows.length + size - 1) ~/ size,
        total: rows.length,
        from: slice.isEmpty ? null : from + 1,
        to: slice.isEmpty ? null : from + slice.length,
      ),
    );
  }
}
