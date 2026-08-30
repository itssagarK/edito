import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/audio_effects_config.dart';
import '../../services/ai_voice_enhancer_service.dart';

class AudioMixerSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const AudioMixerSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioMixerSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<AudioMixerSheet> createState() => _AudioMixerSheetState();
}

class _AudioMixerSheetState extends State<AudioMixerSheet> {
  late double _volume;
  late AudioEffectsConfig _effects;
  bool _isListeningOriginal = false;

  @override
  void initState() {
    super.initState();
    _volume = widget.clip.volume;
    _effects = widget.clip.audioEffects;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      volume: _volume,
      audioEffects: _effects,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final clarityScore = AIVoiceEnhancerService.calculateClarityScore(_effects);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic_none, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 8),
                        Text('Audio & AI Voice Tools', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // 1. Master Volume Card
                _buildCard(
                  title: 'Volume Multiplier',
                  subtitle: '${(_volume * 100).toInt()}% (${_volume > 1.0 ? '+${((_volume - 1.0) * 12).toStringAsFixed(1)}dB' : '${((_volume - 1.0) * 20).toStringAsFixed(1)}dB'})',
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 2.0,
                    divisions: 40,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (val) {
                      setState(() => _volume = val);
                      _applyChange();
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // 2. AI Voice Enhancer & Noise Reduction Card
                _buildCard(
                  title: 'On-Device AI Voice Enhancer',
                  subtitle: 'DeepFilterNet speech isolation & noise removal',
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _effects.isVoiceEnhancerEnabled
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _effects.isVoiceEnhancerEnabled ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _effects.isVoiceEnhancerEnabled ? '$clarityScore% Clarity' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _effects.isVoiceEnhancerEnabled ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable AI Speech Clean', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Removes background hum, wind & room echo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _effects.isVoiceEnhancerEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (enabled) {
                          setState(() {
                            _effects = _effects.copyWith(isVoiceEnhancerEnabled: enabled);
                          });
                          _applyChange();
                        },
                      ),

                      if (_effects.isVoiceEnhancerEnabled) ...[
                        const Divider(color: AppColors.border, height: 20),
                        // De-noise intensity slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Noise Reduction', style: TextStyle(fontSize: 13)),
                            Text('${(_effects.denoiseIntensity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12)),
                          ],
                        ),
                        Slider(
                          value: _effects.denoiseIntensity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          activeColor: AppColors.accent,
                          inactiveColor: AppColors.surfaceElevated,
                          onChanged: (val) {
                            setState(() => _effects = _effects.copyWith(denoiseIntensity: val));
                            _applyChange();
                          },
                        ),

                        // Voice Clarity Boost slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Voice Presence & Clarity', style: TextStyle(fontSize: 13)),
                            Text('${(_effects.voiceClarityGain * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12)),
                          ],
                        ),
                        Slider(
                          value: _effects.voiceClarityGain,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          activeColor: AppColors.primaryLight,
                          inactiveColor: AppColors.surfaceElevated,
                          onChanged: (val) {
                            setState(() => _effects = _effects.copyWith(voiceClarityGain: val));
                            _applyChange();
                          },
                        ),

                        // A/B Comparison Toggle
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _isListeningOriginal = !_isListeningOriginal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isListeningOriginal ? 'Listening to Raw Audio (Original)' : 'Listening to AI Clean Audio (Enhanced)'),
                                duration: const Duration(milliseconds: 900),
                                backgroundColor: _isListeningOriginal ? AppColors.surfaceElevated : AppColors.primary,
                              ),
                            );
                          },
                          icon: Icon(_isListeningOriginal ? Icons.hearing_disabled : Icons.hearing, size: 16),
                          label: Text(_isListeningOriginal ? 'Showing: Original Raw Audio' : 'Showing: AI Cleaned Audio'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isListeningOriginal ? AppColors.accentWarm : AppColors.accent,
                            side: BorderSide(color: _isListeningOriginal ? AppColors.accentWarm : AppColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Fades and Auto-Ducking
                _buildCard(
                  title: 'Fade Envelopes & Auto-Ducking',
                  subtitle: 'Automatic volume transitions',
                  child: Column(
                    children: [
                      // Fade In
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fade In Duration', style: TextStyle(fontSize: 13)),
                          Text('${(_effects.fadeInMs / 1000.0).toStringAsFixed(1)}s', style: AppTypography.timecode.copyWith(fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _effects.fadeInMs.toDouble(),
                        min: 0,
                        max: 4000,
                        divisions: 40,
                        activeColor: AppColors.audioTrack,
                        inactiveColor: AppColors.surfaceElevated,
                        onChanged: (val) {
                          setState(() => _effects = _effects.copyWith(fadeInMs: val.toInt()));
                          _applyChange();
                        },
                      ),

                      // Auto-Ducking
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Smart Auto-Ducking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Auto-lower volume (-10dB) when dialogue is detected', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _effects.isDuckingEnabled,
                        activeColor: AppColors.audioTrack,
                        onChanged: (enabled) {
                          setState(() => _effects = _effects.copyWith(isDuckingEnabled: enabled));
                          _applyChange();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.labelSmall),
                ],
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
