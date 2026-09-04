import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/network/api_exception.dart';
import '../data/repositories/person_repository.dart';
import '../models/person_lookup.dart';

/// The CNIC search: the field an officer types thirteen digits into, and
/// whoever `enforcement/field/person` holds for them.
///
/// Its own controller because more than one form has to name a person — a
/// fine, a case opened on somebody with no unit, a licence applied for at a
/// counter. Each host owns an instance, drops [PersonCnicField] into its form
/// and does what it likes with the answer.
///
/// **The answer is offered, never applied.** MCQ has no single person
/// register: four of them answer separately and the server does not merge
/// them, so the person in front of the officer may not be the person on
/// record. [take] is the officer saying it is.
class PersonLookupController extends GetxController {
  PersonLookupController({PersonRepository? personRepository})
    : _override = personRepository;

  final PersonRepository? _override;

  /// Resolved on the first search, not on construction: a form that carries
  /// this field is not a form that always uses it.
  late final PersonRepository _people =
      _override ?? Get.find<PersonRepository>();

  /// A CNIC is thirteen digits. Nothing goes on the wire until they are all
  /// there — a lookup per keystroke is thirteen calls over a bazaar's uplink
  /// to answer one question.
  static const int length = 13;

  final TextEditingController cnicController = TextEditingController();

  final Rxn<PersonLookup> person = Rxn<PersonLookup>();
  final RxBool isLoading = RxBool(false);

  /// The digits typed so far. Observable because the field has to say what it
  /// is waiting for: a search that fires on the thirteenth digit and says
  /// nothing before it looks like a field that does not work.
  final RxString typed = RxString('');

  /// Whether the officer has taken the suggestion. The card gives way to the
  /// fields it filled in.
  final RxBool isTaken = RxBool(false);

  /// Only the digits, whatever the officer typed between them.
  static String digitsOf(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  String get cnic => digitsOf(cnicController.text);

  /// Whether a whole CNIC has been typed — the point at which anything is
  /// asked of the server.
  bool get isComplete => typed.value.length == length;

  /// How many digits are still to come. Zero once there are enough.
  int get digitsLeft => (length - typed.value.length).clamp(0, length);

  /// The server answered and nobody holds this CNIC. Not an error: it is a
  /// hawker nobody has written up before, and the form collects every field
  /// by hand.
  bool get isUnknown {
    final PersonLookup? found = person.value;
    return found != null && found.suggested == null;
  }

  /// What to offer under the field, or null when there is nothing to offer —
  /// no answer yet, nobody on record, or it has been taken already.
  PersonLookup? get onOffer {
    final PersonLookup? found = person.value;
    if (found == null || isTaken.value || found.suggested == null) return null;
    return found;
  }

  /// Searched as the officer types. A CNIC short of [length] digits is not a
  /// search, and a changed one throws the last answer away: it was about
  /// somebody else.
  Future<void> search(String value) async {
    final String searched = digitsOf(value);
    typed.value = searched;
    person.value = null;
    isTaken.value = false;
    if (searched.length != length) return;

    isLoading.value = true;
    try {
      final PersonLookup found = await _people.byCnic(searched);
      // Only if the officer has not typed on since: a slow answer to an old
      // CNIC must not land under a new one.
      if (cnic == searched) person.value = found;
    } on ApiException {
      // The officer types the details themselves. A lookup that would not go
      // through is not a reason to stop the form it sits on.
      person.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// The officer took the suggestion. What is done with it is the host's
  /// business — this only stops it being offered again.
  void take() => isTaken.value = true;

  /// Back to an empty field with nothing offered.
  void reset() {
    cnicController.clear();
    typed.value = '';
    person.value = null;
    isTaken.value = false;
  }

  @override
  void onClose() {
    cnicController.dispose();
    super.onClose();
  }
}
