import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// Home — emptied while the app moves onto the MCQ Magistrate API.
///
/// One call draws this whole screen: `GET /enforcement/field/beat` returns the
/// officer, the bazaars they are posted to and six work queues. Wire it through
/// a controller over `DashboardRepository`, and put `scope.areaNames` on the
/// screen: the figures cover those bazaars only, and a reader who cannot see
/// which ones will take them for city-wide totals.
///
/// Each queue carries the `endpoint` that opens it — route from the payload
/// (`ApiPaths.resolve`) rather than matching a queue's `key` against a path.
class MagistrateHomeScreen extends StatelessWidget {
  const MagistrateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Home'),
          Expanded(
            child: AppEmptyState(
              icon: Icons.dashboard_outlined,
              title: 'Not wired up yet',
              message:
                  'The beat, the posted bazaars and the work queues come from '
                  'the field beat endpoint.',
            ),
          ),
        ],
      ),
    );
  }
}
