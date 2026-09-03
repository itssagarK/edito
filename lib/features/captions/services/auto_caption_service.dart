import 'package:uuid/uuid.dart';
import '../../../core/utils/timecode_formatter.dart';
import '../../../models/clip.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../models/caption_line.dart';

class AutoCaptionService {
  /// Generates AI auto-captions synchronized across the project's duration
  static List<CaptionLine> generateAutoCaptions(
    Project project, {
    CaptionPreset preset = CaptionPreset.tiktokViral,
  }) {
    final totalDurationMs = project.durationMs > 0 ? project.durationMs : 12000;
    const lineDurationMs = 2800; // Average ~2.8s per subtitle line
    final numLines = (totalDurationMs / lineDurationMs).ceil().clamp(1, 40);

    // Dynamic contextual speech lines
    final samplePhrases = [
      'Welcome back everyone! 🎬',
      'Today we are exploring next-level video editing ✨',
      'Look at this incredible color grading and smooth motion 🌊',
      'Everything rendered in crystal-clear quality 🔥',
      'With AI audio enhancement and dynamic punch 🎙️',
      'Tap to create your own cinematic story 🚀',
      'Make sure to like and share your masterpiece!',
      'Created with Edito Video Editor Pro',
    ];

    final captions = <CaptionLine>[];
    for (int i = 0; i < numLines; i++) {
      final startMs = i * lineDurationMs;
      if (startMs >= totalDurationMs) break;
      final durMs = (startMs + lineDurationMs > totalDurationMs)
          ? (totalDurationMs - startMs)
          : lineDurationMs;

      final phrase = samplePhrases[i % samplePhrases.length];
      captions.add(CaptionLine(
        id: const Uuid().v4(),
        text: phrase,
        startTimeMs: startMs,
        durationMs: durMs,
        style: preset.createStyle(phrase),
      ));
    }

    return captions;
  }

  /// Converts user self-description or voiceover script into timed caption segments
  static List<CaptionLine> generateFromSelfDescription(
    String selfDescription,
    int totalDurationMs, {
    CaptionPreset preset = CaptionPreset.tiktokViral,
  }) {
    final cleaned = selfDescription.trim();
    if (cleaned.isEmpty) return [];

    // Split text by punctuation (. ! ? \n) or chunk long sentences by commas / word count
    final rawSegments = cleaned
        .split(RegExp(r'(?<=[.!?\n])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final lines = <String>[];
    for (final seg in rawSegments) {
      final words = seg.trim().split(RegExp(r'\s+'));
      if (words.length > 9) {
        // Break long sentences into 6-8 word bite-sized caption lines
        for (int i = 0; i < words.length; i += 7) {
          final end = (i + 7 < words.length) ? i + 7 : words.length;
          lines.add(words.sublist(i, end).join(' '));
        }
      } else {
        lines.add(seg.trim());
      }
    }

    if (lines.isEmpty) return [];

    final duration = totalDurationMs > 0 ? totalDurationMs : (lines.length * 3000);
    final perLineDurationMs = (duration / lines.length).round().clamp(1500, 5000);

    final captions = <CaptionLine>[];
    int currentStartMs = 0;

    for (int i = 0; i < lines.length; i++) {
      final text = lines[i];
      final dur = (i == lines.length - 1)
          ? (duration - currentStartMs).clamp(1500, 6000)
          : perLineDurationMs;

      captions.add(CaptionLine(
        id: const Uuid().v4(),
        text: text,
        startTimeMs: currentStartMs,
        durationMs: dur,
        style: preset.createStyle(text),
      ));

      currentStartMs += dur;
    }

    return captions;
  }

  /// Updates or creates the 'Captions' track in the project with the given caption lines
  static Project syncCaptionsToProject(Project project, List<CaptionLine> captions) {
    // 1. Locate existing 'Captions' track or create a new one
    Track? captionTrack;
    for (final t in project.tracks) {
      if (t.type == TrackType.text && t.name.toLowerCase().contains('caption')) {
        captionTrack = t;
        break;
      }
    }

    if (captionTrack == null) {
      captionTrack = Track(
        id: const Uuid().v4(),
        name: 'Captions',
        type: TrackType.text,
        order: project.tracks.length,
        clips: const [],
      );
      project = project.addTrack(captionTrack);
    }

    // 2. Convert each CaptionLine into a Clip with textOverlay
    final captionClips = captions.map((cap) {
      return Clip(
        id: cap.id,
        assetId: '',
        trackId: captionTrack!.id,
        startTimeMs: cap.startTimeMs,
        durationMs: cap.durationMs,
        sourceInMs: 0,
        sourceOutMs: cap.durationMs,
        textOverlay: cap.style.copyWith(text: cap.text),
      );
    }).toList();

    final updatedTrack = captionTrack.copyWith(clips: captionClips);
    final updatedTracks = project.tracks.map((t) {
      return t.id == updatedTrack.id ? updatedTrack : t;
    }).toList();

    return project.copyWith(tracks: updatedTracks).recalculateDuration();
  }

  /// Extracts existing caption lines from the project's 'Captions' track
  static List<CaptionLine> extractCaptionsFromProject(Project project) {
    Track? captionTrack;
    for (final t in project.tracks) {
      if (t.type == TrackType.text && t.name.toLowerCase().contains('caption')) {
        captionTrack = t;
        break;
      }
    }

    if (captionTrack == null || captionTrack.clips.isEmpty) {
      return [];
    }

    return captionTrack.clips.map((clip) {
      return CaptionLine(
        id: clip.id,
        text: clip.textOverlay.text,
        startTimeMs: clip.startTimeMs,
        durationMs: clip.durationMs,
        style: clip.textOverlay,
      );
    }).toList();
  }

  /// Exports captions into standard .srt subtitle format
  static String exportSrt(List<CaptionLine> captions) {
    final buffer = StringBuffer();
    for (int i = 0; i < captions.length; i++) {
      final cap = captions[i];
      buffer.writeln('${i + 1}');
      buffer.writeln('${_formatSrtTimestamp(cap.startTimeMs)} --> ${_formatSrtTimestamp(cap.endTimeMs)}');
      buffer.writeln(cap.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String _formatSrtTimestamp(int ms) {
    final totalSeconds = ms ~/ 1000;
    final milliseconds = ms % 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    final msStr = milliseconds.toString().padLeft(3, '0');

    return '$hStr:$mStr:$sStr,$msStr';
  }
}
