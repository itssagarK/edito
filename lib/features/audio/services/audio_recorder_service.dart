import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../models/audio_effects_config.dart';

class AudioRecordingResult {
  final bool success;
  final String filePath;
  final int durationMs;
  final int fileSize;

  const AudioRecordingResult({
    required this.success,
    required this.filePath,
    required this.durationMs,
    required this.fileSize,
  });
}

class AudioRecorderService {
  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');

  /// Generates a unique output path on disk for voiceover recordings
  static Future<String> generateVoiceoverPath() async {
    final tempDir = await getTemporaryDirectory();
    final voiceDir = Directory('${tempDir.path}/voiceovers');
    if (!voiceDir.existsSync()) {
      voiceDir.createSync(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${voiceDir.path}/voiceover_$timestamp.m4a';
  }

  /// Starts hardware microphone recording directly to a destination AAC file
  static Future<bool> startRecording(String outputPath) async {
    try {
      final res = await _channel.invokeMethod<bool>('startAudioRecording', {
        'outputPath': outputPath,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('AudioRecorderService startRecording error: $e');
      return false;
    }
  }

  /// Stops current hardware audio recording session and returns file metadata
  static Future<AudioRecordingResult?> stopRecording() async {
    try {
      final res = await _channel.invokeMethod<Map>('stopAudioRecording');
      if (res != null && res['success'] == true) {
        return AudioRecordingResult(
          success: true,
          filePath: res['filePath'] as String? ?? '',
          durationMs: (res['durationMs'] as num?)?.toInt() ?? 0,
          fileSize: (res['fileSize'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (e) {
      debugPrint('AudioRecorderService stopRecording error: $e');
    }
    return null;
  }

  /// Queries the live peak amplitude (0 - 32767) from Android MediaRecorder
  static Future<int> getRecordingAmplitude() async {
    try {
      final res = await _channel.invokeMethod<int>('getAudioRecordingAmplitude');
      return res ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Adds the recorded voiceover asset and creates an audio clip placed exactly
  /// at the target playhead timestamp on an audio track.
  static Project insertVoiceoverIntoProject({
    required Project project,
    required String filePath,
    required int durationMs,
    required int startTimeMs,
    String? customTitle,
  }) {
    final effectiveDuration = durationMs.clamp(500, 3600000);
    final assetId = 'asset_vo_${const Uuid().v4().substring(0, 8)}';
    final fileName = filePath.split(Platform.pathSeparator).last;

    final newAsset = MediaAsset(
      id: assetId,
      path: filePath,
      fileName: customTitle ?? fileName,
      type: MediaType.audio,
      durationMs: effectiveDuration,
      fileSize: File(filePath).existsSync() ? File(filePath).lengthSync() : 0,
      hasAudio: true,
    );

    final updatedAssets = List<MediaAsset>.from(project.assets)..add(newAsset);
    final updatedTracks = <Track>[];
    bool trackFound = false;

    for (final track in project.tracks) {
      if (track.type == TrackType.audio && !trackFound) {
        final newClipId = 'clip_vo_${const Uuid().v4().substring(0, 8)}';
        final newClip = Clip(
          id: newClipId,
          assetId: assetId,
          trackId: track.id,
          startTimeMs: startTimeMs,
          durationMs: effectiveDuration,
          sourceInMs: 0,
          sourceOutMs: effectiveDuration,
          volume: 1.0,
          speed: 1.0,
          audioEffects: const AudioEffectsConfig(
            isLoudVoiceEnabled: true,
            voiceBoost: 1.15,
            isVoiceEnhancerEnabled: true,
          ),
        );
        final updatedClips = List<Clip>.from(track.clips)..add(newClip)
          ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
        updatedTracks.add(track.copyWith(clips: updatedClips));
        trackFound = true;
      } else {
        updatedTracks.add(track);
      }
    }

    if (!trackFound) {
      final newTrackId = 'track_voiceover_${const Uuid().v4().substring(0, 8)}';
      final newClip = Clip(
        id: 'clip_vo_${const Uuid().v4().substring(0, 8)}',
        assetId: assetId,
        trackId: newTrackId,
        startTimeMs: startTimeMs,
        durationMs: effectiveDuration,
        sourceInMs: 0,
        sourceOutMs: effectiveDuration,
        volume: 1.0,
        speed: 1.0,
        audioEffects: const AudioEffectsConfig(
          isLoudVoiceEnabled: true,
          voiceBoost: 1.15,
          isVoiceEnhancerEnabled: true,
        ),
      );
      updatedTracks.add(Track(
        id: newTrackId,
        type: TrackType.audio,
        name: '🎙️ Voiceover',
        clips: [newClip],
      ));
    }

    return project.copyWith(
      assets: updatedAssets,
      tracks: updatedTracks,
    ).recalculateDuration();
  }
}
