import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/night_vision_config.dart';
import '../../services/night_vision_compiler_service.dart';

class NightVisionSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const NightVisionSheet({
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => NightVisionSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<NightVisionSheet> createState() => _NightVisionSheetState();
}

class _NightVisionSheetState extends State<NightVisionSheet> with SingleTickerProviderStateMixin {
  late NightVisionConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.nightVision;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(NightVisionConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(nightVision: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case NightVisionMode.phosphorGreen:
        return const Color(0xFF00FF66);
      case NightVisionMode.thermalFlirIronbow:
        return Colors.deepOrangeAccent;
      case NightVisionMode.thermalRainbow:
        return Colors.cyanAccent;
      case NightVisionMode.whiteHot:
        return Colors.white;
      case NightVisionMode.blackHot:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLiveScopeCard(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildReticleSelector(),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (widget.isDocked) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.visibility_rounded,
            color: _accentColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Night Vision & Thermal Scope',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Military Gen-3 phosphor & FLIR thermal optics',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _config.isEnabled,
          activeColor: _accentColor,
          onChanged: (val) {
            _applyConfig(_config.copyWith(isEnabled: val));
          },
        ),
        if (!widget.isDocked && widget.onDone != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildLiveScopeCard() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive
              ? _accentColor.withOpacity(0.5)
              : AppColors.surfaceVariant,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _NightVisionPainter(
                    config: _config,
                    animationValue: _animController.value,
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _config.isActive ? _accentColor : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _config.isActive
                          ? NightVisionCompilerService.getNightVisionBadge(_config)
                          : 'NVG / THERMAL (BYPASS)',
                      style: AppTypography.caption.copyWith(
                        color: _config.isActive ? _accentColor : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _config.isActive ? Colors.redAccent : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'REC [●] BAT 88%',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsRow() {
    final presets = [
      {'name': 'SpecOps Gen-3', 'preset': NightVisionConfig.specOpsGreen},
      {'name': 'FLIR Ironbow', 'preset': NightVisionConfig.flirIronbowThermal},
      {'name': 'Predator Heat', 'preset': NightVisionConfig.predatorThermal},
      {'name': 'White-Hot IR', 'preset': NightVisionConfig.covertWhiteHot},
      {'name': 'Black-Hot IR', 'preset': NightVisionConfig.sniperBlackHot},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optics Presets',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((item) {
              final preset = item['preset'] as NightVisionConfig;
              final isSelected = _config.isEnabled &&
                  _config.mode == preset.mode &&
                  _config.reticle == preset.reticle;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item['name'] as String),
                  selected: isSelected,
                  selectedColor: _accentColor.withOpacity(0.25),
                  checkmarkColor: _accentColor,
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? _accentColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? _accentColor : Colors.transparent,
                    ),
                  ),
                  onSelected: (val) {
                    _applyConfig(preset);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor & Spectrum Mode',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NightVisionMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.25),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? _accentColor : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? _accentColor : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _config.mode.description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildReticleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Targeting Reticle & HUD',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NightVisionReticle.values.map((reticle) {
              final isSelected = _config.reticle == reticle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(reticle.displayName),
                  selected: isSelected,
                  selectedColor: _accentColor.withOpacity(0.25),
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? _accentColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? _accentColor : Colors.transparent,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      _applyConfig(_config.copyWith(reticle: reticle, isEnabled: true));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSlider(
            title: 'Luminance Gain',
            value: _config.gain,
            min: 0.5,
            max: 3.0,
            displayValue: '${_config.gain.toStringAsFixed(1)}x',
            onChanged: (val) {
              _applyConfig(_config.copyWith(gain: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Sensor Noise Grain',
            value: _config.noise,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.noise * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(noise: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Tube Ocular Vignette',
            value: _config.vignette,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.vignette * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(vignette: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Raster Scanlines',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Switch.adaptive(
                value: _config.scanlines,
                activeColor: _accentColor,
                onChanged: (val) {
                  _applyConfig(_config.copyWith(scanlines: val, isEnabled: true));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentColor,
              thumbColor: _accentColor,
              inactiveTrackColor: Colors.white12,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skia Canvas painter rendering optical military night vision and FLIR thermal viewports.
class _NightVisionPainter extends CustomPainter {
  final NightVisionConfig config;
  final double animationValue;

  _NightVisionPainter({
    required this.config,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw base scene with mode color palette
    _paintBaseScene(canvas, size);

    if (!config.isActive) return;

    // 2. Scanlines
    if (config.scanlines) {
      _paintScanlines(canvas, size);
    }

    // 3. Sensor Noise Grain
    if (config.noise > 0.05) {
      _paintSensorNoise(canvas, size);
    }

    // 4. Ocular Vignette
    if (config.vignette > 0.05) {
      _paintOcularVignette(canvas, size);
    }

    // 5. Tactical Reticle & HUD
    _paintReticleAndHud(canvas, size);
  }

  void _paintBaseScene(Canvas canvas, Size size) {
    Color bg;
    Color terrainColor;
    Color targetColor;

    switch (config.mode) {
      case NightVisionMode.phosphorGreen:
        bg = const Color(0xFF031405);
        terrainColor = const Color(0xFF07380E);
        targetColor = const Color(0xFF14C83C);
        break;
      case NightVisionMode.thermalFlirIronbow:
        bg = const Color(0xFF140528);
        terrainColor = const Color(0xFF780E2B);
        targetColor = const Color(0xFFFFD500);
        break;
      case NightVisionMode.thermalRainbow:
        bg = const Color(0xFF001140);
        terrainColor = const Color(0xFF007733);
        targetColor = const Color(0xFFFF2200);
        break;
      case NightVisionMode.whiteHot:
        bg = const Color(0xFF1A1A1A);
        terrainColor = const Color(0xFF4A4A4A);
        targetColor = const Color(0xFFFFFFFF);
        break;
      case NightVisionMode.blackHot:
        bg = const Color(0xFFB0B0B0);
        terrainColor = const Color(0xFF757575);
        targetColor = const Color(0xFF0D0D0D);
        break;
    }

    final bgPaint = Paint()..color = bg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Terrain ridge
    final ridgePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.70)
      ..lineTo(size.width * 0.35, size.height * 0.60)
      ..lineTo(size.width * 0.65, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(ridgePath, Paint()..color = terrainColor);

    // Simulated heat signature target figure
    final targetCenter = Offset(size.width * 0.50, size.height * 0.58);
    final targetPaint = Paint()..color = targetColor;

    // Head
    canvas.drawCircle(Offset(targetCenter.dx, targetCenter.dy - 16), 7, targetPaint);
    // Torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(targetCenter.dx, targetCenter.dy + 3), width: 14, height: 24),
      const Radius.circular(4),
    );
    canvas.drawRRect(torsoRect, targetPaint);
  }

  void _paintScanlines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 1.0;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  void _paintSensorNoise(Canvas canvas, Size size) {
    final rand = math.Random((animationValue * 1000).toInt());
    final count = (size.width * size.height * 0.008 * config.noise).toInt();
    final noisePaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < count; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final alpha = (rand.nextDouble() * 0.5 * config.noise).clamp(0.0, 1.0);
      noisePaint.color = Colors.white.withOpacity(alpha);
      canvas.drawPoints(PointMode.points, [Offset(x, y)], noisePaint);
    }
  }

  void _paintOcularVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(size.width, size.height) * 0.55;

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withOpacity((0.75 * config.vignette).clamp(0.0, 1.0)),
          Colors.black.withOpacity((0.98 * config.vignette).clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.55, 0.82, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  void _paintReticleAndHud(Canvas canvas, Size size) {
    if (config.reticle == NightVisionReticle.none) return;

    final center = Offset(size.width / 2, size.height / 2);
    Color hudColor;

    switch (config.mode) {
      case NightVisionMode.phosphorGreen:
        hudColor = const Color(0xFF40FF70);
        break;
      case NightVisionMode.thermalFlirIronbow:
        hudColor = Colors.orangeAccent;
        break;
      case NightVisionMode.thermalRainbow:
        hudColor = Colors.cyanAccent;
        break;
      case NightVisionMode.whiteHot:
        hudColor = Colors.white70;
        break;
      case NightVisionMode.blackHot:
        hudColor = Colors.black87;
        break;
    }

    final paint = Paint()
      ..color = hudColor.withOpacity(0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    switch (config.reticle) {
      case NightVisionReticle.militaryCrosshair:
        _drawCrosshair(canvas, center, paint);
        break;
      case NightVisionReticle.tacticalGrid:
        _drawGrid(canvas, size, center, paint);
        break;
      case NightVisionReticle.rangefinderOsd:
        _drawRangefinder(canvas, size, center, paint, hudColor);
        break;
      case NightVisionReticle.none:
        break;
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, Paint paint) {
    const gap = 12.0;
    const len = 35.0;

    // Cross lines
    canvas.drawLine(Offset(center.dx - len, center.dy), Offset(center.dx - gap, center.dy), paint);
    canvas.drawLine(Offset(center.dx + gap, center.dy), Offset(center.dx + len, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - len), Offset(center.dx, center.dy - gap), paint);
    canvas.drawLine(Offset(center.dx, center.dy + gap), Offset(center.dx, center.dy + len), paint);

    // Mil dots
    for (double d = 18; d <= len; d += 8) {
      canvas.drawCircle(Offset(center.dx - d, center.dy), 1.0, paint);
      canvas.drawCircle(Offset(center.dx + d, center.dy), 1.0, paint);
      canvas.drawCircle(Offset(center.dx, center.dy - d), 1.0, paint);
      canvas.drawCircle(Offset(center.dx, center.dy + d), 1.0, paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Offset center, Paint paint) {
    final finePaint = Paint()
      ..color = paint.color.withOpacity(0.35)
      ..strokeWidth = 0.8;

    for (double x = size.width * 0.2; x <= size.width * 0.8; x += size.width * 0.15) {
      canvas.drawLine(Offset(x, size.height * 0.2), Offset(x, size.height * 0.8), finePaint);
    }
    for (double y = size.height * 0.25; y <= size.height * 0.75; y += size.height * 0.25) {
      canvas.drawLine(Offset(size.width * 0.2, y), Offset(size.width * 0.8, y), finePaint);
    }

    // Center diamond
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 10)
      ..lineTo(center.dx + 10, center.dy)
      ..lineTo(center.dx, center.dy + 10)
      ..lineTo(center.dx - 10, center.dy)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  void _drawRangefinder(Canvas canvas, Size size, Offset center, Paint paint, Color color) {
    _drawCrosshair(canvas, center, paint);

    // Corner brackets
    const bLen = 14.0;
    const margin = 20.0;
    final r = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);

    // Top-Left
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + bLen, r.top), paint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left, r.top + bLen), paint);
    // Top-Right
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right - bLen, r.top), paint);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + bLen), paint);
    // Bottom-Left
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + bLen, r.bottom), paint);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left, r.bottom - bLen), paint);
    // Bottom-Right
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right - bLen, r.bottom), paint);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - bLen), paint);

    // Compass ticks at top
    final midX = size.width / 2;
    canvas.drawLine(Offset(midX - 30, margin + 4), Offset(midX - 30, margin + 10), paint);
    canvas.drawLine(Offset(midX, margin + 2), Offset(midX, margin + 12), paint);
    canvas.drawLine(Offset(midX + 30, margin + 4), Offset(midX + 30, margin + 10), paint);
  }

  @override
  bool shouldRepaint(covariant _NightVisionPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.animationValue != animationValue;
  }
}
