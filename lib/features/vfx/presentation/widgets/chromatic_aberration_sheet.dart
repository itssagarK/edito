import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/chromatic_aberration_config.dart';
import '../../services/chromatic_aberration_compiler_service.dart';

class ChromaticAberrationSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ChromaticAberrationSheet({
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
      builder: (context) => ChromaticAberrationSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ChromaticAberrationSheet> createState() => _ChromaticAberrationSheetState();
}

class _ChromaticAberrationSheetState extends State<ChromaticAberrationSheet> with SingleTickerProviderStateMixin {
  late ChromaticAberrationConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.chromaticAberration;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void disposeValidate() {
    _animController.dispose();
  }

  @override
  void dispose() {
    disposeValidate();
    super.dispose();
  }

  void _applyConfig(ChromaticAberrationConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(chromaticAberration: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case ChromaticAberrationMode.horizontalSplit:
        return const Color(0xFF00E5FF); // Cyan / Blue split
      case ChromaticAberrationMode.radialDispersion:
        return const Color(0xFFFF4081); // Magenta optical prism
      case ChromaticAberrationMode.anaglyph3d:
        return const Color(0xFFFF1744); // 3D Anaglyph Red
      case ChromaticAberrationMode.hologramJitter:
        return const Color(0xFF76FF03); // Hologram phosphor green
      case ChromaticAberrationMode.prismaticAngle:
        return const Color(0xFFFFEA00); // Spectral solar yellow
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitorVisualizer(),
                  const SizedBox(height: 16),
                  _buildEnableToggle(),
                  if (_config.isEnabled) ...[
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildPresetChips(),
                    const SizedBox(height: 16),
                    _buildControls(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.grain, color: _accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RGB Chromatic Aberration',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Optical prism displacement & holographic color glitch',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (widget.onDone != null)
            IconButton(
              onPressed: widget.onDone,
              icon: const Icon(Icons.check, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonitorVisualizer() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.6) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _ChromaticAberrationPainter(
                config: _config,
                accentColor: _accentColor,
                time: _animController.value,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _accentColor.withOpacity(0.5), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _config.isActive ? _accentColor : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _config.isActive
                                ? 'RGB DISPERSION ACTIVE • ${(math.sin(_animController.value * 2 * math.pi) * 10).toStringAsFixed(1)}PX'
                                : 'RGB ALIGNED (FLAT)',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'R-G-B SPLIT • ${_config.mode.displayName.toUpperCase()}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.blur_linear : Icons.blur_off,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chromatic Aberration',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _config.isEnabled ? 'RGB channel displacement active' : 'Colors perfectly aligned',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _accentColor,
            onChanged: (val) {
              _applyConfig(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DISPERSION PATTERN',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ChromaticAberrationMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.transparent,
                width: 1.2,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    final presets = [
      {'name': 'Cyber Glitch', 'cfg': ChromaticAberrationConfig.cyberGlitch},
      {'name': 'Lens Prism', 'cfg': ChromaticAberrationConfig.lensPrism},
      {'name': '3D Anaglyph', 'cfg': ChromaticAberrationConfig.vintageAnaglyph},
      {'name': 'Hologram Shift', 'cfg': ChromaticAberrationConfig.hologramShift},
      {'name': 'Radial Warp', 'cfg': ChromaticAberrationConfig.radialWarp},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final cfg = p['cfg'] as ChromaticAberrationConfig;
              final isMatch = _config.mode == cfg.mode &&
                  (_config.shiftAmount - cfg.shiftAmount).abs() < 0.05;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(p['name'] as String),
                  backgroundColor: isMatch ? _accentColor.withOpacity(0.25) : AppColors.surfaceVariant,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isMatch ? _accentColor : AppColors.textPrimary,
                    fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isMatch ? _accentColor : AppColors.border,
                    width: 1.0,
                  ),
                  onPressed: () {
                    _applyConfig(cfg.copyWith(isEnabled: true));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          title: 'Shift Amount',
          valueText: '${(_config.shiftAmount * 100).round()}%',
          value: _config.shiftAmount,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(shiftAmount: v)),
        ),
        if (_config.mode == ChromaticAberrationMode.prismaticAngle ||
            _config.mode == ChromaticAberrationMode.hologramJitter)
          _buildSliderTile(
            title: 'Displacement Vector Angle',
            valueText: '${_config.angleDeg.round()}°',
            value: _config.angleDeg,
            min: 0.0,
            max: 360.0,
            onChanged: (v) => _applyConfig(_config.copyWith(angleDeg: v)),
          ),
        if (_config.mode == ChromaticAberrationMode.hologramJitter)
          _buildSliderTile(
            title: 'Glitch Jitter Speed',
            valueText: '${_config.jitterSpeed.toStringAsFixed(1)} Hz',
            value: _config.jitterSpeed,
            min: 0.5,
            max: 10.0,
            onChanged: (v) => _applyConfig(_config.copyWith(jitterSpeed: v)),
          ),
        if (_config.mode == ChromaticAberrationMode.radialDispersion)
          _buildSliderTile(
            title: 'Radial Edge Falloff',
            valueText: '${(_config.falloff * 100).round()}%',
            value: _config.falloff,
            min: 0.1,
            max: 1.0,
            onChanged: (v) => _applyConfig(_config.copyWith(falloff: v)),
          ),
        _buildSliderTile(
          title: 'Color Channel Intensity',
          valueText: '${(_config.colorMix * 100).round()}%',
          value: _config.colorMix,
          min: 0.2,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(colorMix: v)),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
            Text(
              valueText,
              style: AppTypography.bodySmall.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: AppColors.surfaceVariant,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withOpacity(0.15),
            trackHeight: 3.5,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Custom Skia painter displaying animated RGB color split preview.
class _ChromaticAberrationPainter extends CustomPainter {
  final ChromaticAberrationConfig config;
  final Color accentColor;
  final double time;

  _ChromaticAberrationPainter({
    required this.config,
    required this.accentColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width * 0.5, height * 0.5);

    // Subtle optical grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (!config.isActive) {
      // Draw single white crosshair when disabled
      final whitePaint = Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, 28, whitePaint);
      canvas.drawLine(Offset(center.dx - 36, center.dy), Offset(center.dx + 36, center.dy), whitePaint);
      canvas.drawLine(Offset(center.dx, center.dy - 36), Offset(center.dx, center.dy + 36), whitePaint);
      return;
    }

    // Calculate displacement vector
    double maxShift = config.shiftAmount * 22.0;
    double rad = config.angleDeg * (math.pi / 180.0);

    if (config.mode == ChromaticAberrationMode.hologramJitter) {
      final osc = math.sin(time * 2 * math.pi * config.jitterSpeed);
      maxShift *= osc;
    }

    double dx = maxShift;
    double dy = 0.0;

    if (config.mode == ChromaticAberrationMode.prismaticAngle ||
        config.mode == ChromaticAberrationMode.hologramJitter) {
      dx = maxShift * math.cos(rad);
      dy = maxShift * math.sin(rad);
    }

    // Draw Red Channel Layer (displaced +dx, +dy)
    final redPaint = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(config.colorMix * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    _drawOpticalGlyph(canvas, center.translate(dx, dy), redPaint);

    // Draw Green Channel Layer (anchored center)
    final greenPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(config.colorMix * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    _drawOpticalGlyph(canvas, center, greenPaint);

    // Draw Blue/Cyan Channel Layer (displaced -dx, -dy)
    final bluePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(config.colorMix * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    _drawOpticalGlyph(canvas, center.translate(-dx, -dy), bluePaint);

    // Radial dispersion rays if in radial mode
    if (config.mode == ChromaticAberrationMode.radialDispersion) {
      final rayPaint = Paint()
        ..color = accentColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, 40, rayPaint);
      canvas.drawCircle(center, 65, rayPaint);
    }
  }

  void _drawOpticalGlyph(Canvas canvas, Offset pos, Paint paint) {
    canvas.drawCircle(pos, 24, paint);
    canvas.drawLine(Offset(pos.dx - 34, pos.dy), Offset(pos.dx + 34, pos.dy), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 34), Offset(pos.dx, pos.dy + 34), paint);
    canvas.drawRect(Rect.fromCenter(center: pos, width: 28, height: 28), paint);
  }

  @override
  bool shouldRepaint(covariant _ChromaticAberrationPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.time != time;
  }
}
