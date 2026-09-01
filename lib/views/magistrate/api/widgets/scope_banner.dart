import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/reporting/area_scope.dart';
import '../../../../widgets/widgets.dart';

/// Which areas the figures on this screen cover.
///
/// This is not decoration. A screen of figures that looks city-wide but is
/// not invites a decision made on a fraction of the register — "Jinnah Road
/// and Prince Road" at the top is the whole fix.
class ScopeBanner extends StatelessWidget {
  const ScopeBanner({super.key, required this.scope, this.onLight = false});

  final AreaScope scope;

  /// True when it sits on the dark hero header rather than the page.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final description = scope.describe(
      andWord: t('common.and'),
      allAreasWord: t('today.scopeCity'),
    );
    if (description.isEmpty) return const SizedBox.shrink();

    final color = onLight
        ? Colors.white.withValues(alpha: 0.85)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.place_outlined, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: AppText.caption(description, color: color, maxLines: 2),
        ),
      ],
    );
  }
}
