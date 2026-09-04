import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/fine_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/capture/photo_capture.dart';
import '../../../models/enforcement_definitions.dart';
import '../../../models/field_beat.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/evidence_tile.dart';
import 'widgets/fine_amount_field.dart';
import 'widgets/fine_imposed_sheet.dart';
import '../../../config/theme/app_radius.dart';

class CreateFineScreen extends StatefulWidget {
  const CreateFineScreen({super.key, this.unit, this.propertyId});

  /// The shop, when the officer came from its profile.
  final UnitCard? unit;

  /// Its id, when only that was carried on the route.
  final int? propertyId;

  @override
  State<CreateFineScreen> createState() => _CreateFineScreenState();
}

class _CreateFineScreenState extends State<CreateFineScreen> {
  late final FineController controller = Get.put(
    FineController(unit: widget.unit, propertyId: widget.propertyId),
  );

  @override
  void dispose() {
    Get.delete<FineController>();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final outcome = await controller.impose();
    if (!mounted) return;

    if (outcome == ImposeOutcome.success) {
      final fine = controller.imposed.value;
      if (fine == null) return;
      await FineImposedSheet.show(context, fine: fine);
      if (mounted) Navigator.of(context).pop(fine);
    }
    // A refusal is already on the form: the banner carries the server's own
    // sentence and the per-field messages are back under their fields.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Obx(() {
            // Watched, not merely read: the line under the title changes when
            // the officer picks a bazaar, and when a shop fetched by id lands.
            controller.areaId.value;
            controller.profile.value;
            return AppHeroHeader(
              title: 'Impose a fine',
              subtitle: controller.isAreaFine
                  ? (controller.areaName ?? 'Choose the bazaar first')
                  : (controller.hasUnitDetails
                        ? controller.unitTitle
                        : 'Choose the shop first'),
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            );
          }),
          Expanded(
            child: Form(
              key: controller.formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: <Widget>[
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      // The server's own sentence, verbatim. It knows why it
                      // refused and the handset does not.
                      child: AppAlert(message: message),
                    );
                  }),
                  _TargetSection(controller: controller),
                  const SizedBox(height: 20),
                  _OffenceSection(controller: controller),
                  const SizedBox(height: 20),
                  _AmountSection(controller: controller),
                  const SizedBox(height: 20),
                  _PayerSection(controller: controller),
                  const SizedBox(height: 20),
                  _EvidenceSection(controller: controller),
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
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

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
        if (note != null) ...[
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

/// Step 1: what the fine is against, which the officer never chooses here.
///
/// Arriving from a shop's screen fines that shop, and its card is filled in
/// from the register — including the bazaar, which is what travels as
/// `area_id`. Arriving from the fine button fines a person in a bazaar, and
/// the bazaar is the one thing to pick.
class _TargetSection extends StatelessWidget {
  const _TargetSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    // What the fine is against is settled when the controller is built, so
    // this section watches nothing — the two branches below do their own.
    final bool areaFine = controller.isAreaFine;

    return _Section(
      step: '1',
      title: areaFine ? 'The bazaar' : 'The shop',
      child: areaFine
          ? _AreaPicker(controller: controller)
          : _ShopField(controller: controller),
    );
  }
}

class _ShopField extends StatelessWidget {
  const _ShopField({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Watched together, because a shop the officer arrived with answers the
      // first question without touching either of the others.
      controller.profile.value;
      final bool isLoading = controller.isLoadingProfile.value;

      if (controller.hasUnitDetails) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ShopCard(controller: controller),
            // Every fine names a bazaar. The unit's own answers for it, and
            // this is the shop whose record cannot.
            if (controller.targetAreaId == null) ...<Widget>[
              const SizedBox(height: 12),
              _AreaPicker(controller: controller),
            ],
          ],
        );
      }

      if (isLoading) {
        return const AppCard(child: AppText.body('Loading the shop…'));
      }

      final String? error = controller.profileError.value;
      if (error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppAlert(message: error),
            const SizedBox(height: 10),
            AppButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: controller.loadProfile,
            ),
          ],
        );
      }

      // The route named a unit the server would not give up. Nothing here can
      // stand in for it, and a fine against an unknown shop is not one to send.
      return const AppAlert(
        message:
            'This shop could not be loaded, so a fine cannot be raised '
            'against it yet.',
      );
    });
  }
}

