import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/diamond_prism_config.dart';
import '../../services/diamond_prism_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring optical diamond
/// glass prism refractions and chromatic rainbow dispersion.
class DiamondPrismSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const DiamondPrismSheet({
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
      builder: (context) => DiamondPrismSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<DiamondPrismSheet> createState() => _DiamondPrismSheetState();
}

class _DiamondPrismSheetState extends State<DiamondPrismSheet>
    with SingleTickerProviderStateMixin {
  late DiamondPrismConfig _config;
  late AnimationController _animController;
  bool _isAuditionBypass = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.diamondPrism;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(DiamondPrismConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(diamondPrism: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case DiamondPrismMode.brilliantCut:
        return const Color(0xFF00E5FF);
      case DiamondPrismMode.emeraldFacet:
        return const Color(0xFF00E676);
      case DiamondPrismMode.triangularPrism:
        return const Color(0xFFFF4081);
      case DiamondPrismMode.kaleidoCrystal:
        return const Color(0xFF7C4DFF);
      case DiamondPrismMode.spectralHeart:
        return const Color(0xFFFF1744);
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
            child: Icon(Icons.diamond_outlined, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diamond Prism Refraction',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isActive
                      ? '${_config.mode.label} • ${(_config.dispersionStrength * 100).round()}% Dispersion'
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        const cardHeight = 160.0;

        return Container(
          height: cardHeight,
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
                // Interactive 2D Draggable Skia Canvas
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final local = details.localPosition;
                      final nx = (local.dx / cardWidth).clamp(0.05, 0.95);
                      final ny = (local.dy / cardHeight).clamp(0.05, 0.95);
                      _applyConfig(_config.copyWith(
                        centerX: nx,
                        centerY: ny,
                        isEnabled: true,
                      ));
                    },
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _DiamondPrismPainter(
                            config: _isAuditionBypass ? DiamondPrismConfig.defaultDisabled : _config,
                            phase: _animController.value,
                            accentColor: _accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Badge Tag
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
                      const DiamondPrismCompilerService().getPrismBadge(_config),
                      style: AppTypography.labelSmall.copyWith(
                        color: _accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Drag reticle hint
                Positioned(
                  left: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DRAG TO POSITION APEX',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                // A/B Audition Button
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
      },
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FACET GEOMETRY',
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
            itemCount: DiamondPrismMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = DiamondPrismMode.values[index];
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
      ('Brilliant Diamond', DiamondPrismConfig.presetBrilliantDiamond, Icons.diamond),
      ('Newton Prism', DiamondPrismConfig.presetNewtonPrism, Icons.change_history),
      ('Emerald Chamber', DiamondPrismConfig.presetEmeraldChamber, Icons.crop_square),
      ('Cosmic Crystal', DiamondPrismConfig.presetCosmicCrystal, Icons.auto_awesome),
      ('Subtle Glass Edge', DiamondPrismConfig.presetSubtleGlassEdge, Icons.filter_vintage),
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
                  (_config.dispersionStrength - preset.dispersionStrength).abs() < 0.05;

              return InkWell(
                onTap: () => _applyConfig(preset),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 124,
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
          label: 'Rainbow Dispersion',
          value: _config.dispersionStrength,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.dispersionStrength * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(dispersionStrength: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Refraction Angle',
          value: _config.refractionAngle,
          min: 0.0,
          max: 360.0,
          displayValue: '${_config.refractionAngle.round()}°',
          onChanged: (val) => _applyConfig(_config.copyWith(refractionAngle: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Inner Reflection & Glints',
          value: _config.innerReflectionIntensity,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.innerReflectionIntensity * 100).round()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(innerReflectionIntensity: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Spectral Saturation',
          value: _config.spectralSaturation,
          min: 0.5,
          max: 2.0,
          displayValue: '${_config.spectralSaturation.toStringAsFixed(1)}x',
          onChanged: (val) => _applyConfig(_config.copyWith(spectralSaturation: val, isEnabled: true)),
        ),
        _buildSliderRow(
          label: 'Facet Division Count',
          value: _config.facetCount.toDouble(),
          min: 3.0,
          max: 12.0,
          displayValue: '${_config.facetCount}',
          onChanged: (val) => _applyConfig(_config.copyWith(facetCount: val.round(), isEnabled: true)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prism Rotational Drift',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              Switch.adaptive(
                value: _config.isRotating,
                activeColor: _accentColor,
                onChanged: (val) => _applyConfig(_config.copyWith(isRotating: val, isEnabled: true)),
              ),
            ],
          ),
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

/// Skia Canvas painter rendering optical diamond glass facet refractions,
/// spectral rainbow chromatic dispersion strokes, and specular starburst flares.
class _DiamondPrismPainter extends CustomPainter {
  final DiamondPrismConfig config;
  final double phase; // 0.0 to 1.0
  final Color accentColor;

  _DiamondPrismPainter({
    required this.config,
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Dark crystalline background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (config.centerX - 0.5) * 2.0,
          (config.centerY - 0.5) * 2.0,
        ),
        radius: 0.9,
        colors: [
          const Color(0xFF141926),
          const Color(0xFF070A0F),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) return;

    final apex = Offset(size.width * config.centerX, size.height * config.centerY);
    final count = config.facetCount.clamp(3, 12);
    final dispersion = config.dispersionStrength;
    final reflection = config.innerReflectionIntensity;
    final rotAngle = config.isRotating ? (phase * 2 * math.pi) : 0.0;
    final baseAngle = (config.refractionAngle * math.pi / 180.0) + rotAngle;

    final maxRadius = math.max(size.width, size.height) * 0.7;

    // 1. Rainbow Spectral Facet Dispersion Rays
    final rainbowColors = [
      const Color(0xFFFF1744),
      const Color(0xFFFF9100),
      const Color(0xFFFFEA00),
      const Color(0xFF00E676),
      const Color(0xFF00E5FF),
      const Color(0xFF2979FF),
      const Color(0xFFD500F9),
      const Color(0xFFFF1744),
    ];

    for (int i = 0; i < count; i++) {
      final a1 = baseAngle + (i * 2 * math.pi / count);
      final a2 = baseAngle + ((i + 1) * 2 * math.pi / count);

      final p1 = Offset(apex.dx + math.cos(a1) * maxRadius, apex.dy + math.sin(a1) * maxRadius);
      final p2 = Offset(apex.dx + math.cos(a2) * maxRadius, apex.dy + math.sin(a2) * maxRadius);

      final facetPath = Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      // Shaded translucent facet body
      final facetColor = rainbowColors[i % rainbowColors.length];
      final facetFill = Paint()
        ..color = facetColor.withOpacity(0.08 * dispersion * (i % 2 == 0 ? 1.0 : 0.6))
        ..style = PaintingStyle.fill;
      canvas.drawPath(facetPath, facetFill);

      // Prismatic Rainbow Stroke along facet boundary
      final rainbowStroke = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.7 * dispersion),
            facetColor.withOpacity(0.85 * dispersion),
            Colors.transparent,
          ],
        ).createShader(Rect.fromPoints(apex, p1))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(apex, p1, rainbowStroke);

      // Inner reflection bounce line
      if (reflection > 0.15) {
        final midP = Offset((p1.dx + p2.dx) * 0.5, (p1.dy + p2.dy) * 0.5);
        final innerReflect = Paint()
          ..color = Colors.white.withOpacity(0.35 * reflection)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(apex, midP, innerReflect);
      }

      // Specular Starburst glint at facet vertex
      final glintDist = maxRadius * 0.45;
      final glintPos = Offset(apex.dx + math.cos(a1) * glintDist, apex.dy + math.sin(a1) * glintDist);
      _drawStarburstGlint(canvas, glintPos, (4.0 + reflection * 8.0), facetColor, reflection);
    }

    // 2. Diamond Focal Apex Crown Starburst
    _drawStarburstGlint(canvas, apex, 14.0 * (0.8 + reflection * 0.8), Colors.white, 0.9);

    // 3. Focal Reticle Ring
    final reticlePaint = Paint()
      ..color = accentColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(apex, 8, reticlePaint);
    canvas.drawCircle(apex, 2, Paint()..color = accentColor);
  }

  void _drawStarburstGlint(Canvas canvas, Offset pos, double radius, Color color, double opacity) {
    final glintPaint = Paint()
      ..color = Colors.white.withOpacity((opacity * 0.8).clamp(0.0, 1.0))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final auraPaint = Paint()
      ..color = color.withOpacity((opacity * 0.4).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    // Diffuse aura
    canvas.drawCircle(pos, radius * 0.6, auraPaint);

    // 4-pointed cross star rays
    canvas.drawLine(pos.translate(-radius, 0), pos.translate(radius, 0), glintPaint);
    canvas.drawLine(pos.translate(0, -radius), pos.translate(0, radius), glintPaint);

    // Diagonal rays
    final diag = radius * 0.5;
    canvas.drawLine(pos.translate(-diag, -diag), pos.translate(diag, diag), glintPaint);
    canvas.drawLine(pos.translate(-diag, diag), pos.translate(diag, -diag), glintPaint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPrismPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.phase != phase ||
        oldDelegate.accentColor != accentColor;
  }
}
