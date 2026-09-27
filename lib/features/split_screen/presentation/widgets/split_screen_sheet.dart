import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/split_screen_config.dart';
import '../../models/split_screen_preset.dart';
import '../../models/split_screen_cell.dart';

class SplitScreenSheet extends StatefulWidget {
  final SplitScreenConfig config;
  final Function(SplitScreenConfig updatedConfig) onSave;
  final VoidCallback onDone;
  final VoidCallback? onAssignMediaToActiveCell;
  final bool isDocked;

  const SplitScreenSheet({
    super.key,
    required this.config,
    required this.onSave,
    required this.onDone,
    this.onAssignMediaToActiveCell,
    this.isDocked = false,
  });

  @override
  State<SplitScreenSheet> createState() => _SplitScreenSheetState();
}

class _SplitScreenSheetState extends State<SplitScreenSheet> {
  late SplitScreenConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _update(SplitScreenConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(_config);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? null
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 16),
                  if (_config.isEnabled) ...[
                    _buildPresetSection(),
                    const SizedBox(height: 16),
                    _buildCellSlotsSection(),
                    const SizedBox(height: 16),
                    _buildBorderAndCornerSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFBD00FF).withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFFBD00FF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Grid Split Screen Studio',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Create reaction videos, comparisons & video collages',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 22),
            onPressed: widget.onDone,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFFBD00FF) : AppColors.border,
          width: _config.isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: _config.isEnabled ? const Color(0xFFBD00FF) : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split Screen Collage',
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  Text(
                    _config.isEnabled ? 'Active: ${_config.preset.label}' : 'Single full canvas',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFFBD00FF),
            onChanged: (val) {
              _update(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Grid Layout Presets', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            Text('${_config.preset.cellCount} Slots', style: AppTypography.timecode.copyWith(fontSize: 12, color: const Color(0xFFBD00FF))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SplitScreenPresetType.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = SplitScreenPresetType.values[index];
              final isSelected = _config.preset == preset;

              return InkWell(
                onTap: () {
                  _update(_config.copyWith(
                    preset: preset,
                    activeCellIndex: 0,
                  ));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBD00FF).withOpacity(0.18) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFBD00FF) : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mini Grid Diagram
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: _buildMiniGridDiagram(preset, isSelected),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${preset.cellCount} Cells',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGridDiagram(SplitScreenPresetType preset, bool isSelected) {
    final rects = preset.cellRects;
    final activeColor = isSelected ? const Color(0xFFBD00FF) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: activeColor.withOpacity(0.5), width: 1),
      ),
      child: Stack(
        children: [
          for (int i = 0; i < rects.length; i++)
            Positioned(
              left: rects[i].left * 36,
              top: rects[i].top * 36,
              width: rects[i].width * 36,
              height: rects[i].height * 36,
              child: Container(
                margin: const EdgeInsets.all(0.8),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(1.5),
                  border: Border.all(color: activeColor, width: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCellSlotsSection() {
    final cells = _config.effectiveCells;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Media Slots & Assignment', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            if (widget.onAssignMediaToActiveCell != null)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Color(0xFFBD00FF)),
                label: const Text('Add Media', style: TextStyle(color: Color(0xFFBD00FF), fontSize: 12)),
                onPressed: widget.onAssignMediaToActiveCell,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < cells.length; i++)
              _buildSlotChip(cells[i], i),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotChip(SplitScreenCell cell, int index) {
    final isSelected = _config.activeCellIndex == index;

    return InkWell(
      onTap: () {
        _update(_config.copyWith(activeCellIndex: index));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBD00FF).withOpacity(0.25) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFBD00FF) : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cell.hasMedia ? Icons.movie_outlined : Icons.add_circle_outline,
              size: 14,
              color: isSelected ? const Color(0xFFBD00FF) : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Slot ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorderAndCornerSection() {
    final borderColors = [
      0xFFFFFFFF, // Pure White
      0xFF000000, // Black
      0xFF00F0FF, // Electric Cyan
      0xFFFFDC00, // Amber Yellow
      0xFFBD00FF, // Royal Purple
      0xFFFF3450, // Crimson
      0x00000000, // Seamless / Transparent
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grid Dividers & Frame Style', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Border Width
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Divider Width', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.borderWidth.toInt()} px', style: AppTypography.timecode.copyWith(fontSize: 12)),
            ],
          ),
          Slider(
            value: _config.borderWidth,
            min: 0.0,
            max: 12.0,
            divisions: 12,
            activeColor: const Color(0xFFBD00FF),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(borderWidth: val));
            },
          ),

          const SizedBox(height: 8),

          // Border Color Swatches
          const Text('Divider Color', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: borderColors.map((hex) {
              final isSel = _config.borderColor == hex;
              return InkWell(
                onTap: () {
                  _update(_config.copyWith(borderColor: hex));
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? const Color(0xFFBD00FF) : Colors.white24,
                      width: isSel ? 2.5 : 1.0,
                    ),
                  ),
                  child: hex == 0x00000000
                      ? const Center(child: Icon(Icons.block, size: 14, color: Colors.white70))
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Corner Radius
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cell Rounded Corners', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.cornerRadius.toInt()} px', style: AppTypography.timecode.copyWith(fontSize: 12)),
            ],
          ),
          Slider(
            value: _config.cornerRadius,
            min: 0.0,
            max: 24.0,
            divisions: 24,
            activeColor: const Color(0xFFBD00FF),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(cornerRadius: val));
            },
          ),
        ],
      ),
    );
  }
}
