import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/keyframe.dart';
import '../../models/text_overlay_config.dart';
import '../../models/text_preset_style.dart';

class TextEditorSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const TextEditorSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (context) => TextEditorSheet(clip: clip, onSave: onSave, onDone: onDone),
    );
  }

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _textController;
  late TextOverlayConfig _config;
  late List<Keyframe> _keyframes;
  String _selectedPresetCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _config = widget.clip.textOverlay;
    _keyframes = List.from(widget.clip.keyframes);
    _textController = TextEditingController(text: _config.text);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(textOverlay: _config, keyframes: _keyframes);
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            // Drag handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.title, color: AppColors.textTrack, size: 22),
                          const SizedBox(width: 8),
                          Text('Text & Motion Titles', style: AppTypography.titleLarge),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                        onPressed: widget.onDone ?? () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Live Text Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                style: AppTypography.titleLarge.copyWith(fontSize: 18),
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(text: val));
                  _applyChange();
                },
                decoration: const InputDecoration(
                  hintText: 'Enter title text...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Presets'),
                Tab(text: 'Style & Font'),
                Tab(text: 'Curve & Glow'),
                Tab(text: 'Animation'),
                Tab(text: 'Position'),
                Tab(text: 'Keyframes'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildStyleTab(),
                _buildCurveAndGlowTab(),
                _buildAnimationTab(),
                _buildPositionTab(),
                _buildKeyframesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    final categories = ['All', 'Classic', 'Strokes', 'Badges', 'Shadows', 'Neon Glow'];
    final filtered = _selectedPresetCategory == 'All'
        ? TextPresetStyle.presets
        : TextPresetStyle.presets.where((p) => p.category == _selectedPresetCategory).toList();

    return Column(
      children: [
        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: categories.map((cat) {
              final isSel = _selectedPresetCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPresetCategory = cat);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Grid of Presets
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final preset = filtered[index];
              final isApplied = _config.textColor == preset.fillColor &&
                  _config.strokeColor == preset.strokeColor &&
                  _config.backgroundColor == preset.backgroundColor &&
                  _config.glowColor == preset.glowColor;

              return InkWell(
                onTap: () {
                  setState(() => _config = preset.applyTo(_config));
                  _applyChange();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isApplied ? AppColors.primary : AppColors.border,
                      width: isApplied ? 2.0 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // Visual Preview Box
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: preset.backgroundColor != null ? Color(preset.backgroundColor!) : Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (preset.strokeWidth > 0.0 && preset.strokeColor != null)
                              Text(
                                'Aa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = preset.strokeWidth
                                    ..color = Color(preset.strokeColor!),
                                ),
                              ),
                            Text(
                              'Aa',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(preset.fillColor),
                                shadows: [
                                  if (preset.glowColor != null)
                                    Shadow(
                                      color: Color(preset.glowColor!),
                                      blurRadius: 8,
                                    ),
                                  if (preset.shadowColor != null)
                                    Shadow(
                                      color: Color(preset.shadowColor!),
                                      blurRadius: preset.shadowBlur,
                                      offset: Offset(preset.shadowOffsetX, preset.shadowOffsetY),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Preset Name & Category
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              preset.category,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStyleTab() {
    final fonts = ['Inter', 'BebasNeue', 'JetBrainsMono', 'Montserrat', 'Pacifico'];
    final colors = [0xFFFFFFFF, 0xFFFFEAA7, 0xFF00CEC9, 0xFF6C5CE7, 0xFFFF7675, 0xFF55E6C1, 0xFFFD79A8];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Font Family
        Text('Font Family', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: fonts.map((f) {
            final isSelected = _config.fontFamily == f;
            return ChoiceChip(
              label: Text(f),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _config = _config.copyWith(fontFamily: f));
                  _applyChange();
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Font Size
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Font Size', style: AppTypography.titleMedium),
            Text('${_config.fontSize.toInt()} px', style: AppTypography.timecode.copyWith(color: AppColors.accent, fontSize: 12)),
          ],
        ),
        Slider(
          value: _config.fontSize,
          min: 14.0,
          max: 64.0,
          divisions: 50,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(fontSize: val));
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // Text Colors
        Text('Text Color', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: colors.map((colHex) {
            final isSelected = _config.textColor == colHex;
            final color = Color(colHex);

            return InkWell(
              onTap: () {
                setState(() => _config = _config.copyWith(textColor: colHex));
                _applyChange();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurveAndGlowTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // 1. Curved Text Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gesture, color: AppColors.primaryLight, size: 20),
                      const SizedBox(width: 8),
                      Text('Curved Text Arc', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${_config.curveAngle.toStringAsFixed(0)}°',
                    style: AppTypography.timecode.copyWith(color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _config.curveAngle == 0.0
                    ? 'Flat (Straight Line)'
                    : _config.curveAngle > 0
                        ? 'Convex Arc (Arch Dome Upwards)'
                        : 'Concave Arc (Smile Valley Downwards)',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _config.curveAngle,
                min: -180.0,
                max: 180.0,
                divisions: 72,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(curveAngle: val));
                  _applyChange();
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Flat 0°'),
                    onPressed: () {
                      setState(() => _config = _config.copyWith(curveAngle: 0.0));
                      _applyChange();
                    },
                  ),
                  ActionChip(
                    label: const Text('Arch +45°'),
                    onPressed: () {
                      setState(() => _config = _config.copyWith(curveAngle: 45.0));
                      _applyChange();
                    },
                  ),
                  ActionChip(
                    label: const Text('Dome +90°'),
                    onPressed: () {
                      setState(() => _config = _config.copyWith(curveAngle: 90.0));
                      _applyChange();
                    },
                  ),
                  ActionChip(
                    label: const Text('Smile -45°'),
                    onPressed: () {
                      setState(() => _config = _config.copyWith(curveAngle: -45.0));
                      _applyChange();
                    },
                  ),
                  ActionChip(
                    label: const Text('Valley -90°'),
                    onPressed: () {
                      setState(() => _config = _config.copyWith(curveAngle: -90.0));
                      _applyChange();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Outer Glow / Neon Aura Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flare, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text('Neon Glow & Outer Halo', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_config.glowRadius > 0)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                      tooltip: 'Clear Glow',
                      onPressed: () {
                        setState(() => _config = _config.copyWith(glowColor: null, glowRadius: 0.0, glowIntensity: 0.0));
                        _applyChange();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Glow Colors
              const Text('Halo Color', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  0xFFFF0855, // Crimson Red
                  0xFFFFDC00, // Solar Yellow
                  0xFF00E200, // Cyber Green
                  0xFF00F0FF, // Cyan Aqua
                  0xFFBD00FF, // Electric Purple
                  0xFFFF7100, // Sunset Orange
                  0xFFFFFFFF, // Pure White
                ].map((colorHex) {
                  final isSelected = _config.glowColor == colorHex && _config.glowRadius > 0;
                  return InkWell(
                    onTap: () {
                      setState(() => _config = _config.copyWith(
                            glowColor: colorHex,
                            glowRadius: _config.glowRadius == 0 ? 16.0 : _config.glowRadius,
                            glowIntensity: _config.glowIntensity == 0 ? 0.9 : _config.glowIntensity,
                          ));
                      _applyChange();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorHex),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(colorHex).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Glow Radius
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Glow Spread / Radius', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${_config.glowRadius.toInt()} pt', style: AppTypography.timecode.copyWith(fontSize: 12)),
                ],
              ),
              Slider(
                value: _config.glowRadius,
                min: 0.0,
                max: 30.0,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.border,
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(
                        glowRadius: val,
                        glowColor: _config.glowColor ?? 0xFF00F0FF,
                        glowIntensity: _config.glowIntensity == 0 ? 0.9 : _config.glowIntensity,
                      ));
                  _applyChange();
                },
              ),

              // Glow Intensity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Glow Intensity / Opacity', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${(_config.glowIntensity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12)),
                ],
              ),
              Slider(
                value: _config.glowIntensity,
                min: 0.0,
                max: 1.0,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.border,
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(
                        glowIntensity: val,
                        glowColor: _config.glowColor ?? 0xFF00F0FF,
                        glowRadius: _config.glowRadius == 0 ? 16.0 : _config.glowRadius,
                      ));
                  _applyChange();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: TextAnimationType.values.map((anim) {
        final isSelected = _config.animationType == anim;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() => _config = _config.copyWith(animationType: anim));
              _applyChange();
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.motion_photos_on, color: isSelected ? Colors.white : AppColors.primaryLight, size: 20),
            ),
            title: Text(anim.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPositionTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Horizontal Position X
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Horizontal Position (X)', style: TextStyle(fontSize: 13)),
            Text('${(_config.positionX * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.positionX,
          min: 0.05,
          max: 0.95,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(positionX: val));
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // Vertical Position Y
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Vertical Position (Y)', style: TextStyle(fontSize: 13)),
            Text('${(_config.positionY * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.positionY,
          min: 0.05,
          max: 0.95,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(positionY: val));
            _applyChange();
          },
        ),

        const SizedBox(height: 12),

        // Scale
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scale Multiplier', style: TextStyle(fontSize: 13)),
            Text('${_config.scale.toStringAsFixed(1)}x', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.scale,
          min: 0.5,
          max: 3.0,
          activeColor: AppColors.primaryLight,
          inactiveColor: AppColors.surfaceElevated,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(scale: val));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildKeyframesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Header & Quick Add Buttons
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Motion Path Keyframes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Add keyframe points to dynamically animate position, scale, and opacity over time.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                      label: const Text('Start (0s)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addKeyframeAt(0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                      label: const Text('Midpoint', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addKeyframeAt(widget.clip.durationMs ~/ 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accent),
                      label: const Text('End', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addKeyframeAt(widget.clip.durationMs),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_keyframes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.timeline, size: 40, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  const Text('No keyframes added yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Tap a button above to add an animation keyframe', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          )
        else
          for (int i = 0; i < _keyframes.length; i++)
            _buildKeyframeCard(i, _keyframes[i]),
      ],
    );
  }

  void _addKeyframeAt(int timeMs) {
    setState(() {
      _keyframes.removeWhere((k) => (k.timeOffsetMs - timeMs).abs() < 50);
      _keyframes.add(Keyframe(
        timeOffsetMs: timeMs,
        positionX: _config.positionX,
        positionY: _config.positionY,
        scale: _config.scale,
        opacity: 1.0,
      ));
      _keyframes.sort((a, b) => a.timeOffsetMs.compareTo(b.timeOffsetMs));
    });
    _applyChange();
  }

  Widget _buildKeyframeCard(int index, Keyframe kf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('Keyframe #${index + 1} @ ${(kf.timeOffsetMs / 1000.0).toStringAsFixed(2)}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () {
                  setState(() => _keyframes.removeAt(index));
                  _applyChange();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // X & Y
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('X: ${(kf.positionX * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Slider(
                      value: kf.positionX,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        setState(() => _keyframes[index] = kf.copyWith(positionX: v));
                        _applyChange();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Y: ${(kf.positionY * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Slider(
                      value: kf.positionY,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        setState(() => _keyframes[index] = kf.copyWith(positionY: v));
                        _applyChange();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Scale & Opacity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scale: ${kf.scale.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Slider(
                      value: kf.scale,
                      min: 0.5,
                      max: 3.0,
                      activeColor: AppColors.accent,
                      onChanged: (v) {
                        setState(() => _keyframes[index] = kf.copyWith(scale: v));
                        _applyChange();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opacity: ${(kf.opacity * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Slider(
                      value: kf.opacity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppColors.accent,
                      onChanged: (v) {
                        setState(() => _keyframes[index] = kf.copyWith(opacity: v));
                        _applyChange();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
