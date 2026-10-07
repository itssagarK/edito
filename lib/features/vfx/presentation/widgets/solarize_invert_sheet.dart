import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/solarize_invert_config.dart';
import '../../services/solarize_invert_compiler_service.dart';

class SolarizeInvertSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SolarizeInvertSheet({
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
      builder: (context) => SolarizeInvertSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<SolarizeInvertSheet> createState() => _SolarizeInvertSheetState();
}

class _SolarizeInvertSheetState extends State<SolarizeInvertSheet> with SingleTickerProviderStateMixin {
  late SolarizeInvertConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.solarizeInvert;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(SolarizeInvertConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(solarizeInvert: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case SolarizeInvertMode.sabattier:
        return const Color(0xFFFF9100); // Amber solarize
      case SolarizeInvertMode.negativeInvert:
        return const Color(0xFF00E5FF); // Cyan negative
      case SolarizeInvertMode.psychedelic:
        return const Color(0xFFE040FB); // Neon purple acid trip
      case SolarizeInvertMode.thermalHeat:
        return const Color(0xFFFF1744); // Thermal crimson
      case SolarizeInvertMode.crossProcess:
        return const Color(0xFF76FF03); // Cross-process neon lime
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
          Icon(Icons.wb_sunny_outlined, color: _accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thermal Solarization & Invert',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Tone inflection curves, Sabattier effect & negative film',
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
        color: const Color(0xFF0A0D14),
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
              painter: _SolarizeCurvePainter(
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
                                ? 'TONE INFLECTION CURVE • THRESH: ${(_config.threshold * 100).round()}%'
                                : 'LINEAR TONAL RESPONSE',
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
                        'TRANSFER • ${_config.mode.displayName.toUpperCase()}',
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
                _config.isEnabled ? Icons.invert_colors : Icons.invert_colors_off,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solarization & Invert',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _config.isEnabled ? 'Tone inflection curve active' : 'Natural photorealistic tones',
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
          'INVERSION PROFILE',
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
          children: SolarizeInvertMode.values.map((mode) {
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
      {'name': 'Sabattier Solarize', 'cfg': SolarizeInvertConfig.sabattierSolarize},
      {'name': 'Film Negative', 'cfg': SolarizeInvertConfig.negativeFilm},
      {'name': 'Acid Trip', 'cfg': SolarizeInvertConfig.acidTrip},
      {'name': 'Thermal Infrared', 'cfg': SolarizeInvertConfig.thermalInfrared},
      {'name': 'Darkroom Cross', 'cfg': SolarizeInvertConfig.darkroomCross},
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
              final cfg = p['cfg'] as SolarizeInvertConfig;
              final isMatch = _config.mode == cfg.mode &&
                  (_config.threshold - cfg.threshold).abs() < 0.05;

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
        if (_config.mode == SolarizeInvertMode.sabattier ||
            _config.mode == SolarizeInvertMode.psychedelic ||
            _config.mode == SolarizeInvertMode.thermalHeat)
          _buildSliderTile(
            title: 'Inflection Threshold',
            valueText: '${(_config.threshold * 100).round()}%',
            value: _config.threshold,
            min: 0.1,
            max: 0.9,
            onChanged: (v) => _applyConfig(_config.copyWith(threshold: v)),
          ),
        _buildSliderTile(
          title: 'Effect Intensity / Mix',
          valueText: '${(_config.intensity * 100).round()}%',
          value: _config.intensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(intensity: v)),
        ),
        _buildSliderTile(
          title: 'Saturation Boost',
          valueText: '${_config.saturationBoost.toStringAsFixed(2)}x',
          value: _config.saturationBoost,
          min: 1.0,
          max: 2.5,
          onChanged: (v) => _applyConfig(_config.copyWith(saturationBoost: v)),
        ),
        if (_config.mode == SolarizeInvertMode.psychedelic ||
            _config.mode == SolarizeInvertMode.thermalHeat)
          _buildSliderTile(
            title: 'False-Color Tint Hue',
            valueText: '${_config.tintHue.round()}°',
            value: _config.tintHue,
            min: 0.0,
            max: 360.0,
            onChanged: (v) => _applyConfig(_config.copyWith(tintHue: v)),
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

/// Custom Skia painter displaying tone transfer curve and inflection points.
class _SolarizeCurvePainter extends CustomPainter {
  final SolarizeInvertConfig config;
  final Color accentColor;
  final double time;

  _SolarizeCurvePainter({
    required this.config,
    required this.accentColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Graph bounds with padding
    const padL = 36.0;
    const padR = 20.0;
    const padT = 24.0;
    const padB = 24.0;
    final plotW = width - padL - padR;
    final plotH = height - padT - padB;

    // Subtle graph grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final gx = padL + (plotW * (i / 4));
      final gy = padT + (plotH * (i / 4));
      canvas.drawLine(Offset(gx, padT), Offset(gx, height - padB), gridPaint);
      canvas.drawLine(Offset(padL, gy), Offset(width - padR, gy), gridPaint);
    }

    // Graph axes
    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(padL, padT), Offset(padL, height - padB), axisPaint);
    canvas.drawLine(Offset(padL, height - padB), Offset(width - padR, height - padB), axisPaint);

    if (!config.isActive) {
      // Linear diagonal reference line
      final refPaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(padL, height - padB), Offset(width - padR, padT), refPaint);
      return;
    }

    // Draw tone transfer curve
    final curvePath = Path();
    final steps = 60;
    for (int i = 0; i <= steps; i++) {
      final inVal = i / steps; // 0.0 to 1.0
      double outVal = inVal;

      switch (config.mode) {
        case SolarizeInvertMode.negativeInvert:
          outVal = 1.0 - inVal;
          break;

        case SolarizeInvertMode.sabattier:
          if (inVal > config.threshold) {
            outVal = 1.0 - inVal;
          } else {
            outVal = inVal;
          }
          break;

        case SolarizeInvertMode.psychedelic:
          final phase = (inVal * 2 * math.pi) + (time * math.pi);
          outVal = (math.sin(phase) + 1.0) * 0.5;
          break;

        case SolarizeInvertMode.thermalHeat:
          if (inVal < 0.33) {
            outVal = inVal * 1.5;
          } else if (inVal < 0.66) {
            outVal = 1.0 - ((inVal - 0.33) * 0.8);
          } else {
            outVal = (inVal * 0.7) + 0.3;
          }
          break;

        case SolarizeInvertMode.crossProcess:
          // S-Curve with shadow inflection
          outVal = 1.0 / (1.0 + math.exp(-6.0 * (inVal - 0.5)));
          if (inVal < 0.25) outVal = 0.25 - inVal;
          break;
      }

      // Mix with linear based on intensity
      outVal = (outVal * config.intensity) + (inVal * (1.0 - config.intensity));
      outVal = outVal.clamp(0.0, 1.0);

      final px = padL + (inVal * plotW);
      final py = (height - padB) - (outVal * plotH);

      if (i == 0) {
        curvePath.moveTo(px, py);
      } else {
        curvePath.lineTo(px, py);
      }
    }

    // Glowing tone curve
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, glowPaint);

    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    // Inflection threshold vertical guide for Sabattier
    if (config.mode == SolarizeInvertMode.sabattier ||
        config.mode == SolarizeInvertMode.psychedelic) {
      final threshX = padL + (config.threshold * plotW);
      final threshPaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.2;

      // Draw dashed line
      for (double y = padT; y < height - padB; y += 8) {
        canvas.drawLine(Offset(threshX, y), Offset(threshX, math.min(y + 4, height - padB)), threshPaint);
      }

      // Highlight inflection point dot
      canvas.drawCircle(Offset(threshX, (height - padB) - (config.threshold * plotH)), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(threshX, (height - padB) - (config.threshold * plotH)), 2.5, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SolarizeCurvePainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.time != time;
  }
}
