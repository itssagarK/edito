import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/radial_zoom_blur_config.dart';
import '../../services/radial_zoom_blur_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring anamorphic
/// radial zoom blur and angular rotational vortex motion.
class RadialZoomBlurSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const RadialZoomBlurSheet({
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
      builder: (context) => RadialZoomBlurSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<RadialZoomBlurSheet> createState() => _RadialZoomBlurSheetState();
}

class _RadialZoomBlurSheetState extends State<RadialZoomBlurSheet>
    with SingleTickerProviderStateMixin {
  late RadialZoomBlurConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.radialZoomBlur;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(RadialZoomBlurConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(radialZoomBlur: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case RadialZoomBlurMode.hyperspaceWarp:
        return const Color(0xFF00E5FF);
      case RadialZoomBlurMode.actionImpactZoom:
        return const Color(0xFFFF5252);
      case RadialZoomBlurMode.anamorphicVortex:
        return const Color(0xFFE040FB);
      case RadialZoomBlurMode.subtleFocusPunch:
        return const Color(0xFFFFD700);
      case RadialZoomBlurMode.dizzySpin:
        return const Color(0xFF69F0AE);
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
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.surfaceElevated, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonitorCard(),
                    const SizedBox(height: 14),
                    _buildModeSelector(),
                    const SizedBox(height: 14),
                    _buildPresetRow(),
                    const SizedBox(height: 16),
                    _buildSliders(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isDocked) return content;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (_, controller) => content,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceElevated, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.blur_circular, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radial Zoom Blur',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • ${(_config.blurAmount * 100).round()}% Blur'
                      : 'Disabled',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isActive ? _accentColor : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _accentColor,
            onChanged: (val) {
              _applyConfig(_config.copyWith(isEnabled: val));
            },
          ),
          if (!widget.isDocked)
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                shape: const CircleBorder(),
              ),
              onPressed: () {
                widget.onDone?.call();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMonitorCard() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.4) : AppColors.surfaceElevated,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onPanUpdate: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final local = details.localPosition;
            final cx = (local.dx / 320.0).clamp(0.05, 0.95);
            final cy = (local.dy / 180.0).clamp(0.05, 0.95);
            _applyConfig(_config.copyWith(centerX: cx, centerY: cy));
          }
        },
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _RadialZoomBlurPainter(
                config: _config,
                accentColor: _accentColor,
                progress: _animController.value,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _accentColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        'FOCUS: X ${(_config.centerX * 100).round()}% | Y ${(_config.centerY * 100).round()}%',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Text(
                      'TAP/DRAG TO SET FOCAL CENTER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        letterSpacing: 0.8,
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

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BLUR DYNAMICS MODE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: RadialZoomBlurMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final mode = RadialZoomBlurMode.values[idx];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _accentColor.withOpacity(0.25),
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSelected ? _accentColor : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? _accentColor : Colors.transparent,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresetRow() {
    final presets = [
      ('Hyperspace', RadialZoomBlurConfig.presetHyperspace),
      ('Impact Slam', RadialZoomBlurConfig.presetImpactSlam),
      ('Spiral Vortex', RadialZoomBlurConfig.presetAnamorphicSpiral),
      ('Focus Punch', RadialZoomBlurConfig.presetFocusPunch),
      ('Dizzy Whirl', RadialZoomBlurConfig.presetDizzyWhirlwind),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: presets.map((preset) {
            return ActionChip(
              label: Text(preset.$1),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              onPressed: () {
                _applyConfig(preset.$2);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          title: 'Blur Intensity',
          value: _config.blurAmount,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.blurAmount * 100).round()}%',
          onChanged: (v) => _applyConfig(_config.copyWith(blurAmount: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'Angular Rotation Spin',
          value: _config.rotationSpin,
          min: -90.0,
          max: 90.0,
          displayValue: '${_config.rotationSpin.round()}°',
          onChanged: (v) => _applyConfig(_config.copyWith(rotationSpin: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'Sample Quality Taps',
          value: _config.sampleQuality.toDouble(),
          min: 3.0,
          max: 12.0,
          divisions: 9,
          displayValue: '${_config.sampleQuality} taps',
          onChanged: (v) => _applyConfig(_config.copyWith(sampleQuality: v.round())),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.waves, color: _accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rhythmic Pulsation',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Oscillates blur shockwave in rhythm with audio tempo',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _config.isPulsing,
                activeColor: _accentColor,
                onChanged: (val) {
                  _applyConfig(_config.copyWith(isPulsing: val));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset Defaults'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () {
                _applyConfig(RadialZoomBlurConfig.defaultDisabled);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
            Text(
              displayValue,
              style: AppTypography.labelSmall.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: AppColors.surfaceElevated,
            thumbColor: _accentColor,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Skia custom painter visualizing dynamic radial zoom blur rays and focal crosshair.
class _RadialZoomBlurPainter extends CustomPainter {
  final RadialZoomBlurConfig config;
  final Color accentColor;
  final double progress;

  _RadialZoomBlurPainter({
    required this.config,
    required this.accentColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * config.centerX, size.height * config.centerY);

    // Subtle background grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!config.isActive) {
      // Idle crosshair
      final idlePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, 12, idlePaint..style = PaintingStyle.stroke);
      canvas.drawLine(center.translate(-16, 0), center.translate(16, 0), idlePaint);
      canvas.drawLine(center.translate(0, -16), center.translate(0, 16), idlePaint);
      return;
    }

    final pulse = config.isPulsing ? (1.0 + 0.3 * math.sin(progress * 2 * math.pi)) : 1.0;
    final blurScale = config.blurAmount * pulse;
    final rayCount = (config.sampleQuality * 4).clamp(16, 48);
    final spinRad = config.rotationSpin * math.pi / 180.0;

    // Draw radiating speed rays
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + (progress * spinRad * 0.5);
      final rayDist = math.max(size.width, size.height) * (0.8 + 0.4 * math.sin(i * 3.7 + progress * 6.28));
      final rayAlpha = (0.2 + 0.5 * math.sin(i * 1.5).abs()) * blurScale;

      final startDist = 18.0 * (1.0 - blurScale * 0.5);
      final start = Offset(
        center.dx + math.cos(angle) * startDist,
        center.dy + math.sin(angle) * startDist,
      );

      final end = Offset(
        center.dx + math.cos(angle + spinRad * 0.15) * rayDist,
        center.dy + math.sin(angle + spinRad * 0.15) * rayDist,
      );

      final rayPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            accentColor.withOpacity(rayAlpha.clamp(0.0, 0.8)),
            accentColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 1.5 + 2.0 * blurScale
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, rayPaint);
    }

    // Concentric shockwave rings
    for (int r = 1; r <= 3; r++) {
      final ringProgress = (progress + r / 3.0) % 1.0;
      final ringRadius = ringProgress * 120.0 * blurScale + 8;
      final ringAlpha = (1.0 - ringProgress) * 0.5 * blurScale;
      final ringPaint = Paint()
        ..color = accentColor.withOpacity(ringAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // High-visibility focal target reticle
    final targetPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 14, targetPaint);
    canvas.drawCircle(center, 4, Paint()..color = accentColor);
    canvas.drawLine(center.translate(-22, 0), center.translate(-14, 0), targetPaint);
    canvas.drawLine(center.translate(14, 0), center.translate(22, 0), targetPaint);
    canvas.drawLine(center.translate(0, -22), center.translate(0, -14), targetPaint);
    canvas.drawLine(center.translate(0, 14), center.translate(0, 22), targetPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialZoomBlurPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
