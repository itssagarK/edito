import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/clip.dart';
import '../../../../models/track.dart';
import '../../../audio/presentation/widgets/waveform_painter.dart';

class TimelineClipWidget extends StatelessWidget {
  final Clip clip;
  final TrackType trackType;
  final double pps;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double dx) onTrimLeft;
  final Function(double dx) onTrimRight;
  final Function(double dx) onDragMove;

  const TimelineClipWidget({
    super.key,
    required this.clip,
    required this.trackType,
    required this.pps,
    required this.isSelected,
    required this.onTap,
    required this.onTrimLeft,
    required this.onTrimRight,
    required this.onDragMove,
  });

  @override
  Widget build(BuildContext context) {
    final clipWidth = (clip.durationMs / 1000.0) * pps;
    final displayWidth = clipWidth < 24.0 ? 24.0 : clipWidth;

    final Color trackBgColor = trackType == TrackType.video
        ? AppColors.videoTrack
        : (trackType == TrackType.audio ? AppColors.audioTrack : AppColors.textTrack);

    return GestureDetector(
      onTap: onTap,
      onHorizontalDragUpdate: isSelected ? (d) => onDragMove(d.delta.dx) : null,
      child: Container(
        width: displayWidth,
        height: 48,
        decoration: BoxDecoration(
          color: trackBgColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 2.0 : 0.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Waveform background for audio tracks
            if (trackType == TrackType.audio)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: WaveformPainter(
                      color: Colors.white,
                      seed: clip.id.hashCode,
                    ),
                  ),
                ),
              ),

            // Internal clip body content (Icons, duration, AI badge)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 14.0 : 6.0),
                child: Row(
                  children: [
                    Icon(
                      trackType == TrackType.video
                          ? Icons.movie_creation_outlined
                          : (trackType == TrackType.audio ? Icons.graphic_eq : Icons.title),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${(clip.durationMs / 1000.0).toStringAsFixed(1)}s (${clip.id.substring(0, 4)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (clip.audioEffects.isVoiceEnhancerEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppColors.accent, width: 0.8),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ),
                    if (clip.speed != 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${clip.speed}x',
                          style: const TextStyle(fontSize: 9, color: AppColors.accentGold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Left Trim Handle (When selected)
            if (isSelected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 14,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => onTrimLeft(details.delta.dx),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_left, size: 12, color: Colors.black),
                    ),
                  ),
                ),
              ),

            // Right Trim Handle (When selected)
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 14,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => onTrimRight(details.delta.dx),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.chevron_right, size: 12, color: Colors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
