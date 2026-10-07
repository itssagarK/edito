import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/jet_flanger_config.dart';
import '../../services/jet_flanger_compiler_service.dart';

class JetFlangerSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const JetFlangerSheet({
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
      builder: (context) => JetFlangerSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<JetFlangerSheet> createState() => _JetFlangerSheetState();
}

class _JetFlangerSheetState extends State<JetFlangerSheet> with SingleTickerProviderStateMixin {
  late JetFlangerConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.jetFlanger;
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

  void _applyConfig(JetFlangerConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(jetFlanger: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case JetFlangerMode.jetEngineFlyby:
        return const Color(0xFF00E5FF); // Jet exhaust cyan
      case JetFlangerMode.barberpolePhaser:
        return const Color(0xFFFF4081); // Barberpole neon pink
      case JetFlangerMode.metallicResonator:
        return const Color(0xFFFFD600); // Metallic brass yellow
      case JetFlangerMode.stereoSpreadFlanger:
        return const Color(0xFF76FF03); // Wide phosphor lime
      case JetFlangerMode.deepSpaceComb:
        return const Color(0xFFE040FB); // Cosmic violet
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
                  const SizedBox(height: 16),
                  _buildLimiterSafeguardBadge(),
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
              Icons.air,
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
                  'Jet Flanger & Barberpole Phaser',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Comb-filter resonant sweep & infinite notch cancellation',
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
              tooltip: 'Reset Flanger',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _applyConfig(const JetFlangerConfig()),
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
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
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
                    painter: _JetFlangerPainter(
                      config: _config,
                      accentColor: _accentColor,
                      animationProgress: _animController.value,
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
                      ? '${_config.mode.displayName.toUpperCase()} • ${_config.sweepSpeedHz.toStringAsFixed(2)} Hz'
                      : 'FLANGER BYPASS',
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
                'DEPTH: ${_config.depthMs.toStringAsFixed(1)}ms • FEEDBACK: ${(_config.feedback * 100).round()}% • PHASE: ${_config.stereoPhaseDeg.round()}°',
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
            _config.isEnabled ? Icons.surround_sound : Icons.volume_off,
            color: _config.isEnabled ? _accentColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Jet Flanger & Phaser',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? 'Comb filter phase cancellation active with brickwall limiter'
                      : 'Bypassed - clean audio signal passing through untouched',
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
          'COMB-FILTER & PHASER MODE',
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
          children: JetFlangerMode.values.map((mode) {
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
      {'name': 'Jet Flyby', 'config': JetFlangerConfig.jetFlyby, 'color': const Color(0xFF00E5FF)},
      {'name': 'Barberpole', 'config': JetFlangerConfig.barberpole, 'color': const Color(0xFFFF4081)},
      {'name': 'Metallic', 'config': JetFlangerConfig.metallicRing, 'color': const Color(0xFFFFD600)},
      {'name': 'Stereo Wide', 'config': JetFlangerConfig.stereoWide, 'color': const Color(0xFF76FF03)},
      {'name': 'Deep Space', 'config': JetFlangerConfig.deepSpaceHypnotic, 'color': const Color(0xFFE040FB)},
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
              final presetConfig = p['config'] as JetFlangerConfig;
              final name = p['name'] as String;
              final color = p['color'] as Color;
              final isMatched = _config.mode == presetConfig.mode &&
                  (_config.sweepSpeedHz - presetConfig.sweepSpeedHz).abs() < 0.05 &&
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
          'MODULATION & COMB-FILTER CONTROLS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // Sweep Speed
        _buildSlider(
          label: 'LFO Sweep Rate',
          valueText: '${_config.sweepSpeedHz.toStringAsFixed(2)} Hz',
          value: _config.sweepSpeedHz,
          min: 0.05,
          max: 5.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(sweepSpeedHz: val, isEnabled: true));
          },
        ),

        // Delay Depth
        _buildSlider(
          label: 'Comb Delay Depth',
          valueText: '${_config.depthMs.toStringAsFixed(1)} ms',
          value: _config.depthMs,
          min: 1.0,
          max: 15.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(depthMs: val, isEnabled: true));
          },
        ),

        // Feedback / Resonance
        _buildSlider(
          label: 'Resonance Feedback',
          valueText: '${(_config.feedback * 100).round()}%',
          value: _config.feedback,
          min: -0.90,
          max: 0.90,
          onChanged: (val) {
            _applyConfig(_config.copyWith(feedback: val, isEnabled: true));
          },
        ),

        // Stereo Phase Offset
        _buildSlider(
          label: 'L/R Stereo Phase Divergence',
          valueText: '${_config.stereoPhaseDeg.round()}°',
          value: _config.stereoPhaseDeg,
          min: 0.0,
          max: 180.0,
          divisions: 36,
          onChanged: (val) {
            _applyConfig(_config.copyWith(stereoPhaseDeg: val, isEnabled: true));
          },
        ),

        // Dry/Wet Mix
        _buildSlider(
          label: 'Dry / Wet Mix Balance',
          valueText: '${(_config.mix * 100).round()}%',
          value: _config.mix,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(mix: val, isEnabled: true));
          },
        ),
      ],
    );
  }

  Widget _buildLimiterSafeguardBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Color(0xFF00E676), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'DSP Guard: alimiter brickwall ceiling (-0.45 dBFS) protects against comb resonance clipping',
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
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

