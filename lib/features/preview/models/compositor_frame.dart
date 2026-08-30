import 'package:equatable/equatable.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import 'aspect_ratio_preset.dart';

class ActiveAudioSource extends Equatable {
  final String clipId;
  final String assetId;
  final String? filePath;
  final int sourceOffsetMs;
  final double effectiveVolume;
  final bool isMuted;

  const ActiveAudioSource({
    required this.clipId,
    required this.assetId,
    this.filePath,
    required this.sourceOffsetMs,
    required this.effectiveVolume,
    this.isMuted = false,
  });

  @override
  List<Object?> get props => [clipId, assetId, filePath, sourceOffsetMs, effectiveVolume, isMuted];
}

class CompositorFrame extends Equatable {
  final int timestampMs;
  final Clip? primaryVideoClip;
  final MediaAsset? primaryAsset;
  final int sourceFrameTimeMs;
  final List<ActiveAudioSource> activeAudioSources;
  final List<Clip> activeOverlays;
  final AspectRatioPreset aspectRatio;
  final bool hasVisualContent;

  const CompositorFrame({
    required this.timestampMs,
    this.primaryVideoClip,
    this.primaryAsset,
    this.sourceFrameTimeMs = 0,
    this.activeAudioSources = const [],
    this.activeOverlays = const [],
    this.aspectRatio = AspectRatioPreset.ratio16x9,
    this.hasVisualContent = false,
  });

  @override
  List<Object?> get props => [
        timestampMs,
        primaryVideoClip,
        primaryAsset,
        sourceFrameTimeMs,
        activeAudioSources,
        activeOverlays,
        aspectRatio,
        hasVisualContent,
      ];
}
