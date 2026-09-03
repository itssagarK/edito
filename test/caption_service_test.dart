import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/captions/models/caption_line.dart';
import 'package:edito/features/captions/services/auto_caption_service.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';

void main() {
  group('AutoCaptionService and Caption Features', () {
    late Project sampleProject;

    setUp(() {
      final now = DateTime.now();
      final videoAsset = MediaAsset(
        id: 'asset_1',
        path: '/storage/movies/travel_vlog.mp4',
        fileName: 'travel_vlog.mp4',
        type: MediaType.video,
        durationMs: 15000,
        width: 1920,
        height: 1080,
      );

      final videoClip = const Clip(
        id: 'clip_1',
        assetId: 'asset_1',
        trackId: 'track_video_1',
        startTimeMs: 0,
        durationMs: 15000,
        sourceInMs: 0,
        sourceOutMs: 15000,
      );

      sampleProject = Project(
        id: 'proj_captions',
        title: 'Captions Vlog',
        createdAt: now,
        updatedAt: now,
        durationMs: 15000,
        tracks: [
          Track(
            id: 'track_video_1',
            name: 'Main Video',
            type: TrackType.video,
            order: 0,
            clips: [videoClip],
          ),
        ],
        assets: [videoAsset],
      );
    });

    test('generateAutoCaptions creates timed lines across project duration', () {
      final captions = AutoCaptionService.generateAutoCaptions(
        sampleProject,
        preset: CaptionPreset.tiktokViral,
      );

      expect(captions.isNotEmpty, isTrue);
      expect(captions.first.startTimeMs, equals(0));
      expect(captions.first.style.textColor, equals(0xFFFFE600)); // Vibrant TikTok yellow
      expect(captions.first.style.animationType, equals(TextAnimationType.popScale));

      // Ensure contiguous time progression
      for (int i = 0; i < captions.length - 1; i++) {
        expect(captions[i + 1].startTimeMs, greaterThanOrEqualTo(captions[i].startTimeMs));
        expect(captions[i].endTimeMs, lessThanOrEqualTo(15000));
      }
    });

    test('generateFromSelfDescription breaks paragraphs into bite-sized timed subtitles', () {
      const script =
          'Hello everyone and welcome to my channel! Today we are exploring the mountains of Switzerland. '
          'The views here are absolutely breathtaking and the weather is perfect.';

      final captions = AutoCaptionService.generateFromSelfDescription(
        script,
        12000,
        preset: CaptionPreset.cinematicSubtitle,
      );

      expect(captions.length, greaterThanOrEqualTo(3));
      expect(captions.first.text, contains('Hello everyone'));
      expect(captions.first.style.textColor, equals(0xFFFFFFFF));
      expect(captions.first.style.animationType, equals(TextAnimationType.fadeIn));

      // Timestamps must start at 0 and stay within total duration
      expect(captions.first.startTimeMs, equals(0));
      expect(captions.last.endTimeMs, lessThanOrEqualTo(15000));
    });

    test('syncCaptionsToProject attaches text track and allows extraction', () {
      final generated = AutoCaptionService.generateAutoCaptions(sampleProject);
      final updatedProject = AutoCaptionService.syncCaptionsToProject(sampleProject, generated);

      // Verify track was added
      final captionTrack = updatedProject.tracks.firstWhere(
        (t) => t.type == TrackType.text && t.name.contains('Captions'),
      );
      expect(captionTrack.clips.length, equals(generated.length));
      expect(captionTrack.clips.first.textOverlay.text, equals(generated.first.text));

      // Verify extraction
      final extracted = AutoCaptionService.extractCaptionsFromProject(updatedProject);
      expect(extracted.length, equals(generated.length));
      expect(extracted.first.text, equals(generated.first.text));
    });

    test('exportSrt produces compliant SRT formatting', () {
      final captions = [
        CaptionLine(
          id: '1',
          text: 'Welcome to Edito',
          startTimeMs: 1200,
          durationMs: 2500,
          style: CaptionPreset.tiktokViral.createStyle('Welcome to Edito'),
        ),
        CaptionLine(
          id: '2',
          text: 'Next-generation video editing',
          startTimeMs: 3700,
          durationMs: 3000,
          style: CaptionPreset.tiktokViral.createStyle('Next-generation video editing'),
        ),
      ];

      final srt = AutoCaptionService.exportSrt(captions);
      expect(srt, contains('1\n00:00:01,200 --> 00:00:03,700\nWelcome to Edito'));
      expect(srt, contains('2\n00:00:03,700 --> 00:00:06,700\nNext-generation video editing'));
    });

    test('CaptionPreset generates distinct styles for social media and cinema', () {
      const text = 'Caption Test';
      final tiktok = CaptionPreset.tiktokViral.createStyle(text);
      expect(tiktok.textColor, equals(0xFFFFE600));
      expect(tiktok.strokeWidth, equals(2.0));

      final podcast = CaptionPreset.neonPodcast.createStyle(text);
      expect(podcast.textColor, equals(0xFF00E5FF));

      final typewriter = CaptionPreset.retroTypewriter.createStyle(text);
      expect(typewriter.fontFamily, equals('JetBrainsMono'));
      expect(typewriter.animationType, equals(TextAnimationType.typewriter));
    });
  });
}
