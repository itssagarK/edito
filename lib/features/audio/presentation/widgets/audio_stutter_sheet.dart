import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/audio_stutter_config.dart';
import '../../services/audio_stutter_compiler_service.dart';

class AudioStutterSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AudioStutterSheet({
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
      builder: (context) => AudioStutterSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AudioStutterSheet> createState() => _AudioStutterSheetState();
}

class _AudioStutterSheetState extends State<AudioStutterSheet> with SingleTickerProviderStateMixin {
  late AudioStutterConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.audioStutter;
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

  void _applyConfig(AudioStutterConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(audioStutter: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case AudioStutterMode.straight:
        return const Color(0xFF00E5FF); // Electric cyan
      case AudioStutterMode.accelerando:
        return const Color(0xFFFF1744); // Machine gun crimson
      case AudioStutterMode.pitchDrop:
        return const Color(0xFFFF9100); // Vinyl amber
      case AudioStutterMode.reverseEcho:
        return const Color(0xFFE040FB); // Ping-pong magenta
      case AudioStutterMode.granularCloud:
        return const Color(0xFF76FF03); // Granular neon green
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
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitorVisualizer(),
                  const SizedBox(height: 16),
                  _buildEnableToggle(),
                  if (_config.isEnabled) ...[
                    const SizedBox(height: 16),
                    _buildDivisionSelector(),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildPresetChips(),
                    const SizedBox(height: 16),
                    _buildControls(),
                    const SizedBox(height: 16),
                    _buildLimiterBadge(),
                  ],
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.graphic_eq, color: _accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rhythmic Audio Stutter',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Micro-buffer glitch repeater & tape stop drops',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (widget.onDone != null)
            IconButton(
              onPressed: widget.onDone,
              icon: const Icon(Icons.check, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonitorVisualizer() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF090D14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isActive ? _accentColor.withOpacity(0.6) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return CustomPaint(
              painter: _AudioStutterPainter(
                config: _config,
                accentColor: _accentColor,
                time: _animController.value,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _accentColor.withOpacity(0.5), width: 0.8),
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
                          const SizedBox(width: 6),
                          Text(
                            _config.isActive
                                ? 'BUFFER: ${_config.sliceDurationMs.round()}MS • ${_config.repeats}X REPEATS'
                                : 'PASS-THROUGH (NO STUTTER)',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GRID: ${_config.division.label} @ ${_config.bpm.round()} BPM',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
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

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.repeat : Icons.repeat_one,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Stutter Repeater',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _config.isEnabled ? 'Micro-buffer glitch repeats active' : 'Linear continuous audio stream',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
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

  Widget _buildDivisionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTE DIVISION (GRID SYNC)',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StutterDivision.values.map((div) {
            final isSelected = _config.division == div;
            return ChoiceChip(
              label: Text(div.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.transparent,
                width: 1.2,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(division: div));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STUTTER MODE',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AudioStutterMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: isSelected,
              selectedColor: _accentColor.withOpacity(0.2),
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: AppTypography.bodySmall.copyWith(
                color: isSelected ? _accentColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? _accentColor : Colors.transparent,
                width: 1.2,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyConfig(_config.copyWith(mode: mode));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPresetChips() {
    final presets = [
      {'name': '1/8 Beat Roll', 'cfg': AudioStutterConfig.eighthBeatRoll},
      {'name': '1/16 Glitch', 'cfg': AudioStutterConfig.sixteenthGlitch},
      {'name': 'Pitch Drop Brake', 'cfg': AudioStutterConfig.pitchDropBrake},
      {'name': 'Machine Gun Drill', 'cfg': AudioStutterConfig.machineGunDrill},
      {'name': 'Granular Cloud', 'cfg': AudioStutterConfig.granularCloud},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURATED PRESETS',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final cfg = p['cfg'] as AudioStutterConfig;
              final isMatch = _config.mode == cfg.mode &&
                  _config.division == cfg.division &&
                  _config.repeats == cfg.repeats;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(p['name'] as String),
                  backgroundColor: isMatch ? _accentColor.withOpacity(0.25) : AppColors.surfaceVariant,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isMatch ? _accentColor : AppColors.textPrimary,
                    fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isMatch ? _accentColor : AppColors.border,
                    width: 1.0,
                  ),
                  onPressed: () {
                    _applyConfig(cfg.copyWith(isEnabled: true));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          title: 'Repeats Count',
          valueText: '${_config.repeats}x',
          value: _config.repeats.toDouble(),
          min: 1.0,
          max: 8.0,
          divisions: 7,
          onChanged: (v) => _applyConfig(_config.copyWith(repeats: v.round())),
        ),
        _buildSliderTile(
          title: 'Tempo (BPM)',
          valueText: '${_config.bpm.round()} BPM',
          value: _config.bpm,
          min: 60.0,
          max: 200.0,
          onChanged: (v) => _applyConfig(_config.copyWith(bpm: v)),
        ),
        _buildSliderTile(
          title: 'Gate Duty Cycle (Chop Width)',
          valueText: '${(_config.gateWidth * 100).round()}%',
          value: _config.gateWidth,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(gateWidth: v)),
        ),
        if (_config.mode == AudioStutterMode.pitchDrop)
          _buildSliderTile(
            title: 'Pitch Drop Depth',
            valueText: '-${_config.pitchDropSemitones.toStringAsFixed(1)} st',
            value: _config.pitchDropSemitones,
            min: 0.0,
            max: 12.0,
            onChanged: (v) => _applyConfig(_config.copyWith(pitchDropSemitones: v)),
          ),
        _buildSliderTile(
          title: 'Wet Stutter Mix',
          valueText: '${(_config.mix * 100).round()}%',
          value: _config.mix,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => _applyConfig(_config.copyWith(mix: v)),
        ),
      ],
    );
  }

  Widget _buildLimiterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Studio Brickwall Limiter active (Ceiling: -0.5 dB True-Peak) to eliminate digital clipping',
              style: AppTypography.caption.copyWith(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
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
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Custom Skia painter displaying animated rhythmic buffer slice sequencer.
class _AudioStutterPainter extends CustomPainter {
  final AudioStutterConfig config;
  final Color accentColor;
  final double time;

  _AudioStutterPainter({
    required this.config,
    required this.accentColor,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final midY = height * 0.5;

    // Viewport background grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    canvas.drawLine(Offset(0, midY), Offset(width, midY), gridPaint);

    if (!config.isActive) {
      // Draw smooth passing sine wave
      final passPath = Path();
      for (double x = 0; x < width; x += 2) {
        final y = midY + math.sin((x / width * 4 * math.pi) + (time * 2 * math.pi)) * 20;
        if (x == 0) {
          passPath.moveTo(x, y);
        } else {
          passPath.lineTo(x, y);
        }
      }
      final passPaint = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(passPath, passPaint);
      return;
    }

    // Draw repeating buffer slices
    final count = config.repeats;
    final totalSlotW = width / count;

    for (int i = 0; i < count; i++) {
      double slotX = i * totalSlotW;
      double slotW = totalSlotW;

      if (config.mode == AudioStutterMode.accelerando) {
        // Progressively narrowing slots
        final factor = 1.0 - (i * 0.08);
        slotW = (totalSlotW * factor).clamp(12.0, totalSlotW);
      }

      final activeW = slotW * config.gateWidth;

      // Slice background card
      final isCurrent = ((time * count).floor() % count) == i;
      final cardPaint = Paint()
        ..color = isCurrent ? accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(slotX + 2, 22, activeW - 4, height - 44), const Radius.circular(4)),
        cardPaint,
      );

      // Slice border
      final borderPaint = Paint()
        ..color = isCurrent ? accentColor : accentColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 1.6 : 0.8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(slotX + 2, 22, activeW - 4, height - 44), const Radius.circular(4)),
        borderPaint,
      );

      // Internal waveform burst
      final wavePath = Path();
      final points = 24;
      double freq = 2.0;
      double amp = 16.0;

      if (config.mode == AudioStutterMode.pitchDrop) {
        // Pitch drop stretches frequency and drops amplitude across repeats
        freq = 3.0 - (i * 0.35).clamp(0.2, 2.5);
        amp = 18.0 - (i * 1.5).clamp(2.0, 14.0);
      }

      for (int p = 0; p <= points; p++) {
        final px = slotX + 2 + ((activeW - 4) * (p / points));
        final py = midY + math.sin((p / points) * 2 * math.pi * freq) * amp;
        if (p == 0) {
          wavePath.moveTo(px, py);
        } else {
          wavePath.lineTo(px, py);
        }
      }

      final wavePaint = Paint()
        ..color = isCurrent ? Colors.white : accentColor.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2.2 : 1.4;
      canvas.drawPath(wavePath, wavePaint);
    }

    // Playhead sweep line
    final playheadX = (time * width) % width;
    final sweepPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(playheadX, 16), Offset(playheadX, height - 16), sweepPaint);
    canvas.drawCircle(Offset(playheadX, 16), 3.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _AudioStutterPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.time != time;
  }
}
