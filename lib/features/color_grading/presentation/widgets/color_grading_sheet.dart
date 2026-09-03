import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/color_grading_config.dart';
import 'tone_curve_editor.dart';

class ColorGradingSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const ColorGradingSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorGradingSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<ColorGradingSheet> createState() => _ColorGradingSheetState();
}

class _ColorGradingSheetState extends State<ColorGradingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ColorGradingConfig _config;
  String _selectedHslColor = 'red';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _config = widget.clip.colorGrading;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(colorGrading: _config);
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
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
                        const Icon(Icons.palette_outlined, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Color Presets & Grading', style: AppTypography.titleLarge),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 20),
                          tooltip: 'Reset Colors',
                          onPressed: () {
                            setState(() => _config = const ColorGradingConfig());
                            _applyChange();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
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
                Tab(text: 'Basic'),
                Tab(text: 'Color Looks'),
                Tab(text: 'HSL'),
                Tab(text: 'Curves'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicAdjustmentsTab(),
                _buildLutPresetsTab(),
                _buildHslTab(),
                _buildCurvesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicAdjustmentsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _buildSlider(
          label: 'Exposure',
          value: _config.exposure,
          min: -2.0,
          max: 2.0,
          displayValue: '${_config.exposure > 0 ? '+' : ''}${_config.exposure.toStringAsFixed(1)} EV',
          onChanged: (v) {
            setState(() => _config = _config.copyWith(exposure: v));
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Contrast',
          value: _config.contrast,
          min: 0.5,
          max: 1.5,
          displayValue: '${(_config.contrast * 100).toInt()}%',
          onChanged: (v) {
            setState(() => _config = _config.copyWith(contrast: v));
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Saturation',
          value: _config.saturation,
          min: 0.0,
          max: 2.0,
          displayValue: '${(_config.saturation * 100).toInt()}%',
          onChanged: (v) {
            setState(() => _config = _config.copyWith(saturation: v));
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Temperature (Cool ↔ Warm)',
          value: _config.temperature,
          min: -100.0,
          max: 100.0,
          displayValue: '${_config.temperature.toInt()}',
          activeColor: _config.temperature > 0 ? AppColors.accentGold : AppColors.accent,
          onChanged: (v) {
            setState(() => _config = _config.copyWith(temperature: v));
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Tint (Green ↔ Magenta)',
          value: _config.tint,
          min: -100.0,
          max: 100.0,
          displayValue: '${_config.tint.toInt()}',
          onChanged: (v) {
            setState(() => _config = _config.copyWith(tint: v));
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Vignette',
          value: _config.vignette,
          min: 0.0,
          max: 1.0,
          displayValue: '${(_config.vignette * 100).toInt()}%',
          onChanged: (v) {
            setState(() => _config = _config.copyWith(vignette: v));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildLutPresetsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Intensity Slider
        if (_config.activeLut != LutPreset.none) ...[
          _buildSlider(
            label: 'LUT Blend Intensity',
            value: _config.lutIntensity,
            min: 0.0,
            max: 1.0,
            displayValue: '${(_config.lutIntensity * 100).toInt()}%',
            onChanged: (v) {
              setState(() => _config = _config.copyWith(lutIntensity: v));
              _applyChange();
            },
          ),
          const SizedBox(height: 12),
        ],

        // Presets Grid
        ...LutPreset.values.map((preset) {
          final isSelected = _config.activeLut == preset;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () {
                setState(() => _config = _config.copyWith(activeLut: preset));
                _applyChange();
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  preset == LutPreset.none ? Icons.block : Icons.auto_awesome,
                  color: isSelected ? Colors.white : AppColors.primaryLight,
                  size: 20,
                ),
              ),
              title: Text(preset.label, style: AppTypography.titleMedium),
              subtitle: Text(preset.description, style: AppTypography.labelSmall),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.accent, size: 22)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHslTab() {
    final colors = ['red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple', 'magenta'];
    final colorMap = {
      'red': Colors.red,
      'orange': Colors.orange,
      'yellow': Colors.amber,
      'green': Colors.green,
      'cyan': Colors.cyan,
      'blue': Colors.blue,
      'purple': Colors.purple,
      'magenta': Colors.pink,
    };

    final currentHsl = _config.hsl[_selectedHslColor] ?? const HslShift();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Color Picker Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((col) {
            final isSelected = _selectedHslColor == col;
            final dotColor = colorMap[col]!;

            return ChoiceChip(
              avatar: CircleAvatar(backgroundColor: dotColor, radius: 6),
              label: Text(col.toUpperCase()),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedHslColor = col);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Hue Slider
        _buildSlider(
          label: '${_selectedHslColor.toUpperCase()} Hue Shift',
          value: currentHsl.hue,
          min: -180.0,
          max: 180.0,
          displayValue: '${currentHsl.hue.toInt()}°',
          onChanged: (v) {
            final updatedHsl = Map<String, HslShift>.from(_config.hsl);
            updatedHsl[_selectedHslColor] = currentHsl.copyWith(hue: v);
            setState(() => _config = _config.copyWith(hsl: updatedHsl));
            _applyChange();
          },
        ),

        // Saturation Slider
        _buildSlider(
          label: '${_selectedHslColor.toUpperCase()} Saturation',
          value: currentHsl.saturation,
          min: -1.0,
          max: 1.0,
          displayValue: '${(currentHsl.saturation * 100).toInt()}%',
          onChanged: (v) {
            final updatedHsl = Map<String, HslShift>.from(_config.hsl);
            updatedHsl[_selectedHslColor] = currentHsl.copyWith(saturation: v);
            setState(() => _config = _config.copyWith(hsl: updatedHsl));
            _applyChange();
          },
        ),

        // Luminance Slider
        _buildSlider(
          label: '${_selectedHslColor.toUpperCase()} Luminance',
          value: currentHsl.luminance,
          min: -1.0,
          max: 1.0,
          displayValue: '${(currentHsl.luminance * 100).toInt()}%',
          onChanged: (v) {
            final updatedHsl = Map<String, HslShift>.from(_config.hsl);
            updatedHsl[_selectedHslColor] = currentHsl.copyWith(luminance: v);
            setState(() => _config = _config.copyWith(hsl: updatedHsl));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildCurvesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Text('Master RGB Tone Curve', style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        Text('Drag points on the grid to shape contrast & shadows', style: AppTypography.bodyMedium),
        ToneCurveEditor(
          points: _config.masterCurve,
          onPointsChanged: (newPoints) {
            setState(() => _config = _config.copyWith(masterCurve: newPoints));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    Color activeColor = AppColors.primary,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              Text(displayValue, style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: activeColor,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
