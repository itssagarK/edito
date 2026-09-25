import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/vocal_isolation/models/vocal_isolation_config.dart';
import 'package:edito/features/vocal_isolation/services/vocal_isolation_compiler_service.dart';
import 'package:edito/features/vocal_isolation/presentation/widgets/vocal_isolation_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 27: CapCut Pro AI Vocal Isolation & Audio Stem Splitter Suite Tests', () {
    test('VocalIsolationMode enums provide accurate labels and default gains', () {
      expect(VocalIsolationMode.none.label, equals('Off'));
      expect(VocalIsolationMode.isolateVocals.label, equals('Keep Vocals'));
      expect(VocalIsolationMode.removeVocals.label, equals('Remove Vocals'));
      expect(VocalIsolationMode.voiceBoost.label, equals('Voice Boost'));
      expect(VocalIsolationMode.musicBoost.label, equals('Music Boost'));
      expect(VocalIsolationMode.custom.label, equals('Custom Mix'));

      expect(VocalIsolationMode.isolateVocals.defaultInstrumentalGain, equals(-24.0));
      expect(VocalIsolationMode.removeVocals.defaultVocalGain, equals(-24.0));
      expect(VocalIsolationMode.voiceBoost.defaultVocalGain, equals(6.0));
      expect(VocalIsolationMode.musicBoost.defaultVocalGain, equals(-12.0));
    });

    test('IsolationEngine enums provide correct labels and descriptions', () {
      expect(IsolationEngine.centerChannelPhase.label, equals('M/S Phase Cancellation'));
      expect(IsolationEngine.spectralFormantFilter.label, equals('Speech Formant Filter'));
      expect(IsolationEngine.adaptiveDenoiseGate.label, equals('Spectral Noise Gate'));

      expect(IsolationEngine.centerChannelPhase.description, contains('Mid/Side'));
      expect(IsolationEngine.spectralFormantFilter.description, contains('formant'));
    });

    test('VocalIsolationConfig default constructor and fromMode factory', () {
      const defaultConfig = VocalIsolationConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.mode, equals(VocalIsolationMode.none));
      expect(defaultConfig.engine, equals(IsolationEngine.centerChannelPhase));
      expect(defaultConfig.vocalGain, equals(0.0));
      expect(defaultConfig.speechClarity, equals(0.75));
      expect(defaultConfig.brickwallLimiter, isTrue);

      final isolate = VocalIsolationConfig.fromMode(VocalIsolationMode.isolateVocals);
      expect(isolate.isEnabled, isTrue);
      expect(isolate.mode, equals(VocalIsolationMode.isolateVocals));
      expect(isolate.instrumentalGain, equals(-24.0));

      final karaoke = VocalIsolationConfig.fromMode(VocalIsolationMode.removeVocals);
      expect(karaoke.isEnabled, isTrue);
      expect(karaoke.mode, equals(VocalIsolationMode.removeVocals));
      expect(karaoke.vocalGain, equals(-24.0));

      final noneConfig = VocalIsolationConfig.fromMode(VocalIsolationMode.none);
      expect(noneConfig.isEnabled, isFalse);
    });

    test('VocalIsolationConfig JSON serialization roundtrip preserves all attributes', () {
      const original = VocalIsolationConfig(
        isEnabled: true,
        mode: VocalIsolationMode.isolateVocals,
        engine: IsolationEngine.spectralFormantFilter,
        vocalGain: 4.5,
        instrumentalGain: -18.0,
        speechClarity: 0.85,
        noiseThreshold: -42.0,
        stereoWidth: 1.4,
        brickwallLimiter: true,
      );

      final json = original.toJson();
      final restored = VocalIsolationConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.mode, equals(VocalIsolationMode.isolateVocals));
      expect(restored.engine, equals(IsolationEngine.spectralFormantFilter));
      expect(restored.vocalGain, equals(4.5));
      expect(restored.instrumentalGain, equals(-18.0));
      expect(restored.speechClarity, equals(0.85));
      expect(restored.noiseThreshold, equals(-42.0));
      expect(restored.stereoWidth, equals(1.4));
      expect(restored.brickwallLimiter, isTrue);
      expect(restored, equals(original));
    });

    test('VocalIsolationCompilerService generates deterministic FFmpeg filters and enforces brickwall limiter', () {
      const disabled = VocalIsolationConfig();
      expect(VocalIsolationCompilerService.generateFFmpegFilters(disabled), isEmpty);

      // 1. Isolate Vocals
      final isolateConfig = VocalIsolationConfig.fromMode(VocalIsolationMode.isolateVocals);
      final isolateFilters = VocalIsolationCompilerService.generateFFmpegFilters(isolateConfig);
      expect(isolateFilters.any((f) => f.contains('stereotools=')), isTrue);
      expect(isolateFilters.any((f) => f.contains('highpass=f=220,lowpass=f=4200')), isTrue);
      expect(isolateFilters.any((f) => f.contains('agate=')), isTrue);
      expect(isolateFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 2. Remove Vocals (Karaoke phase subtraction)
      final karaokeConfig = VocalIsolationConfig.fromMode(VocalIsolationMode.removeVocals);
      final karaokeFilters = VocalIsolationCompilerService.generateFFmpegFilters(karaokeConfig);
      expect(karaokeFilters.any((f) => f.contains('pan=stereo|c0=c0-0.95*c1|c1=c1-0.95*c0')), isTrue);
      expect(karaokeFilters.any((f) => f.contains('equalizer=f=1800')), isTrue);
      expect(karaokeFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 3. Voice Boost
      final voiceBoost = VocalIsolationConfig.fromMode(VocalIsolationMode.voiceBoost);
      final voiceFilters = VocalIsolationCompilerService.generateFFmpegFilters(voiceBoost);
      expect(voiceFilters.any((f) => f.contains('equalizer=f=1200')), isTrue);
      expect(voiceFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);

      // 4. Music Boost
      final musicBoost = VocalIsolationConfig.fromMode(VocalIsolationMode.musicBoost);
      final musicFilters = VocalIsolationCompilerService.generateFFmpegFilters(musicBoost);
      expect(musicFilters.any((f) => f.contains('equalizer=f=1500:t=q:w=1.8:g=-8.0')), isTrue);
      expect(musicFilters.any((f) => f.contains('alimiter=limit=0.95')), isTrue);
    });

    test('VocalIsolationCompilerService getVocalIsolationBadge formats informative HUD string', () {
      const disabled = VocalIsolationConfig();
      expect(VocalIsolationCompilerService.getVocalIsolationBadge(disabled), isEmpty);
      expect(disabled.badge, isEmpty);

      final enabled = VocalIsolationConfig.fromMode(VocalIsolationMode.isolateVocals);
      expect(enabled.badge, contains('VOCAL ISOLATION'));
      expect(enabled.badge, contains('KEEP VOCALS'));
    });

    test('FFmpegCommandBuilder integrates vocal isolation audio filters into export pipeline', () {
      final vocalClip = Clip(
        id: 'clip_vocal_01',
        assetId: 'asset_dialogue',
        trackId: 'track_audio_01',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        vocalIsolation: VocalIsolationConfig.fromMode(VocalIsolationMode.isolateVocals),
      );

      final project = Project(
        id: 'proj_vocal_test',
        name: 'Vocal Isolation Test Project',
        assets: const [
          MediaAsset(
            id: 'asset_dialogue',
            path: '/media/interview.mp4',
            fileName: 'interview.mp4',
            type: MediaType.video,
            durationMs: 4000,
            hasAudio: true,
          ),
        ],
        tracks: [
          Track(
            id: 'track_audio_01',
            name: 'Main Video Track',
            type: TrackType.video,
            clips: [vocalClip],
          ),
        ],
      );

      const config = ExportConfiguration(
        outputPath: '/out/isolated_vocals_render.mp4',
      );

      final cmd = FFmpegCommandBuilder.buildArguments(project, config);

      expect(cmd.any((arg) => arg.contains('stereotools=')), isTrue);
      expect(cmd.any((arg) => arg.contains('alimiter=limit=0.95')), isTrue);
    });

    testWidgets('VocalIsolationSheet renders studio controls and responds to mode selection', (tester) async {
      VocalIsolationConfig curConfig = const VocalIsolationConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VocalIsolationSheet(
              initialConfig: curConfig,
              onApply: (newConf) => curConfig = newConf,
            ),
          ),
        ),
      );

      // Verify Header and Visualizer Title
      expect(find.text('AI Vocal Isolation'), findsOneWidget);
      expect(find.text('VOCAL STEM'), findsOneWidget);
      expect(find.text('ACCOMPANIMENT STEM'), findsOneWidget);

      // Verify Mode Cards
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Keep Vocals'), findsOneWidget);
      expect(find.text('Remove Vocals'), findsOneWidget);
      expect(find.text('Voice Boost'), findsOneWidget);
      expect(find.text('Music Boost'), findsOneWidget);
      expect(find.text('Custom Mix'), findsOneWidget);

      // Tap on Keep Vocals
      await tester.tap(find.text('Keep Vocals'));
      await tester.pumpAndSettle();

      expect(curConfig.isEnabled, isTrue);
      expect(curConfig.mode, equals(VocalIsolationMode.isolateVocals));
      expect(curConfig.instrumentalGain, equals(-24.0));

      // Sliders & DSP section should now be visible
      expect(find.text('DSP SEPARATION ENGINE'), findsOneWidget);
      expect(find.text('STEM BALANCE & LEVEL CONTROLS'), findsOneWidget);
      expect(find.text('Vocal Stem Gain'), findsOneWidget);
      expect(find.text('Accompaniment Gain'), findsOneWidget);

      // Hold to compare raw audio button
      expect(find.text('Hold to Listen to Raw Audio'), findsOneWidget);
      final rawButtonFinder = find.byType(GestureDetector).last;
      final gesture = await tester.startGesture(tester.getCenter(rawButtonFinder));
      await tester.pump();
      expect(find.text('Listening to Raw Full Mix'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(find.text('Hold to Listen to Raw Audio'), findsOneWidget);
    });
  });
}
