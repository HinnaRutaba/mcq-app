import '../../models/case_type_option.dart';

/// The kinds of case the app offers until MCQ publishes them.
///
/// `enforcement/field/cases` takes `case_type` as a free code, and there is no
/// endpoint listing them yet — so this stands in behind
/// `EnforcementCaseRepository.caseTypes()` and is the only place to edit when
/// one arrives.
const List<CaseTypeOption> caseTypeSeed = <CaseTypeOption>[
  CaseTypeOption(
    code: 'unauthorised_use',
    name: 'Unauthorised use',
    description:
        'The shop is being used for something the allotment does not permit — '
        'trading in other goods, or letting somebody else trade there.',
  ),
];
