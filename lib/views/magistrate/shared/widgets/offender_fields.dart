import 'package:flutter/material.dart';

import '../../../../controllers/person_lookup_controller.dart';
import '../../../../models/person_lookup.dart';
import '../../../../widgets/widgets.dart';
import 'person_cnic_field.dart';

/// The person a field write names, asked for by hand: the CNIC to look them
/// up by, and the three fields the server insists on together.
///
/// Shared by the fine, which bills them, and the case, which is opened
/// against them — both post the same `offender_*` block.
class OffenderFields extends StatelessWidget {
  const OffenderFields({
    super.key,
    required this.lookup,
    required this.nameController,
    required this.fatherController,
    required this.mobileController,
    required this.onTaken,
    required this.onChanged,
    this.validateCnic,
    this.validateName,
    this.validateFather,
    this.validateMobile,
  });

  /// The CNIC search, which owns its own field.
  final PersonLookupController lookup;

  final TextEditingController nameController;
  final TextEditingController fatherController;
  final TextEditingController mobileController;

  /// The officer took whoever the search offered.
  final void Function(PersonSuggestion suggestion, PersonLookup person) onTaken;

  /// Any keystroke on any of the four, for a form that has to know it changed.
  final VoidCallback onChanged;

  final String? Function(String?)? validateCnic;
  final String? Function(String?)? validateName;
  final String? Function(String?)? validateFather;
  final String? Function(String?)? validateMobile;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          PersonCnicField(
            controller: lookup,
            label: "Offender's CNIC",
            hint: 'e.g. 5440011223344',
            validator: validateCnic,
            onChanged: (_) => onChanged(),
            onTaken: onTaken,
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: "Offender's name",
            controller: nameController,
            validator: validateName,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: "Father's name",
            controller: fatherController,
            validator: validateFather,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Mobile number',
            controller: mobileController,
            keyboardType: TextInputType.phone,
            validator: validateMobile,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
