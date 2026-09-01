import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../models/common/money.dart';
import '../text/app_text.dart';
import '../text/money_text.dart';

/// The one big money figure on a profile, on the surface it deserves.
///
/// A raised, gently graded panel with a coloured rail down its leading
/// edge, the label above and the qualifying facts beneath. It exists so the
/// officer never has to hunt for the number he is about to quote to a
/// shopkeeper who is arguing with him.
///
/// Two rules it enforces on its callers:
///
/// * The amount is a [Money] — a string the server sent. Nothing here
///   parses, adds or rounds one.
/// * [amount] may be **null**, and null is drawn as [absentLabel], never as
///   `0.00`. A vacant unit owes nothing because nobody holds it; a tenant
///   who is up to date owes nothing because he paid. Only one of those is
///   good news and the officer will act differently on each.
class AppMoneyPanel extends StatelessWidget {
  const AppMoneyPanel({
    super.key,
    required this.label,
    required this.amount,
    required this.absentLabel,
    this.tone = AppTone.danger,
    this.facts = const [],
    this.footnote,
    this.trailing,
  });

  final String label;
  final Money? amount;

  /// Shown in place of the figure when [amount] is null — "Vacant", "Never
  /// paid", "No figure recorded".
  final String absentLabel;

  final AppTone tone;

  /// Months behind, days overdue, last payment — the qualifiers under the
  /// figure, so nobody has to do arithmetic.
  final List<Widget> facts;

  final String? footnote;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = tone.on(context);
    final surface =
        Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: dark ? 0.16 : 0.10), surface),
            Color.alphaBlend(accent.withValues(alpha: dark ? 0.05 : 0.02), surface),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: dark ? 0.34 : 0.22)),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x1414231A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(21, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText.label(
                          label,
                          color: accent,
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (amount == null)
                    // Absent is not zero, and it never renders as one.
                    AppText.headlineMedium(absentLabel, color: accent)
                  else
                    MoneyText.headline(amount!, color: accent),
                  if (facts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: facts),
                  ],
                  if (footnote != null) ...[
                    const SizedBox(height: 12),
                    AppText.bodySmall(
                      footnote!,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
