import 'package:flutter/material.dart';

import '../../../../config/theme/app_brand.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/field_beat.dart';
import '../../../../widgets/widgets.dart';

/// One queue on Home's grid: how much work of one kind is waiting.
///
/// Built as a plate rather than as a bordered box — a tinted gradient, a
/// curved wash clipped across the foot of it, and a shadow. The tone still
/// comes from the server and still means what it always meant; what changed is
/// that the tile now has a surface for the tone to sit on.
class BeatQueueTile extends StatelessWidget {
  const BeatQueueTile({super.key, required this.queue, this.onTap});

  final FieldQueue queue;
  final VoidCallback? onTap;

  static const double extent = 88;

  @override
  Widget build(BuildContext context) {
    final tone = AppToneColors.fromApi(queue.tone);
    // A queue with nothing in it is not a danger, whatever the server toned
    // it — nought defaulters is the good day.
    final shown = queue.isEmpty ? AppTone.neutral : tone;
    final amount = Formatters.money(queue.amount);
    final ink = shown.on(context);
    final toned = shown != AppTone.neutral;

    // A neutral queue sits on the card surface, not on the scheme's highest
    // container — that step is the page's own colour, and six tiles the colour
    // of the page behind them is what a shadow alone cannot rescue.
    final plate = toned
        ? shown.container(context)
        : Theme.of(context).colorScheme.surface;
    // The wash the sweep is clipped out of. The tone's own ink where there is
    // a tone; the brand on a neutral tile, because neutral ink is a mid-grey
    // and a grey band across a white plate reads as a smudge rather than as
    // light falling on it.
    final wash = toned
        ? ink.withValues(alpha: 0.08)
        : context.brand.primary.withValues(alpha: 0.055);
    final corner = BorderRadius.circular(AppRadius.lg);

    return AppPress(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: corner,
          boxShadow: AppShadows.soft(context),
        ),
        child: ClipRRect(
          borderRadius: corner,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(plate, Colors.white, 0.10)!,
                  Color.lerp(plate, ink, 0.09)!,
                ],
              ),
              border: Border.all(color: ink.withValues(alpha: 0.16)),
              borderRadius: corner,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // The light falling across the foot of the tile. Clipped on a
                // curve, so six of these in a grid read as six surfaces rather
                // than six rectangles.
                ClipPath(
                  clipper: const AppSweepClipper(
                    begin: 0.74,
                    end: 0.40,
                    bow: 0.16,
                  ),
                  child: ColoredBox(color: wash),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: _body(
                    context,
                    ink: ink,
                    toned: toned,
                    shown: shown,
                    amount: amount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required Color ink,
    required bool toned,
    required AppTone shown,
    required String? amount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The mark and the figure share a line: the figure is what the tile is
        // for, and stacking the two only bought the grid an inch of nothing.
        Row(
          children: <Widget>[
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                // Filled for a real tone; a deeper wash of the same grey for
                // neutral, which filled would be light-on-black in dark mode
                // and make the empty queues the loudest thing on the grid.
                color: toned ? ink : ink.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _icon(queue.key),
                size: 13,
                color: toned ? shown.onFilled(context) : ink,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: AppCountUp.count(
                queue.count,
                variant: AppTextVariant.headlineMedium,
                // Default ink on a neutral plate: a faint grey wash is not
                // enough contrast to also drop the count to secondary.
                color: toned ? ink : null,
              ),
            ),
            const Spacer(),
            // Only where the tile goes somewhere — see [QueueDestination].
            if (onTap != null)
              Icon(
                Icons.arrow_outward_rounded,
                size: 12,
                color: ink.withValues(alpha: 0.45),
              ),
          ],
        ),
        const Spacer(),
        Flexible(
          child: AppText.caption(
            _label(queue.key),
            color: toned ? ink : null,
            fontWeight: FontWeight.w600,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 2),
        // A blank line where there is no money — a hard space, because an
        // empty string lays out at no height at all. Every tile is then built
        // the same, and the six labels sit on one line.
        AppText.caption(
          amount ?? '\u00A0',
          color: toned ? ink : null,
          fontWeight: FontWeight.w700,
          maxLines: 1,
        ),
      ],
    );
  }

  static IconData _icon(String key) => switch (key) {
    'defaulters' => Icons.person_off_outlined,
    'follow_ups_due' => Icons.event_repeat_outlined,
    'awaiting_unseal' => Icons.lock_open_outlined,
    'sealed_shops' => Icons.lock_outline_rounded,
    'open_cases' => Icons.folder_open_outlined,
    'assigned_to_me' => Icons.assignment_ind_outlined,
    _ => Icons.list_alt_outlined,
  };

  static String _label(String key) => switch (key) {
    'defaulters' => 'Defaulters',
    'follow_ups_due' => 'Follow-ups due',
    'awaiting_unseal' => 'Awaiting unseal',
    'sealed_shops' => 'Sealed shops',
    'open_cases' => 'Open cases',
    'assigned_to_me' => 'Assigned to me',
    _ => humanise(key),
  };

  /// `follow_ups_due` -> `Follow ups due`. For a queue the server added after
  /// this build shipped.
  static String humanise(String key) {
    if (key.isEmpty) return 'Queue';
    final words = key.replaceAll('_', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }
}
