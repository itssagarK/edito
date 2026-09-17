import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/captions/models/caption_line.dart';
import 'package:edito/features/captions/services/srt_subtitle_service.dart';
import 'package:edito/features/captions/services/caption_compiler_service.dart';
import 'package:edito/features/captions/services/auto_caption_service.dart';

void main() {
  group('Feature 16: Dynamic Kinetic Subtitles & Animated Word-by-Word Caption Studio Tests', () {
    test('KaraokeHighlightStyle enums have descriptive labels', () {
      expect(KaraokeHighlightStyle.none.label, equals('None'));
      expect(KaraokeHighlightStyle.colorFill.label, contains('Color Pop'));
      expect(KaraokeHighlightStyle.scalePunch.label, contains('Scale Bounce'));
      expect(KaraokeHighlightStyle.pillBackground.label, contains('Neon Pill'));
      expect(KaraokeHighlightStyle.glowWave.label, contains('Aura Glow'));
    });

    test('WordTimestamp model supports JSON serialization and deserialization', () {
      const wt = WordTimestamp(word: 'Unstoppable', startOffsetMs: 250, durationMs: 400);
      final json = wt.toJson();

      expect(json['word'], equals('Unstoppable'));
      expect(json['startOffsetMs'], equals(250));
      expect(json['durationMs'], equals(400));

      final restored = WordTimestamp.fromJson(json);
      expect(restored.word, equals('Unstoppable'));
      expect(restored.startOffsetMs, equals(250));
      expect(restored.durationMs, equals(400));
    });

    test('CaptionLine.generateInterpolatedWords correctly calculates word timings', () {
      const text = 'Create high impact viral reels';
      const durationMs = 2500;

      final words = CaptionLine.generateInterpolatedWords(text, durationMs);
      expect(words.length, equals(5));
      expect(words[0].word, equals('Create'));
      expect(words[0].startOffsetMs, equals(0));
      expect(words[4].word, equals('reels'));

      // Check monotonicity
      for (int i = 0; i < words.length - 1; i++) {
        expect(words[i + 1].startOffsetMs, greaterThanOrEqualTo(words[i].startOffsetMs));
        expect(words[i].durationMs, greaterThan(0));
      }

      // Check total coverage
      final lastWordEnd = words.last.startOffsetMs + words.last.durationMs;
      expect(lastWordEnd, equals(durationMs));
    });

    test('CaptionLine.getActiveWordIndex pinpoints the exact active word over time', () {
      final caption = CaptionLine(
        id: 'cap_test_1',
        text: 'Antigravity Studio Engine',
        startTimeMs: 1000,
        durationMs: 3000,
        style: const TextOverlayConfig(text: 'Antigravity Studio Engine'),
        words: const [
          WordTimestamp(word: 'Antigravity', startOffsetMs: 0, durationMs: 1000),
          WordTimestamp(word: 'Studio', startOffsetMs: 1000, durationMs: 1000),
          WordTimestamp(word: 'Engine', startOffsetMs: 2000, durationMs: 1000),
        ],
      );

      // Before start
      expect(caption.getActiveWordIndex(-50), equals(-1));

      // Word 1: 0 - 999 ms
      expect(caption.getActiveWordIndex(0), equals(0));
      expect(caption.getActiveWordIndex(500), equals(0));
      expect(caption.getActiveWordIndex(999), equals(0));

      // Word 2: 1000 - 1999 ms
      expect(caption.getActiveWordIndex(1000), equals(1));
      expect(caption.getActiveWordIndex(1500), equals(1));

      // Word 3: 2000 - 3000 ms
      expect(caption.getActiveWordIndex(2000), equals(2));
      expect(caption.getActiveWordIndex(2800), equals(2));

      // Past the end should cap to the last word
      expect(caption.getActiveWordIndex(3500), equals(2));
    });

    test('CaptionLine JSON serialization preserves all kinetic and styling attributes', () {
      final line = CaptionLine(
        id: 'kinetic_101',
        text: 'Boost your video workflow',
        startTimeMs: 500,
        durationMs: 2000,
        style: const TextOverlayConfig(
          text: 'Boost your video workflow',
          fontFamily: 'Anton',
          fontSize: 32.0,
          textColor: 0xFFFFFFFF,
        ),
        words: const [
          WordTimestamp(word: 'Boost', startOffsetMs: 0, durationMs: 500),
          WordTimestamp(word: 'your', startOffsetMs: 500, durationMs: 400),
          WordTimestamp(word: 'video', startOffsetMs: 900, durationMs: 500),
          WordTimestamp(word: 'workflow', startOffsetMs: 1400, durationMs: 600),
        ],
        highlightStyle: KaraokeHighlightStyle.pillBackground,
        highlightColor: 0xFF00FF66,
        highlightScale: 1.35,
        isKinetic: true,
      );

      final json = line.toJson();
      expect(json['id'], equals('kinetic_101'));
      expect(json['highlightStyle'], equals('pillBackground'));
      expect(json['highlightColor'], equals(0xFF00FF66));
      expect(json['highlightScale'], equals(1.35));
      expect(json['isKinetic'], isTrue);
      expect((json['words'] as List).length, equals(4));

      final restored = CaptionLine.fromJson(json);
      expect(restored.id, equals(line.id));
      expect(restored.text, equals(line.text));
      expect(restored.highlightStyle, equals(KaraokeHighlightStyle.pillBackground));
      expect(restored.highlightColor, equals(0xFF00FF66));
      expect(restored.highlightScale, equals(1.35));
      expect(restored.isKinetic, isTrue);
      expect(restored.words.length, equals(4));
      expect(restored.words[0].word, equals('Boost'));
    });

    test('SrtSubtitleService parses standard SubRip format and WebVTT roundtrip', () {
      const srtInput = '''1
00:00:01,000 --> 00:00:03,500
Welcome to Edito Pro

2
00:00:04,250 --> 00:00:07,000
Cinematic kinetic captions with word syncing
''';

      final captions = SrtSubtitleService.parseSrt(srtInput);
      expect(captions.length, equals(2));

      // Caption 1
      expect(captions[0].text, equals('Welcome to Edito Pro'));
      expect(captions[0].startTimeMs, equals(1000));
      expect(captions[0].endTimeMs, equals(3500));
      expect(captions[0].durationMs, equals(2500));
      expect(captions[0].words.length, equals(4));

      // Caption 2
      expect(captions[1].text, equals('Cinematic kinetic captions with word syncing'));
      expect(captions[1].startTimeMs, equals(4250));
      expect(captions[1].endTimeMs, equals(7000));
      expect(captions[1].words.length, equals(6));

      // Test export to SRT
      final exportedSrt = SrtSubtitleService.exportToSrt(captions);
      expect(exportedSrt, contains('1'));
      expect(exportedSrt, contains('00:00:01,000 --> 00:00:03,500'));
      expect(exportedSrt, contains('Welcome to Edito Pro'));
      expect(exportedSrt, contains('00:00:04,250 --> 00:00:07,000'));

      // Test export to VTT
      final exportedVtt = SrtSubtitleService.exportToVtt(captions);
      expect(exportedVtt, startsWith('WEBVTT'));
      expect(exportedVtt, contains('00:00:01.000 --> 00:00:03.500'));
      expect(exportedVtt, contains('Welcome to Edito Pro'));
    });

    test('CaptionCompilerService compiles timed FFmpeg drawtext filter chains', () {
      final captions = [
        CaptionLine(
          id: 'c1',
          text: "Edito's Next Gen Engine",
          startTimeMs: 1000,
          durationMs: 3000,
          style: const TextOverlayConfig(
            text: "Edito's Next Gen Engine",
            fontSize: 28.0,
            textColor: 0xFFFFFFFF,
            positionX: 0.5,
            positionY: 0.85,
            backgroundColor: 0xCC000000,
            boxPadding: 10.0,
          ),
          highlightStyle: KaraokeHighlightStyle.colorFill,
          isKinetic: true,
        ),
      ];

      final filters = CaptionCompilerService.generateFFmpegDrawTextFilters(
        captions,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filters.length, equals(1));
      final f = filters.first;
      expect(f, startsWith('drawtext='));
      expect(f, contains("text='Edito\\'s Next Gen Engine'"));
      expect(f, contains("enable='between(t,1.00,4.00)'"));
      expect(f, contains('box=1'));

      final badgeKinetic = CaptionCompilerService.getCaptionsBadge(captions);
      expect(badgeKinetic, equals('⚡ KINETIC CAPTIONS (1)'));

      final badgeEmpty = CaptionCompilerService.getCaptionsBadge([]);
      expect(badgeEmpty, isEmpty);
    });

    test('AutoCaptionService seamlessly syncs kinetic captions to project tracks and back', () {
      final initialProject = Project(
        id: 'proj_kinetic_test',
        title: 'Kinetic Project',
        tracks: [
          Track(
            id: 't_video',
            type: TrackType.video,
            clips: [
              Clip(
                id: 'c_vid',
                assetId: 'a1',
                trackId: 't_video',
                startTimeMs: 0,
                durationMs: 8000,
              ),
            ],
          ),
        ],
      );

      final generated = AutoCaptionService.generateAutoCaptions(initialProject);
      expect(generated.isNotEmpty, isTrue);
      expect(generated.first.words.isNotEmpty, isTrue);

      final syncedProject = AutoCaptionService.syncCaptionsToProject(initialProject, generated);
      final captionTrack = syncedProject.tracks.firstWhere((t) => t.type == TrackType.text && t.name == 'Captions');
      expect(captionTrack, isNotNull);
      expect(captionTrack.clips.length, equals(generated.length));
      expect(captionTrack.clips.first.textOverlay.animationType, equals(TextAnimationType.karaoke));

      // Extract back from project
      final extracted = AutoCaptionService.extractCaptionsFromProject(syncedProject);
      expect(extracted.length, equals(generated.length));
      expect(extracted.first.text, equals(generated.first.text));
      expect(extracted.first.words.isNotEmpty, isTrue);
    });
  });
}
