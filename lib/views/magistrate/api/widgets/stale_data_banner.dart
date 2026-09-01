import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/widgets.dart';

/// The stamp on data that came from the cache.
///
/// A magistrate reading this morning's defaulter list in a basement is
/// useful; a spinner is not. But a cached figure must never look live, so
/// this says when it was fetched, every time.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, required this.fetchedAt, this.onRetry});

  final DateTime fetchedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      icon: Icons.cloud_off_rounded,
      tone: AppStatusTone.warning,
      message: t(
        'common.offlineCached',
        args: {'time': Formatters.stamp(fetchedAt)},
      ),
      action: onRetry == null
          ? null
          : AppButton(
              label: t('common.retry'),
              variant: AppButtonVariant.outline,
              fullWidth: false,
              height: 44,
              onPressed: onRetry,
            ),
    );
  }
}
