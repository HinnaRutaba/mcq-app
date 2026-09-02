import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../../../config/theme/app_radius.dart';

/// One of the three pieces of evidence a fine can carry — the photograph, the
/// GPS fix, the witness signature — drawn as a square in a row of three.
///
/// The three used to be full-width buttons stacked down the form, which put the
/// submit button off the bottom of the screen. Side by side they are one glance
/// instead of three, and the officer can see at a distance which of them is
/// still missing.
///
/// State is never carried by colour alone: every tile shows an icon, a word and
/// a tick or a dash, because a magistrate may be colour-blind and is certainly
/// standing in the sun.
class EvidenceTile extends StatelessWidget {
  const EvidenceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.state,
    required this.onTap,
    this.detail,
    this.busy = false,
  });

  final IconData icon;

  /// One word: "Photo", "Location", "Signature".
  final String label;

  final EvidenceState state;

  /// The line under the label — "5 m", "Uploading", "Not attached".
  final String? detail;

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = state.tone;
    final Color accent = state == EvidenceState.empty
        ? (theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55) ??
              theme.colorScheme.outline)
        : tone.on(context);

    return AppCard(
      onTap: busy ? null : onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 34,
            width: 34,
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(7),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accent,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 18, color: accent),
                  ),
          ),
          const SizedBox(height: 8),
          AppText.caption(
            label,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(state.mark, size: 12, color: accent),
              const SizedBox(width: 3),
              Flexible(
                child: AppText.caption(
                  detail ?? state.word,
                  color: accent,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where one piece of evidence stands.
enum EvidenceState {
  /// Nothing attached. Not an error — a fine with no photograph is still a
  /// fine, and the form never blocks on one.
  empty,

  /// Held on the handset but not yet on the server. The fine must not be sent
  /// claiming evidence the server does not have.
  pending,

  /// Uploaded, and its path is on the request.
  attached,

  /// The officer refused it, or the handset could not manage it.
  unavailable;

  AppTone get tone => switch (this) {
    EvidenceState.attached => AppTone.success,
    EvidenceState.pending => AppTone.warning,
    EvidenceState.unavailable => AppTone.danger,
    EvidenceState.empty => AppTone.neutral,
  };

  IconData get mark => switch (this) {
    EvidenceState.attached => Icons.check_rounded,
    EvidenceState.pending => Icons.arrow_upward_rounded,
    EvidenceState.unavailable => Icons.close_rounded,
    EvidenceState.empty => Icons.remove_rounded,
  };

  String get word => switch (this) {
    EvidenceState.attached => 'Attached',
    EvidenceState.pending => 'Sending',
    EvidenceState.unavailable => 'None',
    EvidenceState.empty => 'Add',
  };
}
