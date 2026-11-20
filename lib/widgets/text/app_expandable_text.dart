import 'package:flutter/material.dart';

import '../common/app_press.dart';
import 'app_text.dart';

/// Body text clamped to [maxLines], with Show more / Show less when it runs
/// over. The toggle only appears when the text is actually cut.
class AppExpandableText extends StatefulWidget {
  const AppExpandableText(
    this.text, {
    super.key,
    this.maxLines = 2,
    this.color,
    this.fontWeight,
    this.linkColor,
  });

  final String text;
  final int maxLines;
  final Color? color;
  final FontWeight? fontWeight;

  /// Null draws the toggle in the brand colour.
  final Color? linkColor;

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(context).textTheme.bodyMedium!;
    final TextStyle style = base.copyWith(
      color: widget.color ?? base.color,
      fontWeight: widget.fontWeight ?? base.fontWeight,
    );
    final Color link =
        widget.linkColor ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final bool cut = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _open ? null : widget.maxLines,
                overflow: _open ? null : TextOverflow.ellipsis,
              ),
            ),
            if (cut || _open)
              AppPress(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppText.caption(
                        _open ? 'Show less' : 'Show more',
                        color: link,
                        fontWeight: FontWeight.w700,
                      ),
                      Icon(
                        _open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: link,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
