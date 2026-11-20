import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../models/agreement_case.dart';
import '../../../../widgets/widgets.dart';
import '../../shared/intake_labels.dart';
import 'intake_overview.dart';

/// One sheet of the case drawn onto stamp paper: the printed header on the
/// first, the case's fields, and the allottee's thumb and signature at the foot
/// of every one. A draft from the data — the approved wording is the web's.
class StampPaperSheet {
  const StampPaperSheet._(this.index, this.count, this._blocks);

  static const String headerAsset = 'assets/stamp-paper-header.png';

  /// A sheet in logical units, A4's proportions. Drawn at this size and scaled
  /// to fit, so the text wraps — and the pages break — the same on any screen.
  static const Size size = Size(320, 452.5);

  final int index;
  final int count;
  final List<_Block> _blocks;

  bool get isFirst => index == 0;

  /// The case's fields, flowed over as many sheets as they take.
  static List<StampPaperSheet> lay(BuildContext context, AgreementCase file) {
    final _Ink ink = _Ink(context);
    final List<_Block> blocks = _compose(file);
    final List<double> heights = <double>[
      for (final _Block block in blocks) block.height(ink, _bodyWidth),
    ];

    final List<List<_Block>> sheets = <List<_Block>>[<_Block>[]];
    double left = _bodyHeight(first: true);
    for (int i = 0; i < blocks.length; i++) {
      // A run of kept blocks — a heading and its first line, a whole witness
      // and the line they sign — goes over as one.
      double need = heights[i];
      for (int j = i; blocks[j].keepWithNext && j + 1 < blocks.length; j++) {
        need += heights[j + 1];
      }
      if (need > left && sheets.last.isNotEmpty) {
        sheets.add(<_Block>[]);
        left = _bodyHeight(first: false);
      }
      sheets.last.add(blocks[i]);
      left -= heights[i];
    }
    return <StampPaperSheet>[
      for (int i = 0; i < sheets.length; i++)
        StampPaperSheet._(i, sheets.length, sheets[i]),
    ];
  }

  static const double _side = 22;
  static const double _top = 26;
  static const double _topUnderHeader = 8;
  static const double _footer = 74;
  static const double _bottom = 12;
  static const double _headerHeight = 320 * 356 / 656;

  /// Room left for a hair of rounding between the measure and the page.
  static const double _slack = 4;

  static double get _bodyWidth => size.width - _side * 2;

  static double _bodyHeight({required bool first}) =>
      size.height -
      (first ? _headerHeight + _topUnderHeader : _top) -
      _footer -
      _bottom -
      _slack;

  static List<_Block> _compose(AgreementCase file) {
    final IntakeApplicant? applicant = file.applicant;
    final IntakeShop shop = file.shop;
    return <_Block>[
      _Title(
        'COUNTER AGREEMENT',
        <String>[
          ?file.caseType?.label,
          if (file.intakeNo != null) 'Case no ${file.intakeNo}',
          if (file.contentRevision != null) 'Revision ${file.contentRevision}',
        ].join('  ·  '),
      ),
      ..._section('FIRST PARTY', <String, String?>{
        'Name': 'Metropolitan Corporation Quetta',
      }),
      ..._section('SECOND PARTY — ALLOTTEE', <String, String?>{
        'Name': applicant?.name,
        'Father’s name': applicant?.fatherName,
        'CNIC': applicant?.cnic,
        'Mobile': applicant?.mobile,
        'Business': applicant?.business,
        'NTN': applicant?.ntn,
        'Address': applicant?.address,
      }),
      ..._section('PREMISES', <String, String?>{
        'Shop no': shop.shopNo,
        'Market': shop.market,
        'Area': shop.area,
        'Zone': shop.zone,
        'Address': shop.address,
      }),
      ..._section('TERMS', <String, String?>{
        for (final MapEntry<String, String> line in file.amounts.entries)
          IntakeLabels.humanise(line.key): IntakeMoney.show(line.value),
      }),
      for (final IntakeWitness witness in file.witnesses) ...<_Block>[
        ..._section(
          'WITNESS ${witness.position ?? ''}'.trim(),
          <String, String?>{
            'Name': witness.name,
            'Father’s name': witness.fatherName,
            'CNIC': witness.cnic,
          },
          together: true,
        ),
        const _SignLine('Signature of witness'),
      ],
    ];
  }

  /// A heading and its facts, or nothing when every fact is missing.
  /// [together] keeps the facts on one sheet with whatever follows them.
  static List<_Block> _section(
    String heading,
    Map<String, String?> facts, {
    bool together = false,
  }) {
    final List<_Block> lines = <_Block>[
      for (final MapEntry<String, String?> fact in facts.entries)
        if (fact.value != null && fact.value!.trim().isNotEmpty)
          _Fact(fact.key, fact.value!, keep: together),
    ];
    return lines.isEmpty
        ? const <_Block>[]
        : <_Block>[_Heading(heading), ...lines];
  }
}

