import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../controllers/fine_controller.dart';
import '../../../core/utils/dialer.dart';
import '../../../core/utils/reveal_banner.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/capture/photo_capture.dart';
import '../../../models/enforcement_definitions.dart';
import '../../../models/field_beat.dart';
import '../../../models/unit_card.dart';
import '../../../widgets/widgets.dart';
import 'widgets/area_search_field.dart';
import 'widgets/evidence_tile.dart';
import 'widgets/amount_field.dart';
import 'widgets/person_cnic_field.dart';
import 'widgets/fine_imposed_sheet.dart';
import 'widgets/still_needed_note.dart';
import '../../../config/theme/app_radius.dart';

class CreateFineScreen extends StatefulWidget {
  const CreateFineScreen({
    super.key,
    this.unit,
    this.propertyId,
    this.allotmentId,
  });

  /// The shop, when the officer came from its profile.
  final UnitCard? unit;

  /// Its id, when only that was carried on the route.
  final int? propertyId;

  /// The tenancy on it, carried alongside the id from the shop's profile. It
  /// is what the fine is billed to.
  final int? allotmentId;

  @override
  State<CreateFineScreen> createState() => _CreateFineScreenState();
}

class _CreateFineScreenState extends State<CreateFineScreen> {
  late final FineController controller = Get.put(
    FineController(
      unit: widget.unit,
      propertyId: widget.propertyId,
      allotmentId: widget.allotmentId,
    ),
  );

  /// The form's own scroll, so a refusal can be scrolled back to.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
      return;
    }

    // A refusal is already on the form: the banner carries the server's own
    // sentence and the per-field messages are back under their fields. Only
    // the banner needs finding — it is at the top and the officer is at the
    // bottom. A form that failed on its fields alone is left where it is,
    // because the message they need is beside the field, not up there.
    if (controller.errorMessage.value != null) {
      _scrollController.revealBanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Obx(() {
            // Watched, not merely read: the line under the title changes when
            // the officer picks a area, and when a shop fetched by id lands.
            controller.areaId.value;
            controller.profile.value;
            return AppHeroHeader(
              title: 'Impose a fine',
              subtitle: controller.isAreaFine
                  ? (controller.areaName ?? 'Choose the area first')
                  : (controller.hasUnitDetails
                        ? controller.unitTitle
                        : 'Choose the shop first'),
              leading: AppCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            );
          }),
          Expanded(
            child: Form(
              key: controller.formKey,
              child: ListView(
                controller: _scrollController,
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
                  if (controller.takesRemarks) ...<Widget>[
                    const SizedBox(height: 20),
                    _RemarksSection(controller: controller),
                  ],
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
/// from the register — including the area, which is what travels as
/// `area_id`. Arriving from the fine button fines a person in a area, and
/// the area is the one thing to pick.
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
      title: areaFine ? 'The area' : 'The shop',
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
            // Every fine names a area. The unit's own answers for it, and
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

class _AreaPicker extends StatelessWidget {
  const _AreaPicker({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<int> options = controller.areaOptions;
      if (options.isEmpty && controller.isLoadingAreas) {
        return const AppCard(child: AppText.body('Loading your areas…'));
      }

      // No rows to search: the officer names the area by its id, and the
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
              label: 'Area id',
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
              label: 'Load the areas',
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: controller.reloadAreas,
            ),
          ],
        );
      }

      // The matches belong to the box, not to the form: they open under it
      // and close with it.
      return AreaSearchField(
        controller: controller.areaSearchController,
        optionsFor: controller.areaMatchesFor,
        onChanged: controller.searchArea,
        onSelected: (FieldArea area) => controller.setArea(area.id),
        selected: controller.chosenArea,
        onCleared: controller.clearArea,
        note: 'The fine will be posted here',
      );
    });
  }
}

