import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';


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
