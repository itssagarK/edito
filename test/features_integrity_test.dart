import 'dart:io';
import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/chroma/models/chroma_key_config.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/color_filter_compiler_service.dart';
import 'package:edito/features/enhancement/models/video_enhancement_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/image_editor/models/creative_asset.dart';
import 'package:edito/features/image_editor/models/image_overlay_config.dart';
import 'package:edito/features/image_editor/models/video_layout_config.dart';
import 'package:edito/features/image_editor/services/asset_library_service.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/preview/models/aspect_ratio_preset.dart';
import 'package:edito/features/preview/services/timeline_compositor_service.dart';
import 'package:edito/features/transitions/models/transition_type.dart';
import 'package:edito/features/transitions/services/transition_compiler_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integrity & Real Functionality Verification', () {
    final now = DateTime.now();

    final testAsset = MediaAsset(
      id: 'asset_1',
      path: 'sample_video.mp4',
      fileName: 'sample_video.mp4',
      type: MediaType.video,
      durationMs: 6000,
      width: 1920,
      height: 1080,
    );

    final testAsset2 = MediaAsset(
      id: 'asset_2',
      path: 'sample_video2.mp4',
      fileName: 'sample_video2.mp4',
      type: MediaType.video,
      durationMs: 4000,
      width: 1920,
      height: 1080,
    );

    test('1. Chroma Key color suppression modifies 4x5 Color Filter matrix', () {
      const grading = ColorGradingConfig();
      final defaultMatrix = ColorFilterCompilerService.compileColorMatrix(grading);

      const greenChroma = ChromaKeyConfig(
        isEnabled: true,
        keyColorValue: 0xFF00FF00,
        similarity: 0.30,
      );

      final chromaMatrix = ColorFilterCompilerService.compileColorMatrix(
        grading,
        chromaKey: greenChroma,
      );

      expect(chromaMatrix.length, equals(20));
      expect(chromaMatrix[6], lessThan(defaultMatrix[6]));
      expect(chromaMatrix[9], lessThan(defaultMatrix[9]));
    });

    test('2. Video clip text overlay is evaluated into activeOverlays by TimelineCompositorService', () {
      final clipWithText = Clip(
        id: 'clip_v1',
        assetId: 'asset_1',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
        textOverlay: const TextOverlayConfig(text: 'Breaking News Headline'),
      );

      final project = Project(
        id: 'p_test',
        title: 'Compositor Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 6000,
        assets: [testAsset],
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [clipWithText],
          ),
        ],
      );

      final frame = TimelineCompositorService.evaluateFrame(project, 2000);
      expect(frame.primaryVideoClip, isNotNull);
      expect(frame.activeOverlays, isNotEmpty);
      expect(frame.activeOverlays.first.textOverlay.text, equals('Breaking News Headline'));
    });

    test('3. Creative Asset Badges apply to project clip and generate FFmpeg drawtext box', () {
      final clip = const Clip(
        id: 'clip_v1',
        assetId: 'asset_1',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      var project = Project(
        id: 'p_test',
        title: 'Badge Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 6000,
        assets: [testAsset],
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [clip],
          ),
        ],
      );

      final subscribeBadge = const CreativeAsset(
        id: 'asset_sub',
        title: 'Subscribe & Bell',
        subtitle: 'Call to action',
        category: AssetCategory.badge,
        iconEmoji: '🔔',
        primaryColor: 0xFFFF0000,
        metadata: {'label': 'SUBSCRIBE NOW', 'emoji': '🔔'},
      );

      project = AssetLibraryService.applyAssetToProject(project, subscribeBadge, targetClipId: 'clip_v1');
      final updatedClip = project.tracks.first.clips.first;

      expect(updatedClip.imageOverlay.isEnabled, isTrue);
      expect(updatedClip.imageOverlay.assetLabel, contains('SUBSCRIBE NOW'));

      const config = ExportConfiguration(
        resolution: ResolutionPreset.fhd1080p,
        framerate: FrameratePreset.fps30,
        codec: CodecPreset.h264,
        quality: QualityPreset.balanced,
      );

      final cmd = FFmpegCommandBuilder.buildCommandString(project, config);
      expect(cmd, contains('drawtext=text='));
      expect(cmd, contains('SUBSCRIBE NOW'));
      expect(cmd, contains('box=1'));
    });

    test('4. Video Layout framing applies custom padding and background color to FFmpeg filter', () {
      final clip = const Clip(
        id: 'clip_v1',
        assetId: 'asset_1',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      final project = Project(
        id: 'p_test',
        title: 'Layout Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 6000,
        assets: [testAsset],
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [clip],
          ),
        ],
        layoutConfig: const VideoLayoutConfig(
          ratio: VideoLayoutRatio.ratio9_16,
          framePadding: 20.0,
          backgroundColor: 0xFF2C3E50,
        ),
      );

      const config = ExportConfiguration(
        resolution: ResolutionPreset.fhd1080p,
        framerate: FrameratePreset.fps30,
        codec: CodecPreset.h264,
        quality: QualityPreset.balanced,
      );

      final cmd = FFmpegCommandBuilder.buildCommandString(project, config);
      expect(cmd, contains('scale=1880:1040'));
      expect(cmd, contains('color=0x2C3E50'));
    });

    test('5. Video Transitions compile into xfade filter between clips', () {
      final clip1 = const Clip(
        id: 'clip_v1',
        assetId: 'asset_1',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 0,
        sourceOutMs: 6000,
      );

      final clip2 = const Clip(
        id: 'clip_v2',
        assetId: 'asset_2',
        trackId: 'track_v',
        startTimeMs: 6000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        transitionIn: TransitionConfig(
          type: TransitionType.wipeLeft,
          durationMs: 1000,
        ),
      );

      final project = Project(
        id: 'p_test',
        title: 'Transition Test',
        createdAt: now,
        updatedAt: now,
        durationMs: 10000,
        assets: [testAsset, testAsset2],
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [clip1, clip2],
          ),
        ],
      );

      const config = ExportConfiguration(
        resolution: ResolutionPreset.fhd1080p,
        framerate: FrameratePreset.fps30,
        codec: CodecPreset.h264,
        quality: QualityPreset.balanced,
      );

      final cmd = FFmpegCommandBuilder.buildCommandString(project, config);
      expect(cmd, contains('xfade=transition=wipeleft:duration=1.00'));
    });

    test('6. TransitionCompilerService maps all transition types to valid FFmpeg xfade names', () {
      for (final type in TransitionType.values) {
        if (type == TransitionType.none) {
          expect(type.ffmpegXFadeName, isEmpty);
        } else {
          expect(type.ffmpegXFadeName, isNotEmpty);
          final filter = TransitionCompilerService.generateFFmpegXFade(
            TransitionConfig(type: type, durationMs: 800),
            offsetSec: 5.0,
          );
          expect(filter, contains(type.ffmpegXFadeName));
          expect(filter, contains('duration=0.80'));
          expect(filter, contains('offset=5.00'));
        }
      }
    });
  });
}