/// The bazaar the fine names, searched for by name or code among the ones the
/// register lists for this officer.
///
/// `area_id` is required on every fine, so when the register lists none at all
/// the officer types the id rather than being stopped here.
class _AreaPicker extends StatelessWidget {
  const _AreaPicker({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final FieldArea? chosen = controller.chosenArea;
      if (chosen != null) return _ChosenArea(controller: controller);

      final List<int> options = controller.areaOptions;
      if (options.isEmpty && controller.isLoadingAreas) {
        return const AppCard(child: AppText.body('Loading your bazaars…'));
      }

      // No rows to search: the officer names the bazaar by its id, and the
      // retry is there for the beat that would not load behind it.
      if (options.isEmpty) {
        final String? error = controller.areasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (error != null) ...<Widget>[
              AppAlert(message: error),
              const SizedBox(height: 12),
            ],
            AppTextField(
              label: 'Bazaar id',
              hint: 'e.g. 1',
              controller: controller.areaIdController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              prefixIcon: Icons.location_on_outlined,
              validator: (_) =>
                  controller.validateArea(controller.targetAreaId),
              onChanged: controller.setAreaFromText,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Load the bazaars',
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: controller.reloadAreas,
            ),
          ],
        );
      }

      final List<FieldArea> matches = controller.areaMatches;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSearchField(
            controller: controller.areaSearchController,
            hint: 'Search the bazaar',
            onChanged: controller.searchArea,
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            const AppText.caption('No bazaar of yours matches that.')
          else
            for (final FieldArea area in matches.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => controller.setArea(area.id),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: AppText.body(area.areaName)),
                      if (area.zoneName != null)
                        AppText.caption(area.zoneName!),
                    ],
                  ),
                ),
              ),
        ],
      );
    });
  }
}

/// The bazaar once it is settled — one line, and the way back to the search.
class _ChosenArea extends StatelessWidget {
  const _ChosenArea({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final FieldArea? area = controller.chosenArea;

    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.location_on_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText.titleMedium(
              area?.areaName ?? controller.areaLabel(controller.targetAreaId!),
            ),
          ),
          TextButton(
            onPressed: controller.clearArea,
            child: const AppText.label('Change'),
          ),
        ],
      ),
    );
  }
}

/// The shop the fine is against, as the register has it: which unit, which
/// bazaar — the one that becomes `area_id` — and who holds it.
///
/// Drawn from the unit card the officer arrived with, or from the profile
/// fetched behind a route that carried only an id.
class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    final String? bazaar = controller.unitBazaar;
    final String? code = controller.unitCode;
    final String? address = controller.unitAddress;
    final String? outstanding = controller.unitOutstanding;
    final String? holder = controller.allotteeName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.storefront_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(controller.unitTitle),
                    const SizedBox(height: 2),
                    AppText.caption(
                      // "Vacant" is not the same fact as "owes nothing", so
                      // the two never share a line.
                      controller.unitIsVacant
                          ? 'Vacant — nobody holds this unit'
                          : (holder ?? 'Held, allottee not named'),
                      color: muted,
                    ),
                  ],
                ),
              ),
              if (controller.unitIsSealed)
                const AppStatusBadge(label: 'Sealed', tone: AppTone.warning),
            ],
          ),
          const SizedBox(height: 12),
          if (code != null) AppDetailRow(icon: Icons.tag_rounded, value: code),
          if (bazaar != null)
            AppDetailRow(icon: Icons.location_on_outlined, value: bazaar),
          if (address != null)
            AppDetailRow(
              icon: Icons.place_outlined,
              value: address,
              maxLines: 2,
            ),
          if (outstanding != null)
            // Rent arrears, and a fine is a separate debt: the two figures are
            // never added together.
            AppDetailRow(
              icon: Icons.account_balance_wallet_outlined,
              value:
                  '${Formatters.money(outstanding) ?? outstanding} owed in rent',
            ),
        ],
      ),
    );
  }
}

