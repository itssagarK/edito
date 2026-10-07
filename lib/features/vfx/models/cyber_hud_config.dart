import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Modes of sci-fi tactical HUD holograms and cyber reticles.
enum CyberHudMode {
  tacticalTargeting,
  radarSonarScan,
  sciFiTelemetry,
  cyberpunkCombat,
  flightAvionics,
}

extension CyberHudModeExtension on CyberHudMode {
  String get label {
    switch (this) {
      case CyberHudMode.tacticalTargeting:
        return 'Tactical Target';
      case CyberHudMode.radarSonarScan:
        return 'Radar Sonar';
      case CyberHudMode.sciFiTelemetry:
        return 'Sci-Fi Telemetry';
      case CyberHudMode.cyberpunkCombat:
        return 'Cyber Combat';
      case CyberHudMode.flightAvionics:
        return 'Flight Avionics';
    }
  }

  String get description {
    switch (this) {
      case CyberHudMode.tacticalTargeting:
        return 'Precision target lock brackets with missile tracking lead indicators';
      case CyberHudMode.radarSonarScan:
        return '360° rotating radar sweep arm with sonar ping rings and contact blips';
      case CyberHudMode.sciFiTelemetry:
        return 'Orbital telemetry overlay with digital compass, altitude, and coordinates';
      case CyberHudMode.cyberpunkCombat:
        return 'Aggressive combat HUD with hexagonal shields and critical lock alerts';
      case CyberHudMode.flightAvionics:
        return 'Military jet HUD with artificial horizon, pitch ladder, and flight director';
    }
  }

  String get iconAsset {
    switch (this) {
      case CyberHudMode.tacticalTargeting:
        return 'gps_fixed';
      case CyberHudMode.radarSonarScan:
        return 'radar';
      case CyberHudMode.sciFiTelemetry:
        return 'satellite_alt';
      case CyberHudMode.cyberpunkCombat:
        return 'security';
      case CyberHudMode.flightAvionics:
        return 'flight';
    }
  }
}

/// Palette colors for holographic cyber HUD displays.
enum CyberHudColor {
  cyanQuantum,
  neonGreen,
  amberWarning,
  crimsonCombat,
  violetSyndicate,
}

extension CyberHudColorExtension on CyberHudColor {
  String get label {
    switch (this) {
      case CyberHudColor.cyanQuantum:
        return 'Quantum Cyan';
      case CyberHudColor.neonGreen:
        return 'Phosphor Green';
      case CyberHudColor.amberWarning:
        return 'Warning Amber';
      case CyberHudColor.crimsonCombat:
        return 'Combat Crimson';
      case CyberHudColor.violetSyndicate:
        return 'Syndicate Violet';
    }
  }

  Color get color {
    switch (this) {
      case CyberHudColor.cyanQuantum:
        return const Color(0xFF00F0FF);
      case CyberHudColor.neonGreen:
        return const Color(0xFF00FF66);
      case CyberHudColor.amberWarning:
        return const Color(0xFFFFB800);
      case CyberHudColor.crimsonCombat:
        return const Color(0xFFFF1744);
      case CyberHudColor.violetSyndicate:
        return const Color(0xFFD500F9);
    }
  }

  String get hexColor {
    switch (this) {
      case CyberHudColor.cyanQuantum:
        return '0x00F0FF';
      case CyberHudColor.neonGreen:
        return '0x00FF66';
      case CyberHudColor.amberWarning:
        return '0xFFFFB800';
      case CyberHudColor.crimsonCombat:
        return '0xFFFF1744';
      case CyberHudColor.violetSyndicate:
        return '0xD500F9';
    }
  }
}

/// Configuration for sci-fi cyber HUD holograms and tactical reticles.
class CyberHudConfig extends Equatable {
  final bool isEnabled;
  final CyberHudMode mode;
  final CyberHudColor color;
  final double opacity; // 0.0 to 1.0
  final double scale; // 0.5 to 1.8
  final bool scanlines;
  final bool showTelemetry;
  final double sweepSpeed; // 0.2 to 3.0

  const CyberHudConfig({
    this.isEnabled = false,
    this.mode = CyberHudMode.tacticalTargeting,
    this.color = CyberHudColor.cyanQuantum,
    this.opacity = 0.85,
    this.scale = 1.0,
    this.scanlines = true,
    this.showTelemetry = true,
    this.sweepSpeed = 1.0,
  });

  bool get isActive => isEnabled && opacity > 0.0;

  static const CyberHudConfig defaultDisabled = CyberHudConfig();

  // Curated 5 cinematic presets
  static const CyberHudConfig presetHunterLock = CyberHudConfig(
    isEnabled: true,
    mode: CyberHudMode.tacticalTargeting,
    color: CyberHudColor.crimsonCombat,
    opacity: 0.90,
    scale: 1.1,
    scanlines: true,
    showTelemetry: true,
    sweepSpeed: 1.0,
  );

  static const CyberHudConfig presetSonarSweep = CyberHudConfig(
    isEnabled: true,
    mode: CyberHudMode.radarSonarScan,
    color: CyberHudColor.neonGreen,
    opacity: 0.85,
    scale: 1.0,
    scanlines: true,
    showTelemetry: true,
    sweepSpeed: 1.4,
  );

  static const CyberHudConfig presetAvionicsHud = CyberHudConfig(
    isEnabled: true,
    mode: CyberHudMode.flightAvionics,
    color: CyberHudColor.cyanQuantum,
    opacity: 0.85,
    scale: 1.0,
    scanlines: false,
    showTelemetry: true,
    sweepSpeed: 0.8,
  );

  static const CyberHudConfig presetCyberCombat = CyberHudConfig(
    isEnabled: true,
    mode: CyberHudMode.cyberpunkCombat,
    color: CyberHudColor.amberWarning,
    opacity: 0.90,
    scale: 1.2,
    scanlines: true,
    showTelemetry: true,
    sweepSpeed: 1.2,
  );

  static const CyberHudConfig presetQuantumOrbital = CyberHudConfig(
    isEnabled: true,
    mode: CyberHudMode.sciFiTelemetry,
    color: CyberHudColor.violetSyndicate,
    opacity: 0.75,
    scale: 0.9,
    scanlines: true,
    showTelemetry: false,
    sweepSpeed: 0.6,
  );

  CyberHudConfig copyWith({
    bool? isEnabled,
    CyberHudMode? mode,
    CyberHudColor? color,
    double? opacity,
    double? scale,
    bool? scanlines,
    bool? showTelemetry,
    double? sweepSpeed,
  }) {
    return CyberHudConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      scanlines: scanlines ?? this.scanlines,
      showTelemetry: showTelemetry ?? this.showTelemetry,
      sweepSpeed: sweepSpeed ?? this.sweepSpeed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'mode': mode.name,
      'color': color.name,
      'opacity': opacity,
      'scale': scale,
      'scanlines': scanlines,
      'showTelemetry': showTelemetry,
      'sweepSpeed': sweepSpeed,
    };
  }

  factory CyberHudConfig.fromJson(Map<String, dynamic> json) {
    return CyberHudConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: CyberHudMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => CyberHudMode.tacticalTargeting,
      ),
      color: CyberHudColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => CyberHudColor.cyanQuantum,
      ),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.85,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      scanlines: json['scanlines'] as bool? ?? true,
      showTelemetry: json['showTelemetry'] as bool? ?? true,
      sweepSpeed: (json['sweepSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        color,
        opacity,
        scale,
        scanlines,
        showTelemetry,
        sweepSpeed,
      ];
}
