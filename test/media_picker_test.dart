import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/media/services/metadata_probe_service.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Media Probe & Detection Tests', () {
    test('detectTypeFromExtension correctly classifies video, audio, and image formats', () {
      expect(MetadataProbeService.detectTypeFromExtension('movie.mp4'), equals(MediaType.video));
      expect(MetadataProbeService.detectTypeFromExtension('clip.MOV'), equals(MediaType.video));
      expect(MetadataProbeService.detectTypeFromExtension('footage.mkv'), equals(MediaType.video));

      expect(MetadataProbeService.detectTypeFromExtension('music.mp3'), equals(MediaType.audio));
      expect(MetadataProbeService.detectTypeFromExtension('recording.wav'), equals(MediaType.audio));
      expect(MetadataProbeService.detectTypeFromExtension('voiceover.m4a'), equals(MediaType.audio));

      expect(MetadataProbeService.detectTypeFromExtension('photo.jpg'), equals(MediaType.image));
      expect(MetadataProbeService.detectTypeFromExtension('graphic.png'), equals(MediaType.image));
      expect(MetadataProbeService.detectTypeFromExtension('banner.webp'), equals(MediaType.image));
    });

    test('probeFile generates MediaAsset with fallback values when file does not exist', () async {
      final asset = await MetadataProbeService.probeFile('non_existent_file.mp4', MediaType.video);

      expect(asset.fileName, equals('non_existent_file.mp4'));
      expect(asset.type, equals(MediaType.video));
      expect(asset.durationMs, greaterThan(0));
      expect(asset.width, equals(1920));
      expect(asset.height, equals(1080));
    });
  });
}
