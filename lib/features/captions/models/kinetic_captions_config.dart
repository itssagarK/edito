import 'package:equatable/equatable.dart';
import 'caption_line.dart';

/// CapCut Pro Kinetic Karaoke Highlight Styles
enum KaraokeHighlightStyle {
  none,
  colorFill,
  scalePunch,
  pillBackground,
  glowWave,
  neonUnderline,
  bouncePop,
  typewriterReveal,
}

extension KaraokeHighlightStyleExtension on KaraokeHighlightStyle {
  String get label {
    switch (this) {
      case KaraokeHighlightStyle.none:
        return 'None';
      case KaraokeHighlightStyle.colorFill:
        return 'Color Pop (TikTok)';
      case KaraokeHighlightStyle.scalePunch:
        return 'Scale Bounce';
      case KaraokeHighlightStyle.pillBackground:
        return 'Neon Pill Box';
      case KaraokeHighlightStyle.glowWave:
        return 'Aura Glow Wave';
      case KaraokeHighlightStyle.neonUnderline:
        return 'Neon Underline';
      case KaraokeHighlightStyle.bouncePop:
        return 'Vertical Bounce';
      case KaraokeHighlightStyle.typewriterReveal:
        return 'Typewriter Reveal';
    }
  }

  String get description {
    switch (this) {
      case KaraokeHighlightStyle.none:
        return 'Displays line with uniform static text styling';
      case KaraokeHighlightStyle.colorFill:
        return 'Active spoken word pops in vibrant highlight color';
      case KaraokeHighlightStyle.scalePunch:
        return 'Active word bounces up with organic spring easing';
      case KaraokeHighlightStyle.pillBackground:
        return 'Draws rounded accent pill behind the current word';
      case KaraokeHighlightStyle.glowWave:
        return 'Radiates high-intensity neon glow aura around the active word';
      case KaraokeHighlightStyle.neonUnderline:
        return 'Draws glowing luminous bar indicator beneath the active word';
      case KaraokeHighlightStyle.bouncePop:
        return 'Active word jumps vertically with spring bounce';
      case KaraokeHighlightStyle.typewriterReveal:
        return 'Reveals words sequentially as they are spoken';
    }
  }
}

/// CapCut Pro Kinetic Captions Configuration
class KineticCaptionsConfig extends Equatable {
  final bool isEnabled;
  final KaraokeHighlightStyle style;
  final int highlightColor; // Default 0xFFFFE600 Vibrant Yellow
  final int inactiveColor; // Default 0x99FFFFFF Translucent White
  final double highlightScale; // Default 1.22
  final double inactiveOpacity; // Default 0.55
  final double glowRadius; // Default 14.0
  final bool isUppercase;
  final List<WordTimestamp> words;

  const KineticCaptionsConfig({
    this.isEnabled = false,
    this.style = KaraokeHighlightStyle.colorFill,
    this.highlightColor = 0xFFFFE600,
    this.inactiveColor = 0x99FFFFFF,
    this.highlightScale = 1.22,
    this.inactiveOpacity = 0.55,
    this.glowRadius = 14.0,
    this.isUppercase = false,
    this.words = const [],
  });

