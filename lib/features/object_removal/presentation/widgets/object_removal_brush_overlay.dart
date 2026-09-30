import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/object_removal_config.dart';
import '../../models/object_removal_stroke.dart';
import '../../services/object_removal_compiler_service.dart';

/// Interactive touch overlay for drawing AI object removal masks directly over the video canvas.
class ObjectRemovalBrushOverlay extends StatefulWidget {
  final ObjectRemovalConfig config;
  final ValueChanged<ObjectRemovalConfig> onConfigChanged;
  final bool isInteractive;

  const ObjectRemovalBrushOverlay({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.isInteractive = true,
  });

  @override
  State<ObjectRemovalBrushOverlay> createState() => _ObjectRemovalBrushOverlayState();
}

class _ObjectRemovalBrushOverlayState extends State<ObjectRemovalBrushOverlay> {
  final List<ObjectRemovalPoint> _currentStrokePoints = [];
  Offset? _cursorPosition;
  Offset? _boxStart;
  Offset? _boxCurrent;

  void _onPanStart(DragStartDetails details, Size size) {
    if (!widget.isInteractive) return;

    final localPos = details.localPosition;
    setState(() {
      _cursorPosition = localPos;
      if (widget.config.activeTool == ObjectRemovalToolType.rectangle) {
        _boxStart = localPos;
        _boxCurrent = localPos;
      } else {
        _currentStrokePoints.clear();
        final nx = (localPos.dx / size.width).clamp(0.0, 1.0);
        final ny = (localPos.dy / size.height).clamp(0.0, 1.0);
        _currentStrokePoints.add(ObjectRemovalPoint(
          x: nx,
          y: ny,
          radius: (widget.config.brushSize / size.width) * 0.5,
        ));
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.isInteractive) return;

    final localPos = details.localPosition;
    setState(() {
      _cursorPosition = localPos;
      if (widget.config.activeTool == ObjectRemovalToolType.rectangle) {
        _boxCurrent = localPos;
      } else {
        final nx = (localPos.dx / size.width).clamp(0.0, 1.0);
        final ny = (localPos.dy / size.height).clamp(0.0, 1.0);
        _currentStrokePoints.add(ObjectRemovalPoint(
          x: nx,
          y: ny,
          radius: (widget.config.brushSize / size.width) * 0.5,
        ));
      }
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (!widget.isInteractive) return;

    if (widget.config.activeTool == ObjectRemovalToolType.rectangle) {
      if (_boxStart != null && _boxCurrent != null) {
        final double left = math.min(_boxStart!.dx, _boxCurrent!.dx);
        final double top = math.min(_boxStart!.dy, _boxCurrent!.dy);
        final double width = (_boxStart!.dx - _boxCurrent!.dx).abs();
        final double height = (_boxStart!.dy - _boxCurrent!.dy).abs();

        if (width > 8.0 && height > 8.0) {
          final newRegion = ObjectRemovalRegion(
            id: 'region_${DateTime.now().millisecondsSinceEpoch}',
            x: (left / size.width).clamp(0.0, 1.0),
            y: (top / size.height).clamp(0.0, 1.0),
            width: (width / size.width).clamp(0.01, 1.0),
            height: (height / size.height).clamp(0.01, 1.0),
          );

          final updatedRegions = List<ObjectRemovalRegion>.from(widget.config.regions)..add(newRegion);
          widget.onConfigChanged(widget.config.copyWith(
            isEnabled: true,
            regions: updatedRegions,
          ));
        }
      }
      setState(() {
        _boxStart = null;
        _boxCurrent = null;
        _cursorPosition = null;
      });
    } else {
      // Freehand brush or eraser stroke
      if (_currentStrokePoints.isNotEmpty) {
        final newStroke = ObjectRemovalStroke(
          id: 'stroke_${DateTime.now().millisecondsSinceEpoch}',
          points: List<ObjectRemovalPoint>.from(_currentStrokePoints),
          strokeWidth: widget.config.brushSize,
          feather: widget.config.feather,
          isEraser: widget.config.activeTool == ObjectRemovalToolType.eraser,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        );

        final updatedStrokes = List<ObjectRemovalStroke>.from(widget.config.strokes)..add(newStroke);
        widget.onConfigChanged(widget.config.copyWith(
          isEnabled: true,
          strokes: updatedStrokes,
        ));
      }

      setState(() {
        _currentStrokePoints.clear();
        _cursorPosition = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _onPanStart(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: (d) => _onPanEnd(d, size),
          child: CustomPaint(
            size: size,
            painter: _ObjectRemovalPainter(
              config: widget.config,
              currentStrokePoints: _currentStrokePoints,
              cursorPosition: _cursorPosition,
              boxStart: _boxStart,
              boxCurrent: _boxCurrent,
            ),
          ),
        );
      },
    );
  }
}

class _ObjectRemovalPainter extends CustomPainter {
  final ObjectRemovalConfig config;
  final List<ObjectRemovalPoint> currentStrokePoints;
  final Offset? cursorPosition;
  final Offset? boxStart;
  final Offset? boxCurrent;

  const _ObjectRemovalPainter({
    required this.config,
    required this.currentStrokePoints,
    required this.cursorPosition,
    required this.boxStart,
    required this.boxCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final maskColor = Color(config.maskColorValue);

    // 1. Draw existing committed mask
    if (config.showMaskOverlay && config.isActive) {
      final Path existingPath = ObjectRemovalCompilerService.buildMaskPath(config, size);

      final fillPaint = Paint()
        ..color = maskColor.withOpacity(config.opacity * 0.50)
        ..style = PaintingStyle.fill;
      canvas.drawPath(existingPath, fillPaint);

      final borderPaint = Paint()
        ..color = maskColor.withOpacity(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(existingPath, borderPaint);
    }

    // 2. Draw active in-progress stroke
    if (currentStrokePoints.isNotEmpty) {
      final inProgressStroke = ObjectRemovalStroke(
        id: 'in_progress',
        points: currentStrokePoints,
        strokeWidth: config.brushSize,
        feather: config.feather,
        isEraser: config.activeTool == ObjectRemovalToolType.eraser,
      );

      final tempConfig = ObjectRemovalConfig(
        isEnabled: true,
        strokes: [inProgressStroke],
      );
      final inProgressPath = ObjectRemovalCompilerService.buildMaskPath(tempConfig, size);

      final liveColor = config.activeTool == ObjectRemovalToolType.eraser
          ? Colors.white.withOpacity(0.6)
          : maskColor.withOpacity(0.55);

      final livePaint = Paint()
        ..color = liveColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(inProgressPath, livePaint);

      final liveBorder = Paint()
        ..color = config.activeTool == ObjectRemovalToolType.eraser ? Colors.white : maskColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(inProgressPath, liveBorder);
    }

    // 3. Draw active box selection
    if (boxStart != null && boxCurrent != null) {
      final rect = Rect.fromPoints(boxStart!, boxCurrent!);
      final boxFill = Paint()
        ..color = maskColor.withOpacity(0.40)
        ..style = PaintingStyle.fill;
      final boxStroke = Paint()
        ..color = maskColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, boxFill);
      canvas.drawRect(rect, boxStroke);
    }

    // 4. Draw brush reticle cursor under touch
    if (cursorPosition != null) {
      final radius = config.brushSize * 0.5;
      final cursorPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(cursorPosition!, radius, cursorPaint);

      final centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(cursorPosition!, 2.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectRemovalPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.currentStrokePoints.length != currentStrokePoints.length ||
        oldDelegate.cursorPosition != cursorPosition ||
        oldDelegate.boxStart != boxStart ||
        oldDelegate.boxCurrent != boxCurrent;
  }
}
