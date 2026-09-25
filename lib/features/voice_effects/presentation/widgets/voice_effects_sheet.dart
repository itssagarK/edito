import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/voice_effects_config.dart';
import '../../services/voice_effects_compiler_service.dart';

/// CapCut Pro AI Voice Changer & Audio Timbre Morphing Studio Sheet
class VoiceEffectsSheet extends StatefulWidget {
  final VoiceEffectsConfig initialConfig;
  final ValueChanged<VoiceEffectsConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const VoiceEffectsSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  });

  @override
  State<VoiceEffectsSheet> createState() => _VoiceEffectsSheetState();
}

class _VoiceEffectsSheetState extends State<VoiceEffectsSheet> {
  late VoiceEffectsConfig _config;
  bool _isComparing = false; // Hold to compare raw unaltered voice
  VoiceEffectCategory _selectedCategory = VoiceEffectCategory.all;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(VoiceEffectsConfig updated) {
    setState(() {
      _config = updated;
    });
    widget.onApply(updated);
  }

  void _reset() {
    const fresh = VoiceEffectsConfig();
    _updateConfig(fresh);
  }

  void _selectCharacter(VoiceEffectCharacter character) {
    if (character == VoiceEffectCharacter.none) {
      _reset();
      return;
    }
    final preset = VoiceEffectsConfig.preset(character);
    _updateConfig(preset);
  }

  IconData _getCharacterIcon(VoiceEffectCharacter character) {
    switch (character) {
      case VoiceEffectCharacter.none:
        return Icons.mic_none;
      case VoiceEffectCharacter.chipmunk:
        return Icons.pets;
      case VoiceEffectCharacter.deepMonster:
        return Icons.whatshot;
      case VoiceEffectCharacter.robotVocoder:
        return Icons.smart_toy;
      case VoiceEffectCharacter.echoCave:
        return Icons.landscape;
      case VoiceEffectCharacter.heliumBalloon:
        return Icons.bubble_chart;
      case VoiceEffectCharacter.retroRadio:
        return Icons.radio;
      case VoiceEffectCharacter.vinylLofi:
        return Icons.album;
      case VoiceEffectCharacter.megaphone:
        return Icons.campaign;
      case VoiceEffectCharacter.synthAlien:
        return Icons.rocket_launch;
      case VoiceEffectCharacter.custom:
        return Icons.tune;
    }
  }

