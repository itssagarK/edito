import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/audio_effects_config.dart';
import '../../services/ai_voice_enhancer_service.dart';
import 'parametric_eq_curve_widget.dart';

class AudioMixerSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AudioMixerSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => AudioMixerSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<AudioMixerSheet> createState() => _AudioMixerSheetState();
}

class _AudioMixerSheetState extends State<AudioMixerSheet> with SingleTickerProviderStateMixin {
  late double _volume;
  late AudioEffectsConfig _effects;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _volume = widget.clip.volume;
    _effects = widget.clip.audioEffects;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      volume: _volume,
      audioEffects: _effects,
    );
    widget.onSave(updated);
  }

  void _applyEqualizerPreset(EqualizerPreset preset) {
    setState(() {
      switch (preset) {
        case EqualizerPreset.flat:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.flat,
            eqLowGain: 0.0,
            eqLowFreq: 100.0,
            eqMidGain: 0.0,
            eqMidFreq: 2500.0,
            eqMidQ: 1.0,
            eqHighGain: 0.0,
            eqHighFreq: 10000.0,
            highPassCutoff: 0.0,
            lowPassCutoff: 22000.0,
          );
          break;
        case EqualizerPreset.podcastWarmth:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.podcastWarmth,
            eqLowGain: 4.5,
            eqLowFreq: 120.0,
            eqMidGain: 2.5,
            eqMidFreq: 3000.0,
            eqMidQ: 1.2,
            eqHighGain: 1.5,
            eqHighFreq: 10000.0,
            highPassCutoff: 80.0,
            lowPassCutoff: 20000.0,
          );
          break;
        case EqualizerPreset.bassBoost:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.bassBoost,
            eqLowGain: 7.0,
            eqLowFreq: 90.0,
            eqMidGain: -1.0,
            eqMidFreq: 1000.0,
            eqMidQ: 1.0,
            eqHighGain: 0.0,
            eqHighFreq: 10000.0,
            highPassCutoff: 30.0,
            lowPassCutoff: 22000.0,
          );
          break;
        case EqualizerPreset.trebleSparkle:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.trebleSparkle,
            eqLowGain: -1.0,
            eqLowFreq: 100.0,
            eqMidGain: 1.5,
            eqMidFreq: 3500.0,
            eqMidQ: 1.1,
            eqHighGain: 6.5,
            eqHighFreq: 12000.0,
            highPassCutoff: 60.0,
            lowPassCutoff: 22000.0,
          );
          break;
        case EqualizerPreset.vocalAir:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.vocalAir,
            eqLowGain: -2.0,
            eqLowFreq: 150.0,
            eqMidGain: 3.0,
            eqMidFreq: 4000.0,
            eqMidQ: 1.3,
            eqHighGain: 5.0,
            eqHighFreq: 12000.0,
            highPassCutoff: 90.0,
            lowPassCutoff: 22000.0,
          );
          break;
        case EqualizerPreset.telephone:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.telephone,
            eqLowGain: -12.0,
            eqLowFreq: 200.0,
            eqMidGain: 6.0,
            eqMidFreq: 1800.0,
            eqMidQ: 2.0,
            eqHighGain: -12.0,
            eqHighFreq: 8000.0,
            highPassCutoff: 400.0,
            lowPassCutoff: 3500.0,
          );
          break;
        case EqualizerPreset.deMuddy:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.deMuddy,
            eqLowGain: -1.0,
            eqLowFreq: 100.0,
            eqMidGain: -4.5,
            eqMidFreq: 450.0,
            eqMidQ: 1.8,
            eqHighGain: 2.0,
            eqHighFreq: 8000.0,
            highPassCutoff: 80.0,
            lowPassCutoff: 22000.0,
          );
          break;
        case EqualizerPreset.custom:
          _effects = _effects.copyWith(
            isEqualizerEnabled: true,
            equalizerPreset: EqualizerPreset.custom,
          );
          break;
      }
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.58;
    final badge = AIVoiceEnhancerService.getAudioBadge(_effects);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              children: [
                if (!widget.isDocked)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.graphic_eq, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text('Pro Audio Studio', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 18),
                      onPressed: () {
                        if (widget.onDone != null) {
                          widget.onDone!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Studio Navigation Tabs
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent),
              ),
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: '🎚️ EQ'),
                Tab(text: '🎙️ Vocal'),
                Tab(text: '🦆 Ducking'),
                Tab(text: '🔥 FX'),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEQTab(),
                _buildVocalStudioTab(),
                _buildDuckingLevelsTab(),
                _buildVoiceFXTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: PARAMETRIC EQUALIZER STUDIO
  // ---------------------------------------------------------------------------
  Widget _buildEQTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parametric 3-Band Equalizer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Drag nodes on graph or use precision sliders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            Switch(
              value: _effects.isEqualizerEnabled,
              activeColor: AppColors.accent,
              onChanged: (val) {
                setState(() => _effects = _effects.copyWith(isEqualizerEnabled: val));
                _applyChange();
              },
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Interactive Frequency Response Canvas
        ParametricEQCurveWidget(
          config: _effects,
          height: 150,
          onChanged: (updated) {
            setState(() => _effects = updated);
            _applyChange();
          },
        ),

        const SizedBox(height: 10),

        // EQ Presets Carousel
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: EqualizerPreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final preset = EqualizerPreset.values[idx];
              final isSelected = _effects.isEqualizerEnabled && _effects.equalizerPreset == preset;
              return InkWell(
                onTap: () => _applyEqualizerPreset(preset),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Precision Frequency & Gain Sliders
        _buildSliderCard(
          title: 'Low Shelf (Bass)',
          valueText: '${_effects.eqLowGain > 0 ? "+" : ""}${_effects.eqLowGain.toStringAsFixed(1)} dB  @ ${_effects.eqLowFreq.toInt()} Hz',
          color: const Color(0xFF00E5FF),
          value: _effects.eqLowGain,
          min: -15.0,
          max: 15.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isEqualizerEnabled: true,
                equalizerPreset: EqualizerPreset.custom,
                eqLowGain: double.parse(v.toStringAsFixed(1)),
              );
            });
            _applyChange();
          },
        ),

        const SizedBox(height: 8),

        _buildSliderCard(
          title: 'Mid Bell (Presence)',
          valueText: '${_effects.eqMidGain > 0 ? "+" : ""}${_effects.eqMidGain.toStringAsFixed(1)} dB  @ ${_effects.eqMidFreq >= 1000 ? "${(_effects.eqMidFreq / 1000).toStringAsFixed(1)}k" : _effects.eqMidFreq.toInt()} Hz',
          color: const Color(0xFFFF9100),
          value: _effects.eqMidGain,
          min: -15.0,
          max: 15.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isEqualizerEnabled: true,
                equalizerPreset: EqualizerPreset.custom,
                eqMidGain: double.parse(v.toStringAsFixed(1)),
              );
            });
            _applyChange();
          },
        ),

        const SizedBox(height: 8),

        _buildSliderCard(
          title: 'High Shelf (Air & Treble)',
          valueText: '${_effects.eqHighGain > 0 ? "+" : ""}${_effects.eqHighGain.toStringAsFixed(1)} dB  @ ${(_effects.eqHighFreq / 1000).toStringAsFixed(1)}k Hz',
          color: const Color(0xFFD500F9),
          value: _effects.eqHighGain,
          min: -15.0,
          max: 15.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isEqualizerEnabled: true,
                equalizerPreset: EqualizerPreset.custom,
                eqHighGain: double.parse(v.toStringAsFixed(1)),
              );
            });
            _applyChange();
          },
        ),

        const SizedBox(height: 8),

        // HPF / Low Cut Filter
        _buildSliderCard(
          title: 'High-Pass Filter (Low Cut)',
          valueText: _effects.highPassCutoff <= 20.0 ? 'OFF' : '${_effects.highPassCutoff.toInt()} Hz',
          color: AppColors.textMuted,
          value: _effects.highPassCutoff,
          min: 0.0,
          max: 300.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isEqualizerEnabled: true,
                equalizerPreset: EqualizerPreset.custom,
                highPassCutoff: double.parse(v.toStringAsFixed(0)),
              );
            });
            _applyChange();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: VOCAL ISOLATION & DE-NOISE STUDIO
  // ---------------------------------------------------------------------------
  Widget _buildVocalStudioTab() {
    final clarityScore = AIVoiceEnhancerService.calculateClarityScore(_effects);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Mode Selector Card
        _buildCard(
          title: '🎙️ Vocal Isolation & Neural Gating',
          subtitle: 'Isolate voice, clean background noise, or remove vocals for karaoke',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent),
            ),
            child: Text(
              '$clarityScore% CLARITY',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
            ),
          ),
          child: Column(
            children: [
              ...VocalIsolationMode.values.map((mode) {
                final isSelected = _effects.vocalIsolationMode == mode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withOpacity(0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text(mode.label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(mode.description, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent, size: 18) : null,
                    onTap: () {
                      setState(() {
                        _effects = _effects.copyWith(vocalIsolationMode: mode);
                      });
                      _applyChange();
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_effects.vocalIsolationMode == VocalIsolationMode.isolateVocals) ...[
          _buildSliderCard(
            title: 'Vocal Isolation Intensity',
            valueText: '${(_effects.vocalIsolationIntensity * 100).toInt()}%',
            color: AppColors.accent,
            value: _effects.vocalIsolationIntensity,
            min: 0.2,
            max: 1.0,
            onChanged: (v) {
              setState(() => _effects = _effects.copyWith(vocalIsolationIntensity: v));
              _applyChange();
            },
          ),
          const SizedBox(height: 12),
        ],

        // De-Esser Card
        _buildSliderCard(
          title: 'Sibilance De-Esser (4k - 8k Hz)',
          valueText: _effects.deEsserIntensity <= 0.01 ? 'OFF' : '${(_effects.deEsserIntensity * 100).toInt()}%',
          color: const Color(0xFF00E5FF),
          value: _effects.deEsserIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) {
            setState(() => _effects = _effects.copyWith(deEsserIntensity: v));
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // AI Noise Reduction
        _buildSliderCard(
          title: 'Background Noise Reduction (FFT)',
          valueText: '${(_effects.denoiseIntensity * 100).toInt()}% (-${(_effects.denoiseIntensity * 25).toStringAsFixed(1)}dB)',
          color: AppColors.primaryLight,
          value: _effects.denoiseIntensity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) {
            setState(() => _effects = _effects.copyWith(denoiseIntensity: v));
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // Speech Presence & Clarity
        _buildSliderCard(
          title: 'Speech Clarity & Presence (3.2kHz)',
          valueText: '${(_effects.voiceClarityGain * 100).toInt()}%',
          color: AppColors.accent,
          value: _effects.voiceClarityGain,
          min: 0.5,
          max: 2.0,
          onChanged: (v) {
            setState(() => _effects = _effects.copyWith(voiceClarityGain: v));
            _applyChange();
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: DUCKING & LEVELS TAB
  // ---------------------------------------------------------------------------
  Widget _buildDuckingLevelsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Master Volume
        _buildSliderCard(
          title: 'Master Clip Volume',
          valueText: '${(_volume * 100).toInt()}%',
          color: AppColors.primary,
          value: _volume,
          min: 0.0,
          max: 2.0,
          onChanged: (v) {
            setState(() => _volume = v);
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // Smart Auto-Ducking Card
        _buildCard(
          title: '🦆 Smart Sidechain Auto-Ducking',
          subtitle: 'Automatically lowers background volume during speech',
          badge: Switch(
            value: _effects.isDuckingEnabled,
            activeColor: AppColors.audioTrack,
            onChanged: (val) {
              setState(() => _effects = _effects.copyWith(isDuckingEnabled: val));
              _applyChange();
            },
          ),
          child: Column(
            children: [
              if (_effects.isDuckingEnabled) ...[
                const SizedBox(height: 4),
                _buildSliderCard(
                  title: 'Ducking Attenuation Depth',
                  valueText: '${(_effects.duckingAttenuation * 100).toInt()}% (${((1.0 - _effects.duckingAttenuation) * -20).toStringAsFixed(1)}dB)',
                  color: AppColors.audioTrack,
                  value: _effects.duckingAttenuation,
                  min: 0.05,
                  max: 0.60,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(duckingAttenuation: v));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSliderCard(
                        title: 'Attack Ramp',
                        valueText: '${_effects.duckingAttackMs} ms',
                        color: AppColors.accent,
                        value: _effects.duckingAttackMs.toDouble(),
                        min: 10.0,
                        max: 300.0,
                        onChanged: (v) {
                          setState(() => _effects = _effects.copyWith(duckingAttackMs: v.toInt()));
                          _applyChange();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSliderCard(
                        title: 'Release Ramp',
                        valueText: '${_effects.duckingReleaseMs} ms',
                        color: AppColors.accent,
                        value: _effects.duckingReleaseMs.toDouble(),
                        min: 50.0,
                        max: 1200.0,
                        onChanged: (v) {
                          setState(() => _effects = _effects.copyWith(duckingReleaseMs: v.toInt()));
                          _applyChange();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Fade Envelopes Card
        _buildCard(
          title: 'Fade Envelopes',
          subtitle: 'Smooth intro and outro volume crossfades',
          child: Column(
            children: [
              _buildSliderCard(
                title: 'Fade In Duration',
                valueText: '${(_effects.fadeInMs / 1000.0).toStringAsFixed(2)}s',
                color: AppColors.primaryLight,
                value: _effects.fadeInMs.toDouble(),
                min: 0.0,
                max: 3000.0,
                onChanged: (v) {
                  setState(() => _effects = _effects.copyWith(fadeInMs: v.toInt()));
                  _applyChange();
                },
              ),
              const SizedBox(height: 8),
              _buildSliderCard(
                title: 'Fade Out Duration',
                valueText: '${(_effects.fadeOutMs / 1000.0).toStringAsFixed(2)}s',
                color: AppColors.primaryLight,
                value: _effects.fadeOutMs.toDouble(),
                min: 0.0,
                max: 3000.0,
                onChanged: (v) {
                  setState(() => _effects = _effects.copyWith(fadeOutMs: v.toInt()));
                  _applyChange();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: VOICE FX & BOOSTER
  // ---------------------------------------------------------------------------
  Widget _buildVoiceFXTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Loud Voice Booster Card
        _buildCard(
          title: '🔥 Loud Voice Booster & Pre-Amp',
          subtitle: 'Dynamic compression & true-peak brickwall ceiling',
          badge: Switch(
            value: _effects.isLoudVoiceEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _effects = _effects.copyWith(isLoudVoiceEnabled: val));
              _applyChange();
            },
          ),
          child: Column(
            children: [
              if (_effects.isLoudVoiceEnabled) ...[
                const SizedBox(height: 4),
                _buildSliderCard(
                  title: 'Gain Multiplier',
                  valueText: '${(_effects.voiceBoost * 100).toInt()}% (+${((_effects.voiceBoost - 1.0) * 10).toStringAsFixed(1)}dB)',
                  color: AppColors.primary,
                  value: _effects.voiceBoost,
                  min: 1.0,
                  max: 2.5,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(voiceBoost: v));
                    _applyChange();
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Voice Character Presets
        _buildCard(
          title: '🎙️ Voice Character & Modulation Presets',
          subtitle: 'Transform timbre, formant, and harmonic depth',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VoiceModulationPreset.values.map((preset) {
                  final isSelected = _effects.modulationPreset == preset;
                  return ChoiceChip(
                    label: Text(preset.label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : AppColors.textSecondary),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _effects = _effects.copyWith(modulationPreset: preset);
                        });
                        _applyChange();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _effects.modulationPreset.description,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
              if (_effects.modulationPreset == VoiceModulationPreset.customPitch) ...[
                const SizedBox(height: 12),
                _buildSliderCard(
                  title: 'Custom Pitch Shift',
                  valueText: '${_effects.pitchShiftSemitones > 0 ? "+" : ""}${_effects.pitchShiftSemitones.toStringAsFixed(1)} st',
                  color: AppColors.accent,
                  value: _effects.pitchShiftSemitones,
                  min: -12.0,
                  max: 12.0,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(pitchShiftSemitones: v));
                    _applyChange();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE UI CARD & SLIDER HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String valueText,
    required Color color,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(valueText, style: AppTypography.timecode.copyWith(fontSize: 11, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: color,
              inactiveColor: AppColors.border,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
