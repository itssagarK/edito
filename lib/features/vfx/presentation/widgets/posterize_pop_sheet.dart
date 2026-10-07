import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/posterize_pop_config.dart';
import '../../services/posterize_pop_compiler_service.dart';

class PosterizePopSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const PosterizePopSheet({
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
      builder: (context) => PosterizePopSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<PosterizePopSheet> createState() => _PosterizePopSheetState();
}

class _PosterizePopSheetState extends State<PosterizePopSheet> with SingleTickerProviderStateMixin {
  late PosterizePopConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.posterizePop;
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

  void _applyConfig(PosterizePopConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(posterizePop: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case PosterizePopMode.warholPopArt:
        return const Color(0xFFFF4081); // Warhol vivid magenta
      case PosterizePopMode.comicBookInk:
        return const Color(0xFFFFD600); // Graphic novel yellow
      case PosterizePopMode.cyberpunkDuotone:
        return const Color(0xFF00E5FF); // Neon cyan
      case PosterizePopMode.retro8BitPoster:
        return const Color(0xFF76FF03); // Arcade lime
      case PosterizePopMode.monochromeNoir:
        return const Color(0xFFECEFF1); // Stark silver noir
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
          if (!widget.isDocked) _buildDragHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitorCard(),
                  const SizedBox(height: 16),
                  _buildEnableToggle(),
                  const SizedBox(height: 16),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildPresetSelector(),
                  const SizedBox(height: 20),
                  _buildParameterSliders(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) {
      return content;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: content,
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accentColor.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.palette,
              color: _accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posterize & Pop Art Studio',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quantized tonal stepping & chromatic silk-screen styling',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          if (_config.isActive)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              tooltip: 'Reset Posterization',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _applyConfig(const PosterizePopConfig()),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorCard() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _PosterizePopPainter(
                      config: _config,
                      accentColor: _accentColor,
                      phase: _animController.value,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _config.isActive
                      ? '${_config.mode.displayName.toUpperCase()} • ${_config.colorLevels} LEVELS'
                      : 'POSTERIZE BYPASS',
                  style: AppTypography.caption.copyWith(
                    color: _config.isActive ? _accentColor : Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 8,
              child: Text(
                'SAT: ${_config.saturationBoost.toStringAsFixed(1)}x • CONTRAST: ${_config.contrast.toStringAsFixed(2)}x',
                style: AppTypography.caption.copyWith(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(
            _config.isEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
            color: _config.isEnabled ? _accentColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Posterize & Pop Art',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? 'Deterministic FFmpeg lutrgb color quantization active'
                      : 'Bypassed - continuous tonal gradients preserved',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARTISTIC STYLIZATION MODE',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PosterizePopMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: const Color(0xFF1E2130),
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.white12,
              ),
              onSelected: (selected) {
                if (selected) {
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
            color: Colors.white54,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    final presets = [
      {'name': 'Warhol Pop', 'config': PosterizePopConfig.warholPop, 'color': const Color(0xFFFF4081)},
      {'name': 'Comic Ink', 'config': PosterizePopConfig.comicBook, 'color': const Color(0xFFFFD600)},
      {'name': 'Cyber Duotone', 'config': PosterizePopConfig.cyberDuotone, 'color': const Color(0xFF00E5FF)},
      {'name': '8-Bit Arcade', 'config': PosterizePopConfig.retro8Bit, 'color': const Color(0xFF76FF03)},
      {'name': 'Noir Mono', 'config': PosterizePopConfig.noirMonochrome, 'color': const Color(0xFFECEFF1)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as PosterizePopConfig;
              final name = p['name'] as String;
              final color = p['color'] as Color;
              final isMatched = _config.mode == presetConfig.mode &&
                  _config.colorLevels == presetConfig.colorLevels &&
                  _config.isEnabled;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor: isMatched ? color.withOpacity(0.2) : const Color(0xFF1E2130),
                  side: BorderSide(
                    color: isMatched ? color : Colors.white12,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: AppTypography.bodySmall.copyWith(
                          color: isMatched ? color : Colors.white70,
                          fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => _applyConfig(presetConfig),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUANTIZATION & TONAL PARAMETERS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // Color Levels
        _buildSlider(
          label: 'Color Quantization Levels',
          valueText: '${_config.colorLevels} Steps',
          value: _config.colorLevels.toDouble(),
          min: 2,
          max: 16,
          divisions: 14,
          onChanged: (val) {
            _applyConfig(_config.copyWith(colorLevels: val.round(), isEnabled: true));
          },
        ),

        // Outline Strength
        _buildSlider(
          label: 'Ink Contour Outline',
          valueText: '${(_config.outlineStrength * 100).round()}%',
          value: _config.outlineStrength,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(outlineStrength: val, isEnabled: true));
          },
        ),

        // Saturation Boost
        _buildSlider(
          label: 'Chromatic Saturation Pop',
          valueText: '${_config.saturationBoost.toStringAsFixed(2)}x',
          value: _config.saturationBoost,
          min: 1.0,
          max: 2.5,
          onChanged: (val) {
            _applyConfig(_config.copyWith(saturationBoost: val, isEnabled: true));
          },
        ),

        // Contrast
        _buildSlider(
          label: 'Tonal Contrast Stepping',
          valueText: '${_config.contrast.toStringAsFixed(2)}x',
          value: _config.contrast,
          min: 1.0,
          max: 2.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(contrast: val, isEnabled: true));
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: AppTypography.caption.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
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
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Canvas painter rendering quantized stepped color bars, Warhol silkscreen 4-quadrant preview,
/// and ink contour edge outlines.
class _PosterizePopPainter extends CustomPainter {
  final PosterizePopConfig config;
  final Color accentColor;
  final double phase;

  _PosterizePopPainter({
    required this.config,
    required this.accentColor,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = const Color(0xFF0F111A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) {
      // Smooth continuous gradient when bypassed
      final bypassGradient = LinearGradient(
        colors: [
          Colors.cyan.withOpacity(0.3),
          Colors.magenta.withOpacity(0.3),
          Colors.yellow.withOpacity(0.3),
        ],
      );
      final bypassPaint = Paint()
        ..shader = bypassGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bypassPaint);
      return;
    }

    final levels = config.colorLevels.clamp(2, 16);
    final barHeight = size.height * 0.45;
    final barTop = size.height * 0.40;

    // 1. Draw quantized stepped color bands
    final stepWidth = size.width / levels;
    for (int i = 0; i < levels; i++) {
      final t = i / (levels - 1);
      Color stepColor;

      switch (config.mode) {
        case PosterizePopMode.warholPopArt:
          // Silk-screen cycle: vivid yellow -> hot pink -> cyan -> lime
          final hue = (t * 300.0 + phase * 60.0) % 360.0;
          stepColor = HSVColor.fromAHSV(1.0, hue, 0.85, 0.95).toColor();
          break;

        case PosterizePopMode.comicBookInk:
          // Stepped primary comic colors with ink shading
          final val = (t * 0.8 + 0.2).clamp(0.0, 1.0);
          stepColor = i % 2 == 0
              ? Color.fromRGBO((255 * val).round(), (200 * val).round(), 0, 1.0)
              : Color.fromRGBO((220 * val).round(), 30, (50 * val).round(), 1.0);
          break;

        case PosterizePopMode.cyberpunkDuotone:
          // Cyan to Hot Pink blend
          stepColor = Color.lerp(
            const Color(0xFF00E5FF),
            const Color(0xFFFF4081),
            t,
          )!;
          break;

        case PosterizePopMode.retro8BitPoster:
          // Retro 8-bit RGB stepped palette
          final r = (t * 255).round();
          final g = ((1.0 - t) * 200).round();
          final b = ((math.sin(t * math.pi) * 255)).round();
          stepColor = Color.fromARGB(255, r, g, b);
          break;

        case PosterizePopMode.monochromeNoir:
          // Grayscale quantization
          final gray = (t * 240 + 15).round();
          stepColor = Color.fromARGB(255, gray, gray, gray);
          break;
      }

      final rect = Rect.fromLTWH(i * stepWidth, barTop, stepWidth, barHeight);
      final paint = Paint()..color = stepColor;
      canvas.drawRect(rect, paint);

      // Ink outline separator if outlineStrength > 0
      if (config.outlineStrength > 0.1 && i > 0) {
        final outlinePaint = Paint()
          ..color = Colors.black.withOpacity(config.outlineStrength)
          ..strokeWidth = (config.outlineStrength * 2.5).clamp(1.0, 3.0);
        canvas.drawLine(
          Offset(i * stepWidth, barTop),
          Offset(i * stepWidth, barTop + barHeight),
          outlinePaint,
        );
      }
    }

    // 2. Draw stepped quantized sine wave monitor over the top section
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final wavePath = Path();
    final waveH = size.height * 0.28;
    for (double x = 0; x <= size.width; x += 2.0) {
      final rawY = math.sin((x / size.width) * 4 * math.pi + phase * 2 * math.pi);
      // Quantize the wave to levels
      final normalized = (rawY + 1.0) / 2.0; // 0 to 1
      final stepped = (normalized * (levels - 1)).round() / (levels - 1);
      final y = 20.0 + (1.0 - stepped) * waveH;

      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _PosterizePopPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.phase != phase;
  }
}
