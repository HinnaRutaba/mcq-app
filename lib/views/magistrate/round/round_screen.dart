import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';

/// Today's walk — emptied while the app moves onto the MCQ Magistrate API.
///
/// The same people [DefaultersScreen] ranks, read back as an order to walk in:
/// grouped by bazaar, broken promises first, so the officer follows the screen
/// down the row of shops instead of criss-crossing the beat. The round's
/// `stops` come back on the one call with everything already on the card.
///
/// A stop with `amount: null` is not measured in money and shows no figure —
/// it is a visit that is owed, not a debt.
class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Today’s Round', leading: BackToHomeButton()),
          Expanded(
            child: AppEmptyState(
              icon: Icons.directions_walk_rounded,
              title: 'Not wired up yet',
              message:
                  'The walking order comes from the field round endpoint, '
                  'grouped by bazaar with broken promises first.',
            ),
          ),
        ],
      ),
    );
  }
}
