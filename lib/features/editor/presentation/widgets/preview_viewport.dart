import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';

class PreviewViewport extends StatelessWidget {
  final int currentPositionMs;
  final int totalDurationMs;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;

  const PreviewViewport({
    super.key,
    required this.currentPositionMs,
    required this.totalDurationMs,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onStepBackward,
    required this.onStepForward,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Video Render Canvas Box
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video Surface (Phase 3 will hook real GL / Texture here)
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: const Color(0xFF0A0A0E),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              size: 48,
                              color: AppColors.textMuted.withOpacity(0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preview Viewport (1080p)',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Overlay Timecode Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${TimecodeFormatter.formatSmpte(currentPositionMs)} / ${TimecodeFormatter.formatSmpte(totalDurationMs)}',
                        style: AppTypography.timecode.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Transport Playback Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimecodeFormatter.formatMilliseconds(currentPositionMs),
                style: AppTypography.timecode,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_5, size: 22),
                    onPressed: onStepBackward,
                    tooltip: '-5s',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: onTogglePlay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.forward_5, size: 22),
                    onPressed: onStepForward,
                    tooltip: '+5s',
                  ),
                ],
              ),
              Text(
                TimecodeFormatter.formatMilliseconds(totalDurationMs),
                style: AppTypography.timecode.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
