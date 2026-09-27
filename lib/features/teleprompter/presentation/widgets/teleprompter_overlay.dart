import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/teleprompter_config.dart';

class TeleprompterOverlay extends StatefulWidget {
  final TeleprompterConfig config;
  final Function(TeleprompterConfig updatedConfig)? onConfigChanged;
  final VoidCallback? onClose;

  const TeleprompterOverlay({
    super.key,
    required this.config,
    this.onConfigChanged,
    this.onClose,
  });

  @override
  State<TeleprompterOverlay> createState() => _TeleprompterOverlayState();
}

class _TeleprompterOverlayState extends State<TeleprompterOverlay> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  Timer? _countdownTimer;
  int _countdownRemaining = 0;
  bool _isScrolling = false;
  late int _currentWpm;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentWpm = widget.config.scrollSpeedWpm;
  }

  @override
  void didUpdateWidget(covariant TeleprompterOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.scrollSpeedWpm != widget.config.scrollSpeedWpm) {
      _currentWpm = widget.config.scrollSpeedWpm;
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startCountdownAndScroll() {
    if (widget.config.countdownSeconds > 0 && !_isScrolling) {
      setState(() {
        _countdownRemaining = widget.config.countdownSeconds;
      });
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _countdownRemaining--;
        });
        if (_countdownRemaining <= 0) {
          timer.cancel();
          _startScrolling();
        }
      });
    } else {
      _startScrolling();
    }
  }

  void _startScrolling() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownRemaining = 0;
      _isScrolling = true;
    });

    _scrollTimer?.cancel();
    final double pixelsPerSecond = (_currentWpm / 60.0) * (widget.config.fontSize * widget.config.lineHeight * 0.85);
    final double step = (pixelsPerSecond * 0.016).clamp(0.2, 10.0);

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (current >= max) {
        _pauseScrolling();
      } else {
        _scrollController.jumpTo((current + step).clamp(0.0, max));
      }
    });
  }

  void _pauseScrolling() {
    _scrollTimer?.cancel();
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isScrolling = false;
        _countdownRemaining = 0;
      });
    }
  }

  void _rewind() {
    _pauseScrolling();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _adjustSpeed(int delta) {
    setState(() {
      _currentWpm = (_currentWpm + delta).clamp(60, 300);
    });
    widget.onConfigChanged?.call(widget.config.copyWith(scrollSpeedWpm: _currentWpm));
    if (_isScrolling) {
      _startScrolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.config.isEnabled) return const SizedBox.shrink();

    final script = widget.config.activeScript;
    final double widthFactor = widget.config.windowWidth.clamp(0.3, 1.0);
    final double heightFactor = widget.config.windowHeight.clamp(0.2, 0.9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * widthFactor;
        final h = constraints.maxHeight * heightFactor;
        final top = constraints.maxHeight * widget.config.windowYOffset.clamp(0.05, 0.6);

        return Stack(
          children: [
            Positioned(
              left: (constraints.maxWidth - w) / 2,
              top: top,
              width: w,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(widget.config.backgroundOpacity.clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      // Content Column
                      Column(
                        children: [
                          _buildControlHeader(script.title),
                          Expanded(
                            child: Stack(
                              children: [
                                // Reading Focus Line Indicator
                                if (widget.config.isHighlightFocusLine)
                                  Positioned(
                                    top: (h - 40) / 2,
                                    left: 0,
                                    right: 0,
                                    height: widget.config.fontSize * widget.config.lineHeight + 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00F0FF).withOpacity(0.12),
                                        border: Border.symmetric(
                                          horizontal: BorderSide(
                                            color: const Color(0xFF00F0FF).withOpacity(0.35),
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Scrollable Script Body
                                Transform(
                                  alignment: Alignment.center,
                                  transform: widget.config.isMirrorMode
                                      ? (Matrix4.identity()..scale(-1.0, 1.0))
                                      : Matrix4.identity(),
                                  child: ListView(
                                    controller: _scrollController,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: (h - 40) / 2,
                                    ),
                                    children: [
                                      Text(
                                        script.content,
                                        textAlign: widget.config.textAlign,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: widget.config.fontSize,
                                          height: widget.config.lineHeight,
                                          fontWeight: FontWeight.w600,
                                          shadows: const [
                                            Shadow(
                                              blurRadius: 3.0,
                                              color: Colors.black84,
                                              offset: Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Countdown Overlay (3, 2, 1)
                      if (_countdownRemaining > 0)
                        Container(
                          color: Colors.black.withOpacity(0.75),
                          child: Center(
                            child: Text(
                              '$_countdownRemaining',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00F0FF),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over, color: Color(0xFF00F0FF), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Speed Controls
          IconButton(
            icon: const Icon(Icons.remove, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            style: IconButton.styleFrom(foregroundColor: Colors.white70),
            tooltip: 'Slower',
            onPressed: () => _adjustSpeed(-10),
          ),
          Text(
            '$_currentWpm WPM',
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            style: IconButton.styleFrom(foregroundColor: Colors.white70),
            tooltip: 'Faster',
            onPressed: () => _adjustSpeed(10),
          ),
          const SizedBox(width: 4),

          // Rewind
          IconButton(
            icon: const Icon(Icons.replay, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            style: IconButton.styleFrom(foregroundColor: Colors.white),
            tooltip: 'Rewind to Top',
            onPressed: _rewind,
          ),

          // Play / Pause
          IconButton(
            icon: Icon(
              _isScrolling ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: const Color(0xFF00F0FF),
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            style: IconButton.styleFrom(foregroundColor: const Color(0xFF00F0FF)),
            tooltip: _isScrolling ? 'Pause' : 'Start Prompting',
            onPressed: _isScrolling ? _pauseScrolling : _startCountdownAndScroll,
          ),

          if (widget.onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              style: IconButton.styleFrom(foregroundColor: Colors.white60),
              tooltip: 'Close Teleprompter',
              onPressed: widget.onClose,
            ),
          ],
        ],
      ),
    );
  }
}
