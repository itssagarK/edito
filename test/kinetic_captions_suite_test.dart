import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/captions/models/caption_line.dart';
import 'package:edito/features/captions/models/kinetic_captions_config.dart';
import 'package:edito/features/captions/services/word_level_aligner_service.dart';
import 'package:edito/features/captions/services/caption_compiler_service.dart';
import 'package:edito/features/captions/services/auto_caption_service.dart';
import 'package:edito/features/captions/presentation/widgets/kinetic_caption_overlay.dart';

void main() {
  group('Feature 22: CapCut Pro Kinetic Karaoke Captions Studio Suite Tests', () {
    test('KaraokeHighlightStyle covers all 8 styles with descriptive labels & descriptions', () {
      expect(KaraokeHighlightStyle.values.length, equals(8));
      expect(KaraokeHighlightStyle.none.label, equals('None'));
      expect(KaraokeHighlightStyle.colorFill.label, contains('Color Pop'));
      expect(KaraokeHighlightStyle.scalePunch.label, contains('Scale Bounce'));
      expect(KaraokeHighlightStyle.pillBackground.label, contains('Neon Pill'));
      expect(KaraokeHighlightStyle.glowWave.label, contains('Aura Glow'));
      expect(KaraokeHighlightStyle.neonUnderline.label, contains('Neon Underline'));
      expect(KaraokeHighlightStyle.bouncePop.label, contains('Vertical Bounce'));
      expect(KaraokeHighlightStyle.typewriterReveal.label, contains('Typewriter'));

      for (final style in KaraokeHighlightStyle.values) {
        expect(style.description, isNotEmpty);
      }
    });

    test('KineticCaptionsConfig presets have verified technical properties', () {
      // TikTok Pop
      expect(KineticCaptionsConfig.tiktokPop.isEnabled, isTrue);
      expect(KineticCaptionsConfig.tiktokPop.style, equals(KaraokeHighlightStyle.scalePunch));
      expect(KineticCaptionsConfig.tiktokPop.highlightColor, equals(0xFFFFE600));
      expect(KineticCaptionsConfig.tiktokPop.badge, equals('💥 KINETIC (SCALE BOUNCE)'));

      // Neon Podcast
      expect(KineticCaptionsConfig.neonPodcast.isEnabled, isTrue);
      expect(KineticCaptionsConfig.neonPodcast.style, equals(KaraokeHighlightStyle.glowWave));
      expect(KineticCaptionsConfig.neonPodcast.highlightColor, equals(0xFF00E5FF));
      expect(KineticCaptionsConfig.neonPodcast.badge, equals('✨ KINETIC (AURA GLOW)'));

      // Hormozi Beast
      expect(KineticCaptionsConfig.hormoziBeast.isEnabled, isTrue);
      expect(KineticCaptionsConfig.hormoziBeast.style, equals(KaraokeHighlightStyle.pillBackground));
      expect(KineticCaptionsConfig.hormoziBeast.badge, equals('🏷️ KINETIC (NEON PILL)'));

      // Cyber Pink
      expect(KineticCaptionsConfig.cyberPink.isEnabled, isTrue);
      expect(KineticCaptionsConfig.cyberPink.style, equals(KaraokeHighlightStyle.neonUnderline));
      expect(KineticCaptionsConfig.cyberPink.badge, equals('💖 KINETIC (NEON UNDERLINE)'));

      // Fire Punch
      expect(KineticCaptionsConfig.firePunch.isEnabled, isTrue);
      expect(KineticCaptionsConfig.firePunch.style, equals(KaraokeHighlightStyle.bouncePop));
      expect(KineticCaptionsConfig.firePunch.badge, equals('🚀 KINETIC (BOUNCE POP)'));

      // Cinema Minimal
      expect(KineticCaptionsConfig.cinemaMinimal.isEnabled, isTrue);
      expect(KineticCaptionsConfig.cinemaMinimal.style, equals(KaraokeHighlightStyle.colorFill));
      expect(KineticCaptionsConfig.cinemaMinimal.badge, equals('⚡ KINETIC (COLOR POP)'));

      // Terminal Retro
      expect(KineticCaptionsConfig.terminalRetro.isEnabled, isTrue);
      expect(KineticCaptionsConfig.terminalRetro.style, equals(KaraokeHighlightStyle.typewriterReveal));
      expect(KineticCaptionsConfig.terminalRetro.badge, equals('⌨️ KINETIC (TYPEWRITER)'));
    });

    test('KineticCaptionsConfig serializes to JSON and restores accurately', () {
      const config = KineticCaptionsConfig(
        isEnabled: true,
        style: KaraokeHighlightStyle.neonUnderline,
        highlightColor: 0xFFFF2A85,
        inactiveColor: 0x88FFFFFF,
        highlightScale: 1.35,
        inactiveOpacity: 0.45,
        glowRadius: 18.0,
        isUppercase: true,
        words: [
          WordTimestamp(word: 'Viral', startOffsetMs: 0, durationMs: 400),
          WordTimestamp(word: 'Growth', startOffsetMs: 400, durationMs: 600),
        ],
      );

      final json = config.toJson();
      expect(json['isEnabled'], isTrue);
      expect(json['style'], equals('neonUnderline'));
      expect(json['highlightColor'], equals(0xFFFF2A85));
      expect(json['highlightScale'], equals(1.35));
      expect(json['inactiveOpacity'], equals(0.45));
      expect(json['glowRadius'], equals(18.0));
      expect(json['isUppercase'], isTrue);
      expect((json['words'] as List).length, equals(2));

      final restored = KineticCaptionsConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('WordLevelAlignerService generates weighted word durations matching speech cadence', () {
      const sentence = 'In the beginning, extraordinary moments created everything!';
      const totalDurMs = 4000;

      final words = WordLevelAlignerService.generateWeightedWords(sentence, totalDurMs);
      expect(words.length, equals(7));

      // Monotonicity check
      for (int i = 0; i < words.length - 1; i++) {
        expect(words[i + 1].startOffsetMs, greaterThanOrEqualTo(words[i].startOffsetMs));
        expect(words[i].durationMs, greaterThan(0));
      }

      // Check total coverage
      final lastWordEnd = words.last.startOffsetMs + words.last.durationMs;
      expect(lastWordEnd, equals(totalDurMs));

      // 'extraordinary' should receive significantly more duration than 'In' or 'the'
      final shortWordDur = words.firstWhere((w) => w.word.toLowerCase() == 'in').durationMs;
      final longWordDur = words.firstWhere((w) => w.word.toLowerCase() == 'extraordinary').durationMs;
      expect(longWordDur, greaterThan(shortWordDur));

      // 'beginning,' has comma punctuation which gets breath pause weight
      final punctuatedDur = words.firstWhere((w) => w.word == 'beginning,').durationMs;
      expect(punctuatedDur, greaterThan(shortWordDur));
    });

    test('WordLevelAlignerService spring scale and vertical bounce calculate smooth trajectories', () {
      const word = WordTimestamp(word: 'Punch', startOffsetMs: 1000, durationMs: 800);

      // Outside window
      expect(WordLevelAlignerService.calculateSpringScale(offsetMs: 500, word: word, targetScale: 1.30), equals(1.0));
      expect(WordLevelAlignerService.calculateVerticalBounce(offsetMs: 500, word: word), equals(0.0));

      // Inside spring punch window (1000ms + 100ms)
      final scalePeak = WordLevelAlignerService.calculateSpringScale(offsetMs: 1100, word: word, targetScale: 1.30);
      expect(scalePeak, greaterThan(1.10));

      // Vertical bounce should be negative (upward translation)
      final bounce = WordLevelAlignerService.calculateVerticalBounce(offsetMs: 1100, word: word, maxBouncePixels: 8.0);
      expect(bounce, lessThan(0.0));
    });

    test('CaptionLine loss-lessly converts to timeline Clip and back', () {
      final line = CaptionLine(
        id: 'cap_roundtrip_1',
        text: 'Mastering CapCut Pro Workflows',
        startTimeMs: 1500,
        durationMs: 3200,
        style: const TextOverlayConfig(
          text: 'Mastering CapCut Pro Workflows',
          fontFamily: 'Montserrat',
          fontSize: 32.0,
          textColor: 0xFFFFFFFF,
        ),
        words: const [
          WordTimestamp(word: 'Mastering', startOffsetMs: 0, durationMs: 800),
          WordTimestamp(word: 'CapCut', startOffsetMs: 800, durationMs: 700),
          WordTimestamp(word: 'Pro', startOffsetMs: 1500, durationMs: 500),
          WordTimestamp(word: 'Workflows', startOffsetMs: 2000, durationMs: 1200),
        ],
        highlightStyle: KaraokeHighlightStyle.neonUnderline,
        highlightColor: 0xFFFF2A85,
        inactiveColor: 0x88FFFFFF,
        highlightScale: 1.25,
        inactiveOpacity: 0.50,
        glowRadius: 16.0,
        isKinetic: true,
      );

      // Convert to Clip
      final clip = line.toClip('track_captions_1');
      expect(clip.id, equals('cap_roundtrip_1'));
      expect(clip.trackId, equals('track_captions_1'));
      expect(clip.startTimeMs, equals(1500));
      expect(clip.durationMs, equals(3200));
      expect(clip.kineticCaptions.isEnabled, isTrue);
      expect(clip.kineticCaptions.style, equals(KaraokeHighlightStyle.neonUnderline));
      expect(clip.kineticCaptions.highlightColor, equals(0xFFFF2A85));

      // Reconstruct back to CaptionLine
      final restoredLine = CaptionLine.fromClip(clip);
      expect(restoredLine.id, equals(line.id));
      expect(restoredLine.text, equals(line.text));
      expect(restoredLine.highlightStyle, equals(KaraokeHighlightStyle.neonUnderline));
      expect(restoredLine.highlightColor, equals(0xFFFF2A85));
      expect(restoredLine.highlightScale, equals(1.25));
      expect(restoredLine.words.length, equals(4));
      expect(restoredLine.words[1].word, equals('CapCut'));
    });

    test('CaptionCompilerService generates valid ASS karaoke subtitle format', () {
      final captions = [
        CaptionLine(
          id: 'c_ass_1',
          text: 'Super Fast Editing',
          startTimeMs: 1000,
          durationMs: 2500,
          style: const TextOverlayConfig(
            text: 'Super Fast Editing',
            fontFamily: 'Anton',
            fontSize: 34.0,
          ),
          words: const [
            WordTimestamp(word: 'Super', startOffsetMs: 0, durationMs: 600),
            WordTimestamp(word: 'Fast', startOffsetMs: 600, durationMs: 800),
            WordTimestamp(word: 'Editing', startOffsetMs: 1400, durationMs: 1100),
          ],
          highlightStyle: KaraokeHighlightStyle.colorFill,
          highlightColor: 0xFFFFE600,
          isKinetic: true,
        ),
      ];

      final ass = CaptionCompilerService.generateAssSubtitles(captions);
      expect(ass, contains('[Script Info]'));
      expect(ass, contains('[V4+ Styles]'));
      expect(ass, contains('[Events]'));
      expect(ass, contains('Dialogue: 0,0:00:01.00,0:00:03.50,Default,,0,0,0,,{\\k60}Super {\\k80}Fast {\\k110}Editing'));
    });

    test('CaptionCompilerService generates kinetic FFmpeg drawtext filters with bounce expression', () {
      final captions = [
        CaptionLine(
          id: 'c_draw_1',
          text: 'Viral Hook Moment',
          startTimeMs: 2000,
          durationMs: 3000,
          style: const TextOverlayConfig(
            text: 'Viral Hook Moment',
            fontSize: 28.0,
            textColor: 0xFFFFE600,
            positionX: 0.5,
            positionY: 0.85,
            strokeWidth: 2.0,
            strokeColor: 0xFF000000,
          ),
          highlightStyle: KaraokeHighlightStyle.scalePunch,
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
      expect(f, startsWith('drawtext=text=\'Viral Hook Moment\''));
      expect(f, contains('fontsize=\''));
      expect(f, contains('sin(mod(')); // Kinetic bounce expression
      expect(f, contains('borderw='));
      expect(f, contains("enable='between(t,2.00,5.00)'"));
    });

    testWidgets('KineticCaptionOverlay renders active word with highlight style without errors', (tester) async {
      final caption = CaptionLine(
        id: 'widget_cap_1',
        text: 'Elevate Your Creativity',
        startTimeMs: 1000,
        durationMs: 3000,
        style: const TextOverlayConfig(
          text: 'Elevate Your Creativity',
          fontFamily: 'Montserrat',
          fontSize: 24.0,
          textColor: 0xFFFFFFFF,
        ),
        words: const [
          WordTimestamp(word: 'Elevate', startOffsetMs: 0, durationMs: 1000),
          WordTimestamp(word: 'Your', startOffsetMs: 1000, durationMs: 800),
          WordTimestamp(word: 'Creativity', startOffsetMs: 1800, durationMs: 1200),
        ],
        highlightStyle: KaraokeHighlightStyle.neonUnderline,
        highlightColor: 0xFFFF2A85,
        isKinetic: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KineticCaptionOverlay(
              caption: caption,
              offsetMs: 500, // Word 0 'Elevate' active
            ),
          ),
        ),
      );

      expect(find.text('Elevate'), findsOneWidget);
      expect(find.text('Your'), findsOneWidget);
      expect(find.text('Creativity'), findsOneWidget);
    });

    test('AutoCaptionService syncs kinetic captions to timeline track preserving kinetic config', () {
      final initialProject = Project(
        id: 'proj_kinetic_suite',
        title: 'Kinetic Project',
        tracks: [
          Track(
            id: 't_video',
            name: 'Video Track',
            type: TrackType.video,
            clips: [
              Clip(
                id: 'c1',
                assetId: 'a1',
                trackId: 't_video',
                startTimeMs: 0,
                durationMs: 10000,
                sourceInMs: 0,
                sourceOutMs: 10000,
              ),
            ],
          ),
        ],
      );

      final captions = AutoCaptionService.generateAutoCaptions(initialProject);
      expect(captions.isNotEmpty, isTrue);

      final syncedProject = AutoCaptionService.syncCaptionsToProject(initialProject, captions);
      final captionTrack = syncedProject.tracks.firstWhere((t) => t.name == 'Captions');
      expect(captionTrack.clips.first.kineticCaptions.isEnabled, isTrue);

      final extracted = AutoCaptionService.extractCaptionsFromProject(syncedProject);
      expect(extracted.length, equals(captions.length));
      expect(extracted.first.isKinetic, isTrue);

      // Verify ASS export
      final assExport = AutoCaptionService.exportAss(extracted);
      expect(assExport, contains('[Script Info]'));
      expect(assExport, contains('Dialogue:'));
    });
  });
}
