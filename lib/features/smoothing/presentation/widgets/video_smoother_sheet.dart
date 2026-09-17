import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/video_smoother_config.dart';
import '../../services/ai_video_smoother_service.dart';

class VideoSmootherSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const VideoSmootherSheet({
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
      builder: (context) => VideoSmootherSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<VideoSmootherSheet> createState() => _VideoSmootherSheetState();
}

class _VideoSmootherSheetState extends State<VideoSmootherSheet> with SingleTickerProviderStateMixin {
  late VideoSmootherConfig _config;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.smoother;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(
      smoother: _config,
    );
    widget.onSave(updated);
  }

  void _applyPreset(SmootherPreset preset) {
    setState(() {
      _config = VideoSmootherConfig.getPresetConfig(preset);
    });
    _applyChange();
  }

  void _resetAll() {
    setState(() {
      _config = const VideoSmootherConfig();
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = AIVideoSmootherService.getSmootherBadge(_config);
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.58;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.waves, color: AppColors.accent, size: 22),
                          const SizedBox(width: 8),
                          Text('Optical Flow & Motion Blur', style: AppTypography.titleLarge),
                        ],
                      ),
                      Row(
                        children: [
                          if (_config.hasActiveSmoothing)
                            TextButton(
                              onPressed: _resetAll,
                              child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                            onPressed: () {
                              if (widget.onDone != null) {
                                widget.onDone!();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Presets Carousel
          Container(
            height: 38,
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: SmootherPreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = SmootherPreset.values[index];
                final isSelected = _config.preset == preset;
                return ChoiceChip(
                  label: Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                  onSelected: (selected) {
                    if (selected) _applyPreset(preset);
                  },
                );
              },
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome_motion, size: 14), text: 'Flow & Interpolation'),
                Tab(icon: Icon(Icons.blur_linear, size: 14), text: 'Velocity Motion Blur'),
                Tab(icon: Icon(Icons.security, size: 14), text: 'Stabilizer & Glitch'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFlowTab(),
                _buildMotionBlurTab(),
                _buildStabilizerTab(badgeLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: OPTICAL FLOW & FRAME INTERPOLATION ---
  Widget _buildFlowTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildCard(
          title: '⚡ Frame Interpolation Engine',
          subtitle: 'Select algorithm for temporal motion smoothing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MotionInterpolationMode.values.map((mode) {
                  final isSelected = _config.effectiveInterpolationMode == mode;
                  return ChoiceChip(
                    label: Text(
                      mode.label,
                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _config = _config.copyWith(
                            interpolationMode: mode,
                            isMotionSmoothingEnabled: mode == MotionInterpolationMode.opticalFlow,
                          );
                        });
                        _applyChange();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                _config.effectiveInterpolationMode.description,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        if (_config.effectiveInterpolationMode != MotionInterpolationMode.none)
          _buildCard(
            title: '🎯 Target Output Framerate',
            subtitle: 'Higher FPS synthesizes more in-between frames for ultra-smooth playback',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Framerate Target', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Row(
                  children: [30, 60, 120, 240].map((fps) {
                    final isSelected = _config.targetFps == fps;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(
                          '${fps}fps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
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
          ),
      ],
    );
  }

  // --- TAB 2: VELOCITY MOTION BLUR ---
  Widget _buildMotionBlurTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildCard(
          title: '🌪️ Velocity Shutter Angle Motion Blur',
          subtitle: 'Simulates physical film camera rotary shutter angle',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Motion Blur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Synthesizes temporal exposure trails on moving objects', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                value: _config.isMotionBlurEnabled,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(isMotionBlurEnabled: val));
                  _applyChange();
                },
              ),
              if (_config.isMotionBlurEnabled) ...[
                const Divider(color: AppColors.border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shutter Angle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      '${_config.shutterAngle.toInt()}° ${_getShutterLabel(_config.shutterAngle)}',
                      style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _config.shutterAngle,
                  min: 0.0,
                  max: 360.0,
                  divisions: 36,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surface,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(shutterAngle: val));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Blur Intensity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      '${(_config.motionBlurIntensity * 100).toInt()}%',
                      style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _config.motionBlurIntensity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surface,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(motionBlurIntensity: val));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sub-Frame Samples', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      '${_config.motionBlurSamples} samples',
                      style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.primaryLight),
                    ),
                  ],
                ),
                Slider(
                  value: _config.motionBlurSamples.toDouble(),
                  min: 2.0,
                  max: 16.0,
                  divisions: 14,
                  activeColor: AppColors.primaryLight,
                  inactiveColor: AppColors.surface,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(motionBlurSamples: val.toInt()));
                    _applyChange();
                  },
                ),
                const Divider(color: AppColors.border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Blur Direction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Wrap(
                      spacing: 6,
                      children: MotionBlurDirection.values.map((dir) {
                        final isSelected = _config.motionBlurDirection == dir;
                        return ChoiceChip(
                          label: Text(
                            dir.label,
                            style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _config = _config.copyWith(motionBlurDirection: dir));
                              _applyChange();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: STABILIZER & GLITCH ---
  Widget _buildStabilizerTab(String badgeLabel) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
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
              badgeLabel.isNotEmpty ? badgeLabel : 'INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _config.isStabilizationEnabled ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anti-Shake Stabilization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                  inactiveColor: AppColors.surface,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(stabilizationStrength: val));
                    _applyChange();
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildCard(
          title: '🧹 Anti-Glitch & Flicker Removal',
          subtitle: 'Fixes video drops, micro-stutters, and rolling shutter flutter',
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
      ],
    );
  }

  String _getShutterLabel(double angle) {
    if (angle <= 90) return '(Action Crisp)';
    if (angle <= 180) return '(Hollywood Cinema)';
    if (angle <= 270) return '(Dreamy Motion)';
    return '(Velocity Streak)';
  }

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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
