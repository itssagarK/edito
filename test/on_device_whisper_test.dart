import 'package:flutter_test/flutter_test.dart';
import 'package:edito/core/ai/models/ai_model_descriptor.dart';
import 'package:edito/core/ai/on_device_inference_runner.dart';
import 'package:edito/features/captions/models/caption_line.dart';
import 'package:edito/features/captions/services/auto_caption_service.dart';
import 'package:edito/features/captions/services/whisper_transcription_service.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('On-Device Whisper Speech-to-Text Pipeline (F1)', () {
    late Project sampleProject;

    setUp(() {
      final now = DateTime.now();
      final videoAsset = MediaAsset(
        id: 'asset_speech_1',
        path: '/storage/emulated/0/DCIM/camera_voice.mp4',
        fileName: 'camera_voice.mp4',
        type: MediaType.video,
        durationMs: 8000,
        width: 1920,
        height: 1080,
      );

      final videoClip = const Clip(
        id: 'clip_speech_1',
        assetId: 'asset_speech_1',
        trackId: 'track_v_1',
        startTimeMs: 0,
        durationMs: 8000,
        sourceInMs: 0,
        sourceOutMs: 8000,
      );

      sampleProject = Project(
        id: 'proj_speech_captions',
        title: 'Voice Vlog',
        createdAt: now,
        updatedAt: now,
        durationMs: 8000,
        tracks: [
          Track(
            id: 'track_v_1',
            name: 'Video',
            type: TrackType.video,
            order: 0,
            clips: [videoClip],
          ),
        ],
        assets: [videoAsset],
      );
    });

    test('Whisper transcription returns structured captions with word timings', () async {
      // In unit test environment, transcribeProject uses fallback simulation
      final result = await WhisperTranscriptionService.transcribeProject(
        sampleProject,
        preset: CaptionPreset.tiktokViral,
        language: 'en',
      );

      expect(result.isSuccess, isTrue);
      expect(result.captions.isNotEmpty, isTrue);
      expect(result.detectedLanguage, equals('en'));

      final firstLine = result.captions.first;
      expect(firstLine.startTimeMs, equals(0));
      expect(firstLine.words.isNotEmpty, isTrue);
      expect(firstLine.isKinetic, isTrue);
      expect(firstLine.style.textColor, equals(0xFFFFE600)); // TikTok viral yellow
    });

    test('Whisper transcription respects cancellation token gracefully', () async {
      final cancelToken = CancellationToken()..cancel();

      final result = await WhisperTranscriptionService.transcribeProject(
        sampleProject,
        preset: CaptionPreset.cinematicSubtitle,
        cancelToken: cancelToken,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('cancelled'));
    });

    test('generated whisper captions sync to project timeline and export to .srt', () {
      final captions = [
        CaptionLine(
          id: 'cap_w1',
          text: 'Hello world from on-device whisper',
          startTimeMs: 0,
          durationMs: 3000,
          style: CaptionPreset.tiktokViral.createStyle('Hello world from on-device whisper'),
          words: CaptionLine.generateInterpolatedWords('Hello world from on-device whisper', 3000),
          isKinetic: true,
        ),
        CaptionLine(
          id: 'cap_w2',
          text: 'Zero cloud latency and completely private',
          startTimeMs: 3200,
          durationMs: 3500,
          style: CaptionPreset.tiktokViral.createStyle('Zero cloud latency and completely private'),
          words: CaptionLine.generateInterpolatedWords('Zero cloud latency and completely private', 3500),
          isKinetic: true,
        ),
      ];

      // Sync to project
      final updatedProject = AutoCaptionService.syncCaptionsToProject(sampleProject, captions);
      final captionTrack = updatedProject.tracks.firstWhere((t) => t.type == TrackType.text);

      expect(captionTrack.clips.length, equals(2));
      expect(captionTrack.clips.first.textOverlay.text, equals('Hello world from on-device whisper'));
      expect(captionTrack.clips.first.kineticCaptions.isEnabled, isTrue);

      // Export companion .srt
      final srt = AutoCaptionService.exportSrt(captions);
      expect(srt, contains('1\n00:00:00,000 --> 00:00:03,000\nHello world from on-device whisper'));
      expect(srt, contains('2\n00:00:03,200 --> 00:00:06,700\nZero cloud latency and completely private'));
    });
  });
}
