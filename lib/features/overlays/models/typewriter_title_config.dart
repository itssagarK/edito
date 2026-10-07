import 'dart:math' as math;
import 'package:equatable/equatable.dart';

enum TypewriterMode {
  charByChar,
  wordByWord,
  fadeWord,
  terminalGlitch,
}

extension TypewriterModeExtension on TypewriterMode {
  String get label {
    switch (this) {
      case TypewriterMode.charByChar:
        return 'Letter by Letter';
      case TypewriterMode.wordByWord:
        return 'Word by Word';
      case TypewriterMode.fadeWord:
        return 'Smooth Fade Word';
      case TypewriterMode.terminalGlitch:
        return 'Matrix Terminal Scramble';
    }
  }

  String get iconEmoji {
    switch (this) {
      case TypewriterMode.charByChar:
        return '⌨️';
      case TypewriterMode.wordByWord:
        return '💥';
      case TypewriterMode.fadeWord:
        return '🌊';
      case TypewriterMode.terminalGlitch:
        return '👾';
    }
  }
}

enum TypewriterCursorStyle {
  line,        // |
  block,       // █
  underscore,  // _
  caret,       // ▸
  none,
}

extension TypewriterCursorStyleExtension on TypewriterCursorStyle {
  String get glyph {
    switch (this) {
      case TypewriterCursorStyle.line:
        return '|';
      case TypewriterCursorStyle.block:
        return '█';
      case TypewriterCursorStyle.underscore:
        return '_';
      case TypewriterCursorStyle.caret:
        return '▸';
      case TypewriterCursorStyle.none:
        return '';
    }
  }

  String get label {
    switch (this) {
      case TypewriterCursorStyle.line:
        return 'Line |';
      case TypewriterCursorStyle.block:
        return 'Block █';
      case TypewriterCursorStyle.underscore:
        return 'Underscore _';
      case TypewriterCursorStyle.caret:
        return 'Caret ▸';
      case TypewriterCursorStyle.none:
        return 'No Cursor';
    }
  }
}

class TypewriterTitleConfig extends Equatable {
  final bool isEnabled;
  final TypewriterMode mode;
  final TypewriterCursorStyle cursorStyle;
  final int typingSpeedMs;           // 15ms - 150ms per char (or per word)
  final int startDelayMs;            // 0ms - 1000ms delay before start
  final int cursorBlinkPeriodMs;     // e.g. 500ms
  final bool keepCursorAfterTyping;  // keep blinking after reveal
  final int? wordHighlightColor;     // 0xFF00F0FF, 0xFFFFDC00, etc.
  final bool playTypingSound;        // sound sync metadata
  final String customText;           // optional custom title text

  const TypewriterTitleConfig({
    this.isEnabled = false,
    this.mode = TypewriterMode.charByChar,
    this.cursorStyle = TypewriterCursorStyle.line,
    this.typingSpeedMs = 45,
    this.startDelayMs = 150,
    this.cursorBlinkPeriodMs = 500,
    this.keepCursorAfterTyping = true,
    this.wordHighlightColor,
    this.playTypingSound = false,
    this.customText = '',
  });

  bool get isActive => isEnabled;

  // Preset Configurations
  static const techTerminal = TypewriterTitleConfig(
    isEnabled: true,
    mode: TypewriterMode.charByChar,
    cursorStyle: TypewriterCursorStyle.underscore,
    typingSpeedMs: 35,
    startDelayMs: 100,
    cursorBlinkPeriodMs: 400,
    keepCursorAfterTyping: true,
    wordHighlightColor: 0xFF00FF66,
  );

  static const cinematicNoir = TypewriterTitleConfig(
    isEnabled: true,
    mode: TypewriterMode.charByChar,
    cursorStyle: TypewriterCursorStyle.line,
    typingSpeedMs: 65,
    startDelayMs: 300,
    cursorBlinkPeriodMs: 600,
    keepCursorAfterTyping: false,
    wordHighlightColor: null,
  );

  static const tiktokPunch = TypewriterTitleConfig(
    isEnabled: true,
    mode: TypewriterMode.wordByWord,
    cursorStyle: TypewriterCursorStyle.none,
    typingSpeedMs: 220,
    startDelayMs: 100,
    cursorBlinkPeriodMs: 500,
    keepCursorAfterTyping: false,
    wordHighlightColor: 0xFFFFDC00,
  );

  static const hackerMatrix = TypewriterTitleConfig(
    isEnabled: true,
    mode: TypewriterMode.terminalGlitch,
    cursorStyle: TypewriterCursorStyle.block,
    typingSpeedMs: 40,
    startDelayMs: 150,
    cursorBlinkPeriodMs: 350,
    keepCursorAfterTyping: true,
    wordHighlightColor: 0xFF00F0FF,
  );

  static const minimalClean = TypewriterTitleConfig(
    isEnabled: true,
    mode: TypewriterMode.charByChar,
    cursorStyle: TypewriterCursorStyle.line,
    typingSpeedMs: 45,
    startDelayMs: 200,
    cursorBlinkPeriodMs: 500,
    keepCursorAfterTyping: true,
    wordHighlightColor: null,
  );

