import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../../audio/models/audio_effects_config.dart';
import '../models/tts_voice_profile.dart';
import 'offline_wav_synthesizer.dart';

class TtsGenerationResult {
  final bool isSuccess;
  final Project? project;
  final String? audioPath;
  final int durationMs;
  final String? errorMessage;

  const TtsGenerationResult({
    required this.isSuccess,
    this.project,
    this.audioPath,
    this.durationMs = 0,
    this.errorMessage,
  });
}

class AiVoiceGenerationService {
  static const MethodChannel _galleryChannel = MethodChannel('com.edito.app/gallery');

  /// Generates a real voiceover audio file completely offline using On-Device Android Speech
  /// or high-fidelity offline PCM synthesis, placing it onto the project timeline.
  static Future<TtsGenerationResult> generateVoiceover({
    required Project project,
    required String script,
    required TTSVoiceProfile voice,
    double speedRate = 1.0,
    double pitchShift = 0.0,
    required int startTimeMs,
    bool autoCaptions = true,
  }) async {
    final cleanScript = script.trim();
    if (cleanScript.isEmpty) {
      return const TtsGenerationResult(
        isSuccess: false,
        errorMessage: 'Script text cannot be empty.',
      );
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final ttsDir = Directory(p.join(docDir.path, 'tts'));
      if (!await ttsDir.exists()) {
        await ttsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File(p.join(ttsDir.path, 'voiceover_${voice.id}_$timestamp.wav'));

      int durationMs = 0;
      bool synthesized = false;

      // 1. Attempt Native Android On-Device TTS synthesis via platform channel
      try {
        final double effectivePitch = (1.0 + (voice.defaultPitch + pitchShift) * 0.1).clamp(0.5, 2.0);
        final dynamic channelResult = await _galleryChannel.invokeMethod('synthesizeSpeechToFile', {
          'text': cleanScript,
          'outputPath': outputFile.absolutePath,
          'language': 'en_US',
          'pitch': effectivePitch,
          'speechRate': speedRate.clamp(0.5, 2.5),
          'voiceName': null,
        });

        if (channelResult is Map && channelResult['success'] == true) {
          final file = File(outputFile.absolutePath);
          if (file.existsSync() && file.lengthSync() > 100) {
            synthesized = true;
            durationMs = (channelResult['durationMs'] as num?)?.toInt() ?? 0;
            if (durationMs <= 0) {
              durationMs = _estimateDurationFromScript(cleanScript, speedRate);
            }
          }
        }
      } catch (e) {
        debugPrint('Native Android TTS channel not available or returned error: $e');
      }

      // 2. Offline Fallback: Synthesize genuine PCM WAV audio with speech cadence & formants
      if (!synthesized) {
        durationMs = await OfflineWavSynthesizer.synthesizeToWavFile(
          outputPath: outputFile.absolutePath,
          script: cleanScript,
          voice: voice,
          speechRate: speedRate,
          pitchShift: pitchShift,
        );
        synthesized = outputFile.existsSync() && outputFile.lengthSync() > 100;
      }

      if (!synthesized) {
        return const TtsGenerationResult(
          isSuccess: false,
          errorMessage: 'Could not write synthesized audio file to disk.',
        );
      }

      // 3. Register MediaAsset in project (List<MediaAsset>)
      final assetId = 'tts_${const Uuid().v4().substring(0, 8)}';
      final mediaAsset = MediaAsset(
        id: assetId,
        path: outputFile.absolutePath,
        fileName: p.basename(outputFile.path),
        type: MediaType.audio,
        durationMs: durationMs,
      );

      final updatedAssets = List<MediaAsset>.from(project.assets)..add(mediaAsset);

      // 4. Find or create audio track for voiceover
      final updatedTracks = <Track>[];
      bool trackFound = false;

      for (final track in project.tracks) {
        if (track.type == TrackType.audio && !trackFound) {
          final newClip = Clip(
            id: 'clip_${const Uuid().v4().substring(0, 8)}',
            assetId: assetId,
            trackId: track.id,
            startTimeMs: startTimeMs,
            durationMs: durationMs,
            sourceInMs: 0,
            sourceOutMs: durationMs,
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
          id: 'clip_${const Uuid().v4().substring(0, 8)}',
          assetId: assetId,
          trackId: newTrackId,
          startTimeMs: startTimeMs,
          durationMs: durationMs,
          sourceInMs: 0,
          sourceOutMs: durationMs,
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

      final updatedProject = project.copyWith(
        assets: updatedAssets,
        tracks: updatedTracks,
      ).recalculateDuration();

      return TtsGenerationResult(
        isSuccess: true,
        project: updatedProject,
        audioPath: outputFile.absolutePath,
        durationMs: durationMs,
      );
    } catch (e) {
      debugPrint('Voiceover generation error: $e');
      return TtsGenerationResult(
        isSuccess: false,
        errorMessage: 'Failed to synthesize voiceover: $e',
      );
    }
  }

  static int _estimateDurationFromScript(String script, double speedRate) {
    final words = script.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final effectiveRate = speedRate.clamp(0.5, 2.5);
    final msPerWord = (60000.0 / (150.0 * effectiveRate)).round();
    return (words * msPerWord).clamp(1200, 3600000);
  }
}
