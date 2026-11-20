import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_radius.dart';
import '../../../../models/agreement_case.dart';
import '../../../../models/intake_attachments.dart';
import '../../../../widgets/widgets.dart';
import 'intake_documents.dart';

/// A flag stuck to the screen's right edge. Tapped, it slides out as a drawer
/// with the case's files grouped by whose they are.
class IntakeAttachmentsDrawer extends StatefulWidget {
  const IntakeAttachmentsDrawer({
    super.key,
    required this.open,
    required this.onChanged,
    required this.groups,
    required this.onOpen,
    required this.child,
    this.openingUrl,
  });

  final bool open;
  final ValueChanged<bool> onChanged;

  /// Empty hides the flag — there is no case to read yet.
  final List<IntakeAttachmentGroup> groups;
  final ValueChanged<IntakeDocument> onOpen;
  final String? openingUrl;
  final Widget child;

  @override
  State<IntakeAttachmentsDrawer> createState() =>
      _IntakeAttachmentsDrawerState();
}

class _IntakeAttachmentsDrawerState extends State<IntakeAttachmentsDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
    value: widget.open ? 1 : 0,
  );

  late final Animation<double> _slide = CurvedAnimation(
    parent: _motion,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(IntakeAttachmentsDrawer old) {
    super.didUpdateWidget(old);
    if (widget.open != old.open) {
      widget.open ? _motion.forward() : _motion.reverse();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged(!widget.open);

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return widget.child;
    final double width = math.min(MediaQuery.sizeOf(context).width * 0.86, 380);
    final int count = widget.groups.fold<int>(
      0,
      (int sum, IntakeAttachmentGroup g) => sum + g.docs.length,
    );

    // Back closes the drawer before it leaves the case.
    return PopScope(
      canPop: !widget.open,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) widget.onChanged(false);
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          AnimatedBuilder(
            animation: _slide,
            builder: (BuildContext context, _) {
              final double t = _slide.value;
              return Stack(
                children: <Widget>[
                  if (t > 0)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => widget.onChanged(false),
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.42 * t),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: -width * (1 - t),
                    width: width + _Flag.width,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Align(
                          alignment: const Alignment(0, 0.1),
                          child: _Flag(
                            count: count,
                            open: widget.open,
                            onTap: _toggle,
                          ),
                        ),
                        Expanded(
                          // Offstage when shut, so its rows take no taps.
                          child: t == 0
                              ? const SizedBox.shrink()
                              : _Panel(
                                  count: count,
                                  groups: widget.groups,
                                  onOpen: widget.onOpen,
                                  openingUrl: widget.openingUrl,
                                  onClose: () => widget.onChanged(false),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.count, required this.open, required this.onTap});

  /// Inside the cards' 30px text inset, so it never covers a value.
  static const double width = 28;

  final int count;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fill = scheme.primary;
    final Color ink = scheme.onPrimary;
    return Semantics(
      button: true,
      label: open ? 'Close attachments' : 'Attachments, $count files',
      child: AppPress(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.md),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(-2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                open ? Icons.chevron_right_rounded : Icons.attach_file_rounded,
                size: 16,
                color: ink,
              ),
              const SizedBox(height: 8),
              RotatedBox(
                quarterTurns: 3,
                child: AppText(
                  'Attachments',
                  variant: AppTextVariant.labelLarge,
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // A circle inside the flag; three digits shrink rather than spill.
              Container(
                height: 20,
                width: 20,
                padding: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText(
                    '$count',
                    variant: AppTextVariant.labelSmall,
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.count,
    required this.groups,
    required this.onOpen,
    required this.onClose,
    this.openingUrl,
  });

  final int count;
  final List<IntakeAttachmentGroup> groups;
  final ValueChanged<IntakeDocument> onOpen;
  final VoidCallback onClose;
  final String? openingUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const AppText.titleLarge('Attachments', maxLines: 1),
                        AppText.caption(
                          '$count ${count == 1 ? 'file' : 'files'} on this case',
                        ),
                      ],
                    ),
                  ),
                  AppCircleIconButton(
                    icon: Icons.close_rounded,
                    size: 38,
                    background: theme.colorScheme.surfaceContainerHighest,
                    iconColor: theme.colorScheme.onSurface,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (BuildContext context, int i) => _Group(
                  group: groups[i],
                  onOpen: onOpen,
                  openingUrl: openingUrl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A heading that folds its files away. Starts open.
class _Group extends StatefulWidget {
  const _Group({required this.group, required this.onOpen, this.openingUrl});

  final IntakeAttachmentGroup group;
  final ValueChanged<IntakeDocument> onOpen;
  final String? openingUrl;

  @override
  State<_Group> createState() => _GroupState();
}

class _GroupState extends State<_Group> with AutomaticKeepAliveClientMixin {
  bool _open = true;

  // Scrolled out of the list, a folded group stays folded.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final IntakeAttachmentGroup group = widget.group;
    final String? openingUrl = widget.openingUrl;
    final Color? muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? subtitle = group.subtitle;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        if (group.docs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: _mark + 10, bottom: 4),
            child: AppText.caption('Nothing attached.', color: muted),
          )
        else
          for (final IntakeDocument doc in group.docs) ...<Widget>[
            IntakeDocumentRow(
              doc: doc,
              opening: openingUrl != null && openingUrl == doc.url,
              // A video is listed, never opened: there is no player yet.
              onTap: doc.isVideo || !doc.canOpen
                  ? null
                  : () => widget.onOpen(doc),
            ),
            const SizedBox(height: 8),
          ],
        if (group.note != null)
          Padding(
            padding: const EdgeInsets.only(left: _mark + 10),
            child: AppText.caption(group.note!, color: muted),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  // Solid and round, so it reads as a heading, not a file.
                  Container(
                    height: _mark,
                    width: _mark,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icon(group.owner),
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppText.body(
                          group.title,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                        ),
                        if (subtitle != null)
                          AppText.caption(subtitle, color: muted, maxLines: 1),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 28),
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: AppText.body(
                      '${group.docs.length}',
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 24,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open ? body : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  static const double _mark = 30;

  static IconData _icon(IntakeAttachmentOwner owner) => switch (owner) {
    IntakeAttachmentOwner.applicant => Icons.person_rounded,
    IntakeAttachmentOwner.witness => Icons.badge_rounded,
    IntakeAttachmentOwner.supporting => Icons.folder_copy_rounded,
    IntakeAttachmentOwner.agreement => Icons.description_rounded,
  };
}
