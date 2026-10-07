import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/light_leak_config.dart';
import '../../services/light_leak_compiler_service.dart';

class LightLeakSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const LightLeakSheet({
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
      builder: (context) => LightLeakSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<LightLeakSheet> createState() => _LightLeakSheetState();
}

class _LightLeakSheetState extends State<LightLeakSheet> with SingleTickerProviderStateMixin {
  late LightLeakConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.lightLeak;
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

  void _applyConfig(LightLeakConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(lightLeak: updated);
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
              _buildProfileSelector(),
              const SizedBox(height: 16),
              _buildPositionSelector(),
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
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.wb_sunny_rounded,
            color: Colors.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Light Leak & Rainbow Prisms',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Optical solar flaring & chromatic prism bleeds',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _config.isEnabled,
          activeColor: Colors.amber,
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
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive
              ? Colors.amber.withOpacity(0.5)
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
                  painter: _LightLeakPainter(
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
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _config.isActive ? Colors.amber : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _config.isActive
                          ? LightLeakCompilerService.getLightLeakBadge(_config)
                          : '☀️ LIGHT LEAK (BYPASS)',
                      style: AppTypography.caption.copyWith(
                        color: _config.isActive ? Colors.amber : Colors.white54,
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
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_config.position.displayName} • ${_config.speed.toStringAsFixed(1)}x',
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
      {'name': 'Sunset Gold', 'preset': LightLeakConfig.sunsetGoldenHour},
      {'name': 'Prism Arc', 'preset': LightLeakConfig.spectralPrism},
      {'name': 'Kodak 35mm', 'preset': LightLeakConfig.kodakFilmBurn},
      {'name': 'Cyan Anamorphic', 'preset': LightLeakConfig.cyberpunkCyanFlare},
      {'name': 'Dreamy Glow', 'preset': LightLeakConfig.dreamyPastelBreathing},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optical Flare Presets',
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
              final preset = item['preset'] as LightLeakConfig;
              final isSelected = _config.isEnabled &&
                  _config.profile == preset.profile &&
                  _config.position == preset.position;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(item['name'] as String),
                  selected: isSelected,
                  selectedColor: Colors.amber.withOpacity(0.25),
                  checkmarkColor: Colors.amber,
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? Colors.amber : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? Colors.amber : Colors.transparent,
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

  Widget _buildProfileSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dispersion Profile',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LightLeakProfile.values.map((profile) {
            final isSelected = _config.profile == profile;
            return ChoiceChip(
              label: Text(profile.displayName),
              selected: isSelected,
              selectedColor: Colors.amber.withOpacity(0.25),
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? Colors.amber : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? Colors.amber : Colors.transparent,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  _applyConfig(_config.copyWith(profile: profile, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _config.profile.description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leak Hotspot Origin',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LightLeakPosition.values.map((pos) {
              final isSelected = _config.position == pos;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(pos.displayName),
                  selected: isSelected,
                  selectedColor: Colors.amber.withOpacity(0.25),
                  labelStyle: AppTypography.caption.copyWith(
                    color: isSelected ? Colors.amber : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? Colors.amber : Colors.transparent,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      _applyConfig(_config.copyWith(position: pos, isEnabled: true));
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
            title: 'Leak Intensity',
            value: _config.intensity,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.intensity * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(intensity: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Motion & Pulse Speed',
            value: _config.speed,
            min: 0.2,
            max: 3.0,
            displayValue: '${_config.speed.toStringAsFixed(1)}x',
            onChanged: (val) {
              _applyConfig(_config.copyWith(speed: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Color Saturation',
            value: _config.saturation,
            min: 0.5,
            max: 2.0,
            displayValue: '${(_config.saturation * 100).round()}%',
            onChanged: (val) {
              _applyConfig(_config.copyWith(saturation: val, isEnabled: true));
            },
          ),
          const Divider(color: Colors.white12, height: 16),
          _buildSlider(
            title: 'Warmth / Tint Balance',
            value: _config.warmth,
            min: -1.0,
            max: 1.0,
            displayValue: _config.warmth > 0
                ? '+${(_config.warmth * 100).round()}% Warm'
                : '${(_config.warmth * 100).round()}% Cool',
            onChanged: (val) {
              _applyConfig(_config.copyWith(warmth: val, isEnabled: true));
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
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
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

/// Skia Canvas painter rendering organic radiant optical light leaks and prism refractions.
class _LightLeakPainter extends CustomPainter {
  final LightLeakConfig config;
  final double animationValue;

  _LightLeakPainter({
    required this.config,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw base cinematic viewfinder backdrop
    final bgPaint = Paint()..color = const Color(0xFF101216);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle framing silhouettes
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.60, size.width * 0.7, size.height * 0.80)
      ..lineTo(size.width, size.height * 0.70)
      ..lineTo(size.width, size.height)
      ..close();
    final silPaint = Paint()..color = const Color(0xFF1A1D24);
    canvas.drawPath(hillPath, silPaint);

    if (!config.isActive) return;

    final progress = (animationValue * config.speed) % 1.0;
    final pulse = 0.85 + 0.15 * math.sin(progress * 2 * math.pi);
    final intensity = (config.intensity * pulse).clamp(0.0, 1.0);

    // 2. Determine primary light leak origin point
    Offset origin;
    switch (config.position) {
      case LightLeakPosition.topLeft:
        origin = Offset(size.width * 0.05, size.height * 0.05);
        break;
      case LightLeakPosition.topRight:
        origin = Offset(size.width * 0.95, size.height * 0.05);
        break;
      case LightLeakPosition.bottomLeft:
        origin = Offset(size.width * 0.05, size.height * 0.95);
        break;
      case LightLeakPosition.bottomRight:
        origin = Offset(size.width * 0.95, size.height * 0.95);
        break;
      case LightLeakPosition.centerSweep:
        origin = Offset(size.width * 0.5, size.height * 0.5);
        break;
    }

    // 3. Render optical light bleed layers based on profile
    switch (config.profile) {
      case LightLeakProfile.warmSunsetFlare:
        _paintSunsetFlare(canvas, size, origin, intensity);
        break;
      case LightLeakProfile.rainbowPrism:
        _paintRainbowPrism(canvas, size, origin, intensity, progress);
        break;
      case LightLeakProfile.vintage35mmBurn:
        _paintVintageBurn(canvas, size, origin, intensity);
        break;
      case LightLeakProfile.anamorphicCyanLeak:
        _paintAnamorphicCyan(canvas, size, origin, intensity, progress);
        break;
      case LightLeakProfile.subtleAmbientGlow:
        _paintAmbientGlow(canvas, size, origin, intensity);
        break;
    }
  }

  void _paintSunsetFlare(Canvas canvas, Size size, Offset origin, double intensity) {
    final maxRadius = math.max(size.width, size.height) * 1.2;

    // Hot inner core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity((0.85 * intensity).clamp(0.0, 1.0)),
          Colors.amber.withOpacity((0.60 * intensity).clamp(0.0, 1.0)),
          Colors.deepOrange.withOpacity((0.35 * intensity).clamp(0.0, 1.0)),
          Colors.pinkAccent.withOpacity((0.15 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: maxRadius))
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), corePaint);

    // Warm secondary bounce orb
    final bounceCenter = Offset(
      size.width - origin.dx,
      size.height - origin.dy,
    );
    final bouncePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.orangeAccent.withOpacity((0.35 * intensity).clamp(0.0, 1.0)),
          Colors.purpleAccent.withOpacity((0.15 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: bounceCenter, radius: maxRadius * 0.6))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(bounceCenter, maxRadius * 0.6, bouncePaint);
  }

  void _paintRainbowPrism(Canvas canvas, Size size, Offset origin, double intensity, double progress) {
    // Spectral multi-color prism arcs
    final colors = [
      Colors.redAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.orangeAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.yellowAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.greenAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.cyanAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.blueAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.purpleAccent.withOpacity((0.45 * intensity).clamp(0.0, 1.0)),
      Colors.transparent,
    ];

    final prismRadius = math.max(size.width, size.height) * 1.1;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        startAngle: 0.0,
        endAngle: math.pi * 2,
        transform: GradientRotation(progress * math.pi * 0.5),
      ).createShader(Rect.fromCircle(center: origin, radius: prismRadius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(origin, prismRadius, sweepPaint);

    // Hot central flare
    final centerFlare = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity((0.70 * intensity).clamp(0.0, 1.0)),
          Colors.cyanAccent.withOpacity((0.30 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: 100))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(origin, 100, centerFlare);
  }

  void _paintVintageBurn(Canvas canvas, Size size, Offset origin, double intensity) {
    // Harsh red/amber film gate exposure leakage
    final burnPaint = Paint()
      ..shader = LinearGradient(
        begin: origin.dx < size.width / 2 ? Alignment.centerLeft : Alignment.centerRight,
        end: origin.dx < size.width / 2 ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          Colors.white.withOpacity((0.80 * intensity).clamp(0.0, 1.0)),
          Colors.deepOrange.withOpacity((0.60 * intensity).clamp(0.0, 1.0)),
          Colors.redAccent.withOpacity((0.40 * intensity).clamp(0.0, 1.0)),
          Colors.brown.withOpacity((0.15 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.20, 0.45, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), burnPaint);
  }

  void _paintAnamorphicCyan(Canvas canvas, Size size, Offset origin, double intensity, double progress) {
    // Horizontal cylindrical flare beam
    final beamY = origin.dy + math.sin(progress * 2 * math.pi) * 8;
    final beamHeight = size.height * 0.35;

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.cyanAccent.withOpacity((0.35 * intensity).clamp(0.0, 1.0)),
          Colors.white.withOpacity((0.85 * intensity).clamp(0.0, 1.0)),
          Colors.blueAccent.withOpacity((0.40 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, beamY - beamHeight / 2, size.width, beamHeight))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Rect.fromLTWH(0, beamY - beamHeight / 2, size.width, beamHeight), beamPaint);
  }

  void _paintAmbientGlow(Canvas canvas, Size size, Offset origin, double intensity) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amberAccent.withOpacity((0.40 * intensity).clamp(0.0, 1.0)),
          Colors.pinkAccent.withOpacity((0.20 * intensity).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: origin, radius: math.max(size.width, size.height) * 0.9))
      ..blendMode = BlendMode.screen;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LightLeakPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.animationValue != animationValue;
  }
}
