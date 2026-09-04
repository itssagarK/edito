import 'dart:io';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../models/aspect_ratio_preset.dart';
import '../models/compositor_frame.dart';

class TimelineCompositorService {
  /// Evaluates the complete multi-track composite frame at a specific millisecond timestamp
  static CompositorFrame evaluateFrame(
    Project project,
    int timestampMs, {
    AspectRatioPreset aspectRatio = AspectRatioPreset.ratio16x9,
  }) {
    Clip? primaryVideoClip;
    MediaAsset? primaryAsset;
    int sourceFrameTimeMs = 0;
    final activeAudioSources = <ActiveAudioSource>[];
    final activeOverlays = <Clip>[];

    // Filter tracks by order / hierarchy
    final sortedTracks = List<Track>.from(project.tracks)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final track in sortedTracks) {
      if (track.isHidden) continue;

      // Find clip in this track active at timestampMs
      Clip? activeClip;
      for (final clip in track.clips) {
        final clipStart = clip.startTimeMs;
        final clipEnd = clip.startTimeMs + clip.durationMs;
        final isAtEndBoundary = timestampMs == clipEnd && timestampMs == project.durationMs && clip.durationMs > 0;
        if ((timestampMs >= clipStart && timestampMs < clipEnd) || isAtEndBoundary) {
          if (activeClip == null) {
            activeClip = clip;
          } else {
            // If multiple clips overlap, prefer the one with a verified playable media asset
            MediaAsset? currentAsset;
            MediaAsset? prevAsset;
            for (final a in project.assets) {
              if (a.id == clip.assetId) currentAsset = a;
              if (a.id == activeClip!.assetId) prevAsset = a;
            }
            final currentPlayable = currentAsset != null &&
                (currentAsset.path.startsWith('content://') ||
                    currentAsset.path.startsWith('http') ||
                    File(currentAsset.path).existsSync());
            final prevPlayable = prevAsset != null &&
                (prevAsset.path.startsWith('content://') ||
                    prevAsset.path.startsWith('http') ||
                    File(prevAsset.path).existsSync());
            if (currentPlayable && !prevPlayable) {
              activeClip = clip;
            }
          }
        }
      }

      if (activeClip == null) continue;

      final clipOffset = (timestampMs - activeClip.startTimeMs).clamp(0, activeClip.durationMs);
      final computedSourceMs = activeClip.sourceInMs + (clipOffset * activeClip.speed).round();

      // Find corresponding MediaAsset
      MediaAsset? asset;
      for (final a in project.assets) {
        if (a.id == activeClip.assetId) {
          asset = a;
          break;
        }
      }

      if (track.type == TrackType.video) {
        // Video layer: top-most active video clip takes visual priority
        primaryVideoClip = activeClip;
        primaryAsset = asset;
        sourceFrameTimeMs = computedSourceMs;

        // If video track has audio and is not muted, add to audio mixer with isPrimaryVideoAudio = true
        if (!track.isMuted && !activeClip.isMuted) {
          activeAudioSources.add(ActiveAudioSource(
            clipId: activeClip.id,
            assetId: activeClip.assetId,
            filePath: asset?.path,
            sourceOffsetMs: computedSourceMs,
            effectiveVolume: activeClip.volume,
            isMuted: false,
            isPrimaryVideoAudio: true,
          ));
        }
      } else if (track.type == TrackType.audio) {
        // Audio track: add to audio mixer with isPrimaryVideoAudio = false
        if (!track.isMuted && !activeClip.isMuted) {
          activeAudioSources.add(ActiveAudioSource(
            clipId: activeClip.id,
            assetId: activeClip.assetId,
            filePath: asset?.path,
            sourceOffsetMs: computedSourceMs,
            effectiveVolume: activeClip.volume,
            isMuted: false,
            isPrimaryVideoAudio: false,
          ));
        }
      } else if (track.type == TrackType.overlay || track.type == TrackType.text) {
        activeOverlays.add(activeClip);
      }
    }

    return CompositorFrame(
      timestampMs: timestampMs,
      primaryVideoClip: primaryVideoClip,
      primaryAsset: primaryAsset,
      sourceFrameTimeMs: sourceFrameTimeMs,
      activeAudioSources: activeAudioSources,
      activeOverlays: activeOverlays,
      aspectRatio: aspectRatio,
      hasVisualContent: primaryVideoClip != null,
    );
  }
}
