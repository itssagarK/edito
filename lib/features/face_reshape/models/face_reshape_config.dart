import 'package:equatable/equatable.dart';

enum FaceReshapePreset {
  custom,
  natural,
  vLine,
  chiseled,
  dollFace,
  editorial,
}

extension FaceReshapePresetExtension on FaceReshapePreset {
  String get label {
    switch (this) {
      case FaceReshapePreset.custom:
        return 'Custom';
      case FaceReshapePreset.natural:
        return 'Natural Polish';
      case FaceReshapePreset.vLine:
        return 'V-Line Aesthetic';
      case FaceReshapePreset.chiseled:
        return 'Chiseled Jaw';
      case FaceReshapePreset.dollFace:
        return 'Doll Face & Big Eyes';
      case FaceReshapePreset.editorial:
        return 'High Fashion Editorial';
    }
  }

  String get description {
    switch (this) {
      case FaceReshapePreset.custom:
        return 'Manual custom facial sculpting';
      case FaceReshapePreset.natural:
        return 'Gentle slimming and eye enhancement';
      case FaceReshapePreset.vLine:
        return 'Slim jawline, pointy chin, and wide eyes';
      case FaceReshapePreset.chiseled:
        return 'Defined jawbone, sculpted cheekbones, and refined nose';
      case FaceReshapePreset.dollFace:
        return 'Large luminous eyes, compact chin, and plump lips';
      case FaceReshapePreset.editorial:
        return 'Sharp cheekbones, narrow bridge, and high temples';
    }
  }
}

/// CapCut Pro AI Face Reshape & 3D Feature Sculpting Configuration.
/// Extracted directly from CapCut native FaceReshape_V3 and FaceReshape_V2 distortion architectures.
class FaceReshapeConfig extends Equatable {
  final bool isEnabled;
  final double intensity; // Master intensity 0.0 to 1.0

  // 1. Face & Jaw Sculpting (Process.lua: fzoomface, fvface, fzoomjawbone, fpointychin, fmovchin, fzoomcheekbone, fzoomforehead, ftemple)
  final double faceSlimming; // -1.0 to +1.0 (default 0.0)
  final double vFace; // -1.0 to +1.0 (default 0.0)
  final double jawbone; // -1.0 to +1.0 (default 0.0)
  final double pointyChin; // -1.0 to +1.0 (default 0.0)
  final double chinLength; // -1.0 to +1.0 (default 0.0)
  final double cheekbone; // -1.0 to +1.0 (default 0.0)
  final double forehead; // -1.0 to +1.0 (default 0.0)
  final double temple; // -1.0 to +1.0 (default 0.0)

  // 2. Eye Sculpting (Process.lua: fzoomeye, ffareye, frotateeye, fcornereye, fmoveye)
  final double eyeSize; // -1.0 to +1.0 (default 0.0)
  final double eyeDistance; // -1.0 to +1.0 (default 0.0)
  final double eyeAngle; // -1.0 to +1.0 (default 0.0)
  final double eyeCorner; // -1.0 to +1.0 (default 0.0)
  final double eyePosition; // -1.0 to +1.0 (default 0.0)

  // 3. Nose Sculpting (Process.lua: fzoomnose, fmovnose)
  final double noseSize; // -1.0 to +1.0 (default 0.0)
  final double noseBridge; // -1.0 to +1.0 (default 0.0)

  // 4. Mouth & Smile Sculpting (Process.lua: fzoommouth, flipenhance, fdraglips, fmovmouth)
  final double mouthSize; // -1.0 to +1.0 (default 0.0)
  final double lipEnhance; // -1.0 to +1.0 (default 0.0)
  final double smileCorners; // -1.0 to +1.0 (default 0.0)
  final double mouthPosition; // -1.0 to +1.0 (default 0.0)

