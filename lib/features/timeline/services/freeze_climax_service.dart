import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../transform/models/video_transform_config.dart';
import '../../vfx/models/impact_flash_config.dart';
import '../../color_grading/models/color_grading_config.dart';
import '../models/freeze_climax_config.dart';

class FreezeClimaxService {
  /// Inserts a high-impact freeze frame climax into the project.
  /// Splits the target clip, inserts a styled freeze hold clip with zoom and accents,
  /// and ripple-shifts downstream clips to maintain timeline synchronization.
  static Project insertFreezeClimax(
    Project project, {
    required String trackId,
    required String clipId,
    required int targetPositionMs,
    required FreezeClimaxConfig config,
    bool rippleAllTracks = true,
  }) {
    final trackIndex = project.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return project;

    final targetTrack = project.tracks[trackIndex];
    final clipIndex = targetTrack.clips.indexWhere((c) => c.id == clipId);
    if (clipIndex == -1) return project;

    final originalClip = targetTrack.clips[clipIndex];

    // Ensure split boundary is inside original clip with minimum 40ms headroom on both ends
    final minSplit = originalClip.startTimeMs + 40;
    final maxSplit = originalClip.startTimeMs + originalClip.durationMs - 40;
    if (maxSplit <= minSplit) return project;

    final splitTimeMs = targetPositionMs.clamp(minSplit, maxSplit);
    final offsetMs = splitTimeMs - originalClip.startTimeMs;
    final freezeSourceTimeMs = originalClip.sourceInMs + (offsetMs * originalClip.speed).round();
    final freezeDurationMs = config.freezeDurationMs.clamp(100, 10000);

    // 1. Left (pre-freeze) clip
    final leftClip = originalClip.copyWith(
      id: '${originalClip.id}_left_${DateTime.now().millisecondsSinceEpoch}',
      durationMs: offsetMs,
      sourceOutMs: freezeSourceTimeMs,
    );

    // 2. Freeze Frame Climax clip
    ColorGradingConfig climaxGrading = originalClip.colorGrading;
    switch (config.accentStyle) {
      case FreezeAccentStyle.none:
        break;
      case FreezeAccentStyle.monochrome:
        climaxGrading = climaxGrading.copyWith(saturation: 0.0, contrast: 1.25);
        break;
      case FreezeAccentStyle.actionGrit:
        climaxGrading = climaxGrading.copyWith(contrast: 1.35, brightness: 0.95, saturation: 0.85);
        break;
      case FreezeAccentStyle.warmSunset:
        climaxGrading = climaxGrading.copyWith(temperature: 0.35, saturation: 1.25);
        break;
      case FreezeAccentStyle.neonInvert:
        climaxGrading = climaxGrading.copyWith(contrast: 1.5, saturation: 1.5);
        break;
    }

    final freezeClip = originalClip.copyWith(
      id: 'freeze_${DateTime.now().millisecondsSinceEpoch}',
      startTimeMs: splitTimeMs,
      durationMs: freezeDurationMs,
      sourceInMs: freezeSourceTimeMs,
      sourceOutMs: freezeSourceTimeMs + 40,
      isFreezeFrame: true,
      freezeSourceMs: freezeSourceTimeMs,
      transform: originalClip.transform.copyWith(
        scale: config.zoomScale.clamp(1.0, 2.5),
      ),
      impactFlash: config.flashAccent
          ? const ImpactFlashConfig(
              isEnabled: true,
              type: ImpactFlashType.whiteFlash,
              durationMs: 180,
              intensity: 0.9,
            )
          : const ImpactFlashConfig(),
      colorGrading: climaxGrading,
      volume: config.muteAudioDuringFreeze ? 0.0 : originalClip.volume,
      isMuted: config.muteAudioDuringFreeze ? true : originalClip.isMuted,
    );

    // 3. Right (post-freeze) clip
    final rightDuration = originalClip.durationMs - offsetMs;
    final rightClip = originalClip.copyWith(
      id: '${originalClip.id}_right_${DateTime.now().millisecondsSinceEpoch}',
      startTimeMs: splitTimeMs + freezeDurationMs,
      durationMs: rightDuration,
      sourceInMs: freezeSourceTimeMs,
      sourceOutMs: originalClip.sourceOutMs,
    );

    // 4. Update the target track
    final updatedTargetClips = <Clip>[];
    for (int i = 0; i < targetTrack.clips.length; i++) {
      if (i == clipIndex) {
        updatedTargetClips.add(leftClip);
        updatedTargetClips.add(freezeClip);
        updatedTargetClips.add(rightClip);
      } else {
        final c = targetTrack.clips[i];
        if (c.startTimeMs >= splitTimeMs) {
          updatedTargetClips.add(c.copyWith(startTimeMs: c.startTimeMs + freezeDurationMs));
        } else {
          updatedTargetClips.add(c);
        }
      }
    }

    final updatedTracks = <Track>[];
    for (int i = 0; i < project.tracks.length; i++) {
      if (i == trackIndex) {
        updatedTracks.add(targetTrack.copyWith(clips: updatedTargetClips));
      } else if (rippleAllTracks) {
        final t = project.tracks[i];
        final shiftedClips = t.clips.map((c) {
          if (c.startTimeMs >= splitTimeMs) {
            return c.copyWith(startTimeMs: c.startTimeMs + freezeDurationMs);
          }
          return c;
        }).toList();
        updatedTracks.add(t.copyWith(clips: shiftedClips));
      } else {
        updatedTracks.add(project.tracks[i]);
      }
    }

    return project.copyWith(tracks: updatedTracks);
  }
}
