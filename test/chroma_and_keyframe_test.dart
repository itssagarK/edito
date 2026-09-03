import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/chroma/models/chroma_key_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/overlays/models/keyframe.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/overlays/services/overlay_compiler_service.dart';

void main() {
  group('Chroma Key & Keyframe Animation Tests', () {
    test('ChromaKeyConfig serialization roundtrip', () {
      const config = ChromaKeyConfig(
        isEnabled: true,
        keyColorValue: 0xFF00FF00,
        similarity: 0.22,
        smoothness: 0.12,
        spill: 0.15,
      );

      final json = config.toJson();
      final restored = ChromaKeyConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.keyColorValue, equals(0xFF00FF00));
      expect(restored.similarity, equals(0.22));
      expect(restored.smoothness, equals(0.12));
      expect(restored.spill, equals(0.15));
    });

    test('FFmpegCommandBuilder generates chromakey video filter when enabled', () {
      const chromaClip = Clip(
        id: 'clip_chroma',
        assetId: 'asset_green',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        chromaKey: ChromaKeyConfig(
          isEnabled: true,
          keyColorValue: 0xFF00FF00,
          similarity: 0.20,
          smoothness: 0.10,
        ),
      );

      const videoAsset = MediaAsset(
        id: 'asset_green',
        path: '/storage/movies/green_screen.mp4',
        fileName: 'green_screen.mp4',
        type: MediaType.video,
        durationMs: 4000,
      );

      final project = Project(
        id: 'proj_chroma',
        title: 'Chroma Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        durationMs: 4000,
        assets: const [videoAsset],
        tracks: const [
          Track(
            id: 'track_v',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [chromaClip],
          ),
        ],
      );

      final args = FFmpegCommandBuilder.buildArguments(project, const ExportConfiguration());
      final filterIdx = args.indexOf('-filter_complex');
      final filterGraph = args[filterIdx + 1];

      expect(filterGraph, contains('chromakey=color=0x00FF00:similarity=0.20:blend=0.10'));
    });

    test('OverlayCompilerService smoothly interpolates keyframes', () {
      const textClip = Clip(
        id: 'clip_kf',
        assetId: '',
        trackId: 'track_txt',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        textOverlay: TextOverlayConfig(
          text: 'Animated Motion',
          positionX: 0.1,
          positionY: 0.2,
          scale: 1.0,
        ),
        keyframes: [
          Keyframe(timeOffsetMs: 0, positionX: 0.0, positionY: 0.0, scale: 1.0),
          Keyframe(timeOffsetMs: 2000, positionX: 1.0, positionY: 1.0, scale: 2.0),
        ],
      );

      // Midpoint at 1000ms: position should be 0.5, scale 1.5
      final evaluatedMid = OverlayCompilerService.evaluateOverlayAt(textClip, 1000);
      expect(evaluatedMid.positionX, closeTo(0.5, 0.01));
      expect(evaluatedMid.positionY, closeTo(0.5, 0.01));
      expect(evaluatedMid.scale, closeTo(1.5, 0.01));

      // At start (0ms): position 0.0, scale 1.0
      final evaluatedStart = OverlayCompilerService.evaluateOverlayAt(textClip, 0);
      expect(evaluatedStart.positionX, equals(0.0));
      expect(evaluatedStart.scale, equals(1.0));

      // At end (2000ms): position 1.0, scale 2.0
      final evaluatedEnd = OverlayCompilerService.evaluateOverlayAt(textClip, 2000);
      expect(evaluatedEnd.positionX, equals(1.0));
      expect(evaluatedEnd.scale, equals(2.0));
    });
  });
}
