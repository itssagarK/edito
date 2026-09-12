import 'package:equatable/equatable.dart';

enum HeaderFooterStyle {
  solidBanner,
  gradientBanner,
  glassmorphic,
  pillBadge,
  neonAccent,
  minimalTransparent,
}

extension HeaderFooterStyleExtension on HeaderFooterStyle {
  String get label {
    switch (this) {
      case HeaderFooterStyle.solidBanner:
        return 'Solid Banner';
      case HeaderFooterStyle.gradientBanner:
        return 'Gradient Strip';
      case HeaderFooterStyle.glassmorphic:
        return 'Glassmorphic Translucent';
      case HeaderFooterStyle.pillBadge:
        return 'Floating Pill Badge';
      case HeaderFooterStyle.neonAccent:
        return 'Neon Border Accent';
      case HeaderFooterStyle.minimalTransparent:
        return 'Minimal Transparent';
    }
  }
}

enum HeaderFooterAnim {
  none,
  fadeIn,
  slideIn,
  pulse,
}

extension HeaderFooterAnimExtension on HeaderFooterAnim {
  String get label {
    switch (this) {
      case HeaderFooterAnim.none:
        return 'None (Static)';
      case HeaderFooterAnim.fadeIn:
        return 'Smooth Fade In';
      case HeaderFooterAnim.slideIn:
        return 'Slide In From Edge';
      case HeaderFooterAnim.pulse:
        return 'Gentle Pulse';
    }
  }
}

enum HeaderFooterPreset {
  socialReelsViral,
  breakingNews,
  podcastStudio,
  cinemaLetterbox,
  youtubeTutorial,
  aestheticPastel,
}

extension HeaderFooterPresetExtension on HeaderFooterPreset {
  String get label {
    switch (this) {
      case HeaderFooterPreset.socialReelsViral:
        return '🔥 Viral Social Reels';
      case HeaderFooterPreset.breakingNews:
        return '🔴 Breaking News Alert';
      case HeaderFooterPreset.podcastStudio:
        return '🎙️ Podcast Studio';
      case HeaderFooterPreset.cinemaLetterbox:
        return '🎬 Cinema Letterbox';
      case HeaderFooterPreset.youtubeTutorial:
        return '💡 YouTube Tutorial';
      case HeaderFooterPreset.aestheticPastel:
        return '🌸 Aesthetic Quote';
    }
  }

  HeaderFooterConfig createConfig() {
    switch (this) {
      case HeaderFooterPreset.socialReelsViral:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'TOP 5 VIDEO EDITING SECRETS',
          headerSubtext: 'MUST WATCH UNTIL END 🔥',
          headerFont: 'Anton',
          headerFontSize: 24.0,
          headerTextColor: 0xFFFFE600, // Yellow
          headerBackgroundColor: 0xEE000000,
          headerHeight: 64.0,
          headerStyle: HeaderFooterStyle.solidBanner,
          headerAnimation: HeaderFooterAnim.slideIn,
          headerEmoji: '🔥',
          isHeaderBold: true,
          isHeaderUppercase: true,
          footerText: '@YourChannel • Follow for Part 2 🚀',
          footerSubtext: 'Save & share with a creator',
          footerFont: 'Inter',
          footerFontSize: 16.0,
          footerTextColor: 0xFFFFFFFF,
          footerBackgroundColor: 0xEE000000,
          footerHeight: 52.0,
          footerStyle: HeaderFooterStyle.solidBanner,
          footerAnimation: HeaderFooterAnim.slideIn,
          footerIcon: '📲',
          isFooterBold: true,
        );

      case HeaderFooterPreset.breakingNews:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'BREAKING NEWS UPDATE',
          headerSubtext: 'SPECIAL REPORT • LIVE ON AIR',
          headerFont: 'Montserrat',
          headerFontSize: 22.0,
          headerTextColor: 0xFFFFFFFF,
          headerBackgroundColor: 0xFFD32F2F, // Crimson Red
          headerHeight: 60.0,
          headerStyle: HeaderFooterStyle.solidBanner,
          headerAnimation: HeaderFooterAnim.fadeIn,
          headerEmoji: '🔴',
          isHeaderBold: true,
          isHeaderUppercase: true,
          footerText: 'FULL STORY AT WWW.EDITO.APP • DEVELOPING NEWS',
          footerFont: 'Inter',
          footerFontSize: 15.0,
          footerTextColor: 0xFFFFFFFF,
          footerBackgroundColor: 0xEE1E293B,
          footerHeight: 46.0,
          footerStyle: HeaderFooterStyle.solidBanner,
          footerAnimation: HeaderFooterAnim.fadeIn,
          footerIcon: '📢',
          isFooterBold: true,
          isFooterUppercase: true,
        );

