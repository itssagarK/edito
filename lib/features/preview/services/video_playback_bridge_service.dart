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

  bool _isInitializingVideo = false;
  bool _isInitializingAudio = false;

  final ValueNotifier<VideoPlayerController?> activeVideoController = ValueNotifier(null);
  final ValueNotifier<bool> isVideoReady = ValueNotifier(false);

  bool _isDisposed = false;

  VideoPlayerController? get videoController => _videoController;
  VideoPlayerController? get audioController => _audioController;

  /// Helper to create a VideoPlayerController from path or URI
  static VideoPlayerController createControllerForPath(String path) {
    if (path.startsWith('content://')) {
      return VideoPlayerController.contentUri(Uri.parse(path));
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      return VideoPlayerController.file(File(path));
    }
  }

  /// Helper to test if a file or URI path is valid and playable
  static bool isPlayablePath(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('content://') ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return true;
    }
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Synchronizes video and audio playback controllers with current timeline frame
  Future<void> syncPlayback({
    required CompositorFrame? frame,
    required bool isPlaying,
    required int timestampMs,
  }) async {
    if (_isDisposed) return;

    // 1. Sync Primary Video Clip
    await _syncVideoClip(frame, isPlaying, timestampMs);

    // 2. Sync Dedicated Secondary Audio Clip (Music / SFX only)
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

    if (!isPlayablePath(asset.path)) {
      // Asset is sample placeholder or missing, no local hardware texture
      activeVideoController.value = null;
      isVideoReady.value = false;
      return;
    }

    // If video path changed or controller is null, initialize new controller
    if (_currentVideoPath != asset.path || _videoController == null) {
      if (_isInitializingVideo) return; // Prevent concurrent re-entry
      _isInitializingVideo = true;
      _currentVideoPath = asset.path;
      isVideoReady.value = false;

      try {
        final oldController = _videoController;
        _videoController = null;
        activeVideoController.value = null;

        if (oldController != null) {
          try {
            await oldController.pause();
            await oldController.dispose();
          } catch (_) {}
        }

        final newController = createControllerForPath(asset.path);
        await newController.initialize();

        if (_isDisposed) {
          await newController.dispose();
          return;
        }

        _videoController = newController;
        activeVideoController.value = newController;
        isVideoReady.value = true;
      } catch (e) {
        debugPrint('VideoPlayer initialization error for ${asset.path}: $e');
        _currentVideoPath = null;
        _videoController = null;
        activeVideoController.value = null;
        isVideoReady.value = false;
        return;
      } finally {
        _isInitializingVideo = false;
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
      final maxVideoMs = _videoController!.value.duration.inMilliseconds;
      final targetVideoMs = clipLocalMs.clamp(0, maxVideoMs).toInt();
      final targetDuration = Duration(milliseconds: targetVideoMs);

      if (!isPlaying) {
        // Paused / Scrubbing mode: seek precisely to target frame
        final currentPos = _videoController!.value.position;
        final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();
        if (driftMs > 80) {
          await _videoController!.seekTo(targetDuration);
        }
        if (_videoController!.value.isPlaying) {
          await _videoController!.pause();
        }
      } else {
        // Active Playback mode:
        if (!_videoController!.value.isPlaying) {
          // If starting playback, first position to frame, then start
          await _videoController!.seekTo(targetDuration);
          await _videoController!.play();
        } else {
          // While already playing smoothly, do NOT seek repeatedly (which flushes ExoPlayer decoder)
          // Only resync if massive drift (> 1500ms) occurs
          final currentPos = _videoController!.value.position;
          final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();
          if (driftMs > 1500) {
            await _videoController!.seekTo(targetDuration);
          }
        }
      }
    } catch (e) {
      debugPrint('VideoPlayer sync error: $e');
    }
  }

  Future<void> _syncAudioClip(CompositorFrame? frame, bool isPlaying, int timestampMs) async {
    // Only handle secondary/standalone audio tracks (isPrimaryVideoAudio == false)
    ActiveAudioSource? secondaryAudio;
    if (frame != null) {
      for (final src in frame.activeAudioSources) {
        if (!src.isPrimaryVideoAudio && !src.isMuted && src.filePath != null) {
          secondaryAudio = src;
          break;
        }
      }
    }

    if (secondaryAudio == null || secondaryAudio.filePath == null) {
      if (_audioController != null) {
        try {
          await _audioController!.pause();
        } catch (_) {}
      }
      return;
    }

    final audioPath = secondaryAudio.filePath!;
    if (!isPlayablePath(audioPath)) return;

    if (_currentAudioPath != audioPath || _audioController == null) {
      if (_isInitializingAudio) return;
      _isInitializingAudio = true;
      _currentAudioPath = audioPath;

      try {
        final oldAudio = _audioController;
        _audioController = null;
        if (oldAudio != null) {
          try {
            await oldAudio.pause();
            await oldAudio.dispose();
          } catch (_) {}
        }

        final newAudio = createControllerForPath(audioPath);
        await newAudio.initialize();

        if (_isDisposed) {
          await newAudio.dispose();
          return;
        }

        _audioController = newAudio;
      } catch (e) {
        debugPrint('Audio controller init error for $audioPath: $e');
        _currentAudioPath = null;
        _audioController = null;
        return;
      } finally {
        _isInitializingAudio = false;
      }
    }

    if (_audioController == null || !_audioController!.value.isInitialized) return;

    try {
      final effectiveVolume = secondaryAudio.effectiveVolume.clamp(0.0, 1.0);
      _audioController!.setVolume(effectiveVolume);

      final maxDurationMs = _audioController!.value.duration.inMilliseconds;
      final targetAudioMs = secondaryAudio.sourceOffsetMs.clamp(0, maxDurationMs).toInt();
      final targetDuration = Duration(milliseconds: targetAudioMs);

      if (!isPlaying) {
        final currentPos = _audioController!.value.position;
        final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();
        if (driftMs > 80) {
          await _audioController!.seekTo(targetDuration);
        }
        if (_audioController!.value.isPlaying) {
          await _audioController!.pause();
        }
      } else {
        if (!_audioController!.value.isPlaying) {
          await _audioController!.seekTo(targetDuration);
          await _audioController!.play();
        } else {
          final currentPos = _audioController!.value.position;
          final driftMs = (currentPos.inMilliseconds - targetDuration.inMilliseconds).abs();
          if (driftMs > 1500) {
            await _audioController!.seekTo(targetDuration);
          }
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
    try {
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    try {
      _audioController?.pause();
      _audioController?.dispose();
    } catch (_) {}
    activeVideoController.dispose();
    isVideoReady.dispose();
  }
}
