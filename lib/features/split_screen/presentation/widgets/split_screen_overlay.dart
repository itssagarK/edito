import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/split_screen_config.dart';
import '../../models/split_screen_preset.dart';
import '../../models/split_screen_cell.dart';

class SplitScreenOverlay extends StatelessWidget {
  final SplitScreenConfig config;
  final Function(int cellIndex)? onSelectCell;
  final Function(SplitScreenCell updatedCell)? onCellChanged;
  final VoidCallback? onAddMediaToActiveCell;

  const SplitScreenOverlay({
    super.key,
    required this.config,
    this.onSelectCell,
    this.onCellChanged,
    this.onAddMediaToActiveCell,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isEnabled) return const SizedBox.shrink();

    final rects = config.preset.cellRects;
    final cells = config.effectiveCells;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Draw all cells
            for (int i = 0; i < rects.length; i++)
              _buildCellWidget(
                index: i,
                normRect: rects[i],
                cell: i < cells.length ? cells[i] : SplitScreenCell(index: i),
                canvasWidth: w,
                canvasHeight: h,
              ),

            // Outer Frame Border
            if (config.borderWidth > 0.0)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(config.cornerRadius),
                    border: Border.all(
                      color: Color(config.borderColor),
                      width: config.borderWidth,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCellWidget({
    required int index,
    required Rect normRect,
    required SplitScreenCell cell,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final left = normRect.left * canvasWidth;
    final top = normRect.top * canvasHeight;
    final width = normRect.width * canvasWidth;
    final height = normRect.height * canvasHeight;
    final isSelected = config.activeCellIndex == index;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => onSelectCell?.call(index),
        child: Container(
          margin: EdgeInsets.all(config.borderWidth / 2),
          decoration: BoxDecoration(
            color: cell.hasMedia ? Colors.transparent : Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(config.cornerRadius),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Color(config.borderColor).withOpacity(0.7),
              width: isSelected ? 2.5 : (config.borderWidth > 0 ? 1.0 : 0.0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(config.cornerRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Empty placeholder or Media prompt
                if (!cell.hasMedia)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: isSelected ? AppColors.primaryLight : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Slot ${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cell Index Badge
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Selected Action Toolbar (when active)
                if (isSelected)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onAddMediaToActiveCell != null)
                          InkWell(
                            onTap: onAddMediaToActiveCell,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
