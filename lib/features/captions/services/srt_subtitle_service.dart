import 'package:uuid/uuid.dart';
import '../models/caption_line.dart';

class SrtSubtitleService {
  /// Parses standard SubRip (.srt) subtitle string into a List of CaptionLines with word timings
  static List<CaptionLine> parseSrt(
    String srtContent, {
    CaptionPreset preset = CaptionPreset.tiktokViral,
  }) {
    final lines = srtContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final captions = <CaptionLine>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Check if line is a sequence number
      final isSeqNumber = int.tryParse(line) != null;
      if (isSeqNumber && i + 1 < lines.length && lines[i + 1].contains('-->')) {
        i++; // advance to timecode line
      }

      if (i < lines.length && lines[i].contains('-->')) {
        final timeParts = lines[i].split('-->');
        if (timeParts.length == 2) {
          final startMs = _parseTimestampMs(timeParts[0].trim());
          final endMs = _parseTimestampMs(timeParts[1].trim());
          final durationMs = (endMs - startMs).clamp(200, 30000);

          i++;
          // Accumulate subtitle text until empty line or next index
          final textBuffer = StringBuffer();
          while (i < lines.length && lines[i].trim().isNotEmpty && !lines[i].contains('-->')) {
            if (int.tryParse(lines[i].trim()) != null && (i + 1 < lines.length && lines[i + 1].contains('-->'))) {
              break; // Next block started
            }
            if (textBuffer.isNotEmpty) textBuffer.write(' ');
            textBuffer.write(lines[i].trim());
            i++;
          }

          final text = textBuffer.toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (text.isNotEmpty) {
            final words = CaptionLine.generateInterpolatedWords(text, durationMs);
            captions.add(CaptionLine(
              id: const Uuid().v4(),
              text: text,
              startTimeMs: startMs,
              durationMs: durationMs,
              style: preset.createStyle(text),
              words: words,
              highlightStyle: KaraokeHighlightStyle.colorFill,
            ));
          }
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    return captions;
  }

  /// Exports a list of CaptionLines to standard SubRip (.srt) subtitle format
  static String exportToSrt(List<CaptionLine> captions) {
    final sorted = List<CaptionLine>.from(captions)
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    final sb = StringBuffer();
    for (int i = 0; i < sorted.length; i++) {
      final cap = sorted[i];
      final index = i + 1;
      final startStr = _formatSrtTimestamp(cap.startTimeMs);
      final endStr = _formatSrtTimestamp(cap.endTimeMs);

      sb.writeln('$index');
      sb.writeln('$startStr --> $endStr');
      sb.writeln(cap.text);
      sb.writeln();
    }
    return sb.toString().trim();
  }

  /// Exports a list of CaptionLines to WebVTT (.vtt) format
  static String exportToVtt(List<CaptionLine> captions) {
    final sorted = List<CaptionLine>.from(captions)
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    final sb = StringBuffer();
    sb.writeln('WEBVTT');
    sb.writeln();

    for (int i = 0; i < sorted.length; i++) {
      final cap = sorted[i];
      final index = i + 1;
      final startStr = _formatVttTimestamp(cap.startTimeMs);
      final endStr = _formatVttTimestamp(cap.endTimeMs);

      sb.writeln('$index');
      sb.writeln('$startStr --> $endStr');
      sb.writeln(cap.text);
      sb.writeln();
    }
    return sb.toString().trim();
  }

  static int _parseTimestampMs(String timeStr) {
    // Standard format: 00:01:23,456 or 00:01:23.456
    try {
      final normalized = timeStr.replaceAll(',', '.');
      final parts = normalized.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1 ? int.parse(secParts[1].padRight(3, '0').substring(0, 3)) : 0;
        return (hours * 3600 + minutes * 60 + seconds) * 1000 + millis;
      }
    } catch (_) {}
    return 0;
  }

  static String _formatSrtTimestamp(int ms) {
    final totalSec = ms ~/ 1000;
    final millis = ms % 1000;
    final hours = totalSec ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    final seconds = totalSec % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    final msStr = millis.toString().padLeft(3, '0');

    return '$hStr:$mStr:$sStr,$msStr';
  }

  static String _formatVttTimestamp(int ms) {
    final totalSec = ms ~/ 1000;
    final millis = ms % 1000;
    final hours = totalSec ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    final seconds = totalSec % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    final msStr = millis.toString().padLeft(3, '0');

    return '$hStr:$mStr:$sStr.$msStr';
  }
}
