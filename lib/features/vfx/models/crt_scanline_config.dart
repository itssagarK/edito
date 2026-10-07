import 'package:equatable/equatable.dart';

enum CrtPhosphorTint {
  none,
  amberClassic,      // 1980s Monochrome Amber DEC
  greenPhosphorP1,   // IBM P1 Classic Hacker Green
  cyanTrinitron,     // Sony Trinitron Cyber Aqua
  bwSecurity,        // CCTV High-Contrast B&W
  vaporwavePink,     // Retro Synthwave Neon Pink
}

extension CrtPhosphorTintExtension on CrtPhosphorTint {
  String get label {
    switch (this) {
      case CrtPhosphorTint.none:
        return 'Natural Phosphor';
      case CrtPhosphorTint.amberClassic:
        return 'Amber Classic (1981)';
      case CrtPhosphorTint.greenPhosphorP1:
        return 'P1 Green (IBM 5151)';
      case CrtPhosphorTint.cyanTrinitron:
        return 'Trinitron Cyber Cyan';
      case CrtPhosphorTint.bwSecurity:
        return 'CCTV B&W Monochrome';
      case CrtPhosphorTint.vaporwavePink:
        return 'Vaporwave Neon Pink';
    }
  }

  int? get colorHex {
    switch (this) {
      case CrtPhosphorTint.none:
        return null;
      case CrtPhosphorTint.amberClassic:
        return 0xFFFFB000;
      case CrtPhosphorTint.greenPhosphorP1:
        return 0xFF00FF66;
      case CrtPhosphorTint.cyanTrinitron:
        return 0xFF00F0FF;
      case CrtPhosphorTint.bwSecurity:
        return 0xFFE0E0E0;
      case CrtPhosphorTint.vaporwavePink:
        return 0xFFFF007F;
    }
  }

  String get ffmpegMatrixFilter {
    switch (this) {
      case CrtPhosphorTint.none:
        return '';
      case CrtPhosphorTint.amberClassic:
        return 'colorchannelmixer=rr=1.15:rg=0.7:rb=0:gr=0.3:gg=0.85:gb=0:br=0:bg=0:bb=0.1';
      case CrtPhosphorTint.greenPhosphorP1:
        return 'colorchannelmixer=rr=0.1:rg=0:rb=0:gr=0.6:gg=1.2:gb=0.2:br=0:bg=0.1:bb=0.1';
      case CrtPhosphorTint.cyanTrinitron:
        return 'colorchannelmixer=rr=0.2:rg=0:rb=0:gr=0.1:gg=1.1:gb=0.4:br=0.1:bg=0.4:bb=1.2';
      case CrtPhosphorTint.bwSecurity:
        return 'colorchannelmixer=rr=0.3:rg=0.59:rb=0.11:gr=0.3:gg=0.59:gb=0.11:br=0.3:bg=0.59:bb=0.11';
      case CrtPhosphorTint.vaporwavePink:
        return 'colorchannelmixer=rr=1.2:rg=0.1:rb=0.4:gr=0.1:gg=0.7:gb=0.3:br=0.4:bg=0.2:bb=1.1';
    }
  }
}

class CrtScanlineConfig extends Equatable {
  final bool isEnabled;
  final double scanlinePitch;       // 2.0 to 12.0 pixels
  final double scanlineOpacity;     // 0.0 to 1.0 (darkness of lines)
  final double rollingBarSpeed;     // 0.0 to 3.0 (drift velocity)
  final double rollingBarOpacity;   // 0.0 to 0.5 (hum bar intensity)
  final CrtPhosphorTint phosphorTint;
  final double phosphorGlow;        // 0.0 to 1.0 (beam blooming)
  final double screenCurvature;     // 0.0 to 1.0 (corner falloff / barrel)
  final double rgbShadowOffset;     // 0.0 to 12.0 pixels (chromatic aberration)
  final double analogNoise;         // 0.0 to 0.5 (TV snow grain)
  final bool interlacingFlicker;    // 60Hz subtle field jitter

  const CrtScanlineConfig({
    this.isEnabled = false,
    this.scanlinePitch = 4.0,
    this.scanlineOpacity = 0.40,
    this.rollingBarSpeed = 1.0,
    this.rollingBarOpacity = 0.18,
    this.phosphorTint = CrtPhosphorTint.none,
    this.phosphorGlow = 0.35,
    this.screenCurvature = 0.35,
    this.rgbShadowOffset = 3.0,
    this.analogNoise = 0.12,
    this.interlacingFlicker = true,
  });

  bool get isActive => isEnabled && (scanlineOpacity > 0.05 || phosphorTint != CrtPhosphorTint.none);

  // Preset Configurations
  static const arcade1984 = CrtScanlineConfig(
    isEnabled: true,
    scanlinePitch: 3.5,
    scanlineOpacity: 0.55,
    rollingBarSpeed: 0.8,
    rollingBarOpacity: 0.22,
    phosphorTint: CrtPhosphorTint.cyanTrinitron,
    phosphorGlow: 0.45,
    screenCurvature: 0.45,
    rgbShadowOffset: 4.0,
    analogNoise: 0.15,
    interlacingFlicker: true,
  );

