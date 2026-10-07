import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/overlays/models/typewriter_title_config.dart';
import 'package:edito/features/overlays/models/text_overlay_config.dart';
import 'package:edito/features/overlays/services/typewriter_title_service.dart';
import 'package:edito/features/vfx/models/crt_scanline_config.dart';
import 'package:edito/features/vfx/services/crt_scanline_compiler_service.dart';
import 'package:edito/features/audio/models/reverb_chamber_config.dart';
import 'package:edito/features/audio/services/reverb_compiler_service.dart';

void main() {
  group('Phase 16: Feature 16.1 - Kinetic Typewriter Studio', () {
    test('TypewriterTitleConfig default values and presets', () {
      const config = TypewriterTitleConfig();
      expect(config.isEnabled, isFalse);
      expect(config.mode, equals(TypewriterMode.charByChar));
      expect(config.cursorStyle, equals(TypewriterCursorStyle.line));
      expect(config.typingSpeedMs, equals(45));
      expect(config.startDelayMs, equals(150));
      expect(config.keepCursorAfterTyping, isTrue);

      expect(TypewriterTitleConfig.techTerminal.mode, equals(TypewriterMode.charByChar));
      expect(TypewriterTitleConfig.techTerminal.cursorStyle, equals(TypewriterCursorStyle.underscore));
      expect(TypewriterTitleConfig.tiktokPunch.mode, equals(TypewriterMode.wordByWord));
      expect(TypewriterTitleConfig.hackerMatrix.mode, equals(TypewriterMode.terminalGlitch));
      expect(TypewriterTitleConfig.cinematicNoir.cursorStyle, equals(TypewriterCursorStyle.line));
    });

    test('Typewriter text slicing math and progressive reveal', () {
      const config = TypewriterTitleConfig(
        isEnabled: true,
        mode: TypewriterMode.charByChar,
        typingSpeedMs: 50,
        startDelayMs: 100,
      );

      const text = 'HELLO WORLD';
      // Before start delay: empty
      expect(config.getDisplayText(text, 50), equals(''));
      // At start delay: empty (0 chars)
      expect(config.getDisplayText(text, 100), equals(''));
      // 1 char after 50ms: 'H'
      expect(config.getDisplayText(text, 150), equals('H'));
      // 3 chars after 150ms: 'HEL'
      expect(config.getDisplayText(text, 250), equals('HEL'));
      // Fully revealed
      expect(config.getDisplayText(text, 1000), equals('HELLO WORLD'));
      expect(config.isTypingComplete(text, 1000), isTrue);
    });

    test('Typewriter word-by-word reveal', () {
      const config = TypewriterTitleConfig(
        isEnabled: true,
        mode: TypewriterMode.wordByWord,
        typingSpeedMs: 200,
        startDelayMs: 100,
      );

      const text = 'THE QUICK BROWN FOX';
      // Before start delay
      expect(config.getDisplayText(text, 50), equals(''));
      // 1 word
      expect(config.getDisplayText(text, 300), equals('THE'));
      // 2 words
      expect(config.getDisplayText(text, 500), equals('THE QUICK'));
      // All words
      expect(config.getDisplayText(text, 1200), equals('THE QUICK BROWN FOX'));
    });

    test('Typewriter cursor glyphs and blinking', () {
      const config = TypewriterTitleConfig(
        isEnabled: true,
        cursorStyle: TypewriterCursorStyle.block,
        startDelayMs: 100,
        cursorBlinkPeriodMs: 400,
      );

      expect(TypewriterCursorStyle.block.glyph, equals('█'));
      expect(TypewriterCursorStyle.line.glyph, equals('|'));
      expect(TypewriterCursorStyle.underscore.glyph, equals('_'));

      final cursor = config.getActiveCursor(500, 3000, textLength: 10);
      expect(cursor, anyOf(equals('█'), equals(' ')));
    });

    test('TypewriterTitleService FFmpeg drawtext and timestamps', () {
      const clip = Clip(
        id: 'clip_t1',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      const typeConfig = TypewriterTitleConfig(
        isEnabled: true,
        typingSpeedMs: 40,
        startDelayMs: 200,
      );

      const textConfig = TextOverlayConfig(
        text: 'BREAKING NEWS',
        fontSize: 32,
      );

      final filters = TypewriterTitleService.generateFFmpegFilters(
        clip: clip,
        typewriterConfig: typeConfig,
        textConfig: textConfig,
      );

      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('drawtext=text=\'BREAKING NEWS\'')), isTrue);
      expect(filters.any((f) => f.contains('alpha=')), isTrue);

      final timestamps = TypewriterTitleService.generateTypingClickTimestamps(
        text: 'HELLO',
        config: typeConfig,
      );
      expect(timestamps.length, equals(5));
      expect(timestamps[0], equals(200));
      expect(timestamps[1], equals(240));

      final badge = TypewriterTitleService.getTypewriterBadge(typeConfig);
      expect(badge, contains('TYPEWRITER'));
    });

    test('TypewriterTitleConfig JSON serialization', () {
      const config = TypewriterTitleConfig(
        isEnabled: true,
        mode: TypewriterMode.terminalGlitch,
        cursorStyle: TypewriterCursorStyle.caret,
        typingSpeedMs: 60,
        startDelayMs: 250,
        wordHighlightColor: 0xFF00FF66,
      );

      final json = config.toJson();
      final revived = TypewriterTitleConfig.fromJson(json);

      expect(revived.isEnabled, isTrue);
      expect(revived.mode, equals(TypewriterMode.terminalGlitch));
      expect(revived.cursorStyle, equals(TypewriterCursorStyle.caret));
      expect(revived.typingSpeedMs, equals(60));
      expect(revived.startDelayMs, equals(250));
      expect(revived.wordHighlightColor, equals(0xFF00FF66));
    });
  });

  group('Phase 16: Feature 16.2 - Retro CRT Scanlines Studio', () {
    test('CrtScanlineConfig defaults and presets', () {
      const config = CrtScanlineConfig();
      expect(config.isEnabled, isFalse);
      expect(config.scanlinePitch, equals(4.0));
      expect(config.scanlineOpacity, equals(0.40));
      expect(config.rollingBarSpeed, equals(1.0));
      expect(config.phosphorTint, equals(CrtPhosphorTint.none));

      expect(CrtScanlineConfig.arcade1984.phosphorTint, equals(CrtPhosphorTint.cyanTrinitron));
      expect(CrtScanlineConfig.cyberpunkTerminal.phosphorTint, equals(CrtPhosphorTint.greenPhosphorP1));
      expect(CrtScanlineConfig.vhsCamcorder1995.phosphorTint, equals(CrtPhosphorTint.amberClassic));
      expect(CrtScanlineConfig.securityCctv.phosphorTint, equals(CrtPhosphorTint.bwSecurity));
    });

    test('CrtPhosphorTint color matrices and labels', () {
      expect(CrtPhosphorTint.greenPhosphorP1.colorHex, equals(0xFF00FF66));
      expect(CrtPhosphorTint.amberClassic.colorHex, equals(0xFFFFB000));
      expect(CrtPhosphorTint.cyanTrinitron.colorHex, equals(0xFF00F0FF));

      expect(CrtPhosphorTint.greenPhosphorP1.ffmpegMatrixFilter, contains('colorchannelmixer='));
      expect(CrtPhosphorTint.amberClassic.ffmpegMatrixFilter, contains('colorchannelmixer='));
    });

    test('CrtScanlineCompilerService filter generation', () {
      const config = CrtScanlineConfig(
        isEnabled: true,
        scanlinePitch: 4.0,
        scanlineOpacity: 0.50,
        phosphorTint: CrtPhosphorTint.greenPhosphorP1,
        rgbShadowOffset: 4.0,
        screenCurvature: 0.40,
        analogNoise: 0.20,
      );

      final filters = CrtScanlineCompilerService.generateFFmpegFilters(config);

      expect(filters, isNotEmpty);
      expect(filters.any((f) => f.contains('colorchannelmixer=')), isTrue);
      expect(filters.any((f) => f.contains('rgbashift=rh=4:bh=-4')), isTrue);
      expect(filters.any((f) => f.contains('drawgrid=w=iw:h=4:t=1:c=black@0.50')), isTrue);
      expect(filters.any((f) => f.contains('vignette=')), isTrue);
      expect(filters.any((f) => f.contains('noise=')), isTrue);

      final badge = CrtScanlineCompilerService.getCrtBadge(config);
      expect(badge, contains('CRT SCANLINES'));
      expect(badge, contains('IBM 5151'));
    });

    test('CrtScanlineConfig JSON serialization', () {
      const config = CrtScanlineConfig(
        isEnabled: true,
        scanlinePitch: 5.5,
        scanlineOpacity: 0.65,
        rollingBarSpeed: 1.8,
        phosphorTint: CrtPhosphorTint.vaporwavePink,
      );

      final json = config.toJson();
      final revived = CrtScanlineConfig.fromJson(json);

      expect(revived.isEnabled, isTrue);
      expect(revived.scanlinePitch, equals(5.5));
      expect(revived.scanlineOpacity, equals(0.65));
      expect(revived.rollingBarSpeed, equals(1.8));
      expect(revived.phosphorTint, equals(CrtPhosphorTint.vaporwavePink));
    });
  });

  group('Phase 16: Feature 16.3 - Audio Reverb Chamber Studio', () {
    test('ReverbChamberConfig defaults and room presets', () {
      const config = ReverbChamberConfig();
      expect(config.isEnabled, isFalse);
      expect(config.roomType, equals(ReverbRoomType.vocalHall));
      expect(config.wetDryMix, equals(0.35));
      expect(config.decayTimeMs, equals(1600));

      expect(ReverbChamberConfig.studioBooth.roomType, equals(ReverbRoomType.studioBooth));
      expect(ReverbChamberConfig.studioBooth.decayTimeMs, equals(280));
      expect(ReverbChamberConfig.cathedral.roomType, equals(ReverbRoomType.cathedral));
      expect(ReverbChamberConfig.cathedral.decayTimeMs, equals(3400));
      expect(ReverbChamberConfig.plateReverb.damping, equals(0.15));
    });

    test('ReverbCompilerService multi-tap delay and alimiter safeguard', () {
      const config = ReverbChamberConfig(
        isEnabled: true,
        roomType: ReverbRoomType.vocalHall,
        wetDryMix: 0.40,
        decayTimeMs: 1600,
        damping: 0.50,
        stereoWidth: 0.80,
      );

      final filters = ReverbCompilerService.generateFFmpegFilters(config);

      expect(filters, isNotEmpty);
      // Multi-tap aecho
      expect(filters.any((f) => f.contains('aecho=in_gain=1.0:out_gain=')), isTrue);
      // High-frequency damping
      expect(filters.any((f) => f.contains('equalizer=f=8000:width_type=h:width=2500:g=')), isTrue);
      // Stereo spatializer
      expect(filters.any((f) => f.contains('stereotools=slev=')), isTrue);

      // STRICT AGENTS.MD RULE 4 ENFORCEMENT: true-peak brickwall ceiling limiter
      expect(
        filters.any((f) => f.contains('alimiter=limit=0.95:attack=5:release=50:asc=1')),
        isTrue,
        reason: 'Audio boost/reverb must contain alimiter=limit=0.95:attack=5:release=50:asc=1 to prevent digital clipping',
      );

      final badge = ReverbCompilerService.getReverbBadge(config);
      expect(badge, contains('REVERB'));
      expect(badge, contains('Concert Hall'));
      expect(badge, contains('40% WET'));
    });

    test('ReverbChamberConfig JSON serialization', () {
      const config = ReverbChamberConfig(
        isEnabled: true,
        roomType: ReverbRoomType.cyberCavern,
        wetDryMix: 0.45,
        decayTimeMs: 2500,
        damping: 0.35,
        stereoWidth: 0.85,
        preDelayMs: 30.0,
      );

      final json = config.toJson();
      final revived = ReverbChamberConfig.fromJson(json);

      expect(revived.isEnabled, isTrue);
      expect(revived.roomType, equals(ReverbRoomType.cyberCavern));
      expect(revived.wetDryMix, equals(0.45));
      expect(revived.decayTimeMs, equals(2500));
      expect(revived.damping, equals(0.35));
      expect(revived.stereoWidth, equals(0.85));
      expect(revived.preDelayMs, equals(30.0));
    });
  });

  group('Phase 16: Clip Integration & Schema Compatibility', () {
    test('Clip schema backwards compatibility with default Phase 16 configs', () {
      const clip = Clip(
        id: 'clip_p16',
        assetId: 'asset_1',
        trackId: 'track_1',
        startTimeMs: 0,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
      );

      expect(clip.typewriterTitle, equals(const TypewriterTitleConfig()));
      expect(clip.crtScanline, equals(const CrtScanlineConfig()));
      expect(clip.reverb, equals(const ReverbChamberConfig()));
    });

    test('Clip copyWith and JSON roundtrip preserves Phase 16 properties', () {
      const original = Clip(
        id: 'clip_p16_active',
        assetId: 'asset_2',
        trackId: 'track_2',
        startTimeMs: 1000,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      final updated = original.copyWith(
        typewriterTitle: const TypewriterTitleConfig(isEnabled: true, typingSpeedMs: 55),
        crtScanline: const CrtScanlineConfig(isEnabled: true, scanlinePitch: 3.0),
        reverb: const ReverbChamberConfig(isEnabled: true, wetDryMix: 0.50),
      );

      expect(updated.typewriterTitle.isEnabled, isTrue);
      expect(updated.typewriterTitle.typingSpeedMs, equals(55));
      expect(updated.crtScanline.isEnabled, isTrue);
      expect(updated.crtScanline.scanlinePitch, equals(3.0));
      expect(updated.reverb.isEnabled, isTrue);
      expect(updated.reverb.wetDryMix, equals(0.50));

      final json = updated.toJson();
      final revived = Clip.fromJson(json);

      expect(revived.typewriterTitle.isEnabled, isTrue);
      expect(revived.typewriterTitle.typingSpeedMs, equals(55));
      expect(revived.crtScanline.isEnabled, isTrue);
      expect(revived.crtScanline.scanlinePitch, equals(3.0));
      expect(revived.reverb.isEnabled, isTrue);
      expect(revived.reverb.wetDryMix, equals(0.50));
    });
  });
}
