import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'text_overlay_config.dart';

/// CapCut Studio Typography & Text Effect Presets
/// Extracted directly from CapCut Studio engine assets (textStyle_v2.txt)
class TextPresetStyle extends Equatable {
  final String id;
  final String name;
  final String category; // 'Classic', 'Strokes', 'Badges', 'Shadows', 'Neon Glow'
  final int fillColor;
  final int? strokeColor;
  final double strokeWidth;
  final int? backgroundColor;
  final int? shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final int? glowColor;
  final double glowRadius;
  final double glowIntensity;

  const TextPresetStyle({
    required this.id,
    required this.name,
    required this.category,
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.backgroundColor,
    this.shadowColor,
    this.shadowBlur = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.glowColor,
    this.glowRadius = 0.0,
    this.glowIntensity = 0.0,
  });

  TextOverlayConfig applyTo(TextOverlayConfig config) {
    return config.copyWith(
      textColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      backgroundColor: backgroundColor,
      shadowColor: shadowColor,
      shadowBlur: shadowBlur,
      shadowOffsetX: shadowOffsetX,
      shadowOffsetY: shadowOffsetY,
      glowColor: glowColor,
      glowRadius: glowRadius,
      glowIntensity: glowIntensity,
    );
  }

  static const List<TextPresetStyle> presets = [
    // 1. Classic Basics
    TextPresetStyle(
      id: 'white_black_stroke',
      name: 'White Outline',
      category: 'Classic',
      fillColor: 0xFFFFFFFF,
      strokeColor: 0xFF000000,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'black_white_stroke',
      name: 'Black Outline',
      category: 'Classic',
      fillColor: 0xFF000000,
      strokeColor: 0xFFFFFFFF,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'white_drop_shadow',
      name: 'Drop Shadow',
      category: 'Classic',
      fillColor: 0xFFFFFFFF,
      shadowColor: 0xA6000000, // 65% black
      shadowBlur: 3.0,
      shadowOffsetX: 3.0,
      shadowOffsetY: 3.0,
    ),
    TextPresetStyle(
      id: 'white_soft_shadow',
      name: 'Soft Shadow',
      category: 'Classic',
      fillColor: 0xFFFFFFFF,
      shadowColor: 0xFF000000,
      shadowBlur: 8.0,
      shadowOffsetX: 0.0,
      shadowOffsetY: 2.0,
    ),

    // 2. High-Impact Stroke Styles
    TextPresetStyle(
      id: 'yellow_black_stroke',
      name: 'Cyber Yellow',
      category: 'Strokes',
      fillColor: 0xFFF0FF00,
      strokeColor: 0xFF000000,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'red_white_stroke',
      name: 'Crimson Red',
      category: 'Strokes',
      fillColor: 0xFFEC1D1D,
      strokeColor: 0xFFFFFFFF,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'orange_white_stroke',
      name: 'Sunset Orange',
      category: 'Strokes',
      fillColor: 0xFFFF8000,
      strokeColor: 0xFFFFFFFF,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'blue_white_stroke',
      name: 'Electric Blue',
      category: 'Strokes',
      fillColor: 0xFF008EFF,
      strokeColor: 0xFFFFFFFF,
      strokeWidth: 2.5,
    ),
    TextPresetStyle(
      id: 'green_black_stroke',
      name: 'Emerald Neon',
      category: 'Strokes',
      fillColor: 0xFF00FF18,
      strokeColor: 0xFF000000,
      strokeWidth: 2.5,
    ),

    // 3. Creator Highlight Badges
    TextPresetStyle(
      id: 'black_yellow_badge',
      name: 'Yellow Tag',
      category: 'Badges',
      fillColor: 0xFF000000,
      backgroundColor: 0xFFFFDC00,
    ),
    TextPresetStyle(
      id: 'white_purple_badge',
      name: 'Purple Tag',
      category: 'Badges',
      fillColor: 0xFFFFFFFF,
      backgroundColor: 0xFF8100FF,
    ),
    TextPresetStyle(
      id: 'white_black_badge',
      name: 'Dark Badge',
      category: 'Badges',
      fillColor: 0xFFFFFFFF,
      backgroundColor: 0xE6000000,
    ),
    TextPresetStyle(
      id: 'black_white_badge',
      name: 'White Plate',
      category: 'Badges',
      fillColor: 0xFF000000,
      backgroundColor: 0xE6FFFFFF,
    ),
    TextPresetStyle(
      id: 'green_black_badge',
      name: 'Matrix Badge',
      category: 'Badges',
      fillColor: 0xFF00FF18,
      backgroundColor: 0xE6000000,
    ),

    // 4. Stylized Dual-Tone Shadows
    TextPresetStyle(
      id: 'black_neon_green_shadow',
      name: 'Cyber Shadow',
      category: 'Shadows',
      fillColor: 0xFF000000,
      shadowColor: 0xFF00FF18,
      shadowBlur: 2.0,
      shadowOffsetX: 4.0,
      shadowOffsetY: 4.0,
    ),
    TextPresetStyle(
      id: 'gold_crimson_shadow',
      name: 'Golden Retro',
      category: 'Shadows',
      fillColor: 0xFFF4C70F,
      shadowColor: 0xFFB61B1C,
      shadowBlur: 2.0,
      shadowOffsetX: 4.0,
      shadowOffsetY: 4.0,
    ),

    // 5. Outer Glow / Neon Halos
    TextPresetStyle(
      id: 'neon_red_glow',
      name: 'Neon Crimson',
      category: 'Neon Glow',
      fillColor: 0xFFFFFFFF,
      glowColor: 0xFFFF0855,
      glowRadius: 18.0,
      glowIntensity: 0.95,
      shadowColor: 0xFFFF0855,
      shadowBlur: 14.0,
      shadowOffsetX: 0.0,
      shadowOffsetY: 0.0,
    ),
    TextPresetStyle(
      id: 'neon_yellow_glow',
      name: 'Neon Solar',
      category: 'Neon Glow',
      fillColor: 0xFFFFFFFF,
      glowColor: 0xFFFFDC00,
      glowRadius: 18.0,
      glowIntensity: 0.95,
      shadowColor: 0xFFFFDC00,
      shadowBlur: 14.0,
      shadowOffsetX: 0.0,
      shadowOffsetY: 0.0,
    ),
    TextPresetStyle(
      id: 'neon_green_glow',
      name: 'Neon Cyber',
      category: 'Neon Glow',
      fillColor: 0xFFFFFFFF,
      glowColor: 0xFF00E200,
      glowRadius: 18.0,
      glowIntensity: 0.95,
      shadowColor: 0xFF00E200,
      shadowBlur: 14.0,
      shadowOffsetX: 0.0,
      shadowOffsetY: 0.0,
    ),
    TextPresetStyle(
      id: 'neon_cyan_glow',
      name: 'Neon Aqua',
      category: 'Neon Glow',
      fillColor: 0xFFFFFFFF,
      glowColor: 0xFF00F0FF,
      glowRadius: 18.0,
      glowIntensity: 0.95,
      shadowColor: 0xFF00F0FF,
      shadowBlur: 14.0,
      shadowOffsetX: 0.0,
      shadowOffsetY: 0.0,
    ),
  ];

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        fillColor,
        strokeColor,
        strokeWidth,
        backgroundColor,
        shadowColor,
        shadowBlur,
        shadowOffsetX,
        shadowOffsetY,
        glowColor,
        glowRadius,
        glowIntensity,
      ];
}
