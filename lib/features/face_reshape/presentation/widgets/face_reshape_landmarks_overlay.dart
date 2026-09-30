import 'package:flutter/material.dart';
import '../../models/face_reshape_config.dart';
import '../../services/face_reshape_compiler_service.dart';

/// Interactive viewport overlay rendering 3D facial sculpting landmark anchors and contour wireframe.
class FaceReshapeLandmarksOverlay extends StatefulWidget {
  final FaceReshapeConfig config;
  final ValueChanged<FaceReshapeConfig> onConfigChanged;
  final bool isInteractive;

  const FaceReshapeLandmarksOverlay({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.isInteractive = true,
  });

  @override
  State<FaceReshapeLandmarksOverlay> createState() => _FaceReshapeLandmarksOverlayState();
}

class _FaceReshapeLandmarksOverlayState extends State<FaceReshapeLandmarksOverlay> {
  String? _activeLandmarkKey;

  void _handlePanStart(DragStartDetails details, Size size) {
    if (!widget.isInteractive) return;
    final landmarks = FaceReshapeCompilerService.calculateFacialLandmarks(widget.config, size);

    String? closestKey;
    double minDistance = 32.0; // 32px hit target

    for (final entry in landmarks.entries) {
      final dist = (entry.value - details.localPosition).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestKey = entry.key;
      }
    }

    setState(() {
      _activeLandmarkKey = closestKey;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_activeLandmarkKey == null || !widget.isInteractive) return;

    final dy = details.delta.dy / size.height;
    final dx = details.delta.dx / size.width;

    var cfg = widget.config;

    switch (_activeLandmarkKey) {
      case 'chin':
        cfg = cfg.copyWith(
          isEnabled: true,
          chinLength: (cfg.chinLength + dy * 2.5).clamp(-1.0, 1.0),
        );
        break;
      case 'cheekLeft':
        cfg = cfg.copyWith(
          isEnabled: true,
          faceSlimming: (cfg.faceSlimming + dx * 2.5).clamp(-1.0, 1.0),
        );
        break;
      case 'cheekRight':
        cfg = cfg.copyWith(
          isEnabled: true,
          faceSlimming: (cfg.faceSlimming - dx * 2.5).clamp(-1.0, 1.0),
        );
        break;
      case 'leftEye':
      case 'rightEye':
        cfg = cfg.copyWith(
          isEnabled: true,
          eyeSize: (cfg.eyeSize - dy * 2.0).clamp(-1.0, 1.0),
        );
        break;
      case 'nose':
        cfg = cfg.copyWith(
          isEnabled: true,
          noseSize: (cfg.noseSize + dx * 2.0).clamp(-1.0, 1.0),
        );
        break;
      case 'mouthLeft':
      case 'mouthRight':
        cfg = cfg.copyWith(
          isEnabled: true,
          smileCorners: (cfg.smileCorners - dy * 2.5).clamp(-1.0, 1.0),
        );
        break;
      case 'jawLeft':
      case 'jawRight':
        cfg = cfg.copyWith(
          isEnabled: true,
          vFace: (cfg.vFace - dx * 2.5).clamp(-1.0, 1.0),
        );
        break;
    }

    widget.onConfigChanged(cfg);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _activeLandmarkKey = null;
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
            painter: _FaceLandmarksPainter(
              config: widget.config,
              activeLandmarkKey: _activeLandmarkKey,
            ),
          ),
        );
      },
    );
  }
}

class _FaceLandmarksPainter extends CustomPainter {
  final FaceReshapeConfig config;
  final String? activeLandmarkKey;

  const _FaceLandmarksPainter({
    required this.config,
    required this.activeLandmarkKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final landmarks = FaceReshapeCompilerService.calculateFacialLandmarks(config, size);
    final contourPath = FaceReshapeCompilerService.buildLandmarkContourPath(config, size);

    // 1. Draw glowing contour wireframe
    final contourPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(contourPath, contourPaint);

    // Eye connections
    if (landmarks.containsKey('leftEye') && landmarks.containsKey('rightEye')) {
      final eyeLine = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(landmarks['leftEye']!, landmarks['rightEye']!, eyeLine);
    }

    // 2. Draw Landmark Anchor Dots
    for (final entry in landmarks.entries) {
      final isSelected = entry.key == activeLandmarkKey;
      final pt = entry.value;

      final dotPaint = Paint()
        ..color = isSelected ? const Color(0xFFFF2D55) : const Color(0xFF00E5FF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSelected ? 5.5 : 3.5, dotPaint);

      final outerRing = Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.9 : 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(pt, isSelected ? 8.0 : 5.5, outerRing);
    }
  }

  @override
  bool shouldRepaint(covariant _FaceLandmarksPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.activeLandmarkKey != activeLandmarkKey;
  }
}
