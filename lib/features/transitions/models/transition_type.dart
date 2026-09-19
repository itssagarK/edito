import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TransitionCategory {
  all,
  basic,
  whip,
  cinematic,
  distortion,
}

extension TransitionCategoryExtension on TransitionCategory {
  String get label {
    switch (this) {
      case TransitionCategory.all:
        return 'All (18)';
      case TransitionCategory.basic:
        return '✨ Basic Dissolves';
      case TransitionCategory.whip:
        return '🌪️ Whip & Slides';
      case TransitionCategory.cinematic:
        return '🎬 Cinematic Flares';
      case TransitionCategory.distortion:
        return '🌀 Glitch & Warp';
    }
  }
}

enum TransitionEasing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  springPunch,
}

extension TransitionEasingExtension on TransitionEasing {
  String get label {
    switch (this) {
      case TransitionEasing.linear:
        return 'Linear';
      case TransitionEasing.easeIn:
        return 'Ease In';
      case TransitionEasing.easeOut:
        return 'Ease Out';
      case TransitionEasing.easeInOut:
        return 'Smooth In-Out';
      case TransitionEasing.springPunch:
        return 'Spring Punch';
    }
  }

  Curve get curve {
    switch (this) {
      case TransitionEasing.linear:
        return Curves.linear;
      case TransitionEasing.easeIn:
        return Curves.easeInQuad;
      case TransitionEasing.easeOut:
        return Curves.easeOutQuad;
      case TransitionEasing.easeInOut:
        return Curves.easeInOutCubic;
      case TransitionEasing.springPunch:
        return Curves.elasticOut;
    }
  }
}

enum TransitionType {
  none,
  crossDissolve,
  fadeBlack,
  fadeWhite,
  wipeLeft,
  wipeRight,
  slideUp,
  slideDown,
  zoomIn,
  // Cinematic Pro Transitions (CapCut Parity)
  whipPanLeft,
  whipPanRight,
  glitchDisplace,
  filmBurn,
  spinClockwise,
  spinCounterClockwise,
  directionalWarp,
  pixelateDissolve,
  lensFlash,
}

extension TransitionTypeExtension on TransitionType {
  String get label {
    switch (this) {
      case TransitionType.none:
        return 'None';
      case TransitionType.crossDissolve:
        return 'Cross Dissolve';
      case TransitionType.fadeBlack:
        return 'Fade to Black';
      case TransitionType.fadeWhite:
        return 'Fade to White';
      case TransitionType.wipeLeft:
        return 'Wipe Left';
      case TransitionType.wipeRight:
        return 'Wipe Right';
      case TransitionType.slideUp:
        return 'Slide Up';
      case TransitionType.slideDown:
        return 'Slide Down';
      case TransitionType.zoomIn:
        return 'Circle Zoom';
      case TransitionType.whipPanLeft:
        return '⚡ Whip Pan Left';
      case TransitionType.whipPanRight:
        return '⚡ Whip Pan Right';
      case TransitionType.glitchDisplace:
        return '📺 Glitch Displace';
      case TransitionType.filmBurn:
        return '🔥 Film Burn Flare';
      case TransitionType.spinClockwise:
        return '🔄 Spin 180° CW';
      case TransitionType.spinCounterClockwise:
        return '🔃 Spin 180° CCW';
      case TransitionType.directionalWarp:
        return '💥 Zoom Blur Warp';
      case TransitionType.pixelateDissolve:
        return '👾 Pixelate Dissolve';
      case TransitionType.lensFlash:
        return '✨ Anamorphic Flash';
    }
  }

  String get description {
    switch (this) {
      case TransitionType.none:
        return 'Direct cut between adjacent clips without blending';
      case TransitionType.crossDissolve:
        return 'Smooth cross-fade opacity blend between incoming and outgoing footage';
      case TransitionType.fadeBlack:
        return 'Dips outgoing frame to solid pitch black before fading in the next clip';
      case TransitionType.fadeWhite:
        return 'Dips outgoing frame to overexposed white before fading into next clip';
      case TransitionType.wipeLeft:
        return 'Sharp vertical curtain wipes from right edge to left edge';
      case TransitionType.wipeRight:
        return 'Sharp vertical curtain wipes from left edge to right edge';
      case TransitionType.slideUp:
        return 'Next scene pushes current scene upwards into view';
      case TransitionType.slideDown:
        return 'Next scene drops downwards pushing current scene out';
      case TransitionType.zoomIn:
        return 'Iris circle opens outwards revealing the incoming scene';
      case TransitionType.whipPanLeft:
        return 'High-velocity camera whip pan to left with directional motion blur';
      case TransitionType.whipPanRight:
        return 'High-velocity camera whip pan to right with directional motion blur';
      case TransitionType.glitchDisplace:
        return 'Digital RGB chromatic aberration split with horizontal scanline displacement';
      case TransitionType.filmBurn:
        return 'Warm amber-orange organic 35mm film burn flare with light leak overexposure';
      case TransitionType.spinClockwise:
        return 'Kinetic clockwise rotational spin with dynamic center perspective scaling';
      case TransitionType.spinCounterClockwise:
        return 'Kinetic counter-clockwise rotational spin into next clip';
      case TransitionType.directionalWarp:
        return 'Explosive radial zoom blur pushing outward with warp displacement';
      case TransitionType.pixelateDissolve:
        return 'Retro 8-bit mosaic blocks expanding and resolving into the next clip';
      case TransitionType.lensFlash:
        return 'Bright anamorphic lens flare streak blasting the frame with light';
    }
  }

