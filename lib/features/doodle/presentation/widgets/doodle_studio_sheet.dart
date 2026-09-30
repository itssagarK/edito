import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/doodle_stroke.dart';
import '../../models/doodle_config.dart';

class DoodleStudioSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const DoodleStudioSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<DoodleStudioSheet> createState() => _DoodleStudioSheetState();
}

class _DoodleStudioSheetState extends State<DoodleStudioSheet> {
  late DoodleConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.doodle;
  }

  void _update(DoodleConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(doodle: _config));
  }

  void _undoLastStroke() {
    if (_config.strokes.isEmpty) return;
    final updated = List<DoodleStroke>.from(_config.strokes)..removeLast();
    _update(_config.copyWith(strokes: updated));
  }

  void _clearAllStrokes() {
    _update(_config.copyWith(strokes: const []));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? null : const BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 12),
                  if (_config.isEnabled) ...[
                    _buildBrushTypeSelector(),
                    const SizedBox(height: 12),
                    if (_config.activeBrush != DoodleBrushType.eraser) ...[
                      _buildColorPalette(),
                      const SizedBox(height: 12),
                    ],
                    _buildBrushSizeSlider(),
                    const SizedBox(height: 12),
                    if (_config.activeBrush != DoodleBrushType.eraser) ...[
                      _buildOpacitySlider(),
                      const SizedBox(height: 12),
                    ],
                    _buildActionButtons(),
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
              color: const Color(0xFFFF2D55).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.draw,
              color: Color(0xFFFF2D55),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doodle & Brush Studio',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Edito Pro Creative Painting & Annotations',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accent),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFFFF2D55) : AppColors.border,
          width: _config.isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creative Drawing Canvas',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isEnabled
                      ? 'Active — ${_config.strokes.length} strokes rendered on video'
                      : 'Enable to draw freehand doodles, neon arrows, and annotations',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFFFF2D55),
            onChanged: (val) {
              _update(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrushTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: DoodleBrushType.values.map((brush) {
          final isSelected = _config.activeBrush == brush;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _update(_config.copyWith(activeBrush: brush)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF2D55).withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    brush.icon,
                    size: 20,
                    color: isSelected ? const Color(0xFFFF2D55) : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brush.label,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFFF2D55) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stroke Color Palette', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: DoodleConfig.studioColors.map((cVal) {
              final isSelected = _config.brushColorValue == cVal;
              final col = Color(cVal);
              return GestureDetector(
                onTap: () => _update(_config.copyWith(brushColorValue: cVal)),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : AppColors.border,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: col.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: col.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSizeSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Brush Stroke Width', style: AppTypography.bodySmall),
              Text(
                '${_config.brushSize.toInt()} px',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF2D55)),
              ),
            ],
          ),
          Slider(
            value: _config.brushSize,
            min: 2.0,
            max: 80.0,
            activeColor: const Color(0xFFFF2D55),
            inactiveColor: AppColors.border,
            onChanged: (val) => _update(_config.copyWith(brushSize: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildOpacitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Stroke Opacity', style: AppTypography.bodySmall),
              Text(
                '${(_config.opacity * 100).toInt()}%',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF2D55)),
              ),
            ],
          ),
          Slider(
            value: _config.opacity,
            min: 0.1,
            max: 1.0,
            activeColor: const Color(0xFFFF2D55),
            inactiveColor: AppColors.border,
            onChanged: (val) => _update(_config.copyWith(opacity: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasStrokes = _config.strokes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo Stroke'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasStrokes ? AppColors.textPrimary : AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: hasStrokes ? _undoLastStroke : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasStrokes ? const Color(0xFFFF2D55) : AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: hasStrokes ? _clearAllStrokes : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_all, size: 16),
          label: const Text('Apply Drawings to All Video Clips'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onSave(widget.clip.copyWith(doodle: _config), applyToAll: true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doodle drawings applied to all clips'),
                duration: Duration(milliseconds: 900),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),
      ],
    );
  }
}
