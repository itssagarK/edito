import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/tremolo_wah_config.dart';
import '../../services/tremolo_wah_compiler_service.dart';

class TremoloWahSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const TremoloWahSheet({
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
      builder: (context) => TremoloWahSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<TremoloWahSheet> createState() => _TremoloWahSheetState();
}

class _TremoloWahSheetState extends State<TremoloWahSheet> with SingleTickerProviderStateMixin {
  late TremoloWahConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.tremoloWah;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(TremoloWahConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(tremoloWah: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case TremoloWahMode.stereoTremolo:
        return const Color(0xFF00E5FF); // Electric cyan
      case TremoloWahMode.autoWahFunk:
        return const Color(0xFFFF9100); // Funk neon orange
      case TremoloWahMode.leslieRotary:
        return const Color(0xFF76FF03); // Retro rotary lime
      case TremoloWahMode.stutterGate:
        return const Color(0xFFFF1744); // Chop red
      case TremoloWahMode.psychedelicSweep:
        return const Color(0xFFD500F9); // Psychedelic purple
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
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isDocked) _buildHeader(),
              const SizedBox(height: 8),

              // Enable toggle & quick status
              _buildEnableSwitch(),
              const SizedBox(height: 12),

              // Animated Skia Canvas Modulation Visualizer
              _buildModulationMonitor(),
              const SizedBox(height: 16),

              // Presets row
              _buildPresetsSection(),
              const SizedBox(height: 16),

              // Modulation Mode selector
              _buildModeSelector(),
              const SizedBox(height: 16),

              // LFO Waveform selector
              _buildWaveformSelector(),
              const SizedBox(height: 16),

              // Parameter controls
              _buildSliders(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.waves, color: _accentColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stereo Tremolo & Auto-Wah',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'Periodic stereo LFO amplitude pulses & resonant wah filters',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (widget.onDone != null)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.check, size: 20),
            onPressed: widget.onDone,
          ),
      ],
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? _accentColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.surround_sound : Icons.volume_off,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _config.isEnabled ? 'Modulation Active' : 'Modulation Bypassed',
                style: AppTypography.bodyMedium.copyWith(
                  color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: _accentColor,
            onChanged: (val) => _applyConfig(_config.copyWith(isEnabled: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildModulationMonitor() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 130),
                  painter: _TremoloWahPainter(
                    config: _config,
                    animationValue: _animController.value,
                    accentColor: _accentColor,
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
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
                    const SizedBox(width: 5),
                    Text(
                      'LFO: ${_config.frequencyHz.toStringAsFixed(1)} Hz | ${_config.waveform.displayName.split(' ').first}',
                      style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 10,
              child: Text(
                _config.mode.displayName,
                style: AppTypography.caption.copyWith(
                  color: _accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presets = [
      {'name': 'Vintage Surf', 'config': TremoloWahConfig.vintageSurfTremolo, 'icon': Icons.surfing},
      {'name': 'Funky Wah', 'config': TremoloWahConfig.funkyAutoWah, 'icon': Icons.music_note},
      {'name': 'Leslie Rotary', 'config': TremoloWahConfig.leslieOrganSpeaker, 'icon': Icons.rotate_right},
      {'name': 'EDM Stutter', 'config': TremoloWahConfig.hardEdmStutter, 'icon': Icons.flash_on},
      {'name': 'Psychedelic', 'config': TremoloWahConfig.trippyPhaserSweep, 'icon': Icons.all_inclusive},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODULATION PRESETS',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as TremoloWahConfig;
              final isSelected = _config.mode == presetConfig.mode &&
                  (_config.frequencyHz - presetConfig.frequencyHz).abs() < 0.2;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    p['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.black : _accentColor,
                  ),
                  label: Text(p['name'] as String),
                  selected: isSelected,
                  selectedColor: _accentColor,
                  checkmarkColor: Colors.black,
                  backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _applyConfig(presetConfig.copyWith(isEnabled: true));
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

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODULATION ENGINE',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TremoloWahMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor,
              backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _config.mode.description,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LFO WAVE SHAPE',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: LfoWaveform.values.map((wave) {
            final isSelected = _config.waveform == wave;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(
                    wave.displayName.split(' ').first,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _accentColor,
                  backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
                  onSelected: (selected) {
                    if (selected) {
                      _applyConfig(_config.copyWith(waveform: wave));
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    final showFilterControls = _config.mode == TremoloWahMode.autoWahFunk ||
        _config.mode == TremoloWahMode.psychedelicSweep ||
        _config.mode == TremoloWahMode.leslieRotary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency LFO Speed
        _buildSliderTile(
          title: 'LFO Rate / Speed',
          valueText: '${_config.frequencyHz.toStringAsFixed(1)} Hz',
          value: _config.frequencyHz,
          min: 0.2,
          max: 20.0,
          onChanged: (val) => _applyConfig(_config.copyWith(frequencyHz: val)),
        ),

        // Modulation Depth
        _buildSliderTile(
          title: 'Modulation Depth',
          valueText: '${(_config.depth * 100).round()}%',
          value: _config.depth,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => _applyConfig(_config.copyWith(depth: val)),
        ),

        // Wah Filter Resonance Peak
        if (showFilterControls)
          _buildSliderTile(
            title: 'Filter Resonance (Q)',
            valueText: '${_config.resonance.toStringAsFixed(1)}x',
            value: _config.resonance,
            min: 0.5,
            max: 10.0,
            onChanged: (val) => _applyConfig(_config.copyWith(resonance: val)),
          ),

        // Wah Center Frequency
        if (_config.mode == TremoloWahMode.autoWahFunk ||
            _config.mode == TremoloWahMode.psychedelicSweep)
          _buildSliderTile(
            title: 'Center Frequency',
            valueText: '${_config.centerFreqHz.round()} Hz',
            value: _config.centerFreqHz,
            min: 200.0,
            max: 4000.0,
            onChanged: (val) => _applyConfig(_config.copyWith(centerFreqHz: val)),
          ),

        // Stereo Phase Offset
        _buildSliderTile(
          title: 'Stereo Phase Offset (L/R)',
          valueText: '${_config.stereoPhaseOffsetDeg.round()}°',
          value: _config.stereoPhaseOffsetDeg,
          min: 0.0,
          max: 180.0,
          onChanged: (val) => _applyConfig(_config.copyWith(stereoPhaseOffsetDeg: val)),
        ),

        // Wet / Dry Mix
        _buildSliderTile(
          title: 'Wet / Dry Mix',
          valueText: '${(_config.mix * 100).round()}%',
          value: _config.mix,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => _applyConfig(_config.copyWith(mix: val)),
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

/// Custom Skia painter displaying animated dual-channel LFO waveform oscillation and resonant filter curve.
class _TremoloWahPainter extends CustomPainter {
  final TremoloWahConfig config;
  final double animationValue;
  final Color accentColor;

  _TremoloWahPainter({
    required this.config,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2.0;

    // Background grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = height * (i / 5.0);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (int i = 1; i <= 6; i++) {
      final x = width * (i / 7.0);
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    if (!config.isActive) {
      // Inactive flat baseline
      final flatPaint = Paint()
        ..color = Colors.grey.withOpacity(0.4)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(0, centerY), Offset(width, centerY), flatPaint);
      return;
    }

    final phaseOffsetRad = (config.stereoPhaseOffsetDeg * math.pi) / 180.0;
    final cycles = (config.frequencyHz * 0.8).clamp(1.0, 8.0);
    final amplitude = (height * 0.35) * config.depth;

    // Draw Left Channel LFO Wave (Cyan)
    _drawChannelWave(
      canvas: canvas,
      width: width,
      centerY: centerY,
      amplitude: amplitude,
      cycles: cycles,
      phase: animationValue * 2 * math.pi,
      color: accentColor,
      waveform: config.waveform,
    );

    // Draw Right Channel LFO Wave with Phase Offset (Orange/Pink)
    if (config.stereoPhaseOffsetDeg > 5) {
      _drawChannelWave(
        canvas: canvas,
        width: width,
        centerY: centerY,
        amplitude: amplitude,
        cycles: cycles,
        phase: animationValue * 2 * math.pi + phaseOffsetRad,
        color: const Color(0xFFFF4081),
        waveform: config.waveform,
      );
    }

    // If Auto-Wah or Psychedelic Sweep, draw resonant bandpass peak overlay
    if (config.mode == TremoloWahMode.autoWahFunk ||
        config.mode == TremoloWahMode.psychedelicSweep) {
      _drawResonantFilterPeak(canvas, width, height);
    }
  }

  void _drawChannelWave({
    required Canvas canvas,
    required double width,
    required double centerY,
    required double amplitude,
    required double cycles,
    required double phase,
    required Color color,
    required LfoWaveform waveform,
  }) {
    final wavePaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path();
    for (double x = 0; x <= width; x += 2.0) {
      final t = (x / width) * cycles * 2 * math.pi + phase;
      double sample = 0.0;

      switch (waveform) {
        case LfoWaveform.sine:
          sample = math.sin(t);
          break;
        case LfoWaveform.triangle:
          sample = (2.0 / math.pi) * math.asin(math.sin(t));
          break;
        case LfoWaveform.square:
          sample = math.sin(t) >= 0 ? 0.9 : -0.9;
          break;
        case LfoWaveform.sawtooth:
          sample = (2.0 * ((t / (2 * math.pi)) - ((t / (2 * math.pi)).floor() + 0.5)));
          break;
      }

      final y = centerY - (sample * amplitude);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  void _drawResonantFilterPeak(Canvas canvas, double width, double height) {
    final peakPaint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = Colors.amber.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // Center frequency position mapped across width (200Hz to 4000Hz logarithmically)
    final minLog = math.log(200.0);
    final maxLog = math.log(4000.0);
    final curLog = math.log(config.centerFreqHz.clamp(200.0, 4000.0));
    final peakX = width * ((curLog - minLog) / (maxLog - minLog));
    final qWidth = (width / (config.resonance * 1.5)).clamp(15.0, 120.0);

    final path = Path();
    path.moveTo(0, height);
    for (double x = 0; x <= width; x += 3.0) {
      final dist = (x - peakX).abs();
      final normDist = dist / qWidth;
      final bell = math.exp(-normDist * normDist * 2.0);
      final y = height - (bell * (height * 0.75));
      path.lineTo(x, y);
    }
    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, peakPaint);
  }

  @override
  bool shouldRepaint(covariant _TremoloWahPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.config != config;
  }
}
