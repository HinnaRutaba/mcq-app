import 'dart:io';

import 'package:mcq_app/core/network/api_exception.dart';
import 'package:mcq_app/core/network/api_service.dart';
import 'package:mcq_app/data/repositories/agreement_repository.dart';
import 'package:mcq_app/models/models.dart';

/// Payloads shaped from `docs/MOBILE_API.md`'s field tables. The captured
/// examples file was not in the repo, so these follow the guide's wording;
/// swap in captured bodies when they are to hand.
Map<String, dynamic> sessionWith({
  List<String> workspaces = const <String>['agreements'],
  List<String> capabilities = const <String>[
    'agreements.endorse',
    'agreements.dispatch',
    'agreements.view',
    'agreements.execution_evidence',
  ],
  bool passwordChangeRequired = false,
  String? token,
}) => <String, dynamic>{
  'data': <String, dynamic>{
    'token': ?token,
    'expires_at': '2026-12-16T10:00:00+05:00',
    'user': <String, dynamic>{
      'id': '9',
      'username': 'cmo.quetta',
      'name': 'Sana Baloch',
      'designation': 'Chief Municipal Officer',
      'roles': <String>['CMO'],
      'permissions': <String>['allotment.intake.forward'],
    },
    'mobile': <String, dynamic>{
      'workspaces': workspaces,
      'capabilities': capabilities,
      'password_change_required': passwordChangeRequired,
    },
  },
  'message': 'Signed in.',
};

Map<String, dynamic> dashboardData() => <String, dynamic>{
  'waiting': <String, dynamic>{
    'total': 7,
    'scope': 'awaiting_me',
    'queues': <Map<String, dynamic>>[
      <String, dynamic>{'key': 'review', 'count': 5, 'scope': 'review'},
      <String, dynamic>{'key': 'queries', 'count': 1, 'scope': 'queries'},
      <String, dynamic>{'key': 'dispatch', 'count': 1, 'scope': 'dispatch'},
    ],
  },
  'returned_by_me': <String, dynamic>{'count': 2, 'scope': 'returned_by_me'},
  'my_actions': <Map<String, dynamic>>[
    <String, dynamic>{
      'action': 'endorsed',
      'cases': 12,
      'acts': 14,
      'scope': 'acted:endorsed',
    },
    <String, dynamic>{
      'action': 'returned',
      'cases': 3,
      'acts': 3,
      'scope': 'acted:returned',
    },
    <String, dynamic>{
      'action': 'dispatched',
      'cases': 4,
      'acts': 4,
      'scope': 'acted:dispatched',
    },
  ],
  'register': <String, dynamic>{
    'by_status': <Map<String, dynamic>>[
      <String, dynamic>{
        'status': <String, dynamic>{
          'value': 'pending_cmo',
          'label': 'With the CMO',
        },
        'count': 5,
        'scope': 'all',
      },
      <String, dynamic>{
        'status': <String, dynamic>{
          'value': 'pending_admin',
          'label': 'With the Administrator',
        },
        'count': 8,
        'scope': 'all',
      },
      <String, dynamic>{'status': 'activated', 'count': 21, 'scope': 'all'},
      <String, dynamic>{'status': 'rejected', 'count': 0, 'scope': 'all'},
    ],
    'in_progress': 14,
    'activated_cases': 21,
    'agreements_live': 19,
  },
  'generated_at': '2026-11-16T09:30:00+05:00',
};

