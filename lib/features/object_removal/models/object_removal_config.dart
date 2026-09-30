import 'dart:math' as math;
import 'dart:ui' show Rect, Size;
import 'package:equatable/equatable.dart';
import 'object_removal_stroke.dart';

enum ObjectRemovalMode {
  aiMagicEraser,
  smartDelogo,
  blurPatch,
  cloneStamp,
}

extension ObjectRemovalModeExtension on ObjectRemovalMode {
  String get label {
    switch (this) {
      case ObjectRemovalMode.aiMagicEraser:
        return 'AI Magic Eraser';
      case ObjectRemovalMode.smartDelogo:
        return 'Smart Delogo';
      case ObjectRemovalMode.blurPatch:
        return 'Privacy Blur';
      case ObjectRemovalMode.cloneStamp:
        return 'Clone Stamp';
    }
  }

  String get description {
    switch (this) {
      case ObjectRemovalMode.aiMagicEraser:
        return 'Deep inpainting boundary texture reconstruction';
      case ObjectRemovalMode.smartDelogo:
        return 'Fast edge-preserving bilateral spatial interpolation';
      case ObjectRemovalMode.blurPatch:
        return 'Silky Gaussian privacy defocus obscuration';
      case ObjectRemovalMode.cloneStamp:
        return 'Exemplar texture cloning from neighbor source';
    }
  }
}

enum ObjectRemovalToolType {
  brush,
  eraser,
  rectangle,
  lasso,
}

extension ObjectRemovalToolTypeExtension on ObjectRemovalToolType {
  String get label {
    switch (this) {
      case ObjectRemovalToolType.brush:
        return 'Brush Pen';
      case ObjectRemovalToolType.eraser:
        return 'Eraser';
      case ObjectRemovalToolType.rectangle:
        return 'Box Select';
      case ObjectRemovalToolType.lasso:
        return 'Lasso Area';
    }
  }
}

enum ObjectRemovalPreset {
  custom,
  watermark,
  photobomber,
  powerLines,
  blemish,
  brandLogo,
}

extension ObjectRemovalPresetExtension on ObjectRemovalPreset {
  String get label {
    switch (this) {
      case ObjectRemovalPreset.custom:
        return 'Custom';
      case ObjectRemovalPreset.watermark:
        return 'Watermark / Text';
      case ObjectRemovalPreset.photobomber:
        return 'Photobomber';
      case ObjectRemovalPreset.powerLines:
        return 'Wires & Lines';
      case ObjectRemovalPreset.blemish:
        return 'Skin Blemish';
      case ObjectRemovalPreset.brandLogo:
        return 'Brand Logo';
    }
  }
}

/// CapCut Pro AI Object Removal & Magic Eraser Pen Suite Configuration.
class ObjectRemovalConfig extends Equatable {
  final bool isEnabled;
  final ObjectRemovalMode mode;
  final ObjectRemovalToolType activeTool;
  final List<ObjectRemovalStroke> strokes;
  final List<ObjectRemovalRegion> regions;
  final double brushSize; // 6.0 to 120.0 (display pixels)
  final double feather; // 0.0 to 1.0 softness
  final double opacity; // 0.0 to 1.0 mask opacity
  final bool invertMask; // Invert mask (remove background vs object)
  final bool showMaskOverlay; // Live translucent red overlay visible
  final int maskColorValue; // e.g. 0x88FF2D55

  const ObjectRemovalConfig({
    this.isEnabled = false,
    this.mode = ObjectRemovalMode.aiMagicEraser,
    this.activeTool = ObjectRemovalToolType.brush,
    this.strokes = const [],
    this.regions = const [],
    this.brushSize = 28.0,
    this.feather = 0.25,
    this.opacity = 1.0,
    this.invertMask = false,
    this.showMaskOverlay = true,
    this.maskColorValue = 0x88FF2D55,
  });

  /// Returns true if removal is enabled and there are active strokes or regions to process.
  bool get isActive => isEnabled && (strokes.isNotEmpty || regions.isNotEmpty);

  /// Computes the unified bounding box in pixels covering all active strokes and regions.
  Rect? computeCombinedBounds(Size size) {
    if (!isActive) return null;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final stroke in strokes) {
      if (stroke.isEraser) continue;
      final bounds = stroke.computePixelBounds(size);
      minX = math.min(minX, bounds.left);
      minY = math.min(minY, bounds.top);
      maxX = math.max(maxX, bounds.right);
      maxY = math.max(maxY, bounds.bottom);
    }

