import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/kaleidoscope_config.dart';
import '../../services/kaleidoscope_compiler_service.dart';

class KaleidoscopeSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const KaleidoscopeSheet({
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
      builder: (context) => KaleidoscopeSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<KaleidoscopeSheet> createState() => _KaleidoscopeSheetState();
}

class _KaleidoscopeSheetState extends State<KaleidoscopeSheet> with SingleTickerProviderStateMixin {
  late KaleidoscopeConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.kaleidoscope;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(KaleidoscopeConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(kaleidoscope: updated);
    widget.onSave(updatedClip);
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
              _buildLiveMonitorCard(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildPatternSelector(),
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
            color: const Color(0xFFE040FB).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.auto_awesome_mosaic_rounded,
            color: Color(0xFFE040FB),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prismatic Kaleidoscope',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Radial sacred geometry & multi-facet mirror reflections',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _config.isEnabled,
          activeColor: const Color(0xFFE040FB),
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

  Widget _buildLiveMonitorCard() {
    return Container(
      width: double.infinity,
      height: 155,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive
              ? const Color(0xFFE040FB).withOpacity(0.5)
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
                  painter: _KaleidoscopePainter(
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
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _config.isActive ? const Color(0xFFE040FB) : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _config.isActive
                          ? KaleidoscopeCompilerService.getKaleidoscopeBadge(_config)
                          : '💎 KALEIDO (BYPASS)',
                      style: AppTypography.caption.copyWith(
                        color: _config.isActive ? const Color(0xFFE040FB) : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_config.segments.round()} FACETS • ${_config.zoom.toStringAsFixed(1)}x ZOOM',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
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
      {'name': 'Hexagon 6', 'preset': KaleidoscopeConfig.classicHexagon},
      {'name': 'Mandala 8', 'preset': KaleidoscopeConfig.sacredMandala},
      {'name': 'Quad Mirror', 'preset': KaleidoscopeConfig.quadRetroMirror},
      {'name': 'Crystal 12', 'preset': KaleidoscopeConfig.cosmicCrystal},
      {'name': 'Twin Split', 'preset': KaleidoscopeConfig.twinSymmetry},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prism Presets',
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
              final preset = item['preset'] as KaleidoscopeConfig;
              final isSelected = _config.isEnabled &&
                  _config.pattern == preset.pattern &&
                  _config.segments == preset.segments;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item['name'] as String),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE040FB).withOpacity(0.25),
                  checkmarkColor: const Color(0xFFE040FB),
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? const Color(0xFFE040FB) : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFE040FB) : Colors.transparent,
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

  Widget _buildPatternSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Symmetry Geometry',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: KaleidoscopePattern.values.map((pattern) {
            final isSelected = _config.pattern == pattern;
            return ChoiceChip(
              label: Text(pattern.displayName),
              selected: isSelected,
              selectedColor: const Color(0xFFE040FB).withOpacity(0.25),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? const Color(0xFFE040FB) : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFE040FB) : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  double defaultSeg;
                  switch (pattern) {
                    case KaleidoscopePattern.verticalSplitMirror:
                      defaultSeg = 2.0;
                      break;
                    case KaleidoscopePattern.quadMirror:
                      defaultSeg = 4.0;
                      break;
                    case KaleidoscopePattern.hexagonalPrism:
                      defaultSeg = 6.0;
                      break;
                    case KaleidoscopePattern.octagonalMandala:
                      defaultSeg = 8.0;
                      break;
                    case KaleidoscopePattern.dodecahedralDream:
                      defaultSeg = 12.0;
                      break;
                  }
                  _applyConfig(_config.copyWith(
                    pattern: pattern,
                    segments: defaultSeg,
                    isEnabled: true,
                  ));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _config.pattern.description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
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
            title: 'Facets / Segments',
            value: _config.segments,
            min: 2.0,
            max: 12.0,
            displayValue: '${_config.segments.round()} Fold',
            onChanged: (val) {
              _applyConfig(_config.copyWith(segments: val.roundToDouble(), isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Rotation Speed',
            value: _config.rotationSpeed,
            min: -2.0,
            max: 2.0,
            displayValue: '${_config.rotationSpeed.toStringAsFixed(1)}x',
            onChanged: (val) {
              _applyConfig(_config.copyWith(rotationSpeed: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Focal Zoom Scale',
            value: _config.zoom,
            min: 0.5,
            max: 2.5,
            displayValue: '${_config.zoom.toStringAsFixed(1)}x',
            onChanged: (val) {
              _applyConfig(_config.copyWith(zoom: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Pivot Offset X',
            value: _config.centerX,
            min: -0.5,
            max: 0.5,
            displayValue: '${(_config.centerX * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(centerX: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Pivot Offset Y',
            value: _config.centerY,
            min: -0.5,
            max: 0.5,
            displayValue: '${(_config.centerY * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(centerY: val, isEnabled: true));
            },
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
              activeTrackColor: const Color(0xFFE040FB),
              thumbColor: const Color(0xFFE040FB),
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

/// Skia Canvas painter rendering authentic radial kaleidoscope symmetry reflections.
class _KaleidoscopePainter extends CustomPainter {
  final KaleidoscopeConfig config;
  final double animationValue;

  _KaleidoscopePainter({
    required this.config,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark base viewport background
    final bgPaint = Paint()..color = const Color(0xFF0D0B14);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) return;

    final center = Offset(
      size.width * 0.5 + size.width * config.centerX,
      size.height * 0.5 + size.height * config.centerY,
    );

    final numFacets = config.segments.round().clamp(2, 12);
    final sliceAngle = (2 * math.pi) / numFacets;
    final rotDrift = animationValue * config.rotationSpeed * math.pi * 2;
    final maxRadius = math.max(size.width, size.height) * config.zoom;

    // 2. Render radial kaleidoscopic facets
    for (int i = 0; i < numFacets; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sliceAngle + rotDrift);

      // Alternate mirror flipping to create seamless reflection
      if (i % 2 == 1) {
        canvas.scale(1.0, -1.0);
      }

      // Clip wedge sector
      final clipPath = Path()
        ..moveTo(0, 0)
        ..lineTo(maxRadius * math.cos(-sliceAngle / 2), maxRadius * math.sin(-sliceAngle / 2))
        ..lineTo(maxRadius * math.cos(sliceAngle / 2), maxRadius * math.sin(sliceAngle / 2))
        ..close();
      canvas.clipPath(clipPath);

      // Draw rich prismatic colored patterns inside the wedge
      _drawPrismaticPattern(canvas, maxRadius);

      canvas.restore();
    }

    // 3. Central mandala gem highlight
    final gemPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          const Color(0xFFE040FB).withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 18))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, 18, gemPaint);

    // Facet perimeter boundary ring
    final ringPaint = Paint()
      ..color = const Color(0xFFE040FB).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, math.min(size.width, size.height) * 0.45, ringPaint);
  }

  void _drawPrismaticPattern(Canvas canvas, double radius) {
    final colors = [
      const Color(0xFFFF007F), // Neon Magenta
      const Color(0xFF7928CA), // Deep Purple
      const Color(0xFF0070F3), // Bright Blue
      const Color(0xFF00DFD8), // Cyan
      const Color(0xFFFFD600), // Gold
    ];

    for (int j = 0; j < colors.length; j++) {
      final r = radius * (1.0 - j * 0.18);
      final paint = Paint()
        ..color = colors[j].withOpacity(0.65)
        ..style = PaintingStyle.fill;

      final starPath = Path()
        ..moveTo(r * 0.2, 0)
        ..lineTo(r * 0.6, r * 0.2)
        ..lineTo(r, 0)
        ..lineTo(r * 0.6, -r * 0.2)
        ..close();
      canvas.drawPath(starPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _KaleidoscopePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.animationValue != animationValue;
  }
}
