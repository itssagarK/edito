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

class WordTimestamp extends Equatable {
  final String word;
  final int startOffsetMs; // milliseconds offset from caption line start
  final int durationMs;

  const WordTimestamp({
    required this.word,
    required this.startOffsetMs,
    required this.durationMs,
  });

  int get endOffsetMs => startOffsetMs + durationMs;

  WordTimestamp copyWith({
    String? word,
    int? startOffsetMs,
    int? durationMs,
  }) {
    return WordTimestamp(
      word: word ?? this.word,
      startOffsetMs: startOffsetMs ?? this.startOffsetMs,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'startOffsetMs': startOffsetMs,
        'durationMs': durationMs,
      };

  factory WordTimestamp.fromJson(Map<String, dynamic> json) => WordTimestamp(
        word: json['word'] as String? ?? '',
        startOffsetMs: json['startOffsetMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 300,
      );

  @override
  List<Object?> get props => [word, startOffsetMs, durationMs];
}

enum KaraokeHighlightStyle {
  none,
  colorFill,
  scalePunch,
  pillBackground,
  glowWave,
}

extension KaraokeHighlightStyleExtension on KaraokeHighlightStyle {
  String get label {
    switch (this) {
      case KaraokeHighlightStyle.none:
        return 'Standard Static';
      case KaraokeHighlightStyle.colorFill:
        return 'Color Pop (TikTok)';
      case KaraokeHighlightStyle.scalePunch:
        return 'Scale Bounce';
      case KaraokeHighlightStyle.pillBackground:
        return 'Neon Pill Box';
      case KaraokeHighlightStyle.glowWave:
        return 'Aura Glow Wave';
    }
  }

  String get description {
    switch (this) {
      case KaraokeHighlightStyle.none:
        return 'Displays line with uniform text styling';
      case KaraokeHighlightStyle.colorFill:
        return 'Active spoken word pops in vibrant highlight color';
      case KaraokeHighlightStyle.scalePunch:
        return 'Active word bounces up 20% with spring easing';
      case KaraokeHighlightStyle.pillBackground:
        return 'Draws rounded accent pill behind the current word';
      case KaraokeHighlightStyle.glowWave:
        return 'Radiates high-intensity neon glow shadow around the active word';
    }
  }
}

class CaptionLine extends Equatable {
  final String id;
  final String text;
  final int startTimeMs;
  final int durationMs;
  final TextOverlayConfig style;
  final List<WordTimestamp> words;
  final KaraokeHighlightStyle highlightStyle;
  final int highlightColor; // Default 0xFFFFE600 Vibrant Yellow
  final double highlightScale; // Default 1.20
  final bool isKinetic;

  const CaptionLine({
    required this.id,
    required this.text,
    required this.startTimeMs,
    required this.durationMs,
    required this.style,
    this.words = const [],
    this.highlightStyle = KaraokeHighlightStyle.colorFill,
    this.highlightColor = 0xFFFFE600,
    this.highlightScale = 1.20,
    this.isKinetic = true,
  });

  int get endTimeMs => startTimeMs + durationMs;

  /// Returns effective words list; if empty, automatically interpolates balanced word timings based on durationMs
  List<WordTimestamp> get effectiveWords {
    if (words.isNotEmpty) return words;
    return generateInterpolatedWords(text, durationMs);
  }

  /// Finds index of active word at given elapsed offset (offsetMs = currentPositionMs - startTimeMs)
  int getActiveWordIndex(int offsetMs) {
    final list = effectiveWords;
    if (list.isEmpty) return -1;
    for (int i = 0; i < list.length; i++) {
      final w = list[i];
      if (offsetMs >= w.startOffsetMs && offsetMs < w.endOffsetMs) {
        return i;
      }
    }
    // If past all words but within caption duration, point to last word
    if (offsetMs >= 0 && offsetMs < durationMs) {
      return list.length - 1;
    }
    return -1;
  }

  /// Automatically splits text into words and balances start offset and duration proportionally
  static List<WordTimestamp> generateInterpolatedWords(String text, int totalDurationMs) {
    final rawWords = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.isEmpty) return [];

    final result = <WordTimestamp>[];
    final perWordMs = (totalDurationMs / rawWords.length).round();

    int offset = 0;
    for (int i = 0; i < rawWords.length; i++) {
      final isLast = i == rawWords.length - 1;
      final dur = isLast ? (totalDurationMs - offset).clamp(100, totalDurationMs) : perWordMs;
      result.add(WordTimestamp(
        word: rawWords[i],
        startOffsetMs: offset,
        durationMs: dur,
      ));
      offset += dur;
    }
    return result;
  }

  CaptionLine copyWith({
    String? id,
    String? text,
    int? startTimeMs,
    int? durationMs,
    TextOverlayConfig? style,
    List<WordTimestamp>? words,
    KaraokeHighlightStyle? highlightStyle,
    int? highlightColor,
    double? highlightScale,
    bool? isKinetic,
  }) {
    return CaptionLine(
      id: id ?? this.id,
      text: text ?? this.text,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      durationMs: durationMs ?? this.durationMs,
      style: style ?? this.style,
      words: words ?? this.words,
      highlightStyle: highlightStyle ?? this.highlightStyle,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightScale: highlightScale ?? this.highlightScale,
      isKinetic: isKinetic ?? this.isKinetic,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'startTimeMs': startTimeMs,
        'durationMs': durationMs,
        'style': style.toJson(),
        'words': words.map((w) => w.toJson()).toList(),
        'highlightStyle': highlightStyle.name,
        'highlightColor': highlightColor,
        'highlightScale': highlightScale,
        'isKinetic': isKinetic,
      };

  factory CaptionLine.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>?;
    final wordsList = rawWords != null
        ? rawWords.map((w) => WordTimestamp.fromJson(w as Map<String, dynamic>)).toList()
        : <WordTimestamp>[];

    final rawHighlight = json['highlightStyle'] as String?;
    final highlightStyle = KaraokeHighlightStyle.values.firstWhere(
      (h) => h.name == rawHighlight,
      orElse: () => KaraokeHighlightStyle.colorFill,
    );

    return CaptionLine(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      startTimeMs: json['startTimeMs'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 2500,
      style: json['style'] != null
          ? TextOverlayConfig.fromJson(json['style'] as Map<String, dynamic>)
          : const TextOverlayConfig(),
      words: wordsList,
      highlightStyle: highlightStyle,
      highlightColor: (json['highlightColor'] as num?)?.toInt() ?? 0xFFFFE600,
      highlightScale: (json['highlightScale'] as num?)?.toDouble() ?? 1.20,
      isKinetic: json['isKinetic'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        text,
        startTimeMs,
        durationMs,
        style,
        words,
        highlightStyle,
        highlightColor,
        highlightScale,
        isKinetic,
      ];
}
