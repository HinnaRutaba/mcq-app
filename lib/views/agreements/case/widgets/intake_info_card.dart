import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../widgets/widgets.dart';

/// A titled block of a case — the shop, the applicant, a witness.
class IntakeInfoCard extends StatelessWidget {
  const IntakeInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IntakeIconPlate(icon: icon),
              const SizedBox(width: 10),
              Expanded(child: AppText.titleMedium(title, maxLines: 1)),
              ?trailing,
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// A glyph on a soft brand tint, beside a card or group heading.
class IntakeIconPlate extends StatelessWidget {
  const IntakeIconPlate({
    super.key,
    required this.icon,
    this.size = 34,
    this.tone,
  });

  final IconData icon;
  final double size;

  /// Null draws in the brand colour.
  final AppTone? tone;

  @override
  Widget build(BuildContext context) {
    final Color ink =
        tone?.on(context) ?? Theme.of(context).colorScheme.primary;
    final Color fill = tone?.container(context) ?? ink.withValues(alpha: 0.12);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: size * 0.52, color: ink),
    );
  }
}

/// A fact with its label, for the fields a reviewer reads one by one.
class IntakeFact extends StatelessWidget {
  const IntakeFact({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 2, child: AppText.caption(label, color: muted)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: AppText.body(
              value,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.end,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  /// Only the facts the server sent; a row reading "—" is noise.
  static List<Widget> of(Map<String, String?> facts) => <Widget>[
    for (final MapEntry<String, String?> fact in facts.entries)
      if (fact.value != null) IntakeFact(label: fact.key, value: fact.value!),
  ];
}
