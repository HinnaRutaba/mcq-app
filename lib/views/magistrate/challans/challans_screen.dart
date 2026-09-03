import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';

/// Challans — what the shopkeeper actually pays, listed in one place rather
/// than found a shop at a time through a profile.
///
/// Empty for now. The list behind it is [ChallanRepository.challans], which is
/// paged and mixes rent challans with fines; the screen will have to keep the
/// two apart rather than totalling them.
class ChallansScreen extends StatelessWidget {
  const ChallansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Challans', leading: BackToHomeButton()),
          Expanded(
            child: AppEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Not wired up yet',
              message:
                  'The challan list comes from the billing endpoint, paged, '
                  'with rent challans and fines kept apart.',
            ),
          ),
        ],
      ),
    );
  }
}
