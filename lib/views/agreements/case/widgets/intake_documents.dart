import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../config/theme/app_radius.dart';
import '../../../../core/network/api_service.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import 'intake_pdf_pages.dart';

/// One file on the case: its kind, its name, and a spinner while fetching.
class IntakeDocumentRow extends StatelessWidget {
  const IntakeDocumentRow({
    super.key,
    required this.doc,
    required this.opening,
    this.onTap,
  });

  final IntakeDocument doc;
  final bool opening;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final IconData icon = doc.isPdf
        ? Icons.picture_as_pdf_outlined
        : doc.isVideo
        ? Icons.videocam_outlined
        : Icons.image_outlined;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      child: Row(
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText.body(
                  doc.name,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                ),
                if (doc.filename != null && doc.filename != doc.name)
                  AppText.caption(doc.filename!, maxLines: 1),
              ],
            ),
          ),
          if (opening)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (onTap != null)
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// A fetched document, shown in place: an image to pinch, or a PDF's pages.
/// The sheet is as tall as what it holds, up to 85% of the screen.
/// Nothing is written to the phone's storage.
class IntakeDocumentSheet extends StatelessWidget {
  const IntakeDocumentSheet({
    super.key,
    required this.title,
    required this.download,
    this.imageSize,
  });

  final String title;
  final ApiDownload download;

  /// The image's pixel size, read before the sheet opens so it is laid out
  /// at its final height. Null for a PDF, or an image that would not decode.
  final Size? imageSize;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required ApiDownload download,
  }) async {
    final Size? size = isImage(download) ? await _measure(download) : null;
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext context) => IntakeDocumentSheet(
        title: title,
        download: download,
        imageSize: size,
      ),
    );
  }

  /// Reads the header only; the pixels are decoded when the sheet draws.
  static Future<Size?> _measure(ApiDownload download) async {
    try {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        download.bytes,
      );
      final ui.ImageDescriptor d = await ui.ImageDescriptor.encoded(buffer);
      final Size size = Size(d.width.toDouble(), d.height.toDouble());
      d.dispose();
      buffer.dispose();
      return size.isEmpty ? null : size;
    } catch (_) {
      return null;
    }
  }

  static bool isImage(ApiDownload download) =>
      download.isImage ||
      (!download.isPdf &&
          download.bytes.isNotEmpty &&
          _looksLikeImage(download.bytes));

  /// JPEG, PNG and WebP magic numbers, for a server that sent no type.
  static bool _looksLikeImage(List<int> b) {
    if (b.length < 4) return false;
    return (b[0] == 0xFF && b[1] == 0xD8) ||
        (b[0] == 0x89 && b[1] == 0x50) ||
        (b[0] == 0x52 && b[1] == 0x49);
  }

  @override
  Widget build(BuildContext context) {
    final int kb = (download.bytes.length / 1024).ceil();
    final Size? size = imageSize;

    final Widget body;
    if (!isImage(download)) {
      body = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: IntakePdfPages(
          bytes: download.bytes,
          sourceName: '$title#$kb',
          title: title,
        ),
      );
    } else if (size == null) {
      body = const _Unshown();
    } else {
      // Never wider than the file itself, so a small image is not blown up.
      body = Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        // heightFactor 1: hug the image rather than fill the sheet.
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: size.width),
            child: AspectRatio(
              aspectRatio: size.width / size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Image.memory(
                    download.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const _Unshown(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
            child: Row(
              children: <Widget>[
                AppCircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  background: scheme.surfaceContainerHighest,
                  iconColor: scheme.onSurface,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(child: AppText.titleMedium(title, maxLines: 1)),
              ],
            ),
          ),
          Flexible(child: body),
        ],
      ),
    );
  }
}

class _Unshown extends StatelessWidget {
  const _Unshown();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 32),
    child: AppEmptyState(
      icon: Icons.broken_image_outlined,
      title: 'Could not show this file',
    ),
  );
}
