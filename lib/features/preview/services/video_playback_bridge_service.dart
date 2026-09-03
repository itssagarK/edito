import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../models/media_asset.dart';
import '../models/compositor_frame.dart';

class VideoPlaybackBridgeService {
  VideoPlayerController? _videoController;
  VideoPlayerController? _audioController;

  String? _currentVideoPath;
  String? _currentAudioPath;

  final ValueNotifier<VideoPlayerController?> activeVideoController = ValueNotifier(null);
  final ValueNotifier<bool> isVideoReady = ValueNotifier(false);

  bool _isDisposed = false;

  VideoPlayerController? get videoController => _videoController;
  VideoPlayerController? get audioController => _audioController;

  /// Synchronizes video and audio playback controllers with current timeline frame
  Future<void> syncPlayback({
    required CompositorFrame? frame,
    required bool isPlaying,
    required int timestampMs,
  }) async {
    if (_isDisposed) return;

    // 1. Sync Primary Video Clip
    await _syncVideoClip(frame, isPlaying, timestampMs);

    // 2. Sync Primary Audio Clip
    await _syncAudioClip(frame, isPlaying, timestampMs);
  }

  Future<void> _syncVideoClip(CompositorFrame? frame, bool isPlaying, int timestampMs) async {
    final clip = frame?.primaryVideoClip;
    final asset = frame?.primaryAsset;

    if (clip == null || asset == null || asset.type != MediaType.video) {
      if (_videoController != null) {
        try {
          await _videoController!.pause();
        } catch (_) {}
      }
      activeVideoController.value = null;
      isVideoReady.value = false;
      return;
    }

    final videoFile = File(asset.path);
    final fileExists = videoFile.existsSync();

    if (!fileExists) {
      // Asset is sample placeholder, no local file to play
      activeVideoController.value = null;
      isVideoReady.value = false;
      return;
    }

    // If video path changed, initialize new controller
    if (_currentVideoPath != asset.path || _videoController == null) {
      _currentVideoPath = asset.path;
      isVideoReady.value = false;

      try {
        await _videoController?.dispose();
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();

        if (_isDisposed) return;

        activeVideoController.value = _videoController;
        isVideoReady.value = true;
      } catch (e) {
        debugPrint('VideoPlayer initialization error: $e');
        activeVideoController.value = null;
        isVideoReady.value = false;
        return;
      }
    }

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    // Configure Audio volume & speed for video clip
    try {
      final effectiveVolume = clip.isMuted
          ? 0.0
          : (clip.volume *
              (clip.audioEffects.isDuckingEnabled ? clip.audioEffects.duckingAttenuation : 1.0) *
              (clip.audioEffects.isLoudVoiceEnabled ? clip.audioEffects.voiceBoost : 1.0))
              .clamp(0.0, 1.0);

      _videoController!.setVolume(effectiveVolume);
      _videoController!.setPlaybackSpeed(clip.speed.clamp(0.25, 4.0));

      // Calculate target time within source video
      final clipLocalMs = timestampMs - clip.startTimeMs + clip.sourceInMs;
      final targetDuration = Duration(milliseconds: clipLocalMs.clamp(0, _videoController!.value.duration.inMilliseconds));

      // Drift check: If position drifts by more than 350ms, seek to exact frame
      final currentPos = _videoController!.value.position;
      final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();

      if (driftMs > 350 || !isPlaying) {
        await _videoController!.seekTo(targetDuration);
      }

      if (isPlaying) {
        if (!_videoController!.value.isPlaying) {
          await _videoController!.play();
        }
      } else {
        if (_videoController!.value.isPlaying) {
          await _videoController!.pause();
        }
      }
    } catch (e) {
      debugPrint('VideoPlayer sync error: $e');
    }
  }

  Future<void> _syncAudioClip(CompositorFrame? frame, bool isPlaying, int timestampMs) async {
    final audioClip = frame?.activeAudioClips.isNotEmpty == true ? frame!.activeAudioClips.first : null;
    if (audioClip == null) {
      if (_audioController != null) {
        try {
          await _audioController!.pause();
        } catch (_) {}
      }
      return;
    }

    // Find audio asset path
    final audioAsset = frame?.primaryAsset?.type == MediaType.audio
        ? frame?.primaryAsset
        : null;

    if (audioAsset == null) return;
    final audioFile = File(audioAsset.path);
    if (!audioFile.existsSync()) return;

    if (_currentAudioPath != audioAsset.path || _audioController == null) {
      _currentAudioPath = audioAsset.path;
      try {
        await _audioController?.dispose();
        _audioController = VideoPlayerController.file(audioFile);
        await _audioController!.initialize();
      } catch (e) {
        debugPrint('Audio controller init error: $e');
        return;
      }
    }

    if (_audioController == null || !_audioController!.value.isInitialized) return;

    try {
      final effectiveVolume = audioClip.isMuted ? 0.0 : audioClip.volume.clamp(0.0, 1.0);
      _audioController!.setVolume(effectiveVolume);
      _audioController!.setPlaybackSpeed(audioClip.speed.clamp(0.25, 4.0));

      final clipLocalMs = timestampMs - audioClip.startTimeMs + audioClip.sourceInMs;
      final targetDuration = Duration(milliseconds: clipLocalMs.clamp(0, _audioController!.value.duration.inMilliseconds));

      final currentPos = _audioController!.value.position;
      final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();

      if (driftMs > 350 || !isPlaying) {
        await _audioController!.seekTo(targetDuration);
      }

      if (isPlaying) {
        if (!_audioController!.value.isPlaying) {
          await _audioController!.play();
        }
      } else {
        if (_audioController!.value.isPlaying) {
          await _audioController!.pause();
        }
      }
    } catch (_) {}
  }

  void play() {
    _videoController?.play();
    _audioController?.play();
  }

  void pause() {
    _videoController?.pause();
    _audioController?.pause();
  }

  void dispose() {
    _isDisposed = true;
    _videoController?.dispose();
    _audioController?.dispose();
    activeVideoController.dispose();
    isVideoReady.dispose();
  }
}
