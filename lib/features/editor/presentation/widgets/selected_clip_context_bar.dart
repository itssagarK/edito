import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';

/// Contextual status and safety bar displayed directly above the timeline.
/// Provides instant feedback on the currently selected clip, its in/out boundaries,
/// quick safe-action buttons, and clear deselection to prevent accidental edits.
class SelectedClipContextBar extends StatelessWidget {
  final Project project;
  final String? selectedClipId;
  final int playheadPositionMs;
  final VoidCallback onDeselect;
  final VoidCallback onSplit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onOpenTimestampJump;

  const SelectedClipContextBar({
    super.key,
    required this.project,
    required this.selectedClipId,
    required this.playheadPositionMs,
    required this.onDeselect,
    required this.onSplit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onOpenTimestampJump,
  });

  @override
  Widget build(BuildContext context) {
    Clip? selectedClip;
    Track? selectedTrack;

    if (selectedClipId != null) {
      for (final track in project.tracks) {
        for (final clip in track.clips) {
          if (clip.id == selectedClipId) {
            selectedClip = clip;
            selectedTrack = track;
            break;
          }
        }
        if (selectedClip != null) break;
      }
    }

    final hasSelection = selectedClip != null;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hasSelection ? AppColors.surfaceElevated : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: hasSelection ? AppColors.accent.withOpacity(0.3) : AppColors.border,
            width: 1.0,
          ),
          bottom: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: hasSelection
          ? _buildSelectedClipView(context, selectedClip!, selectedTrack)
          : _buildTimelineDefaultView(context),
    );
  }

  Widget _buildSelectedClipView(BuildContext context, Clip clip, Track? track) {
    final clipInMs = clip.startTimeMs;
    final clipOutMs = clip.startTimeMs + clip.durationMs;
    final isPlayheadInsideClip = playheadPositionMs >= clipInMs && playheadPositionMs <= clipOutMs;

    IconData trackIcon = Icons.videocam;
    if (track != null) {
      if (track.type == TrackType.audio) {
        trackIcon = Icons.audiotrack;
      } else if (track.type == TrackType.overlay) {
        trackIcon = Icons.title;
      }
    }

    return Row(
      children: [
        // Track & Clip Type Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trackIcon, size: 12, color: AppColors.primaryLight),
              const SizedBox(width: 4),
              Text(
                track?.name ?? 'Clip',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Clip Timing Info
        Expanded(
          child: Text(
            'In: ${TimecodeFormatter.formatMilliseconds(clipInMs)} • Dur: ${(clip.durationMs / 1000).toStringAsFixed(1)}s • Out: ${TimecodeFormatter.formatMilliseconds(clipOutMs)}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Quick Split Action
        _buildActionPill(
          icon: Icons.content_cut,
          label: 'Split',
          color: isPlayheadInsideClip ? AppColors.accent : AppColors.textMuted,
          onTap: onSplit,
          tooltip: isPlayheadInsideClip ? 'Split clip at playhead' : 'Split clip at midpoint',
        ),
        const SizedBox(width: 4),

        // Quick Duplicate Action
        _buildActionPill(
          icon: Icons.copy,
          label: 'Copy',
          color: AppColors.textPrimary,
          onTap: onDuplicate,
          tooltip: 'Duplicate clip',
        ),
        const SizedBox(width: 4),

        // Quick Delete Action
        _buildActionPill(
          icon: Icons.delete_outline,
          label: 'Del',
          color: AppColors.accentWarm,
          onTap: onDelete,
          tooltip: 'Delete clip',
        ),
        const SizedBox(width: 6),

        // Prominent Deselect Button
        InkWell(
          onTap: onDeselect,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 12, color: AppColors.textSecondary),
                SizedBox(width: 2),
                Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDefaultView(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF20BF6B),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Timeline Ready',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•  ${project.tracks.length} Tracks',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Jump Button
            InkWell(
              onTap: onOpenTimestampJump,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.av_timer, size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      TimecodeFormatter.formatMilliseconds(playheadPositionMs),
                      style: AppTypography.timecode.copyWith(
                        fontSize: 10.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
