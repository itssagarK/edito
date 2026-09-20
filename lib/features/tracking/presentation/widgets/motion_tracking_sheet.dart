import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../models/motion_tracking_config.dart';
import '../../services/motion_tracking_service.dart';

/// CapCut Pro Smart Motion Tracking Studio Sheet
class MotionTrackingSheet extends StatefulWidget {
  final Project project;
  final Clip targetClip;
  final Function(Project updatedProject) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const MotionTrackingSheet({
    super.key,
    required this.project,
    required this.targetClip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Clip targetClip,
    required Function(Project) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MotionTrackingSheet(
        project: project,
        targetClip: targetClip,
        onSave: onSave,
      ),
    );
  }

  @override
  State<MotionTrackingSheet> createState() => _MotionTrackingSheetState();
}

class _MotionTrackingSheetState extends State<MotionTrackingSheet> {
  late MotionTrackingConfig _config;
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String? _selectedPinnedId;

  @override
  void initState() {
    super.initState();
    _config = widget.targetClip.motionTracking;
    _selectedPinnedId = _config.pinnedOverlayId;

    // If no pinned overlay selected, default to the first available text/overlay clip if any
    if (_selectedPinnedId == null) {
      final availableOverlays = _getAvailableOverlayClips();
      if (availableOverlays.isNotEmpty) {
        _selectedPinnedId = availableOverlays.first.id;
      }
    }
  }

  List<Clip> _getAvailableOverlayClips() {
    final overlays = <Clip>[];
    for (final t in widget.project.tracks) {
      if (t.id == widget.targetClip.trackId) continue;
      for (final c in t.clips) {
        if (c.textOverlay.text.trim().isNotEmpty || c.imageOverlay.isEnabled) {
          overlays.add(c);
        }
      }
    }
    return overlays;
  }

  void _runTrackingAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.1;
    });

    await Future.delayed(const Duration(milliseconds: 180));
    setState(() => _analysisProgress = 0.45);

    await Future.delayed(const Duration(milliseconds: 180));
    setState(() => _analysisProgress = 0.85);

    // Solve trajectory
    final trajectory = MotionTrackingService.generateTrajectory(
      totalDurationMs: widget.targetClip.durationMs,
      targetType: _config.targetType,
      startX: _config.reticleX,
      startY: _config.reticleY,
      smoothingFactor: _config.smoothingFactor,
    );

    setState(() {
      _analysisProgress = 1.0;
      _isAnalyzing = false;
      _config = _config.copyWith(
        isEnabled: true,
        trajectory: trajectory,
        pinnedOverlayId: _selectedPinnedId,
      );
    });

    _applyAndSave();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Motion tracking completed! Solved ${trajectory.length} trajectory points.'),
          backgroundColor: const Color(0xFF00FF66),
        ),
      );
    }
  }

  void _bakeToKeyframes() {
    if (!_config.isEnabled || _config.trajectory.isEmpty || _selectedPinnedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please analyze and track a subject first!')),
      );
      return;
    }

    final keyframes = MotionTrackingService.convertTrajectoryToKeyframes(_config);

    // Apply keyframes to the pinned overlay clip
    var updatedProject = widget.project;
    final updatedTracks = updatedProject.tracks.map((track) {
      final updatedClips = track.clips.map((clip) {
        if (clip.id == _selectedPinnedId) {
          return clip.copyWith(keyframes: keyframes);
        }
        return clip;
      }).toList();
      return track.copyWith(clips: updatedClips);
    }).toList();

    updatedProject = updatedProject.copyWith(tracks: updatedTracks);
    widget.onSave(updatedProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Baked ${keyframes.length} motion keyframes to overlay timeline!'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _applyAndSave() {
    final updatedClip = widget.targetClip.copyWith(motionTracking: _config);

    // Update project
    final updatedTracks = widget.project.tracks.map((track) {
      final updatedClips = track.clips.map((clip) {
        return clip.id == updatedClip.id ? updatedClip : clip;
      }).toList();
      return track.copyWith(clips: updatedClips);
    }).toList();

    widget.onSave(widget.project.copyWith(tracks: updatedTracks));
  }

  @override
  Widget build(BuildContext context) {
    final availableOverlays = _getAvailableOverlayClips();

    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? null : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            // Header Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Motion Tracking',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _config.isEnabled ? 'Active (${_config.trajectory.length} pts)' : 'Select subject to pin overlays',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Switch(
                      value: _config.isEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(isEnabled: val);
                        });
                        _applyAndSave();
                      },
                    ),
                    if (widget.onDone != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                        icon: const Icon(Icons.check, color: AppColors.accent, size: 18),
                        onPressed: widget.onDone,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Main Controls Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // 1. Target Overlay Selector
                const Text(
                  'PINNED OVERLAY ITEM',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                if (availableOverlays.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'No text titles or stickers found on timeline. Add a text overlay to pin to this tracked motion.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  )
                else
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableOverlays.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final ov = availableOverlays[idx];
                        final isSel = _selectedPinnedId == ov.id;
                        final label = ov.textOverlay.text.trim().isNotEmpty
                            ? '💬 "${ov.textOverlay.text}"'
                            : '🖼️ Sticker';

                        return ChoiceChip(
                          label: Text(label, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.black : Colors.white,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedPinnedId = ov.id;
                              _config = _config.copyWith(pinnedOverlayId: ov.id);
                            });
                            _applyAndSave();
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 14),

                // 2. Target Subject Type
                const Text(
                  'TRACKING SUBJECT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TrackingTargetType.values.map((type) {
                    final isSel = _config.targetType == type;
                    return ChoiceChip(
                      label: Text('${type.icon} ${type.label}', style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _config = _config.copyWith(targetType: type);
                        });
                        _applyAndSave();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 3. Tracking Mode
                const Text(
                  'MOTION DYNAMICS MODE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TrackingMode.values.map((mode) {
                    final isSel = _config.mode == mode;
                    return ChoiceChip(
                      label: Text(mode.label, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _config = _config.copyWith(mode: mode);
                        });
                        _applyAndSave();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 4. Anchor Placement
                const Text(
                  'ANCHOR PLACEMENT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TrackingAnchor.values.map((anchor) {
                    final isSel = _config.anchor == anchor;
                    return ChoiceChip(
                      label: Text(anchor.label, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _config = _config.copyWith(anchor: anchor);
                        });
                        _applyAndSave();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 5. Smoothing Factor Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MOTION SMOOTHING: ${(_config.smoothingFactor * 100).round()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    Text(
                      _config.smoothingFactor < 0.25 ? 'Responsive' : 'Cinematic Damped',
                      style: const TextStyle(fontSize: 10, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _config.smoothingFactor.clamp(0.0, 0.90),
                  min: 0.0,
                  max: 0.90,
                  divisions: 9,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.border,
                  onChanged: (val) {
                    setState(() {
                      _config = _config.copyWith(smoothingFactor: val);
                    });
                    _applyAndSave();
                  },
                ),

                if (_isAnalyzing) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _analysisProgress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Analyzing optical flow vectors (${(_analysisProgress * 100).round()}%)...',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _bakeToKeyframes,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.timeline, size: 16),
                    label: const Text('Bake Keyframes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _runTrackingAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Start Tracking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
