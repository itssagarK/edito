import 'package:equatable/equatable.dart';
import '../../overlays/models/text_overlay_config.dart';

enum CaptionPreset {
  tiktokViral,
  cinematicSubtitle,
  neonPodcast,
  firePunch,
  comicHero,
  minimalWhite,
  retroTypewriter,
  pastelAesthetic,
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
      case CaptionPreset.firePunch:
        return '🔥 Fire Punch';
      case CaptionPreset.comicHero:
        return '💥 Comic Hero';
      case CaptionPreset.minimalWhite:
        return '💬 Minimal Clean';
      case CaptionPreset.retroTypewriter:
        return '⌨️ Retro Typewriter';
      case CaptionPreset.pastelAesthetic:
        return '🌸 Pastel Dream';
    }
  }

  TextOverlayConfig createStyle(String text) {
    switch (this) {
      case CaptionPreset.tiktokViral:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Anton',
          fontSize: 30.0,
          textColor: 0xFFFFE600, // Vibrant Yellow
          backgroundColor: 0xDD000000,
          strokeColor: 0xFF000000,
          strokeWidth: 2.5,
          positionX: 0.5,
          positionY: 0.82,
          animationType: TextAnimationType.popScale,
          isBold: true,
          isUppercase: true,
          boxCornerRadius: 8.0,
          boxPadding: 10.0,
        );

      case CaptionPreset.cinematicSubtitle:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Montserrat',
          fontSize: 22.0,
          textColor: 0xFFFFFFFF,
          backgroundColor: 0x88000000,
          positionX: 0.5,
          positionY: 0.86,
          animationType: TextAnimationType.fadeIn,
          isBold: false,
          letterSpacing: 1.2,
          boxCornerRadius: 4.0,
        );

      case CaptionPreset.neonPodcast:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Poppins',
          fontSize: 26.0,
          textColor: 0xFF00E5FF, // Cyan
          backgroundColor: 0xEE0B132B,
          strokeColor: 0xFF00B0FF,
          strokeWidth: 1.5,
          positionX: 0.5,
          positionY: 0.80,
          animationType: TextAnimationType.shimmer,
          isBold: true,
          boxCornerRadius: 10.0,
          boxPadding: 10.0,
        );

      case CaptionPreset.firePunch:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Bebas Neue',
          fontSize: 32.0,
          textColor: 0xFFFF5500, // Blaze Orange
          backgroundColor: 0xDD180000,
          strokeColor: 0xFFFFD700, // Gold stroke
          strokeWidth: 2.0,
          positionX: 0.5,
          positionY: 0.82,
          animationType: TextAnimationType.bounce,
          isBold: true,
          isUppercase: true,
          boxCornerRadius: 6.0,
          boxPadding: 8.0,
        );

      case CaptionPreset.comicHero:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Permanent Marker',
          fontSize: 28.0,
          textColor: 0xFFFFD700, // Golden Yellow
          backgroundColor: 0xEE000000,
          strokeColor: 0xFF000000,
          strokeWidth: 3.0,
          positionX: 0.5,
          positionY: 0.82,
          animationType: TextAnimationType.popScale,
          isBold: true,
          isUppercase: true,
          boxCornerRadius: 12.0,
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
          isBold: true,
          shadowColor: 0xDD000000,
          shadowBlur: 6.0,
        );

      case CaptionPreset.retroTypewriter:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'JetBrains Mono',
          fontSize: 20.0,
          textColor: 0xFFF5F6FA,
          backgroundColor: 0xEE1E293B,
          positionX: 0.5,
          positionY: 0.85,
          animationType: TextAnimationType.typewriter,
          isBold: false,
          letterSpacing: 0.5,
          boxCornerRadius: 4.0,
        );

      case CaptionPreset.pastelAesthetic:
        return TextOverlayConfig(
          text: text,
          fontFamily: 'Caveat',
          fontSize: 28.0,
          textColor: 0xFFFF85A1, // Pastel Pink
          backgroundColor: 0xCC2A1B3D,
          positionX: 0.5,
          positionY: 0.84,
          animationType: TextAnimationType.zoomIn,
          isBold: true,
          boxCornerRadius: 14.0,
          boxPadding: 12.0,
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
