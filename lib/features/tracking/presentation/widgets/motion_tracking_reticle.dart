import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/motion_tracking_config.dart';

/// CapCut Pro Interactive Subject Tracking Reticle
class MotionTrackingReticle extends StatefulWidget {
  final MotionTrackingConfig config;
  final Function(double x, double y, double radius) onReticleChanged;
  final bool isTrackingRunning;

  const MotionTrackingReticle({
    super.key,
    required this.config,
    required this.onReticleChanged,
    this.isTrackingRunning = false,
  });

  @override
  State<MotionTrackingReticle> createState() => _MotionTrackingReticleState();
}

class _MotionTrackingReticleState extends State<MotionTrackingReticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.maxWidth;
        final boxH = constraints.maxHeight;

        final centerPixelX = widget.config.reticleX * boxW;
        final centerPixelY = widget.config.reticleY * boxH;
        final sizePixels = (widget.config.reticleRadius * boxW * 2.0).clamp(60.0, 220.0);

        final targetColor = widget.isTrackingRunning
            ? const Color(0xFF00FF66) // Green when solving
            : const Color(0xFFFFE600); // Yellow targeting

        return Stack(
          children: [
            // Target reticle box positioned at (reticleX, reticleY)
            Positioned(
              left: centerPixelX - sizePixels / 2,
              top: centerPixelY - sizePixels / 2,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final newNormX = (widget.config.reticleX + details.delta.dx / boxW).clamp(0.08, 0.92);
                  final newNormY = (widget.config.reticleY + details.delta.dy / boxH).clamp(0.08, 0.92);
                  widget.onReticleChanged(newNormX, newNormY, widget.config.reticleRadius);
                },
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    final scale = widget.isTrackingRunning ? _pulseAnim.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: sizePixels,
                    height: sizePixels,
                    decoration: BoxDecoration(
                      color: targetColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Reticle Corner Brackets Custom Painter
                        CustomPaint(
                          size: Size(sizePixels, sizePixels),
                          painter: _ReticleCornerPainter(color: targetColor),
                        ),
                        // Center Crosshair
                        Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: targetColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: targetColor.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Top Label
                        Positioned(
                          top: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: targetColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                '${widget.config.targetType.icon} ${widget.config.targetType.label.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: targetColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// CustomPainter that renders CapCut Pro's 4 corner targeting brackets
class _ReticleCornerPainter extends CustomPainter {
  final Color color;

  const _ReticleCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 14.0;
    final w = size.width;
    final h = size.height;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-Right
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLen, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLen), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, h), Offset(cornerLen, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLen), paint);

    // Bottom-Right
    canvas.drawLine(Offset(w, h), Offset(w - cornerLen, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticleCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
