import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/trade_capture_controller.dart';
import '../../../core/capture/location_capture.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/trade_application.dart';
import '../../../models/trade_application_request.dart';
import '../../../models/trade_tariff.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/evidence_tile.dart';
import 'widgets/trade_captured_sheet.dart';
import 'widgets/trade_category_sheet.dart';

/// Capturing an unlicensed shop on the spot.
///
/// Three numbered blocks on one scroll — the trade, the shopkeeper, the shop —
/// under a bar that stays on screen carrying the fee the server quoted and the
/// button. One pass, not a wizard: an officer standing in front of a shopkeeper
/// should see everything the capture will say without tapping "next".
///
/// The fee is never worked out here. It comes off the tariff for (trade x
/// zone), is shown per year exactly as sent, and the server prices the licence
/// when it raises the challan.
///
/// The write does four things at once — quotes the fee, raises the challan,
/// issues a payment link and texts the shopkeeper — and carries no
/// `client_action_uuid`, so a call that never came back may still have landed.
/// That case sends the officer to their captures rather than offering a retry.
class TradeCaptureScreen extends StatefulWidget {
  const TradeCaptureScreen({super.key, this.searched, this.areaId});

  /// The CNIC or mobile the officer looked up before finding nothing.
  final String? searched;

  /// The bazaar they were filtering by, when they were.
  final int? areaId;

  @override
  State<TradeCaptureScreen> createState() => _TradeCaptureScreenState();
}

class _TradeCaptureScreenState extends State<TradeCaptureScreen> {
  late final TradeCaptureController controller = Get.put(
    TradeCaptureController(
      searched: widget.searched,
      initialAreaId: widget.areaId,
    ),
  );

  @override
  void dispose() {
    Get.delete<TradeCaptureController>();
    super.dispose();
  }

  /// True means the officer's own captures have moved — one was written, or
  /// they went to check whether one had been.
  void _leave({required bool changed}) =>
      Navigator.of(context).pop<bool>(changed);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final CaptureOutcome outcome = await controller.capture();
    if (!mounted) return;

    if (outcome == CaptureOutcome.success) {
      final TradeApplication? application = controller.captured.value;
      if (application == null) return;
      await TradeCapturedSheet.show(context, application: application);
      if (mounted) _leave(changed: true);
    }
    // Everything else is already on the form: the banner carries the server's
    // own sentence, and a refusal's per-field messages are back under their
    // fields.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Obx(
            () => AppHeroHeader(
              title: 'Capture a shop',
              subtitle: controller.zoneName ?? 'Trading without a licence',
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _leave(changed: false),
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: controller.formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: <Widget>[
                  _Banner(
                    controller: controller,
                    onCheck: () => _leave(changed: true),
                  ),
                  _TradeSection(controller: controller),
                  const SizedBox(height: 20),
                  _ShopkeeperSection(controller: controller),
                  const SizedBox(height: 20),
                  _ShopSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        controller: controller,
        onSubmit: _submit,
      ),
    );
  }
}

/// Whatever the last attempt left behind: a tariff that would not load, a
/// refusal, or the one that matters — a send that never came back.
class _Banner extends StatelessWidget {
  const _Banner({required this.controller, required this.onCheck});

  final TradeCaptureController controller;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) => Obx(() => _banner(context));

  /// The `Obx` belongs here rather than around this widget: a value read in a
  /// child's own build registers with nothing.
  Widget _banner(BuildContext context) {
    if (controller.mayHaveLanded.value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppAlert(
              tone: AppTone.warning,
              icon: Icons.help_outline_rounded,
              message:
                  'That did not come back, and this capture cannot be sent '
                  'twice safely. Check your captures before sending again — '
                  'the shop may already be on the register.',
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Check my captures',
              icon: Icons.fact_check_outlined,
              variant: AppButtonVariant.outline,
              onPressed: onCheck,
            ),
          ],
        ),
      );
    }

    final String? message =
        controller.errorMessage.value ?? controller.tariffError.value;
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      // The server's own sentence, verbatim. It knows why it refused and the
      // handset does not.
      child: AppAlert(message: message),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// A numbered block. The number is the point: it tells the officer how much
