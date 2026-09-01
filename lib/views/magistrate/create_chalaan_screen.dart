import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Imposing a fine — emptied while the app moves onto the MCQ Magistrate API.
///
/// `FineRepository.impose()` does the lot in one transaction: it posts the
/// receivable, raises a payable challan, issues a payment link and texts the
/// person fined. Three things this form has to get right when it is built:
///
/// * Photograph first. Upload through `EvidenceRepository.upload()` and send
///   the returned path, so on a weak signal the image goes up once and the
///   fine can be retried without it.
/// * Hold on to the `FineRequest` instance for retries. Its
///   `client_action_uuid` is what makes a resend the same fine instead of a
///   second one.
/// * Set `FineRequest.offender` when the unit's `needsOffenderDetails` is
///   true — name, father's name and mobile are required together. Pass
///   `FineRequest.seal` to seal the shop in the same request, and remember the
///   fine stands even if that seal is refused.
class CreateChalaanScreen extends StatelessWidget {
  const CreateChalaanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Impose a Fine')),
      body: const AppEmptyState(
        icon: Icons.gavel_rounded,
        title: 'Not wired up yet',
        message: 'The fine form posts to the enforcement fines endpoint.',
      ),
    );
  }
}
