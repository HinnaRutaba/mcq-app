import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart'
    show
        PdfDocument,
        PdfDocumentRefData,
        PdfDocumentViewBuilder,
        PdfPage,
        PdfPageView;

import '../../../../widgets/widgets.dart';
import '../pdf_reader_screen.dart';

/// A PDF held in memory, page under page. A phone-width A4 page is too small
/// to read, so a tap anywhere on it opens the whole document full screen.
/// Nothing is written to the phone's storage.
class IntakePdfPages extends StatelessWidget {
  const IntakePdfPages({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.title,
    this.maxWidth = 600,
  });

  final Uint8List bytes;

  /// Keys the parsed document; a new file needs a new name.
  final String sourceName;

  /// Heads the full-screen reader a tap opens.
  final String title;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return PdfDocumentViewBuilder(
      documentRef: PdfDocumentRefData(bytes, sourceName: sourceName),
      errorBuilder: (BuildContext context, Object error, _) =>
          const AppEmptyState(
            icon: Icons.broken_image_outlined,
            title: 'Could not open this PDF',
            message: 'The file came back, but it is not a PDF the phone reads.',
          ),
      builder: (BuildContext context, PdfDocument? document) {
        if (document == null) return const _Opening();
        // One tap target for the whole document, not page by page.
        return Semantics(
          button: true,
          label: 'Open $title full screen',
          child: AppPress(
            scale: 0.98,
            onTap: () => PdfReaderScreen.open(
              context,
              bytes: bytes,
              sourceName: sourceName,
              title: title,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final PdfPage page in document.pages) ...<Widget>[
                  if (page.pageNumber > 1) const SizedBox(height: 16),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: page.width / page.height,
                          child: PdfPageView(
                            document: document,
                            pageNumber: page.pageNumber,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(child: CircularProgressIndicator()),
  );
}
