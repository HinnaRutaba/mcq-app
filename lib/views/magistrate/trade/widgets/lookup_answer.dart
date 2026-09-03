import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../models/trade_licence.dart';
import '../../../../widgets/widgets.dart';

/// The answer to the doorway question: may this shop trade?
///
/// Three answers, not two. Found-and-live is a shop to leave alone;
/// found-and-lapsed is a renewal the shopkeeper already owes; never-licensed is
/// a capture. Read from `has_valid_licence` and `found`, which is the server's
/// judgement — never from a date comparison here.
class LookupAnswer extends StatelessWidget {
  const LookupAnswer({
    super.key,
    required this.answer,
    required this.onCapture,
  });

  final TradeLicenceLookup answer;

  /// Offered on the one answer that becomes a field capture.
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final AppTone tone = _tone;
    final Color ink = tone.on(context);

    return AppCard(
      color: tone.container(context),
      borderColor: ink.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_icon, size: 19, color: tone.onFilled(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(_verdict, color: ink, maxLines: 1),
                    if (answer.searched != null) ...<Widget>[
                      const SizedBox(height: 2),
                      AppText.caption(
                        answer.searched!,
                        color: ink,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppText.body(_explanation, color: ink),
          if (answer.isUnlicensed) ...<Widget>[
            const SizedBox(height: 14),
            AppButton(
              label: 'Capture this shop',
              icon: Icons.add_business_outlined,
              onPressed: onCapture,
            ),
          ],
        ],
      ),
    );
  }

  AppTone get _tone {
    if (answer.hasValidLicence) return AppTone.success;
    return answer.found ? AppTone.warning : AppTone.danger;
  }

  IconData get _icon {
    if (answer.hasValidLicence) return Icons.verified_rounded;
    return answer.found
        ? Icons.event_busy_rounded
        : Icons.error_outline_rounded;
  }

  String get _verdict {
    if (answer.hasValidLicence) return 'Licensed';
    return answer.found ? 'Licence lapsed' : 'Not on the register';
  }

  String get _explanation {
    if (answer.hasValidLicence) {
      return 'This shop may trade today. Nothing to do here.';
    }
    if (answer.found) {
      return 'On the register, but nothing live. This is a renewal the '
          'shopkeeper already owes — not a new application.';
    }
    return 'Nothing licensed against this. Capturing it quotes the fee, '
        'raises the challan and texts the shopkeeper a payment link.';
  }
}
