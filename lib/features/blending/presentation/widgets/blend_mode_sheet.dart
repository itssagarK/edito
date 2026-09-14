import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/blend_mode_config.dart';

class BlendModeSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback? onDone;

  const BlendModeSheet({
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
      builder: (context) => BlendModeSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<BlendModeSheet> createState() => _BlendModeSheetState();
}

class _BlendModeSheetState extends State<BlendModeSheet> with SingleTickerProviderStateMixin {
  late BlendModeConfig _config;
  bool _applyToAll = false;
  BlendModeCategory _selectedCategory = BlendModeCategory.standard;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.blendMode;
    _selectedCategory = _config.mode.category;
  }

  void _updateConfig(BlendModeConfig newConfig) {
    setState(() => _config = newConfig);
    final updated = widget.clip.copyWith(blendMode: _config);
    widget.onSave(updated, applyToAll: _applyToAll);
  }

  void _reset() {
    _updateConfig(const BlendModeConfig());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
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

          // Opacity Slider
          _buildOpacitySlider(),

          // Category Chips Carousel
          _buildCategoryFilter(),

          // Blend Mode Grid
          Expanded(
            child: _buildModesList(),
          ),

          // Presets Carousel & Apply to all
          _buildFooterSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                child: const Icon(Icons.layers, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pro Blending Modes', style: AppTypography.bodyBold),
                  Text(
                    '${_config.mode.label.toUpperCase()} (${(_config.opacity * 100).round()}%)',
                    style: AppTypography.micro.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Reset Button
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
                tooltip: 'Reset to Normal',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
                onPressed: _config.isEnabled ? _reset : null,
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

  Widget _buildOpacitySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.opacity, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Opacity: ${(_config.opacity * 100).round()}%',
            style: AppTypography.captionBold,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                thumbColor: AppColors.accent,
                inactiveTrackColor: AppColors.surface,
                trackHeight: 3,
              ),
              child: Slider(
                value: _config.opacity.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (v) => _updateConfig(_config.copyWith(opacity: v)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'cat': BlendModeCategory.standard, 'label': 'Standard'},
      {'cat': BlendModeCategory.lighten, 'label': 'Lighten (Screen)'},
      {'cat': BlendModeCategory.darken, 'label': 'Darken (Multiply)'},
      {'cat': BlendModeCategory.contrast, 'label': 'Contrast (Overlay)'},
      {'cat': BlendModeCategory.inversion, 'label': 'Inversion (FX)'},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = categories[i];
          final cat = item['cat'] as BlendModeCategory;
          final isSelected = _selectedCategory == cat;

          return ChoiceChip(
            selected: isSelected,
            label: Text(item['label'] as String),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.surface,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = cat);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildModesList() {
    final modes = ProBlendMode.values.where((m) {
      if (_selectedCategory == BlendModeCategory.standard) return true;
      return m.category == _selectedCategory;
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 8,
      ),
      itemCount: modes.length,
      itemBuilder: (context, i) {
        final mode = modes[i];
        final isSelected = _config.mode == mode;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _updateConfig(_config.copyWith(mode: mode)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mode.label,
                      style: AppTypography.captionBold.copyWith(
                        color: isSelected ? AppColors.accent : Colors.white,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, size: 14, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  mode.description,
                  style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterSection() {
    final presets = [
      {'preset': BlendModePreset.lightLeak, 'title': 'Light Leak (Screen 85%)', 'icon': Icons.wb_sunny_outlined},
      {'preset': BlendModePreset.shadowTexture, 'title': 'Shadows (Multiply 75%)', 'icon': Icons.texture},
      {'preset': BlendModePreset.cinematicVibe, 'title': 'Cinematic (Overlay 80%)', 'icon': Icons.movie_filter_outlined},
      {'preset': BlendModePreset.subtleGlow, 'title': 'Soft Glow (SoftLight 90%)', 'icon': Icons.blur_on},
      {'preset': BlendModePreset.magicEnergy, 'title': 'Magic Energy (Dodge 70%)', 'icon': Icons.bolt},
      {'preset': BlendModePreset.psychedelicX, 'title': 'Psychedelic (Diff 100%)', 'icon': Icons.auto_awesome},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One-Tap Presets Carousel
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final item = presets[i];
                final preset = item['preset'] as BlendModePreset;
                return ActionChip(
                  avatar: Icon(item['icon'] as IconData, size: 14, color: AppColors.accent),
                  label: Text(item['title'] as String, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.cardBackground,
                  onPressed: () {
                    final cfg = BlendModeConfig.fromPreset(preset);
                    _updateConfig(cfg);
                    setState(() => _selectedCategory = cfg.mode.category);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Apply to all toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Apply blend mode to all project clips',
                style: AppTypography.micro.copyWith(color: AppColors.textSecondary),
              ),
              Switch(
                value: _applyToAll,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  setState(() => _applyToAll = v);
                  final updated = widget.clip.copyWith(blendMode: _config);
                  widget.onSave(updated, applyToAll: _applyToAll);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
