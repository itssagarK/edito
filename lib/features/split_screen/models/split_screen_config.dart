import 'package:equatable/equatable.dart';
import 'split_screen_preset.dart';
import 'split_screen_cell.dart';

class SplitScreenConfig extends Equatable {
  final bool isEnabled;
  final SplitScreenPresetType preset;
  final List<SplitScreenCell> cells;
  final double borderWidth;
  final int borderColor;
  final double cornerRadius;
  final int? activeCellIndex;

  const SplitScreenConfig({
    this.isEnabled = false,
    this.preset = SplitScreenPresetType.twoVertical,
    this.cells = const [],
    this.borderWidth = 2.0,
    this.borderColor = 0xFFFFFFFF,
    this.cornerRadius = 0.0,
    this.activeCellIndex,
  });

  bool get isActive => isEnabled;

  /// Returns fully guaranteed list of cells matching preset.cellCount
  List<SplitScreenCell> get effectiveCells {
    final count = preset.cellCount;
    final result = <SplitScreenCell>[];
    for (int i = 0; i < count; i++) {
      final existing = cells.firstWhere(
        (c) => c.index == i,
        orElse: () => SplitScreenCell(index: i),
      );
      result.add(existing);
    }
    return result;
  }

  SplitScreenConfig updateCell(SplitScreenCell updatedCell) {
    final current = effectiveCells;
    final updatedList = current.map((c) => c.index == updatedCell.index ? updatedCell : c).toList();
    return copyWith(cells: updatedList);
  }

  SplitScreenConfig copyWith({
    bool? isEnabled,
    SplitScreenPresetType? preset,
    List<SplitScreenCell>? cells,
    double? borderWidth,
    int? borderColor,
    double? cornerRadius,
    int? activeCellIndex,
  }) {
    return SplitScreenConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      preset: preset ?? this.preset,
      cells: cells ?? this.cells,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      activeCellIndex: activeCellIndex ?? this.activeCellIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'preset': preset.name,
        'cells': cells.map((c) => c.toJson()).toList(),
        'borderWidth': borderWidth,
        'borderColor': borderColor,
        'cornerRadius': cornerRadius,
        'activeCellIndex': activeCellIndex,
      };

  factory SplitScreenConfig.fromJson(Map<String, dynamic> json) => SplitScreenConfig(
        isEnabled: json['isEnabled'] as bool? ?? false,
        preset: SplitScreenPresetType.values.firstWhere(
          (p) => p.name == json['preset'],
          orElse: () => SplitScreenPresetType.twoVertical,
        ),
        cells: (json['cells'] as List<dynamic>?)
                ?.map((c) => SplitScreenCell.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 2.0,
        borderColor: (json['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
        activeCellIndex: (json['activeCellIndex'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [
        isEnabled,
        preset,
        cells,
        borderWidth,
        borderColor,
        cornerRadius,
        activeCellIndex,
      ];
}
