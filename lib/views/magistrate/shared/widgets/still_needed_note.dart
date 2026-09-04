import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../widgets/widgets.dart';

/// What a form is still short of, in the order it asks for it.
///
/// The whole list, never an "and 3 more": a disabled button an officer cannot
/// explain is the thing they give up on, and the shortened version sent them
/// scrolling the form to find out which field was empty.
class StillNeededNote extends StatelessWidget {
  const StillNeededNote({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppTone.warning.on(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTone.warning.container(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 16, color: ink),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.caption(
              'Still needed: ${missing.join(', ')}',
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
