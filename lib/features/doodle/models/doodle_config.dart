import 'package:equatable/equatable.dart';
import 'doodle_stroke.dart';

/// CapCut Pro Creative Brush & Doodle Drawing Configuration.
/// Extracted from Brush2D_StickerPainter, Brush2D_StickerEraser, and normal_pen native architectures.
class DoodleConfig extends Equatable {
  final bool isEnabled;
  final DoodleBrushType activeBrush;
  final int brushColorValue; // Current active stroke color
  final double brushSize; // 2.0 to 80.0 px (default 16.0)
  final double opacity; // 0.1 to 1.0 (default 1.0)
  final double hardness; // 0.0 to 1.0 (default 1.0)
  final List<DoodleStroke> strokes;

  const DoodleConfig({
    this.isEnabled = false,
    this.activeBrush = DoodleBrushType.pen,
    this.brushColorValue = 0xFFFFD700, // Studio Gold
    this.brushSize = 16.0,
    this.opacity = 1.0,
    this.hardness = 1.0,
    this.strokes = const [],
  });

  /// Curated studio palette colors for doodle annotations and artistic lettering.
  static const List<int> studioColors = [
    0xFFFFD700, // Vibrant Gold
    0xFF00E5FF, // Cyan Glow
    0xFFFF2D55, // Coral Neon Pink
    0xFF00FF88, // Electric Lime
    0xFFBD00FF, // Cyber Violet
    0xFFFF9100, // Sunset Orange
    0xFFFFFFFF, // Pure Studio White
    0xFF1E272E, // Carbon Charcoal
  ];

  bool get isActive => isEnabled && strokes.isNotEmpty;

  DoodleConfig copyWith({
    bool? isEnabled,
    DoodleBrushType? activeBrush,
    int? brushColorValue,
    double? brushSize,
    double? opacity,
    double? hardness,
    List<DoodleStroke>? strokes,
  }) {
    return DoodleConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      activeBrush: activeBrush ?? this.activeBrush,
      brushColorValue: brushColorValue ?? this.brushColorValue,
      brushSize: brushSize ?? this.brushSize,
      opacity: opacity ?? this.opacity,
      hardness: hardness ?? this.hardness,
      strokes: strokes ?? this.strokes,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'activeBrush': activeBrush.name,
        'brushColorValue': brushColorValue,
        'brushSize': brushSize,
        'opacity': opacity,
        'hardness': hardness,
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory DoodleConfig.fromJson(Map<String, dynamic> json) => DoodleConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        activeBrush: json['activeBrush'] != null
            ? DoodleBrushType.values.firstWhere(
                (b) => b.name == json['activeBrush'],
                orElse: () => DoodleBrushType.pen,
              )
            : DoodleBrushType.pen,
        brushColorValue: json['brushColorValue'] as int? ?? 0xFFFFD700,
        brushSize: (json['brushSize'] as num?)?.toDouble() ?? 16.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        hardness: (json['hardness'] as num?)?.toDouble() ?? 1.0,
        strokes: (json['strokes'] as List<dynamic>?)
                ?.map((s) => DoodleStroke.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        isEnabled,
        activeBrush,
        brushColorValue,
        brushSize,
        opacity,
        hardness,
        strokes,
      ];
}
