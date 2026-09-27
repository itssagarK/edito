import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'teleprompter_script.dart';

enum PrompterSpeedPreset {
  slow(90, 'Slow (90 WPM)'),
  normal(130, 'Normal (130 WPM)'),
  energetic(175, 'Energetic (175 WPM)'),
  speedrun(240, 'Speedrun (240 WPM)');

  final int wpm;
  final String label;
  const PrompterSpeedPreset(this.wpm, this.label);
}

class TeleprompterConfig extends Equatable {
  final bool isEnabled;
  final String activeScriptId;
  final List<TeleprompterScript> scripts;
  final int scrollSpeedWpm; // Words per minute (60 to 300)
  final double fontSize; // Font size in sp (14.0 to 42.0)
  final double lineHeight; // Line height multiplier (1.2 to 2.5)
  final TextAlign textAlign;
  final bool isMirrorMode; // Horizontal flip for glass teleprompters
  final double backgroundOpacity; // 0.0 (transparent) to 1.0 (solid black)
  final int countdownSeconds; // 0, 3, 5, 10
  final bool isHighlightFocusLine; // Displays central reading guide indicator
  final double windowWidth; // Normalized width 0.3 - 1.0
  final double windowHeight; // Normalized height 0.2 - 0.9
  final double windowYOffset; // Normalized vertical positioning 0.05 - 0.7

  const TeleprompterConfig({
    this.isEnabled = false,
    this.activeScriptId = 'script_tiktok_hook',
    this.scripts = const [],
    this.scrollSpeedWpm = 130,
    this.fontSize = 22.0,
    this.lineHeight = 1.6,
    this.textAlign = TextAlign.center,
    this.isMirrorMode = false,
    this.backgroundOpacity = 0.65,
    this.countdownSeconds = 3,
    this.isHighlightFocusLine = true,
    this.windowWidth = 0.88,
    this.windowHeight = 0.45,
    this.windowYOffset = 0.15,
  });

  List<TeleprompterScript> get effectiveScripts {
    if (scripts.isEmpty) {
      return TeleprompterScript.defaultSampleScripts;
    }
    return scripts;
  }

  TeleprompterScript get activeScript {
    final list = effectiveScripts;
    return list.firstWhere(
      (s) => s.id == activeScriptId,
      orElse: () => list.first,
    );
  }

  TeleprompterConfig copyWith({
    bool? isEnabled,
    String? activeScriptId,
    List<TeleprompterScript>? scripts,
    int? scrollSpeedWpm,
    double? fontSize,
    double? lineHeight,
    TextAlign? textAlign,
    bool? isMirrorMode,
    double? backgroundOpacity,
    int? countdownSeconds,
    bool? isHighlightFocusLine,
    double? windowWidth,
    double? windowHeight,
    double? windowYOffset,
  }) {
    return TeleprompterConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      activeScriptId: activeScriptId ?? this.activeScriptId,
      scripts: scripts ?? this.scripts,
      scrollSpeedWpm: scrollSpeedWpm ?? this.scrollSpeedWpm,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      textAlign: textAlign ?? this.textAlign,
      isMirrorMode: isMirrorMode ?? this.isMirrorMode,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isHighlightFocusLine: isHighlightFocusLine ?? this.isHighlightFocusLine,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      windowYOffset: windowYOffset ?? this.windowYOffset,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'activeScriptId': activeScriptId,
        'scripts': scripts.map((s) => s.toJson()).toList(),
        'scrollSpeedWpm': scrollSpeedWpm,
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'textAlign': textAlign.name,
        'isMirrorMode': isMirrorMode,
        'backgroundOpacity': backgroundOpacity,
        'countdownSeconds': countdownSeconds,
        'isHighlightFocusLine': isHighlightFocusLine,
        'windowWidth': windowWidth,
        'windowHeight': windowHeight,
        'windowYOffset': windowYOffset,
      };

  factory TeleprompterConfig.fromJson(Map<String, dynamic> json) {
    final rawScripts = json['scripts'] as List<dynamic>?;
    final scriptsList = rawScripts != null
        ? rawScripts.map((s) => TeleprompterScript.fromJson(s as Map<String, dynamic>)).toList()
        : <TeleprompterScript>[];

    final alignStr = json['textAlign'] as String? ?? 'center';
    final parsedAlign = TextAlign.values.firstWhere(
      (a) => a.name == alignStr,
      orElse: () => TextAlign.center,
    );

    return TeleprompterConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      activeScriptId: json['activeScriptId'] as String? ?? 'script_tiktok_hook',
      scripts: scriptsList,
      scrollSpeedWpm: json['scrollSpeedWpm'] as int? ?? 130,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 22.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      textAlign: parsedAlign,
      isMirrorMode: json['isMirrorMode'] as bool? ?? false,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.65,
      countdownSeconds: json['countdownSeconds'] as int? ?? 3,
      isHighlightFocusLine: json['isHighlightFocusLine'] as bool? ?? true,
      windowWidth: (json['windowWidth'] as num?)?.toDouble() ?? 0.88,
      windowHeight: (json['windowHeight'] as num?)?.toDouble() ?? 0.45,
      windowYOffset: (json['windowYOffset'] as num?)?.toDouble() ?? 0.15,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        activeScriptId,
        scripts,
        scrollSpeedWpm,
        fontSize,
        lineHeight,
        textAlign,
        isMirrorMode,
        backgroundOpacity,
        countdownSeconds,
        isHighlightFocusLine,
        windowWidth,
        windowHeight,
        windowYOffset,
      ];
}
