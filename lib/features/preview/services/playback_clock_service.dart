import 'dart:async';

class PlaybackClockService {
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _startPositionMs = 0;
  int _maxDurationMs = 0;
  double _playbackRate = 1.0;
  bool _isPlaying = false;

  final StreamController<int> _tickController = StreamController<int>.broadcast();
  Stream<int> get tickStream => _tickController.stream;

  bool get isPlaying => _isPlaying;

  void start({
    required int startPositionMs,
    required int maxDurationMs,
    double playbackRate = 1.0,
  }) {
    pause();
    _startPositionMs = startPositionMs;
    _maxDurationMs = maxDurationMs;
    _playbackRate = playbackRate;
    _isPlaying = true;

    _stopwatch.reset();
    _stopwatch.start();

    // 60 FPS tick timer (~16ms intervals)
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsedMs = (_stopwatch.elapsedMilliseconds * _playbackRate).round();
      final currentPos = _startPositionMs + elapsedMs;

      if (_maxDurationMs > 0 && currentPos >= _maxDurationMs) {
        _tickController.add(_maxDurationMs);
        pause();
      } else {
        _tickController.add(currentPos);
      }
    });
  }

  void pause() {
    _isPlaying = false;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
  }

  void seek(int targetPositionMs) {
    if (_isPlaying) {
      start(
        startPositionMs: targetPositionMs,
        maxDurationMs: _maxDurationMs,
        playbackRate: _playbackRate,
      );
    }
  }

  void dispose() {
    pause();
    _tickController.close();
  }
}