class _OffenceSection extends StatelessWidget {
  const _OffenceSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '2',
      title: 'The offence',
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _OffencePicker(controller: controller),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Provision of law',
              hint: 'e.g. Section 96, Balochistan LG Act 2010',
              controller: controller.provisionController,
              validator: controller.validateProvision,
              onChanged: (_) => controller.markEdited(),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// The offences MCQ's register carries, with the amount and the section of law
/// it suggests for each. Never a list written into the app: these are rows MCQ
/// can rename, reprice and switch off.
class _OffencePicker extends StatelessWidget {
  const _OffencePicker({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<FineTypeDefinition> types = controller.fineTypes;

      if (types.isEmpty) {
        if (controller.isLoadingOffences) {
          return const AppText.body('Loading the offence list…');
        }
        final String? error = controller.offencesError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppAlert(
              message:
                  error ??
                  'The offence list has not been loaded, so a fine cannot be '
                      'raised yet.',
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: controller.reloadOffences,
            ),
          ],
        );
      }

      final FineTypeDefinition? chosen = controller.fineType.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppDropdown<FineTypeDefinition>(
            // The rows arrive after the first build, and the choice prefills
            // two other fields — both need the field rebuilt on its value.
            key: ValueKey<int?>(chosen?.id),
            label: 'What happened',
            hint: 'Choose an offence',
            items: types,
            itemLabel: (FineTypeDefinition type) => type.name,
            value: chosen,
            validator: controller.validateFineType,
            onChanged: controller.chooseFineType,
          ),
          if (chosen != null) ...<Widget>[
            const SizedBox(height: 12),
            _OffenceDetails(type: chosen),
          ],
        ],
      );
    });
  }
}

/// Everything the register holds about the chosen offence — its Urdu wording,
/// when it applies, the section it is raised under and what it is worth.
///
/// Shown because an officer quoting a provision at a shopkeeper is reading it
/// off this screen, and because the Urdu is what they will say out loud.
class _OffenceDetails extends StatelessWidget {
  const _OffenceDetails({required this.type});

  final FineTypeDefinition type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

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
          if (type.nameUr != null)
            // Right to left, and larger than a caption: Urdu set small is not
            // readable at arm's length in the sun.
            Directionality(
              textDirection: TextDirection.rtl,
              child: AppText.titleMedium(type.nameUr!),
            ),
          if (type.description != null) ...<Widget>[
            if (type.nameUr != null) const SizedBox(height: 8),
            AppText.body(type.description!, color: muted, maxLines: 4),
          ],
          if (type.defaultProvision != null) ...<Widget>[
            const SizedBox(height: 10),
            AppDetailRow(
              icon: Icons.gavel_rounded,
              value: type.defaultProvision!,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}

/// The amount, on its own. It is the one figure argued about at a shop counter
/// and the one an officer must not mistype, so it is not left as one field
/// among four inside the offence card.
class _AmountSection extends StatelessWidget {
  const _AmountSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '3',
      title: 'The amount',
      child: Obx(() {
        // Re-read after an offence is chosen: the figure is prefilled from the
        // register, and a text controller is not observable.
        controller.revision.value;
        return FineAmountField(
          controller: controller.amountController,
          suggestion: controller.suggestedAmount,
          validator: controller.validateAmount,
          onChanged: (_) => controller.markEdited(),
        );
      }),
    );
  }
}

class _PayerSection extends StatelessWidget {
  const _PayerSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    // The server's own answer, read and not recomputed: whether there is
    // anybody on the register to bill is its judgement, not the handset's.
    // Both are settled when the controller is built, so nothing here watches.
    final needsOffender = controller.needsOffenderDetails;
    final areaFine = controller.isAreaFine;

