import 'package:get/get.dart';

import '../../core/network/api_constants.dart';
import '../../models/enforcement/fine.dart';
import '../../models/offline/queued_write.dart';
import '../../models/property/property_summary.dart';
import 'field_write_controller.dart';

/// Imposing a fine.
///
/// A fine produces a payable challan with its own payment link, and the
/// person fined gets an SMS with that link — that is the whole point: the
/// officer wants the money paid so the shutter can be unsealed.
///
/// Two cases, and both are handled:
///
/// * **The unit has a live agreement.** The server finds the holder and
///   bills them; `allotment_id` is not computed here, and the offender
///   fields are refused as unnecessary.
/// * **Nobody holds the unit** — a hawker over-pricing, an encroachment on
///   a footpath, a shutter between tenancies. The offender's name and
///   mobile number are then required, and the SMS with the payment link
///   goes to the number the officer types. Get that field wrong and the
///   fine is unrecoverable, so the number is validated properly.
class FineFormController extends FieldWriteController {
  FineFormController({
    required this.property,
    required super.enforcement,
    required super.photos,
    required super.location,
    required super.queue,
    this.needsOffenderOverride,
  });

  factory FineFormController.resolve(
    PropertySummary property, {
    bool? needsOffenderOverride,
  }) =>
      FineFormController(
        property: property,
        needsOffenderOverride: needsOffenderOverride,
        enforcement: Get.find(),
        photos: Get.find(),
        location: Get.find(),
        queue: Get.find(),
      );

  final PropertySummary property;

  /// The server's `needs_offender_details` flag, when the officer arrived
  /// from a field card that carried one.
  ///
  /// **Trust the flag over anything worked out on the handset.** A database
  /// constraint refuses a fine that names nobody, and the server knows
  /// about tenancy changes this app has not seen yet.
  final bool? needsOffenderOverride;

  final RxString fineType = ''.obs;

  /// The amount exactly as typed. Kept as a string the whole way to the
  /// server: no `double.parse`, no `toStringAsFixed`.
  final RxString amount = ''.obs;

  final RxString legalProvision = ''.obs;
  final RxString offenderName = ''.obs;
  final RxString offenderMobile = ''.obs;

  /// Optional. Worth having where the officer can get it — a CNIC is what
  /// turns a name into a person the corporation can pursue.
  final RxString offenderCnic = ''.obs;

  final Rx<FineOutcome?> outcome = Rx<FineOutcome?>(null);

  /// The form asks for the offender the moment the unit turns out to be
  /// unheld, with a line saying why — otherwise the officer thinks the form
  /// is broken.
  bool get needsOffenderDetails =>
      needsOffenderOverride ?? !property.hasLiveAllotment;

  /// `03009876543` — 11 digits starting 03. The payment link is
  /// unrecoverable if this is wrong.
  static final RegExp mobilePattern = RegExp(r'^03\d{9}$');

  String? validateAmount(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'fines.amountRequired';
    // A shape check on the string, not a parse: the server does the
    // arithmetic and holds the decimal.
    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(raw)) {
      return 'fines.amountFormat';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (!needsOffenderDetails) return null;
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'fines.offenderMobileRequired';
    if (!mobilePattern.hasMatch(raw)) return 'fines.offenderMobileFormat';
    return null;
  }

  bool get isValid {
    if (fineType.value.isEmpty) return false;
    if (validateAmount(amount.value) != null) return false;
    if (legalProvision.value.trim().isEmpty) return false;
    if (needsOffenderDetails) {
      if (offenderName.value.trim().isEmpty) return false;
      if (validateMobile(offenderMobile.value) != null) return false;
    }
    return true;
  }

  Map<String, dynamic> _body({required bool offline}) => {
        'fine_type': fineType.value,
        'fine_amount': amount.value.trim(),
        'legal_provision': legalProvision.value.trim(),
        if (needsOffenderDetails) 'offender_name': offenderName.value.trim(),
        if (needsOffenderDetails)
          'offender_mobile_no': offenderMobile.value.trim(),
        if (needsOffenderDetails && offenderCnic.value.trim().isNotEmpty)
          'offender_cnic': offenderCnic.value.trim(),
        ...buildEvidence(recordedOffline: offline).toJson(),
      };

  Future<FieldWriteResult> submit() => runWrite(
        successKey: 'fines.imposed',
        send: () async {
          final result = await enforcementRepository.imposeFine(
            propertyId: property.id,
            fineType: fineType.value,
            fineAmount: amount.value.trim(),
            legalProvision: legalProvision.value.trim(),
            offenderName:
                needsOffenderDetails ? offenderName.value.trim() : null,
            offenderMobileNo:
                needsOffenderDetails ? offenderMobile.value.trim() : null,
            offenderCnic:
                needsOffenderDetails ? offenderCnic.value.trim() : null,
            evidence: buildEvidence(),
          );
          outcome.value = result;
          return result.wasCreated;
        },
        queueItem: () => QueuedWrite(
          clientActionUuid: clientActionUuid,
          kind: QueuedWriteKind.fine,
          path: ApiConstants.propertyFines(property.id),
          body: _body(offline: true),
          recordedAt: DateTime.now(),
          shopLabel: property.label,
          allotteeLabel: needsOffenderDetails
              ? offenderName.value.trim()
              : property.allottee.name,
          localPhotoPath: photo.value?.path,
          localSignaturePath: signature.value?.path,
          propertyId: property.id,
        ),
      );
}
