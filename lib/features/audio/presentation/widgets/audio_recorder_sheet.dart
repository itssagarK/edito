import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/services/timecode_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../services/audio_recorder_service.dart';

enum RecordingStudioState {
  ready,
  countdown,
  recording,
  preview,
}

class AudioRecorderSheet extends StatefulWidget {
  final Project project;
  final int currentPlayheadMs;
  final Function(Project updatedProject) onProjectUpdated;
  final VoidCallback? onDone;

  const AudioRecorderSheet({
    super.key,
    required this.project,
    this.currentPlayheadMs = 0,
    required this.onProjectUpdated,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    int currentPlayheadMs = 0,
    required Function(Project) onProjectUpdated,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AudioRecorderSheet(
        project: project,
        currentPlayheadMs: currentPlayheadMs,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<AudioRecorderSheet> with SingleTickerProviderStateMixin {
  RecordingStudioState _state = RecordingStudioState.ready;
  String? _recordedFilePath;
  int _recordedDurationMs = 0;

  // Countdown
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  // Live Recording Tracking
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  final List<double> _amplitudeHistory = List.filled(36, 0.08);
  double _currentAmplitude = 0.0;

  // Preview Playback
  VideoPlayerController? _previewController;
  bool _isPlayingPreview = false;
  int _previewPositionMs = 0;

  // Pulsing animation for recording badge
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _stopwatch.stop();
    _pulseController.dispose();
    _disposePreviewController();
    super.dispose();
  }

  void _disposePreviewController() {
    _previewController?.pause();
    _previewController?.dispose();
    _previewController = null;
  }

  void _startCountdown() {
    setState(() {
      _state = RecordingStudioState.countdown;
      _countdownSeconds = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _beginRecording();
      }
    });
  }

  Future<void> _beginRecording() async {
    _countdownTimer?.cancel();
    final targetPath = await AudioRecorderService.generateVoiceoverPath();
    final success = await AudioRecorderService.startRecording(targetPath);

    if (!success) {
      if (!mounted) return;
      setState(() => _state = RecordingStudioState.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Unable to start microphone recording. Check permissions.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _stopwatch.reset();
    _stopwatch.start();

    setState(() {
      _state = RecordingStudioState.recording;
      _recordedFilePath = targetPath;
      _amplitudeHistory.fillRange(0, _amplitudeHistory.length, 0.08);
    });

    // Recording duration tick
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {});
    });

    // Amplitude polling for dynamic VU waveform
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 65), (_) async {
      final amp = await AudioRecorderService.getRecordingAmplitude();
      if (!mounted || _state != RecordingStudioState.recording) return;

      // Android MediaRecorder returns 0..32767
      final normalized = (amp / 28000.0).clamp(0.06, 1.0);
      setState(() {
        _currentAmplitude = normalized;
        _amplitudeHistory.removeAt(0);
        _amplitudeHistory.add(normalized);
      });
    });
  }

  Future<void> _stopRecording() async {
    _stopwatch.stop();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    final result = await AudioRecorderService.stopRecording();
    final finalDuration = result?.durationMs ?? _stopwatch.elapsedMilliseconds;

    if (result == null || finalDuration < 400) {
      if (!mounted) return;
      setState(() => _state = RecordingStudioState.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording too short (minimum 0.5s required)'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    _recordedDurationMs = finalDuration;
    _initPreviewController(result.filePath);

    setState(() {
      _state = RecordingStudioState.preview;
      _recordedFilePath = result.filePath;
    });
  }

  void _initPreviewController(String filePath) {
    _disposePreviewController();
    final file = File(filePath);
    if (!file.existsSync()) return;

    _previewController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      })
      ..addListener(() {
        if (!mounted || _previewController == null) return;
        final pos = _previewController!.value.position.inMilliseconds;
        final isPlaying = _previewController!.value.isPlaying;
        if (pos != _previewPositionMs || isPlaying != _isPlayingPreview) {
          setState(() {
            _previewPositionMs = pos;
            _isPlayingPreview = isPlaying;
          });
        }
      });
  }

  void _togglePreviewPlayback() {
    if (_previewController == null || !_previewController!.value.isInitialized) return;
    if (_previewController!.value.isPlaying) {
      _previewController!.pause();
    } else {
      if (_previewController!.value.position >= _previewController!.value.duration) {
        _previewController!.seekTo(Duration.zero);
      }
      _previewController!.play();
    }
  }

  void _discardRecording() {
    _disposePreviewController();
    if (_recordedFilePath != null) {
      try {
        final f = File(_recordedFilePath!);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    setState(() {
      _state = RecordingStudioState.ready;
      _recordedFilePath = null;
      _recordedDurationMs = 0;
      _previewPositionMs = 0;
      _isPlayingPreview = false;
    });
  }

  void _applyToTimeline() {
    if (_recordedFilePath == null || _recordedDurationMs < 300) return;

    final updatedProject = AudioRecorderService.insertVoiceoverIntoProject(
      project: widget.project,
      filePath: _recordedFilePath!,
      durationMs: _recordedDurationMs,
      startTimeMs: widget.currentPlayheadMs,
    );

    widget.onProjectUpdated(updatedProject);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎙️ Voiceover inserted at ${TimecodeFormatter.formatMilliseconds(widget.currentPlayheadMs)} (${(_recordedDurationMs / 1000).toStringAsFixed(1)}s)'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Voiceover Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          'Insert position: ${TimecodeFormatter.formatMilliseconds(widget.currentPlayheadMs)}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    if (_state == RecordingStudioState.recording) {
                      _stopRecording();
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // State-Specific Display Area
            if (_state == RecordingStudioState.countdown)
              _buildCountdownView()
            else if (_state == RecordingStudioState.recording)
              _buildRecordingView()
            else if (_state == RecordingStudioState.preview)
              _buildPreviewView()
            else
              _buildReadyView(),
          ],
        ),
      ),
    );
  }

  // Ready State View
  Widget _buildReadyView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                'Ready to Record',
                style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Live voiceover will be synced directly to timeline at playhead position',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Big Record Button
              GestureDetector(
                onTap: _startCountdown,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(0.15),
                    border: Border.all(color: Colors.redAccent, width: 3),
                  ),
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('TAP TO RECORD', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ],
          ),
        ),
      ],
    );
  }

  // Countdown View
  Widget _buildCountdownView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Text(
              '$_countdownSeconds',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Get ready to speak...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _beginRecording,
            child: const Text('Skip Countdown ➔', style: TextStyle(color: AppColors.accent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Active Recording View
  Widget _buildRecordingView() {
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final seconds = (elapsedMs ~/ 1000) % 60;
    final minutes = (elapsedMs ~/ 60000);
    final hundredths = (elapsedMs % 1000) ~/ 10;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundredths.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
          ),
          child: Column(
            children: [
              // Live Recording Pill Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RECORDING LIVE',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Timer
              Text(
                timeStr,
                style: const TextStyle(fontSize: 34, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white),
              ),

              const SizedBox(height: 16),

              // Live Waveform Visualizer
              SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _amplitudeHistory.map((amp) {
                    final barHeight = math.max(6.0, amp * 52.0);
                    final color = amp > 0.7
                        ? Colors.redAccent
                        : amp > 0.4
                            ? Colors.amberAccent
                            : AppColors.accent;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      width: 4.5,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Stop Recording Button
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(0.2),
                    border: Border.all(color: Colors.redAccent, width: 2.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('TAP TO STOP', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // Preview & Timeline Insertion View
  Widget _buildPreviewView() {
    final durSec = (_recordedDurationMs / 1000.0).toStringAsFixed(1);
    final posSec = (_previewPositionMs / 1000.0).toStringAsFixed(1);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF20BF6B), size: 18),
                      SizedBox(width: 6),
                      Text('Voiceover Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${durSec}s', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Audio Playback Bar
              Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(38, 38),
                    ),
                    icon: Icon(_isPlayingPreview ? Icons.pause : Icons.play_arrow, size: 22),
                    onPressed: _togglePreviewPlayback,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _recordedDurationMs > 0 ? (_previewPositionMs / _recordedDurationMs).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${posSec}s', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            Text('${durSec}s', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons: Retake & Add to Timeline
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retake'),
                onPressed: _discardRecording,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add to Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _applyToTimeline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
