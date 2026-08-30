class TimecodeFormatter {
  /// Formats milliseconds into standard MM:SS.SS or HH:MM:SS format
  static String formatMilliseconds(int milliseconds, {bool showHours = false}) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hundredths = (duration.inMilliseconds.remainder(1000) / 10).floor();

    if (showHours || hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${hundredths.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${hundredths.toString().padLeft(2, '0')}';
    }
  }

  /// Formats time in SMPTE timecode (HH:MM:SS:FF)
  static String formatSmpte(int milliseconds, {int fps = 30}) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final frame = ((duration.inMilliseconds.remainder(1000) / 1000.0) * fps).floor();

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}:'
        '${frame.toString().padLeft(2, '0')}';
  }
}