/// Skia Canvas painter rendering dynamic comb filter notches, frequency cancellation curves,
/// and L/R stereo phase offset ripples.
class _JetFlangerPainter extends CustomPainter {
  final JetFlangerConfig config;
  final Color accentColor;
  final double animationProgress;

  _JetFlangerPainter({
    required this.config,
    required this.accentColor,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = const Color(0xFF0B0E17);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw logarithmic frequency grid lines (100Hz, 1kHz, 10kHz)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (double f = 0.2; f < 1.0; f += 0.25) {
      canvas.drawLine(
        Offset(f * size.width, 0),
        Offset(f * size.width, size.height),
        gridPaint,
      );
    }

    if (!config.isActive) {
      // Flat bypass line across center
      final bypassPaint = Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5),
        bypassPaint,
      );
      return;
    }

    final centerY = size.height * 0.5;
    final maxAmp = size.height * 0.38;
    final lfoRate = config.sweepSpeedHz;
    final depth = config.depthMs;
    final feedback = config.feedback;
    final phaseL = animationProgress * 2 * math.pi * lfoRate;
    final phaseR = phaseL + (config.stereoPhaseDeg * math.pi / 180.0);

    // 1. Draw Left Channel comb filter curve (accent color)
    _drawCombCurve(
      canvas: canvas,
      size: size,
      phase: phaseL,
      depth: depth,
      feedback: feedback,
      centerY: centerY,
      maxAmp: maxAmp,
      color: accentColor,
      strokeWidth: 2.0,
    );

    // 2. If stereo divergence > 5 degrees, draw Right Channel curve in complementary color
    if (config.stereoPhaseDeg > 5.0) {
      final rightColor = Color.lerp(accentColor, Colors.white, 0.4)!.withOpacity(0.65);
      _drawCombCurve(
        canvas: canvas,
        size: size,
        phase: phaseR,
        depth: depth,
        feedback: feedback,
        centerY: centerY,
        maxAmp: maxAmp,
        color: rightColor,
        strokeWidth: 1.2,
      );
    }
  }

  void _drawCombCurve({
    required Canvas canvas,
    required Size size,
    required double phase,
    required double depth,
    required double feedback,
    required double centerY,
    required double maxAmp,
    required Color color,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    // Delay time in seconds swept by LFO
    final lfoSweep = (math.sin(phase) + 1.0) * 0.5; // 0 to 1
    final sweptDelayMs = 0.5 + lfoSweep * depth; // ms
    final sweptDelaySec = sweptDelayMs / 1000.0;

    for (double x = 0; x <= size.width; x += 2.0) {
      final normX = x / size.width;
      // Frequency from 20 Hz to 20,000 Hz logarithmically
      final freq = 20.0 * math.pow(1000.0, normX);

      // Comb filter transfer function magnitude: |H(f)| = sqrt(1 + R^2 + 2R cos(2*pi*f*T)) / (1 + |R|)
      final omega = 2 * math.pi * freq * sweptDelaySec;
      final magnitude = math.sqrt(1.0 + feedback * feedback + 2.0 * feedback * math.cos(omega));
      final normalizedGain = (magnitude / (1.0 + feedback.abs())).clamp(0.0, 1.0);

      final y = centerY - (normalizedGain - 0.5) * 2.0 * maxAmp;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JetFlangerPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.animationProgress != animationProgress;
  }
}
