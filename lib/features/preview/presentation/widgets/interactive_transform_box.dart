import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// CapCut-style interactive transform box with corner handles:
/// - Top-Left: Delete (X)
/// - Top-Right: Duplicate (+)
/// - Bottom-Left: Edit (✏️)
/// - Bottom-Right: Scale & Rotate (🔄)
/// - Center: Single-finger drag pan & two-finger pinch-zoom / rotate
class InteractiveTransformBox extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final double scale;
  final double rotation; // in degrees
  final double positionX; // 0.0 to 1.0 normalized
  final double positionY; // 0.0 to 1.0 normalized
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onEdit;
  final Function(double newX, double newY)? onPositionChanged;
  final Function(double newScale, double newRotation)? onTransformChanged;

  const InteractiveTransformBox({
    super.key,
    required this.child,
    this.isSelected = false,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
    this.onDuplicate,
    this.onEdit,
    this.onPositionChanged,
    this.onTransformChanged,
  });

  @override
  State<InteractiveTransformBox> createState() => _InteractiveTransformBoxState();
}

class _InteractiveTransformBoxState extends State<InteractiveTransformBox> {
  late double _currentX;
  late double _currentY;
  late double _currentScale;
  late double _currentRotation;

  // Handle drag tracking
  Offset? _rotateHandleStartOffset;
  double? _initialRotationOnDrag;
  double? _initialScaleOnDrag;

  @override
  void initState() {
    super.initState();
    _currentX = widget.positionX;
    _currentY = widget.positionY;
    _currentScale = widget.scale;
    _currentRotation = widget.rotation;
  }

  @override
  void didUpdateWidget(covariant InteractiveTransformBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionX != widget.positionX) _currentX = widget.positionX;
    if (oldWidget.positionY != widget.positionY) _currentY = widget.positionY;
    if (oldWidget.scale != widget.scale) _currentScale = widget.scale;
    if (oldWidget.rotation != widget.rotation) _currentRotation = widget.rotation;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        final isSnappedX = (_currentX - 0.5).abs() < 0.02;
        final isSnappedY = (_currentY - 0.5).abs() < 0.02;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Snap alignment guidelines (subtle cyan crosshairs)
            if (widget.isSelected && isSnappedX)
              Positioned(
                left: canvasWidth * 0.5 - 0.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.0,
                  color: AppColors.accent.withOpacity(0.7),
                ),
              ),
            if (widget.isSelected && isSnappedY)
              Positioned(
                left: 0,
                right: 0,
                top: canvasHeight * 0.5 - 0.5,
                child: Container(
                  height: 1.0,
                  color: AppColors.accent.withOpacity(0.7),
                ),
              ),

            // Element positioning on canvas
            Align(
              alignment: Alignment(
                (_currentX * 2.0) - 1.0,
                (_currentY * 2.0) - 1.0,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onDoubleTap: widget.onDoubleTap,
                onScaleStart: widget.isSelected
                    ? (details) {
                        _initialScaleOnDrag = _currentScale;
                        _initialRotationOnDrag = _currentRotation;
                      }
                    : null,
                onScaleUpdate: widget.isSelected
                    ? (details) {
                        if (canvasWidth <= 0 || canvasHeight <= 0) return;

                        // 1. Position pan
                        final dxNorm = details.focalPointDelta.dx / canvasWidth;
                        final dyNorm = details.focalPointDelta.dy / canvasHeight;

                        double newX = (_currentX + dxNorm).clamp(0.05, 0.95);
                        double newY = (_currentY + dyNorm).clamp(0.05, 0.95);

                        // Snap to center
                        if ((newX - 0.5).abs() < 0.025) newX = 0.5;
                        if ((newY - 0.5).abs() < 0.025) newY = 0.5;

                        // 2. Scale
                        double newScale = _currentScale;
                        if (details.scale != 1.0 && _initialScaleOnDrag != null) {
                          newScale = (_initialScaleOnDrag! * details.scale).clamp(0.2, 5.0);
                        }

                        // 3. Rotation
                        double newRot = _currentRotation;
                        if (details.rotation != 0.0 && _initialRotationOnDrag != null) {
                          newRot = _initialRotationOnDrag! + (details.rotation * 180.0 / math.pi);
                          // Snap to 0, 90, 180, 270
                          final normRot = (newRot % 360 + 360) % 360;
                          for (final snap in [0.0, 90.0, 180.0, 270.0, 360.0]) {
                            if ((normRot - snap).abs() < 4.0) {
                              newRot = snap == 360.0 ? 0.0 : snap;
                              break;
                            }
                          }
                        }

                        setState(() {
                          _currentX = newX;
                          _currentY = newY;
                          _currentScale = newScale;
                          _currentRotation = newRot;
                        });

                        widget.onPositionChanged?.call(newX, newY);
                        widget.onTransformChanged?.call(newScale, newRot);
                      }
                    : null,
                child: Transform.rotate(
                  angle: _currentRotation * (math.pi / 180.0),
                  child: Transform.scale(
                    scale: _currentScale,
                    child: Container(
                      decoration: widget.isSelected
                          ? BoxDecoration(
                              border: Border.all(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The actual content (e.g. text or image)
                          Padding(
                            padding: EdgeInsets.all(widget.isSelected ? 8.0 : 0.0),
                            child: widget.child,
                          ),

                          // CapCut-style 4 corner interactive control handles
                          if (widget.isSelected) ...[
                            // Top-Left: Delete Handle (X)
                            Positioned(
                              top: -12,
                              left: -12,
                              child: _buildHandleButton(
                                icon: Icons.close,
                                color: const Color(0xFFFF4757),
                                onTap: widget.onDelete,
                              ),
                            ),

                            // Top-Right: Duplicate Handle (+)
                            Positioned(
                              top: -12,
                              right: -12,
                              child: _buildHandleButton(
                                icon: Icons.control_point_duplicate,
                                color: AppColors.primary,
                                onTap: widget.onDuplicate,
                              ),
                            ),

                            // Bottom-Left: Quick Edit Handle (✏️)
                            Positioned(
                              bottom: -12,
                              left: -12,
                              child: _buildHandleButton(
                                icon: Icons.edit,
                                color: const Color(0xFF2ED573),
                                onTap: widget.onEdit ?? widget.onDoubleTap,
                              ),
                            ),

                            // Bottom-Right: Rotate & Scale Handle (🔄)
                            Positioned(
                              bottom: -12,
                              right: -12,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  _rotateHandleStartOffset = details.globalPosition;
                                  _initialScaleOnDrag = _currentScale;
                                  _initialRotationOnDrag = _currentRotation;
                                },
                                onPanUpdate: (details) {
                                  if (_rotateHandleStartOffset == null) return;
                                  final delta = details.globalPosition - _rotateHandleStartOffset!;
                                  final distanceDelta = (delta.dx + delta.dy) / 120.0;
                                  final newScale = ((_initialScaleOnDrag ?? 1.0) + distanceDelta).clamp(0.2, 5.0);

                                  // Angular drag rotation
                                  final angleDelta = (delta.dx - delta.dy) * 0.4;
                                  final newRot = (_initialRotationOnDrag ?? 0.0) + angleDelta;

                                  setState(() {
                                    _currentScale = newScale;
                                    _currentRotation = newRot;
                                  });

                                  widget.onTransformChanged?.call(newScale, newRot);
                                },
                                child: _buildHandleButton(
                                  icon: Icons.sync,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildHandleButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
