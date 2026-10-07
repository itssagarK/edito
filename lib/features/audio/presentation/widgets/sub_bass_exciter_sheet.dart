import 'dart:math' as math;
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/sub_bass_exciter_config.dart';
import '../../services/sub_bass_exciter_compiler_service.dart';

/// Interactive bottom sheet and docked panel for configuring Sub-Bass 808
/// saturator and harmonic low-end excitation.
class SubBassExciterSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SubBassExciterSheet({
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
      builder: (context) => SubBassExciterSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<SubBassExciterSheet> createState() => _SubBassExciterSheetState();
}

class _SubBassExciterSheetState extends State<SubBassExciterSheet>
    with SingleTickerProviderStateMixin {
  late SubBassExciterConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.subBassExciter;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(SubBassExciterConfig updated) {
    setState(() => _config = updated);
    final updatedClip = widget.clip.copyWith(subBassExciter: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case SubBassExciterMode.club808Punch:
        return const Color(0xFFFF5252);
      case SubBassExciterMode.cinematicSubRumble:
        return const Color(0xFFFF9100);
      case SubBassExciterMode.analogWarmthDrive:
        return const Color(0xFFFFD600);
      case SubBassExciterMode.phoneSpeakerExciter:
        return const Color(0xFF00E5FF);
      case SubBassExciterMode.heavyBassDrop:
        return const Color(0xFFE040FB);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isDocked) _buildDragHandle(),
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCanvasMonitor(),
              const SizedBox(height: 10),
              _buildLimiterGuardBadge(),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildPresetsRow(),
              const SizedBox(height: 16),
              _buildSliders(),
            ],
          ),
        ),
      ),
    );

    return content;
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accentColor.withAlpha(38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.speaker, color: _accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sub-Bass 808 Exciter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _config.isEnabled
                    ? 'Active: ${_config.mode.label} (${_config.subFrequency.toInt()}Hz +${_config.subBoostDb.toInt()}dB)'
                    : 'Disabled • Tap toggle to activate',
                style: TextStyle(
                  color: _config.isEnabled ? _accentColor : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _config.isEnabled,
          activeColor: _accentColor,
          onChanged: (val) => _applyConfig(_config.copyWith(isEnabled: val)),
        ),
        if (!widget.isDocked && widget.onDone != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(36, 36),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDone?.call();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCanvasMonitor() {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F080A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isEnabled ? _accentColor.withAlpha(100) : Colors.white12,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return CustomPaint(
              painter: _SubBassExciterPainter(
                config: _config,
                animationProgress: _animController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLimiterGuardBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accentColor.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: _accentColor, size: 14),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'DSP Guard: True-Peak Brickwall Ceiling Active (-0.05 dBFS)',
              style: TextStyle(
                color: Color(0xFFFF8A80),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUB HARMONIC CHARACTER',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SubBassExciterMode.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mode = SubBassExciterMode.values[index];
              final isSelected = _config.mode == mode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _accentColor,
                backgroundColor: const Color(0xFF20202E),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildPresetsRow() {
    final presets = [
      ('808 Trap', SubBassExciterConfig.trap808Punch),
      ('Sub Drop', SubBassExciterConfig.trailerSubDrop),
      ('Tape Warm', SubBassExciterConfig.tapeWarmBass),
      ('Phone Pop', SubBassExciterConfig.mobileMaxxBass),
      ('Dubstep', SubBassExciterConfig.dubstepSeismic),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRESETS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return ActionChip(
                backgroundColor: const Color(0xFF20202E),
                side: BorderSide(
                  color: _accentColor.withAlpha(50),
                ),
                label: Text(
                  preset.$1,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                onPressed: () => _applyConfig(preset.$2),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderTile(
          label: 'Sub Tuning Frequency',
          value: _config.subFrequency,
          min: 30.0,
          max: 120.0,
          displayValue: '${_config.subFrequency.toInt()} Hz',
          onChanged: (val) => _applyConfig(_config.copyWith(subFrequency: val)),
        ),
        _buildSliderTile(
          label: 'Sub Harmonic Boost',
          value: _config.subBoostDb,
          min: 0.0,
          max: 18.0,
          displayValue: '+${_config.subBoostDb.toStringAsFixed(1)} dB',
          onChanged: (val) => _applyConfig(_config.copyWith(subBoostDb: val)),
        ),
        _buildSliderTile(
          label: 'Drive Saturation',
          value: _config.driveSaturation,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.driveSaturation * 100).toInt()}%',
          onChanged: (val) =>
              _applyConfig(_config.copyWith(driveSaturation: val)),
        ),
        _buildSliderTile(
          label: 'Psychoacoustic Harmonics',
          value: _config.harmonicsMix,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.harmonicsMix * 100).toInt()}%',
          onChanged: (val) => _applyConfig(_config.copyWith(harmonicsMix: val)),
        ),
        _buildSliderTile(
          label: 'Low-Pass Cutoff',
          value: _config.lowPassCutoff,
          min: 80.0,
          max: 250.0,
          displayValue: '${_config.lowPassCutoff.toInt()} Hz',
          onChanged: (val) => _applyConfig(_config.copyWith(lowPassCutoff: val)),
        ),
      ],
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
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
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _accentColor,
            inactiveTrackColor: Colors.white12,
            thumbColor: _accentColor,
            overlayColor: _accentColor.withAlpha(38),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: _config.isEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

/// Skia Canvas painter rendering a simulated seismic sub-bass spectrum analyzer
/// and pulsating sub-acoustic energy ripples.
class _SubBassExciterPainter extends CustomPainter {
  final SubBassExciterConfig config;
  final double animationProgress;

  _SubBassExciterPainter({
    required this.config,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F080A));

    if (!config.isEnabled) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'SUB-BASS EXCITER DISABLED',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

    final centerX = size.width * 0.28;
    final centerY = size.height * 0.5;
    final boostScale = (config.subBoostDb / 18.0).clamp(0.2, 1.0);

    for (int ring = 1; ring <= 4; ring++) {
      final ringProgress = (animationProgress + (ring * 0.25)) % 1.0;
      final radius = 10.0 + ringProgress * (size.height * 0.45 * boostScale);
      final alpha = ((1.0 - ringProgress) * 180 * boostScale).toInt().clamp(0, 255);

      final ringPaint = Paint()
        ..color = const Color(0xFFFF5252).withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(centerX, centerY), radius, ringPaint);
    }

    final corePulse = math.sin(animationProgress * 4 * math.pi) * 4 * boostScale;
    final corePaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 10.0 + corePulse, corePaint);

    final barsStartX = size.width * 0.52;
    final barAreaWidth = size.width * 0.44;
    final barCount = 16;
    final barWidth = (barAreaWidth / barCount) - 3;

    for (int i = 0; i < barCount; i++) {
      final freqRatio = i / barCount;
      final subInfluence = (1.0 - freqRatio * 1.5).clamp(0.0, 1.0);
      final harmonicInfluence = (math.sin(freqRatio * math.pi * 3).abs() * config.harmonicsMix).clamp(0.0, 1.0);

      final barAnim = math.sin((animationProgress * 6) + (i * 0.5)).abs();
      final heightFactor = (subInfluence * boostScale * 0.85 + harmonicInfluence * 0.4) * barAnim;
      final barHeight = (heightFactor * size.height * 0.75).clamp(4.0, size.height * 0.85);

      final bx = barsStartX + (i * (barWidth + 3));
      final by = size.height - barHeight - 8;

      final barColor = (i < 4)
          ? const Color(0xFFFF5252)
          : (i < 9)
              ? const Color(0xFFFF9100)
              : const Color(0xFFFFD600);

      final barPaint = Paint()
        ..color = barColor.withAlpha(220)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, barWidth, barHeight),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    final badgeText =
        '${config.subFrequency.toInt()} HZ • +${config.subBoostDb.toStringAsFixed(1)} DB • ${(config.harmonicsMix * 100).toInt()}% OVERTONES';
    final badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Color(0xFFFF8A80),
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeRect = Rect.fromLTWH(
      8,
      size.height - badgePainter.height - 12,
      badgePainter.width + 12,
      badgePainter.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
      Paint()..color = Colors.black.withAlpha(200),
    );
    badgePainter.paint(
      canvas,
      Offset(badgeRect.left + 6, badgeRect.top + 3),
    );
  }

  @override
  bool shouldRepaint(covariant _SubBassExciterPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.animationProgress != animationProgress;
  }
}
