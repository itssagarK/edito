import 'dart:math' as math;
import '../models/caption_line.dart';

/// CapCut Pro Speech Cadence & Word-Level Timing Aligner Service
class WordLevelAlignerService {
  static const Set<String> _shortPrepositions = {
    'a', 'an', 'the', 'in', 'on', 'at', 'to', 'of', 'and', 'is', 'for', 'by', 'it', 'so', 'or', 'if', 'as', 'my', 'we'
  };

  /// Generates speech-weighted word timestamps where longer words & punctuated pauses
  /// naturally receive proportional duration matching real human speech cadence.
  static List<WordTimestamp> generateWeightedWords(String text, int totalDurationMs) {
    final rawWords = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.isEmpty) return const [];
    if (totalDurationMs <= 0) return const [];

    if (rawWords.length == 1) {
      return [
        WordTimestamp(
          word: rawWords.first,
          startOffsetMs: 0,
          durationMs: totalDurationMs,
        ),
      ];
    }

    // 1. Calculate speech weight per word
    final weights = <double>[];
    for (final raw in rawWords) {
      final clean = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      double w = clean.length.toDouble().clamp(1.0, 12.0);

      // Short words/articles are spoken quicker
      if (_shortPrepositions.contains(clean)) {
        w = math.max(1.0, w * 0.70);
      }

      // Sentence terminal punctuation creates natural conversational breath pause
      if (raw.endsWith('.') || raw.endsWith('!') || raw.endsWith('?')) {
        w += 3.5;
      } else if (raw.endsWith(',') || raw.endsWith(';') || raw.endsWith(':')) {
        w += 2.0;
      } else if (raw.endsWith('—') || raw.endsWith('-')) {
        w += 1.5;
      }

      weights.add(w);
    }

    final totalWeight = weights.fold<double>(0.0, (sum, w) => sum + w);
    const minWordMs = 120; // Minimum audible threshold for a spoken word

    // 2. Distribute total duration proportionally
    final result = <WordTimestamp>[];
    int currentOffset = 0;

    for (int i = 0; i < rawWords.length; i++) {
      final isLast = i == rawWords.length - 1;
      int dur;

      if (isLast) {
        dur = totalDurationMs - currentOffset;
        if (dur < minWordMs && result.isNotEmpty) {
          dur = minWordMs;
        }
      } else {
        final rawDur = ((weights[i] / totalWeight) * totalDurationMs).round();
        dur = rawDur.clamp(minWordMs, totalDurationMs - currentOffset - (rawWords.length - i - 1) * minWordMs);
      }

      result.add(WordTimestamp(
        word: rawWords[i],
        startOffsetMs: currentOffset,
        durationMs: dur,
      ));

      currentOffset += dur;
    }

    return result;
  }

  /// Locates the active word index at the given playhead offset
  static int getActiveWordIndex(List<WordTimestamp> words, int offsetMs, int totalDurationMs) {
    if (words.isEmpty) return -1;
    if (offsetMs < 0) return -1;

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (offsetMs >= w.startOffsetMs && offsetMs < w.endOffsetMs) {
        return i;
      }
    }

    // If past all words, anchor to last word
    if (offsetMs >= 0) {
      return words.length - 1;
    }

    return -1;
  }

  /// Calculates real-time spring punch scale (1.0 to targetScale) with organic overshoot
  static double calculateSpringScale({
    required int offsetMs,
    required WordTimestamp word,
    required double targetScale,
  }) {
    if (offsetMs < word.startOffsetMs || offsetMs >= word.endOffsetMs) {
      return 1.0;
    }

    final elapsed = offsetMs - word.startOffsetMs;
    const punchDurationMs = 220; // Peak spring response window

    if (elapsed < punchDurationMs) {
      final t = elapsed / punchDurationMs;
      // Damped sine spring curve with peak at ~35% and gentle settle
      final springOvershoot = math.sin(t * math.pi);
      return 1.0 + ((targetScale - 1.0) * springOvershoot * 1.15).clamp(0.0, targetScale - 1.0 + 0.15);
    } else {
      // Settled scale
      return 1.0 + (targetScale - 1.0) * 0.70;
    }
  }

  /// Calculates vertical bounce translation for Bounce Pop animation
  static double calculateVerticalBounce({
    required int offsetMs,
    required WordTimestamp word,
    double maxBouncePixels = 6.0,
  }) {
    if (offsetMs < word.startOffsetMs || offsetMs >= word.endOffsetMs) {
      return 0.0;
    }

    final elapsed = offsetMs - word.startOffsetMs;
    const bounceDurationMs = 240;

    if (elapsed < bounceDurationMs) {
      final t = elapsed / bounceDurationMs;
      // Parabolic jump trajectory: 4 * t * (1 - t)
      return -maxBouncePixels * (4 * t * (1 - t));
    }

    return 0.0;
  }
}