      case HeaderFooterPreset.podcastStudio:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'THE CREATIVE MINDSET PODCAST',
          headerSubtext: 'EPISODE 42 • MASTERING YOUR CRAFT',
          headerFont: 'Poppins',
          headerFontSize: 22.0,
          headerTextColor: 0xFF00E5FF,
          headerBackgroundColor: 0xEE0F172A,
          headerHeight: 58.0,
          headerStyle: HeaderFooterStyle.glassmorphic,
          headerAnimation: HeaderFooterAnim.fadeIn,
          headerEmoji: '🎙️',
          isHeaderBold: true,
          footerText: 'AVAILABLE ON SPOTIFY & APPLE PODCASTS',
          footerFont: 'Inter',
          footerFontSize: 14.0,
          footerTextColor: 0xFFF1F5F9,
          footerBackgroundColor: 0xEE0F172A,
          footerHeight: 44.0,
          footerStyle: HeaderFooterStyle.glassmorphic,
          footerAnimation: HeaderFooterAnim.fadeIn,
          footerIcon: '🎧',
          isFooterBold: false,
        );

      case HeaderFooterPreset.cinemaLetterbox:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'A CINEMATIC STORY',
          headerFont: 'Montserrat',
          headerFontSize: 18.0,
          headerTextColor: 0xFFFFD700,
          headerBackgroundColor: 0xFF000000,
          headerHeight: 68.0,
          headerStyle: HeaderFooterStyle.solidBanner,
          headerAnimation: HeaderFooterAnim.none,
          isHeaderBold: false,
          isHeaderUppercase: true,
          footerText: 'DIRECTED WITH EDITO PRO',
          footerFont: 'Montserrat',
          footerFontSize: 14.0,
          footerTextColor: 0xFFB0B0B0,
          footerBackgroundColor: 0xFF000000,
          footerHeight: 68.0,
          footerStyle: HeaderFooterStyle.solidBanner,
          footerAnimation: HeaderFooterAnim.none,
          isFooterBold: false,
          isFooterUppercase: true,
        );

      case HeaderFooterPreset.youtubeTutorial:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'STEP 1: COLOR GRADING MASTERY',
          headerSubtext: 'BEGINNER TO PRO IN 5 MINUTES 🎬',
          headerFont: 'Bebas Neue',
          headerFontSize: 26.0,
          headerTextColor: 0xFF00FFCC,
          headerBackgroundColor: 0xDD111827,
          headerHeight: 60.0,
          headerStyle: HeaderFooterStyle.pillBadge,
          headerAnimation: HeaderFooterAnim.slideIn,
          headerEmoji: '💡',
          isHeaderBold: true,
          footerText: '🔔 SUBSCRIBE FOR WEEKLY VIDEO EDITING TIPS',
          footerFont: 'Inter',
          footerFontSize: 15.0,
          footerTextColor: 0xFFFFFFFF,
          footerBackgroundColor: 0xDD111827,
          footerHeight: 48.0,
          footerStyle: HeaderFooterStyle.pillBadge,
          footerAnimation: HeaderFooterAnim.slideIn,
          footerIcon: '🔔',
          isFooterBold: true,
        );

      case HeaderFooterPreset.aestheticPastel:
        return const HeaderFooterConfig(
          isHeaderEnabled: true,
          isFooterEnabled: true,
          headerText: 'Daily Affirmation & Vision',
          headerSubtext: 'Create beautiful moments ✨',
          headerFont: 'Caveat',
          headerFontSize: 26.0,
          headerTextColor: 0xFFFF70A6,
          headerBackgroundColor: 0xCC2A1B3D,
          headerHeight: 56.0,
          headerStyle: HeaderFooterStyle.glassmorphic,
          headerAnimation: HeaderFooterAnim.fadeIn,
          headerEmoji: '🌸',
          isHeaderBold: true,
          footerText: 'Save this reminder for later ❤️',
          footerFont: 'Poppins',
          footerFontSize: 14.0,
          footerTextColor: 0xFFFDE2E4,
          footerBackgroundColor: 0xCC2A1B3D,
          footerHeight: 44.0,
          footerStyle: HeaderFooterStyle.glassmorphic,
          footerAnimation: HeaderFooterAnim.fadeIn,
          footerIcon: '✨',
          isFooterBold: false,
        );
    }
  }
}

