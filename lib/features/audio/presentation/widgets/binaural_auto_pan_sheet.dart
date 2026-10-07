import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/binaural_auto_pan_config.dart';
import '../../services/binaural_auto_pan_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring 3D binaural
/// auto-pan rotation and Doppler pitch swell effects.
class BinauralAutoPanSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const BinauralAutoPanSheet({
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
      builder: (context) => BinauralAutoPanSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<BinauralAutoPanSheet> createState() => _BinauralAutoPanSheetState();
}

class _BinauralAutoPanSheetState extends State<BinauralAutoPanSheet>
    with SingleTickerProviderStateMixin {
  late BinauralAutoPanConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.binauralAutoPan;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(BinauralAutoPanConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(binauralAutoPan: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case BinauralAutoPanMode.circular3DOrbit:
        return const Color(0xFF00E5FF);
      case BinauralAutoPanMode.pendulumSwing:
        return const Color(0xFFFF9100);
      case BinauralAutoPanMode.dopplerFlyby:
        return const Color(0xFFFF1744);
      case BinauralAutoPanMode.chaoticVortex:
        return const Color(0xFFE040FB);
      case BinauralAutoPanMode.subtleStereoSpread:
        return const Color(0xFF00E676);
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
            child: Icon(Icons.surround_sound, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Binaural Auto-Pan',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • ${_config.rateHz.toStringAsFixed(2)} Hz'
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
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.4) : AppColors.surfaceElevated,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: _BinauralAutoPanPainter(
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
                      '3D SOUNDSTAGE: ${_config.mode.label.toUpperCase()}',
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
                  top: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF00E676), size: 10),
                        SizedBox(width: 4),
                        Text(
                          'LIMITER GUARD',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Text(
                    'L / R STEREO PAN METERS',
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
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPATIAL MOTION TRAJECTORY',
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
            itemCount: BinauralAutoPanMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final mode = BinauralAutoPanMode.values[idx];
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
      ('3D Orbit', BinauralAutoPanConfig.presetHeadphoneOrbit),
      ('Metronome', BinauralAutoPanConfig.presetMetronomeSwing),
      ('Jet Doppler', BinauralAutoPanConfig.presetJetDopplerPass),
      ('Crazy Vortex', BinauralAutoPanConfig.presetCrazyVortex),
      ('Ambient Spread', BinauralAutoPanConfig.presetAmbientSpatial),
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
          title: 'Pan Modulation Rate',
          value: _config.rateHz,
          min: 0.05,
          max: 4.0,
          displayValue: '${_config.rateHz.toStringAsFixed(2)} Hz',
          onChanged: (v) => _applyConfig(_config.copyWith(rateHz: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'Stereo Pan Depth',
          value: _config.depth,
          min: 0.1,
          max: 1.0,
          displayValue: '${(_config.depth * 100).round()}%',
          onChanged: (v) => _applyConfig(_config.copyWith(depth: v, isEnabled: true)),
        ),
        _buildSliderTile(
          title: 'Doppler Pitch Warp',
          value: _config.dopplerIntensity,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.dopplerIntensity * 100).round()}%',
          onChanged: (v) => _applyConfig(_config.copyWith(dopplerIntensity: v)),
        ),
        _buildSliderTile(
          title: '3D Vertical Elevation',
          value: _config.elevation,
          min: -1.0,
          max: 1.0,
          displayValue: _config.elevation == 0
              ? 'Level (0°)'
              : _config.elevation > 0
                  ? '+${(_config.elevation * 45).round()}° (Above)'
                  : '${(_config.elevation * 45).round()}° (Below)',
          onChanged: (v) => _applyConfig(_config.copyWith(elevation: v)),
        ),
        _buildSliderTile(
          title: 'Binaural Stereo Spread',
          value: _config.stereoSpread,
          min: 0.5,
          max: 2.0,
          displayValue: '${_config.stereoSpread.toStringAsFixed(1)}x',
          onChanged: (v) => _applyConfig(_config.copyWith(stereoSpread: v)),
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
                _applyConfig(BinauralAutoPanConfig.defaultDisabled);
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
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Skia custom painter visualizing dynamic 3D binaural soundstage,
/// listener head node, orbiting sound source, and L/R pan level meters.
class _BinauralAutoPanPainter extends CustomPainter {
  final BinauralAutoPanConfig config;
  final Color accentColor;
  final double progress;

  _BinauralAutoPanPainter({
    required this.config,
    required this.accentColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radarRadius = math.min(size.width, size.height) * 0.40;

    // 1. Radar background rings
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radarRadius, gridPaint);
    canvas.drawCircle(center, radarRadius * 0.65, gridPaint);
    canvas.drawCircle(center, radarRadius * 0.35, gridPaint);

    // Crosshairs (Front, Back, Left, Right)
    canvas.drawLine(center.translate(-radarRadius, 0), center.translate(radarRadius, 0), gridPaint);
    canvas.drawLine(center.translate(0, -radarRadius), center.translate(0, radarRadius), gridPaint);

    // 2. Central Listener Head Silhouette & Headphones
    final headPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Head circle
    canvas.drawCircle(center, 10, headPaint);
    // Nose pointer (facing up = Front)
    final nosePath = Path()
      ..moveTo(center.dx - 3, center.dy - 9)
      ..lineTo(center.dx, center.dy - 15)
      ..lineTo(center.dx + 3, center.dy - 9)
      ..close();
    canvas.drawPath(nosePath, headPaint);

    // Left & Right Headphones cups
    final earPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(-14, 0), width: 5, height: 12),
        const Radius.circular(2),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(14, 0), width: 5, height: 12),
        const Radius.circular(2),
      ),
      earPaint,
    );

    if (!config.isActive) return;

    // 3. Compute Orbiting Sound Source Position
    final orbitTime = progress * 2 * math.pi;
    double panX = 0;
    double panY = 0;

    switch (config.mode) {
      case BinauralAutoPanMode.circular3DOrbit:
        panX = math.sin(orbitTime);
        panY = -math.cos(orbitTime);
        break;
      case BinauralAutoPanMode.pendulumSwing:
        panX = math.sin(orbitTime);
        panY = 0.2 * math.cos(orbitTime * 2);
        break;
      case BinauralAutoPanMode.dopplerFlyby:
        panX = (math.sin(orbitTime) * 1.3).clamp(-1.0, 1.0);
        panY = math.cos(orbitTime * 0.5) * 0.4;
        break;
      case BinauralAutoPanMode.chaoticVortex:
        panX = math.sin(orbitTime * 1.5) * 0.8;
        panY = math.cos(orbitTime * 2.3) * 0.8;
        break;
      case BinauralAutoPanMode.subtleStereoSpread:
        panX = math.sin(orbitTime * 0.8) * 0.5;
        panY = math.cos(orbitTime * 0.8) * 0.3;
        break;
    }

    final sourcePos = Offset(
      center.dx + panX * radarRadius * config.depth,
      center.dy + panY * radarRadius * config.depth * (1.0 - config.elevation.abs() * 0.3),
    );

    // 4. Sound Wave Ripple Rings
    final rippleCount = 3;
    for (int i = 0; i < rippleCount; i++) {
      final rProgress = (progress * 2 + i / rippleCount) % 1.0;
      final rRadius = rProgress * 28.0 + 4;
      final rAlpha = (1.0 - rProgress) * 0.7 * config.depth;

      final wavePaint = Paint()
        ..color = accentColor.withOpacity(rAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(sourcePos, rRadius, wavePaint);
    }

    // 5. Sound Source Node
    final sourcePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sourcePos, 6.0, sourcePaint);
    canvas.drawCircle(sourcePos, 2.0, Paint()..color = Colors.white);

    // Connecting sound vector ray to listener
    final rayPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, sourcePos, rayPaint);

    // 6. Dynamic L/R Stereo Volume Level Meters (Vertical bars on bottom corners)
    final panNorm = (panX + 1.0) / 2.0; // 0.0 (full left) to 1.0 (full right)
    final leftLevel = ((1.0 - panNorm * config.depth) * 0.9 + 0.1).clamp(0.1, 1.0);
    final rightLevel = ((panNorm * config.depth) * 0.9 + 0.1).clamp(0.1, 1.0);

    const mWidth = 12.0;
    const mMaxH = 40.0;
    final bY = size.height - 12.0;

    // Left Meter
    final leftRect = Rect.fromLTWH(14, bY - (mMaxH * leftLevel), mWidth, mMaxH * leftLevel);
    canvas.drawRect(
      Rect.fromLTWH(14, bY - mMaxH, mWidth, mMaxH),
      Paint()..color = AppColors.surfaceElevated,
    );
    canvas.drawRect(leftRect, Paint()..color = accentColor);

    // Right Meter
    final rightRect = Rect.fromLTWH(size.width - 26, bY - (mMaxH * rightLevel), mWidth, mMaxH * rightLevel);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 26, bY - mMaxH, mWidth, mMaxH),
      Paint()..color = AppColors.surfaceElevated,
    );
    canvas.drawRect(rightRect, Paint()..color = accentColor);

    // L / R Text labels
    final lText = TextSpan(
      text: 'L',
      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
    );
    TextPainter(text: lText, textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(16, bY - mMaxH - 14));

    final rText = TextSpan(
      text: 'R',
      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
    );
    TextPainter(text: rText, textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(size.width - 24, bY - mMaxH - 14));
  }

  @override
  bool shouldRepaint(covariant _BinauralAutoPanPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
