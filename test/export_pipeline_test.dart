import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/audio/models/audio_effects_config.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/features/export/models/export_status.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';

void main() {
  group('FFmpeg Export Pipeline Tests', () {
    late Project sampleProject;

    setUp(() {
      final now = DateTime.now();

      final videoAsset = MediaAsset(
        id: 'asset_v1',
        path: '/storage/movies/action.mp4',
        fileName: 'action.mp4',
        type: MediaType.video,
        durationMs: 20000,
        width: 1920,
        height: 1080,
      );

      final audioAsset = MediaAsset(
        id: 'asset_a1',
        path: '/storage/music/beat.mp3',
        fileName: 'beat.mp3',
        type: MediaType.audio,
        durationMs: 40000,
      );

      final videoClip = const Clip(
        id: 'clip_v1',
        assetId: 'asset_v1',
        trackId: 'track_v',
        startTimeMs: 0,
        durationMs: 6000,
        sourceInMs: 1000,
        sourceOutMs: 7000,
        volume: 1.0,
        speed: 1.0,
        audioEffects: AudioEffectsConfig(
          isVoiceEnhancerEnabled: true,
          denoiseIntensity: 0.75,
        ),
      );

      final audioClip = const Clip(
        id: 'clip_a1',
        assetId: 'asset_a1',
        trackId: 'track_a',
        startTimeMs: 0,
        durationMs: 10000,
        sourceInMs: 0,
        sourceOutMs: 10000,
        volume: 0.6,
      );

      sampleProject = Project(
        id: 'proj_export',
        title: 'Final Cut',
        createdAt: now,
        updatedAt: now,
        durationMs: 10000,
        tracks: [
          Track(
            id: 'track_v',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [videoClip],
          ),
          Track(
            id: 'track_a',
            name: 'Soundtrack',
            type: TrackType.audio,
            order: 1,
            clips: [audioClip],
          ),
        ],
        assets: [videoAsset, audioAsset],
      );
    });

    test('FFmpegCommandBuilder generates valid video and audio filter graph', () {
      const config = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        framerate: ExportFramerate.fps30,
        codec: ExportCodec.h264,
        quality: ExportQuality.high,
        outputPath: '/storage/exports/final_render.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(sampleProject, config);

      // Verify input arguments
      expect(args, contains('-i'));
      expect(args, contains('/storage/movies/action.mp4'));
      expect(args, contains('/storage/music/beat.mp3'));

      // Verify filter complex
      expect(args, contains('-filter_complex'));
      final filterComplexIdx = args.indexOf('-filter_complex');
      final filterGraph = args[filterComplexIdx + 1];

      // Video trims & scaling
      expect(filterGraph, contains('trim=start=1.000:end=7.000'));
      expect(filterGraph, contains('scale=1920:1080:force_original_aspect_ratio=decrease'));
      expect(filterGraph, contains('concat=n=1:v=1:a=0 [vout]'));

      // Audio trims & AI voice filter & mix
      expect(filterGraph, contains('atrim=start=1.000:end=7.000'));
      expect(filterGraph, contains('afftdn=nr=18.8:nf=-45'));
      expect(filterGraph, contains('amix=inputs=2:normalize=0 [aout]'));

      // Encoders and output
      expect(args, contains('libx264'));
      expect(args, contains('-crf'));
      expect(args, contains('18'));
      expect(args, contains('-r'));
      expect(args, contains('30'));
      expect(args, contains('-c:a'));
      expect(args, contains('aac'));
      expect(args, contains('/storage/exports/final_render.mp4'));
    });

    test('File size estimation accurately scales with duration and resolution', () {
      const config1080p = ExportConfiguration(
        resolution: ExportResolution.res1080p,
        quality: ExportQuality.standard,
      );

      // 60 seconds of 1080p at 12 Mbps base = 60 * 12 / 8 = 90 MB
      final est60s = config1080p.estimateFileSizeMb(60000);
      expect(est60s, equals(90.0));

      // 30 seconds of 4K at 35 Mbps base = 30 * 35 / 8 = 131.25 -> ~131.3 MB
      const config4K = ExportConfiguration(
        resolution: ExportResolution.res4k,
        quality: ExportQuality.standard,
      );
      final est4K = config4K.estimateFileSizeMb(30000);
      expect(est4K, closeTo(131.3, 0.5));
    });

    test('ExportProgress calculates correct percentage and ETA', () {
      const progress = ExportProgress(
        status: ExportStatus.rendering,
        progress: 0.65,
        currentFrame: 195,
        totalFrames: 300,
        elapsedTimeMs: 6500,
        etaRemainingMs: 3500,
      );

      expect(progress.percentage, equals(65));
      expect(progress.currentFrame, equals(195));
      expect(progress.totalFrames, equals(300));
    });

    test('FFmpegCommandBuilder burns in text track captions into output stream', () {
      final textClip = const Clip(
        id: 'clip_t1',
        assetId: '',
        trackId: 'track_text',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        textOverlay: TextOverlayConfig(
          text: 'Viral Subtitle',
          fontSize: 28,
        ),
      );

      final projectWithCaptions = sampleProject.copyWith(
        tracks: [
          ...sampleProject.tracks,
          Track(
            id: 'track_text',
            name: 'Captions',
            type: TrackType.text,
            order: 2,
            clips: [textClip],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/storage/exports/caption_test.mp4',
      );

      final args = FFmpegCommandBuilder.buildArguments(projectWithCaptions, config);
      final filterIdx = args.indexOf('-filter_complex');
      final filterGraph = args[filterIdx + 1];

      expect(filterGraph, contains('[vconcat]'));
      expect(filterGraph, contains('drawtext=text=\'Viral Subtitle\''));
      expect(filterGraph, contains('[vout]'));
    });
  });
}
