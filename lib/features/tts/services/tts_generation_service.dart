import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../../models/clip.dart';
import '../../../../models/media_asset.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../audio/models/audio_effects_config.dart';
import '../../captions/models/caption_line.dart';
import '../models/tts_voice_profile.dart';

class TTSGenerationService {
  /// Estimates spoken duration in milliseconds from text and speech rate
  static int estimateSpokenDurationMs({
    required String script,
    double speechRate = 1.0,
  }) {
    final cleanText = script.trim();
    if (cleanText.isEmpty) return 1000;

    final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;

    // Punctuation pauses
    final longPauses = RegExp(r'[.!?]').allMatches(cleanText).length;
    final shortPauses = RegExp(r'[,;:]').allMatches(cleanText).length;

    final effectiveRate = speechRate.clamp(0.5, 2.0);
    // Standard baseline: 150 words per minute = 400ms per word at 1.0x
    final msPerWord = (60000.0 / (150.0 * effectiveRate)).round();
    final wordsDurationMs = wordCount * msPerWord;

    final pauseDurationMs = (longPauses * 320) + (shortPauses * 140);
    final totalMs = wordsDurationMs + pauseDurationMs;

    return totalMs.clamp(1200, 3600000); // 1.2s to 60 minutes
  }

  /// Generates a realistic PCM waveform data series simulating human speech cadence
  static List<double> generateRealisticWaveform(int durationMs, {int sampleCount = 64}) {
    final rand = Random(durationMs);
    final samples = <double>[];

    // Speech typically alternates between vocal bursts and inter-word pauses
    for (int i = 0; i < sampleCount; i++) {
      final progress = i / sampleCount;
      // Cadence wave simulating phrasing breath
      final phraseEnvelope = (sin(progress * pi * 5).abs() * 0.7) + 0.2;
      final jitter = (rand.nextDouble() * 0.3) - 0.15;
      final val = (phraseEnvelope + jitter).clamp(0.08, 0.95);
      samples.add(double.parse(val.toStringAsFixed(2)));
    }

    return samples;
  }

  /// Compiles FFmpeg synthetic speech synthesis filter expression for export
  static String generateSpeechFFmpegFilter(TTSConfig config, {required int durationMs}) {
    final durationSec = (durationMs / 1000.0).toStringAsFixed(2);
    final semitoneFactor = pow(2.0, config.pitchShift / 12.0);
    final f0 = (config.voice.fundamentalHz * semitoneFactor).round().clamp(50, 450);
    final f1 = config.voice.f1Hz;
    final f2 = config.voice.f2Hz;

    // Harmonic formant synthesis carrier with vocal tract bandpass resonances
    return "aevalsrc='0.4*sin(2*PI*$f0*t)*(1+0.4*sin(2*PI*5*t)) + "
        "0.25*sin(2*PI*${f0 * 2}*t) + 0.15*sin(2*PI*${f0 * 3}*t):d=$durationSec', "
        "bandpass=f=$f1:width_type=h:w=200, "
        "bandpass=f=$f2:width_type=h:w=300, "
        "volume=${config.volumeBoost.toStringAsFixed(2)}, "
        "alimiter=limit=0.95:attack=5:release=50:asc=1";
  }

  /// Generates and inserts a synthesized voiceover audio clip into the project timeline
  static Project insertVoiceoverClip({
    required Project project,
    required TTSConfig config,
    required int startTimeMs,
  }) {
    final durationMs = estimateSpokenDurationMs(
      script: config.scriptText,
      speechRate: config.speechRate,
    );

    final waveform = generateRealisticWaveform(durationMs);
    final uuid = const Uuid().v4();
    final assetId = 'tts_asset_${uuid.substring(0, 8)}';
    final fileName = 'Voiceover_${config.voice.displayName.split(' ').first}.m4a';

    final ttsAsset = MediaAsset(
      id: assetId,
      path: fileName,
      fileName: fileName,
      type: MediaType.audio,
      durationMs: durationMs,
      waveform: waveform,
    );

    final newClip = Clip(
      id: 'tts_clip_${uuid.substring(0, 8)}',
      assetId: assetId,
      startTimeMs: startTimeMs,
      durationMs: durationMs,
      sourceInMs: 0,
      sourceOutMs: durationMs,
      audioEffects: AudioEffectsConfig(
        volume: config.volumeBoost,
        aiVoiceBoost: true,
      ),
    );

    // Find first audio track or create a dedicated voiceover track
    Track? targetTrack;
    for (final track in project.tracks) {
      if (track.type == TrackType.audio && track.name.toLowerCase().contains('voice')) {
        targetTrack = track;
        break;
      }
    }
    targetTrack ??= project.tracks.firstWhere(
      (t) => t.type == TrackType.audio,
      orElse: () {
        final newTrack = Track(
          id: 'track_tts_${uuid.substring(0, 8)}',
          type: TrackType.audio,
          name: '🎙️ AI Voiceover',
        );
        return newTrack;
      },
    );

    final updatedClips = [...targetTrack.clips, newClip]
      ..sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

    final updatedTrack = targetTrack.copyWith(clips: updatedClips);

    final updatedTracks = project.tracks.contains(targetTrack)
        ? project.tracks.map((t) => t.id == targetTrack!.id ? updatedTrack : t).toList()
        : [...project.tracks, updatedTrack];

    final updatedAssets = [...project.assets, ttsAsset];

    final updatedProject = project.copyWith(
      tracks: updatedTracks,
      assets: updatedAssets,
    ).recalculateDuration();

    return updatedProject;
  }

  /// Splits script into sequential caption lines synchronized with spoken duration
  static List<CaptionLine> generateSynchronizedCaptions({
    required String script,
    required int startTimeMs,
    required int totalDurationMs,
  }) {
    final clean = script.trim();
    if (clean.isEmpty) return [];

    // Split script into sentence phrases or chunks of 4-6 words
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return [];

    final chunks = <String>[];
    const chunkSize = 5;
    for (int i = 0; i < words.length; i += chunkSize) {
      final end = min(i + chunkSize, words.length);
      chunks.add(words.sublist(i, end).join(' '));
    }

    final captions = <CaptionLine>[];
    final msPerChunk = (totalDurationMs / chunks.length).round();

    for (int i = 0; i < chunks.length; i++) {
      final chunkStart = startTimeMs + (i * msPerChunk);
      final chunkDuration = msPerChunk.clamp(800, totalDurationMs);
      captions.add(
        CaptionLine(
          id: 'caption_tts_$i',
          text: chunks[i],
          startTimeMs: chunkStart,
          durationMs: chunkDuration,
          preset: CaptionPreset.tiktokViral,
        ),
      );
    }

    return captions;
  }
}
