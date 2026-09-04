import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_status_colors.dart';
import '../../../controllers/property_profile_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/api_refs.dart';
import '../../../models/challan.dart';
import '../../../models/defaulter_card.dart';
import '../../../models/enforcement_action.dart';
import '../../../models/enforcement_case.dart';
import '../../../models/property_profile.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/challan_sheet.dart';
import '../shared/widgets/create_fine_button.dart';
import 'widgets/case_card.dart';
import 'widgets/case_timeline.dart';
import 'widgets/profile_header.dart';

const EdgeInsets _cardPadding = EdgeInsets.fromLTRB(12, 16, 12, 16);

class PropertyProfileScreen extends StatefulWidget {
  const PropertyProfileScreen({
    super.key,
    required this.propertyId,
    this.card,
    this.initialTab,
  });

  final int propertyId;

  final DefaulterCard? card;

  /// The face to open on. Null opens the overview.
  final ProfileTab? initialTab;

  @override
  State<PropertyProfileScreen> createState() => _PropertyProfileScreenState();
}

class _PropertyProfileScreenState extends State<PropertyProfileScreen> {
  late final PropertyProfileController controller = Get.put(
    PropertyProfileController(
      propertyId: widget.propertyId,
      card: widget.card,
      initialTab: widget.initialTab,
    ),
  );