Map<String, dynamic> caseData({
  String id = '41',
  String status = 'pending_cmo',
  int lockVersion = 3,
  bool endorseAllowed = true,
  bool queryOpen = false,
  // The Administrator's stage: approve, return or reject.
  bool admin = false,
  // Sent back once before, with remarks long enough to fold.
  bool returned = false,
}) => <String, dynamic>{
  'id': id,
  'intake_no': 'CA-2026-0041',
  'case_type': <String, dynamic>{'value': 'new', 'label': 'New allotment'},
  'status': <String, dynamic>{
    'value': status,
    'label': 'With the CMO',
    'tone': 'warning',
  },
  'approval_route': 'standard',
  'content_revision': 38,
  'lock_version': lockVersion,
  'with_branch': 'cmo',
  'next_action': 'CMO review',
  'submitted_at': '2026-11-12T11:20:00+05:00',
  'shop': <String, dynamic>{
    'shop_no': 'S-14',
    'market': <String, dynamic>{'id': 3, 'name': 'Liaquat Bazaar'},
    'area': <String, dynamic>{'id': 2, 'name': 'Prince Road'},
    'zone': 'Zone A',
    'address': 'Liaquat Bazaar, Quetta',
    'verified': true,
    'reviewed_location': <String, dynamic>{
      'market': 'Liaquat Bazaar',
      'area': 'Prince Road',
      'zone': 'Zone A',
      'shop': 'S-14',
    },
    'location_changed_since_review': false,
  },
  'applicant': <String, dynamic>{
    'name': 'Abdul Karim',
    'father_name': 'Muhammad Yousaf',
    'cnic': '54400-1122334-5',
    'mobile': '03001234567',
    'address': 'Satellite Town, Quetta',
    'business': 'Cloth merchant',
    'ntn': null,
    'record': <String, dynamic>{'matches': true, 'label': 'AL-00912'},
  },
  // Name and CNIC agree once spacing and dashes are ignored; the rest differ.
  'legacy': <String, dynamic>{
    'entry': <String, dynamic>{
      'id': '113',
      'version_no': 1,
      'allottee_name': 'Abdul karim',
      'father_name': 'Haji Muhammad Yousaf',
      'cnic': '5440011223345',
      'mobile_no': '03362318009',
      'monthly_rent': '10248.70',
      'opening_arrears': '512828.40',
      'arrears_up_to': '2021-07-30',
      'source_reference': 'Sheeetoffinalmcq.xlsx, Sheet1 row 115',
      'sheet_row': 115,
    },
    'agreement': null,
    'allottee': null,
  },
  'witnesses': <Map<String, dynamic>>[
    <String, dynamic>{
      'position': 1,
      'name': 'Gul Khan',
      'father_name': 'Noor Khan',
      'cnic': '54400-9988776-1',
      'mobile': '03111234567',
    },
    <String, dynamic>{
      'position': 2,
      'name': 'Faiz Muhammad',
      'father_name': 'Sher Muhammad',
      'cnic': '54400-3344556-7',
    },
  ],
  'amounts': <String, dynamic>{
    'verified_monthly_rent': '12500.00',
    'opening_arrears': '45000.00',
    'opening_arrears_as_of': '2026-10-31',
    'charges_rent': true,
    'security_deposit': '37500.00',
    'first_rent_month': '2026-12',
    'instalments': <String, dynamic>{
      'offered': true,
      'months': 12,
      'breakdown': <String, dynamic>{
        'total': '1831530.00',
        'months': 12,
        'each': '152627.50',
        'last': '152627.50',
        'uneven': false,
        'first_period': '2026-11',
      },
    },
  },
  'actions': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '201',
      'action': <String, dynamic>{'value': 'submitted', 'label': 'Submitted'},
      'actor': <String, dynamic>{'name': 'Estate clerk'},
      'actor_role': 'estate',
      'branch': 'estate',
      'from_status': 'draft',
      'to_status': 'pending_taxation',
      'at': '2026-11-10T10:00:00+05:00',
      'attachments': <Map<String, dynamic>>[],
    },
    <String, dynamic>{
      'id': '202',
      'action': <String, dynamic>{
        'value': 'taxation_forwarded',
        'label': 'Forwarded by Taxation',
      },
      'actor': 'Taxation Superintendent',
      'branch': 'taxation',
      'from_status': 'pending_taxation',
      'to_status': 'pending_cmo',
      'remarks': 'Arrears verified against the register.',
      'at': '2026-11-12T11:20:00+05:00',
      'attachments': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '7',
          'filename': 'arrears-statement.pdf',
          'mime': 'application/pdf',
          'url': '/api/v1/allotment/intakes/41/actions/202/files/7',
        },
      ],
    },
  ],
  'last_return': returned
      ? <String, dynamic>{
          'returned_by': 'Administrator',
          'from_stage': 'administrator',
          'remarks':
              'The arrears statement does not match the legacy register: '
              'the register shows Rs 512,828.40 up to July 2021, the case '
              'Rs 45,000. Attach the reconciliation and the allottee’s '
              'affidavit before sending it on again.',
          'at': '2026-11-13T09:30:00+05:00',
        }
      : null,
  'stage': <String, dynamic>{
    'query': queryOpen
        ? <String, dynamic>{
            'asked_by': 'Administrator',
            'from_stage': 'administrator',
            'remarks': 'Confirm the deposit was taken at the new rate.',
            'at': '2026-11-14T15:00:00+05:00',
          }
        : null,
    'act_options': admin
        ? <Map<String, dynamic>>[
            for (final String act in <String>['approve', 'return', 'reject'])
              <String, dynamic>{
                'act': act,
                'allowed': true,
                'reason': null,
                'method': 'POST',
                'path': '/api/v1/allotment/intakes/$id/$act',
                'signed': act == 'approve',
                'remarks_required': act != 'approve',
                'destinations': act == 'return'
                    ? <String>['estate', 'taxation', 'cmo']
                    : <String>[],
              },
          ]
        : <Map<String, dynamic>>[
            <String, dynamic>{
              'act': 'endorse',
              'allowed': endorseAllowed && !queryOpen,
              'reason': endorseAllowed && !queryOpen ? null : 'query_open',
              'method': 'POST',
              'path': '/api/v1/allotment/intakes/$id/endorse',
              'signed': true,
              'remarks_required': false,
              'destinations': <String>[],
            },
            <String, dynamic>{
              'act': 'return',
              'allowed': true,
              'reason': null,
              'method': 'POST',
              'path': '/api/v1/allotment/intakes/$id/return',
              'signed': false,
              'remarks_required': true,
              'destinations': <String>['estate', 'taxation'],
            },
            <String, dynamic>{
              'act': 'respond',
              'allowed': queryOpen,
              'reason': queryOpen ? null : 'no_open_query',
              'method': 'POST',
              'path': '/api/v1/allotment/intakes/$id/respond',
              'signed': false,
              'remarks_required': false,
              'destinations': <String>[],
            },
          ],
  },
  'media': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': '11',
      'slot': 'applicant_photo',
      'evidence_code': 'APP-PHOTO',
      'mime': 'image/jpeg',
      'is_pdf': false,
      'filename': 'photo.jpg',
      'url': '/api/v1/allotment/intakes/41/media/11',
    },
    <String, dynamic>{
      'id': '12',
      'slot': 'cnic_front',
      'mime': 'image/jpeg',
      'is_pdf': false,
      'filename': 'cnic-front.jpg',
      'url': '/api/v1/allotment/intakes/41/media/12',
    },
    <String, dynamic>{
      'id': '13',
      'slot': 'witness_1_cnic_front',
      'mime': 'image/jpeg',
      'is_pdf': false,
      'filename': 'w1-cnic.jpg',
      'url': '/api/v1/allotment/intakes/41/media/13',
    },
    <String, dynamic>{
      'id': '14',
      'slot': 'witness_1_thumb',
      'mime': 'image/jpeg',
      'is_pdf': false,
      'filename': 'w1-thumb.jpg',
      'url': '/api/v1/allotment/intakes/41/media/14',
    },
    <String, dynamic>{
      'id': '15',
      'slot': 'witness_2_cnic_front',
      'mime': 'image/jpeg',
      'is_pdf': false,
      'filename': 'w2-cnic.jpg',
      'url': '/api/v1/allotment/intakes/41/media/15',
    },
  ],
  'numbered_pdf': null,
  'agreement_pdf': <String, dynamic>{
    'kind': 'draft',
    'available': true,
    'pdf_url': '/api/v1/allotment/intakes/$id/agreement-pdf',
    'download_url': '/api/v1/allotment/intakes/$id/agreement-pdf?download=1',
  },
  'execution': <String, dynamic>{
    'signed_scan': <String, dynamic>{'current': null, 'history': <Object>[]},
    'execution_video': <String, dynamic>{
      'current': <String, dynamic>{'id': '3', 'mime': 'video/mp4', 'url': null},
      'restricted': true,
    },
  },
};