    return _Section(
      step: '4',
      title: 'Who pays',
      note: needsOffender
          ? 'CNIC, Name, father\'s name and mobile are required together.'
          : 'Filled in from the register. Correct it if the person in front of '
                'you is somebody else.',
      // The same block whoever pays: on a shop it arrives filled in from
      // the register, and on a hawker's fine it is the only record of who
      // was fined.
      child: AppCard(
        child: Column(
          children: <Widget>[
            AppTextField(
              label: "Offender's CNIC",
              hint: needsOffender ? 'e.g. 5440011223344' : 'Optional',
              controller: controller.offenderCnicController,
              validator: controller.validateOffenderCnic,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: "Offender's name",
              controller: controller.offenderNameController,
              validator: controller.validateOffenderName,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: "Father's name",
              controller: controller.offenderFatherController,
              validator: controller.validateOffenderFather,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Mobile number',
              controller: controller.offenderMobileController,
              keyboardType: TextInputType.phone,
              validator: controller.validateOffenderMobile,
              onChanged: (_) => controller.markEdited(),
            ),
            const SizedBox(height: 18),

            AppTextField(
              label: areaFine ? 'Where they were found' : 'Address',
              hint: areaFine
                  ? 'Optional, e.g. handcart, Circular Road'
                  : 'Optional',
              controller: controller.offenderAddressController,
              maxLines: 2,
              onChanged: (_) => controller.markEdited(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.controller});

  final FineController controller;

  Future<void> _photo(BuildContext context) async {
    final outcome = await controller.attachPhoto();
    if (!context.mounted) return;
    if (outcome == PhotoOutcome.needsSettings) {
      _say(context, 'Allow the camera in Settings to attach a photograph.');
    }
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: AppText.body(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '5',
      title: 'The photograph',
      // The photograph is the only evidence this endpoint takes: a location
      // fix, a signature, a witness and remarks are not fields on a fine, so
      // the form does not collect what it cannot send.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Obx(
            // A third of the row: the tile is a square by design, and stretched
            // across the form it reads as an empty panel rather than a button.
            () => Row(
              children: <Widget>[
                Expanded(
                  child: EvidenceTile(
                    icon: Icons.photo_camera_outlined,
                    label: 'Photo',
                    busy: controller.isUploadingPhoto.value,
                    state: _photoState,
                    detail: _photoDetail,
                    onTap: controller.photoUploadedPath.value != null
                        ? controller.removePhoto
                        : (controller.photoLocalPath.value != null
                              ? controller.retryPhotoUpload
                              : () => _photo(context)),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          Obx(() {
            final path = controller.photoLocalPath.value;
            if (path == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.file(
                  File(path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  // A thumbnail that will not decode must not take the form
                  // down with it.
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  EvidenceState get _photoState {
    if (controller.photoUploadedPath.value != null) {
      return EvidenceState.attached;
    }
    if (controller.photoLocalPath.value != null) return EvidenceState.pending;
    return EvidenceState.empty;
  }

  String? get _photoDetail {
    if (controller.isUploadingPhoto.value) return 'Sending';
    if (controller.photoUploadedPath.value != null) return 'Attached';
    if (controller.photoLocalPath.value != null) return 'Retry';
    return null;
  }
}

/// The bar that stays on screen: the amount as typed, what is still missing,
/// and the button.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.controller, required this.onSubmit});

  final FineController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

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
            final amount = controller.amountController.text.trim();
            final missing = controller.missing;

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
                          AppText.caption('Fine amount', color: muted),
                          const SizedBox(height: 2),
                          // Printed exactly as typed. Never parsed, never
                          // rounded, never added to anything.
                          AppText.titleLarge(
                            amount.isEmpty ? '—' : 'Rs $amount',
                          ),
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
                  label: 'Impose a fine',
                  icon: Icons.gavel_rounded,
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