  @override
  void dispose() {
    Get.delete<PropertyProfileController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CreateFineButton(propertyId: controller.propertyId),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(
          () => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              ProfileHeader(
                title: controller.holder,
                subtitle: controller.propertyLine,
                owed: Formatters.money(controller.outstanding),
                unpaidMonths: controller.unpaidMonths,
                lastPaid: controller.lastPaymentDate,
                neverPaid: controller.neverPaid,
                nextVisit: controller.nextVisitDate,
                promised: controller.hasCommitment,
                mobileNo: controller.mobileNo,
                point: controller.mapPoint,
                address: controller.mapQuery,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              AppPinnedBar(
                height: _tabsHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
                  child: AppChipTabs<ProfileTab>(
                    items: ProfileTab.values,
                    itemLabel: (ProfileTab tab) => tab.label,
                    selected: controller.tab.value,
                    onChanged: controller.showTab,
                    compact: true,
                  ),
                ),
              ),
              ..._slivers(context, controller),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pinned tab strip: 14 + a 32pt chip row + 2.
const double _tabsHeight = 48;

List<Widget> _slivers(
  BuildContext context,
  PropertyProfileController controller,
) {
  if (controller.isLoading.value && !controller.hasData) {
    return const <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }

  final String? error = controller.errorMessage.value;
  if (error != null && !controller.hasData) {
    return <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorRetry(
          title: 'Could not load this shop',
          message: error,
          onRetry: controller.load,
        ),
      ),
    ];
  }

  return <Widget>[
    SliverPadding(
      // Deep at the bottom: the fine button floats over the last of the list.
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
      sliver: SliverList.list(
        children: <Widget>[
          if (error != null) ...<Widget>[
            AppAlert(
              message: error,
              tone: AppTone.warning,
              icon: Icons.wifi_off_rounded,
            ),
            const SizedBox(height: 20),
          ],
          ..._tabBody(context, controller),
        ],
      ),
    ),
  ];
}

/// One tab's worth of the shop. Read inside the body's `Obx`, so switching tab
/// rebuilds the list.
List<Widget> _tabBody(
  BuildContext context,
  PropertyProfileController controller,
) => switch (controller.tab.value) {
  ProfileTab.overview => _overview(controller),
  ProfileTab.owed => _owed(context, controller),
  ProfileTab.cases => _cases(controller),
  ProfileTab.history => _history(controller),
};

List<Widget> _overview(PropertyProfileController controller) {
  final PropertyProfile? profile = controller.profile.value;
  if (profile == null) {
    return <Widget>[_unread('The unit’s details have not come through yet')];
  }

  return <Widget>[
    _section('The unit', _ShopCard(property: profile.property)),
    const SizedBox(height: 20),
    _section(
      'Who holds it',
      _HolderCard(
        allottee: profile.allottee,
        allotment: profile.allotment,
        vacant: profile.isVacant,
      ),
    ),
    if (_hasEnforcement(profile.enforcement)) ...<Widget>[
      const SizedBox(height: 20),
      _section(
        'Enforcement',
        _EnforcementCard(enforcement: profile.enforcement),
      ),
    ],
  ];
}

List<Widget> _owed(BuildContext context, PropertyProfileController controller) {
  final PropertyProfile? profile = controller.profile.value;
  if (profile == null) {
    return <Widget>[_unread('The rent position has not come through yet')];
  }

  final PropertyPosition position = profile.position;
  final List<BarDatum> parts = _owedBars(context, position);

  return <Widget>[
    if (parts.isNotEmpty) ...<Widget>[
      _section(
        'What makes up the debt',
        AppCard(
          padding: _cardPadding,
          // Not sorted: this period, then everything older, then the charge on
          // it is the order a shopkeeper is told the figure in.
          child: AppBarList(data: parts, sorted: false),
        ),
      ),
      const SizedBox(height: 20),
    ],
    _section('The rent side', _PositionCard(position: position)),
    if (profile.challans.isNotEmpty) ...<Widget>[
      const SizedBox(height: 20),
      _section('Bills', _Challans(challans: profile.challans)),
    ],
  ];
}

List<Widget> _cases(PropertyProfileController controller) => <Widget>[
  _section(
    'Cases',
    _Cases(
      files: controller.cases.toList(),
      selectedId: controller.selectedCaseId.value,
      onSelect: controller.showCase,
    ),
    note: controller.cases.isEmpty ? null : 'Tap a case to read its history',
  ),
];

List<Widget> _history(PropertyProfileController controller) => <Widget>[
  _Timeline(
    file: controller.selectedCase,
    actions: controller.actions.toList(),
    isLoading: controller.isLoadingTimeline.value,
    error: controller.timelineError.value,
  ),
];

/// The three figures the debt is made of, as bars against each other.
///
/// A row is drawn only for a figure the server actually sent; a zero it did
/// send stays, because "no surcharge yet" is worth seeing.
List<BarDatum> _owedBars(BuildContext context, PropertyPosition position) {
  final AppStatusColors status = context.status;
  final int months = position.unpaidMonths;

  BarDatum? bar(String label, String? amount, Color color, {String? caption}) {
    final String? printed = Formatters.money(amount);
    if (printed == null) return null;
    return BarDatum(
      label: label,
      // Parsed only to draw the bar with; the figure beside it is the
      // server's own string, printed.
      value: double.tryParse(amount!.trim()) ?? 0,
      valueLabel: printed,
      caption: caption,
      color: color,
    );
  }

  return <BarDatum>[
    ?bar('Rent this period', position.currentDue, status.info),
    ?bar(
      'Arrears',
      position.arrearsDue,
      status.danger,
      caption: months > 0 ? '$months months unpaid' : null,
    ),
    ?bar('Surcharge', position.surchargeDue, status.warning),
  ];
}

Widget _section(String title, Widget child, {String? note}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    AppText.titleMedium(title),
    if (note != null) ...<Widget>[
      const SizedBox(height: 3),
      Builder(
        builder: (BuildContext context) => AppText.caption(
          note,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          maxLines: 1,
        ),
      ),
    ],
    const SizedBox(height: 10),
    child,
  ],
);

/// A tab whose call has not answered. The failure itself, if there was one,
/// rides at the top of the list already.
Widget _unread(String message) => AppCard(
  padding: _cardPadding,
  child: AppDetailRow(
    icon: Icons.cloud_off_outlined,
    value: message,
    maxLines: 2,
  ),
);

