import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';

class TimelineSurface extends StatelessWidget {
  final Project? project;
  final int playheadPositionMs;
  final double zoomScale;
  final String? selectedClipId;
  final Function(int) onSeek;
  final Function(String?, {String? trackId}) onSelectClip;

  const TimelineSurface({
    super.key,
    required this.project,
    required this.playheadPositionMs,
    required this.zoomScale,
    this.selectedClipId,
    required this.onSeek,
    required this.onSelectClip,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = project?.tracks ?? [];
    final totalDurationMs = project?.durationMs ?? 30000;
    final pps = AppConstants.timelinePixelsPerSecond * zoomScale;
    final totalWidth = (totalDurationMs / 1000.0) * pps + 400; // Extra buffer for dragging

    final playheadX = (playheadPositionMs / 1000.0) * pps;

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Timeline Ruler
          Container(
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(
                top: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: GestureDetector(
                onTapDown: (details) {
                  final tappedMs = ((details.localPosition.dx / pps) * 1000).toInt();
                  onSeek(tappedMs);
                },
                onHorizontalDragUpdate: (details) {
                  final tappedMs = ((details.localPosition.dx / pps) * 1000).toInt();
                  onSeek(tappedMs);
                },
                child: CustomPaint(
                  size: Size(totalWidth, 28),
                  painter: _RulerPainter(pps: pps, totalDurationMs: totalDurationMs),
                ),
              ),
            ),
          ),

          // Multi-Track Surface
          Expanded(
            child: Stack(
              children: [
                // Tracks Container
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: totalWidth,
                    child: ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _buildTrackRow(track, pps);
                      },
                    ),
                  ),
                ),

                // Center Playhead Indicator
                Positioned(
                  left: playheadX.clamp(0.0, totalWidth),
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.playhead,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: AppConstants.playheadWidth,
                            color: AppColors.playhead,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackRow(Track track, double pps) {
    final trackColor = track.type == TrackType.video
        ? AppColors.videoTrack
        : (track.type == TrackType.audio ? AppColors.audioTrack : AppColors.textTrack);

    return Container(
      height: AppConstants.timelineTrackHeight,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Track Name Badge
          Positioned(
            left: 8,
            top: 4,
            child: Row(
              children: [
                Icon(
                  track.type == TrackType.video
                      ? Icons.videocam_outlined
                      : (track.type == TrackType.audio ? Icons.audiotrack_outlined : Icons.title),
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  track.name,
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ),

          // Render Clips inside track
          ...track.clips.map((clip) {
            final clipX = (clip.startTimeMs / 1000.0) * pps;
            final clipWidth = (clip.durationMs / 1000.0) * pps;
            final isSelected = selectedClipId == clip.id;

            return Positioned(
              left: clipX,
              top: 18,
              bottom: 4,
              width: clipWidth.clamp(20.0, 10000.0),
              child: GestureDetector(
                onTap: () => onSelectClip(clip.id, trackId: track.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: trackColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? 2 : 0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Clip ${clip.id.substring(0, 4)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double pps;
  final int totalDurationMs;

  _RulerPainter({required this.pps, required this.totalDurationMs});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.4)
      ..strokeWidth = 1;

    final majorLinePaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.2;

    final textStyle = AppTypography.timecode.copyWith(
      fontSize: 9,
      color: AppColors.textMuted,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final totalSeconds = (totalDurationMs / 1000.0).ceil() + 10;

    for (int s = 0; s <= totalSeconds; s++) {
      final x = s * pps;

      // Major second mark
      canvas.drawLine(Offset(x, 14), Offset(x, 28), majorLinePaint);

      textPainter.text = TextSpan(text: '${s}s', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 3, 2));

      // Minor sub-second ticks
      for (int sub = 1; sub <= 3; sub++) {
        final subX = x + (sub * (pps / 4));
        canvas.drawLine(Offset(subX, 20), Offset(subX, 28), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.pps != pps || oldDelegate.totalDurationMs != totalDurationMs;
  }
}