  static const cyberpunkTerminal = CrtScanlineConfig(
    isEnabled: true,
    scanlinePitch: 4.0,
    scanlineOpacity: 0.65,
    rollingBarSpeed: 1.5,
    rollingBarOpacity: 0.30,
    phosphorTint: CrtPhosphorTint.greenPhosphorP1,
    phosphorGlow: 0.60,
    screenCurvature: 0.50,
    rgbShadowOffset: 5.0,
    analogNoise: 0.18,
    interlacingFlicker: true,
  );

  static const vhsCamcorder1995 = CrtScanlineConfig(
    isEnabled: true,
    scanlinePitch: 6.0,
    scanlineOpacity: 0.38,
    rollingBarSpeed: 0.5,
    rollingBarOpacity: 0.20,
    phosphorTint: CrtPhosphorTint.amberClassic,
    phosphorGlow: 0.30,
    screenCurvature: 0.30,
    rgbShadowOffset: 3.5,
    analogNoise: 0.25,
    interlacingFlicker: true,
  );

  static const pvmBroadcast = CrtScanlineConfig(
    isEnabled: true,
    scanlinePitch: 2.5,
    scanlineOpacity: 0.30,
    rollingBarSpeed: 0.0,
    rollingBarOpacity: 0.0,
    phosphorTint: CrtPhosphorTint.none,
    phosphorGlow: 0.20,
    screenCurvature: 0.15,
    rgbShadowOffset: 2.0,
    analogNoise: 0.05,
    interlacingFlicker: false,
  );

  static const securityCctv = CrtScanlineConfig(
    isEnabled: true,
    scanlinePitch: 5.0,
    scanlineOpacity: 0.50,
    rollingBarSpeed: 2.0,
    rollingBarOpacity: 0.35,
    phosphorTint: CrtPhosphorTint.bwSecurity,
    phosphorGlow: 0.25,
    screenCurvature: 0.40,
    rgbShadowOffset: 1.5,
    analogNoise: 0.30,
    interlacingFlicker: true,
  );

  CrtScanlineConfig copyWith({
    bool? isEnabled,
    double? scanlinePitch,
    double? scanlineOpacity,
    double? rollingBarSpeed,
    double? rollingBarOpacity,
    CrtPhosphorTint? phosphorTint,
    double? phosphorGlow,
    double? screenCurvature,
    double? rgbShadowOffset,
    double? analogNoise,
    bool? interlacingFlicker,
  }) {
    return CrtScanlineConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      scanlinePitch: scanlinePitch ?? this.scanlinePitch,
      scanlineOpacity: scanlineOpacity ?? this.scanlineOpacity,
      rollingBarSpeed: rollingBarSpeed ?? this.rollingBarSpeed,
      rollingBarOpacity: rollingBarOpacity ?? this.rollingBarOpacity,
      phosphorTint: phosphorTint ?? this.phosphorTint,
      phosphorGlow: phosphorGlow ?? this.phosphorGlow,
      screenCurvature: screenCurvature ?? this.screenCurvature,
      rgbShadowOffset: rgbShadowOffset ?? this.rgbShadowOffset,
      analogNoise: analogNoise ?? this.analogNoise,
      interlacingFlicker: interlacingFlicker ?? this.interlacingFlicker,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'scanlinePitch': scanlinePitch,
        'scanlineOpacity': scanlineOpacity,
        'rollingBarSpeed': rollingBarSpeed,
        'rollingBarOpacity': rollingBarOpacity,
        'phosphorTint': phosphorTint.name,
        'phosphorGlow': phosphorGlow,
        'screenCurvature': screenCurvature,
        'rgbShadowOffset': rgbShadowOffset,
        'analogNoise': analogNoise,
        'interlacingFlicker': interlacingFlicker,
      };

  factory CrtScanlineConfig.fromJson(Map<String, dynamic> json) => CrtScanlineConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        scanlinePitch: (json['scanlinePitch'] as num?)?.toDouble() ?? 4.0,
        scanlineOpacity: (json['scanlineOpacity'] as num?)?.toDouble() ?? 0.40,
        rollingBarSpeed: (json['rollingBarSpeed'] as num?)?.toDouble() ?? 1.0,
        rollingBarOpacity: (json['rollingBarOpacity'] as num?)?.toDouble() ?? 0.18,
        phosphorTint: CrtPhosphorTint.values.firstWhere(
          (e) => e.name == json['phosphorTint'],
          orElse: () => CrtPhosphorTint.none,
        ),
        phosphorGlow: (json['phosphorGlow'] as num?)?.toDouble() ?? 0.35,
        screenCurvature: (json['screenCurvature'] as num?)?.toDouble() ?? 0.35,
        rgbShadowOffset: (json['rgbShadowOffset'] as num?)?.toDouble() ?? 3.0,
        analogNoise: (json['analogNoise'] as num?)?.toDouble() ?? 0.12,
        interlacingFlicker: json['interlacingFlicker'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        scanlinePitch,
        scanlineOpacity,
        rollingBarSpeed,
        rollingBarOpacity,
        phosphorTint,
        phosphorGlow,
        screenCurvature,
        rgbShadowOffset,
        analogNoise,
        interlacingFlicker,
      ];
}
