import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_radius.dart';
import '../../../controllers/trade_capture_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/form_scroll.dart';
import '../../../models/field_beat.dart';
import '../../../models/trade_application.dart';
import '../../../models/trade_application_request.dart';
import '../../../models/trade_tariff.dart';
import '../../../widgets/widgets.dart';
import '../shared/widgets/area_search_field.dart';
import '../shared/widgets/still_needed_note.dart';
import 'widgets/capture_sheet.dart';
import 'widgets/trade_category_sheet.dart';

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

  /// The form's own scroll, so a refusal can be scrolled back to.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
      await CaptureSheet.confirm(context, application: application);
      if (mounted) _leave(changed: true);
      return;
    }

    // A send that never came back is not a message but a choice — check the
    // captures, or send again — so it stays a block at the top of the form,
    // and the form is carried back to it.
    if (controller.mayHaveLanded.value) {
      _scrollController.revealBanner();
      return;
    }

    // Otherwise the server's own sentence is in the submit bar, under the
    // thumb that just pressed the button. Anything it blamed a field for is
    // under that field — which may be several sections up, so the form goes
    // to it.
    scrollToFirstError(controller.formKey);
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
              // A column, not a list: this form is a fixed handful of
              // sections, and a lazy list only ever builds the visible ones —
              // so `validate()` paints messages on half the form and passes
              // the rest, and a field that was never built cannot be scrolled
              // to when the server names it.
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Banner(
                      controller: controller,
                      onCheck: () => _leave(changed: true),
                    ),
                    _AreaSection(controller: controller),
                    const SizedBox(height: 20),
                    _TradeSection(controller: controller),
                    const SizedBox(height: 20),
                    _ShopkeeperSection(controller: controller),
                    const SizedBox(height: 20),
                    _ShopSection(controller: controller),
                  ],
                ),
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

    // A refused capture is not here: it is in the submit bar, beside the
    // button that will be pressed again. This is the tariff — a fee that would
    // not load belongs beside the form it prices.
    final String? message = controller.tariffError.value;
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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

/// Step 1: the bazaar, which nothing else on this form can be answered
/// without — `tariff?area_id=` prices one bazaar and has to be told which.
class _AreaSection extends StatelessWidget {
  const _AreaSection({required this.controller});

  final TradeCaptureController controller;

  @override
  Widget build(BuildContext context) => _Section(
    step: '1',
    title: 'The bazaar',
    note: 'MCQ prices a trade by zone, so the bazaar decides the fee.',
    child: Obx(() => _picker(context)),
  );

  /// Read inside the builder, not around this widget: a value read in a
  /// child's own build registers with nothing.
  Widget _picker(BuildContext context) {
    final List<int> options = controller.areaOptions;
    if (options.isEmpty && controller.isLoadingAreas.value) {
      return const AppCard(child: AppText.body('Loading your bazaars…'));
    }

    // Nothing to search, so nothing can be priced. The message is the beat's
    // own, and the button is the way back to it.
    if (options.isEmpty) {
      final String? error = controller.areasError.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppAlert(
            message:
                error ??
                'Your bazaars have not loaded, so a trade cannot be priced '
                    'yet.',
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Load the bazaars',
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.outline,
            fullWidth: false,
            onPressed: controller.loadAreas,
          ),
        ],
      );
    }

    // The matches belong to the box, not to the form: they open under it and
    // close with it.
    return AreaSearchField(
      controller: controller.areaSearchController,
      optionsFor: controller.areaMatchesFor,
      onChanged: controller.searchArea,
      onSelected: (FieldArea area) => controller.setArea(area.id),
      selected: controller.chosenArea,
      onCleared: controller.clearArea,
      hint: 'Search the bazaar',
      note: 'The licence is priced for this bazaar',
      error: controller.areaError,
    );
  }
}

