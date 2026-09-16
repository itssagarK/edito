import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/models/media_asset.dart';
import 'package:edito/models/project.dart';
import 'package:edito/models/track.dart';
import 'package:edito/features/beats/models/beat_detection_config.dart';
import 'package:edito/features/beats/services/beat_detector_service.dart';
import 'package:edito/features/timeline/services/timeline_editing_service.dart';

void main() {
  group('BeatDetectionConfig Model Tests', () {
    test('Default BeatDetectionConfig is inactive and has proper defaults', () {
      const config = BeatDetectionConfig();
      expect(config.isEnabled, false);
      expect(config.mode, BeatDetectionMode.auto);
      expect(config.bpm, 120.0);
      expect(config.sensitivity, 0.70);
      expect(config.snapToBeats, true);
      expect(config.beatTimestampsMs, isEmpty);
      expect(config.hasBeats, false);
    });

    test('BeatDetectionConfig serialization and deserialization retains all fields', () {
      const original = BeatDetectionConfig(
        isEnabled: true,
        mode: BeatDetectionMode.manual,
        bpm: 128.0,
        sensitivity: 0.85,
        snapToBeats: true,
        beatTimestampsMs: [0, 468, 937, 1406, 1875],
      );

      final json = original.toJson();
      final deserialized = BeatDetectionConfig.fromJson(json);

      expect(deserialized.isEnabled, true);
      expect(deserialized.mode, BeatDetectionMode.manual);
      expect(deserialized.bpm, 128.0);
      expect(deserialized.sensitivity, 0.85);
      expect(deserialized.snapToBeats, true);
      expect(deserialized.beatTimestampsMs, equals([0, 468, 937, 1406, 1875]));
      expect(deserialized.hasBeats, true);
      expect(deserialized, equals(original));
    });

    test('BeatDetectionMode extension provides descriptive human labels', () {
      expect(BeatDetectionMode.auto.label, 'Auto Transient');
      expect(BeatDetectionMode.manual.label, 'Tap Tempo / Manual');
      expect(BeatDetectionMode.gridBpm.label, 'Rhythm Grid BPM');

      expect(BeatDetectionMode.auto.description, contains('Automatic transient'));
      expect(BeatDetectionMode.manual.description, contains('Tap along'));
      expect(BeatDetectionMode.gridBpm.description, contains('Mathematical tempo'));
    });
  });

  group('BeatDetectorService Tests', () {
    test('Mathematical tempo grid generates regular beat intervals', () {
      // 120 BPM = 500ms per beat. In 2000ms duration -> [0, 500, 1000, 1500]
      final beats = BeatDetectorService.autoDetectBeats(
        durationMs: 2000,
        bpm: 120.0,
        sensitivity: 0.70, // No eighth-note subdivisions
      );

      expect(beats, equals([0, 500, 1000, 1500]));
    });

    test('High sensitivity generates eighth-note upbeat subdivisions', () {
      // 120 BPM = 500ms interval. Sensitivity 0.80 adds upbeats at +250ms
      final beats = BeatDetectorService.autoDetectBeats(
        durationMs: 1100,
        bpm: 120.0,
        sensitivity: 0.80,
      );

      expect(beats, containsAll([0, 250, 500, 750, 1000]));
    });

    test('PCM peak transient detection registers local maximums above threshold', () {
      final pcm = List<double>.filled(100, 0.1);
      pcm[20] = 0.95; // Strong beat peak
      pcm[60] = 0.90; // Strong beat peak

      final beats = BeatDetectorService.autoDetectBeats(
        durationMs: 2000,
        bpm: 120.0,
        sensitivity: 0.75,
        pcmPeaks: pcm,
      );

      expect(beats.isNotEmpty, true);
      expect(beats.any((b) => (b - 400).abs() < 50), true); // 20 * (2000/100) = 400ms
      expect(beats.any((b) => (b - 1200).abs() < 50), true); // 60 * (2000/100) = 1200ms
    });

    test('Manual beat marker addition keeps timestamps sorted and prevents close duplicates', () {
      const initial = BeatDetectionConfig(
        isEnabled: true,
        beatTimestampsMs: [500, 1500],
      );

      // Add between 500 and 1500
      final updated = BeatDetectorService.addManualBeat(initial, 1000);
      expect(updated.beatTimestampsMs, equals([500, 1000, 1500]));

      // Attempt to add duplicate within 120ms (e.g. 1050ms) -> ignored
      final dupResult = BeatDetectorService.addManualBeat(updated, 1050);
      expect(dupResult.beatTimestampsMs, equals([500, 1000, 1500]));
    });

    test('removeNearBeat removes marker within tolerance', () {
      const config = BeatDetectionConfig(
        isEnabled: true,
        beatTimestampsMs: [500, 1000, 1500],
      );

      final removed = BeatDetectorService.removeNearBeat(config, 1020, toleranceMs: 50);
      expect(removed.beatTimestampsMs, equals([500, 1500]));
    });

    test('calculateBpmFromTaps calculates accurate tempo from tap intervals', () {
      // Taps every 500ms -> 120 BPM
      final taps = [1000, 1500, 2000, 2500, 3000];
      final bpm = BeatDetectorService.calculateBpmFromTaps(taps);
      expect(bpm, 120.0);

      // Taps every 468.75ms -> ~128 BPM
      final taps128 = [0, 469, 938, 1406, 1875];
      final bpm128 = BeatDetectorService.calculateBpmFromTaps(taps128);
      expect(bpm128, inInclusiveRange(127.0, 129.0));
    });

    test('findNearestBeat locates closest beat within threshold', () {
      final beats = [500, 1000, 1500, 2000];
      final snapped = BeatDetectorService.findNearestBeat(beats, 1040, thresholdMs: 100);
      expect(snapped, 1000);

      final missed = BeatDetectorService.findNearestBeat(beats, 1250, thresholdMs: 100);
      expect(missed, 1250);
    });

    test('getBeatsBadge formats HUD status string', () {
      const inactive = BeatDetectionConfig();
      expect(BeatDetectorService.getBeatsBadge(inactive), '');

      const active = BeatDetectionConfig(
        isEnabled: true,
        bpm: 128.0,
        beatTimestampsMs: [0, 500, 1000],
      );
      expect(BeatDetectorService.getBeatsBadge(active), '🥁 BEATS: 128 BPM (3)');
    });
  });

  group('TimelineEditingService Beat Snapping Tests', () {
    test('Magnetic snapping pulls playhead to clip beat timestamp', () {
      final clip = Clip(
        id: 'c1',
        assetId: 'a1',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        beatConfig: const BeatDetectionConfig(
          isEnabled: true,
          bpm: 120.0,
          snapToBeats: true,
          beatTimestampsMs: [500, 1000, 1500], // Absolute: 1500, 2000, 2500
        ),
      );

      final project = Project(
        id: 'p1',
        title: 'Beats Project',
        durationMs: 4000,
        tracks: [
          Track(id: 't1', type: TrackType.video, clips: [clip]),
        ],
        assets: const [
          MediaAsset(id: 'a1', path: 'video.mp4', fileName: 'video.mp4', type: MediaType.video, durationMs: 5000),
        ],
      );

      // Target playhead is 1960ms (within 150ms of 2000ms beat marker)
      final snapped = TimelineEditingService.calculateSnapTime(project, 1960, thresholdMs: 100);
      expect(snapped, 2000);

      // Target playhead 2040ms -> snaps to 2000ms
      final snappedAfter = TimelineEditingService.calculateSnapTime(project, 2040, thresholdMs: 100);
      expect(snappedAfter, 2000);

      // Outside snap threshold (e.g. 1800ms) -> keeps target
      final nonSnapped = TimelineEditingService.calculateSnapTime(project, 1800, thresholdMs: 50);
      expect(nonSnapped, 1800);
    });

    test('Snapping is disabled when snapToBeats is false', () {
      final clip = Clip(
        id: 'c1',
        assetId: 'a1',
        startTimeMs: 1000,
        durationMs: 3000,
        sourceInMs: 0,
        sourceOutMs: 3000,
        beatConfig: const BeatDetectionConfig(
          isEnabled: true,
          bpm: 120.0,
          snapToBeats: false, // Disabled
          beatTimestampsMs: [1000], // Absolute: 2000ms
        ),
      );

      final project = Project(
        id: 'p1',
        title: 'Beats Project',
        durationMs: 4000,
        tracks: [
          Track(id: 't1', type: TrackType.video, clips: [clip]),
        ],
      );

      final snapped = TimelineEditingService.calculateSnapTime(project, 1960, thresholdMs: 100);
      expect(snapped, 1960); // Not snapped to 2000ms
    });
  });

  group('Clip Integration Tests', () {
    test('Clip serializes and deserializes beatConfig accurately', () {
      final clip = Clip(
        id: 'c_test',
        assetId: 'a_test',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
        beatConfig: const BeatDetectionConfig(
          isEnabled: true,
          mode: BeatDetectionMode.gridBpm,
          bpm: 130.0,
          sensitivity: 0.65,
          snapToBeats: true,
          beatTimestampsMs: [0, 461, 923],
        ),
      );

      final json = clip.toJson();
      final reconstructed = Clip.fromJson(json);

      expect(reconstructed.beatConfig.isEnabled, true);
      expect(reconstructed.beatConfig.mode, BeatDetectionMode.gridBpm);
      expect(reconstructed.beatConfig.bpm, 130.0);
      expect(reconstructed.beatConfig.beatTimestampsMs, equals([0, 461, 923]));
      expect(reconstructed, equals(clip));
    });
  });
}
