import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import 'intake_pdf_pages.dart';
import 'stamp_paper.dart';

/// The Preview tab: the server's stamp paper PDF when it has rendered one,
/// the stamp paper drawn from the case fields when it has not.
class IntakeAgreementPreview extends StatelessWidget {
  const IntakeAgreementPreview({
    super.key,
    required this.file,
    required this.bytes,
    required this.loading,
    required this.onRetry,
    this.error,
  });

  final AgreementCase file;
  final Uint8List? bytes;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final IntakeAgreementPdf? pdf = file.agreementPdf;
    if (pdf == null || !pdf.canView) return StampPaperSheets(file: file);

    final Uint8List? bytes = this.bytes;
    final String? error = this.error;
    final Widget body;
    if (bytes != null) {
      body = IntakePdfPages(
        bytes: bytes,
        sourceName: _source(pdf, bytes),
        title: _title(pdf),
      );
    } else if (error != null && !loading) {
      body = AppErrorRetry(
        title: 'Could not fetch the agreement',
        message: error,
        onRetry: onRetry,
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 14),
            AppText.caption('Fetching the agreement…'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (bytes != null) ...<Widget>[
          const AppText.caption(
            'Tap the agreement to open it full screen.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        body,
      ],
    );
  }

  // Length too: a re-rendered draft keeps its address.
  static String _source(IntakeAgreementPdf pdf, Uint8List bytes) =>
      '${pdf.viewUrl}#${bytes.length}';

  static String _title(IntakeAgreementPdf pdf) =>
      pdf.isDraft ? 'Stamp paper (draft)' : 'Stamp paper';
}
