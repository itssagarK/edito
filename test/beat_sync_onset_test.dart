import 'package:flutter_test/flutter_test.dart';
import 'package:edito/features/beats/models/beat_detection_config.dart';
import 'package:edito/features/beats/services/beat_detector_service.dart';
import 'package:edito/models/clip.dart';

void main() {
  group('BeatDetectorService Spectral Onset Detection Tests', () {
    test('detectSpectralOnsets detects distinct rhythmic transient spikes', () {
      // 100 samples across 5000ms (50ms per sample)
      // Rhythm pulses every 10 samples (500ms -> 120 BPM)
      final energy = List<double>.filled(100, 0.05);
      for (int i = 10; i < 100; i += 10) {
        energy[i] = 0.95; // transient peak
        if (i + 1 < 100) energy[i + 1] = 0.30; // decay
      }

      final onsets = BeatDetectorService.detectSpectralOnsets(
        energySamples: energy,
        durationMs: 5000,
        sensitivity: 0.70,
        maxBpm: 200.0,
      );

      expect(onsets.isNotEmpty, isTrue);
      expect(onsets.length, greaterThanOrEqualTo(8));
      // First beat should be around 500ms
      expect(onsets[0], closeTo(500, 50));
    });

    test('estimateBpmFromBeats accurately calculates 120 BPM from 500ms inter-beat intervals', () {
      final beats = [0, 500, 1000, 1500, 2000, 2500, 3000];
      final bpm = BeatDetectorService.estimateBpmFromBeats(beats);
      expect(bpm, 120.0);
    });

    test('estimateBpmFromBeats calculates 140 BPM from ~428ms inter-beat intervals', () {
      final beats = [0, 428, 857, 1285, 1714, 2142];
      final bpm = BeatDetectorService.estimateBpmFromBeats(beats);
      expect(bpm, closeTo(140.0, 1.0));
    });
  });

  group('Beat Magnetic Snapping Tests', () {
    test('snapTimestampToNearestBeat snaps playhead to closest beat within threshold', () {
      const clip = Clip(
        id: 'clip_music',
        assetId: 'song.mp3',
        name: 'Music',
        startTimeMs: 1000,
        durationMs: 5000,
        beatConfig: BeatDetectionConfig(
          isEnabled: true,
          snapToBeats: true,
          beatTimestampsMs: [500, 1000, 1500, 2000], // Absolute: 1500, 2000, 2500, 3000
        ),
      );

      // Playhead at 1960ms (within 40ms of 2000ms beat)
      final snapped = BeatDetectorService.snapTimestampToNearestBeat(
        clip: clip,
        playheadMs: 1960,
        thresholdMs: 100,
      );

      expect(snapped, 2000);
    });

    test('snapTimestampToNearestBeat does not alter timestamp when outside threshold', () {
      const clip = Clip(
        id: 'clip_music',
        assetId: 'song.mp3',
        name: 'Music',
        startTimeMs: 1000,
        durationMs: 5000,
        beatConfig: BeatDetectionConfig(
          isEnabled: true,
          snapToBeats: true,
          beatTimestampsMs: [500, 1000, 1500, 2000],
        ),
      );

      // Playhead at 1750ms (equidistant from 1500 and 2000, diff 250ms > 100ms threshold)
      final notSnapped = BeatDetectorService.snapTimestampToNearestBeat(
        clip: clip,
        playheadMs: 1750,
        thresholdMs: 100,
      );

      expect(notSnapped, 1750);
    });

    test('snapTimestampToNearestBeat returns original timestamp when snapToBeats is false', () {
      const clip = Clip(
        id: 'clip_music',
        assetId: 'song.mp3',
        name: 'Music',
        startTimeMs: 1000,
        durationMs: 5000,
        beatConfig: BeatDetectionConfig(
          isEnabled: true,
          snapToBeats: false, // Disabled snapping
          beatTimestampsMs: [500, 1000, 1500, 2000],
        ),
      );

      final result = BeatDetectorService.snapTimestampToNearestBeat(
        clip: clip,
        playheadMs: 1980,
        thresholdMs: 100,
      );

      expect(result, 1980);
    });
  });
}
