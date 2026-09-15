import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../services/timeline_editing_service.dart';

class ClipWorkflowSheet extends StatefulWidget {
  final Project project;
  final Clip clip;
  final int playheadPositionMs;
  final Function(Project updatedProject) onProjectChanged;
  final VoidCallback? onDone;

  const ClipWorkflowSheet({
    super.key,
    required this.project,
    required this.clip,
    required this.playheadPositionMs,
    required this.onProjectChanged,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Clip clip,
    required int playheadPositionMs,
    required Function(Project) onProjectChanged,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipWorkflowSheet(
        project: project,
        clip: clip,
        playheadPositionMs: playheadPositionMs,
        onProjectChanged: onProjectChanged,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ClipWorkflowSheet> createState() => _ClipWorkflowSheetState();
}

class _ClipWorkflowSheetState extends State<ClipWorkflowSheet> {
  late Clip _currentClip;
  late Project _currentProject;
  int _freezeDurationSec = 3;

  @override
  void initState() {
    super.initState();
    _currentClip = widget.clip;
    _currentProject = widget.project;
  }

  void _updateProject(Project updated) {
    setState(() {
      _currentProject = updated;
      for (final track in updated.tracks) {
        for (final clip in track.clips) {
          if (clip.id == _currentClip.id) {
            _currentClip = clip;
            break;
          }
        }
      }
    });
    widget.onProjectChanged(updated);
  }

  void _handleFreezeFrame() {
    final updated = TimelineEditingService.freezeFrame(
      _currentProject,
      _currentClip.id,
      widget.playheadPositionMs,
      freezeDurationMs: _freezeDurationSec * 1000,
    );
    if (updated != null) {
      _updateProject(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❄️ Inserted ${_freezeDurationSec}s Freeze Frame at ${(widget.playheadPositionMs / 1000.0).toStringAsFixed(1)}s'),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleToggleReverse() {
    final updated = TimelineEditingService.toggleReverseClip(_currentProject, _currentClip.id);
    if (updated != null) {
      _updateProject(updated);
      final isNowRev = !_currentClip.isReversed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowRev ? '⏪ Video & Audio playback set to REVERSE' : '▶️ Playback restored to FORWARD'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleExtractAudio() {
    final updated = TimelineEditingService.extractAudio(_currentProject, _currentClip.id);
    if (updated != null) {
      _updateProject(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎵 Audio detached to dedicated audio track! Video muted.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleDuplicateClip() {
    final updated = TimelineEditingService.duplicateClip(_currentProject, _currentClip.id);
    _updateProject(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Clip duplicated successfully'),
        duration: Duration(milliseconds: 800),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReversed = _currentClip.isReversed;
    final isFreeze = _currentClip.isFreezeFrame;
    final isMuted = _currentClip.isMuted;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.movie_creation_outlined, color: AppColors.primaryLight, size: 22),
                      const SizedBox(width: 8),
                      Text('Clip Workflow Studio', style: AppTypography.titleMedium),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),

              // Clip Info Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildChip('⏱️ ${( _currentClip.durationMs / 1000.0).toStringAsFixed(1)}s', AppColors.primary),
                  _buildChip('🎬 Start: ${( _currentClip.startTimeMs / 1000.0).toStringAsFixed(1)}s', AppColors.surfaceElevated),
                  if (isFreeze)
                    _buildChip('❄️ FREEZE FRAME', const Color(0xFF00E5FF)),
                  if (isReversed)
                    _buildChip('⏪ REVERSED', const Color(0xFFFF5252)),
                  if (isMuted)
                    _buildChip('🔇 MUTED', AppColors.accentWarm),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Freeze Frame Tool Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFreeze ? const Color(0xFF00E5FF) : AppColors.border,
                    width: isFreeze ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.ac_unit, color: Color(0xFF00E5FF), size: 18),
                            SizedBox(width: 8),
                            Text('Freeze Frame', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ],
                        ),
                        Text(
                          '${_freezeDurationSec}s Hold',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Freezes video at playhead and pauses playback while preserving audio pacing.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Duration:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Expanded(
                          child: Slider(
                            value: _freezeDurationSec.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: const Color(0xFF00E5FF),
                            inactiveColor: AppColors.border,
                            onChanged: (val) {
                              setState(() => _freezeDurationSec = val.round());
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.pause_circle_filled, size: 16),
                        label: Text('Insert ${_freezeDurationSec}s Freeze at Playhead (${(widget.playheadPositionMs / 1000.0).toStringAsFixed(1)}s)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                          foregroundColor: const Color(0xFF00E5FF),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _handleFreezeFrame,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Reverse Playback Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReversed ? const Color(0xFFFF5252) : AppColors.border,
                    width: isReversed ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isReversed ? const Color(0xFFFF5252).withOpacity(0.2) : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isReversed ? Icons.replay : Icons.play_arrow,
                        color: isReversed ? const Color(0xFFFF5252) : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReversed ? 'Reverse Playback Active' : 'Forward Playback',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isReversed ? const Color(0xFFFF5252) : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isReversed ? 'Video & audio play backwards from tail' : 'Standard chronological playback',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReversed ? const Color(0xFFFF5252) : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: _handleToggleReverse,
                      child: Text(isReversed ? 'Restore' : 'Reverse'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Detach / Extract Audio Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detach / Extract Audio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Separates audio onto a standalone track for mixing and independent trimming.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: _handleExtractAudio,
                      child: const Text('Extract'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Duplicate & Speed Retime Quick Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Duplicate Clip'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _handleDuplicateClip,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: widget.onDone ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
