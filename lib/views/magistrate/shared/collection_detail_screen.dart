import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

/// The shopkeeper profile — emptied while the app moves onto the MCQ
/// Magistrate API.
///
/// Opened from a card, so build the header from the card already in hand and
/// let `ReportingRepository.propertyProfile()` fill in the rest: holder, money
/// position, seal and open cases. `EnforcementCaseRepository.actions()` draws
/// the visit timeline below it.
///
/// A fine is a separate debt from the rent. One person can hold a live rent
/// link and a live fine link at once; show them apart and never add them
/// together.
class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.recordId});

  /// The record this screen will load once it is wired up. Comes straight off
  /// the route (`/magistrate/collections/:id`).
  final String recordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppText.titleLarge('Details')),
      body: const AppEmptyState(
        icon: Icons.storefront_outlined,
        title: 'Not wired up yet',
        message:
            'The unit profile and its visit timeline come from the reporting '
            'and enforcement case endpoints.',
      ),
    );
  }
}
