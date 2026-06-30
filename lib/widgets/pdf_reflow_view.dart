import 'package:flutter/material.dart';

import '../services/pdf_text_extractor.dart';
import '../theme/app_theme.dart';
import '../theme/paper_palette.dart';
import '../theme/reading_options.dart';

/// Renders extracted PDF text as reflowable, paper-like reading — the
/// Kindle-style view. Honors the paper palette plus font size and line spacing.
class PdfReflowView extends StatefulWidget {
  const PdfReflowView({
    super.key,
    required this.title,
    required this.blocks,
    required this.palette,
    required this.fontScale,
    required this.lineHeight,
    required this.font,
    required this.margin,
    required this.initialProgress,
    required this.onProgress,
    this.onTap,
  });

  final String title;
  final List<ReflowBlock> blocks;
  final PaperPalette palette;
  final double fontScale;
  final double lineHeight;
  final ReadingFont font;
  final ReadingMargin margin;
  final double initialProgress;
  final ValueChanged<double> onProgress;
  final VoidCallback? onTap;

  @override
  State<PdfReflowView> createState() => _PdfReflowViewState();
}

class _PdfReflowViewState extends State<PdfReflowView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reportProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  @override
  void dispose() {
    _controller.removeListener(_reportProgress);
    _controller.dispose();
    super.dispose();
  }

  void _restore() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    if (max > 0 && widget.initialProgress > 0) {
      _controller.jumpTo((widget.initialProgress.clamp(0.0, 1.0)) * max);
    }
  }

  void _reportProgress() {
    if (!_controller.hasClients) return;
    final max = _controller.position.maxScrollExtent;
    widget.onProgress(max <= 0 ? 0.0 : (_controller.offset / max).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final fontSize = 19.0 * widget.fontScale;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      child: ColoredBox(
        color: p.page,
        child: SafeArea(
          child: ListView.builder(
            controller: _controller,
            padding: EdgeInsets.fromLTRB(
              widget.margin.horizontal,
              PapyrTheme.space7,
              widget.margin.horizontal,
              PapyrTheme.space7,
            ),
            itemCount: widget.blocks.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: PapyrTheme.space5),
                  child: Text(
                    widget.title,
                    style: PapyrTheme.title(p.inkPrimary, size: 26),
                  ),
                );
              }
              final block = widget.blocks[i - 1];
              if (block.isHeading) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: PapyrTheme.space4,
                    bottom: PapyrTheme.space3,
                  ),
                  child: Text(
                    block.text,
                    style: PapyrTheme.title(p.inkPrimary, size: fontSize * 1.15),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: PapyrTheme.space4),
                child: Text(
                  block.text,
                  style: PapyrTheme.readingWith(
                    widget.font,
                    p.inkPrimary,
                    size: fontSize,
                    height: widget.lineHeight,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
