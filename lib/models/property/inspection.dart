import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';

/// A recorded inspection of a unit. This is the one field write that takes
/// the image directly on the request, as `multipart/form-data` with an
/// optional `photo` part — not the two-step evidence flow.
class Inspection {
  const Inspection({
    required this.id,
    required this.inspectionType,
    required this.status,
    this.findings,
    this.inspectedOn,
    this.hasPhoto = false,
    this.propertyId,
    this.inspectedBy,
  });

  final int id;
  final ApiEnum inspectionType;
  final ApiEnum status;
  final String? findings;
  final DateTime? inspectedOn;
  final bool hasPhoto;
  final int? propertyId;
  final String? inspectedBy;

  factory Inspection.fromJson(Map<String, dynamic> json) => Inspection(
        id: json.intOr('id'),
        inspectionType: json.apiEnum('inspection_type'),
        status: json.apiEnum('status'),
        findings: json.str('findings'),
        inspectedOn: json.date('inspected_on') ?? json.date('created_at'),
        hasPhoto: json.boolean('has_photo') || json.str('photo_path') != null,
        propertyId: json.integer('property_id'),
        inspectedBy: json.child('inspected_by')?.str('name'),
      );
}
