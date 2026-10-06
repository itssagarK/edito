import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/features/editor/providers/editor_provider.dart';
import 'package:edito/features/overlays/models/progress_bar_config.dart';
import 'package:edito/features/image_editor/models/ken_burns_config.dart';
import 'package:edito/features/timeline/services/gap_closer_service.dart';
import 'package:edito/features/image_editor/services/ken_burns_compiler_service.dart';
import 'package:edito/features/overlays/services/progress_bar_compiler_service.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';

void main() {
  group('Phase 13: 100% Self-Dependent Offline AI / Creative Suite Tests', () {
    group('1. ProgressBarConfig (Social Video Retention Bar)', () {
      test('Default ProgressBarConfig is disabled with standard dimensions', () {
        const config = ProgressBarConfig();
        expect(config.enabled, isFalse);
        expect(config.height, equals(4.0));
        expect(config.position, equals(ProgressBarPosition.bottom));
        expect(config.glow, isTrue);
        expect(config.borderRadius, equals(2.0));
        expect(config.colors.length, equals(2));
      });

      test('Presets provide vibrant gradient color configurations', () {
        expect(ProgressBarPresets.electricBlue.colors, contains(const Color(0xFF00E5FF)));
        expect(ProgressBarPresets.cyberNeon.colors, contains(const Color(0xFF00FFA3)));
        expect(ProgressBarPresets.crimsonFlame.colors, contains(const Color(0xFFFF2A6D)));
        expect(ProgressBarPresets.minimalist.glow, isFalse);
      });

      test('Serialization round-trip preserves all properties', () {
        const original = ProgressBarConfig(
          enabled: true,
          position: ProgressBarPosition.top,
          height: 7.5,
          borderRadius: 4.0,
          glow: false,
          colors: [Color(0xFFFF0055), Color(0xFFFF9900), Color(0xFFFFFF00)],
          backgroundColor: Color(0x33000000),
        );

        final json = original.toJson();
        final restored = ProgressBarConfig.fromJson(json);

        expect(restored.enabled, isTrue);
        expect(restored.position, equals(ProgressBarPosition.top));
        expect(restored.height, equals(7.5));
        expect(restored.borderRadius, equals(4.0));
        expect(restored.glow, isFalse);
        expect(restored.colors.length, equals(3));
        expect(restored, equals(original));
      });

      test('Project model integrates ProgressBarConfig with JSON persistence', () {
        final project = Project(
          id: 'proj_pb_1',
          title: 'Retention Reel',
          width: 1080,
          height: 1920,
          fps: 60,
          durationMs: 15000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tracks: const [],
          assets: const [],
          progressBar: ProgressBarPresets.electricBlue.copyWith(enabled: true, height: 6.0),
        );

        expect(project.progressBar.enabled, isTrue);
        expect(project.progressBar.height, equals(6.0));

        final projectJson = project.toJson();
        final reconstructed = Project.fromJson(projectJson);

        expect(reconstructed.progressBar.enabled, isTrue);
        expect(reconstructed.progressBar.height, equals(6.0));
        expect(reconstructed.progressBar.colors, equals(project.progressBar.colors));
      });
    });

    group('2. KenBurnsConfig (2D Photo & Video Pan/Zoom Transforms)', () {
      test('Default KenBurnsConfig is inactive', () {
        const config = KenBurnsConfig();
        expect(config.mode, equals(KenBurnsMode.none));
        expect(config.intensity, equals(0.2));
        expect(config.easingCurve, equals(KenBurnsEasing.easeInOut));
        expect(config.isActive, isFalse);
      });

      test('Mode activation activates configuration', () {
        expect(const KenBurnsConfig(mode: KenBurnsMode.zoomIn).isActive, isTrue);
        expect(const KenBurnsConfig(mode: KenBurnsMode.zoomOut).isActive, isTrue);
        expect(const KenBurnsConfig(mode: KenBurnsMode.panLeft).isActive, isTrue);
        expect(const KenBurnsConfig(mode: KenBurnsMode.panRight).isActive, isTrue);
        expect(const KenBurnsConfig(mode: KenBurnsMode.diagonalDrift).isActive, isTrue);
      });

      test('evaluateTransform math delivers smooth affine matrices', () {
        const zoomIn = KenBurnsConfig(
          mode: KenBurnsMode.zoomIn,
          intensity: 0.3,
          easingCurve: KenBurnsEasing.linear,
        );

        final t0 = zoomIn.evaluateTransform(0.0);
        expect(t0.scale, closeTo(1.0, 0.001));
        expect(t0.translateX, equals(0.0));
        expect(t0.translateY, equals(0.0));

        final tMid = zoomIn.evaluateTransform(0.5);
        expect(tMid.scale, closeTo(1.15, 0.001));

        final t1 = zoomIn.evaluateTransform(1.0);
        expect(t1.scale, closeTo(1.30, 0.001));

        // Clamping edge cases
        final tUnder = zoomIn.evaluateTransform(-0.5);
        expect(tUnder.scale, closeTo(1.0, 0.001));

        final tOver = zoomIn.evaluateTransform(1.5);
        expect(tOver.scale, closeTo(1.30, 0.001));
      });

      test('Pan & Diagonal motion produce expected directional offsets', () {
        const panLeft = KenBurnsConfig(
          mode: KenBurnsMode.panLeft,
          intensity: 0.2,
          easingCurve: KenBurnsEasing.linear,
        );

        final panStart = panLeft.evaluateTransform(0.0);
        final panEnd = panLeft.evaluateTransform(1.0);

        expect(panStart.scale, greaterThan(1.0)); // Zoomed in slightly to prevent black border
        expect(panStart.translateX, greaterThan(0.0));
        expect(panEnd.translateX, lessThan(0.0));

        const drift = KenBurnsConfig(
          mode: KenBurnsMode.diagonalDrift,
          intensity: 0.25,
          easingCurve: KenBurnsEasing.linear,
        );

        final driftEnd = drift.evaluateTransform(1.0);
        expect(driftEnd.scale, greaterThan(1.0));
        expect(driftEnd.translateX, isNot(0.0));
        expect(driftEnd.translateY, isNot(0.0));
      });

      test('Serialization round-trip preserves KenBurns settings', () {
        const original = KenBurnsConfig(
          mode: KenBurnsMode.diagonalDrift,
          intensity: 0.35,
          easingCurve: KenBurnsEasing.easeOut,
        );

        final json = original.toJson();
        final restored = KenBurnsConfig.fromJson(json);

        expect(restored.mode, equals(KenBurnsMode.diagonalDrift));
        expect(restored.intensity, equals(0.35));
        expect(restored.easingCurve, equals(KenBurnsEasing.easeOut));
        expect(restored, equals(original));
      });

      test('Clip model integrates KenBurnsConfig with JSON persistence', () {
        const clip = Clip(
          id: 'clip_kb_1',
          assetId: 'asset_1',
          trackId: 'track_1',
          startTimeMs: 0,
          durationMs: 5000,
          sourceInMs: 0,
          sourceOutMs: 5000,
          kenBurns: KenBurnsConfig(mode: KenBurnsMode.zoomIn, intensity: 0.25),
        );

        expect(clip.kenBurns.isActive, isTrue);
        expect(clip.kenBurns.mode, equals(KenBurnsMode.zoomIn));

        final clipJson = clip.toJson();
        final restored = Clip.fromJson(clipJson);

        expect(restored.kenBurns.isActive, isTrue);
        expect(restored.kenBurns.intensity, equals(0.25));
      });
    });

    group('3. GapCloserService (Timeline Micro-Gap Finder & Ripple Closer)', () {
      late Project projectWithGaps;

      setUp(() {
        projectWithGaps = Project(
          id: 'proj_gaps_1',
          title: 'Gap Test Project',
          width: 1920,
          height: 1080,
          fps: 30,
          durationMs: 12000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tracks: [
            const Track(
              id: 'track_v1',
              type: TrackType.video,
              name: 'Main Video',
              clips: [
                Clip(
                  id: 'c1',
                  assetId: 'a1',
                  trackId: 'track_v1',
                  startTimeMs: 0,
                  durationMs: 3000,
                  sourceInMs: 0,
                  sourceOutMs: 3000,
                ),
                // 50ms micro black flash gap here (3000 to 3050)
                Clip(
                  id: 'c2',
                  assetId: 'a2',
                  trackId: 'track_v1',
                  startTimeMs: 3050,
                  durationMs: 2000,
                  sourceInMs: 0,
                  sourceOutMs: 2000,
                ),
                // 120ms gap here (5050 to 5170)
                Clip(
                  id: 'c3',
                  assetId: 'a3',
                  trackId: 'track_v1',
                  startTimeMs: 5170,
                  durationMs: 4000,
                  sourceInMs: 0,
                  sourceOutMs: 4000,
                ),
              ],
            ),
          ],
          assets: const [],
        );
      });

      test('analyzeGaps detects exact micro-gap positions and counts', () {
        final analysis = GapCloserService.analyzeGaps(projectWithGaps, maxGapThresholdMs: 500);

        expect(analysis.totalGaps, equals(2));
        expect(analysis.totalGapDurationMs, equals(170)); // 50ms + 120ms
        expect(analysis.gaps.length, equals(2));

        expect(analysis.gaps[0].startMs, equals(3000));
        expect(analysis.gaps[0].endMs, equals(3050));
        expect(analysis.gaps[0].durationMs, equals(50));

        expect(analysis.gaps[1].startMs, equals(5050));
        expect(analysis.gaps[1].endMs, equals(5170));
        expect(analysis.gaps[1].durationMs, equals(120));
      });

      test('closeAllGaps ripples timeline and closes gaps seamlessly', () {
        final compacted = GapCloserService.closeAllGaps(projectWithGaps, maxGapThresholdMs: 500);

        final clips = compacted.tracks.first.clips;
        expect(clips[0].startTimeMs, equals(0));
        expect(clips[0].durationMs, equals(3000));

        // c2 should now touch c1 exactly at 3000ms
        expect(clips[1].startTimeMs, equals(3000));
        expect(clips[1].durationMs, equals(2000));

        // c3 should touch c2 exactly at 5000ms
        expect(clips[2].startTimeMs, equals(5000));
        expect(clips[2].durationMs, equals(4000));

        // Post-compact analysis should report 0 gaps
        final postAnalysis = GapCloserService.analyzeGaps(compacted, maxGapThresholdMs: 500);
        expect(postAnalysis.totalGaps, equals(0));
        expect(postAnalysis.totalGapDurationMs, equals(0));
      });

      test('closeAllGaps leaves intentional large gaps untouched if threshold is smaller', () {
        final analysis = GapCloserService.analyzeGaps(projectWithGaps, maxGapThresholdMs: 80);

        // Only the 50ms gap is <= 80ms; 120ms is ignored as intentional pause
        expect(analysis.totalGaps, equals(1));
        expect(analysis.totalGapDurationMs, equals(50));

        final compacted = GapCloserService.closeAllGaps(projectWithGaps, maxGapThresholdMs: 80);
        final clips = compacted.tracks.first.clips;

        expect(clips[1].startTimeMs, equals(3000)); // 50ms closed
        expect(clips[2].startTimeMs, equals(5120)); // shifted by 50ms only, 120ms gap preserved
      });
    });

    group('4. EditorTool Enum Completeness', () {
      test('EditorTool contains Phase 13 tools', () {
        expect(EditorTool.values, contains(EditorTool.progressBar));
        expect(EditorTool.values, contains(EditorTool.kenBurns));
        expect(EditorTool.values, contains(EditorTool.gapCloser));
      });
    });

    group('5. Export Parity & Native FFmpeg Filters', () {
      test('ProgressBarCompilerService generates drawbox filters', () {
        const disabled = ProgressBarConfig(enabled: false);
        final emptyFilters = ProgressBarCompilerService.generateFFmpegFilters(
          disabled,
          totalDurationMs: 10000,
          targetWidth: 1080,
          targetHeight: 1920,
        );
        expect(emptyFilters, isEmpty);

        final active = ProgressBarPresets.electricBlue.copyWith(enabled: true, glow: true);
        final filters = ProgressBarCompilerService.generateFFmpegFilters(
          active,
          totalDurationMs: 15000,
          targetWidth: 1080,
          targetHeight: 1920,
        );
        expect(filters.length, equals(3));
        expect(filters[0], contains('drawbox=x=0')); // Background track
        expect(filters[1], contains('min(iw,iw*(t/15.000))')); // Glow layer
        expect(filters[2], contains('min(iw,iw*(t/15.000))')); // Dynamic fill
      });

      test('KenBurnsCompilerService generates zoom & crop filter expressions', () {
        const inactive = KenBurnsConfig(mode: KenBurnsMode.none);
        expect(
          KenBurnsCompilerService.generateFFmpegFilters(
            inactive,
            clipDurationMs: 4000,
            targetWidth: 1920,
            targetHeight: 1080,
          ),
          isEmpty,
        );

        const zoomIn = KenBurnsConfig(mode: KenBurnsMode.zoomIn, intensity: 0.25);
        final zoomInFilters = KenBurnsCompilerService.generateFFmpegFilters(
          zoomIn,
          clipDurationMs: 4000,
          targetWidth: 1920,
          targetHeight: 1080,
        );
        expect(zoomInFilters.length, equals(1));
        expect(zoomInFilters.first, contains("crop=w='iw/(1.0+0.250*min(t/4.000,1.0))'"));

        const panRight = KenBurnsConfig(mode: KenBurnsMode.panRight, intensity: 0.2);
        final panRightFilters = KenBurnsCompilerService.generateFFmpegFilters(
          panRight,
          clipDurationMs: 5000,
          targetWidth: 1920,
          targetHeight: 1080,
        );
        expect(panRightFilters.length, equals(1));
        expect(panRightFilters.first, contains("(iw-ow)*min(t/5.000,1.0)"));
      });

      test('FFmpegCommandBuilder includes ProgressBar and KenBurns in output arguments', () {
        final project = Project(
          id: 'proj_export_test',
          title: 'Export Test',
          width: 1920,
          height: 1080,
          fps: 30,
          durationMs: 4000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tracks: [
            const Track(
              id: 'track_1',
              type: TrackType.video,
              name: 'Video Track',
              clips: [
                Clip(
                  id: 'clip_kb',
                  assetId: 'asset_kb',
                  trackId: 'track_1',
                  startTimeMs: 0,
                  durationMs: 4000,
                  sourceInMs: 0,
                  sourceOutMs: 4000,
                  kenBurns: KenBurnsConfig(mode: KenBurnsMode.zoomIn, intensity: 0.2),
                ),
              ],
            ),
          ],
          assets: const [
            MediaAsset(
              id: 'asset_kb',
              name: 'test.mp4',
              path: '/tmp/test.mp4',
              type: MediaType.video,
              durationMs: 4000,
              width: 1920,
              height: 1080,
            ),
          ],
          progressBar: ProgressBarPresets.electricBlue.copyWith(enabled: true),
        );

        final result = FFmpegCommandBuilder.build(
          project: project,
          config: const ExportConfiguration(
            resolution: ExportResolution.r1080p,
            framerate: ExportFramerate.fps30,
            quality: ExportQuality.high,
            codec: ExportCodec.h264,
          ),
          outputPath: '/tmp/out.mp4',
        );

        expect(result.command, contains('crop=w='));
        expect(result.command, contains('min(iw,iw*(t/4.000))'));
      });
    });
  });
}