    for (final region in regions) {
      final rect = region.toRect(size);
      minX = math.min(minX, rect.left);
      minY = math.min(minY, rect.top);
      maxX = math.max(maxX, rect.right);
      maxY = math.max(maxY, rect.bottom);
    }

    if (minX == double.infinity || maxX == -double.infinity) {
      return null;
    }

    return Rect.fromLTRB(
      minX.clamp(0.0, size.width),
      minY.clamp(0.0, size.height),
      maxX.clamp(0.0, size.width),
      maxY.clamp(0.0, size.height),
    );
  }

  /// Preset factory generator for standard editing workflows.
  factory ObjectRemovalConfig.fromPreset(ObjectRemovalPreset preset) {
    switch (preset) {
      case ObjectRemovalPreset.watermark:
        return const ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.smartDelogo,
          activeTool: ObjectRemovalToolType.rectangle,
          brushSize: 32.0,
          feather: 0.15,
        );
      case ObjectRemovalPreset.photobomber:
        return const ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.aiMagicEraser,
          activeTool: ObjectRemovalToolType.brush,
          brushSize: 42.0,
          feather: 0.35,
        );
      case ObjectRemovalPreset.powerLines:
        return const ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.aiMagicEraser,
          activeTool: ObjectRemovalToolType.brush,
          brushSize: 12.0,
          feather: 0.10,
        );
      case ObjectRemovalPreset.blemish:
        return const ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.aiMagicEraser,
          activeTool: ObjectRemovalToolType.brush,
          brushSize: 18.0,
          feather: 0.40,
        );
      case ObjectRemovalPreset.brandLogo:
        return const ObjectRemovalConfig(
          isEnabled: true,
          mode: ObjectRemovalMode.smartDelogo,
          activeTool: ObjectRemovalToolType.rectangle,
          brushSize: 26.0,
          feather: 0.20,
        );
      case ObjectRemovalPreset.custom:
        return const ObjectRemovalConfig();
    }
  }

  ObjectRemovalConfig copyWith({
    bool? isEnabled,
    ObjectRemovalMode? mode,
    ObjectRemovalToolType? activeTool,
    List<ObjectRemovalStroke>? strokes,
    List<ObjectRemovalRegion>? regions,
    double? brushSize,
    double? feather,
    double? opacity,
    bool? invertMask,
    bool? showMaskOverlay,
    int? maskColorValue,
  }) {
    return ObjectRemovalConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      activeTool: activeTool ?? this.activeTool,
      strokes: strokes ?? this.strokes,
      regions: regions ?? this.regions,
      brushSize: brushSize ?? this.brushSize,
      feather: feather ?? this.feather,
      opacity: opacity ?? this.opacity,
      invertMask: invertMask ?? this.invertMask,
      showMaskOverlay: showMaskOverlay ?? this.showMaskOverlay,
      maskColorValue: maskColorValue ?? this.maskColorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'mode': mode.index,
        'activeTool': activeTool.index,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'regions': regions.map((r) => r.toJson()).toList(),
        'brushSize': brushSize,
        'feather': feather,
        'opacity': opacity,
        'invertMask': invertMask,
        'showMaskOverlay': showMaskOverlay,
        'maskColorValue': maskColorValue,
      };

  factory ObjectRemovalConfig.fromJson(Map<String, dynamic> json) {
    return ObjectRemovalConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      mode: ObjectRemovalMode.values[(json['mode'] as int?)?.clamp(0, ObjectRemovalMode.values.length - 1) ?? 0],
      activeTool: ObjectRemovalToolType.values[
          (json['activeTool'] as int?)?.clamp(0, ObjectRemovalToolType.values.length - 1) ?? 0],
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((s) => ObjectRemovalStroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      regions: (json['regions'] as List<dynamic>?)
              ?.map((r) => ObjectRemovalRegion.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      brushSize: (json['brushSize'] as num?)?.toDouble() ?? 28.0,
      feather: (json['feather'] as num?)?.toDouble() ?? 0.25,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      invertMask: json['invertMask'] as bool? ?? false,
      showMaskOverlay: json['showMaskOverlay'] as bool? ?? true,
      maskColorValue: json['maskColorValue'] as int? ?? 0x88FF2D55,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        mode,
        activeTool,
        strokes,
        regions,
        brushSize,
        feather,
        opacity,
        invertMask,
        showMaskOverlay,
        maskColorValue,
      ];
}
