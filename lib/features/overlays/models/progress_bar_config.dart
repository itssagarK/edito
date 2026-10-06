import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Available stylistic presets for social retention progress bars.
enum ProgressBarPreset {
  neonCyber,
  sunsetFlame,
  emeraldMint,
  electricWhite,
  socialGold,
}

extension ProgressBarPresetExtension on ProgressBarPreset {
  String get label {
    switch (this) {
      case ProgressBarPreset.neonCyber:
        return '⚡ Neon Cyber';
      case ProgressBarPreset.sunsetFlame:
        return '🔥 Sunset Flame';
      case ProgressBarPreset.emeraldMint:
        return '🌿 Emerald Mint';
      case ProgressBarPreset.electricWhite:
        return '⚪ Crisp Minimal';
      case ProgressBarPreset.socialGold:
        return '👑 Social Gold';
    }
  }

  Color get primaryColor {
    switch (this) {
      case ProgressBarPreset.neonCyber:
        return const Color(0xFF00E5FF);
      case ProgressBarPreset.sunsetFlame:
        return const Color(0xFFFF9100);
      case ProgressBarPreset.emeraldMint:
        return const Color(0xFF00E676);
      case ProgressBarPreset.electricWhite:
        return const Color(0xFFFFFFFF);
      case ProgressBarPreset.socialGold:
        return const Color(0xFFFFD700);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case ProgressBarPreset.neonCyber:
        return const Color(0xFF7C4DFF);
      case ProgressBarPreset.sunsetFlame:
        return const Color(0xFFFF1744);
      case ProgressBarPreset.emeraldMint:
        return const Color(0xFF1DE9B6);
      case ProgressBarPreset.electricWhite:
        return const Color(0xFFB0BEC5);
      case ProgressBarPreset.socialGold:
        return const Color(0xFFFF6D00);
    }
  }
}

/// 100% Offline, Deterministic Social Retention Progress Bar Configuration.
///
/// Overlays a smooth, real-time filling progress bar across the video canvas
/// to maximize viewer completion rate on TikTok, Instagram Reels, and Shorts.
class ProgressBarConfig extends Equatable {
  final bool isEnabled;
  final double height; // 2.0 to 16.0 px
  final bool isTopPosition; // false = bottom, true = top
  final int primaryColorValue;
  final int secondaryColorValue;
  final int trackColorValue;
  final bool showGlow;
  final double borderRadius;
  final bool showTimeRemaining;

  const ProgressBarConfig({
    this.isEnabled = false,
    this.height = 4.0,
    this.isTopPosition = false,
    this.primaryColorValue = 0xFF00E5FF,
    this.secondaryColorValue = 0xFF7C4DFF,
    this.trackColorValue = 0x4D000000,
    this.showGlow = true,
    this.borderRadius = 2.0,
    this.showTimeRemaining = false,
  });

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);
  Color get trackColor => Color(trackColorValue);

  ProgressBarConfig copyWith({
    bool? isEnabled,
    double? height,
    bool? isTopPosition,
    int? primaryColorValue,
    int? secondaryColorValue,
    int? trackColorValue,
    bool? showGlow,
    double? borderRadius,
    bool? showTimeRemaining,
  }) {
    return ProgressBarConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      height: height ?? this.height,
      isTopPosition: isTopPosition ?? this.isTopPosition,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      trackColorValue: trackColorValue ?? this.trackColorValue,
      showGlow: showGlow ?? this.showGlow,
      borderRadius: borderRadius ?? this.borderRadius,
      showTimeRemaining: showTimeRemaining ?? this.showTimeRemaining,
    );
  }

  factory ProgressBarConfig.fromPreset(ProgressBarPreset preset, {bool isEnabled = true}) {
    return ProgressBarConfig(
      isEnabled: isEnabled,
      primaryColorValue: preset.primaryColor.value,
      secondaryColorValue: preset.secondaryColor.value,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'height': height,
        'isTopPosition': isTopPosition,
        'primaryColorValue': primaryColorValue,
        'secondaryColorValue': secondaryColorValue,
        'trackColorValue': trackColorValue,
        'showGlow': showGlow,
        'borderRadius': borderRadius,
        'showTimeRemaining': showTimeRemaining,
      };

  factory ProgressBarConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProgressBarConfig();
    return ProgressBarConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      height: (json['height'] as num?)?.toDouble() ?? 4.0,
      isTopPosition: json['isTopPosition'] as bool? ?? false,
      primaryColorValue: (json['primaryColorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
      secondaryColorValue: (json['secondaryColorValue'] as num?)?.toInt() ?? 0xFF7C4DFF,
      trackColorValue: (json['trackColorValue'] as num?)?.toInt() ?? 0x4D000000,
      showGlow: json['showGlow'] as bool? ?? true,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 2.0,
      showTimeRemaining: json['showTimeRemaining'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        height,
        isTopPosition,
        primaryColorValue,
        secondaryColorValue,
        trackColorValue,
        showGlow,
        borderRadius,
        showTimeRemaining,
      ];
}
