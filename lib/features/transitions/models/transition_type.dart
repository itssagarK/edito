import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
        return 'Zoom In';
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
        return Icons.zoom_in;
    }
  }
}

class TransitionConfig extends Equatable {
  final TransitionType type;
  final int durationMs; // 200 to 2000ms

  const TransitionConfig({
    this.type = TransitionType.none,
    this.durationMs = 500,
  });

  bool get isEnabled => type != TransitionType.none && durationMs > 0;

  TransitionConfig copyWith({
    TransitionType? type,
    int? durationMs,
  }) {
    return TransitionConfig(
      type: type ?? this.type,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'durationMs': durationMs,
      };

  factory TransitionConfig.fromJson(Map<String, dynamic> json) => TransitionConfig(
        type: TransitionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransitionType.none,
        ),
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 500,
      );

  @override
  List<Object?> get props => [type, durationMs];
}