  /// Computes visible text at [elapsedMs] into the clip
  String getDisplayText(String originalText, int elapsedMs, {int totalDurationMs = 3000}) {
    if (!isEnabled || originalText.isEmpty) return originalText;

    if (elapsedMs < startDelayMs) {
      return '';
    }

    final activeTime = elapsedMs - startDelayMs;

    switch (mode) {
      case TypewriterMode.charByChar:
        final charsToShow = (activeTime / math.max(1, typingSpeedMs)).floor();
        if (charsToShow >= originalText.length) {
          return originalText;
        }
        return originalText.substring(0, charsToShow.clamp(0, originalText.length));

      case TypewriterMode.wordByWord:
      case TypewriterMode.fadeWord:
        final words = originalText.split(' ');
        if (words.isEmpty) return originalText;
        final wordsToShow = (activeTime / math.max(1, typingSpeedMs)).floor();
        if (wordsToShow >= words.length) {
          return originalText;
        }
        return words.take(math.max(1, wordsToShow)).join(' ');

      case TypewriterMode.terminalGlitch:
        final charsToShow = (activeTime / math.max(1, typingSpeedMs)).floor();
        if (charsToShow >= originalText.length) {
          return originalText;
        }
        final revealed = originalText.substring(0, charsToShow.clamp(0, originalText.length));
        if (revealed.length < originalText.length) {
          // Add 2-3 randomized matrix characters
          const matrixGlyphs = '01#%&*@!?>~_';
          final seed = elapsedMs ~/ 50;
          final glitchChar1 = matrixGlyphs[(seed * 7) % matrixGlyphs.length];
          final glitchChar2 = matrixGlyphs[(seed * 13 + 3) % matrixGlyphs.length];
          return '$revealed$glitchChar1$glitchChar2';
        }
        return revealed;
    }
  }

  /// Evaluates cursor visibility & character at [elapsedMs]
  String getActiveCursor(int elapsedMs, int totalDurationMs, {int textLength = 10}) {
    if (!isEnabled || cursorStyle == TypewriterCursorStyle.none) return '';

    if (elapsedMs < startDelayMs) {
      // Blink waiting for start
      final isBlinkOn = (elapsedMs ~/ (cursorBlinkPeriodMs / 2)) % 2 == 0;
      return isBlinkOn ? cursorStyle.glyph : ' ';
    }

    final activeTime = elapsedMs - startDelayMs;
    final totalTypingDuration = mode == TypewriterMode.wordByWord
        ? (textLength / 4.0).ceil() * typingSpeedMs
        : textLength * typingSpeedMs;

    final isTypingDone = activeTime >= totalTypingDuration;

    if (isTypingDone && !keepCursorAfterTyping) {
      return '';
    }

    final isBlinkOn = (elapsedMs ~/ (cursorBlinkPeriodMs / 2)) % 2 == 0;
    return isBlinkOn ? cursorStyle.glyph : ' ';
  }

  /// Checks if typing animation has fully finished revealing the text
  bool isTypingComplete(String originalText, int elapsedMs) {
    if (!isEnabled) return true;
    if (elapsedMs < startDelayMs) return false;
    final activeTime = elapsedMs - startDelayMs;

    if (mode == TypewriterMode.wordByWord || mode == TypewriterMode.fadeWord) {
      final wordsCount = originalText.split(' ').where((w) => w.isNotEmpty).length;
      return activeTime >= (wordsCount * typingSpeedMs);
    }

    return activeTime >= (originalText.length * typingSpeedMs);
  }

  TypewriterTitleConfig copyWith({
    bool? isEnabled,
    TypewriterMode? mode,
    TypewriterCursorStyle? cursorStyle,
    int? typingSpeedMs,
    int? startDelayMs,
    int? cursorBlinkPeriodMs,
    bool? keepCursorAfterTyping,
    int? wordHighlightColor,
    bool? playTypingSound,
    String? customText,
  }) {
    return TypewriterTitleConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      cursorStyle: cursorStyle ?? this.cursorStyle,
      typingSpeedMs: typingSpeedMs ?? this.typingSpeedMs,
      startDelayMs: startDelayMs ?? this.startDelayMs,
      cursorBlinkPeriodMs: cursorBlinkPeriodMs ?? this.cursorBlinkPeriodMs,
      keepCursorAfterTyping: keepCursorAfterTyping ?? this.keepCursorAfterTyping,
      wordHighlightColor: wordHighlightColor ?? this.wordHighlightColor,
      playTypingSound: playTypingSound ?? this.playTypingSound,
      customText: customText ?? this.customText,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'cursorStyle': cursorStyle.name,
        'typingSpeedMs': typingSpeedMs,
        'startDelayMs': startDelayMs,
        'cursorBlinkPeriodMs': cursorBlinkPeriodMs,
        'keepCursorAfterTyping': keepCursorAfterTyping,
        'wordHighlightColor': wordHighlightColor,
        'playTypingSound': playTypingSound,
        'customText': customText,
      };

  factory TypewriterTitleConfig.fromJson(Map<String, dynamic> json) => TypewriterTitleConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        mode: TypewriterMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => TypewriterMode.charByChar,
        ),
        cursorStyle: TypewriterCursorStyle.values.firstWhere(
          (e) => e.name == json['cursorStyle'],
          orElse: () => TypewriterCursorStyle.line,
        ),
        typingSpeedMs: (json['typingSpeedMs'] as num?)?.toInt() ?? 45,
        startDelayMs: (json['startDelayMs'] as num?)?.toInt() ?? 150,
        cursorBlinkPeriodMs: (json['cursorBlinkPeriodMs'] as num?)?.toInt() ?? 500,
        keepCursorAfterTyping: json['keepCursorAfterTyping'] as bool? ?? true,
        wordHighlightColor: (json['wordHighlightColor'] as num?)?.toInt(),
        playTypingSound: json['playTypingSound'] as bool? ?? false,
        customText: json['customText'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        cursorStyle,
        typingSpeedMs,
        startDelayMs,
        cursorBlinkPeriodMs,
        keepCursorAfterTyping,
        wordHighlightColor,
        playTypingSound,
        customText,
      ];
}