bool _hasEnforcement(PropertyEnforcement enforcement) =>
    enforcement.isSealed ||
    enforcement.sealNo != null ||
    enforcement.hasOpenCase ||
    enforcement.openLegalCases > 0;

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.property});

  final ProfileProperty property;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: _cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (property.streetAddress != null)
            AppDetailRow(
              icon: Icons.place_outlined,
              value: property.streetAddress!,
              maxLines: 2,
            ),
          if (property.propertyCode != null)
            AppDetailRow(
              icon: Icons.qr_code_2_rounded,
              value: property.propertyCode!,
            ),
          if (property.register949Ref != null)
            AppDetailRow(
              icon: Icons.menu_book_outlined,
              // Register 949 is the corporation's own ledger of units; the
              // reference is what a clerk looks the shop up by.
              value: 'Register 949 · ${property.register949Ref}',
            ),
          if (property.zoneName != null)
            AppDetailRow(icon: Icons.map_outlined, value: property.zoneName!),
          const SizedBox(height: 2),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              if (property.categoryName != null)
                AppStatusBadge(label: property.categoryName!),
              // Sent as bare strings with no tone of their own, so they are
              // shown as stated rather than coloured by a guess here.
              if (property.occupancyStatus != null)
                AppStatusBadge(label: _humanise(property.occupancyStatus!)),
              if (property.physicalStatus != null)
                AppStatusBadge(label: _humanise(property.physicalStatus!)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.position});

  final PropertyPosition position;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: _cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The server's own total of the rent side — not the three bars above
          // added up here, and never a fine folded in.
          _Money(
            label: 'Total outstanding',
            value: position.totalOutstanding,
            strong: true,
          ),
          _Money(label: 'Collected to date', value: position.totalCollected),
          if (position.hasEverPaid)
            _Money(
              label: 'Last payment',
              text: Formatters.date(position.lastPaymentDate!.toLocal()),
            )
          else
            const _Money(label: 'Last payment', text: 'Never'),
        ],
      ),
    );
  }
}

/// A label and a figure, which is how money reads: down a column, aligned on
/// the right, so two amounts can be compared without reading the labels twice.
class _Money extends StatelessWidget {
  const _Money({
    required this.label,
    this.value,
    this.text,
    this.strong = false,
  });

  final String label;

  /// A money string from the API, printed through [Formatters.money].
  final String? value;

  /// Already-formatted text, for a row that is not an amount.
  final String? text;

  final bool strong;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final String shown = text ?? Formatters.money(value) ?? '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: AppText.body(label, color: muted, maxLines: 1)),
          const SizedBox(width: 12),
          AppText.body(
            shown,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _HolderCard extends StatelessWidget {
  const _HolderCard({
    required this.allottee,
    required this.allotment,
    required this.vacant,
  });

  final AllotteeRef? allottee;
  final AllotmentRef? allotment;
  final bool vacant;

  @override
  Widget build(BuildContext context) {
    if (vacant || allottee == null) {
      return const AppCard(
        padding: _cardPadding,
        child: AppDetailRow(
          icon: Icons.person_off_outlined,
          // A vacant shop can still owe money and can still be traded out
          // of by somebody who is not on the register.
          value: 'Nobody holds this shop on the register',
          maxLines: 2,
        ),
      );
    }

    final AllotteeRef holder = allottee!;

    return AppCard(
      padding: _cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (holder.fullName != null)
            AppDetailRow(
              icon: Icons.person_outline_rounded,
              value: holder.fullName!,
            ),
          // The number, as a fact. Pressing it is a header action — the ways
          // to reach the holder are gathered up there, not one per card.
          if (holder.mobileNo != null)
            AppDetailRow(icon: Icons.call_outlined, value: holder.mobileNo!),
          if (holder.cnic != null)
            AppDetailRow(icon: Icons.badge_outlined, value: holder.cnic!),
          if (holder.allotteeCode != null)
            AppDetailRow(icon: Icons.tag_rounded, value: holder.allotteeCode!),
          if (allotment?.allotmentNo != null)
            AppDetailRow(
              icon: Icons.description_outlined,
              // The tenancy the unit is held under. The API does not say
              // whether it is an agreement or a licence, so neither does this.
              value: allotment!.allotmentNo!,
            ),
        ],
      ),
    );
  }
}

class _EnforcementCard extends StatelessWidget {
  const _EnforcementCard({required this.enforcement});