/// The shop the fine is against, as the register has it: which unit, which
/// area — the one that becomes `area_id` — and who holds it.
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

    final String? area = controller.unitArea;
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
          if (area != null)
            AppDetailRow(icon: Icons.location_on_outlined, value: area),
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
      // The section of law is not asked for: it belongs to the offence, and
      // the register's own is shown under the choice — see [_OffenceDetails].
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: _OffencePicker(controller: controller),
      ),
    );
  }
}

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
            // the amount — both need the field rebuilt on its value.
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
            // Only when the register holds something about it: an offence it
            // carries nothing for would draw an empty panel.
            if (_OffenceDetails.hasSomethingToSay(chosen)) ...<Widget>[
              const SizedBox(height: 12),
              _OffenceDetails(type: chosen),
            ],
            // The one offence that cannot be fined from the field. Said here
            // rather than left to the disabled button, because the way out is
            // to choose a different offence.
            if (chosen.defaultProvision == null) ...<Widget>[
              const SizedBox(height: 12),
              const AppAlert(
                tone: AppTone.warning,
                icon: Icons.gavel_rounded,
                message:
                    'The register gives no section of law for this offence, '
                    'and a fine without one cannot be enforced. Choose '
                    'another offence.',
              ),
            ],
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

  /// Whether the register holds anything about [type] worth a panel.
  static bool hasSomethingToSay(FineTypeDefinition type) =>
      type.nameUr != null ||
      type.description != null ||
      type.defaultProvision != null;

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
            // Said as the fine will read, because this is the provision that
            // travels — the form no longer asks anyone to type one.
            AppDetailRow(
              icon: Icons.gavel_rounded,
              value: 'Raised under ${type.defaultProvision}',
              maxLines: 3,
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
        return AmountField(
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
    return Obx(() {
      // Read in the builder: behind a route that carried only an id, the
      // person to bill arrives with the profile long after this is first drawn.
      controller.profile.value;

      // The server's own answer, read and not recomputed: whether there is
      // anybody on the register to bill is its judgement, not the handset's.
      final bool needsOffender = controller.needsOffenderDetails;

      final Widget child;
      final String note;
      if (controller.hasRegisteredPayer) {
        child = _RegisteredPayerCard(controller: controller);
        note = 'Billed to the tenancy, as the register holds it.';
      } else if (!needsOffender && controller.isLoadingProfile.value) {
        child = const AppCard(child: AppText.body('Reading the register…'));
        note = 'Finding who holds this shop.';
      } else {
        child = _PayerFields(controller: controller);
        note = needsOffender
            ? 'CNIC, Name, father\'s name and mobile are required together.'
            : 'Filled in from the register. Correct it if the person in front '
                  'of you is somebody else.';
      }

      return _Section(step: '4', title: 'Who pays', note: note, child: child);
    });
  }
}

/// Who the register holds the shop under — shown, not asked for.
///
/// The fine is posted against the tenancy, so the identity behind it is a
/// record to read back at the counter rather than four fields to retype.
class _RegisteredPayerCard extends StatelessWidget {
  const _RegisteredPayerCard({required this.controller});

  final FineController controller;

  static const Dialer _dialer = Dialer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    final String? father = controller.allotteeFatherName;
    final String? cnic = controller.allotteeCnic;
    final String? mobile = controller.allotteeMobile;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.person_outline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText.titleMedium(
                      controller.allotteeName ?? 'Held, allottee not named',
                    ),
                    const SizedBox(height: 2),
                    AppText.caption('On the property register', color: muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (father != null)
            AppDetailRow(
              icon: Icons.people_outline_rounded,
              value: 'S/O $father',
              maxLines: 2,
            ),
          if (cnic != null)
            AppDetailRow(icon: Icons.credit_card_outlined, value: cnic),
          if (mobile != null)
            AppDetailRow(
              icon: Icons.phone_outlined,
              value: mobile,
              // A number on screen is worth nothing without a way to dial it.
              trailing: AppButton(
                label: 'Call',
                icon: Icons.phone_outlined,
                variant: AppButtonVariant.outline,
                fullWidth: false,
                height: 34,
                onPressed: () => _dialer.call(mobile),
              ),
            ),
        ],
      ),
    );
  }
}

/// The payer named by hand — a hawker, a handcart, somebody trading out of a
/// unit nobody holds. On that fine this block is the only record of who was
/// fined.
class _PayerFields extends StatelessWidget {
  const _PayerFields({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          PersonCnicField(
            controller: controller.personLookup,
            label: "Offender's CNIC",
            hint: "e.g. 5440011223344",
            validator: controller.validateOffenderCnic,
            onChanged: (_) => controller.markEdited(),
            onTaken: controller.takePerson,
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
        ],
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
      // fix, a signature and a witness are not fields on a fine, so the form
      // does not collect what it cannot send.
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

/// The officer's own words, on a fine raised from a shop's profile. Optional,
/// and last: a note is written after the offence, the amount and the person
/// are settled, not before.
class _RemarksSection extends StatelessWidget {
  const _RemarksSection({required this.controller});

  final FineController controller;

  @override
  Widget build(BuildContext context) {
    return _Section(
      step: '6',
      title: 'Remarks',
      note:
          'Optional. Anything a clerk reading this fine later would need to '
          'know.',
      child: AppCard(
        child: AppTextField(
          hint: 'e.g. Refused to remove the display after two warnings',
          controller: controller.remarksController,
          maxLines: 3,
          validator: controller.validateRemarks,
          onChanged: (_) => controller.markEdited(),
        ),
      ),
    );
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
                // A total line: the label on the left, the figure at the
                // right edge where a reader looks for it.
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppText.caption('Fine amount', color: muted),
                    ),
                    // Printed exactly as typed. Never parsed, never rounded,
                    // never added to anything.
                    AppText.titleLarge(amount.isEmpty ? '—' : 'Rs $amount'),
                  ],
                ),
                // A row of its own, and every missing field named: the
                // shortened version told an officer the button would not press
                // without telling them what to do about it.
                if (missing.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  StillNeededNote(missing: missing),
                ],
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
