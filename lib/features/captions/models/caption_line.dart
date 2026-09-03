import 'package:equatable/equatable.dart';
import '../../overlays/models/text_overlay_config.dart';

enum CaptionPreset {
  tiktokViral,
  cinematicSubtitle,
  neonPodcast,
  minimalWhite,
  retroTypewriter,
}

extension CaptionPresetExtension on CaptionPreset {
  String get label {
    switch (this) {
      case CaptionPreset.tiktokViral:
        return '⚡ TikTok / Reels Viral';
      case CaptionPreset.cinematicSubtitle:
        return '🎬 Cinema Subtitle';
      case CaptionPreset.neonPodcast:
        return '🎙️ Neon Podcast';
      case CaptionPreset.minimalWhite:
        return '💬 Minimal Clean';
      case CaptionPreset.retroTypewriter:
        return '⌨️ Retro Typewriter';
    }
  }

  TextOverlayConfig createStyle(String text) {
    switch (this) {
      case CaptionPreset.tiktokViral:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Inter',
          fontSize: 28.0,
          textColor: 0xFFFFE600, // Vibrant Yellow
          backgroundColor: 0xCC000000,
          strokeColor: 0xFF000000,
          strokeWidth: 2.0,
          positionX: 0.5,
          positionY: 0.82,
          animationType: TextAnimationType.popScale,
        );

      case CaptionPreset.cinematicSubtitle:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Inter',
          fontSize: 22.0,
          textColor: 0xFFFFFFFF,
          backgroundColor: 0x99000000,
          positionX: 0.5,
          positionY: 0.86,
          animationType: TextAnimationType.fadeIn,
        );

      case CaptionPreset.neonPodcast:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Inter',
          fontSize: 26.0,
          textColor: 0xFF00E5FF, // Cyan
          backgroundColor: 0xDD111827,
          strokeColor: 0xFF00B0FF,
          strokeWidth: 1.5,
          positionX: 0.5,
          positionY: 0.80,
          animationType: TextAnimationType.shimmer,
        );

      case CaptionPreset.minimalWhite:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Inter',
          fontSize: 22.0,
          textColor: 0xFFFFFFFF,
          backgroundColor: null,
          positionX: 0.5,
          positionY: 0.84,
          animationType: TextAnimationType.none,
        );

      case CaptionPreset.retroTypewriter:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'JetBrainsMono',
          fontSize: 20.0,
          textColor: 0xFFF5F6FA,
          backgroundColor: 0xEE1E293B,
          positionX: 0.5,
          positionY: 0.85,
          animationType: TextAnimationType.typewriter,
        );
    }
  }
}

class CaptionLine extends Equatable {
  final String id;
  final String text;
  final int startTimeMs;
  final int durationMs;
  final TextOverlayConfig style;

  const CaptionLine({
    required this.id,
    required this.text,
    required this.startTimeMs,
    required this.durationMs,
    required this.style,
  });

  int get endTimeMs => startTimeMs + durationMs;

  CaptionLine copyWith({
    String? id,
    String? text,
    int? startTimeMs,
    int? durationMs,
    TextOverlayConfig? style,
  }) {
    return CaptionLine(
      id: id ?? this.id,
      text: text ?? this.text,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      durationMs: durationMs ?? this.durationMs,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'startTimeMs': startTimeMs,
        'durationMs': durationMs,
        'style': style.toJson(),
      };

  factory CaptionLine.fromJson(Map<String, dynamic> json) => CaptionLine(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        startTimeMs: json['startTimeMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 2500,
        style: json['style'] != null
            ? TextOverlayConfig.fromJson(json['style'] as Map<String, dynamic>)
            : const TextOverlayConfig(),
      );

  @override
  List<Object?> get props => [id, text, startTimeMs, durationMs, style];
}
