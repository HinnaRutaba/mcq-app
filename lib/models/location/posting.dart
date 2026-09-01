import '../../core/utils/json_reader.dart';
import '../common/api_enum.dart';

/// A posting: the assignment that gives an officer authority over an area.
class Posting {
  const Posting({
    required this.id,
    required this.areaId,
    required this.areaName,
    this.role = ApiEnum.unknown,
    this.fromDate,
    this.toDate,
    this.isActive = true,
  });

  final int id;
  final int areaId;
  final String areaName;
  final ApiEnum role;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isActive;

  factory Posting.fromJson(Map<String, dynamic> json) => Posting(
        id: json.intOr('id'),
        areaId: json.integer('area_id') ?? json.child('area')?.intOr('id') ?? 0,
        areaName:
            json.str('area_name') ?? json.child('area')?.strOr('name') ?? '',
        role: json.apiEnum('role'),
        fromDate: json.date('from_date') ?? json.date('effective_from'),
        toDate: json.date('to_date') ?? json.date('effective_to'),
        isActive: json.boolean('is_active', fallback: true),
      );
}
