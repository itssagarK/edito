import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/spatial_audio_pan_config.dart';

class SpatialPanSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SpatialPanSheet({
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
      builder: (context) => SpatialPanSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<SpatialPanSheet> createState() => _SpatialPanSheetState();
}

class _SpatialPanSheetState extends State<SpatialPanSheet> with SingleTickerProviderStateMixin {
  late SpatialAudioPanConfig _config;
  late AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.spatialPan.isEnabled
        ? widget.clip.spatialPan
        : const SpatialAudioPanConfig(isEnabled: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  void _apply(SpatialAudioPanConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onSave(widget.clip.copyWith(spatialPan: newConfig));
  }

  void _applyPreset(double pan, {bool is8D = false, double speed = 0.3, double depth = 0.85}) {
    _apply(_config.copyWith(
      isEnabled: true,
      pan: pan,
      is8DOrbitEnabled: is8D,
      orbitSpeedHz: speed,
      orbitDepth: depth,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.70;

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
                    child: const Icon(Icons.headphones, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '8D Spatial Audio & Stereo Pan',
                          style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Binaural equal-power panning & rotating 8D headphone orbit',
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
                // Animated Binaural Headphone Radar Canvas
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF101520),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                  ),
                  child: AnimatedBuilder(
                    animation: _orbitController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(double.infinity, 150),
                        painter: _BinauralHeadphonePainter(
                          config: _config,
                          animValue: _orbitController.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Equal Power Gains Indicator
                Builder(
                  builder: (context) {
                    final gains = _config.calculateEqualPowerGains();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Left: ${(gains.$1 * 100).round()}%',
                          style: TextStyle(
                            color: gains.$1 > gains.$2 ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _config.is8DOrbitEnabled
                              ? '8D ORBIT ACTIVE (~${(1.0 / _config.orbitSpeedHz).toStringAsFixed(1)}s period)'
                              : (_config.pan == 0 ? 'CENTER BALANCED' : (_config.pan < 0 ? 'PAN LEFT' : 'PAN RIGHT')),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5),
                        ),
                        Text(
                          'Right: ${(gains.$2 * 100).round()}%',
                          style: TextStyle(
                            color: gains.$2 > gains.$1 ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Pan Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stereo Pan Position', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text(
                          _config.pan == 0.0 ? 'Center' : '${(_config.pan * 100).round()}%',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _apply(_config.copyWith(pan: 0.0)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: _config.pan,
                  min: -1.0,
                  max: 1.0,
                  divisions: 40,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    _apply(_config.copyWith(
                      isEnabled: true,
                      pan: double.parse(val.toStringAsFixed(2)),
                    ));
                  },
                ),
                const SizedBox(height: 8),

                // 8D Orbit Mode Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('8D Binaural Audio Orbit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Spins audio around listener headphones in an orbital trajectory', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _config.is8DOrbitEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    _apply(_config.copyWith(isEnabled: true, is8DOrbitEnabled: v));
                  },
                ),

                if (_config.is8DOrbitEnabled) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Orbit Rotation Speed', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text('${_config.orbitSpeedHz.toStringAsFixed(2)} Hz', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _config.orbitSpeedHz,
                    min: 0.1,
                    max: 1.5,
                    divisions: 28,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      _apply(_config.copyWith(orbitSpeedHz: double.parse(val.toStringAsFixed(2))));
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stereo Orbit Width / Depth', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text('${(_config.orbitDepth * 100).round()}%', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _config.orbitDepth,
                    min: 0.2,
                    max: 1.0,
                    divisions: 16,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      _apply(_config.copyWith(orbitDepth: double.parse(val.toStringAsFixed(2))));
                    },
                  ),
                ],

                const SizedBox(height: 12),
                // Presets
                const Text('Spatial Presets', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip('Center Balance', 0.0, is8D: false),
                    _presetChip('Left Stage', -0.65, is8D: false),
                    _presetChip('Right Stage', 0.65, is8D: false),
                    _presetChip('Slow 8D Orbit', 0.0, is8D: true, speed: 0.20),
                    _presetChip('Viral 8D (Hit)', 0.0, is8D: true, speed: 0.35),
                    _presetChip('Hyper Orbit', 0.0, is8D: true, speed: 0.75),
                  ],
                ),
              ],
            ),
          ),

          // Done Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!widget.isDocked) {
                    Navigator.of(context).pop();
                  } else {
                    widget.onDone?.call();
                  }
                },
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text(
                  'Apply Spatial Pan',
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

  Widget _presetChip(String label, double pan, {bool is8D = false, double speed = 0.3}) {
    final isSelected = _config.is8DOrbitEnabled == is8D &&
        (!is8D ? (_config.pan - pan).abs() < 0.05 : (_config.orbitSpeedHz - speed).abs() < 0.05);

    return InkWell(
      onTap: () => _applyPreset(pan, is8D: is8D, speed: speed),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.20) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BinauralHeadphonePainter extends CustomPainter {
  final SpatialAudioPanConfig config;
  final double animValue;

  _BinauralHeadphonePainter({required this.config, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;

    // 1. Orbital Ring Track
    final trackPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final orbitRx = size.width * 0.36;
    final orbitRy = size.height * 0.32;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: orbitRx * 2, height: orbitRy * 2), trackPaint);

    // 2. Head Silhouette in Center
    final headPaint = Paint()
      ..color = const Color(0xFF1E2838)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 24, headPaint);

    // Left & Right Ear Cushions
    final earPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 25, cy), width: 8, height: 22), const Radius.circular(4)), earPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 25, cy), width: 8, height: 22), const Radius.circular(4)), earPaint);

    // Headband
    final bandPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 50), math.pi, math.pi, false, bandPaint);

    // Labels L & R
    final textPainterL = TextPainter(
      text: const TextSpan(text: 'L', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterL.paint(canvas, Offset(cx - 45, cy - 6));

    final textPainterR = TextPainter(
      text: const TextSpan(text: 'R', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterR.paint(canvas, Offset(cx + 36, cy - 6));

    // 3. Sound Source Node Position
    double emitterPan;
    if (config.is8DOrbitEnabled) {
      // 8D continuous rotation
      final angle = animValue * 2.0 * math.pi * config.orbitSpeedHz * 4.0;
      final px = cx + (math.sin(angle) * orbitRx * config.orbitDepth);
      final py = cy - (math.cos(angle) * orbitRy * config.orbitDepth);

      _drawEmitter(canvas, Offset(px, py), size);
      return;
    } else {
      emitterPan = config.pan;
    }

    final px = cx + (emitterPan * orbitRx);
    final py = cy;
    _drawEmitter(canvas, Offset(px, py), size);
  }

  void _drawEmitter(Canvas canvas, Offset pos, Size size) {
    // Glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(pos, 16, glowPaint);

    // Core Particle
    final corePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 8, corePaint);

    // Specular dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BinauralHeadphonePainter oldDelegate) {
    return true;
  }
}
