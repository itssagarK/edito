import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsProvider {
  openAi('OpenAI TTS (tts-1 / tts-1-hd)'),
  elevenLabs('ElevenLabs AI Voices'),
  offline('On-Device Android Speech');

  final String label;
  const TtsProvider(this.label);
}

enum SttProvider {
  openAiWhisper('OpenAI Whisper (whisper-1)'),
  groqWhisper('Groq Whisper (whisper-large-v3, Ultra-Fast)');

  final String label;
  const SttProvider(this.label);
}

class AiSettings {
  final String openAiApiKey;
  final String groqApiKey;
  final String elevenLabsApiKey;
  final String removeBgApiKey;
  final TtsProvider ttsProvider;
  final SttProvider sttProvider;
  final String openAiVoice;
  final String elevenLabsVoiceId;

  const AiSettings({
    this.openAiApiKey = '',
    this.groqApiKey = '',
    this.elevenLabsApiKey = '',
    this.removeBgApiKey = '',
    this.ttsProvider = TtsProvider.openAi,
    this.sttProvider = SttProvider.openAiWhisper,
    this.openAiVoice = 'alloy',
    this.elevenLabsVoiceId = '21m00Tcm4TlvDq8ikWAM', // Rachel
  });

  bool get hasWhisperKey =>
      (sttProvider == SttProvider.openAiWhisper && openAiApiKey.trim().isNotEmpty) ||
      (sttProvider == SttProvider.groqWhisper && groqApiKey.trim().isNotEmpty) ||
      openAiApiKey.trim().isNotEmpty ||
      groqApiKey.trim().isNotEmpty;

  bool get hasTtsKey {
    if (ttsProvider == TtsProvider.openAi) return openAiApiKey.trim().isNotEmpty;
    if (ttsProvider == TtsProvider.elevenLabs) return elevenLabsApiKey.trim().isNotEmpty;
    return true; // offline doesn't require key
  }

  bool get hasRemoveBgKey => removeBgApiKey.trim().isNotEmpty;

  AiSettings copyWith({
    String? openAiApiKey,
    String? groqApiKey,
    String? elevenLabsApiKey,
    String? removeBgApiKey,
    TtsProvider? ttsProvider,
    SttProvider? sttProvider,
    String? openAiVoice,
    String? elevenLabsVoiceId,
  }) {
    return AiSettings(
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      elevenLabsApiKey: elevenLabsApiKey ?? this.elevenLabsApiKey,
      removeBgApiKey: removeBgApiKey ?? this.removeBgApiKey,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      sttProvider: sttProvider ?? this.sttProvider,
      openAiVoice: openAiVoice ?? this.openAiVoice,
      elevenLabsVoiceId: elevenLabsVoiceId ?? this.elevenLabsVoiceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'openAiApiKey': openAiApiKey,
        'groqApiKey': groqApiKey,
        'elevenLabsApiKey': elevenLabsApiKey,
        'removeBgApiKey': removeBgApiKey,
        'ttsProvider': ttsProvider.name,
        'sttProvider': sttProvider.name,
        'openAiVoice': openAiVoice,
        'elevenLabsVoiceId': elevenLabsVoiceId,
      };

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    TtsProvider tts = TtsProvider.openAi;
    try {
      tts = TtsProvider.values.byName(json['ttsProvider'] as String? ?? 'openAi');
    } catch (_) {}

    SttProvider stt = SttProvider.openAiWhisper;
    try {
      stt = SttProvider.values.byName(json['sttProvider'] as String? ?? 'openAiWhisper');
    } catch (_) {}

    return AiSettings(
      openAiApiKey: json['openAiApiKey'] as String? ?? '',
      groqApiKey: json['groqApiKey'] as String? ?? '',
      elevenLabsApiKey: json['elevenLabsApiKey'] as String? ?? '',
      removeBgApiKey: json['removeBgApiKey'] as String? ?? '',
      ttsProvider: tts,
      sttProvider: stt,
      openAiVoice: json['openAiVoice'] as String? ?? 'alloy',
      elevenLabsVoiceId: json['elevenLabsVoiceId'] as String? ?? '21m00Tcm4TlvDq8ikWAM',
    );
  }
}

class AiConfigurationService {
  static AiSettings _cachedSettings = const AiSettings();
  static bool _isLoaded = false;

  static Future<AiSettings> getSettings() async {
    if (_isLoaded) return _cachedSettings;

    try {
      // 1. Try local JSON file in documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'ai_settings.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        _cachedSettings = AiSettings.fromJson(map);
        _isLoaded = true;
        return _cachedSettings;
      }
    } catch (e) {
      debugPrint('Error reading ai_settings.json: $e');
    }

    try {
      // 2. Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('edito_ai_settings');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cachedSettings = AiSettings.fromJson(map);
        _isLoaded = true;
        return _cachedSettings;
      }
    } catch (_) {}

    _isLoaded = true;
    return _cachedSettings;
  }

  static Future<void> saveSettings(AiSettings settings) async {
    _cachedSettings = settings;
    _isLoaded = true;

    final jsonStr = jsonEncode(settings.toJson());

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'ai_settings.json'));
      await file.writeAsString(jsonStr);
    } catch (e) {
      debugPrint('Error saving ai_settings.json: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('edito_ai_settings', jsonStr);
    } catch (_) {}
  }

  /// Tests an OpenAI API key by making a lightweight ping to /v1/models
  static Future<bool> testOpenAiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse('https://api.openai.com/v1/models'));
      request.headers.set('Authorization', 'Bearer ${apiKey.trim()}');
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OpenAI key test error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  /// Tests a Groq API key by making a lightweight ping to /openai/v1/models
  static Future<bool> testGroqKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse('https://api.groq.com/openai/v1/models'));
      request.headers.set('Authorization', 'Bearer ${apiKey.trim()}');
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Groq key test error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  /// Tests an ElevenLabs API key by pinging /v1/user
  static Future<bool> testElevenLabsKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse('https://api.elevenlabs.io/v1/user'));
      request.headers.set('xi-api-key', apiKey.trim());
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ElevenLabs key test error: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
