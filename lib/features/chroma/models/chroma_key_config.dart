import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ChromaKeyConfig extends Equatable {
  final bool isEnabled;
  final int keyColorValue; // e.g. 0xFF00FF00 (green)
  final double similarity; // 0.05 to 0.60
  final double smoothness; // 0.0 to 0.40
  final double spill;      // 0.0 to 0.50

  const ChromaKeyConfig({
    this.isEnabled = false,
    this.keyColorValue = 0xFF00FF00, // Default pure green screen
    this.similarity = 0.15,
    this.smoothness = 0.08,
    this.spill = 0.10,
  });

  Color get keyColor => Color(keyColorValue);

  ChromaKeyConfig copyWith({
    bool? isEnabled,
    int? keyColorValue,
    double? similarity,
    double? smoothness,
    double? spill,
  }) {
    return ChromaKeyConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      keyColorValue: keyColorValue ?? this.keyColorValue,
      similarity: similarity ?? this.similarity,
      smoothness: smoothness ?? this.smoothness,
      spill: spill ?? this.spill,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'keyColorValue': keyColorValue,
        'similarity': similarity,
        'smoothness': smoothness,
        'spill': spill,
      };

  factory ChromaKeyConfig.fromJson(Map<String, dynamic> json) => ChromaKeyConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        keyColorValue: (json['keyColorValue'] as num?)?.toInt() ?? 0xFF00FF00,
        similarity: (json['similarity'] as num?)?.toDouble() ?? 0.15,
        smoothness: (json['smoothness'] as num?)?.toDouble() ?? 0.08,
        spill: (json['spill'] as num?)?.toDouble() ?? 0.10,
      );

  @override
  List<Object?> get props => [isEnabled, keyColorValue, similarity, smoothness, spill];
}
