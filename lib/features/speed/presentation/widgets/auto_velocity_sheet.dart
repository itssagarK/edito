import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../models/auto_velocity_config.dart';
import '../services/auto_velocity_service.dart';

class AutoVelocitySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const AutoVelocitySheet({
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
      barrierColor: Colors.black.withOpacity(0.15),
      backgroundColor: Colors.transparent,
      builder: (context) => AutoVelocitySheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<AutoVelocitySheet> createState() => _AutoVelocitySheetState();
}

class _AutoVelocitySheetState extends State<AutoVelocitySheet> {
  late AutoVelocityConfig _config;
  int _activeTab = 0; // 0: Styles & Rhythm, 1: Speed Dynamics, 2: Micro-Effects
  double _manualBpm = 120.0;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.autoVelocity;
    _manualBpm = widget.clip.beatConfig.bpm > 0 ? widget.clip.beatConfig.bpm : 120.0;
  }

  void _applyAndSave() {
    final newCurve = AutoVelocityService.generateVelocityCurve(
      widget.clip,
      _config,
      fallbackBpm: _manualBpm,
    );

    final updatedClip = widget.clip.copyWith(
      autoVelocity: _config,
      speedCurve: _config.isEnabled ? newCurve : widget.clip.speedCurve,
    );

    widget.onSave(updatedClip);
  }

  void _applyPreset(AutoVelocityConfig preset) {
    setState(() {
      _config = preset;
    });
    _applyAndSave();
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
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildTabs(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildTabContent(),
            ),
          ),
          _buildBottomAction(),
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
    final badge = AutoVelocityService.getBadge(_config);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF5252)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flash_on, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Auto-Velocity Studio',
                  style: AppTypography.titleMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  badge.isNotEmpty ? badge : 'Rhythm-synced explosive speed surges & micro-zooms',
                  style: AppTypography.caption.copyWith(
                    color: _config.isEnabled ? const Color(0xFFFFD700) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFFFFD700),
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(isEnabled: val);
              });
              _applyAndSave();
            },
          ),
          if (widget.onDone != null)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Color(0xFFFFD700)),
              style: IconButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: widget.onDone,
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Styles & Rhythm', 'Speed Bursts', 'Micro-Effects'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight.withOpacity(0.1))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _activeTab == index;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                style: AppTypography.caption.copyWith(
                  color: isSelected ? const Color(0xFFFFD700) : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildStylesTab();
      case 1:
        return _buildDynamicsTab();
      case 2:
        return _buildEffectsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStylesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAPCUT PRO VELOCITY PRESETS', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip('⚡ Classic Velocity', AutoVelocityConfig.presetClassic),
            _buildPresetChip('💥 Phonk / Trap Rush', AutoVelocityConfig.presetPhonkTrap),
            _buildPresetChip('🌊 Hyper-Drift', AutoVelocityConfig.presetHyperDrift),
            _buildPresetChip('🥁 Stutter BPM', AutoVelocityConfig.presetStutterBpm),
            _buildPresetChip('☕ Lofi Chill', AutoVelocityConfig.presetLofiChill),
          ],
        ),
        const SizedBox(height: 16),
        Text('RHYTHMIC BEAT INTERVAL', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Row(
          children: VelocityInterval.values.map((interval) {
            final isSelected = _config.interval == interval;
            final label = () {
              switch (interval) {
                case VelocityInterval.everyBeat:
                  return 'Every Beat (1/1)';
                case VelocityInterval.halfBeat:
                  return 'Half Beat (1/2)';
                case VelocityInterval.doubleBeat:
                  return 'Double Beat (2/1)';
              }
            }();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFFFFD700).withOpacity(0.25),
                backgroundColor: AppColors.surface,
                onSelected: (_) {
                  setState(() => _config = _config.copyWith(interval: interval, isEnabled: true));
                  _applyAndSave();
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grid BPM Tempo', style: AppTypography.caption),
                  Text('${_manualBpm.toInt()} BPM', style: AppTypography.caption.copyWith(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFFD700),
                  inactiveTrackColor: AppColors.surfaceHighlight.withOpacity(0.3),
                  thumbColor: const Color(0xFFFFD700),
                ),
                child: Slider(
                  value: _manualBpm.clamp(60.0, 180.0),
                  min: 60.0,
                  max: 180.0,
                  divisions: 24,
                  onChanged: (val) {
                    setState(() => _manualBpm = val);
                    _applyAndSave();
                  },
                ),
              ),
              Text(
                widget.clip.beatConfig.hasBeats
                    ? '✓ Using ${widget.clip.beatConfig.beatTimestampsMs.length} analyzed audio beat markers.'
                    : 'ℹ️ Synchronizing to mathematical rhythmic grid at ${_manualBpm.toInt()} BPM.',
                style: AppTypography.caption.copyWith(
                  color: widget.clip.beatConfig.hasBeats ? const Color(0xFF00FF66) : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, AutoVelocityConfig preset) {
    return ActionChip(
      backgroundColor: AppColors.surface,
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.surfaceHighlight.withOpacity(0.3)),
      ),
      onPressed: () => _applyPreset(preset),
    );
  }

  Widget _buildDynamicsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(
          title: 'Slow-Mo Buildup Speed',
          value: _config.slowSpeed,
          min: 0.1,
          max: 0.9,
          divisions: 16,
          label: '${_config.slowSpeed.toStringAsFixed(2)}x',
          onChanged: (val) {
            setState(() => _config = _config.copyWith(slowSpeed: val, isEnabled: true));
            _applyAndSave();
          },
        ),
        _buildSlider(
          title: 'Peak Acceleration Burst Speed',
          value: _config.fastSpeed,
          min: 1.5,
          max: 8.0,
          divisions: 26,
          label: '${_config.fastSpeed.toStringAsFixed(1)}x',
          onChanged: (val) {
            setState(() => _config = _config.copyWith(fastSpeed: val, isEnabled: true));
            _applyAndSave();
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Optical Flow Smooth Slow-Mo', style: AppTypography.bodyMedium),
                    Text('AI motion frame interpolation (minterpolate) for jitterless slow motion', style: AppTypography.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              Switch(
                value: _config.enableSmoothSlowMo,
                activeColor: const Color(0xFFFFD700),
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(enableSmoothSlowMo: val, isEnabled: true));
                  _applyAndSave();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('White Flash Exposure Pulse', style: AppTypography.bodyMedium),
                  Switch(
                    value: _config.enableFlashPulse,
                    activeColor: const Color(0xFFFFD700),
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(enableFlashPulse: val, isEnabled: true));
                      _applyAndSave();
                    },
                  ),
                ],
              ),
              if (_config.enableFlashPulse) ...[
                const Divider(color: Colors.white12),
                _buildSlider(
                  title: 'Flash Burst Intensity',
                  value: _config.flashIntensity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  label: '${(_config.flashIntensity * 100).toInt()}%',
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(flashIntensity: val));
                    _applyAndSave();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Camera Micro-Zoom Punch-In', style: AppTypography.bodyMedium),
                  Switch(
                    value: _config.enableMicroZoom,
                    activeColor: const Color(0xFFFFD700),
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(enableMicroZoom: val, isEnabled: true));
                      _applyAndSave();
                    },
                  ),
                ],
              ),
              if (_config.enableMicroZoom) ...[
                const Divider(color: Colors.white12),
                _buildSlider(
                  title: 'Micro-Zoom Punch Scale',
                  value: _config.microZoomFactor,
                  min: 1.02,
                  max: 1.25,
                  divisions: 23,
                  label: '${_config.microZoomFactor.toStringAsFixed(2)}x',
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(microZoomFactor: val));
                    _applyAndSave();
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chromatic RGB Aberration Peak', style: AppTypography.bodyMedium),
              Switch(
                value: _config.enableRgbGlitch,
                activeColor: const Color(0xFFFFD700),
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(enableRgbGlitch: val, isEnabled: true));
                  _applyAndSave();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.auto_awesome, color: Colors.black),
        label: const Text(
          'Re-Calculate & Apply Velocity Ramp',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          setState(() => _config = _config.copyWith(isEnabled: true));
          _applyAndSave();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ Auto-Velocity rhythm curve compiled and applied!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.caption),
            Text(label, style: AppTypography.caption.copyWith(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFFD700),
            inactiveTrackColor: AppColors.surfaceHighlight.withOpacity(0.3),
            thumbColor: const Color(0xFFFFD700),
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
