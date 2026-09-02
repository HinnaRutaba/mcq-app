import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';
import '../shared/widgets/back_to_home_button.dart';

/// Everyone behind on rent, worst first — emptied while the app moves onto the
/// MCQ Magistrate API.
///
/// One call fills this screen: `field/defaulters` returns the card already
/// complete, so a row never costs a second request. The sister screen is
/// [RoundScreen], which reads the same people back in walking order; this one
/// is the ranked list an officer scans when they are deciding where to go
/// rather than following a route.
///
/// `FieldCardTile` draws these rows when it lands — `field/defaulters`,
/// `field/units` and the round's `stops` return the same shape on purpose, so
/// there is one card widget and not three.
///
/// Amounts arrive as strings and stay strings. Never total two of them in
/// Dart, and keep `outstanding: null` apart from `0` all the way to the widget
/// — a vacant unit reads "Vacant", never "0.00".
class DefaultersScreen extends StatelessWidget {
  const DefaultersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Defaulters', leading: BackToHomeButton()),
          Expanded(
            child: AppEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Not wired up yet',
              message:
                  'Everyone behind on rent comes from the field defaulters '
                  'endpoint, worst first.',
            ),
          ),
        ],
      ),
    );
  }
}
