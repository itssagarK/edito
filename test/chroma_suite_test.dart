import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/chroma/models/chroma_key_config.dart';
import 'package:edito/features/chroma/services/chroma_key_compiler_service.dart';
import 'package:edito/features/export/models/export_config.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';

void main() {
  group('ChromaKeyConfig Model Tests', () {
    test('Default ChromaKeyConfig has proper initial values', () {
      const config = ChromaKeyConfig();
      expect(config.isEnabled, false);
      expect(config.keyColorValue, 0xFF00FF00);
      expect(config.similarity, 0.15);
      expect(config.smoothness, 0.08);
      expect(config.spill, 0.10);
      expect(config.edgeChoke, 0.0);
      expect(config.isLumaKey, false);
    });

    test('ChromaKeyConfig serialization and deserialization retains all fields', () {
      const original = ChromaKeyConfig(
        isEnabled: true,
        keyColorValue: 0xFF0055FF, // Blue screen
        similarity: 0.22,
        smoothness: 0.12,
        spill: 0.18,
        edgeChoke: 0.05,
        isLumaKey: true,
      );

      final json = original.toJson();
      final deserialized = ChromaKeyConfig.fromJson(json);

      expect(deserialized.isEnabled, true);
      expect(deserialized.keyColorValue, 0xFF0055FF);
      expect(deserialized.similarity, 0.22);
      expect(deserialized.smoothness, 0.12);
      expect(deserialized.spill, 0.18);
      expect(deserialized.edgeChoke, 0.05);
      expect(deserialized.isLumaKey, true);
      expect(deserialized, equals(original));
    });
  });

  group('ChromaKeyCompilerService Tests', () {
    test('Disabled chroma key returns empty filter list', () {
      const config = ChromaKeyConfig(isEnabled: false);
      final filters = ChromaKeyCompilerService.generateFFmpegFilters(config);
      expect(filters, isEmpty);
      expect(ChromaKeyCompilerService.getChromaBadge(config), '');
    });

    test('Green screen generates chromakey, yuva420p format, and green despill filter', () {
      const config = ChromaKeyConfig(
        isEnabled: true,
        keyColorValue: 0xFF00FF00,
        similarity: 0.16,
        smoothness: 0.09,
        spill: 0.15,
      );

      final filters = ChromaKeyCompilerService.generateFFmpegFilters(config);
      expect(filters.length, 3);
      expect(filters[0], 'chromakey=color=0x00FF00:similarity=0.16:blend=0.09');
      expect(filters[1], 'format=yuva420p');
      expect(filters[2], contains('despill=type=green:mix=0.38:expand=0.1'));
    });

    test('Blue screen generates blue despill filter', () {
      const config = ChromaKeyConfig(
        isEnabled: true,
        keyColorValue: 0xFF0055FF,
        similarity: 0.20,
        smoothness: 0.10,
        spill: 0.20,
      );

      final filters = ChromaKeyCompilerService.generateFFmpegFilters(config);
      expect(filters.any((f) => f.contains('despill=type=blue')), isTrue);
    });

    test('Produces appropriate HUD badges for green, blue, and luma keys', () {
      const green = ChromaKeyConfig(isEnabled: true, keyColorValue: 0xFF00FF00, similarity: 0.15);
      expect(ChromaKeyCompilerService.getChromaBadge(green), contains('GREEN (15%)'));

      const blue = ChromaKeyConfig(isEnabled: true, keyColorValue: 0xFF0055FF, similarity: 0.20);
      expect(ChromaKeyCompilerService.getChromaBadge(blue), contains('BLUE (20%)'));

      const lumaBlack = ChromaKeyConfig(isEnabled: true, keyColorValue: 0xFF000000, similarity: 0.25, isLumaKey: true);
      expect(ChromaKeyCompilerService.getChromaBadge(lumaBlack), contains('LUMA KEY (BLACK 25%)'));
    });

    test('Generates valid 20-element 4x5 Skia color matrix for real-time spill suppression', () {
      const config = ChromaKeyConfig(isEnabled: true, spill: 0.20);
      final matrix = ChromaKeyCompilerService.generateSpillMatrix(config);
      expect(matrix.length, 20);
      // Green channel row (index 6) should be attenuated (< 1.0)
      expect(matrix[6], lessThan(1.0));
    });
  });

  group('FFmpeg Export Chroma Key Integration', () {
    test('Builds chromakey and despill filterchain in FFmpeg command', () {
      const asset = MediaAsset(
        id: 'asset-chroma',
        path: '/storage/actor.mp4',
        fileName: 'actor.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      const chromaClip = Clip(
        id: 'clip-chroma',
        assetId: 'asset-chroma',
        trackId: 't-chroma',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        chromaKey: ChromaKeyConfig(
          isEnabled: true,
          keyColorValue: 0xFF00FF00,
          similarity: 0.15,
          smoothness: 0.08,
          spill: 0.12,
        ),
      );

      const track = Track(
        id: 't-chroma',
        name: 'Chroma Track',
        type: TrackType.video,
        clips: [chromaClip],
      );

      const project = Project(
        id: 'p-chroma',
        name: 'Chroma Export Test',
        durationMs: 5000,
        tracks: [track],
        assets: [asset],
      );

      final cmd = FFmpegCommandBuilder.build(
        project: project,
        config: const ExportConfig(),
        outputPath: '/storage/chroma_out.mp4',
      );

      expect(cmd.command.contains('chromakey=color=0x00FF00'), isTrue);
      expect(cmd.command.contains('format=yuva420p'), isTrue);
      expect(cmd.command.contains('despill=type=green'), isTrue);
    });
  });
}