/// One sheet, scaled to the width it is given.
class StampPaperPage extends StatelessWidget {
  const StampPaperPage({super.key, required this.file, required this.sheet});

  final AgreementCase file;
  final StampPaperSheet sheet;

  @override
  Widget build(BuildContext context) {
    final _Ink ink = _Ink(context);
    final Size size = StampPaperSheet.size;
    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: size,
          // The sheet's type is set at its own size: the reader's text scale
          // and bold-text setting would break pages the measure did not.
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling, boldText: false),
            child: Theme(
              data: Theme.of(context).copyWith(textTheme: ink.theme),
              child: DefaultTextStyle(
                style: ink.base,
                child: ColoredBox(
                  color: AppColors.paper,
                  child: _Sheet(file: file, sheet: sheet),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.file, required this.sheet});

  final AgreementCase file;
  final StampPaperSheet sheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (sheet.isFirst)
          Image.asset(
            StampPaperSheet.headerAsset,
            height: StampPaperSheet._headerHeight,
            fit: BoxFit.fill,
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              StampPaperSheet._side,
              sheet.isFirst
                  ? StampPaperSheet._topUnderHeader
                  : StampPaperSheet._top,
              StampPaperSheet._side,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final _Block block in sheet._blocks) block.build(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StampPaperSheet._side,
            0,
            StampPaperSheet._side,
            StampPaperSheet._bottom,
          ),
          child: _Footer(file: file, sheet: sheet),
        ),
      ],
    );
  }
}

/// The allottee's thumb impression and signature, on every sheet.
class _Footer extends StatelessWidget {
  const _Footer({required this.file, required this.sheet});

  final AgreementCase file;
  final StampPaperSheet sheet;