  /// ⚡ TikTok / Reels Viral Pop
  static const tiktokPop = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.scalePunch,
    highlightColor: 0xFFFFE600, // Vibrant Yellow
    inactiveColor: 0x99FFFFFF,
    highlightScale: 1.25,
    inactiveOpacity: 0.55,
    glowRadius: 10.0,
    isUppercase: true,
  );

  /// 🎙️ Neon Podcast Glow
  static const neonPodcast = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.glowWave,
    highlightColor: 0xFF00E5FF, // Cyan
    inactiveColor: 0x88FFFFFF,
    highlightScale: 1.15,
    inactiveOpacity: 0.50,
    glowRadius: 18.0,
    isUppercase: false,
  );

  /// 🔥 Hormozi / Beast Energy Pill
  static const hormoziBeast = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.pillBackground,
    highlightColor: 0xFF00FF66, // Neon Lime Green
    inactiveColor: 0x88FFFFFF,
    highlightScale: 1.18,
    inactiveOpacity: 0.50,
    glowRadius: 12.0,
    isUppercase: true,
  );

  /// 💖 Cyberpunk Underline
  static const cyberPink = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.neonUnderline,
    highlightColor: 0xFFFF2A85, // Hot Pink
    inactiveColor: 0x99FFFFFF,
    highlightScale: 1.20,
    inactiveOpacity: 0.60,
    glowRadius: 16.0,
    isUppercase: false,
  );

  /// 💥 Action Fire Bounce
  static const firePunch = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.bouncePop,
    highlightColor: 0xFFFF6B00, // Blaze Orange
    inactiveColor: 0x88FFFFFF,
    highlightScale: 1.30,
    inactiveOpacity: 0.50,
    glowRadius: 14.0,
    isUppercase: true,
  );

  /// 🎬 Cinema Minimal
  static const cinemaMinimal = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.colorFill,
    highlightColor: 0xFFFFFFFF, // Pure White
    inactiveColor: 0x77FFFFFF,
    highlightScale: 1.08,
    inactiveOpacity: 0.60,
    glowRadius: 6.0,
    isUppercase: false,
  );

  /// ⌨️ Retro Terminal Typewriter
  static const terminalRetro = KineticCaptionsConfig(
    isEnabled: true,
    style: KaraokeHighlightStyle.typewriterReveal,
    highlightColor: 0xFF00FF66, // Matrix Green
    inactiveColor: 0x4400FF66,
    highlightScale: 1.00,
    inactiveOpacity: 0.00,
    glowRadius: 8.0,
    isUppercase: false,
  );

  /// Floating HUD status badge
  String get badge {
    if (!isEnabled || style == KaraokeHighlightStyle.none) return '';
    switch (style) {
      case KaraokeHighlightStyle.colorFill:
        return '⚡ KINETIC (COLOR POP)';
      case KaraokeHighlightStyle.scalePunch:
        return '💥 KINETIC (SCALE BOUNCE)';
      case KaraokeHighlightStyle.pillBackground:
        return '🏷️ KINETIC (NEON PILL)';
      case KaraokeHighlightStyle.glowWave:
        return '✨ KINETIC (AURA GLOW)';
      case KaraokeHighlightStyle.neonUnderline:
        return '💖 KINETIC (NEON UNDERLINE)';
      case KaraokeHighlightStyle.bouncePop:
        return '🚀 KINETIC (BOUNCE POP)';
      case KaraokeHighlightStyle.typewriterReveal:
        return '⌨️ KINETIC (TYPEWRITER)';
      case KaraokeHighlightStyle.none:
        return '';
    }
  }

  KineticCaptionsConfig copyWith({
    bool? isEnabled,
    KaraokeHighlightStyle? style,
    int? highlightColor,
    int? inactiveColor,
    double? highlightScale,
    double? inactiveOpacity,
    double? glowRadius,
    bool? isUppercase,
    List<WordTimestamp>? words,
  }) {
    return KineticCaptionsConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      style: style ?? this.style,
      highlightColor: highlightColor ?? this.highlightColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      highlightScale: highlightScale ?? this.highlightScale,
      inactiveOpacity: inactiveOpacity ?? this.inactiveOpacity,
      glowRadius: glowRadius ?? this.glowRadius,
      isUppercase: isUppercase ?? this.isUppercase,
      words: words ?? this.words,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'style': style.name,
        'highlightColor': highlightColor,
        'inactiveColor': inactiveColor,
        'highlightScale': highlightScale,
        'inactiveOpacity': inactiveOpacity,
        'glowRadius': glowRadius,
        'isUppercase': isUppercase,
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory KineticCaptionsConfig.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['style'] as String?;
    final style = KaraokeHighlightStyle.values.firstWhere(
      (s) => s.name == rawStyle,
      orElse: () => KaraokeHighlightStyle.colorFill,
    );

    final rawWords = json['words'] as List<dynamic>?;
    final words = rawWords != null
        ? rawWords.map((w) => WordTimestamp.fromJson(w as Map<String, dynamic>)).toList()
        : const <WordTimestamp>[];

    return KineticCaptionsConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      style: style,
      highlightColor: (json['highlightColor'] as num?)?.toInt() ?? 0xFFFFE600,
      inactiveColor: (json['inactiveColor'] as num?)?.toInt() ?? 0x99FFFFFF,
      highlightScale: (json['highlightScale'] as num?)?.toDouble() ?? 1.22,
      inactiveOpacity: (json['inactiveOpacity'] as num?)?.toDouble() ?? 0.55,
      glowRadius: (json['glowRadius'] as num?)?.toDouble() ?? 14.0,
      isUppercase: json['isUppercase'] as bool? ?? false,
      words: words,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        style,
        highlightColor,
        inactiveColor,
        highlightScale,
        inactiveOpacity,
        glowRadius,
        isUppercase,
        words,
      ];
}
