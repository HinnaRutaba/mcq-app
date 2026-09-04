import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../controllers/person_lookup_controller.dart';
import '../../../../models/person_lookup.dart';
import '../../../../widgets/widgets.dart';
import 'person_suggestion_card.dart';

class PersonCnicField extends StatelessWidget {
  const PersonCnicField({
    super.key,
    required this.controller,
    required this.onTaken,
    this.onChanged,
    this.validator,
    this.label = 'CNIC',
    this.hint = 'e.g. 5440011223344',
  });

  final PersonLookupController controller;

  /// The officer took the suggestion. The host fills its own fields in from
  /// it — and [PersonLookup] is passed too, because how many fines are already
  /// on the CNIC is often the point of having looked.
  final void Function(PersonSuggestion suggestion, PersonLookup person) onTaken;

  /// Every keystroke, for a host that has to know the form changed.
  final ValueChanged<String>? onChanged;

  final String? Function(String?)? validator;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppTextField(
          label: label,
          hint: hint,
          controller: controller.cnicController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(PersonLookupController.length),
          ],
          validator: validator,
          onChanged: (String value) {
            controller.search(value);
            onChanged?.call(value);
          },
        ),
        // Everything the search has to say for itself. A field that answers
        // only on the thirteenth digit, and says nothing at all before it,
        // reads as a field that does not work.
        Obx(() {
          if (controller.isLoading.value) {
            return const _Line('Looking this CNIC up…');
          }

          final PersonLookup? found = controller.onOffer;
          if (found != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PersonSuggestionCard(
                person: found,
                onTake: () {
                  controller.take();
                  onTaken(found.suggested!, found);
                },
              ),
            );
          }

          if (controller.isUnknown && !controller.isTaken.value) {
            return const _Line(
              'No record for this CNIC. Fill the details in below.',
            );
          }

          final int left = controller.digitsLeft;
          if (controller.typed.value.isNotEmpty && left > 0) {
            return _Line(
              left == 1
                  ? '1 more digit and the register is searched'
                  : '$left more digits and the register is searched',
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

/// One muted line under the field, for what the search is doing.
class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppText.caption(text, color: muted),
    );
  }
}