  TransitionCategory get category {
    switch (this) {
      case TransitionType.none:
      case TransitionType.crossDissolve:
      case TransitionType.fadeBlack:
      case TransitionType.fadeWhite:
        return TransitionCategory.basic;
      case TransitionType.wipeLeft:
      case TransitionType.wipeRight:
      case TransitionType.slideUp:
      case TransitionType.slideDown:
      case TransitionType.whipPanLeft:
      case TransitionType.whipPanRight:
        return TransitionCategory.whip;
      case TransitionType.filmBurn:
      case TransitionType.lensFlash:
        return TransitionCategory.cinematic;
      case TransitionType.zoomIn:
      case TransitionType.glitchDisplace:
      case TransitionType.spinClockwise:
      case TransitionType.spinCounterClockwise:
      case TransitionType.directionalWarp:
      case TransitionType.pixelateDissolve:
        return TransitionCategory.distortion;
    }
  }

  String get ffmpegXFadeName {
    switch (this) {
      case TransitionType.none:
        return '';
      case TransitionType.crossDissolve:
        return 'fade';
      case TransitionType.fadeBlack:
        return 'fadeblack';
      case TransitionType.fadeWhite:
        return 'fadewhite';
      case TransitionType.wipeLeft:
        return 'wipeleft';
      case TransitionType.wipeRight:
        return 'wiperight';
      case TransitionType.slideUp:
        return 'slideup';
      case TransitionType.slideDown:
        return 'slidedown';
      case TransitionType.zoomIn:
        return 'circleopen';
      case TransitionType.whipPanLeft:
        return 'wipeleft';
      case TransitionType.whipPanRight:
        return 'wiperight';
      case TransitionType.glitchDisplace:
        return 'pixelize';
      case TransitionType.filmBurn:
        return 'smoothdown';
      case TransitionType.spinClockwise:
        return 'radial';
      case TransitionType.spinCounterClockwise:
        return 'radial';
      case TransitionType.directionalWarp:
        return 'zoomin';
      case TransitionType.pixelateDissolve:
        return 'pixelize';
      case TransitionType.lensFlash:
        return 'fadewhite';
    }
  }

  IconData get icon {
    switch (this) {
      case TransitionType.none:
        return Icons.block;
      case TransitionType.crossDissolve:
        return Icons.blur_on;
      case TransitionType.fadeBlack:
        return Icons.brightness_medium;
      case TransitionType.fadeWhite:
        return Icons.brightness_high;
      case TransitionType.wipeLeft:
        return Icons.keyboard_arrow_left;
      case TransitionType.wipeRight:
        return Icons.keyboard_arrow_right;
      case TransitionType.slideUp:
        return Icons.keyboard_arrow_up;
      case TransitionType.slideDown:
        return Icons.keyboard_arrow_down;
      case TransitionType.zoomIn:
        return Icons.circle_outlined;
      case TransitionType.whipPanLeft:
        return Icons.fast_rewind;
      case TransitionType.whipPanRight:
        return Icons.fast_forward;
      case TransitionType.glitchDisplace:
        return Icons.broken_image_outlined;
      case TransitionType.filmBurn:
        return Icons.local_fire_department;
      case TransitionType.spinClockwise:
        return Icons.rotate_right;
      case TransitionType.spinCounterClockwise:
        return Icons.rotate_left;
      case TransitionType.directionalWarp:
        return Icons.zoom_out_map;
      case TransitionType.pixelateDissolve:
        return Icons.grid_view;
      case TransitionType.lensFlash:
        return Icons.flash_on;
    }
  }
}

class TransitionConfig extends Equatable {
  final TransitionType type;
  final int durationMs; // 100 to 3000ms
  final TransitionEasing easing;
  final bool playSfx;

  const TransitionConfig({
    this.type = TransitionType.none,
    this.durationMs = 500,
    this.easing = TransitionEasing.easeInOut,
    this.playSfx = false,
  });

  bool get isEnabled => type != TransitionType.none && durationMs > 0;

  TransitionConfig copyWith({
    TransitionType? type,
    int? durationMs,
    TransitionEasing? easing,
    bool? playSfx,
  }) {
    return TransitionConfig(
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
      easing: easing ?? this.easing,
      playSfx: playSfx ?? this.playSfx,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'durationMs': durationMs,
        'easing': easing.name,
        'playSfx': playSfx,
      };

  factory TransitionConfig.fromJson(Map<String, dynamic> json) => TransitionConfig(
        type: TransitionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransitionType.none,
        ),
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 500,
        easing: TransitionEasing.values.firstWhere(
          (e) => e.name == json['easing'],
          orElse: () => TransitionEasing.easeInOut,
        ),
        playSfx: json['playSfx'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [type, durationMs, easing, playSfx];
}
