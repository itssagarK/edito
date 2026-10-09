import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/water_caustics_config.dart';
import '../../services/water_caustics_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring liquid water
/// caustics, wave ripples, and underwater light refractions.
class WaterCausticsSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const WaterCausticsSheet({
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
      builder: (context) => WaterCausticsSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<WaterCausticsSheet> createState() => _WaterCausticsSheetState();
}

class _WaterCausticsSheetState extends State<WaterCausticsSheet>
    with SingleTickerProviderStateMixin {
  late WaterCausticsConfig _config;
  late AnimationController _animController;
  bool _isAuditionBypass = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.waterCaustics;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(WaterCausticsConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(waterCaustics: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case WaterCausticsMode.tropicalPool:
        return const Color(0xFF00E5FF);
      case WaterCausticsMode.abyssalDeep:
        return const Color(0xFF2979FF);
      case WaterCausticsMode.emeraldLagoon:
        return const Color(0xFF00E676);
      case WaterCausticsMode.bioluminescentReef:
        return const Color(0xFFD500F9);
      case WaterCausticsMode.sunkenGold:
        return const Color(0xFFFFD600);
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
                    _buildPreviewMonitorCard(),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildPresetsCarousel(),
                    const SizedBox(height: 16),
                    _buildControlSliders(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceElevated, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.water_drop_outlined, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquid Water Caustics',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • ${(_config.intensity * 100).round()}% Intensity'
                      : 'Disabled',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isActive ? _accentColor : AppColors.textMuted,
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
          if (!widget.isDocked && widget.onDone != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.textPrimary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                padding: const EdgeInsets.all(8),
              ),
              onPressed: widget.onDone,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewMonitorCard() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.5) : AppColors.surfaceElevated,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WaterCausticsPainter(
                      config: _isAuditionBypass ? WaterCausticsConfig.defaultDisabled : _config,
                      phase: _animController.value,
                      accentColor: _accentColor,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  const WaterCausticsCompilerService().getCausticsBadge(_config),
                  style: AppTypography.labelSmall.copyWith(
                    color: _accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isAuditionBypass = true),
                onTapUp: (_) => setState(() => _isAuditionBypass = false),
                onTapCancel: () => setState(() => _isAuditionBypass = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAuditionBypass ? _accentColor : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HOLD A/B',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isAuditionBypass ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AQUATIC ENVIRONMENT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WaterCausticsMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = WaterCausticsMode.values[index];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _accentColor.withOpacity(0.25),
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: isSelected ? _accentColor : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? _accentColor : Colors.transparent,
                    width: 1.2,
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

  Widget _buildPresetsCarousel() {
    final presets = [
      ('Tropical Lagoon', WaterCausticsConfig.presetTropicalLagoon, Icons.water_drop),
      ('Abyssal Trench', WaterCausticsConfig.presetAbyssalTrench, Icons.waves),
      ('Emerald Cenote', WaterCausticsConfig.presetEmeraldCenote, Icons.pool),
      ('Bioluminescent', WaterCausticsConfig.presetBioluminescentNight, Icons.flare),
      ('Shallow Sunlight', WaterCausticsConfig.presetShallowSunlight, Icons.wb_sunny),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (name, preset, icon) = presets[index];
              final isSelected = _config.mode == preset.mode &&
                  (_config.intensity - preset.intensity).abs() < 0.05;

              return InkWell(
                onTap: () => _applyConfig(preset),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor.withOpacity(0.15) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _accentColor : Colors.white.withOpacity(0.06),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: isSelected ? _accentColor : AppColors.textSecondary, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? _accentColor : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderRow(
          label: 'Caustic Intensity',
          value: _config.intensity,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.intensity * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(intensity: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Mesh Scale Density',
          value: _config.scale,
          min: 0.5,
          max: 3.0,
          displayValue: '${_config.scale.toStringAsFixed(1)}x',
          onChanged: (val) => _applyConfig(_config.copyWith(scale: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Ripple Speed',
          value: _config.speed,
          min: 0.2,
          max: 3.0,
          displayValue: '${_config.speed.toStringAsFixed(1)}x',
          onChanged: (val) => _applyConfig(_config.copyWith(speed: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Refraction Warp',
          value: _config.refractionWarp,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.refractionWarp * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(refractionWarp: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Chromatic Dispersion',
          value: _config.chromaticDispersion,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.chromaticDispersion * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(chromaticDispersion: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Aquatic Tint Depth',
          value: _config.tintDepth,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.tintDepth * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(tintDepth: val, isEnabled: true)),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
            Text(
              displayValue,
              style: AppTypography.labelMedium.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _accentColor,
            inactiveTrackColor: AppColors.surfaceElevated,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withOpacity(0.15),
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

/// Skia Canvas painter rendering procedural liquid water caustics light webs
/// and shimmering refractive wave ripples.
class _WaterCausticsPainter extends CustomPainter {
  final WaterCausticsConfig config;
  final double phase; // 0.0 to 1.0
  final Color accentColor;

  _WaterCausticsPainter({
    required this.config,
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Deep aquatic gradient background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF001824), accentColor, 0.15 * config.tintDepth)!,
          Color.lerp(const Color(0xFF000810), accentColor, 0.30 * config.tintDepth)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) return;

    final intensity = config.intensity;
    final scale = config.scale;
    final speed = config.speed;
    final time = phase * 2 * math.pi * speed;
    final dispersion = config.chromaticDispersion;

    // 2. Procedural Caustic Web Filaments
    // Generate overlapping harmonic wave interference networks
    final cols = (7 * scale).round().clamp(4, 16);
    final rows = (5 * scale).round().clamp(3, 12);
    final dx = size.width / cols;
    final dy = size.height / rows;

    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Base cyan/white glowing caustic paths
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x0 = c * dx;
        final y0 = r * dy;

        // Wave distortion offsets
        final wave1 = math.sin(time + c * 0.8 + r * 0.5) * 8.0 * config.refractionWarp;
        final wave2 = math.cos(time * 1.3 + c * 0.5 - r * 0.7) * 7.0 * config.refractionWarp;

        final start = Offset(x0 + wave1, y0 + wave2);
        final cp1 = Offset(x0 + dx * 0.4 + wave2, y0 + dy * 0.2 + wave1);
        final cp2 = Offset(x0 + dx * 0.7 - wave1, y0 + dy * 0.8 - wave2);
        final end = Offset(x0 + dx + wave2, y0 + dy + wave1);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

        // Chromatic dispersion fringe (red/cyan shift)
        if (dispersion > 0.1) {
          final shift = dispersion * 3.0;
          final redShiftPaint = Paint()
            ..color = const Color(0xFFFF5252).withOpacity(0.18 * intensity)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path.shift(Offset(shift, -shift * 0.5)), redShiftPaint);
        }

        // Main luminous caustic glow
        causticPaint
          ..color = accentColor.withOpacity(0.40 * intensity)
          ..strokeWidth = 2.2;
        canvas.drawPath(path, causticPaint);

        // Brilliant bright specular core
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(0.65 * intensity)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, corePaint);
      }
    }

    // 3. Shimmering Voronoi caustic node sparkle glints
    final glintPaint = Paint()..style = PaintingStyle.fill;
    final glintCount = (10 * scale).round().clamp(6, 24);
    for (int i = 0; i < glintCount; i++) {
      final gx = (math.sin(time * 0.7 + i * 1.6) * 0.5 + 0.5) * size.width;
      final gy = (math.cos(time * 0.9 + i * 2.1) * 0.5 + 0.5) * size.height;
      final pulse = (math.sin(time * 2.5 + i) * 0.5 + 0.5);
      final radius = (1.5 + pulse * 2.5) * intensity;

      glintPaint.color = Colors.white.withOpacity((0.3 + pulse * 0.5) * intensity);
      canvas.drawCircle(Offset(gx, gy), radius, glintPaint);

      // Diffuse halo
      glintPaint.color = accentColor.withOpacity((0.15 + pulse * 0.25) * intensity);
      canvas.drawCircle(Offset(gx, gy), radius * 2.4, glintPaint);
    }

    // 4. Underwater Vignette falloff
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.55 * config.tintDepth),
        ],
        stops: const [0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _WaterCausticsPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.phase != phase ||
        oldDelegate.accentColor != accentColor;
  }
}
