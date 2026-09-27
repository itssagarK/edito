import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/edge_aura/models/edge_aura_config.dart';
import 'package:edito/features/edge_aura/services/edge_aura_compiler_service.dart';
import 'package:edito/features/edge_aura/presentation/widgets/edge_aura_sheet.dart';
import 'package:edito/features/export/services/ffmpeg_command_builder.dart';
import 'package:edito/features/export/models/export_preset.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/track.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/media_asset.dart';

void main() {
  group('Feature 32: CapCut Pro AI Video Glow & Edge Aura Studio Suite Tests', () {
    test('EdgeGlowStyle enums provide accurate labels, descriptions, categories, and colors', () {
      expect(EdgeGlowStyle.none.label, equals('None'));
      expect(EdgeGlowStyle.cyberCyan.label, equals('Cyber Cyan'));
      expect(EdgeGlowStyle.synthwavePink.label, equals('Synthwave Pink'));
      expect(EdgeGlowStyle.solarGold.label, equals('Solar Gold'));
      expect(EdgeGlowStyle.radioactiveGreen.label, equals('Radioactive'));
      expect(EdgeGlowStyle.plasmaPurple.label, equals('Plasma Purple'));
      expect(EdgeGlowStyle.infernoFlame.label, equals('Inferno Flame'));
      expect(EdgeGlowStyle.rgbGhost.label, equals('RGB Ghost'));
      expect(EdgeGlowStyle.custom.label, equals('Custom Aura'));

      expect(EdgeGlowStyle.cyberCyan.category, equals(EdgeAuraCategory.cyber));
      expect(EdgeGlowStyle.plasmaPurple.category, equals(EdgeAuraCategory.cyber));
      expect(EdgeGlowStyle.rgbGhost.category, equals(EdgeAuraCategory.cyber));
      expect(EdgeGlowStyle.synthwavePink.category, equals(EdgeAuraCategory.energy));
      expect(EdgeGlowStyle.solarGold.category, equals(EdgeAuraCategory.energy));
      expect(EdgeGlowStyle.radioactiveGreen.category, equals(EdgeAuraCategory.energy));
      expect(EdgeGlowStyle.infernoFlame.category, equals(EdgeAuraCategory.energy));
      expect(EdgeGlowStyle.custom.category, equals(EdgeAuraCategory.custom));

      expect(EdgeGlowStyle.cyberCyan.defaultColorValue, equals(0xFF00F0FF));
      expect(EdgeGlowStyle.synthwavePink.defaultColorValue, equals(0xFFFF007F));
      expect(EdgeGlowStyle.solarGold.defaultColorValue, equals(0xFFFFD700));

      expect(EdgeAuraCategory.all.label, equals('All'));
      expect(EdgeAuraCategory.cyber.label, equals('Cyber & Sci-Fi'));
      expect(EdgeAuraCategory.energy.label, equals('Radiant Energy'));
      expect(EdgeAuraCategory.custom.label, equals('Custom'));
    });

    test('EdgeAuraConfig default constructor and preset factory initialize correctly', () {
      const defaultConfig = EdgeAuraConfig();
      expect(defaultConfig.isEnabled, isFalse);
      expect(defaultConfig.style, equals(EdgeGlowStyle.none));
      expect(defaultConfig.intensity, equals(1.0));
      expect(defaultConfig.radius, equals(15.0));
      expect(defaultConfig.threshold, equals(0.25));
      expect(defaultConfig.pulseSpeed, equals(0.0));
      expect(defaultConfig.badge, isEmpty);

      // Cyber Cyan Preset
      final cyan = EdgeAuraConfig.preset(EdgeGlowStyle.cyberCyan);
      expect(cyan.isEnabled, isTrue);
      expect(cyan.style, equals(EdgeGlowStyle.cyberCyan));
      expect(cyan.colorValue, equals(0xFF00F0FF));
      expect(cyan.badge, equals('AURA: CYBER CYAN'));

      // Synthwave Pink Preset (uses Addition blend mode)
      final pink = EdgeAuraConfig.preset(EdgeGlowStyle.synthwavePink);
      expect(pink.isEnabled, isTrue);
      expect(pink.style, equals(EdgeGlowStyle.synthwavePink));
      expect(pink.blendMode, equals(GlowBlendMode.addition));
      expect(pink.badge, equals('AURA: SYNTHWAVE PINK'));

      // Solar Gold Preset
      final gold = EdgeAuraConfig.preset(EdgeGlowStyle.solarGold);
      expect(gold.isEnabled, isTrue);
      expect(gold.style, equals(EdgeGlowStyle.solarGold));
      expect(gold.radius, equals(22.0));
      expect(gold.badge, equals('AURA: SOLAR GOLD'));

      // None Preset
      final nonePreset = EdgeAuraConfig.preset(EdgeGlowStyle.none);
      expect(nonePreset.isEnabled, isFalse);
      expect(nonePreset.style, equals(EdgeGlowStyle.none));
    });

    test('EdgeAuraConfig JSON serialization and copyWith integrity', () {
      const original = EdgeAuraConfig(
        isEnabled: true,
        style: EdgeGlowStyle.plasmaPurple,
        intensity: 1.4,
        radius: 20.0,
        threshold: 0.30,
        pulseSpeed: 1.5,
        colorValue: 0xFFBD00FF,
        blendMode: GlowBlendMode.overlay,
        preserveSubject: true,
      );

      final json = original.toJson();
      final restored = EdgeAuraConfig.fromJson(json);

      expect(restored.isEnabled, isTrue);
      expect(restored.style, equals(EdgeGlowStyle.plasmaPurple));
      expect(restored.intensity, equals(1.4));
      expect(restored.radius, equals(20.0));
      expect(restored.threshold, equals(0.30));
      expect(restored.pulseSpeed, equals(1.5));
      expect(restored.colorValue, equals(0xFFBD00FF));
      expect(restored.blendMode, equals(GlowBlendMode.overlay));
      expect(restored.preserveSubject, isTrue);
      expect(restored, equals(original));

      final updated = original.copyWith(intensity: 1.8, pulseSpeed: 0.0);
      expect(updated.intensity, equals(1.8));
      expect(updated.pulseSpeed, equals(0.0));
      expect(updated.style, equals(EdgeGlowStyle.plasmaPurple));
    });

    test('EdgeAuraCompilerService generates deterministic FFmpeg filters and handles pulse speed', () {
      const disabled = EdgeAuraConfig();
      expect(EdgeAuraCompilerService.generateFFmpegFilters(disabled), isEmpty);

      // 1. Static Cyber Cyan
      final cyan = EdgeAuraConfig.preset(EdgeGlowStyle.cyberCyan);
      final cyanFilters = EdgeAuraCompilerService.generateFFmpegFilters(cyan);
      expect(cyanFilters.any((f) => f.contains('edgedetect=') && f.contains('mode=colormix')), isTrue);
      expect(cyanFilters.any((f) => f.contains('colorbalance=')), isTrue);
      expect(cyanFilters.any((f) => f.contains('eq=contrast=') && f.contains('brightness=')), isTrue);

      // 2. RGB Ghost with chromatic split
      final ghost = EdgeAuraConfig.preset(EdgeGlowStyle.rgbGhost);
      final ghostFilters = EdgeAuraCompilerService.generateFFmpegFilters(ghost);
      expect(ghostFilters.any((f) => f.contains('rgbashift=rh=6:bv=-6')), isTrue);

      // 3. Radioactive Green with dynamic breathing pulse
      final radioactive = EdgeAuraConfig.preset(EdgeGlowStyle.radioactiveGreen);
      final radioFilters = EdgeAuraCompilerService.generateFFmpegFilters(radioactive);
      expect(radioFilters.any((f) => f.contains('eval=frame') && f.contains('sin(')), isTrue);
    });

    test('Clip model integrates EdgeAuraConfig properly', () {
      const clip = Clip(
        id: 'clip_aura_01',
        assetId: 'asset_vid_01',
        trackId: 'track_vid_01',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );
      expect(clip.edgeAura.isEnabled, isFalse);

      final cyanPreset = EdgeAuraConfig.preset(EdgeGlowStyle.cyberCyan);
      final modifiedClip = clip.copyWith(edgeAura: cyanPreset);
      expect(modifiedClip.edgeAura.isEnabled, isTrue);
      expect(modifiedClip.edgeAura.style, equals(EdgeGlowStyle.cyberCyan));
      expect(modifiedClip.edgeAura.badge, equals('AURA: CYBER CYAN'));

      final json = modifiedClip.toJson();
      final fromJsonClip = Clip.fromJson(json);
      expect(fromJsonClip.edgeAura, equals(cyanPreset));
    });

    test('FFmpegCommandBuilder integrates Edge Aura into deterministic video filter graph', () {
      const asset = MediaAsset(
        id: 'asset_v01',
        path: '/storage/media/dance_clip.mp4',
        fileName: 'dance_clip.mp4',
        type: MediaType.video,
        durationMs: 4000,
      );

      final clipWithAura = Clip(
        id: 'clip_01',
        assetId: asset.id,
        trackId: 'track_v01',
        startTimeMs: 0,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
        edgeAura: EdgeAuraConfig.preset(EdgeGlowStyle.cyberCyan),
      );

      final project = Project(
        id: 'proj_01',
        name: 'Edge Aura Test Project',
        durationMs: 4000,
        assets: [asset],
        tracks: [
          Track(
            id: 'track_v01',
            name: 'Video Track',
            type: TrackType.video,
            order: 0,
            clips: [clipWithAura],
          ),
        ],
      );

      final result = FFmpegCommandBuilder.buildCommand(
        project: project,
        outputPath: '/storage/export/aura_output.mp4',
        config: ExportPreset.highQuality1080p,
      );

      // Verify that the filter_complex contains edge detection and chromatic colorbalance
      expect(result.command, contains('edgedetect='));
      expect(result.command, contains('mode=colormix'));
      expect(result.command, contains('colorbalance='));
    });

    testWidgets('EdgeAuraSheet renders styles, allows selection, and supports comparison bypass', (tester) async {
      EdgeAuraConfig currentConfig = const EdgeAuraConfig();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EdgeAuraSheet(
              initialConfig: currentConfig,
              onApply: (cfg) {
                currentConfig = cfg;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edge_aura_sheet')), findsOneWidget);
      expect(find.text('CapCut Pro Video Glow & Edge Aura'), findsOneWidget);
      expect(find.text('Standard Clean Video'), findsOneWidget);

      // 1. Select Cyber Cyan Preset
      final cyanFinder = find.byKey(const ValueKey('edge_aura_style_cyberCyan'));
      expect(cyanFinder, findsOneWidget);
      await tester.tap(cyanFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isTrue);
      expect(currentConfig.style, equals(EdgeGlowStyle.cyberCyan));
      expect(find.text('AURA: CYBER CYAN'), findsOneWidget);

      // 2. Select Synthwave Pink Preset
      final pinkFinder = find.byKey(const ValueKey('edge_aura_style_synthwavePink'));
      expect(pinkFinder, findsOneWidget);
      await tester.tap(pinkFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isTrue);
      expect(currentConfig.style, equals(EdgeGlowStyle.synthwavePink));
      expect(find.text('AURA: SYNTHWAVE PINK'), findsOneWidget);

      // 3. Test Hold to Compare
      final compareFinder = find.byKey(const ValueKey('edge_aura_hold_to_compare'));
      expect(compareFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(compareFinder));
      await tester.pump();
      expect(find.text('Raw Video Bypass (Comparing)'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(find.text('AURA: SYNTHWAVE PINK'), findsOneWidget);

      // 4. Test Reset Button
      final resetFinder = find.byKey(const ValueKey('edge_aura_reset_button'));
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(currentConfig.isEnabled, isFalse);
      expect(currentConfig.style, equals(EdgeGlowStyle.none));
      expect(find.text('Standard Clean Video'), findsOneWidget);
    });
  });
}
