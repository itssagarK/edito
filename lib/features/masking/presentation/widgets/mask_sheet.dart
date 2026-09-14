import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/mask_config.dart';

class MaskSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback? onDone;

  const MaskSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip, {bool applyToAll}) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaskSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<MaskSheet> createState() => _MaskSheetState();
}

class _MaskSheetState extends State<MaskSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MaskConfig _config;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.mask;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateConfig(MaskConfig newConfig) {
    setState(() => _config = newConfig);
    final updated = widget.clip.copyWith(mask: _config);
    widget.onSave(updated, applyToAll: _applyToAll);
  }

  void _reset() {
    _updateConfig(const MaskConfig());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          _buildHeader(),

          // Shape Selector Carousel
          _buildShapeSelector(),

          // Tab Bar (Presets, Adjust, Transform)
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.captionBold,
            tabs: const [
              Tab(text: 'PRESETS'),
              Tab(text: 'ADJUST'),
              Tab(text: 'TRANSFORM'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildAdjustTab(),
                _buildTransformTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.masks, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masking Studio', style: AppTypography.bodyBold),
                  Text(
                    _config.isActive
                        ? '${_config.type.name.toUpperCase()} ${_config.inverted ? "(INVERTED)" : ""}'
                        : 'NO MASK APPLIED',
                    style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Invert Quick Toggle
              IconButton(
                icon: Icon(
                  _config.inverted ? Icons.invert_colors : Icons.invert_colors_off,
                  color: _config.inverted ? AppColors.accent : AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: 'Invert Mask',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: _config.inverted
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                onPressed: _config.isActive
                    ? () => _updateConfig(_config.copyWith(inverted: !_config.inverted))
                    : null,
              ),
              // Reset Button
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
                tooltip: 'Reset',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                onPressed: _config.isActive ? _reset : null,
              ),
              // Done Button
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
                tooltip: 'Apply',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                onPressed: () {
                  widget.onDone?.call();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeSelector() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildShapeChip(MaskType.none, 'None', Icons.block),
          _buildShapeChip(MaskType.linear, 'Linear', Icons.splitscreen),
          _buildShapeChip(MaskType.radial, 'Radial', Icons.circle_outlined),
          _buildShapeChip(MaskType.rectangle, 'Rectangle', Icons.crop_square),
          _buildShapeChip(MaskType.filmStrip, 'Film Strip', Icons.movie_creation_outlined),
          _buildShapeChip(MaskType.heart, 'Heart', Icons.favorite_border),
          _buildShapeChip(MaskType.star, 'Star', Icons.star_border),
        ],
      ),
    );
  }

  Widget _buildShapeChip(MaskType type, String label, IconData icon) {
    final bool isSelected = _config.type == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: isSelected,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.surface,
        onSelected: (selected) {
          if (selected) {
            _updateConfig(_config.copyWith(
              type: type,
              // sensible defaults when switching from none
              width: _config.width == 0 ? 0.6 : _config.width,
              height: _config.height == 0 ? 0.6 : _config.height,
            ));
          }
        },
      ),
    );
  }

  Widget _buildPresetsTab() {
    final presets = [
      {'preset': MaskPreset.splitHorizontal, 'title': 'Split Horizontal', 'icon': Icons.horizontal_split, 'desc': 'Side-by-side or clone reveal'},
      {'preset': MaskPreset.splitVertical, 'title': 'Split Vertical', 'icon': Icons.vertical_split, 'desc': 'Top & bottom split screen'},
      {'preset': MaskPreset.spotlightCircle, 'title': 'Spotlight Circle', 'icon': Icons.circle, 'desc': 'Smooth feathered circular focus'},
      {'preset': MaskPreset.roundedCard, 'title': 'Rounded Card', 'icon': Icons.rounded_corner, 'desc': 'Floating modern video card'},
      {'preset': MaskPreset.cinematicLetterbox, 'title': 'Letterbox Cutout', 'icon': Icons.crop_16_9, 'desc': '2.39:1 widescreen matte'},
      {'preset': MaskPreset.dreamyHeart, 'title': 'Dreamy Heart', 'icon': Icons.favorite, 'desc': 'Romantic feathered heart cutout'},
      {'preset': MaskPreset.popStar, 'title': 'Pop Star', 'icon': Icons.star, 'desc': 'Dynamic 5-point star mask'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Presets Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: presets.length,
          itemBuilder: (context, i) {
            final item = presets[i];
            final preset = item['preset'] as MaskPreset;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _updateConfig(MaskConfig.fromPreset(preset));
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: AppTypography.captionBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item['desc'] as String,
                            style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

        const SizedBox(height: 12),
        _buildApplyToAllTile(),
      ],
    );
  }

  Widget _buildAdjustTab() {
    if (!_config.isActive) {
      return const Center(
        child: Text('Select a mask shape above to adjust settings', style: AppTypography.caption),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Feather Softness Slider
        _buildSlider(
          label: 'Feather (Edge Softness)',
          value: _config.feather,
          min: 0.0,
          max: 1.0,
          valueDisplay: '${(_config.feather * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(feather: v)),
        ),

        // Corner Roundness (Only for Rectangle)
        if (_config.type == MaskType.rectangle)
          _buildSlider(
            label: 'Corner Roundness',
            value: _config.roundness,
            min: 0.0,
            max: 1.0,
            valueDisplay: '${(_config.roundness * 100).round()}%',
            onChanged: (v) => _updateConfig(_config.copyWith(roundness: v)),
          ),

        // Invert Mask Switch
        SwitchListTile(
          title: const Text('Invert Mask', style: AppTypography.captionBold),
          subtitle: Text(
            _config.inverted ? 'Showing outside of mask' : 'Showing inside of mask',
            style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
          ),
          value: _config.inverted,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => _updateConfig(_config.copyWith(inverted: v)),
        ),

        // Opacity Slider
        _buildSlider(
          label: 'Master Opacity',
          value: _config.opacity,
          min: 0.0,
          max: 1.0,
          valueDisplay: '${(_config.opacity * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(opacity: v)),
        ),

        const SizedBox(height: 8),
        _buildApplyToAllTile(),
      ],
    );
  }

  Widget _buildTransformTab() {
    if (!_config.isActive) {
      return const Center(
        child: Text('Select a mask shape above to adjust transforms', style: AppTypography.caption),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Width / Horizontal Scale
        _buildSlider(
          label: 'Width / Scale X',
          value: _config.width,
          min: 0.1,
          max: 1.5,
          valueDisplay: '${(_config.width * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(width: v)),
        ),

        // Height / Vertical Scale
        _buildSlider(
          label: 'Height / Scale Y',
          value: _config.height,
          min: 0.1,
          max: 1.5,
          valueDisplay: '${(_config.height * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(height: v)),
        ),

        // Rotation Angle
        _buildSlider(
          label: 'Rotation',
          value: _config.rotation,
          min: 0.0,
          max: 360.0,
          valueDisplay: '${_config.rotation.round()}°',
          onChanged: (v) => _updateConfig(_config.copyWith(rotation: v)),
        ),

        // Quick Rotation Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0.0, 45.0, 90.0, 180.0, 270.0].map((deg) {
            final bool isCurrent = (_config.rotation - deg).abs() < 1.0;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                side: BorderSide(color: isCurrent ? AppColors.accent : AppColors.border),
                backgroundColor: isCurrent ? AppColors.accent.withValues(alpha: 0.15) : null,
              ),
              onPressed: () => _updateConfig(_config.copyWith(rotation: deg)),
              child: Text('${deg.toInt()}°', style: AppTypography.micro),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        // Position Center X & Y
        _buildSlider(
          label: 'Center X',
          value: _config.centerX,
          min: 0.0,
          max: 1.0,
          valueDisplay: '${(_config.centerX * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(centerX: v)),
        ),
        _buildSlider(
          label: 'Center Y',
          value: _config.centerY,
          min: 0.0,
          max: 1.0,
          valueDisplay: '${(_config.centerY * 100).round()}%',
          onChanged: (v) => _updateConfig(_config.copyWith(centerY: v)),
        ),

        const SizedBox(height: 8),
        _buildApplyToAllTile(),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueDisplay,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption),
            Text(valueDisplay, style: AppTypography.captionBold.copyWith(color: AppColors.accent)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            inactiveTrackColor: AppColors.surface,
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildApplyToAllTile() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: CheckboxListTile(
        title: const Text('Apply mask to all clips', style: AppTypography.captionBold),
        subtitle: Text(
          'Applies current mask configuration to all video clips in project',
          style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
        ),
        value: _applyToAll,
        activeColor: AppColors.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onChanged: (val) {
          setState(() => _applyToAll = val ?? false);
          final updated = widget.clip.copyWith(mask: _config);
          widget.onSave(updated, applyToAll: _applyToAll);
        },
      ),
    );
  }
}
