import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../motion/app_stagger.dart';

/// One event on a timeline.
class AppTimelineEntry {
  const AppTimelineEntry({
    required this.icon,
    required this.child,
    this.tone = AppTone.neutral,
    this.emphasis = false,
  });

  final IconData icon;

  /// The card, tile or block for this event. The timeline draws the rail
  /// and the node; what hangs off it is the caller's.
  final Widget child;

  final AppTone tone;

  /// Draws the node filled — for the event that changed the case.
  final bool emphasis;
}

/// A history, drawn as a timeline rather than as a list of cards.
///
/// A visit log is not a list of unrelated rows: it is a **sequence**, and
/// the officer's question of it is always about order and gaps — "he
/// promised, then what happened", "how long since anybody went". A rail
/// with nodes answers that shape at a glance; a stack of cards makes him
/// reconstruct it from dates.
///
/// The rail runs down the **leading** edge, so it is on the right in Urdu
/// and the sequence still reads from the start of the line. Each node
/// carries the event's own glyph, so a seal, a promise and a warning are
/// distinguishable without reading a word or seeing a colour.
class AppTimeline extends StatelessWidget {
  const AppTimeline({
    super.key,
    required this.entries,
    this.animate = true,
    this.spacing = 14,
  });

  final List<AppTimelineEntry> entries;
  final bool animate;
  final double spacing;

  static const double _nodeSize = 34;
  static const double _gutter = 14;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final rail = Theme.of(context).dividerColor;

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          AppStaggerIn(
            index: i,
            enabled: animate,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _nodeSize,
                    child: Column(
                      children: [
                        _Node(entry: entries[i]),
                        // The connector stops at the last node rather than
                        // trailing off into nothing.
                        if (i < entries.length - 1)
                          Expanded(
                            child: Container(width: 2, color: rail),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: _gutter),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: i < entries.length - 1 ? spacing : 0,
                      ),
                      child: entries[i].child,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.entry});

  final AppTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final colour = entry.tone.on(context);
    final filled = entry.emphasis;

    return Container(
      width: AppTimeline._nodeSize,
      height: AppTimeline._nodeSize,
      decoration: BoxDecoration(
        color: filled ? colour : entry.tone.container(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? colour : colour.withValues(alpha: 0.34),
          width: 1.5,
        ),
      ),
      child: Icon(
        entry.icon,
        size: 17,
        color: filled ? entry.tone.onFilled(context) : colour,
      ),
    );
  }
}
