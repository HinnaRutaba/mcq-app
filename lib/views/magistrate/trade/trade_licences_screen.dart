import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';

/// Trade licences — the second register an officer works in the same bazaar,
/// and a separate one from enforcement: a licence is permission to trade, not
/// a debt.
///
/// Empty for now. The screen behind it is `/api/v1/trade/field/beat`, already
/// modelled in [ApiTradeRepository] — the bazaars in scope and the three
/// queues (expiring, lapsed, live), none of them carrying money.
class TradeLicencesScreen extends StatelessWidget {
  const TradeLicencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Trade Licences', leading: BackToHomeButton()),
          Expanded(
            child: AppEmptyState(
              icon: Icons.badge_rounded,
              title: 'Not wired up yet',
              message:
                  'The licence queues come from the trade field beat — '
                  'expiring, lapsed and live, scoped to the bazaars on '
                  'the officer’s beat.',
            ),
          ),
        ],
      ),
    );
  }
}
