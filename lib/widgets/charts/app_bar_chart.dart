import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../text/app_text.dart';

/// One month's worth of data for [AppBarChart].
class ChartPoint {
  const ChartPoint({required this.label, required this.paid, required this.due});

  final String label;
  final double paid;
  final double due;
}

/// A small "paid vs due" grouped bar chart for the dashboards.
///
/// Colors are the validated status pair (paid = success green, due = info
/// blue) rather than arbitrary categorical hues, since these are genuinely
/// payment *states*. Values are never color-only: there's a text legend and
/// tapping a group reveals its exact figures — the mobile equivalent of a
/// hover tooltip.
class AppBarChart extends StatefulWidget {
  const AppBarChart({super.key, required this.data, this.height = 150});

  final List<ChartPoint> data;
  final double height;

  @override
  State<AppBarChart> createState() => _AppBarChartState();
}

class _AppBarChartState extends State<AppBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paidColor = isDark ? AppColors.secondaryDark : AppColors.secondary;
    const dueColor = AppColors.info;
    final axisColor = Theme.of(context).dividerColor;

    final maxValue = widget.data.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.paid, d.due)),
    );
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: paidColor, label: 'Paid'),
            const SizedBox(width: 16),
            _LegendDot(color: dueColor, label: 'Due'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final groupWidth = constraints.maxWidth / widget.data.length;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final index = (details.localPosition.dx / groupWidth)
                      .floor()
                      .clamp(0, widget.data.length - 1);
                  setState(() => _selected = _selected == index ? null : index);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _BarChartPainter(
                        data: widget.data,
                        maxValue: safeMax,
                        paidColor: paidColor,
                        dueColor: dueColor,
                        axisColor: axisColor,
                        selected: _selected,
                      ),
                    ),
                    if (_selected != null)
                      Positioned(
                        left: (_selected! * groupWidth)
                            .clamp(0, math.max(0, constraints.maxWidth - 150)),
                        top: 0,
                        child: _ChartTooltip(point: widget.data[_selected!]),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.paidColor,
    required this.dueColor,
    required this.axisColor,
    required this.selected,
  });

  final List<ChartPoint> data;
  final double maxValue;
  final Color paidColor;
  final Color dueColor;
  final Color axisColor;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    final groupWidth = size.width / data.length;
    const barGap = 3.0;
    final barWidth = math.max(4.0, (groupWidth - barGap - 16) / 2);

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final groupLeft = i * groupWidth + (groupWidth - (barWidth * 2 + barGap)) / 2;
      final isDimmed = selected != null && selected != i;
      final opacity = isDimmed ? 0.35 : 1.0;

      final paidHeight = (point.paid / maxValue) * (chartHeight - 8);
      final dueHeight = (point.due / maxValue) * (chartHeight - 8);

      _drawBar(
        canvas,
        Rect.fromLTWH(groupLeft, chartHeight - paidHeight, barWidth, paidHeight),
        paidColor.withValues(alpha: opacity),
      );
      _drawBar(
        canvas,
        Rect.fromLTWH(
          groupLeft + barWidth + barGap,
          chartHeight - dueHeight,
          barWidth,
          dueHeight,
        ),
        dueColor.withValues(alpha: opacity),
      );

      textPainter.text = TextSpan(
        text: point.label,
        style: TextStyle(fontSize: 11, color: axisColor),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * groupWidth + (groupWidth - textPainter.width) / 2, chartHeight + 4),
      );
    }
  }

  void _drawBar(Canvas canvas, Rect rect, Color color) {
    if (rect.height <= 0) return;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selected != selected ||
        oldDelegate.maxValue != maxValue;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        AppText.caption(label),
      ],
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({required this.point});

  final ChartPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.label(point.label),
          const SizedBox(height: 2),
          AppText.caption('Paid ${Formatters.currency(point.paid)}'),
          AppText.caption('Due ${Formatters.currency(point.due)}'),
        ],
      ),
    );
  }
}