class HeaderFooterConfig extends Equatable {
  final bool isHeaderEnabled;
  final bool isFooterEnabled;

  // Header Attributes
  final String headerText;
  final String headerSubtext;
  final String headerFont;
  final double headerFontSize;
  final int headerTextColor;
  final int headerBackgroundColor;
  final double headerHeight; // 20 to 120 px
  final HeaderFooterStyle headerStyle;
  final HeaderFooterAnim headerAnimation;
  final String headerEmoji;
  final bool isHeaderBold;
  final bool isHeaderUppercase;

  // Footer Attributes
  final String footerText;
  final String footerSubtext;
  final String footerFont;
  final double footerFontSize;
  final int footerTextColor;
  final int footerBackgroundColor;
  final double footerHeight; // 20 to 120 px
  final HeaderFooterStyle footerStyle;
  final HeaderFooterAnim footerAnimation;
  final String footerIcon;
  final bool isFooterBold;
  final bool isFooterUppercase;

  const HeaderFooterConfig({
    this.isHeaderEnabled = false,
    this.isFooterEnabled = false,
    this.headerText = '',
    this.headerSubtext = '',
    this.headerFont = 'Inter',
    this.headerFontSize = 22.0,
    this.headerTextColor = 0xFFFFFFFF,
    this.headerBackgroundColor = 0xEE000000,
    this.headerHeight = 56.0,
    this.headerStyle = HeaderFooterStyle.solidBanner,
    this.headerAnimation = HeaderFooterAnim.fadeIn,
    this.headerEmoji = '',
    this.isHeaderBold = true,
    this.isHeaderUppercase = true,
    this.footerText = '',
    this.footerSubtext = '',
    this.footerFont = 'Inter',
    this.footerFontSize = 16.0,
    this.footerTextColor = 0xFFFFFFFF,
    this.footerBackgroundColor = 0xEE000000,
    this.footerHeight = 48.0,
    this.footerStyle = HeaderFooterStyle.solidBanner,
    this.footerAnimation = HeaderFooterAnim.fadeIn,
    this.footerIcon = '',
    this.isFooterBold = false,
    this.isFooterUppercase = false,
  });

  bool get hasActiveOverlay => (isHeaderEnabled && headerText.trim().isNotEmpty) ||
                                (isFooterEnabled && footerText.trim().isNotEmpty);

  HeaderFooterConfig copyWith({
    bool? isHeaderEnabled,
    bool? isFooterEnabled,
    String? headerText,
    String? headerSubtext,
    String? headerFont,
    double? headerFontSize,
    int? headerTextColor,
    int? headerBackgroundColor,
    double? headerHeight,
    HeaderFooterStyle? headerStyle,
    HeaderFooterAnim? headerAnimation,
    String? headerEmoji,
    bool? isHeaderBold,
    bool? isHeaderUppercase,
    String? footerText,
    String? footerSubtext,
    String? footerFont,
    double? footerFontSize,
    int? footerTextColor,
    int? footerBackgroundColor,
    double? footerHeight,
    HeaderFooterStyle? footerStyle,
    HeaderFooterAnim? footerAnimation,
    String? footerIcon,
    bool? isFooterBold,
    bool? isFooterUppercase,
  }) {
    return HeaderFooterConfig(
      isHeaderEnabled: isHeaderEnabled ?? this.isHeaderEnabled,
      isFooterEnabled: isFooterEnabled ?? this.isFooterEnabled,
      headerText: headerText ?? this.headerText,
      headerSubtext: headerSubtext ?? this.headerSubtext,
      headerFont: headerFont ?? this.headerFont,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerHeight: headerHeight ?? this.headerHeight,
      headerStyle: headerStyle ?? this.headerStyle,
      headerAnimation: headerAnimation ?? this.headerAnimation,
      headerEmoji: headerEmoji ?? this.headerEmoji,
      isHeaderBold: isHeaderBold ?? this.isHeaderBold,
      isHeaderUppercase: isHeaderUppercase ?? this.isHeaderUppercase,
      footerText: footerText ?? this.footerText,
      footerSubtext: footerSubtext ?? this.footerSubtext,
      footerFont: footerFont ?? this.footerFont,
      footerFontSize: footerFontSize ?? this.footerFontSize,
      footerTextColor: footerTextColor ?? this.footerTextColor,
      footerBackgroundColor: footerBackgroundColor ?? this.footerBackgroundColor,
      footerHeight: footerHeight ?? this.footerHeight,
      footerStyle: footerStyle ?? this.footerStyle,
      footerAnimation: footerAnimation ?? this.footerAnimation,
      footerIcon: footerIcon ?? this.footerIcon,
      isFooterBold: isFooterBold ?? this.isFooterBold,
      isFooterUppercase: isFooterUppercase ?? this.isFooterUppercase,
    );
  }

