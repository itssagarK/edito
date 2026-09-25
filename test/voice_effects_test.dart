import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/voice_effects/models/voice_effects_config.dart';
import 'package:edito/features/voice_effects/services/voice_effects_compiler_service.dart';
import 'package:edito/features/voice_effects/presentation/widgets/voice_effects_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 31: CapCut Pro AI Voice Changer & Audio Timbre Morphing Studio Suite Tests', () {
    test('VoiceEffectCharacter enums provide accurate labels, descriptions, and categories', () {
      expect(VoiceEffectCharacter.none.label, equals('Original'));
      expect(VoiceEffectCharacter.chipmunk.label, equals('Chipmunk'));
      expect(VoiceEffectCharacter.deepMonster.label, equals('Deep Monster'));
      expect(VoiceEffectCharacter.robotVocoder.label, equals('Robot Vocoder'));
      expect(VoiceEffectCharacter.echoCave.label, equals('Cavern Echo'));
      expect(VoiceEffectCharacter.heliumBalloon.label, equals('Helium Squeak'));
      expect(VoiceEffectCharacter.retroRadio.label, equals('Retro Walkie'));
      expect(VoiceEffectCharacter.vinylLofi.label, equals('Vinyl Lo-Fi'));
      expect(VoiceEffectCharacter.megaphone.label, equals('Megaphone'));
      expect(VoiceEffectCharacter.synthAlien.label, equals('Synth Alien'));
      expect(VoiceEffectCharacter.custom.label, equals('Custom Timbre'));

      expect(VoiceEffectCharacter.chipmunk.category, equals(VoiceEffectCategory.characters));
      expect(VoiceEffectCharacter.deepMonster.category, equals(VoiceEffectCategory.characters));
      expect(VoiceEffectCharacter.retroRadio.category, equals(VoiceEffectCategory.retro));
      expect(VoiceEffectCharacter.vinylLofi.category, equals(VoiceEffectCategory.retro));
      expect(VoiceEffectCharacter.megaphone.category, equals(VoiceEffectCategory.retro));
      expect(VoiceEffectCharacter.echoCave.category, equals(VoiceEffectCategory.spatial));
      expect(VoiceEffectCharacter.custom.category, equals(VoiceEffectCategory.custom));

      expect(VoiceEffectCategory.all.label, equals('All'));
      expect(VoiceEffectCategory.characters.label, equals('Characters'));
      expect(VoiceEffectCategory.retro.label, equals('Retro & Lo-Fi'));
      expect(VoiceEffectCategory.spatial.label, equals('Spatial Reverb'));
      expect(VoiceEffectCategory.custom.label, equals('Custom'));
    });

    test('VoiceEffectsConfig default constructor and preset factory initialize correctly', () {
      const defaultConfig = VoiceEffectsConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.character, equals(VoiceEffectCharacter.none));
      expect(defaultConfig.pitchSemitones, equals(0.0));
      expect(defaultConfig.formantShift, equals(1.0));
      expect(defaultConfig.timbreResonance, equals(0.0));
      expect(defaultConfig.vibratoDepth, equals(0.0));
      expect(defaultConfig.echoDelayMs, equals(0));
      expect(defaultConfig.distortion, equals(0.0));
      expect(defaultConfig.mix, equals(1.0));
      expect(defaultConfig.badge, isEmpty);

      final chipmunk = VoiceEffectsConfig.preset(VoiceEffectCharacter.chipmunk);
      expect(chipmunk.isEnabled, isTrue);
      expect(chipmunk.character, equals(VoiceEffectCharacter.chipmunk));
      expect(chipmunk.pitchSemitones, equals(8.0));
      expect(chipmunk.badge, equals('VOICE: CHIPMUNK'));

      final monster = VoiceEffectsConfig.preset(VoiceEffectCharacter.deepMonster);
      expect(monster.isEnabled, isTrue);
      expect(monster.character, equals(VoiceEffectCharacter.deepMonster));
      expect(monster.pitchSemitones, equals(-8.0));
      expect(monster.badge, equals('VOICE: DEEP MONSTER'));

      final robot = VoiceEffectsConfig.preset(VoiceEffectCharacter.robotVocoder);
      expect(robot.isEnabled, isTrue);
      expect(robot.character, equals(VoiceEffectCharacter.robotVocoder));
      expect(robot.vibratoDepth, equals(0.5));
      expect(robot.badge, equals('VOICE: ROBOT VOCODER'));

      final echo = VoiceEffectsConfig.preset(VoiceEffectCharacter.echoCave);
      expect(echo.isEnabled, isTrue);
      expect(echo.character, equals(VoiceEffectCharacter.echoCave));
      expect(echo.echoDelayMs, equals(250));
      expect(echo.echoFeedback, equals(0.55));
      expect(echo.badge, equals('VOICE: CAVERN ECHO'));

      final nonePreset = VoiceEffectsConfig.preset(VoiceEffectCharacter.none);
      expect(nonePreset.isEnabled, isFalse);
      expect(nonePreset.character, equals(VoiceEffectCharacter.none));
    });

    test('VoiceEffectsConfig JSON serialization and copyWith integrity', () {
      const original = VoiceEffectsConfig(
        isEnabled: true,
        character: VoiceEffectCharacter.retroRadio,
        pitchSemitones: -2.0,
        formantShift: 0.9,
        timbreResonance: 0.4,
        vibratoDepth: 0.2,
        vibratoRate: 6.0,
        echoDelayMs: 120,
        echoFeedback: 0.35,
        distortion: 0.5,
        mix: 0.85,
        lowCutHz: 350.0,
        highCutHz: 4500.0,
      );

      final json = original.toJson();
      final restored = VoiceEffectsConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.character, equals(VoiceEffectCharacter.retroRadio));
      expect(restored.pitchSemitones, equals(-2.0));
      expect(restored.formantShift, equals(0.9));
      expect(restored.timbreResonance, equals(0.4));
      expect(restored.vibratoDepth, equals(0.2));
      expect(restored.vibratoRate, equals(6.0));
      expect(restored.echoDelayMs, equals(120));
      expect(restored.echoFeedback, equals(0.35));
      expect(restored.distortion, equals(0.5));
      expect(restored.mix, equals(0.85));
      expect(restored.lowCutHz, equals(350.0));
      expect(restored.highCutHz, equals(4500.0));
      expect(restored, equals(original));

      final updated = original.copyWith(pitchSemitones: 4.0, mix: 1.0);
      expect(updated.pitchSemitones, equals(4.0));
      expect(updated.mix, equals(1.0));
      expect(updated.character, equals(VoiceEffectCharacter.retroRadio));
    });

    test('VoiceEffectsCompilerService generates deterministic FFmpeg filters and enforces Rule 4 limiter', () {
      const disabled = VoiceEffectsConfig();
      expect(VoiceEffectsCompilerService.generateFFmpegFilters(disabled), isEmpty);

      // 1. Chipmunk (+8 semitones)
      final chipmunk = VoiceEffectsConfig.preset(VoiceEffectCharacter.chipmunk);
      final chipmunkFilters = VoiceEffectsCompilerService.generateFFmpegFilters(chipmunk);
      expect(chipmunkFilters.any((f) => f.contains('asetrate=') && f.contains('aresample=44100')), isTrue);
      expect(chipmunkFilters.any((f) => f.contains('atempo=')), isTrue);
      expect(chipmunkFilters.any((f) => f.contains('alimiter=limit=0.95:attack=5:release=50:asc=1')), isTrue);

      // 2. Deep Monster (-8 semitones)
      final monster = VoiceEffectsConfig.preset(VoiceEffectCharacter.deepMonster);
      final monsterFilters = VoiceEffectsCompilerService.generateFFmpegFilters(monster);
      expect(monsterFilters.any((f) => f.contains('asetrate=') && f.contains('aresample=44100')), isTrue);
      expect(monsterFilters.any((f) => f.contains('highpass=f=60')), isTrue);
      expect(monsterFilters.any((f) => f.contains('lowpass=f=4500')), isTrue);
      expect(monsterFilters.any((f) => f.contains('equalizer=f=350')), isTrue);
      expect(monsterFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 3. Robot Vocoder
      final robot = VoiceEffectsConfig.preset(VoiceEffectCharacter.robotVocoder);
      final robotFilters = VoiceEffectsCompilerService.generateFFmpegFilters(robot);
      expect(robotFilters.any((f) => f.contains('vibrato=f=12.0:d=0.50')), isTrue);
      expect(robotFilters.any((f) => f.contains('equalizer=f=2200')), isTrue);
      expect(robotFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 4. Cavern Echo
      final echo = VoiceEffectsConfig.preset(VoiceEffectCharacter.echoCave);
      final echoFilters = VoiceEffectsCompilerService.generateFFmpegFilters(echo);
      expect(echoFilters.any((f) => f.contains('aecho=0.8:0.88:250:0.55')), isTrue);
      expect(echoFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 5. Retro Radio with Distortion
      final radio = VoiceEffectsConfig.preset(VoiceEffectCharacter.retroRadio);
      final radioFilters = VoiceEffectsCompilerService.generateFFmpegFilters(radio);
      expect(radioFilters.any((f) => f.contains('acrusher=bits=')), isTrue);
      expect(radioFilters.any((f) => f.contains('highpass=f=400')), isTrue);
      expect(radioFilters.any((f) => f.contains('lowpass=f=3500')), isTrue);
      expect(radioFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);
    });

    test('Clip model integrates VoiceEffectsConfig properly', () {
      const clip = Clip(
        id: 'clip_voice_01',
        assetId: 'asset_audio_01',
        trackId: 'track_audio_01',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );
      expect(clip.voiceEffects.isEnabled, isFalse);

      final chipmunkPreset = VoiceEffectsConfig.preset(VoiceEffectCharacter.chipmunk);
      final modifiedClip = clip.copyWith(voiceEffects: chipmunkPreset);
      expect(modifiedClip.voiceEffects.isEnabled, isTrue);
      expect(modifiedClip.voiceEffects.character, equals(VoiceEffectCharacter.chipmunk));
      expect(modifiedClip.voiceEffects.pitchSemitones, equals(8.0));

      final json = modifiedClip.toJson();
      final fromJsonClip = Clip.fromJson(json);
      expect(fromJsonClip.voiceEffects, equals(chipmunkPreset));
    });

    test('FFmpegCommandBuilder integrates Voice Effects into deterministic audio DSP graph', () {
      const asset = MediaAsset(
        id: 'asset_audio_01',
        path: '/storage/media/dialogue.mp4',
        fileName: 'dialogue.mp4',
        type: MediaType.video,
        durationMs: 5000,
        hasAudio: true,
      );

      final clipWithVoice = Clip(
        id: 'clip_01',
        assetId: asset.id,
        trackId: 'track_v01',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        voiceEffects: VoiceEffectsConfig.preset(VoiceEffectCharacter.chipmunk),
      );

      final project = Project(
        id: 'proj_01',
        name: 'Voice Effects Test Project',
        durationMs: 5000,
        assets: [asset],
        tracks: [
          Track(
            id: 'track_v01',
            name: 'Video & Audio Track',
            type: TrackType.video,
            order: 0,
            clips: [clipWithVoice],
          ),
        ],
      );

      final result = FFmpegCommandBuilder.buildCommand(
        project: project,
        outputPath: '/storage/export/voice_test.mp4',
        config: ExportPreset.highQuality1080p,
      );

      // Verify that the filter_complex contains pitch modulation and true-peak limiter
      expect(result.command, contains('asetrate='));
      expect(result.command, contains('aresample=44100'));
      expect(result.command, contains('atempo='));
      expect(result.command, contains('alimiter=limit=0.95:attack=5:release=50:asc=1'));
    });

    testWidgets('VoiceEffectsSheet renders presets, allows character selection, and updates config', (tester) async {
      VoiceEffectsConfig currentConfig = const VoiceEffectsConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceEffectsSheet(
              initialConfig: currentConfig,
              onApply: (cfg) {
                currentConfig = cfg;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('voice_effects_sheet')), findsOneWidget);
      expect(find.text('CapCut Pro Voice Changer'), findsOneWidget);
      expect(find.text('Standard Vocal Pass'), findsOneWidget);

      // 1. Select Chipmunk Character Preset
      final chipmunkFinder = find.byKey(const ValueKey('voice_effect_character_chipmunk'));
      expect(chipmunkFinder, findsOneWidget);
      await tester.tap(chipmunkFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isTrue);
      expect(currentConfig.character, equals(VoiceEffectCharacter.chipmunk));
      expect(currentConfig.pitchSemitones, equals(8.0));
      expect(find.text('VOICE: CHIPMUNK'), findsOneWidget);

      // 2. Select Cavern Echo Preset
      final echoFinder = find.byKey(const ValueKey('voice_effect_character_echoCave'));
      expect(echoFinder, findsOneWidget);
      await tester.tap(echoFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isTrue);
      expect(currentConfig.character, equals(VoiceEffectCharacter.echoCave));
      expect(currentConfig.echoDelayMs, equals(250));
      expect(find.text('VOICE: CAVERN ECHO'), findsOneWidget);

      // 3. Test Hold to Compare
      final compareFinder = find.byKey(const ValueKey('voice_effects_hold_to_compare'));
      expect(compareFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(compareFinder));
      await tester.pump();
      expect(find.text('Raw Audio Bypass (Comparing)'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(find.text('VOICE: CAVERN ECHO'), findsOneWidget);

      // 4. Test Reset Button
      final resetFinder = find.byKey(const ValueKey('voice_effects_reset_button'));
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isFalse);
      expect(currentConfig.character, equals(VoiceEffectCharacter.none));
      expect(find.text('Standard Vocal Pass'), findsOneWidget);
    });
  });
}
