import 'package:equatable/equatable.dart';

enum CharacterZoomMode {
  cinematicPushIn,
  punchIn,
  dramaticCrash,
  slowCreep,
  closeUpLock,
  pulse,
}

extension CharacterZoomModeExtension on CharacterZoomMode {
  String get label {
    switch (this) {
      case CharacterZoomMode.cinematicPushIn:
        return 'Cinematic Push-In';
      case CharacterZoomMode.punchIn:
        return 'Punch-In (Jump Zoom)';
      case CharacterZoomMode.dramaticCrash:
        return 'Dramatic Crash Zoom';
      case CharacterZoomMode.slowCreep:
        return 'Slow Creep Tension';
      case CharacterZoomMode.closeUpLock:
        return 'Close-Up Framing Lock';
      case CharacterZoomMode.pulse:
        return 'Rhythmic Pulse Zoom';
    }
  }

  String get description {
    switch (this) {
      case CharacterZoomMode.cinematicPushIn:
        return 'Smooth dramatic slow zoom into character over dialogue';
      case CharacterZoomMode.punchIn:
        return 'Instant jump-cut punch-in for YouTube/Reels key punchlines';
      case CharacterZoomMode.dramaticCrash:
        return 'Rapid high-energy snap zoom onto the character (0.35s)';
      case CharacterZoomMode.slowCreep:
        return 'Subtle tension builder (1.0x to 1.15x) keeping focus on face';
      case CharacterZoomMode.closeUpLock:
        return 'Static close-up crop directly framing character face/chest';
      case CharacterZoomMode.pulse:
        return 'Rhythmic pulsing zoom oscillation with audio energy';
    }
  }

  bool get isAnimated {
    switch (this) {
      case CharacterZoomMode.cinematicPushIn:
      case CharacterZoomMode.dramaticCrash:
      case CharacterZoomMode.slowCreep:
      case CharacterZoomMode.pulse:
        return true;
      case CharacterZoomMode.punchIn:
      case CharacterZoomMode.closeUpLock:
        return false;
    }
  }
}

enum CharacterZoomEasing {
  easeInOut,
  easeOut,
  linear,
  elastic,
}

extension CharacterZoomEasingExtension on CharacterZoomEasing {
  String get label {
    switch (this) {
      case CharacterZoomEasing.easeInOut:
        return 'Ease In-Out';
      case CharacterZoomEasing.easeOut:
        return 'Ease Out';
      case CharacterZoomEasing.linear:
        return 'Linear';
      case CharacterZoomEasing.elastic:
        return 'Elastic Snap';
    }
  }
}

class CharacterZoomConfig extends Equatable {
  final bool isEnabled;
  final CharacterZoomMode mode;
  final double targetZoom;          // 1.1x to 3.0x (default 1.4x)
  final double startZoom;           // 1.0x to 2.0x (default 1.0x)
  final double characterCenterX;    // 0.0 to 1.0 (default 0.50)
  final double characterCenterY;    // 0.0 to 1.0 (default 0.35 face level)
  final double animationDurationSec;// 0.2s to 10.0s (default 2.0s)
  final double startDelaySec;       // 0.0s to 5.0s (default 0.0s)
  final CharacterZoomEasing easing; // Easing curve
  final bool addFocusVignette;      // Edge darkening focused on subject
  final bool addSubjectAura;        // Subject vibrance/saturation pop

  const CharacterZoomConfig({
    this.isEnabled = false,
    this.mode = CharacterZoomMode.cinematicPushIn,
    this.targetZoom = 1.40,
    this.startZoom = 1.0,
    this.characterCenterX = 0.50,
    this.characterCenterY = 0.35,
    this.animationDurationSec = 2.0,
    this.startDelaySec = 0.0,
    this.easing = CharacterZoomEasing.easeInOut,
    this.addFocusVignette = false,
    this.addSubjectAura = false,
  });

  CharacterZoomConfig copyWith({
    bool? isEnabled,
    CharacterZoomMode? mode,
    double? targetZoom,
    double? startZoom,
    double? characterCenterX,
    double? characterCenterY,
    double? animationDurationSec,
    double? startDelaySec,
    CharacterZoomEasing? easing,
    bool? addFocusVignette,
    bool? addSubjectAura,
  }) {
    return CharacterZoomConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      targetZoom: targetZoom ?? this.targetZoom,
      startZoom: startZoom ?? this.startZoom,
      characterCenterX: characterCenterX ?? this.characterCenterX,
      characterCenterY: characterCenterY ?? this.characterCenterY,
      animationDurationSec: animationDurationSec ?? this.animationDurationSec,
      startDelaySec: startDelaySec ?? this.startDelaySec,
      easing: easing ?? this.easing,
      addFocusVignette: addFocusVignette ?? this.addFocusVignette,
      addSubjectAura: addSubjectAura ?? this.addSubjectAura,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.name,
        'targetZoom': targetZoom,
        'startZoom': startZoom,
        'characterCenterX': characterCenterX,
        'characterCenterY': characterCenterY,
        'animationDurationSec': animationDurationSec,
        'startDelaySec': startDelaySec,
        'easing': easing.name,
        'addFocusVignette': addFocusVignette,
        'addSubjectAura': addSubjectAura,
      };

  factory CharacterZoomConfig.fromJson(Map<String, dynamic> json) {
    return CharacterZoomConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: CharacterZoomMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => CharacterZoomMode.cinematicPushIn,
      ),
      targetZoom: (json['targetZoom'] as num?)?.toDouble() ?? 1.40,
      startZoom: (json['startZoom'] as num?)?.toDouble() ?? 1.0,
      characterCenterX: (json['characterCenterX'] as num?)?.toDouble() ?? 0.50,
      characterCenterY: (json['characterCenterY'] as num?)?.toDouble() ?? 0.35,
      animationDurationSec: (json['animationDurationSec'] as num?)?.toDouble() ?? 2.0,
      startDelaySec: (json['startDelaySec'] as num?)?.toDouble() ?? 0.0,
      easing: CharacterZoomEasing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => CharacterZoomEasing.easeInOut,
      ),
      addFocusVignette: json['addFocusVignette'] as bool? ?? false,
      addSubjectAura: json['addSubjectAura'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        targetZoom,
        startZoom,
        characterCenterX,
        characterCenterY,
        animationDurationSec,
        startDelaySec,
        easing,
        addFocusVignette,
        addSubjectAura,
      ];
}