  Color _getCharacterColor(VoiceEffectCharacter character) {
    switch (character) {
      case VoiceEffectCharacter.none:
        return AppColors.textSecondary;
      case VoiceEffectCharacter.chipmunk:
        return Colors.amberAccent;
      case VoiceEffectCharacter.deepMonster:
        return Colors.deepOrangeAccent;
      case VoiceEffectCharacter.robotVocoder:
        return Colors.cyanAccent;
      case VoiceEffectCharacter.echoCave:
        return Colors.lightBlueAccent;
      case VoiceEffectCharacter.heliumBalloon:
        return Colors.pinkAccent;
      case VoiceEffectCharacter.retroRadio:
        return Colors.orangeAccent;
      case VoiceEffectCharacter.vinylLofi:
        return Colors.purpleAccent;
      case VoiceEffectCharacter.megaphone:
        return Colors.redAccent;
      case VoiceEffectCharacter.synthAlien:
        return Colors.greenAccent;
      case VoiceEffectCharacter.custom:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = _isComparing ? const VoiceEffectsConfig() : _config;

    return Container(
      key: const ValueKey('voice_effects_sheet'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            _buildHeader(),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category Selector
                    _buildCategoryChips(),
                    const SizedBox(height: 12),

                    // Character Preset Grid / Row
                    _buildCharacterPresets(),
                    const SizedBox(height: 14),

                    // Hold to Compare & Status Banner
                    _buildCompareBar(effectiveConfig),
                    const SizedBox(height: 14),

                    // Pitch Shift Semitones Slider
                    _buildPitchSlider(),
                    const SizedBox(height: 10),

                    // Timbre Formant Resonance Slider
                    _buildSlider(
                      label: 'Formant / Timbre Resonance',
                      value: _config.timbreResonance,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          character: _config.character == VoiceEffectCharacter.none
                              ? VoiceEffectCharacter.custom
                              : _config.character,
                          timbreResonance: val,
                        ));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Vibrato Pitch Modulation Slider
                    _buildSlider(
                      label: 'Vibrato Depth',
                      value: _config.vibratoDepth,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          character: _config.character == VoiceEffectCharacter.none
                              ? VoiceEffectCharacter.custom
                              : _config.character,
                          vibratoDepth: val,
                        ));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Cavern Echo Delay Slider
                    _buildSlider(
                      label: 'Cavern Echo Delay',
                      value: _config.echoDelayMs.toDouble(),
                      min: 0.0,
                      max: 600.0,
                      displayValue: '${_config.echoDelayMs} ms',
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          character: _config.character == VoiceEffectCharacter.none
                              ? VoiceEffectCharacter.custom
                              : _config.character,
                          echoDelayMs: val.round(),
                          echoFeedback: val > 0 && _config.echoFeedback == 0.0 ? 0.4 : _config.echoFeedback,
                        ));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Distortion / Lo-Fi Saturation Slider
                    _buildSlider(
                      label: 'Distortion & Overdrive',
                      value: _config.distortion,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          character: _config.character == VoiceEffectCharacter.none
                              ? VoiceEffectCharacter.custom
                              : _config.character,
                          distortion: val,
                        ));
                      },
                    ),
                    const SizedBox(height: 10),

                    // Wet / Dry Mix Slider
                    _buildSlider(
                      key: const ValueKey('voice_effects_mix_slider'),
                      label: 'Wet / Dry Effect Mix',
                      value: _config.mix,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          mix: val,
                        ));
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'CapCut Pro Voice Changer',
            style: AppTypography.subtitle2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            key: const ValueKey('voice_effects_reset_button'),
            onPressed: _reset,
            child: Text(
              'Reset',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            key: const ValueKey('voice_effects_done_button'),
            icon: const Icon(Icons.check, color: AppColors.primary),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VoiceEffectCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat.label),
              selected: isSelected,
              selectedColor: AppColors.primary.withValues(alpha: 0.25),
              backgroundColor: AppColors.cardSurface,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCharacterPresets() {
    final availableCharacters = VoiceEffectCharacter.values.where((c) {
      if (_selectedCategory == VoiceEffectCategory.all) return true;
      return c.category == _selectedCategory;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableCharacters.map((char) {
          final isSelected = _config.character == char && _config.isEnabled;
          final icon = _getCharacterIcon(char);
          final color = _getCharacterColor(char);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              key: ValueKey('voice_effect_character_${char.name}'),
              onTap: () => _selectCharacter(char),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : AppColors.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      char.label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompareBar(VoiceEffectsConfig effectiveConfig) {
    final badge = VoiceEffectsCompilerService.getBadgeLabel(effectiveConfig);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _isComparing ? Icons.volume_off : Icons.graphic_eq,
            color: _isComparing ? Colors.amberAccent : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isComparing
                  ? 'Raw Audio Bypass (Comparing)'
                  : (badge.isNotEmpty ? badge : 'Standard Vocal Pass'),
              style: AppTypography.caption.copyWith(
                color: _isComparing ? Colors.amberAccent : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            key: const ValueKey('voice_effects_hold_to_compare'),
            onTapDown: (_) => setState(() => _isComparing = true),
            onTapUp: (_) => setState(() => _isComparing = false),
            onTapCancel: () => setState(() => _isComparing = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isComparing ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(
                'Hold to Compare',
                style: AppTypography.caption.copyWith(
                  color: _isComparing ? Colors.black : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchSlider() {
    final pitch = _config.pitchSemitones;
    final pitchText = pitch > 0 ? '+${pitch.toStringAsFixed(1)} st' : '${pitch.toStringAsFixed(1)} st';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pitch Shift (Semitones)',
              style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            ),
            Row(
              children: [
                Text(
                  pitchText,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pitch != 0.0) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    key: const ValueKey('voice_effects_reset_pitch_button'),
                    onTap: () {
                      _updateConfig(_config.copyWith(pitchSemitones: 0.0));
                    },
                    child: const Icon(Icons.restart_alt, size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            key: const ValueKey('voice_effects_pitch_slider'),
            value: pitch,
            min: -12.0,
            max: 12.0,
            divisions: 48, // Quarter-semitone precision
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                isEnabled: true,
                character: _config.character == VoiceEffectCharacter.none
                    ? VoiceEffectCharacter.custom
                    : _config.character,
                pitchSemitones: val,
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    Key? key,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool percent = false,
    String? displayValue,
  }) {
    final text = displayValue ?? (percent ? '${(value * 100).round()}%' : value.toStringAsFixed(2));

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
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
