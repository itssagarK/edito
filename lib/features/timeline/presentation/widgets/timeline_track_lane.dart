import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/track.dart';
import 'timeline_clip_widget.dart';

class TimelineTrackLane extends StatelessWidget {
  final Track track;
  final double pps;
  final double totalWidth;
  final String? selectedClipId;
  final Function(String clipId) onSelectClip;
  final Function(String clipId, double dx) onTrimClipLeft;
  final Function(String clipId, double dx) onTrimClipRight;
  final Function(String clipId, double dx) onMoveClip;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleLock;

  const TimelineTrackLane({
    super.key,
    required this.track,
    required this.pps,
    required this.totalWidth,
    required this.selectedClipId,
    required this.onSelectClip,
    required this.onTrimClipLeft,
    required this.onTrimClipRight,
    required this.onMoveClip,
    required this.onToggleMute,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.timelineTrackHeight,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: track.isLocked ? AppColors.accentWarm.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Track Control Header (Left)
          Container(
            width: AppConstants.timelineHeaderWidth,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      track.type == TrackType.video
                          ? Icons.videocam
                          : (track.type == TrackType.audio ? Icons.audiotrack : Icons.title),
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        track.name,
                        style: AppTypography.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mute track
                    InkWell(
                      onTap: onToggleMute,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          track.isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 14,
                          color: track.isMuted ? AppColors.accentWarm : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Lock track
                    InkWell(
                      onTap: onToggleLock,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          track.isLocked ? Icons.lock : Icons.lock_open,
                          size: 14,
                          color: track.isLocked ? AppColors.accentGold : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Track Clip Surface (Right)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: totalWidth,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: track.clips.map((clip) {
                    final clipX = (clip.startTimeMs / 1000.0) * pps;

                    return Positioned(
                      left: clipX,
                      child: TimelineClipWidget(
                        clip: clip,
                        trackType: track.type,
                        pps: pps,
                        isSelected: selectedClipId == clip.id,
                        onTap: () => onSelectClip(clip.id),
                        onTrimLeft: (dx) => onTrimClipLeft(clip.id, dx),
                        onTrimRight: (dx) => onTrimClipRight(clip.id, dx),
                        onDragMove: (dx) => onMoveClip(clip.id, dx),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
