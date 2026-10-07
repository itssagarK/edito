import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/pitch_harmonizer_config.dart';
import '../../services/pitch_harmonizer_compiler_service.dart';

class PitchHarmonizerSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const PitchHarmonizerSheet({
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
      builder: (context) => PitchHarmonizerSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<PitchHarmonizerSheet> createState() => _PitchHarmonizerSheetState();
}

class _PitchHarmonizerSheetState extends State<PitchHarmonizerSheet> with SingleTickerProviderStateMixin {
  late PitchHarmonizerConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.pitchHarmonizer;
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

  void _applyConfig(PitchHarmonizerConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(pitchHarmonizer: updated);
    widget.onSave(updatedClip);
  }

  Color get _accentColor {
    switch (_config.mode) {
      case PitchHarmonizerMode.naturalSemitone:
        return const Color(0xFF00E5FF); // Electric cyan
      case PitchHarmonizerMode.octaveDoubler:
        return const Color(0xFFFF9100); // Warm orange
      case PitchHarmonizerMode.vocalHarmonizer:
        return const Color(0xFF76FF03); // Harmonic lime
      case PitchHarmonizerMode.chipmunkHelium:
        return const Color(0xFFFF4081); // Bright pink
      case PitchHarmonizerMode.deepMonsterSub:
        return const Color(0xFF9C27B0); // Dark violet
      case PitchHarmonizerMode.roboticRingMod:
        return const Color(0xFFFFD600); // Cybernetic yellow
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

              // Enable switch
              _buildEnableSwitch(),
              const SizedBox(height: 12),

              // Live interactive musical keyboard monitor
              _buildKeyboardMonitor(),
              const SizedBox(height: 16),

              // Presets row
              _buildPresetsSection(),
              const SizedBox(height: 16),

              // Mode selector
              _buildModeSelector(),
              const SizedBox(height: 16),

              // Harmony interval selector (if mode is harmonizer or doubler)
              if (_config.mode == PitchHarmonizerMode.vocalHarmonizer ||
                  _config.mode == PitchHarmonizerMode.octaveDoubler) ...[
                _buildHarmonyIntervalSelector(),
                const SizedBox(height: 16),
              ],

              // Parameter sliders
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
        Icon(Icons.music_note_rounded, color: _accentColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vocal Pitch & Harmonizer Studio',
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                'Musical semitone transposition, interval harmonies, & robot timbre',
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
                _config.isEnabled ? Icons.mic : Icons.mic_off,
                color: _config.isEnabled ? _accentColor : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _config.isEnabled ? 'Harmonizer Active' : 'Harmonizer Bypassed',
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

  Widget _buildKeyboardMonitor() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1019),
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
                  painter: _PitchHarmonizerPainter(
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
                      'PITCH: ${_config.semitones >= 0 ? '+' : ''}${_config.semitones} ST (${_config.cents >= 0 ? '+' : ''}${_config.cents}¢)',
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
      {'name': '5th Harmony', 'config': PitchHarmonizerConfig.leadVocalFifthHarmony, 'icon': Icons.music_note},
      {'name': 'Sub-Octave', 'config': PitchHarmonizerConfig.deepSubOctaveDoubler, 'icon': Icons.arrow_downward},
      {'name': 'Airy Octave', 'config': PitchHarmonizerConfig.airyUpperOctave, 'icon': Icons.arrow_upward},
      {'name': 'Monster Deep', 'config': PitchHarmonizerConfig.demonGravePitch, 'icon': Icons.sentiment_very_dissatisfied},
      {'name': 'Dalek Robot', 'config': PitchHarmonizerConfig.dalekRoboticMod, 'icon': Icons.smart_toy},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VOCAL PRESETS',
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
              final presetConfig = p['config'] as PitchHarmonizerConfig;
              final isSelected = _config.mode == presetConfig.mode &&
                  _config.semitones == presetConfig.semitones;
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
          'PITCH ENGINE',
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
          children: PitchHarmonizerMode.values.map((mode) {
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

  Widget _buildHarmonyIntervalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARMONY INTERVAL',
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
            children: HarmonyInterval.values.map((interval) {
              final isSelected = _config.harmonyInterval == interval;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(interval.displayName),
                  selected: isSelected,
                  selectedColor: _accentColor,
                  backgroundColor: AppColors.surfaceVariant.withOpacity(0.5),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _applyConfig(_config.copyWith(harmonyInterval: interval));
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

  Widget _buildSliders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Semitones Slider
        _buildSliderTile(
          title: 'Pitch Transposition (Semitones)',
          valueText: '${_config.semitones >= 0 ? '+' : ''}${_config.semitones} st',
          value: _config.semitones.toDouble(),
          min: -12.0,
          max: 12.0,
          divisions: 24,
          onChanged: (val) => _applyConfig(_config.copyWith(semitones: val.round())),
        ),

        // Cents Fine Tuning
        _buildSliderTile(
          title: 'Fine-Tuning Pitch Drift',
          valueText: '${_config.cents >= 0 ? '+' : ''}${_config.cents} ¢',
          value: _config.cents.toDouble(),
          min: -50.0,
          max: 50.0,
          divisions: 100,
          onChanged: (val) => _applyConfig(_config.copyWith(cents: val.round())),
        ),

        // Harmony Voice Level (if harmonizer/doubler)
        if (_config.mode == PitchHarmonizerMode.vocalHarmonizer ||
            _config.mode == PitchHarmonizerMode.octaveDoubler)
          _buildSliderTile(
            title: 'Harmony Voice Level',
            valueText: '${(_config.harmonyMix * 100).round()}%',
            value: _config.harmonyMix,
            min: 0.1,
            max: 1.0,
            onChanged: (val) => _applyConfig(_config.copyWith(harmonyMix: val)),
          ),

        // Wet / Dry Mix
        _buildSliderTile(
          title: 'Wet / Dry Balance',
          valueText: '${(_config.mix * 100).round()}%',
          value: _config.mix,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => _applyConfig(_config.copyWith(mix: val)),
        ),

        // Formant Preservation Switch
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Formant Acoustic Preservation',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            'Preserves natural human vocal tract resonance',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          value: _config.formantPreserve,
          activeColor: _accentColor,
          onChanged: (val) => _applyConfig(_config.copyWith(formantPreserve: val)),
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

/// Custom Skia painter displaying stylized musical keyboard keys and pitch frequency indicators.
class _PitchHarmonizerPainter extends CustomPainter {
  final PitchHarmonizerConfig config;
  final double animationValue;
  final Color accentColor;

  _PitchHarmonizerPainter({
    required this.config,
    required this.animationValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Viewport background grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    if (!config.isActive) {
      final flatPaint = Paint()
        ..color = Colors.grey.withOpacity(0.4)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(0, height * 0.5), Offset(width, height * 0.5), flatPaint);
      return;
    }

    // 1. Draw Stylized Musical Keyboard at the bottom
    const numWhiteKeys = 14;
    final keyW = width / numWhiteKeys;
    final keyH = height * 0.35;
    final keyY = height - keyH;

    final whiteKeyPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final whiteKeyBorder = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int k = 0; k < numWhiteKeys; k++) {
      final rect = Rect.fromLTWH(k * keyW, keyY, keyW, keyH);
      canvas.drawRect(rect, whiteKeyPaint);
      canvas.drawRect(rect, whiteKeyBorder);
    }

    // Root note key (center key 7)
    final rootKeyIdx = (7 + (config.semitones * 0.5)).clamp(0, numWhiteKeys - 1).round();
    final rootRect = Rect.fromLTWH(rootKeyIdx * keyW, keyY, keyW, keyH);
    final activeKeyPaint = Paint()
      ..color = accentColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rootRect, activeKeyPaint);

    // If Harmonizer or Doubler, highlight harmony note key
    if (config.mode == PitchHarmonizerMode.vocalHarmonizer ||
        config.mode == PitchHarmonizerMode.octaveDoubler) {
      final harmIdx = (rootKeyIdx + (config.harmonyInterval.semitoneOffset * 0.5))
          .clamp(0, numWhiteKeys - 1)
          .round();
      final harmRect = Rect.fromLTWH(harmIdx * keyW, keyY, keyW, keyH);
      final harmKeyPaint = Paint()
        ..color = const Color(0xFFFF4081).withOpacity(0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRect(harmRect, harmKeyPaint);
    }

    // 2. Animated audio spectral pitch harmonics
    final wavePath = Path();
    wavePath.moveTo(0, height * 0.35);
    final freq = 2.0 + (config.semitones.abs() * 0.3);
    for (double x = 0; x <= width; x += 3.0) {
      final phase = animationValue * 2 * math.pi;
      final y = (height * 0.35) +
          math.sin((x / width) * freq * 2 * math.pi + phase) * (height * 0.18);
      wavePath.lineTo(x, y);
    }

    final wavePaint = Paint()
      ..color = accentColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _PitchHarmonizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.config != config;
  }
}