Map<String, dynamic> casesPage({List<Map<String, dynamic>>? rows}) {
  final List<Map<String, dynamic>> data =
      rows ??
      <Map<String, dynamic>>[
        caseData(),
        caseData(id: '42', queryOpen: true)
          ..['intake_no'] = 'CA-2026-0042'
          ..['applicant'] = <String, dynamic>{
            'name': 'Rahim Shah',
            'cnic': '54400-5566778-9',
          },
      ];
  return <String, dynamic>{
    'data': data,
    'meta': <String, dynamic>{
      'current_page': 1,
      'last_page': 1,
      'per_page': 25,
      'total': data.length,
    },
    'links': <String, dynamic>{},
  };
}

/// Answers from the fixtures above, for the previews.
class FakeAgreementRepository implements AgreementRepository {
  FakeAgreementRepository({this.failure, this.empty = false});

  final Object? failure;
  final bool empty;

  @override
  Future<AgreementDashboard> dashboard({
    int? marketId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (failure != null) throw failure!;
    if (empty) {
      return AgreementDashboard.fromJson(<String, dynamic>{
        'waiting': <String, dynamic>{'total': 0, 'queues': <Object>[]},
        'returned_by_me': <String, dynamic>{'count': 0},
        'my_actions': <Object>[],
      });
    }
    return AgreementDashboard.fromJson(dashboardData());
  }

  @override
  Future<Paginated<AgreementCase>> cases(
    IntakeListQuery query, {
    String? search,
    int? marketId,
    int page = 1,
    int perPage = 25,
  }) async {
    if (failure != null) throw failure!;
    final Map<String, dynamic> body = empty
        ? casesPage(rows: <Map<String, dynamic>>[])
        : casesPage();
    return Paginated<AgreementCase>.fromResponse(
      ApiResponse.fromBody(body),
      AgreementCase.fromJson,
    );
  }

  @override
  Future<AgreementCase> caseDetail(String id) async {
    if (failure != null) throw failure!;
    return AgreementCase.fromJson(
      caseData(
        id: id,
        queryOpen: id == '42',
        returned: id == '42',
        admin: id == '43',
      ),
    );
  }

  @override
  Future<AgreementCase> act(
    String caseId,
    IntakeActOption option,
    IntakeDecisionRequest request,
  ) async => AgreementCase.fromJson(
    caseData(id: caseId, status: 'pending_admin', lockVersion: 4),
  );

  /// The stamp paper PDF is a real file, so the Preview tab draws pages;
  /// anything else is not in a preview.
  @override
  Future<ApiDownload> document(String url) async {
    if (url.contains('agreement-pdf')) {
      // Sync: async IO never completes inside a widget test's fake clock.
      return ApiDownload(
        bytes: File('test/assets/agreement_draft.pdf').readAsBytesSync(),
        contentType: 'application/pdf',
      );
    }
    throw const ApiException(
      message: 'Not in a preview.',
      failure: ApiFailure.notFound,
    );
  }
}