  Map<String, dynamic> toJson() => {
        'isHeaderEnabled': isHeaderEnabled,
        'isFooterEnabled': isFooterEnabled,
        'headerText': headerText,
        'headerSubtext': headerSubtext,
        'headerFont': headerFont,
        'headerFontSize': headerFontSize,
        'headerTextColor': headerTextColor,
        'headerBackgroundColor': headerBackgroundColor,
        'headerHeight': headerHeight,
        'headerStyle': headerStyle.name,
        'headerAnimation': headerAnimation.name,
        'headerEmoji': headerEmoji,
        'isHeaderBold': isHeaderBold,
        'isHeaderUppercase': isHeaderUppercase,
        'footerText': footerText,
        'footerSubtext': footerSubtext,
        'footerFont': footerFont,
        'footerFontSize': footerFontSize,
        'footerTextColor': footerTextColor,
        'footerBackgroundColor': footerBackgroundColor,
        'footerHeight': footerHeight,
        'footerStyle': footerStyle.name,
        'footerAnimation': footerAnimation.name,
        'footerIcon': footerIcon,
        'isFooterBold': isFooterBold,
        'isFooterUppercase': isFooterUppercase,
      };

  factory HeaderFooterConfig.fromJson(Map<String, dynamic> json) => HeaderFooterConfig(
        isHeaderEnabled: json['isHeaderEnabled'] as bool? ?? false,
        isFooterEnabled: json['isFooterEnabled'] as bool? ?? false,
        headerText: json['headerText'] as String? ?? '',
        headerSubtext: json['headerSubtext'] as String? ?? '',
        headerFont: json['headerFont'] as String? ?? 'Inter',
        headerFontSize: (json['headerFontSize'] as num?)?.toDouble() ?? 22.0,
        headerTextColor: (json['headerTextColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        headerBackgroundColor: (json['headerBackgroundColor'] as num?)?.toInt() ?? 0xEE000000,
        headerHeight: (json['headerHeight'] as num?)?.toDouble() ?? 56.0,
        headerStyle: HeaderFooterStyle.values.firstWhere(
          (e) => e.name == json['headerStyle'],
          orElse: () => HeaderFooterStyle.solidBanner,
        ),
        headerAnimation: HeaderFooterAnim.values.firstWhere(
          (e) => e.name == json['headerAnimation'],
          orElse: () => HeaderFooterAnim.fadeIn,
        ),
        headerEmoji: json['headerEmoji'] as String? ?? '',
        isHeaderBold: json['isHeaderBold'] as bool? ?? true,
        isHeaderUppercase: json['isHeaderUppercase'] as bool? ?? true,
        footerText: json['footerText'] as String? ?? '',
        footerSubtext: json['footerSubtext'] as String? ?? '',
        footerFont: json['footerFont'] as String? ?? 'Inter',
        footerFontSize: (json['footerFontSize'] as num?)?.toDouble() ?? 16.0,
        footerTextColor: (json['footerTextColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        footerBackgroundColor: (json['footerBackgroundColor'] as num?)?.toInt() ?? 0xEE000000,
        footerHeight: (json['footerHeight'] as num?)?.toDouble() ?? 48.0,
        footerStyle: HeaderFooterStyle.values.firstWhere(
          (e) => e.name == json['footerStyle'],
          orElse: () => HeaderFooterStyle.solidBanner,
        ),
        footerAnimation: HeaderFooterAnim.values.firstWhere(
          (e) => e.name == json['footerAnimation'],
          orElse: () => HeaderFooterAnim.fadeIn,
        ),
        footerIcon: json['footerIcon'] as String? ?? '',
        isFooterBold: json['isFooterBold'] as bool? ?? false,
        isFooterUppercase: json['isFooterUppercase'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        isHeaderEnabled,
        isFooterEnabled,
        headerText,
        headerSubtext,
        headerFont,
        headerFontSize,
        headerTextColor,
        headerBackgroundColor,
        headerHeight,
        headerStyle,
        headerAnimation,
        headerEmoji,
        isHeaderBold,
        isHeaderUppercase,
        footerText,
        footerSubtext,
        footerFont,
        footerFontSize,
        footerTextColor,
        footerBackgroundColor,
        footerHeight,
        footerStyle,
        footerAnimation,
        footerIcon,
        isFooterBold,
        isFooterUppercase,
      ];
}
