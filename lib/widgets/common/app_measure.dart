import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Renders [child] as it is, and reports the height it came out at.
///
/// For a sliver header, which has to declare its extents before it lays a
/// child out: put a copy of the block under one of these inside an [Offstage]
/// and declare what comes back, rather than adding the column up by hand and
/// leaving a gap under it when the arithmetic drifts.
class AppMeasure extends SingleChildRenderObjectWidget {
  const AppMeasure({
    super.key,
    required this.onHeight,
    required Widget super.child,
  });

  /// Called after the frame the height changed on — never during layout.
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasure(onHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMeasure).onHeight = onHeight;
  }
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onHeight);

  ValueChanged<double> onHeight;

  /// The last height handed out, so a scroll frame that re-lays the same
  /// block out does not report it again.
  double? _sent;

  @override
  void performLayout() {
    super.performLayout();
    if (size.height == _sent) return;
    _sent = size.height;
    // After the frame: a height cannot be reported into a rebuild of the tree
    // that is being laid out.
    WidgetsBinding.instance.addPostFrameCallback(
      (Duration _) => onHeight(size.height),
    );
  }
}
