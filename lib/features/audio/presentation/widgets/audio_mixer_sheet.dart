import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/audio_effects_config.dart';
import '../../services/ai_voice_enhancer_service.dart';
import 'acoustic_space_visualizer.dart';
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
    _tabController = TabController(length: 5, vsync: this);
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

  void _applyReverbPreset(RoomReverbPreset preset) {
    setState(() {
      _effects = AudioEffectsConfig.getReverbPreset(preset, base: _effects);
    });
    _applyChange();
  }

  void _applyDeHumMode(DeHumMode mode) {
    setState(() {
      _effects = AudioEffectsConfig.getDeHumConfig(mode, base: _effects);
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.62;
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

          // Studio Navigation Tabs (5 Tabs)
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
                Tab(text: '🧹 Restore'),
                Tab(text: '🏛️ Acoustic'),
                Tab(text: '🎙️ Vocal'),
                Tab(text: '🦆 Dynamics'),
              ],
            ),
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEQTab(),
                _buildRestoreTab(),
                _buildAcousticTab(),
                _buildVocalStudioTab(),
                _buildDynamicsTab(),
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
                Text('Low Shelf, Mid Bell & High Shelf tone shaping', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
        const SizedBox(height: 8),

        // Live Equalizer Curve Skia Plotter
        ParametricEqCurveWidget(config: _effects),
        const SizedBox(height: 10),

        // Preset Carousel
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: EqualizerPreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final preset = EqualizerPreset.values[idx];
              final isSelected = _effects.isEqualizerEnabled && _effects.equalizerPreset == preset;
              return ChoiceChip(
                label: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surfaceElevated,
                onSelected: (_) => _applyEqualizerPreset(preset),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Band 1: Low Shelf
        _buildSliderCard(
          title: 'Low Shelf (Bass Resonance)',
          valueText: '${_effects.eqLowGain > 0 ? "+" : ""}${_effects.eqLowGain.toStringAsFixed(1)} dB @ ${_effects.eqLowFreq.toInt()} Hz',
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

        // Band 2: Mid Bell
        _buildSliderCard(
          title: 'Mid Bell (Speech Presence)',
          valueText: '${_effects.eqMidGain > 0 ? "+" : ""}${_effects.eqMidGain.toStringAsFixed(1)} dB @ ${_effects.eqMidFreq.toInt()} Hz (Q: ${_effects.eqMidQ.toStringAsFixed(1)})',
          color: AppColors.primary,
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

        // Band 3: High Shelf
        _buildSliderCard(
          title: 'High Shelf (Treble Air & Crisp)',
          valueText: '${_effects.eqHighGain > 0 ? "+" : ""}${_effects.eqHighGain.toStringAsFixed(1)} dB @ ${_effects.eqHighFreq.toInt()} Hz',
          color: AppColors.accent,
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
  // TAB 2: AUDIO RESTORATION (DE-HUM, DE-ESSER, WIND/PLOSIVE GUARD)
  // ---------------------------------------------------------------------------
  Widget _buildRestoreTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Powerline Ground De-Hum Card
        _buildCard(
          title: '⚡ Powerline Ground Hum Remover',
          subtitle: 'Eliminates 50Hz/60Hz ground loop hums and electrical harmonics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: DeHumMode.values.map((mode) {
                  final isSelected = _effects.deHumMode == mode;
                  return ChoiceChip(
                    label: Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => _applyDeHumMode(mode),
                  );
                }).toList(),
              ),
              if (_effects.deHumMode != DeHumMode.off) ...[
                const SizedBox(height: 10),
                _buildSliderCard(
                  title: 'Hum Attenuation Depth',
                  valueText: '${_effects.deHumGain.toStringAsFixed(1)} dB',
                  color: AppColors.accent,
                  value: _effects.deHumGain,
                  min: -48.0,
                  max: -12.0,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(deHumGain: v));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Harmonic Notches: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ...[1, 2, 3, 4].map((h) {
                      final isSel = _effects.deHumHarmonics == h;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${h}x (${(_effects.deHumMode.defaultFrequency * h).toInt()}Hz)', style: TextStyle(fontSize: 9, color: isSel ? Colors.black : Colors.white)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onSelected: (_) {
                            setState(() => _effects = _effects.copyWith(deHumHarmonics: h));
                            _applyChange();
                          },
                        ),
                      );
                    }),
                  ],
                ),
                if (_effects.deHumMode == DeHumMode.custom) ...[
                  const SizedBox(height: 6),
                  _buildSliderCard(
                    title: 'Custom Base Frequency',
                    valueText: '${_effects.customHumFreq.toInt()} Hz',
                    color: AppColors.primaryLight,
                    value: _effects.customHumFreq,
                    min: 40.0,
                    max: 120.0,
                    onChanged: (v) {
                      setState(() => _effects = _effects.copyWith(customHumFreq: v));
                      _applyChange();
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Targeted Frequency Sibilance De-Esser
        _buildCard(
          title: '🎙️ Multi-Band Vocal De-Esser',
          subtitle: 'Smooths harsh sibilance ("s", "sh", "ch") and condenser splash',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: DeEsserMode.values.map((mode) {
                  final isSelected = _effects.deEsserMode == mode;
                  return ChoiceChip(
                    label: Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00E5FF),
                    backgroundColor: AppColors.surface,
                    onSelected: (_) {
                      setState(() {
                        _effects = _effects.copyWith(
                          deEsserMode: mode,
                          deEsserIntensity: mode == DeEsserMode.off ? 0.0 : (_effects.deEsserIntensity > 0 ? _effects.deEsserIntensity : 0.65),
                          deEsserFrequency: mode.targetFrequency,
                        );
                      });
                      _applyChange();
                    },
                  );
                }).toList(),
              ),
              if (_effects.deEsserMode != DeEsserMode.off) ...[
                const SizedBox(height: 10),
                _buildSliderCard(
                  title: 'De-Esser Reduction Intensity',
                  valueText: '${(_effects.deEsserIntensity * 100).toInt()}%',
                  color: const Color(0xFF00E5FF),
                  value: _effects.deEsserIntensity > 0 ? _effects.deEsserIntensity : 0.65,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(deEsserIntensity: v));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 6),
                _buildSliderCard(
                  title: 'Center Sibilance Frequency',
                  valueText: '${(_effects.deEsserFrequency / 1000).toStringAsFixed(1)} kHz',
                  color: AppColors.primary,
                  value: _effects.deEsserFrequency,
                  min: 3000.0,
                  max: 10000.0,
                  onChanged: (v) {
                    setState(() => _effects = _effects.copyWith(deEsserFrequency: v));
                    _applyChange();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Wind & Mic Plosive Guard
        _buildCard(
          title: '🌬️ Wind & Mic Plosive Guard',
          subtitle: 'Cancels aggressive microphone pop thumps ("p", "b") & wind turbulence',
          badge: Switch(
            value: _effects.isWindDePlosiveEnabled,
            activeColor: AppColors.accent,
            onChanged: (val) {
              setState(() => _effects = _effects.copyWith(isWindDePlosiveEnabled: val));
              _applyChange();
            },
          ),
          child: _effects.isWindDePlosiveEnabled
              ? Column(
                  children: [
                    const SizedBox(height: 4),
                    _buildSliderCard(
                      title: 'Guard Attenuation Depth',
                      valueText: '${(_effects.dePlosiveIntensity * 100).toInt()}%',
                      color: AppColors.accent,
                      value: _effects.dePlosiveIntensity,
                      min: 0.2,
                      max: 1.0,
                      onChanged: (v) {
                        setState(() => _effects = _effects.copyWith(dePlosiveIntensity: v));
                        _applyChange();
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: STUDIO ROOM REVERB & ACOUSTIC SIMULATION
  // ---------------------------------------------------------------------------
  Widget _buildAcousticTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Studio Room Reverb (Freeverb)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Natural spatial reflections & acoustic space modeling', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            Switch(
              value: _effects.isReverbEnabled && _effects.reverbPreset != RoomReverbPreset.none,
              activeColor: AppColors.accent,
              onChanged: (val) {
                if (val) {
                  _applyReverbPreset(_effects.reverbPreset != RoomReverbPreset.none ? _effects.reverbPreset : RoomReverbPreset.intimateRoom);
                } else {
                  _applyReverbPreset(RoomReverbPreset.none);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Live 3D Acoustic Space Wireframe Visualizer
        AcousticSpaceVisualizer(config: _effects),
        const SizedBox(height: 10),

        // Reverb Presets Carousel
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: RoomReverbPreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final preset = RoomReverbPreset.values[idx];
              final isSelected = _effects.isReverbEnabled && _effects.reverbPreset == preset;
              return ChoiceChip(
                label: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surfaceElevated,
                onSelected: (_) => _applyReverbPreset(preset),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Acoustic Geometry Sliders
        _buildSliderCard(
          title: 'Virtual Room Size',
          valueText: '${(_effects.reverbRoomSize * 100).toInt()}%',
          color: AppColors.accent,
          value: _effects.reverbRoomSize,
          min: 0.05,
          max: 1.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isReverbEnabled: true,
                reverbPreset: RoomReverbPreset.custom,
                reverbRoomSize: v,
              );
            });
            _applyChange();
          },
        ),
        const SizedBox(height: 8),

        _buildSliderCard(
          title: 'High-Frequency Damping',
          valueText: '${(_effects.reverbDamping * 100).toInt()}%',
          color: AppColors.primaryLight,
          value: _effects.reverbDamping,
          min: 0.0,
          max: 1.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isReverbEnabled: true,
                reverbPreset: RoomReverbPreset.custom,
                reverbDamping: v,
              );
            });
            _applyChange();
          },
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _buildSliderCard(
                title: 'Wet Mix (Reverb)',
                valueText: '${(_effects.reverbWetGain * 100).toInt()}%',
                color: const Color(0xFF00E5FF),
                value: _effects.reverbWetGain,
                min: 0.0,
                max: 0.50,
                onChanged: (v) {
                  setState(() {
                    _effects = _effects.copyWith(
                      isReverbEnabled: true,
                      reverbPreset: RoomReverbPreset.custom,
                      reverbWetGain: v,
                    );
                  });
                  _applyChange();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSliderCard(
                title: 'Dry Mix (Direct)',
                valueText: '${(_effects.reverbDryGain * 100).toInt()}%',
                color: Colors.white70,
                value: _effects.reverbDryGain,
                min: 0.40,
                max: 1.0,
                onChanged: (v) {
                  setState(() {
                    _effects = _effects.copyWith(
                      isReverbEnabled: true,
                      reverbPreset: RoomReverbPreset.custom,
                      reverbDryGain: v,
                    );
                  });
                  _applyChange();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildSliderCard(
          title: 'Stereo Spatial Width',
          valueText: '${(_effects.reverbWidth * 100).toInt()}%',
          color: Colors.deepPurpleAccent,
          value: _effects.reverbWidth,
          min: 0.2,
          max: 1.0,
          onChanged: (v) {
            setState(() {
              _effects = _effects.copyWith(
                isReverbEnabled: true,
                reverbPreset: RoomReverbPreset.custom,
                reverbWidth: v,
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
  // TAB 4: VOCAL ISOLATION & DE-NOISE STUDIO
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
  // TAB 5: DYNAMICS, DUCKING & VOICE MODULATION FX
  // ---------------------------------------------------------------------------
  Widget _buildDynamicsTab() {
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
                  title: 'Pre-Amp Boost Gain',
                  valueText: '${(_effects.voiceBoost * 100).toInt()}% (+${((_effects.voiceBoost - 1.0) * 10.0).toStringAsFixed(1)}dB)',
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

        // Voice Modulation Presets
        _buildCard(
          title: '🎭 Voice Modulation & Character FX',
          subtitle: 'Stylize voice pitch, formants & robot/broadcast tone',
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: VoiceModulationPreset.values.map((preset) {
                  final isSelected = _effects.modulationPreset == preset;
                  return ChoiceChip(
                    label: Text(
                      preset.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) {
                      setState(() {
                        _effects = _effects.copyWith(
                          modulationPreset: preset,
                          pitchShiftSemitones: preset == VoiceModulationPreset.deepNarrator
                              ? -4.0
                              : (preset == VoiceModulationPreset.crystalClear ? 2.0 : 0.0),
                        );
                      });
                      _applyChange();
                    },
                  );
                }).toList(),
              ),
              if (_effects.modulationPreset == VoiceModulationPreset.customPitch) ...[
                const SizedBox(height: 10),
                _buildSliderCard(
                  title: 'Pitch Shift (Semitones)',
                  valueText: '${_effects.pitchShiftSemitones > 0 ? "+" : ""}${_effects.pitchShiftSemitones.toStringAsFixed(1)} st',
                  color: Colors.orangeAccent,
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
  // SHARED UI HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildCard({
    required String title,
    required String subtitle,
    Widget? badge,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              Text(valueText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
