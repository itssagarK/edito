import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/speed_ease_config.dart';

class SpeedEaseSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SpeedEaseSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => SpeedEaseSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<SpeedEaseSheet> createState() => _SpeedEaseSheetState();
}

class _SpeedEaseSheetState extends State<SpeedEaseSheet> {
  late SpeedEaseConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.speedEase.isEnabled
        ? widget.clip.speedEase
        : const SpeedEaseConfig(isEnabled: true);
  }

  void _applyPreset(SpeedEasePreset preset) {
    final pts = preset.defaultControlPoints;
    setState(() {
      _config = _config.copyWith(
        isEnabled: true,
        preset: preset,
        p1x: pts.$1,
        p1y: pts.$2,
        p2x: pts.$3,
        p2y: pts.$4,
      );
    });
  }

  void _saveChanges() {
    final effectiveAvg = _config.calculateEffectiveAverageSpeed();
    final sourceSpan = (widget.clip.sourceOutMs - widget.clip.sourceInMs).abs();
    final newDuration = effectiveAvg > 0 && sourceSpan > 0
        ? (sourceSpan / effectiveAvg).round().clamp(100, 3600000)
        : widget.clip.durationMs;

    final updated = widget.clip.copyWith(
      speedEase: _config,
      durationMs: newDuration,
    );

    widget.onSave(updated);
    if (!widget.isDocked) {
      Navigator.of(context).pop();
    } else {
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bezier Speed Ramping & Optical Ease',
                          style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sculpt continuous velocity curves with cubic bezier handles',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              children: [
                // Interactive Bezier Curve Canvas
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101520),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanUpdate: (details) {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          if (w <= 0 || h <= 0) return;

                          // Normalized touch coordinate (0 to 1)
                          final normX = (details.localPosition.dx / w).clamp(0.0, 1.0);
                          final normY = (1.0 - (details.localPosition.dy / h)).clamp(0.0, 1.0);

                          // Distance to P1 vs P2
                          final d1 = (normX - _config.p1x).abs() + (normY - _config.p1y).abs();
                          final d2 = (normX - _config.p2x).abs() + (normY - _config.p2y).abs();

                          setState(() {
                            if (d1 < d2) {
                              _config = _config.copyWith(
                                preset: SpeedEasePreset.custom,
                                p1x: normX,
                                p1y: normY,
                              );
                            } else {
                              _config = _config.copyWith(
                                preset: SpeedEasePreset.custom,
                                p2x: normX,
                                p2y: normY,
                              );
                            }
                          });
                        },
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _BezierCurveGraphPainter(config: _config),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'P1 (${_config.p1x.toStringAsFixed(2)}, ${_config.p1y.toStringAsFixed(2)})  •  P2 (${_config.p2x.toStringAsFixed(2)}, ${_config.p2y.toStringAsFixed(2)})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Avg: ${_config.calculateEffectiveAverageSpeed().toStringAsFixed(2)}x',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Presets Wrap
                const Text('Optical Velocity Presets', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SpeedEasePreset.values.map((preset) {
                    final isSel = _config.preset == preset;
                    return InkWell(
                      onTap: () => _applyPreset(preset),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary.withOpacity(0.20) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          preset.label,
                          style: TextStyle(
                            color: isSel ? AppColors.primary : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Min Speed Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Slowest Valley Speed', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${_config.minSpeed.toStringAsFixed(2)}x', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.minSpeed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(minSpeed: double.parse(val.toStringAsFixed(2))));
                  },
                ),
                const SizedBox(height: 8),

                // Max Speed Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Peak Burst Speed', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${_config.maxSpeed.toStringAsFixed(2)}x', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.maxSpeed,
                  min: 1.0,
                  max: 6.0,
                  divisions: 25,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(maxSpeed: double.parse(val.toStringAsFixed(2))));
                  },
                ),
              ],
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text(
                  'Apply Bezier Speed Curve',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BezierCurveGraphPainter extends CustomPainter {
  final SpeedEaseConfig config;

  _BezierCurveGraphPainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 4; i++) {
      final x = (w / 4) * i;
      final y = (h / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Control handles lines
    final handleLinePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.35)
      ..strokeWidth = 1.5;

    final p0 = Offset(0, h);
    final p1 = Offset(config.p1x * w, (1.0 - config.p1y) * h);
    final p2 = Offset(config.p2x * w, (1.0 - config.p2y) * h);
    final p3 = Offset(w, 0);

    canvas.drawLine(p0, p1, handleLinePaint);
    canvas.drawLine(p3, p2, handleLinePaint);

    // 3. Smooth Bezier Curve Path
    final curvePath = Path();
    curvePath.moveTo(p0.dx, p0.dy);
    curvePath.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    final curvePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(curvePath, curvePaint);

    // 4. Fill under curve with gradient
    final fillPath = Path.from(curvePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.25),
          AppColors.primary.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Handle Knobs
    final knobPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final knobRingPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final pt in [p1, p2]) {
      canvas.drawCircle(pt, 6.0, knobPaint);
      canvas.drawCircle(pt, 6.0, knobRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BezierCurveGraphPainter oldDelegate) {
    return oldDelegate.config != config;
  }
}
