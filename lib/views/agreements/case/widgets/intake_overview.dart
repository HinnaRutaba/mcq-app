import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/agreement_case.dart';
import '../../../../models/intake_legacy.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';
import 'intake_case_hero.dart';
import 'intake_info_card.dart';
import 'intake_legacy_card.dart';
import 'intake_note_alert.dart';

/// The notices a reviewer must read before acting: an open query, the last
/// return, a moved shop. Above every tab.
class IntakeNotices extends StatelessWidget {
  const IntakeNotices({super.key, required this.file});

  final AgreementCase file;

  @override
  Widget build(BuildContext context) {
    final IntakeNote? query = file.query;
    final IntakeNote? returned = file.lastReturn;
    final List<Widget> notices = <Widget>[
      if (file.shop.locationChangedSinceReview)
        AppAlert(
          tone: AppTone.danger,
          icon: Icons.wrong_location_outlined,
          message:
              'The shop’s location changed since it was reviewed'
              '${file.shop.reviewedLocation == null ? '' : ' (was ${file.shop.reviewedLocation})'}. '
              'Onward acts are closed — return the case to Estate.',
        ),
      if (query != null)
        IntakeNoteAlert(
          lead: 'Query open',
          note: query,
          tone: AppTone.warning,
          icon: Icons.help_outline_rounded,
        ),
      if (returned != null)
        IntakeNoteAlert(
          lead: 'Returned',
          note: returned,
          tone: AppTone.info,
          icon: Icons.undo_rounded,
        ),
      if (file.shop.problem != null)
        AppAlert(
          tone: AppTone.warning,
          icon: Icons.report_problem_outlined,
          message: file.shop.problem!,
        ),
    ];
    if (notices.isEmpty) return const SizedBox.shrink();
    return Column(
      children: <Widget>[
        for (final Widget notice in notices) ...<Widget>[
          notice,
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Identity, shop, applicant and witnesses.
class IntakeOverview extends StatelessWidget {
  const IntakeOverview({
    super.key,
    required this.file,
    this.legacyChecks = const <LegacyCheck>[],
    this.showLegacyMatches = false,
    this.onShowLegacyMatches,
  });

  final AgreementCase file;

  /// The case against its legacy register row, from the controller.
  final List<LegacyCheck> legacyChecks;
  final bool showLegacyMatches;
  final ValueChanged<bool>? onShowLegacyMatches;

  @override
  Widget build(BuildContext context) {
    final IntakeShop shop = file.shop;
    final IntakeApplicant? applicant = file.applicant;
    final IntakeLegacy? legacy = file.legacy;

    final List<Widget> cards = <Widget>[
      IntakeCaseHero(file: file),
      // Straight under the case, so a difference is seen without scrolling.
      if (legacy != null)
        IntakeLegacyCard(
          legacy: legacy,
          checks: legacyChecks,
          showMatches: showLegacyMatches,
          onShowMatches: onShowLegacyMatches ?? (_) {},
        ),
      IntakeInfoCard(
        title: 'Shop',
        icon: Icons.storefront_outlined,
        trailing: shop.verified == null
            ? null
            : AppStatusBadge(
                label: shop.verified! ? 'Verified' : 'Not verified',
                tone: shop.verified! ? AppTone.success : AppTone.warning,
              ),
        children: IntakeFact.of(<String, String?>{
          'Shop no': shop.shopNo,
          'Market': shop.market,
          'Area': shop.area,
          'Zone': shop.zone,
          'Address': shop.address,
          'At review': shop.reviewedLocation,
        }),
      ),
      if (applicant != null)
        IntakeInfoCard(
          title: 'Applicant',
          icon: Icons.person_outline_rounded,
          trailing: applicant.recordMatches == null
              ? null
              : AppStatusBadge(
                  label: applicant.recordMatches!
                      ? 'Matches register'
                      : 'Differs from register',
                  tone: applicant.recordMatches!
                      ? AppTone.success
                      : AppTone.warning,
                ),
          children: IntakeFact.of(<String, String?>{
            'Name': applicant.name,
            'Father': applicant.fatherName,
            'CNIC': applicant.cnic,
            'Mobile': applicant.mobile,
            'Business': applicant.business,
            'NTN': applicant.ntn,
            'Address': applicant.address,
            'Register record': applicant.recordLabel,
          }),
        ),
      for (final IntakeWitness witness in file.witnesses)
        IntakeInfoCard(
          title: 'Witness ${witness.position ?? ''}'.trim(),
          icon: Icons.badge_outlined,
          children: IntakeFact.of(<String, String?>{
            'Name': witness.name,
            'Father': witness.fatherName,
            'CNIC': witness.cnic,
            'Mobile': witness.mobile,
          }),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          AppEntrance(index: i, child: cards[i]),
        ],
      ],
    );
  }
}

/// `amounts.*`, as the server computed them. Nothing is added up here.
class IntakeMoney extends StatelessWidget {
  const IntakeMoney({super.key, required this.amounts});

  final Map<String, String> amounts;

  /// "12500.00" is money; "6" (months) and "2026-01-01" are not.
  static final RegExp _money = RegExp(r'^-?\d+\.\d{2}$');

  /// Formatters.money prints no paise, so only whole rupees go through it.
  /// A flag such as `charges_rent` reads Yes or No.
  static String show(String value) {
    if (value == 'true') return 'Yes';
    if (value == 'false') return 'No';
    if (!_money.hasMatch(value)) return value;
    return value.endsWith('.00') ? Formatters.money(value)! : 'Rs $value';
  }

  @override
  Widget build(BuildContext context) {
    if (amounts.isEmpty) {
      return const AppEmptyState(
        icon: Icons.payments_outlined,
        title: 'No figures yet',
        message: 'The server has not computed the amounts for this case.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IntakeInfoCard(
          title: 'Amounts',
          icon: Icons.payments_outlined,
          children: <Widget>[
            for (final MapEntry<String, String> line in amounts.entries)
              IntakeFact(
                label: IntakeLabels.humanise(line.key),
                value: show(line.value),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const AppText.caption(
          'Every figure is computed by the server.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
