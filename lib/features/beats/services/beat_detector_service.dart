import 'dart:math';
import '../models/beat_detection_config.dart';

class BeatDetectorService {
  /// Automatically generates rhythmic beat timestamps across a clip duration
  static List<int> autoDetectBeats({
    required int durationMs,
    double bpm = 120.0,
    double sensitivity = 0.70,
    List<double>? pcmPeaks,
  }) {
    if (durationMs <= 0) return [];

    final beats = <int>[];

    // 1. If real PCM sample peaks are available, perform energy flux transient detection
    if (pcmPeaks != null && pcmPeaks.length > 10) {
      final n = pcmPeaks.length;
      final msPerPeak = durationMs / n;

      // Compute moving energy average
      double sum = 0;
      for (final p in pcmPeaks) {
        sum += p;
      }
      final mean = sum / n;

      // Threshold: lower sensitivity means only highest peaks register
      final threshold = mean + ((1.0 - sensitivity) * 0.45);
      final minIntervalMs = (30000.0 / bpm.clamp(60.0, 220.0)).round(); // Minimum gap between beats

      int lastBeatMs = -minIntervalMs;
      for (int i = 1; i < n - 1; i++) {
        final current = pcmPeaks[i];
        final prev = pcmPeaks[i - 1];
        final next = pcmPeaks[i + 1];

        // Peak local maximum and above threshold
        if (current > prev && current > next && current >= threshold) {
          final tMs = (i * msPerPeak).round();
          if (tMs - lastBeatMs >= minIntervalMs) {
            beats.add(tMs);
            lastBeatMs = tMs;
          }
        }
      }

      if (beats.isNotEmpty) return beats;
    }

    // 2. Mathematical Tempo Grid Beat Generator
    final effectiveBpm = bpm.clamp(40.0, 240.0);
    final intervalMs = (60000.0 / effectiveBpm).round();

    // Primary downbeats (quarters)
    for (int t = 0; t < durationMs; t += intervalMs) {
      beats.add(t);
      // High sensitivity adds eighth-note upbeats
      if (sensitivity > 0.75) {
        final upbeat = t + (intervalMs ~/ 2);
        if (upbeat < durationMs) {
          beats.add(upbeat);
        }
      }
    }

    beats.sort();
    return beats;
  }

  /// Adds a manual beat marker at the specified timestamp
  static BeatDetectionConfig addManualBeat(BeatDetectionConfig config, int timestampMs) {
    if (timestampMs < 0) return config;

    // Check if a marker already exists within 120ms
    final exists = config.beatTimestampsMs.any((b) => (b - timestampMs).abs() < 120);
    if (exists) return config;

    final updated = [...config.beatTimestampsMs, timestampMs]..sort();
    return config.copyWith(
      isEnabled: true,
      beatTimestampsMs: updated,
    );
  }

  /// Removes any beat marker located within tolerance of timestampMs
  static BeatDetectionConfig removeNearBeat(BeatDetectionConfig config, int timestampMs, {int toleranceMs = 150}) {
    final updated = config.beatTimestampsMs.where((b) => (b - timestampMs).abs() > toleranceMs).toList();
    return config.copyWith(beatTimestampsMs: updated);
  }

  /// Calculates estimated BPM from successive tap timestamps
  static double calculateBpmFromTaps(List<int> tapTimestampsMs) {
    if (tapTimestampsMs.length < 2) return 120.0;

    final intervals = <int>[];
    for (int i = 1; i < tapTimestampsMs.length; i++) {
      final diff = tapTimestampsMs[i] - tapTimestampsMs[i - 1];
      if (diff >= 200 && diff <= 2000) {
        intervals.add(diff);
      }
    }

    if (intervals.isEmpty) return 120.0;

    final avgIntervalMs = intervals.reduce((a, b) => a + b) / intervals.length;
    final calculatedBpm = (60000.0 / avgIntervalMs).clamp(40.0, 240.0);
    return double.parse(calculatedBpm.toStringAsFixed(1));
  }

  /// Finds the closest beat marker within snapping threshold
  static int findNearestBeat(List<int> beatTimestampsMs, int targetMs, {int thresholdMs = 120}) {
    if (beatTimestampsMs.isEmpty) return targetMs;

    int closest = targetMs;
    int minDiff = thresholdMs + 1;

    for (final b in beatTimestampsMs) {
      final diff = (targetMs - b).abs();
      if (diff <= thresholdMs && diff < minDiff) {
        minDiff = diff;
        closest = b;
      }
    }

    return closest;
  }

  /// Returns a concise HUD badge for real-time viewport and timeline display
  static String getBeatsBadge(BeatDetectionConfig config) {
    if (!config.hasBeats) return '';
    return '🥁 BEATS: ${config.bpm.toInt()} BPM (${config.beatTimestampsMs.length})';
  }
}
