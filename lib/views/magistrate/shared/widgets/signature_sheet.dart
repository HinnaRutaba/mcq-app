import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../widgets/widgets.dart';
import '../../../../config/theme/app_radius.dart';

/// Where a witness signs.
///
/// Opened as a sheet rather than a page so the form behind it is never lost:
/// the officer is holding the handset out to somebody else, and coming back to
/// a form that has reset itself is how a fine gets abandoned halfway.
///
/// Returns the path of a PNG written to the handset's temporary directory, or
/// null if nothing was signed. The caller uploads it and sends the path — the
/// file itself never travels on the fine.
class SignatureSheet extends StatefulWidget {
  const SignatureSheet({super.key, required this.witnessName});

  /// Shown at the top so the person signing can see whose name it is against.
  final String? witnessName;

  /// Opens the sheet and resolves to the PNG's path, or null.
  static Future<String?> show(BuildContext context, {String? witnessName}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) =>
          SignatureSheet(witnessName: witnessName),
    );
  }

  @override
  State<SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<SignatureSheet> {
  late final SignatureController _controller = SignatureController(
    // Thick enough to survive being drawn with a fingertip in sunlight.
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStroke);
  }

  void _onStroke() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onStroke);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty || _saving) return;
    setState(() => _saving = true);

    final Uint8List? png = await _controller.toPngBytes();
    if (png == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    // The systemTemp directory, not the documents directory: this file exists
    // only long enough to be uploaded, and nothing should be left behind on a
    // handset that is shared between officers.
    final File file = File(
      '${Directory.systemTemp.path}/witness_signature_'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png, flush: true);

    if (mounted) Navigator.of(context).pop(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    final signed = _controller.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppText.titleLarge('Witness signature'),
          const SizedBox(height: 4),
          AppText.body(
            widget.witnessName == null || widget.witnessName!.trim().isEmpty
                ? 'Hand the handset to the witness and ask them to sign.'
                : 'Hand the handset to ${widget.witnessName!.trim()} and ask '
                      'them to sign.',
            color: muted,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          AppText.caption(
            signed ? 'Sign above the line.' : 'Nothing signed yet.',
            color: muted,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: 'Clear',
                  variant: AppButtonVariant.outline,
                  onPressed: signed ? _controller.clear : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Attach',
                  icon: Icons.check_rounded,
                  isLoading: _saving,
                  onPressed: signed ? _save : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
