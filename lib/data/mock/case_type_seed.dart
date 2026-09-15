import '../../models/case_type_option.dart';

/// The kinds of case the app offers when the register publishes none.
///
/// `enforcement/definitions` is the source of truth — see
/// `EnforcementDefinitions.caseTypes`, which `EnforcementCaseRepository.
/// caseTypes()` prefers whenever MCQ sends a `case_types` block. These rows
/// stand behind it for a handset that has never reached the definitions
/// endpoint, and carry the same codes the register does, so a case opened
/// offline is filed under the code MCQ would have named.
const List<CaseTypeOption> caseTypeSeed = <CaseTypeOption>[
  CaseTypeOption(
    code: 'arrears_recovery',
    name: 'Arrears recovery',
    description:
        'Rent is owed on the unit and the file is opened to work the debt '
        'through.',
  ),
  CaseTypeOption(
    code: 'unauthorised_use',
    name: 'Unauthorised use',
    description:
        'The shop is being used for something the allotment does not permit — '
        'trading in other goods, or letting somebody else trade there.',
  ),
  CaseTypeOption(
    code: 'subletting',
    name: 'Subletting',
    description:
        'The allottee has let somebody else hold or trade from the unit '
        'without MCQ transferring it to them.',
  ),
  CaseTypeOption(
    code: 'encroachment',
    name: 'Encroachment',
    description:
        'Ground outside the unit has been taken — a display, a stall or a '
        'structure on the footpath or the bazaar’s common space.',
  ),
  CaseTypeOption(
    code: 'illegal_construction',
    name: 'Illegal construction',
    description:
        'The unit has been built on or altered without MCQ’s sanction — a '
        'mezzanine, an extension, a shopfront moved out.',
  ),
  CaseTypeOption(
    code: 'seal_violation',
    name: 'Seal violation',
    description:
        'A seal on the unit has been broken, or the shop has been traded from '
        'while the seal stood.',
  ),
];