  @override
  Widget build(BuildContext context) {
    final IntakeApplicant? applicant = file.applicant;
    final String who = <String>[
      ?applicant?.name,
      if (applicant?.cnic != null) 'CNIC ${applicant!.cnic}',
    ].join('  ·  ');
    return SizedBox(
      height: StampPaperSheet._footer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const ColoredBox(
            color: AppColors.paperRule,
            child: SizedBox(height: 0.8),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.paperRule,
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 26,
                      color: AppColors.paperRule.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const AppText('Thumb impression', variant: _Ink.small),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const ColoredBox(
                      color: AppColors.paperInk,
                      child: SizedBox(height: 0.8, width: double.infinity),
                    ),
                    const SizedBox(height: 3),
                    const AppText('Signature of allottee', variant: _Ink.small),
                    if (who.isNotEmpty)
                      AppText(
                        who,
                        variant: _Ink.small,
                        color: AppColors.paperInk,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  AppText(
                    'Page ${sheet.index + 1} of ${sheet.count}',
                    variant: _Ink.small,
                    color: AppColors.paperInk,
                  ),
                  AppText(
                    'Draft · ${file.intakeNo ?? 'Case ${file.id}'}',
                    variant: _Ink.small,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The sheet's type: fixed sizes, set as a text theme so [AppText] draws it
/// and [measure] reads the very same styles.
class _Ink {
  _Ink(BuildContext context) {
    final TextStyle root =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    TextStyle s(
      double size,
      FontWeight weight,
      Color color, [
      double spacing = 0,
    ]) => root.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.3,
      letterSpacing: spacing,
      decoration: TextDecoration.none,
    );
    base = s(9, FontWeight.w500, AppColors.paperInk);
    theme = TextTheme(
      titleMedium: s(13, FontWeight.w800, AppColors.paperNavy, 1.6),
      labelLarge: s(8.5, FontWeight.w800, AppColors.paperNavy, 1.1),
      bodyMedium: s(9, FontWeight.w600, AppColors.paperInk),
      bodySmall: s(8, FontWeight.w500, AppColors.paperInkMuted),
      labelSmall: s(7, FontWeight.w500, AppColors.paperInkMuted),
    );
  }

  static const AppTextVariant title = AppTextVariant.titleMedium;
  static const AppTextVariant heading = AppTextVariant.labelLarge;
  static const AppTextVariant value = AppTextVariant.bodyMedium;
  static const AppTextVariant label = AppTextVariant.bodySmall;
  static const AppTextVariant small = AppTextVariant.labelSmall;

  late final TextStyle base;
  late final TextTheme theme;

  TextStyle? _style(AppTextVariant variant) => switch (variant) {
    AppTextVariant.titleMedium => theme.titleMedium,
    AppTextVariant.labelLarge => theme.labelLarge,
    AppTextVariant.bodyMedium => theme.bodyMedium,
    AppTextVariant.bodySmall => theme.bodySmall,
    _ => theme.labelSmall,
  };

  /// The height [AppText] will lay [text] out at — merged with the sheet's
  /// default style exactly as [Text] merges it.
  double measure(
    String text,
    AppTextVariant variant,
    double width, {
    int? maxLines,
    TextAlign align = TextAlign.start,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: base.merge(_style(variant))),
      textDirection: TextDirection.ltr,
      textAlign: align,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: width);
    final double height = painter.height;
    painter.dispose();
    return height;
  }
}

/// One unbreakable run of the sheet's body. [height] and [build] share their
/// numbers, so the page breaks where the sheet actually fills.
sealed class _Block {
  const _Block();

  bool get keepWithNext => false;

  double height(_Ink ink, double width);

  Widget build();
}

class _Title extends _Block {
  const _Title(this.title, this.subtitle);

  final String title;
  final String subtitle;

  static const double _above = 4;
  static const double _between = 2;
  static const double _below = 4;

  @override
  double height(_Ink ink, double width) =>
      _above +
      ink.measure(title, _Ink.title, width, align: TextAlign.center) +
      (subtitle.isEmpty
          ? 0
          : _between +
                ink.measure(
                  subtitle,
                  _Ink.label,
                  width,
                  align: TextAlign.center,
                )) +
      _below;

  @override
  Widget build() => Padding(
    padding: const EdgeInsets.only(top: _above, bottom: _below),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppText(title, variant: _Ink.title, textAlign: TextAlign.center),
        if (subtitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: _between),
          AppText(subtitle, variant: _Ink.label, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}

class _Heading extends _Block {
  const _Heading(this.text);

  final String text;

  static const double _above = 9;
  static const double _gap = 2;
  static const double _rule = 0.8;
  static const double _below = 4;

  @override
  bool get keepWithNext => true;

  @override
  double height(_Ink ink, double width) =>
      _above + ink.measure(text, _Ink.heading, width) + _gap + _rule + _below;

  @override
  Widget build() => Padding(
    padding: const EdgeInsets.only(top: _above, bottom: _below),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppText(text, variant: _Ink.heading),
        const SizedBox(height: _gap),
        const ColoredBox(
          color: AppColors.paperNavy,
          child: SizedBox(height: _rule),
        ),
      ],
    ),
  );
}

class _Fact extends _Block {
  const _Fact(this.label, this.value, {this.keep = false});

  final bool keep;

  @override
  bool get keepWithNext => keep;

  final String label;
  final String value;

  static const double _labelWidth = 84;
  static const double _gap = 8;
  static const double _below = 3;

  /// Caps a runaway value, so no one line outgrows a sheet.
  static const int _maxLines = 4;

  @override
  double height(_Ink ink, double width) {
    final double left = ink.measure(
      label,
      _Ink.label,
      _labelWidth,
      maxLines: 2,
    );
    final double right = ink.measure(
      value,
      _Ink.value,
      width - _labelWidth - _gap,
      maxLines: _maxLines,
    );
    return (left > right ? left : right) + _below;
  }

  @override
  Widget build() => Padding(
    padding: const EdgeInsets.only(bottom: _below),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _labelWidth,
          child: AppText(label, variant: _Ink.label, maxLines: 2),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: AppText(value, variant: _Ink.value, maxLines: _maxLines),
        ),
      ],
    ),
  );
}

/// A line to sign on, under the person it belongs to.
class _SignLine extends _Block {
  const _SignLine(this.label);

  final String label;

  static const double _above = 20;
  static const double _rule = 0.8;
  static const double _gap = 2;
  static const double _width = 150;

  @override
  double height(_Ink ink, double width) =>
      _above + _rule + _gap + ink.measure(label, _Ink.small, _width);

  @override
  Widget build() => Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      width: _width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: _above),
          const ColoredBox(
            color: AppColors.paperInk,
            child: SizedBox(height: _rule, width: double.infinity),
          ),
          const SizedBox(height: _gap),
          AppText(label, variant: _Ink.small),
        ],
      ),
    ),
  );
}

/// The case on stamp paper, sheet after sheet; a tapped sheet opens alone to
/// pinch. The Preview tab and the stamp paper screen both draw this.
class StampPaperSheets extends StatelessWidget {
  const StampPaperSheets({super.key, required this.file});

  final AgreementCase file;

  static Future<void> _zoom(
    BuildContext context,
    AgreementCase file,
    StampPaperSheet sheet,
  ) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black87,
    pageBuilder: (BuildContext context, _, _) => SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: StampPaperPage(file: file, sheet: sheet),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: AppCircleIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<StampPaperSheet> sheets = StampPaperSheet.lay(context, file);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppAlert(
          tone: AppTone.info,
          icon: Icons.description_outlined,
          message:
              'Draft (data only): laid out from the case fields, not the '
              'numbered copy. Tap a page to zoom.',
        ),
        for (final StampPaperSheet sheet in sheets) ...<Widget>[
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AppPress(
                onTap: () => _zoom(context, file, sheet),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: StampPaperPage(file: file, sheet: sheet),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
