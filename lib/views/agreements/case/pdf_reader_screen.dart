import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart'
    show
        PdfDocument,
        PdfViewer,
        PdfViewerController,
        PdfViewerGeneralTapHandlerDetails,
        PdfViewerGeneralTapType,
        PdfViewerParams;

import '../../../widgets/widgets.dart';

/// A PDF full screen, every page in one scroll from the first: pinch to zoom,
/// re-drawn sharp at every zoom, and a double tap that jumps to a readable
/// size. Held in memory only.
class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.title,
  });

  final Uint8List bytes;
  final String sourceName;
  final String title;

  static Future<void> open(
    BuildContext context, {
    required Uint8List bytes,
    required String sourceName,
    required String title,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          PdfReaderScreen(bytes: bytes, sourceName: sourceName, title: title),
    ),
  );

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _viewer = PdfViewerController();
  int? _page;
  int? _pages;

  /// Fit-width text on a phone is ~6pt; this brings it to ~15.
  static const double _readingZoom = 2.5;

  bool _onTap(
    BuildContext context,
    PdfViewerController viewer,
    PdfViewerGeneralTapHandlerDetails details,
  ) {
    if (details.type != PdfViewerGeneralTapType.doubleTap) return false;
    final double fit = viewer.coverScale;
    final bool zoomedIn = viewer.currentZoom > fit * 1.4;
    viewer.zoomOnLocalPosition(
      localPosition: details.localPosition,
      newZoom: zoomedIn ? fit : fit * _readingZoom,
      duration: const Duration(milliseconds: 260),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets inset = MediaQuery.paddingOf(context);
    final int? page = _page;
    final int? pages = _pages;
    const Color ink = Colors.white;
    final Color chip = Colors.white.withValues(alpha: 0.12);

    // Edge to edge on a dark ground; only the zoom buttons float over it.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _ground,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, inset.top + 8, 12, 8),
                    child: Row(
                      children: <Widget>[
                        AppCircleIconButton(
                          icon: Icons.close_rounded,
                          background: chip,
                          iconColor: ink,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppText.body(
                                widget.title,
                                color: ink,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                              ),
                              AppText.caption(
                                page == null || pages == null
                                    ? 'Pinch or double-tap to zoom'
                                    : 'Page $page of $pages · '
                                          'double-tap to zoom',
                                color: ink.withValues(alpha: 0.75),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PdfViewer.data(
                      widget.bytes,
                      sourceName: widget.sourceName,
                      controller: _viewer,
                      params: PdfViewerParams(
                        backgroundColor: _ground,
                        pageDropShadow: BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        onGeneralTap: _onTap,
                        onViewerReady:
                            (PdfDocument document, PdfViewerController _) =>
                                setState(() {
                                  _pages = document.pages.length;
                                  _page ??= 1;
                                }),
                        onPageChanged: (int? number) {
                          if (number != null && number != _page) {
                            setState(() => _page = number);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16 + inset.bottom,
              child: Column(
                children: <Widget>[
                  AppCircleIconButton(
                    icon: Icons.add_rounded,
                    background: Colors.black.withValues(alpha: 0.55),
                    iconColor: ink,
                    onTap: () {
                      if (_viewer.isReady) _viewer.zoomUp();
                    },
                  ),
                  const SizedBox(height: 10),
                  AppCircleIconButton(
                    icon: Icons.remove_rounded,
                    background: Colors.black.withValues(alpha: 0.55),
                    iconColor: ink,
                    onTap: () {
                      if (_viewer.isReady) _viewer.zoomDown();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _ground = Color(0xFF1C1F1E);
}
