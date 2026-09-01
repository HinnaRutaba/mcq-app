import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../../config/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../buttons/app_button.dart';
import '../motion/app_pressable.dart';
import '../text/app_text.dart';

/// A witness signature, taken on the handset.
///
/// The schema has carried `signature_path` since it was written, and a seal
/// with a witness signature on the record is a far stronger document than
/// one without — it costs the officer fifteen seconds at the shop front and
/// saves an argument six months later.
///
/// It is written out as a PNG and uploaded exactly like the photograph:
/// separately, first, so a failed action never loses it and a retry does
/// not ask the witness to sign again.
class AppSignaturePad {
  AppSignaturePad._();

  /// Returns the written file, or null if the officer backed out.
  static Future<File?> capture(BuildContext context) {
    return showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SignatureSheet(),
    );
  }
}

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet();

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  late final SignatureController _pad = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.lightTextPrimary,
    exportBackgroundColor: Colors.white,
  );

  bool _saving = false;

  @override
  void dispose() {
    _pad.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_pad.isEmpty) return;
    setState(() => _saving = true);
    try {
      final bytes = await _pad.toPngBytes();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (mounted) Navigator.of(context).pop(file);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              AppText.titleLarge(t('action.signature')),
              const SizedBox(height: 4),
              AppText.bodySmall(
                t('action.signatureHelp'),
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              // Always white and always left-to-right: a signature is a
              // drawing, not text, and it must look the same in Urdu.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Signature(
                    controller: _pad,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: t('action.signatureClear'),
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        _pad.clear();
                        AppHaptics.select();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: t('common.save'),
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