/// form is left, which a flat run of labels never does.
class _Section extends StatelessWidget {
  const _Section({
    required this.step,
    required this.title,
    required this.child,
    this.note,
  });

  final String step;
  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              height: 24,
              width: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: AppText.caption(
                step,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: AppText.titleLarge(title)),
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 34),
            child: AppText.body(note!, color: muted),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _TradeSection extends StatelessWidget {
  const _TradeSection({required this.controller});

  final TradeCaptureController controller;

  Future<void> _pick(BuildContext context) async {
    final TradeCategory? chosen = await TradeCategorySheet.show(
      context,
      groups: controller.quotableGroups,
      unpriced: controller.unpricedCount,
      selected: controller.category.value,
    );
    if (chosen != null) controller.chooseCategory(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '1',
      title: 'The trade',
      note: 'MCQ prices a trade by zone, so the bazaar decides the fee.',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Obx(() {
              if (controller.isLoadingTariff.value &&
                  controller.tariff.value == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.areaOptions.isEmpty) {
                return AppButton(
                  label: 'Load the tariff',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: controller.loadTariff,
                );
              }
              return AppDropdown<int>(
                // Keyed on the value: the tariff answers with a bazaar when
                // none was asked for, and an unkeyed form field would keep
                // showing the hint over a choice that has already been made.
                key: ValueKey<int?>(controller.areaId.value),
                label: 'Bazaar',
                items: controller.areaOptions,
                itemLabel: controller.areaLabel,
                value: controller.areaId.value,
                onChanged: controller.setArea,
                prefixIcon: Icons.place_outlined,
                validator: (_) => controller.areaError,
              );
            }),
            const SizedBox(height: 18),
            Obx(
              () => _TradePicker(
                category: controller.category.value,
                error: controller.categoryError,
                enabled: controller.quotableGroups.isNotEmpty,
                onTap: () => _pick(context),
              ),
            ),
            const SizedBox(height: 18),
            Obx(
              () => AppDropdown<int>(
                key: ValueKey<int>(controller.years.value),
                label: 'Licence term',
                items: controller.termOptions,
                itemLabel: (int year) =>
                    '$year ${year == 1 ? 'year' : 'years'}',
                value: controller.years.value,
                onChanged: controller.setYears,
                prefixIcon: Icons.event_repeat_outlined,
                validator: (_) => controller.yearsError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chosen trade, or the invitation to choose one. A tap opens the tariff's
/// own grouped picker rather than a ninety-item dropdown.
class _TradePicker extends StatelessWidget {
  const _TradePicker({
    required this.category,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  final TradeCategory? category;
  final String? error;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );
    final String? fee = Formatters.money(category?.annualFee);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppText.label('Trade'),
        const SizedBox(height: 8),
        AppCard(
          onTap: enabled ? onTap : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          borderColor: error == null ? null : theme.colorScheme.error,
          child: Row(
            children: <Widget>[
              Icon(Icons.storefront_outlined, size: 20, color: muted),
              const SizedBox(width: 12),
              Expanded(
                child: AppText.body(
                  category?.categoryName ??
                      (enabled ? 'Choose a trade' : 'No priced trade here'),
                  color: category == null ? muted : null,
                  maxLines: 2,
                ),
              ),
              if (fee != null) ...<Widget>[
                const SizedBox(width: 10),
                // Per year, as quoted. Never multiplied by the term.
                AppText.body('$fee / yr', fontWeight: FontWeight.w700),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: muted),
            ],
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: 6),
          AppText.caption(error!, color: theme.colorScheme.error),
        ],
      ],
    );
  }
}

class _ShopkeeperSection extends StatelessWidget {
  const _ShopkeeperSection({required this.controller});

  final TradeCaptureController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '2',
      title: 'The shopkeeper',
      note:
          'The mobile number is where the payment link is texted, so a wrong '
          'digit is a challan nobody sees.',
      child: AppCard(
        child: Column(
          children: <Widget>[
            AppTextField(
              label: 'Name',
              controller: controller.applicantController,
              textInputAction: TextInputAction.next,
              validator: controller.validateApplicant,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: "Father's name",
              controller: controller.fatherController,
              textInputAction: TextInputAction.next,
              validator: controller.validateFather,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Mobile number',
              hint: '03XXXXXXXXX',
              controller: controller.mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              prefixIcon: Icons.phone_outlined,
              validator: controller.validateMobile,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'CNIC',
              // Thirteen bare digits here, unlike the dashed form a fine takes.
              hint: 'Optional · ${TradeApplicationRequest.cnicLength} digits',
              controller: controller.cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  TradeApplicationRequest.cnicLength,
                ),
              ],
              prefixIcon: Icons.badge_outlined,
              validator: controller.validateCnic,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Email',
              hint: 'Optional',
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
              validator: controller.validateEmail,
              onChanged: (_) => controller.markEdited(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({required this.controller});

  final TradeCaptureController controller;

  Future<void> _location(BuildContext context) async {
    final LocationOutcome outcome = await controller.attachLocation();
    if (!context.mounted) return;
    switch (outcome) {
      case LocationOutcome.fixed:
        break;
      case LocationOutcome.serviceOff:
        _say(context, 'Turn location on to record where the shop stands.');
      case LocationOutcome.needsSettings:
        _say(context, 'Allow location in Settings to record where you stood.');
      case LocationOutcome.refused:
      case LocationOutcome.unavailable:
        _say(
          context,
          'No fix here. The capture can still be sent without one.',
        );
    }
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText.body(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return _Section(
      step: '3',
      title: 'The shop',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppTextField(
              label: 'Business name',
              hint: 'e.g. Al Madina Naan Shop',
              controller: controller.businessController,
              textInputAction: TextInputAction.next,
              validator: controller.validateBusiness,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Shop address',
              hint: 'e.g. Shop 14, Circular Road, Quetta',
              controller: controller.addressController,
              maxLines: 2,
              validator: controller.validateAddress,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            Obx(
              () => Row(
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    child: EvidenceTile(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      busy: controller.isFixingLocation.value,
                      state: _locationState,
                      detail: _locationDetail,
                      onTap: () => _location(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppText.caption(
                      'Optional, and it is what puts somebody at this '
                      'shopfront if the capture is ever argued with.',
                      color: muted,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Remarks',
              hint: 'Optional',
              controller: controller.remarksController,
              maxLines: 3,
              validator: controller.validateRemarks,
              onChanged: (_) => controller.markEdited(),
            ),
          ],
        ),
      ),
    );
  }

  EvidenceState get _locationState {
    if (controller.locationFix.value != null) return EvidenceState.attached;
    return switch (controller.locationOutcome.value) {
      LocationOutcome.refused ||
      LocationOutcome.needsSettings ||
      LocationOutcome.serviceOff => EvidenceState.unavailable,
      _ => EvidenceState.empty,
    };
  }

  String? get _locationDetail {
    final LocationFix? fix = controller.locationFix.value;
    // The accuracy is the evidence. "Fixed" alone could mean 800 metres, which
    // does not put anybody in front of a shop.
    if (fix != null) return '${fix.accuracyM.round()} m';
    return null;
  }
}

/// The bar that stays on screen: the fee as the server quoted it, what is
/// still missing, and the button.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final TradeCaptureController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? muted = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.6,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Obx(() {
            // Re-read the text controllers whenever anything was edited.
            controller.revision.value;
            final String? fee = Formatters.money(controller.annualFee);
            final List<String> missing = controller.missing;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppText.caption('Licence fee', color: muted),
                          const SizedBox(height: 2),
                          // Per year, exactly as quoted. The server prices the
                          // licence over the term when it raises the challan.
                          AppText.titleLarge(fee == null ? '—' : '$fee / year'),
                        ],
                      ),
                    ),
                    if (missing.isNotEmpty)
                      Flexible(
                        child: AppText.caption(
                          'Still needed: ${missing.take(2).join(', ')}'
                          '${missing.length > 2 ? '…' : ''}',
                          color: muted,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: controller.mayHaveLanded.value
                      ? 'Send it again'
                      : 'Capture this shop',
                  icon: Icons.add_business_outlined,
                  isLoading: controller.isSubmitting.value,
                  onPressed: missing.isEmpty ? onSubmit : null,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
