import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import 'intake_info_card.dart';

/// The case at a glance on a light brand plate: number, type and when it was
/// submitted on top; where the shop is and who the applicant is below.
class IntakeCaseHero extends StatelessWidget {
  const IntakeCaseHero({super.key, required this.file});

  final AgreementCase file;

  @override
  Widget build(BuildContext context) {
    final Color brand = AppTone.primary.on(context);
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
    final String? type = file.caseType?.label;
    // Each part kept whole, so "Zone A" never splits across lines.
    final String? address = file.shop.fullAddress
        ?.split(' · ')
        .map((String part) => part.replaceAll(' ', '\u00A0'))
        .join(' · ');
    final DateTime? submitted = file.submittedAt?.toLocal();

    final String? revised = _revised(file.contentRevision);
    final IntakeApplicant? applicant = file.applicant;
    final List<MapEntry<String, String>> facts =
        <String, String?>{
              'Applicant': applicant?.name,
              'Father': applicant?.fatherName,
              'CNIC': applicant?.cnic,
              'Mobile': applicant?.mobile,
              'Business': applicant?.business,
              'NTN': applicant?.ntn,
              'Register record': applicant?.recordLabel,
            }.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!))
            .toList();

    return AppTonePlate(
      tone: AppTone.primary,
      fit: StackFit.loose,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const IntakeIconPlate(icon: Icons.folder_open_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(
                      file.intakeNo ?? 'Case ${file.id}',
                      color: brand,
                      maxLines: 1,
                    ),
                    if (submitted != null)
                      AppText.caption(
                        'Submitted ${Formatters.date(submitted)}',
                        color: muted,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              if (type != null || revised != null) ...<Widget>[
                const SizedBox(width: 8),
                // The type, and under it how often the case was revised.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (type != null)
                      AppStatusBadge(label: type, tone: AppTone.info),
                    if (revised != null) ...<Widget>[
                      if (type != null) const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.history_rounded, size: 13, color: brand),
                          const SizedBox(width: 3),
                          AppText.caption(
                            revised,
                            color: brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: brand.withValues(alpha: 0.16)),
          ),
          if (address != null) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.place_outlined, size: 16, color: brand),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText.body(
                    address,
                    fontWeight: FontWeight.w600,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (applicant != null) const SizedBox(height: 12),
          ],
          if (applicant?.recordMatches != null) ...<Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(
                label: applicant!.recordMatches!
                    ? 'Matches register'
                    : 'Differs from register',
                tone: applicant.recordMatches!
                    ? AppTone.success
                    : AppTone.warning,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Two to a row, so the applicant fits the plate the steps left.
          for (int i = 0; i < facts.length; i += 2) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final MapEntry<String, String> fact
                    in facts.skip(i).take(2))
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppText.caption(fact.key, color: muted),
                        const SizedBox(height: 2),
                        AppText.body(
                          fact.value,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                if (i + 1 == facts.length) const Spacer(),
              ],
            ),
          ],
          if (applicant?.address != null) ...<Widget>[
            const SizedBox(height: 10),
            AppText.caption('Applicant address', color: muted),
            const SizedBox(height: 2),
            AppText.body(
              applicant!.address!,
              fontWeight: FontWeight.w600,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  /// "Revised 38 times"; nothing until it has been revised.
  static String? _revised(int? revision) => switch (revision) {
    null || <= 0 => null,
    1 => 'Revised once',
    _ => 'Revised $revision times',
  };
}
