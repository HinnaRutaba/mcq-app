import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/agreement_case.dart';
import '../../../widgets/widgets.dart';
import 'widgets/stamp_paper.dart';

/// The case on stamp paper, sheet after sheet. Drawn from the case it was
/// opened with, so a cold link with none has nothing to draw.
class StampPaperScreen extends StatelessWidget {
  const StampPaperScreen({super.key, this.file});

  final AgreementCase? file;

  @override
  Widget build(BuildContext context) {
    final AgreementCase? file = this.file;
    return Scaffold(
      body: Column(
        children: <Widget>[
          AppHeroHeader(
            title: 'Stamp paper',
            subtitle: file?.intakeNo,
            leading: AppCircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          Expanded(
            child: file == null
                ? const Center(
                    child: AppEmptyState(
                      icon: Icons.description_outlined,
                      title: 'Nothing to draw',
                      message: 'Open the stamp paper from its case.',
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: StampPaperSheets(file: file),
                  ),
          ),
        ],
      ),
    );
  }
}
