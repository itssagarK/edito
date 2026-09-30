import 'package:flutter/material.dart';
import '../../models/doodle_stroke.dart';
import '../../models/doodle_config.dart';
import '../../services/doodle_compiler_service.dart';

/// Interactive viewport overlay for drawing freehand doodle strokes and neon annotations.
class DoodleCanvasOverlay extends StatefulWidget {
  final DoodleConfig config;
  final ValueChanged<DoodleConfig> onConfigChanged;
  final bool isInteractive;

  const DoodleCanvasOverlay({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.isInteractive = true,
  });

  @override
  State<DoodleCanvasOverlay> createState() => _DoodleCanvasOverlayState();
}

class _DoodleCanvasOverlayState extends State<DoodleCanvasOverlay> {
  final List<DoodlePoint> _activePoints = [];
  Offset? _currentCursorPos;

  void _handlePanStart(DragStartDetails details, Size size) {
    if (!widget.isInteractive) return;

    final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _currentCursorPos = details.localPosition;
      if (widget.config.activeBrush == DoodleBrushType.eraser) {
        final remaining = DoodleCompilerService.eraseAtPoint(
          widget.config.strokes,
          details.localPosition,
          widget.config.brushSize * 1.5,
          size,
        );
        widget.onConfigChanged(widget.config.copyWith(strokes: remaining));
      } else {
        _activePoints.clear();
        _activePoints.add(DoodlePoint(x: normX, y: normY));
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.isInteractive) return;

    final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _currentCursorPos = details.localPosition;
      if (widget.config.activeBrush == DoodleBrushType.eraser) {
        final remaining = DoodleCompilerService.eraseAtPoint(
          widget.config.strokes,
          details.localPosition,
          widget.config.brushSize * 1.5,
          size,
        );
        widget.onConfigChanged(widget.config.copyWith(strokes: remaining));
      } else {
        _activePoints.add(DoodlePoint(x: normX, y: normY));
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isInteractive) return;

    if (widget.config.activeBrush != DoodleBrushType.eraser && _activePoints.length >= 2) {
      final newStroke = DoodleStroke(
        id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
        points: List.from(_activePoints),
        brushType: widget.config.activeBrush,
        colorValue: widget.config.brushColorValue,
        strokeWidth: widget.config.brushSize,
        opacity: widget.config.opacity,
        hardness: widget.config.hardness,
      );

      final updatedStrokes = [...widget.config.strokes, newStroke];
      widget.onConfigChanged(widget.config.copyWith(
        isEnabled: true,
        strokes: updatedStrokes,
      ));
    }

    setState(() {
      _activePoints.clear();
      _currentCursorPos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (d) => _handlePanStart(d, size),
          onPanUpdate: (d) => _handlePanUpdate(d, size),
          onPanEnd: _handlePanEnd,
          child: CustomPaint(
            size: size,
            painter: _DoodleCanvasPainter(
              config: widget.config,
              activePoints: _activePoints,
              cursorPos: _currentCursorPos,
            ),
          ),
        );
      },
    );
  }
}

class _DoodleCanvasPainter extends CustomPainter {
  final DoodleConfig config;
  final List<DoodlePoint> activePoints;
  final Offset? cursorPos;

  const _DoodleCanvasPainter({
    required this.config,
    required this.activePoints,
    required this.cursorPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Paint all committed doodle strokes
    for (final stroke in config.strokes) {
      DoodleCompilerService.paintStroke(canvas, stroke, size);
    }

    // 2. Paint in-progress stroke if drawing
    if (activePoints.isNotEmpty && config.activeBrush != DoodleBrushType.eraser) {
      final inProgressStroke = DoodleStroke(
        id: 'in_progress',
        points: activePoints,
        brushType: config.activeBrush,
        colorValue: config.brushColorValue,
        strokeWidth: config.brushSize,
        opacity: config.opacity,
        hardness: config.hardness,
      );
      DoodleCompilerService.paintStroke(canvas, inProgressStroke, size);
    }

    // 3. Render circular reticle cursor during touch interaction
    if (cursorPos != null) {
      final radius = config.activeBrush == DoodleBrushType.eraser
          ? config.brushSize * 1.5
          : config.brushSize / 2.0;

      final reticlePaint = Paint()
        ..color = config.activeBrush == DoodleBrushType.eraser
            ? Colors.white.withOpacity(0.8)
            : Color(config.brushColorValue).withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(cursorPos!, radius, reticlePaint);

      // Center crosshair dot
      final centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(cursorPos!, 2.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _DoodleCanvasPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.activePoints.length != activePoints.length ||
        oldDelegate.cursorPos != cursorPos;
  }
}
