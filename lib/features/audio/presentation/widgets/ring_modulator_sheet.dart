import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/ring_modulator_config.dart';
import '../../services/ring_modulator_compiler_service.dart';

class RingModulatorSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const RingModulatorSheet({
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
      builder: (context) => RingModulatorSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<RingModulatorSheet> createState() => _RingModulatorSheetState();
}

class _RingModulatorSheetState extends State<RingModulatorSheet> with SingleTickerProviderStateMixin {
  late RingModulatorConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.ringModulator;
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

  void _applyConfig(RingModulatorConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(ringModulator: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case RingModulatorMode.dalekRobotic:
        return const Color(0xFFFFD600); // Dalek metallic gold
      case RingModulatorMode.alienVocoder:
        return const Color(0xFF00E5FF); // Alien electric cyan
      case RingModulatorMode.subHarmonicTremor:
        return const Color(0xFFFF1744); // Sub-tremor crimson
      case RingModulatorMode.cyberBellBells:
        return const Color(0xFFE040FB); // Bell chime violet
      case RingModulatorMode.dualCarrierScifi:
        return const Color(0xFF76FF03); // Sci-Fi phosphor lime
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
              Icons.notifications_active_rounded,
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
                  'Metallic Ring Modulator & Vocoder',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Carrier wave multiplication & robotic Dalek voice synthesis',
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
              tooltip: 'Reset Ring Modulator',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _applyConfig(const RingModulatorConfig()),
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
        color: const Color(0xFF0C0F17),
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
                    painter: _RingModulatorPainter(
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
                      ? '${_config.mode.displayName.toUpperCase()} • ${_config.carrierFreqHz.toStringAsFixed(0)} Hz CARRIER'
                      : 'RING MOD BYPASS',
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
                'DEPTH: ${(_config.depth * 100).round()}% • HARMONICS: ${(_config.harmonicMix * 100).round()}% • MIX: ${(_config.mix * 100).round()}%',
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
            _config.isEnabled ? Icons.record_voice_over : Icons.voice_over_off,
            color: _config.isEnabled ? _accentColor : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Ring Modulator',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _config.isEnabled
                      ? 'Sinusoidal amplitude multiplication active with brickwall limiter'
                      : 'Bypassed - natural human vocal tones preserved',
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
          'CARRIER WAVE & ROBOTIC VOCAL PRESET',
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
          children: RingModulatorMode.values.map((mode) {
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
      {'name': 'Dalek Robot', 'config': RingModulatorConfig.dalekRobot, 'color': const Color(0xFFFFD600)},
      {'name': 'Alien Vocoder', 'config': RingModulatorConfig.alienSpeech, 'color': const Color(0xFF00E5FF)},
      {'name': 'Sub-Tremor', 'config': RingModulatorConfig.subTremor, 'color': const Color(0xFFFF1744)},
      {'name': 'Cyber Chime', 'config': RingModulatorConfig.cyberChime, 'color': const Color(0xFFE040FB)},
      {'name': 'Sci-Fi Dual', 'config': RingModulatorConfig.spaceInterference, 'color': const Color(0xFF76FF03)},
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
              final presetConfig = p['config'] as RingModulatorConfig;
              final name = p['name'] as String;
              final color = p['color'] as Color;
              final isMatched = _config.mode == presetConfig.mode &&
                  (_config.carrierFreqHz - presetConfig.carrierFreqHz).abs() < 1.0 &&
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
          'CARRIER OSCILLATOR & DSP CONTROLS',
          style: AppTypography.caption.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // Carrier Frequency
        _buildSlider(
          label: 'Carrier Oscillator Frequency',
          valueText: '${_config.carrierFreqHz.toStringAsFixed(0)} Hz',
          value: _config.carrierFreqHz,
          min: 5.0,
          max: 2000.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(carrierFreqHz: val, isEnabled: true));
          },
        ),

        // Modulation Depth
        _buildSlider(
          label: 'Modulation Multiplier Depth',
          valueText: '${(_config.depth * 100).round()}%',
          value: _config.depth,
          min: 0.10,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(depth: val, isEnabled: true));
          },
        ),

        // Harmonics
        _buildSlider(
          label: 'Second Harmonic Overtone',
          valueText: '${(_config.harmonicMix * 100).round()}%',
          value: _config.harmonicMix,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            _applyConfig(_config.copyWith(harmonicMix: val, isEnabled: true));
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
              'DSP Guard: alimiter brickwall ceiling (-0.45 dBFS) prevents carrier clipping and harmonic distortion',
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

/// Skia Canvas painter rendering multiplied carrier wave, amplitude envelope lobes,
/// and sum/difference sidebands.
class _RingModulatorPainter extends CustomPainter {
  final RingModulatorConfig config;
  final Color accentColor;
  final double animationProgress;

  _RingModulatorPainter({
    required this.config,
    required this.accentColor,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bgPaint = Paint()..color = const Color(0xFF0C0F17);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (!config.isActive) {
      // Flat bypass center line
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
    final maxAmp = size.height * 0.40;
    final carrierCycles = (config.carrierFreqHz / 25.0).clamp(2.0, 18.0);
    final modCycles = 2.0;

    final phase = animationProgress * 2 * math.pi;

    // 1. Draw Amplitude Envelope Lobes (dashed/faint accent)
    final envPaint = Paint()
      ..color = accentColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final envPathTop = Path();
    final envPathBottom = Path();

    for (double x = 0; x <= size.width; x += 2.0) {
      final normX = x / size.width;
      final modWave = (math.sin(normX * modCycles * 2 * math.pi + phase) * 0.5 + 0.5) * config.depth;
      final yTop = centerY - modWave * maxAmp;
      final yBottom = centerY + modWave * maxAmp;

      if (x == 0) {
        envPathTop.moveTo(x, yTop);
        envPathBottom.moveTo(x, yBottom);
      } else {
        envPathTop.lineTo(x, yTop);
        envPathBottom.lineTo(x, yBottom);
      }
    }

    canvas.drawPath(envPathTop, envPaint);
    canvas.drawPath(envPathBottom, envPaint);

    // 2. Draw Multiplied Ring Modulated Waveform (accent color solid)
    final modPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final modPath = Path();
    for (double x = 0; x <= size.width; x += 2.0) {
      final normX = x / size.width;
      // Carrier wave
      final carrier = math.sin(normX * carrierCycles * 2 * math.pi + phase * 3.0);
      // Harmonic wave
      final harmonic = config.harmonicMix > 0.05
          ? math.sin(normX * carrierCycles * 4 * math.pi + phase * 6.0) * config.harmonicMix * 0.5
          : 0.0;
      // Audio modulator signal
      final modSignal = math.sin(normX * modCycles * 2 * math.pi + phase);
      // Multiplied output: y = m(t) * (c(t) + h(t))
      final output = (modSignal * (carrier + harmonic)) * config.depth;
      final y = centerY - output * maxAmp;

      if (x == 0) {
        modPath.moveTo(x, y);
      } else {
        modPath.lineTo(x, y);
      }
    }

    canvas.drawPath(modPath, modPaint);
  }

  @override
  bool shouldRepaint(covariant _RingModulatorPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.animationProgress != animationProgress;
  }
}