  const FaceReshapeConfig({
    this.isEnabled = false,
    this.intensity = 1.0,
    this.faceSlimming = 0.0,
    this.vFace = 0.0,
    this.jawbone = 0.0,
    this.pointyChin = 0.0,
    this.chinLength = 0.0,
    this.cheekbone = 0.0,
    this.forehead = 0.0,
    this.temple = 0.0,
    this.eyeSize = 0.0,
    this.eyeDistance = 0.0,
    this.eyeAngle = 0.0,
    this.eyeCorner = 0.0,
    this.eyePosition = 0.0,
    this.noseSize = 0.0,
    this.noseBridge = 0.0,
    this.mouthSize = 0.0,
    this.lipEnhance = 0.0,
    this.smileCorners = 0.0,
    this.mouthPosition = 0.0,
  });

  /// True if face sculpting is active with non-zero parameters.
  bool get isActive =>
      isEnabled &&
      intensity > 0.001 &&
      (faceSlimming.abs() > 0.001 ||
          vFace.abs() > 0.001 ||
          jawbone.abs() > 0.001 ||
          pointyChin.abs() > 0.001 ||
          chinLength.abs() > 0.001 ||
          cheekbone.abs() > 0.001 ||
          forehead.abs() > 0.001 ||
          temple.abs() > 0.001 ||
          eyeSize.abs() > 0.001 ||
          eyeDistance.abs() > 0.001 ||
          eyeAngle.abs() > 0.001 ||
          eyeCorner.abs() > 0.001 ||
          eyePosition.abs() > 0.001 ||
          noseSize.abs() > 0.001 ||
          noseBridge.abs() > 0.001 ||
          mouthSize.abs() > 0.001 ||
          lipEnhance.abs() > 0.001 ||
          smileCorners.abs() > 0.001 ||
          mouthPosition.abs() > 0.001);

  factory FaceReshapeConfig.fromPreset(FaceReshapePreset preset) {
    switch (preset) {
      case FaceReshapePreset.natural:
        return const FaceReshapeConfig(
          isEnabled: true,
          intensity: 0.8,
          faceSlimming: 0.25,
          vFace: 0.20,
          eyeSize: 0.20,
          noseSize: -0.15,
          smileCorners: 0.15,
        );
      case FaceReshapePreset.vLine:
        return const FaceReshapeConfig(
          isEnabled: true,
          intensity: 1.0,
          faceSlimming: 0.50,
          vFace: 0.60,
          jawbone: -0.35,
          pointyChin: 0.40,
          eyeSize: 0.45,
          eyeDistance: -0.10,
          noseSize: -0.30,
          smileCorners: 0.20,
        );
      case FaceReshapePreset.chiseled:
        return const FaceReshapeConfig(
          isEnabled: true,
          intensity: 0.9,
          faceSlimming: 0.30,
          jawbone: 0.40,
          cheekbone: 0.35,
          chinLength: 0.25,
          noseSize: -0.20,
          noseBridge: 0.30,
        );
      case FaceReshapePreset.dollFace:
        return const FaceReshapeConfig(
          isEnabled: true,
          intensity: 1.0,
          faceSlimming: 0.40,
          vFace: 0.45,
          chinLength: -0.20,
          eyeSize: 0.60,
          eyeAngle: 0.15,
          noseSize: -0.25,
          mouthSize: -0.10,
          lipEnhance: 0.45,
          smileCorners: 0.30,
        );
      case FaceReshapePreset.editorial:
        return const FaceReshapeConfig(
          isEnabled: true,
          intensity: 0.85,
          faceSlimming: 0.35,
          cheekbone: 0.50,
          temple: 0.25,
          eyeAngle: 0.25,
          noseSize: -0.35,
          noseBridge: 0.40,
          lipEnhance: 0.20,
        );
      case FaceReshapePreset.custom:
        return const FaceReshapeConfig();
    }
  }