/// Step 2: the trade, and with it the fee and the term — all three off the
/// tariff for the bazaar above, none of them typed.
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
  Widget build(BuildContext context) => _Section(
    step: '2',
    title: 'The trade',
    note:
        'MCQ prices the trade, so choosing it sets the fee — the figure on '
        'the bar below is what the shopkeeper is charged, and it cannot be '
        'changed here.',
    child: AppCard(child: Obx(() => _body(context))),
  );

  Widget _body(BuildContext context) {
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    if (controller.areaId.value == null) {
      return AppText.body(
        'Name the bazaar first — the prices are the ones MCQ charges there.',
        color: muted,
      );
    }

    if (controller.isLoadingTariff.value && controller.tariff.value == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // The banner at the top of the form already carries why. This is the way
    // to ask again.
    if (controller.tariff.value == null) {
      return AppButton(
        label: 'Load the prices',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.outline,
        onPressed: controller.loadTariff,
      );
    }

    final TradeCategory? chosen = controller.category.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _TradePicker(
          category: chosen,
          error: controller.categoryError,
          enabled: controller.quotableGroups.isNotEmpty,
          onTap: () => _pick(context),
        ),
        if (chosen != null) ...<Widget>[
          const SizedBox(height: 12),
          _TradeDetails(
            category: chosen,
            group: controller.categoryGroup,
            zoneName: controller.zoneName,
          ),
        ],
        const SizedBox(height: 18),
        // Stated, not asked: a year is the only term MCQ issues in the field.
        const AppText.label('Licence term'),
        const SizedBox(height: 8),
        const AppDetailRow(
          icon: Icons.event_repeat_outlined,
          value: 'One year — the only term issued in the field',
        ),
      ],
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

class _TradeDetails extends StatelessWidget {
  const _TradeDetails({
    required this.category,
    required this.group,
    required this.zoneName,
  });

  final TradeCategory category;
  final String? group;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (category.categoryNameUr != null) ...<Widget>[
            // Right to left, and larger than a caption: Urdu set small is not
            // readable at arm's length in the sun.
            Directionality(
              textDirection: TextDirection.rtl,
              child: AppText.titleMedium(category.categoryNameUr!),
            ),
            const SizedBox(height: 10),
          ],
          if (group != null)
            AppDetailRow(icon: Icons.category_outlined, value: group!),
          if (category.categoryCode != null)
            AppDetailRow(
              icon: Icons.tag_rounded,
              value: category.categoryCode!,
            ),
          if (zoneName != null)
            // The zone is the answer to "why that figure?" — MCQ prices a
            // trade per zone and the bazaar inherits it.
            AppDetailRow(
              icon: Icons.map_outlined,
              value: 'Priced for $zoneName',
              maxLines: 2,
            ),
        ],
      ),
    );
  }
}

class _ShopkeeperSection extends StatelessWidget {
  const _ShopkeeperSection({required this.controller});

  final TradeCaptureController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '3',
      title: 'The shopkeeper',
      note:
          'The mobile number is where the payment link is texted, so a wrong '
          'digit is a challan nobody sees.',
      child: AppCard(
        child: Column(
          children: <Widget>[
            AppTextField(
              label: 'CNIC',
              hint: "e.g. 5440011223344",
              controller: controller.cnicController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  TradeApplicationRequest.cnicLength,
                ),
              ],
              validator: controller.validateCnic,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
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
              validator: controller.validateMobile,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Email',
              optional: true,
              hint: 'name@example.com',
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
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

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '4',
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
          ],
        ),
      ),
    );
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
            final String fee = controller.fee;
            final List<String> missing = controller.missing;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // A total line: the label on the left, the figure at the right
                // edge where a reader looks for it.
                Row(
                  children: <Widget>[
                    Expanded(
                      // The term is on the label, not on the figure: "/ year"
                      // beside a long fee runs the row off a narrow screen.
                      child: AppText.caption(
                        "Licence fee, per year — MCQ's quote",
                        color: muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Printed as the tariff quoted it. Never parsed, never
                    // rounded, never multiplied by the term.
                    AppText.titleLarge(fee.isEmpty ? '—' : 'Rs $fee'),
                  ],
                ),
                // A row of its own, and every missing field named: a disabled
                // button an officer cannot explain is the one they give up on.
                if (missing.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  StillNeededNote(missing: missing),
                ],
                // Why the last press did not go through, kept beside the
                // button that will be pressed again. Not while the send is
                // unconfirmed: the block at the top of the form says that
                // better, and saying it twice in two tones reads as two
                // different problems.
                if (controller.errorMessage.value != null &&
                    !controller.mayHaveLanded.value) ...<Widget>[
                  const SizedBox(height: 10),
                  AppAlert(
                    message: controller.errorMessage.value!,
                    compact: true,
                  ),
                ],
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
