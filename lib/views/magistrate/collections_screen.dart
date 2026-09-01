import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';

/// The collection round — emptied while the app moves onto the MCQ Magistrate
/// API.
///
/// Two lists feed this screen, both on `DefaultersRepository`: `defaulters()`
/// for everyone behind on rent, worst first, and `round()` for the same people
/// grouped by bazaar with broken promises first — a walking order rather than a
/// list. Everything needed to decide sits on the card already, so a row never
/// costs a second call.
///
/// Amounts arrive as strings and stay strings. Never total two of them in Dart.
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          AppHeroHeader(title: 'Collections'),
          Expanded(
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Not wired up yet',
              message:
                  'Defaulters and today’s round come from the field '
                  'defaulters endpoints.',
            ),
          ),
        ],
      ),
    );
  }
}