  FaceReshapeConfig copyWith({
    bool? isEnabled,
    double? intensity,
    double? faceSlimming,
    double? vFace,
    double? jawbone,
    double? pointyChin,
    double? chinLength,
    double? cheekbone,
    double? forehead,
    double? temple,
    double? eyeSize,
    double? eyeDistance,
    double? eyeAngle,
    double? eyeCorner,
    double? eyePosition,
    double? noseSize,
    double? noseBridge,
    double? mouthSize,
    double? lipEnhance,
    double? smileCorners,
    double? mouthPosition,
  }) {
    return FaceReshapeConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      intensity: intensity ?? this.intensity,
      faceSlimming: faceSlimming ?? this.faceSlimming,
      vFace: vFace ?? this.vFace,
      jawbone: jawbone ?? this.jawbone,
      pointyChin: pointyChin ?? this.pointyChin,
      chinLength: chinLength ?? this.chinLength,
      cheekbone: cheekbone ?? this.cheekbone,
      forehead: forehead ?? this.forehead,
      temple: temple ?? this.temple,
      eyeSize: eyeSize ?? this.eyeSize,
      eyeDistance: eyeDistance ?? this.eyeDistance,
      eyeAngle: eyeAngle ?? this.eyeAngle,
      eyeCorner: eyeCorner ?? this.eyeCorner,
      eyePosition: eyePosition ?? this.eyePosition,
      noseSize: noseSize ?? this.noseSize,
      noseBridge: noseBridge ?? this.noseBridge,
      mouthSize: mouthSize ?? this.mouthSize,
      lipEnhance: lipEnhance ?? this.lipEnhance,
      smileCorners: smileCorners ?? this.smileCorners,
      mouthPosition: mouthPosition ?? this.mouthPosition,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'intensity': intensity,
        'faceSlimming': faceSlimming,
        'vFace': vFace,
        'jawbone': jawbone,
        'pointyChin': pointyChin,
        'chinLength': chinLength,
        'cheekbone': cheekbone,
        'forehead': forehead,
        'temple': temple,
        'eyeSize': eyeSize,
        'eyeDistance': eyeDistance,
        'eyeAngle': eyeAngle,
        'eyeCorner': eyeCorner,
        'eyePosition': eyePosition,
        'noseSize': noseSize,
        'noseBridge': noseBridge,
        'mouthSize': mouthSize,
        'lipEnhance': lipEnhance,
        'smileCorners': smileCorners,
        'mouthPosition': mouthPosition,
      };

  factory FaceReshapeConfig.fromJson(Map<String, dynamic> json) => FaceReshapeConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
        faceSlimming: (json['faceSlimming'] as num?)?.toDouble() ?? 0.0,
        vFace: (json['vFace'] as num?)?.toDouble() ?? 0.0,
        jawbone: (json['jawbone'] as num?)?.toDouble() ?? 0.0,
        pointyChin: (json['pointyChin'] as num?)?.toDouble() ?? 0.0,
        chinLength: (json['chinLength'] as num?)?.toDouble() ?? 0.0,
        cheekbone: (json['cheekbone'] as num?)?.toDouble() ?? 0.0,
        forehead: (json['forehead'] as num?)?.toDouble() ?? 0.0,
        temple: (json['temple'] as num?)?.toDouble() ?? 0.0,
        eyeSize: (json['eyeSize'] as num?)?.toDouble() ?? 0.0,
        eyeDistance: (json['eyeDistance'] as num?)?.toDouble() ?? 0.0,
        eyeAngle: (json['eyeAngle'] as num?)?.toDouble() ?? 0.0,
        eyeCorner: (json['eyeCorner'] as num?)?.toDouble() ?? 0.0,
        eyePosition: (json['eyePosition'] as num?)?.toDouble() ?? 0.0,
        noseSize: (json['noseSize'] as num?)?.toDouble() ?? 0.0,
        noseBridge: (json['noseBridge'] as num?)?.toDouble() ?? 0.0,
        mouthSize: (json['mouthSize'] as num?)?.toDouble() ?? 0.0,
        lipEnhance: (json['lipEnhance'] as num?)?.toDouble() ?? 0.0,
        smileCorners: (json['smileCorners'] as num?)?.toDouble() ?? 0.0,
        mouthPosition: (json['mouthPosition'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        intensity,
        faceSlimming,
        vFace,
        jawbone,
        pointyChin,
        chinLength,
        cheekbone,
        forehead,
        temple,
        eyeSize,
        eyeDistance,
        eyeAngle,
        eyeCorner,
        eyePosition,
        noseSize,
        noseBridge,
        mouthSize,
        lipEnhance,
        smileCorners,
        mouthPosition,
      ];
}
