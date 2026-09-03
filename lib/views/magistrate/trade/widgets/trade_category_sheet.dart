import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/trade_tariff.dart';
import '../../../../widgets/widgets.dart';

/// The trade picker, grouped as the tariff sends it and priced for this zone.
///
/// Only trades the zone carries a price for are in here — a trade with no fee
/// cannot raise a challan, and offering one would quote a shopkeeper a free
/// licence. When MCQ has left some unpriced the sheet says how many rather
/// than quietly looking short.
class TradeCategorySheet extends StatefulWidget {
  const TradeCategorySheet({
    super.key,
    required this.groups,
    this.unpriced = 0,
    this.selected,
  });

  final List<TradeCategoryGroup> groups;

  /// How many trades this zone has no price for.
  final int unpriced;

  final TradeCategory? selected;

  static Future<TradeCategory?> show(
    BuildContext context, {
    required List<TradeCategoryGroup> groups,
    int unpriced = 0,
    TradeCategory? selected,
  }) {
    return showModalBottomSheet<TradeCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => TradeCategorySheet(
        groups: groups,
        unpriced: unpriced,
        selected: selected,
      ),
    );
  }

  @override
  State<TradeCategorySheet> createState() => _TradeCategorySheetState();
}

class _TradeCategorySheetState extends State<TradeCategorySheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The groups, narrowed by the search box. Ninety-odd trades is more than a
  /// scroll answers, and an officer looking for "tandoor" knows the word.
  List<TradeCategoryGroup> get _shown {
    final String term = _query.trim().toLowerCase();
    if (term.isEmpty) return widget.groups;
    return <TradeCategoryGroup>[
      for (final TradeCategoryGroup group in widget.groups)
        if (group.categories.any((TradeCategory c) => _matches(c, term)))
          TradeCategoryGroup(
            group: group.group,
            categories: group.categories
                .where((TradeCategory c) => _matches(c, term))
                .toList(),
          ),
    ];
  }

  static bool _matches(TradeCategory category, String term) =>
      category.categoryName.toLowerCase().contains(term) ||
      (category.categoryCode?.toLowerCase().contains(term) ?? false) ||
      (category.categoryNameUr?.contains(term) ?? false);

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final List<TradeCategoryGroup> groups = _shown;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppText.titleLarge('What does the shop trade as?'),
                  const SizedBox(height: 4),
                  AppText.caption(
                    widget.unpriced == 0
                        ? 'Priced for this zone by MCQ.'
                        : 'Priced for this zone by MCQ. '
                              '${widget.unpriced} trades are unpriced here and '
                              'cannot be captured.',
                    color: muted,
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    controller: _search,
                    hint: 'Search trades',
                    onChanged: (String term) => setState(() => _query = term),
                  ),
                ],
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No trade matches',
                      message: 'Try a shorter word, or the trade in English.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: <Widget>[
                        for (final TradeCategoryGroup group
                            in groups) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: AppText.label(
                              group.label,
                              color: muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          for (final TradeCategory category in group.categories)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CategoryRow(
                                category: category,
                                chosen: category.id == widget.selected?.id,
                                onTap: () =>
                                    Navigator.of(context).pop(category),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.chosen,
    required this.onTap,
  });

  final TradeCategory category;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final Color primary = Theme.of(context).colorScheme.primary;
    final String? fee = Formatters.money(category.annualFee);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: chosen ? AppTone.primary.container(context) : null,
      borderColor: chosen ? primary : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText.body(
                  category.categoryName,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
                if (category.categoryNameUr != null) ...<Widget>[
                  const SizedBox(height: 2),
                  AppText.caption(
                    category.categoryNameUr!,
                    color: muted,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // The fee as the server quoted it, never multiplied by the term
              // — the server prices the licence when it raises the challan.
              AppText.body(fee ?? '—', fontWeight: FontWeight.w700),
              const SizedBox(height: 2),
              AppText.caption('per year', color: muted),
            ],
          ),
          if (chosen) ...<Widget>[
            const SizedBox(width: 10),
            Icon(Icons.check_circle_rounded, size: 20, color: primary),
          ],
        ],
      ),
    );
  }
}
