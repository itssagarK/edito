import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/video_smoother_config.dart';
import '../../services/ai_video_smoother_service.dart';

class VideoSmootherSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const VideoSmootherSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoSmootherSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<VideoSmootherSheet> createState() => _VideoSmootherSheetState();
}

class _VideoSmootherSheetState extends State<VideoSmootherSheet> {
  late VideoSmootherConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.smoother;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      smoother: _config,
    );
    widget.onSave(updated);
  }

  void _applyPreset(SmootherPreset preset) {
    setState(() {
      switch (preset) {
        case SmootherPreset.gimbalSmooth:
          _config = _config.copyWith(
            preset: preset,
            isStabilizationEnabled: true,
            stabilizationStrength: 0.85,
            isMotionSmoothingEnabled: true,
            targetFps: 60,
            isDeGlitchEnabled: true,
            isDeFlickerEnabled: false,
          );
          break;
        case SmootherPreset.motion60fps:
          _config = _config.copyWith(
            preset: preset,
            isStabilizationEnabled: false,
            isMotionSmoothingEnabled: true,
            targetFps: 60,
            isDeGlitchEnabled: true,
            isDeFlickerEnabled: false,
          );
          break;
        case SmootherPreset.antiGlitch:
          _config = _config.copyWith(
            preset: preset,
            isStabilizationEnabled: false,
            isMotionSmoothingEnabled: false,
            isDeGlitchEnabled: true,
            isDeFlickerEnabled: true,
          );
          break;
        case SmootherPreset.extremeAction:
          _config = _config.copyWith(
            preset: preset,
            isStabilizationEnabled: true,
            stabilizationStrength: 1.0,
            isMotionSmoothingEnabled: true,
            targetFps: 60,
            isDeGlitchEnabled: true,
            isDeFlickerEnabled: true,
          );
          break;
        case SmootherPreset.standard:
          _config = _config.copyWith(
            preset: preset,
            isStabilizationEnabled: false,
            stabilizationStrength: 0.75,
            isMotionSmoothingEnabled: false,
            targetFps: 60,
            isDeGlitchEnabled: false,
            isDeFlickerEnabled: false,
          );
          break;
      }
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = AIVideoSmootherService.getSmootherBadge(_config);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                        const Icon(Icons.waves, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Video Smoother & Anti-Flutter', style: AppTypography.titleLarge),
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
                // 1. Gimbal Stabilization Card
                _buildCard(
                  title: '🛡️ AI Camera Stabilizer',
                  subtitle: 'Cancels handheld shake and walking bounce like a 3-axis gimbal',
                  badge: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _config.isStabilizationEnabled ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _config.isStabilizationEnabled ? AppColors.accent : AppColors.border),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _config.isStabilizationEnabled ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable Anti-Shake Stabilization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Cancels jitter and smooths erratic motion vectors', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _config.isStabilizationEnabled,
                        activeColor: AppColors.accent,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isStabilizationEnabled: val));
                          _applyChange();
                        },
                      ),
                      if (_config.isStabilizationEnabled) ...[
                        const Divider(color: AppColors.border, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stabilization Strength', style: TextStyle(fontSize: 13)),
                            Text('${(_config.stabilizationStrength * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
                          ],
                        ),
                        Slider(
                          value: _config.stabilizationStrength,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          activeColor: AppColors.accent,
                          inactiveColor: AppColors.surfaceElevated,
                          onChanged: (val) {
                            setState(() => _config = _config.copyWith(stabilizationStrength: val));
                            _applyChange();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Optical Flow Motion Smoothing Card
                _buildCard(
                  title: '⚡ Fluid Motion & Frame Interpolation',
                  subtitle: 'Generates intermediate frames for butter-smooth movement',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('60 FPS Optical Flow Smoothing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Eliminates motion judder and cadence flutter', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _config.isMotionSmoothingEnabled,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isMotionSmoothingEnabled: val));
                          _applyChange();
                        },
                      ),
                      if (_config.isMotionSmoothingEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Target Output Framerate', style: TextStyle(fontSize: 13)),
                            Row(
                              children: [30, 60, 120].map((fps) {
                                final isSelected = _config.targetFps == fps;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text('${fps}fps', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: AppColors.surface,
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _config = _config.copyWith(targetFps: fps));
                                        _applyChange();
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Glitch & Flicker Elimination Card
                _buildCard(
                  title: '🧹 Anti-Glitch & Flicker Removal',
                  subtitle: 'Fixes video drops, micro-stutters, and rolling shutter flicker',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('De-Glitch & Frame Cadence Fix', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Removes duplicate frozen frames and forces steady frame pacing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _config.isDeGlitchEnabled,
                        activeColor: AppColors.primaryLight,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isDeGlitchEnabled: val));
                          _applyChange();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Anti-Flicker Filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Suppresses LED lights and sensor shutter luminance flutter', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _config.isDeFlickerEnabled,
                        activeColor: AppColors.accentWarm,
                        onChanged: (val) {
                          setState(() => _config = _config.copyWith(isDeFlickerEnabled: val));
                          _applyChange();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Presets Card
                _buildCard(
                  title: '✨ Smoother Presets',
                  subtitle: 'One-tap optimization for action, cinema, and handheld clips',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: SmootherPreset.values.map((preset) {
                          final isSelected = _config.preset == preset;
                          return ChoiceChip(
                            label: Text(preset.label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            selected: isSelected,
                            selectedColor: AppColors.accent,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                            onSelected: (selected) {
                              if (selected) {
                                _applyPreset(preset);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _config.preset.description,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.labelSmall),
                  ],
                ),
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
