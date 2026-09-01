import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Sealed shops and the unseal queue — emptied while the app moves onto the
/// MCQ Magistrate API.
///
/// One list read two ways, both on `FieldSealRepository.seals()`: everything
/// the officer has sealed, and — with `readyOnly: true` — the ones the server
/// considers settled. Gate the release button on the server's own
/// `readyToRelease` and nothing else; lifting a seal it has not cleared needs
/// an override reason, which is the record of why a shop that still owes money
/// was opened.
class SealedScreen extends StatelessWidget {
  const SealedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Sealed Shops'),
          Expanded(
            child: AppEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Not wired up yet',
              message:
                  'Sealed shops and the unseal queue come from the field seals '
                  'endpoint.',
            ),
          ),
        ],
      ),
    );
  }
}
