import 'package:flutter/material.dart';

import '../buttons/app_button.dart';
import '../text/app_text.dart';

/// The bottom of a paged list: the next page on its way, an offer to fetch it,
/// or the end said out loud.
class AppListFooter extends StatelessWidget {
  const AppListFooter({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    this.total,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  /// What the server says the whole list holds. Null until the first page has
  /// landed, and then said at the end so the officer knows what they read.
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    // Scrolling fetches the next page on its own; this is for the thumb that
    // stops at the gap, and it is what a test can press.
    if (hasMore) {
      return Center(
        child: AppButton(
          label: 'Load more',
          icon: Icons.expand_more_rounded,
          variant: AppButtonVariant.outline,
          fullWidth: false,
          onPressed: onLoadMore,
        ),
      );
    }

    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Center(
      child: AppText.caption(
        total == null ? 'End of the list' : 'End of the list · $total in all',
        color: muted,
      ),
    );
  }
}
