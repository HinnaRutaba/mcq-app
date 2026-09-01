import '../../core/utils/json_reader.dart';

/// The `scope` block that rides on every scoped list response.
///
/// A magistrate is posted to specific areas and the restriction lives
/// inside a database view (`vw_magistrate_defaulters`), so no request can
/// widen it — but the app must *display* the fact, or an officer will read
/// a screen of figures as city-wide when it is a fraction of the register.
/// Never build a client-side area filter as if it were the control; it is
/// a convenience on top of a server control.
class AreaScope {
  const AreaScope({
    required this.restricted,
    required this.areaIds,
    required this.areaNames,
  });

  final bool restricted;
  final List<int> areaIds;
  final List<String> areaNames;

  static const AreaScope unknown =
      AreaScope(restricted: true, areaIds: [], areaNames: []);

  factory AreaScope.fromJson(Map<String, dynamic>? json) {
    if (json == null) return unknown;
    return AreaScope(
      restricted: json.boolean('restricted', fallback: true),
      areaIds: json.integers('area_ids'),
      areaNames: json.strings('area_names'),
    );
  }

  /// An officer with no posting sees nothing, correctly. That is not a bug
  /// in the app — say so on screen rather than showing an empty list.
  bool get hasPosting => areaNames.isNotEmpty;

  /// "Jinnah Road and Prince Road" — the whole fix for a figure that looks
  /// city-wide.
  String describe({required String andWord, required String allAreasWord}) {
    if (!restricted) return allAreasWord;
    if (areaNames.isEmpty) return '';
    if (areaNames.length == 1) return areaNames.single;
    final head = areaNames.sublist(0, areaNames.length - 1).join(', ');
    return '$head $andWord ${areaNames.last}';
  }
}