  final PropertyEnforcement enforcement;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: _cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (enforcement.sealNo != null)
            AppDetailRow(
              icon: Icons.lock_outline_rounded,
              value: enforcement.sealedOn == null
                  ? 'Seal ${enforcement.sealNo}'
                  : 'Seal ${enforcement.sealNo} · '
                        '${Formatters.date(enforcement.sealedOn!.toLocal())}',
            ),
          if (enforcement.openCaseNo != null)
            AppDetailRow(
              icon: Icons.folder_open_outlined,
              value: 'Case ${enforcement.openCaseNo}',
            ),
          if (enforcement.openLegalCases > 0)
            AppDetailRow(
              icon: Icons.gavel_rounded,
              // A matter before a court, as opposed to the corporation's own
              // file — worth saying plainly before anything is sealed.
              value:
                  '${enforcement.openLegalCases} legal '
                  '${enforcement.openLegalCases == 1 ? 'case' : 'cases'} '
                  'before a court',
              maxLines: 2,
            ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[
              if (enforcement.isSealed)
                const AppStatusBadge(label: 'Sealed', tone: AppTone.danger),
              if (enforcement.sealStatus != null)
                AppStatusBadge(label: _humanise(enforcement.sealStatus!)),
              if (enforcement.caseStatus != null)
                AppStatusBadge(label: _humanise(enforcement.caseStatus!)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Challans extends StatelessWidget {
  const _Challans({required this.challans});

  final List<Challan> challans;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      children: <Widget>[
        for (final Challan challan in challans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              // The row is a summary; the whole bill — its breakdown, what is
              // payable today and the number to quote — is a press away.
              onTap: () => ChallanSheet.show(context, challan: challan),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppText.body(
                          challan.challanNo ?? 'Bill #${challan.id}',
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // This bill alone. A fine bill and a rent bill are
                      // separate debts and are never totalled.
                      //
                      // `payable_now` first — it is the server's answer to
                      // what is due today, after any deferral, and the figure
                      // quoted at a counter. The two behind it are fallbacks
                      // for a row that omits it, so the column is never blank
                      // while the bill carries a figure at all.
                      AppText.body(
                        Formatters.money(challan.amounts.payableNow) ??
                            Formatters.money(challan.amounts.balanceAmount) ??
                            Formatters.money(challan.amounts.totalAmount) ??
                            '—',
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: <Widget>[
                      if (challan.status != null)
                        AppStatusBadge(
                          label: challan.status!.label,
                          tone: AppToneColors.fromApi(challan.status!.tone),
                        ),
                      if (challan.challanType != null)
                        AppStatusBadge(label: challan.challanType!.label),
                      if (challan.isOverdue)
                        AppStatusBadge(
                          label: '${challan.daysOverdue} days overdue',
                          tone: AppTone.danger,
                        ),
                    ],
                  ),
                  if (challan.dueDate != null) ...<Widget>[
                    const SizedBox(height: 8),
                    AppText.caption(
                      'Due ${Formatters.date(challan.dueDate!.toLocal())}',
                      color: muted,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Cases extends StatelessWidget {
  const _Cases({
    required this.files,
    required this.selectedId,
    required this.onSelect,
  });

  final List<EnforcementCase> files;

  /// The case whose timeline the history tab shows.
  final int? selectedId;

  final void Function(int caseId) onSelect;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const AppCard(
        padding: _cardPadding,
        child: AppDetailRow(
          icon: Icons.folder_off_outlined,
          value: 'No enforcement case has been opened on this shop',
          maxLines: 2,
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final EnforcementCase file in files)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CaseCard(
              file: file,
              selected: file.id == selectedId,
              onTap: file.id == null ? null : () => onSelect(file.id!),
            ),
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.file,
    required this.actions,
    required this.isLoading,
    required this.error,
  });

  /// The case being read, when one has been chosen.
  final EnforcementCase? file;

  /// Oldest first, as the endpoint sent them.
  final List<EnforcementAction> actions;

  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppText.titleMedium('Visit timeline'),
        if (file?.caseNo != null) ...<Widget>[
          const SizedBox(height: 3),
          AppText.caption(file!.caseNo!, color: muted, maxLines: 1),
        ],
        const SizedBox(height: 10),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          AppAlert(
            message: error!,
            tone: AppTone.warning,
            icon: Icons.wifi_off_rounded,
          )
        else if (actions.isEmpty)
          AppCard(
            padding: _cardPadding,
            child: AppDetailRow(
              icon: Icons.history_toggle_off_outlined,
              value: file == null
                  ? 'A timeline starts with the first case on the unit'
                  : 'Nothing has been recorded on this case yet',
              maxLines: 2,
            ),
          )
        else
          CaseTimeline(actions: actions),
      ],
    );
  }
}

/// `awaiting_release` -> `Awaiting release`. For the profile's bare status
/// strings, which arrive without a label of their own.
String _humanise(String value) {
  final String words = value.replaceAll('_', ' ').trim();
  if (words.isEmpty) return value;
  return words[0].toUpperCase() + words.substring(1);
}
