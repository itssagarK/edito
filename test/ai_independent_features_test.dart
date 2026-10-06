import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/color_grading/models/color_grading_config.dart';
import 'package:edito/features/color_grading/services/ai_color_enhancer_service.dart';
import 'package:edito/features/audio/services/ai_silence_remover_service.dart';
import 'package:edito/features/timeline/services/ai_scene_detector_service.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';

void main() {
  group('Independent On-Device AI Features Tests', () {
    // 1. AI AUTO-COLOR & TONE INTELLIGENCE TESTS
    group('AiColorEnhancerService Tests', () {
      test('computeEnhancement with intensity 0.0 returns unchanged base config', () {
        const base = ColorGradingConfig(
          exposure: 0.05,
          contrast: 1.05,
          saturation: 1.0,
        );

        final result = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.smartAuto,
          intensity: 0.0,
        );

        expect(result.exposure, closeTo(0.05, 0.001));
        expect(result.contrast, closeTo(1.05, 0.001));
        expect(result.saturation, closeTo(1.0, 0.001));
      });

      test('computeEnhancement applies distinct profiles for all modes', () {
        const base = ColorGradingConfig();

        final smartAuto = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.smartAuto,
          intensity: 1.0,
        );
        final vivid = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.vibrantPop,
          intensity: 1.0,
        );
        final cinema = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.cinematicWarm,
          intensity: 1.0,
        );
        final cool = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.cleanCool,
          intensity: 1.0,
        );
        final lowLight = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.lowLightBoost,
          intensity: 1.0,
        );

        // Smart auto lifts shadows and balances exposure
        expect(smartAuto.exposure, greaterThan(0.10));
        expect(smartAuto.contrast, greaterThan(1.0));

        // Vivid pop has higher saturation and contrast
        expect(vivid.saturation, greaterThan(smartAuto.saturation));
        expect(vivid.contrast, greaterThan(smartAuto.contrast));

        // Cinematic warm has elevated golden temperature
        expect(cinema.temperature, greaterThan(10.0));

        // Clean cool has negative temperature (cool blue tint)
        expect(cool.temperature, lessThan(0.0));

        // Low light boost has the highest shadow and exposure boost
        expect(lowLight.exposure, greaterThan(smartAuto.exposure));
        expect(lowLight.shadows, greaterThan(0.35));
      });

      test('estimateMetricsFromRgb estimates Rec.709 luminance and color cast', () {
        final neutral = AiColorEnhancerService.estimateMetricsFromRgb(
          avgR: 0.5,
          avgG: 0.5,
          avgB: 0.5,
        );
        expect(neutral['luminance'], closeTo(0.5, 0.01));
        expect(neutral['colorCast'], closeTo(0.0, 0.01));

        final warmRed = AiColorEnhancerService.estimateMetricsFromRgb(
          avgR: 0.8,
          avgG: 0.5,
          avgB: 0.2,
        );
        expect(warmRed['colorCast'], greaterThan(10.0)); // Warm cast
      });

      test('adaptive luminance compensation boosts underexposed footage', () {
        const base = ColorGradingConfig();

        final normal = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.smartAuto,
          intensity: 1.0,
          measuredMeanLuminance: 0.50,
        );

        final darkFootage = AiColorEnhancerService.computeEnhancement(
          baseConfig: base,
          mode: AiColorMode.smartAuto,
          intensity: 1.0,
          measuredMeanLuminance: 0.15, // Dark/underexposed
        );

        expect(darkFootage.exposure, greaterThan(normal.exposure));
        expect(darkFootage.shadows, greaterThan(normal.shadows));
      });
    });

    // 2. AI SILENCE REMOVER & AUTO JUMP-CUT TESTS
    group('AiSilenceRemoverService Tests', () {
      late Project testProject;
      late Clip speechClip;
      late Clip nextClip;

      setUp(() {
        speechClip = const Clip(
          id: 'speech_clip',
          assetId: 'asset_1',
          trackId: 'track_1',
          startTimeMs: 0,
          durationMs: 10000,
          sourceInMs: 0,
          sourceOutMs: 10000,
        );

        nextClip = const Clip(
          id: 'next_clip',
          assetId: 'asset_2',
          trackId: 'track_1',
          startTimeMs: 10000,
          durationMs: 4000,
          sourceInMs: 0,
          sourceOutMs: 4000,
        );

        testProject = Project(
          id: 'proj_ai_test',
          title: 'Silence Test',
          durationMs: 14000,
          width: 1920,
          height: 1080,
          fps: 30.0,
          tracks: [
            Track(
              id: 'track_1',
              name: 'Main Video',
              type: TrackType.video,
              order: 0,
              clips: [speechClip, nextClip],
            ),
          ],
        );
      });

      test('removeSilencesFromClip splits clip and ripples subsequent clips', () {
        // Mock analysis: 2 speech blocks with a 2-second silence between 3000ms and 5000ms
        const analysis = SilenceAnalysisResult(
          totalClipDurationMs: 10000,
          speechSegments: [
            [0, 3000],
            [5000, 10000],
          ],
          silenceSegments: [
            [3000, 5000],
          ],
          totalSilenceDurationMs: 2000,
          speechPercentage: 80.0,
        );

        final updatedProject = AiSilenceRemoverService.removeSilencesFromClip(
          project: testProject,
          clipId: speechClip.id,
          analysis: analysis,
          paddingMs: 0, // Exact boundaries for testing
        );

        expect(updatedProject, isNotNull);
        final mainTrack = updatedProject!.tracks.first;

        // Original clip should be replaced by 2 sub-clips + 1 next clip = 3 clips total
        expect(mainTrack.clips.length, equals(3));

        final subClip1 = mainTrack.clips[0];
        final subClip2 = mainTrack.clips[1];
        final rippledNextClip = mainTrack.clips[2];

        // First segment: 0 to 3000ms
        expect(subClip1.startTimeMs, equals(0));
        expect(subClip1.durationMs, equals(3000));

        // Second segment: starts immediately after first segment at 3000ms, duration 5000ms
        expect(subClip2.startTimeMs, equals(3000));
        expect(subClip2.durationMs, equals(5000));

        // Subsequent clip rippled backwards: originally at 10000ms, now at 8000ms!
        expect(rippledNextClip.startTimeMs, equals(8000));
        expect(rippledNextClip.id, equals(nextClip.id));

        // Total project duration reduced from 14000ms to 12000ms
        expect(updatedProject.durationMs, equals(12000));
      });
    });

    // 3. AI SCENE CUT & SHOT BOUNDARY DETECTOR TESTS
    group('AiSceneDetectorService Tests', () {
      late Project testProject;
      late Clip longRawClip;

      setUp(() {
        longRawClip = const Clip(
          id: 'long_raw_clip',
          assetId: 'asset_raw',
          trackId: 'track_1',
          startTimeMs: 1000,
          durationMs: 12000,
          sourceInMs: 0,
          sourceOutMs: 12000,
        );

        testProject = Project(
          id: 'proj_scene_test',
          title: 'Scene Test',
          durationMs: 13000,
          width: 1920,
          height: 1080,
          fps: 30.0,
          tracks: [
            Track(
              id: 'track_1',
              name: 'Main Video',
              type: TrackType.video,
              order: 0,
              clips: [longRawClip],
            ),
          ],
        );
      });

      test('detectSceneCuts generates scenes via analytical fallback', () async {
        final result = await AiSceneDetectorService.detectSceneCuts(
          videoPath: '',
          durationMs: 12000,
          sensitivity: 0.5,
        );

        expect(result.isSuccess, isTrue);
        expect(result.totalDurationMs, equals(12000));
        expect(result.cutTimestampsMs, isNotEmpty);
        expect(result.scenes, isNotEmpty);
      });

      test('splitClipAtSceneCuts splits clip into independent scene clips', () {
        final cuts = [4000, 8000]; // Cuts at 4s and 8s

        final updatedProject = AiSceneDetectorService.splitClipAtSceneCuts(
          project: testProject,
          clipId: longRawClip.id,
          cutTimestampsMs: cuts,
        );

        expect(updatedProject, isNotNull);
        final mainTrack = updatedProject!.tracks.first;

        // Clip should be split into 3 scenes: 0-4s, 4-8s, 8-12s
        expect(mainTrack.clips.length, equals(3));

        final scene1 = mainTrack.clips[0];
        final scene2 = mainTrack.clips[1];
        final scene3 = mainTrack.clips[2];

        expect(scene1.startTimeMs, equals(1000));
        expect(scene1.durationMs, equals(4000));

        expect(scene2.startTimeMs, equals(5000));
        expect(scene2.durationMs, equals(4000));

        expect(scene3.startTimeMs, equals(9000));
        expect(scene3.durationMs, equals(4000));

        // Total duration preserved
        expect(scene1.durationMs + scene2.durationMs + scene3.durationMs, equals(12000));
      });
    });

    // 4. EDITOR TOOLS ENUM COMPLETENESS
    group('EditorTool Registration Tests', () {
      test('EditorTool contains all independent AI tools', () {
        expect(EditorTool.values.contains(EditorTool.aiColorEnhance), isTrue);
        expect(EditorTool.values.contains(EditorTool.aiSilenceRemover), isTrue);
        expect(EditorTool.values.contains(EditorTool.aiSceneSplit), isTrue);
      });
    });
  });
}
