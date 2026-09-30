import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/object_removal_config.dart';
import '../../models/object_removal_stroke.dart';

class ObjectRemovalSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const ObjectRemovalSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<ObjectRemovalSheet> createState() => _ObjectRemovalSheetState();
}

class _ObjectRemovalSheetState extends State<ObjectRemovalSheet> {
  late ObjectRemovalConfig _config;
  final List<List<ObjectRemovalStroke>> _undoStack = [];
  final List<List<ObjectRemovalStroke>> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _config = widget.clip.objectRemoval;
  }

  void _update(ObjectRemovalConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(objectRemoval: _config));
  }

  void _pushUndoState() {
    _undoStack.add(List<ObjectRemovalStroke>.from(_config.strokes));
    _redoStack.clear();
  }

  void _undo() {
    if (_config.strokes.isNotEmpty) {
      _pushUndoState();
      final updatedStrokes = List<ObjectRemovalStroke>.from(_config.strokes)..removeLast();
      _update(_config.copyWith(strokes: updatedStrokes));
    } else if (_config.regions.isNotEmpty) {
      final updatedRegions = List<ObjectRemovalRegion>.from(_config.regions)..removeLast();
      _update(_config.copyWith(regions: updatedRegions));
    }
  }

  void _clearAll() {
    _pushUndoState();
    _update(_config.copyWith(
      strokes: const [],
      regions: const [],
    ));
  }

  void _applyPreset(ObjectRemovalPreset preset) {
    _pushUndoState();
    final newConfig = ObjectRemovalConfig.fromPreset(preset).copyWith(
      strokes: _config.strokes,
      regions: _config.regions,
    );
    _update(newConfig);
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
                    _buildPresetsSection(),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildToolSelector(),
                    const SizedBox(height: 16),
                    _buildSlidersSection(),
                    const SizedBox(height: 16),
                    _buildMaskActions(),
                    const SizedBox(height: 16),
                    _buildTogglesSection(),
                    const SizedBox(height: 16),
                    _buildApplyToAllButton(),
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
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_fix_high,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Magic Eraser',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Inpainting & Object Removal Pen',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
          color: _config.isEnabled ? AppColors.accent : AppColors.border,
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
                  'Enable AI Removal',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isEnabled
                    ? 'Active — Draw on video canvas to erase objects'
                    : 'Turn on to remove unwanted objects or watermarks',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: AppColors.accent,
            onChanged: (val) {
              _update(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SMART WORKFLOW PRESETS',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ObjectRemovalPreset.values.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(preset.label),
                  selected: false,
                  selectedColor: AppColors.accent.withOpacity(0.2),
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  onSelected: (selected) {
                    if (selected) _applyPreset(preset);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INPAINTING ALGORITHM',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...ObjectRemovalMode.values.map((mode) {
          final isSelected = _config.mode == mode;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.12) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.4 : 1.0,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                mode == ObjectRemovalMode.aiMagicEraser
                    ? Icons.auto_awesome
                    : mode == ObjectRemovalMode.smartDelogo
                        ? Icons.healing
                        : mode == ObjectRemovalMode.blurPatch
                            ? Icons.blur_on
                            : Icons.content_copy,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              title: Text(
                mode.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                mode.description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.accent, size: 18)
                  : null,
              onTap: () {
                _update(_config.copyWith(mode: mode));
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildToolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECTION TOOL',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ObjectRemovalToolType.values.map((tool) {
            final isSelected = _config.activeTool == tool;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _update(_config.copyWith(activeTool: tool)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          tool == ObjectRemovalToolType.brush
                              ? Icons.brush
                              : tool == ObjectRemovalToolType.eraser
                                  ? Icons.cleaning_services
                                  : tool == ObjectRemovalToolType.rectangle
                                      ? Icons.crop_square
                                      : Icons.gesture,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.label,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlidersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pen Brush Size', style: AppTypography.bodySmall),
            Row(
              children: [
                Container(
                  width: _config.brushSize * 0.4,
                  height: _config.brushSize * 0.4,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_config.brushSize.toInt()} px', style: AppTypography.caption),
              ],
            ),
          ],
        ),
        Slider(
          value: _config.brushSize,
          min: 6.0,
          max: 100.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _update(_config.copyWith(brushSize: val)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Edge Feathering', style: AppTypography.bodySmall),
            Text('${(_config.feather * 100).toInt()}%', style: AppTypography.caption),
          ],
        ),
        Slider(
          value: _config.feather,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _update(_config.copyWith(feather: val)),
        ),
      ],
    );
  }

  Widget _buildMaskActions() {
    final strokeCount = _config.strokes.length + _config.regions.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.layers, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$strokeCount active mask ${strokeCount == 1 ? 'patch' : 'patches'}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('Undo'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            onPressed: strokeCount > 0 ? _undo : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: strokeCount > 0 ? _clearAll : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTogglesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Show Overlay Mask', style: AppTypography.bodySmall),
            subtitle: Text('Renders red translucent highlight on canvas', style: AppTypography.caption),
            value: _config.showMaskOverlay,
            activeColor: AppColors.accent,
            onChanged: (val) => _update(_config.copyWith(showMaskOverlay: val)),
          ),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Invert Removal Mask', style: AppTypography.bodySmall),
            subtitle: Text('Preserve painted object and erase surroundings', style: AppTypography.caption),
            value: _config.invertMask,
            activeColor: AppColors.accent,
            onChanged: (val) => _update(_config.copyWith(invertMask: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyToAllButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.copy_all, size: 18),
      label: const Text('Apply Removal Config to All Video Clips'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        widget.onSave(widget.clip.copyWith(objectRemoval: _config), applyToAll: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Object Removal configuration applied to all clips'),
            duration: Duration(milliseconds: 900),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
      },
    );
  }
}
