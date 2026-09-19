import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/color_grading_config.dart';
import 'color_scopes_widget.dart';
import 'color_wheel_widget.dart';
import 'tone_curve_editor.dart';

class ColorGradingSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ColorGradingSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip updatedClip, {bool applyToAll}) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.15),
      backgroundColor: Colors.transparent,
      builder: (context) => ColorGradingSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ColorGradingSheet> createState() => _ColorGradingSheetState();
}

class _ColorGradingSheetState extends State<ColorGradingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ColorGradingConfig _config;
  String _selectedHslColor = 'red';
  bool _applyToAll = false;
  int _selectedWheelIndex = 0; // 0: All 4, 1: Lift, 2: Gamma, 3: Gain, 4: Offset

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _config = widget.clip.colorGrading;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(colorGrading: _config);
    widget.onSave(updated, applyToAll: _applyToAll);
  }

  void _updateConfig(ColorGradingConfig Function(ColorGradingConfig) updater) {
    setState(() {
      _config = updater(_config);
    });
    _applyChange();
  }

  void _resetAll() {
    setState(() {
      _config = const ColorGradingConfig();
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.62;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, color: AppColors.accent, size: 22),
                          const SizedBox(width: 8),
                          Text('Pro Color Grading', style: AppTypography.titleLarge),
                        ],
                      ),
                      Row(
                        children: [
                          if (_config.isGraded)
                            TextButton(
                              onPressed: _resetAll,
                              child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                            onPressed: () {
                              _applyChange();
                              widget.onDone?.call();
                              Navigator.pop(context);
                            },
                            tooltip: 'Done',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.accent.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Real-time RGB Waveform Scopes Monitor
          ColorScopesWidget(config: _config),

          // Tab Bar: Looks | Wheels | Adjust | Curves | HSL
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome, size: 14), text: 'Looks'),
                Tab(icon: Icon(Icons.donut_large, size: 14), text: 'Wheels'),
                Tab(icon: Icon(Icons.tune, size: 14), text: 'Adjust'),
                Tab(icon: Icon(Icons.show_chart, size: 14), text: 'Curves'),
                Tab(icon: Icon(Icons.color_lens_outlined, size: 14), text: 'HSL'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLooksTab(),
                _buildColorWheelsTab(),
                _buildAdjustTab(),
                _buildCurvesTab(),
                _buildHslTab(),
              ],
            ),
          ),

          // Bottom Bar: Apply to All
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _applyToAll,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() => _applyToAll = val ?? false);
                        _applyChange();
                      },
                    ),
                    const Text('Apply grade to all clips', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Text(
                  _config.isGraded
                      ? (_config.activeLut != LutPreset.none
                          ? '${_config.activeLut.name.toUpperCase()} GRADED'
                          : 'PRO GRADED')
                      : 'ORIGINAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _config.isGraded ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOOKS (PRESETS) TAB ---
  Widget _buildLooksTab() {
    return Column(
      children: [
        if (_config.activeLut != LutPreset.none)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                const Text('LUT Intensity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                Expanded(
                  child: Slider(
                    value: _config.lutIntensity,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.accent,
                    onChanged: (val) => _updateConfig((c) => c.copyWith(lutIntensity: val)),
                  ),
                ),
                Text('${(_config.lutIntensity * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: LutPreset.values.length,
            itemBuilder: (context, index) {
              final preset = LutPreset.values[index];
              final isSelected = _config.activeLut == preset;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    preset.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppColors.accent : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    preset.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
                      : null,
                  onTap: () {
                    _updateConfig((c) => c.copyWith(activeLut: preset));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- 3-WAY COLOR WHEELS TAB ---
  Widget _buildColorWheelsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        // 1. Color Wheels Quick Presets Strip
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...ColorWheelsPreset.values.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(
                      preset.label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onPressed: () {
                      _updateConfig((c) => c.applyColorWheelsPreset(preset));
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Mode Selector: [ALL 4] [LIFT] [GAMMA] [GAIN] [OFFSET]
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildWheelModeButton(0, 'ALL 4', null),
              _buildWheelModeButton(1, 'LIFT', const Color(0xFF00E5FF)),
              _buildWheelModeButton(2, 'GAMMA', const Color(0xFFFFD700)),
              _buildWheelModeButton(3, 'GAIN', const Color(0xFFFF007F)),
              _buildWheelModeButton(4, 'OFFSET', AppColors.accent),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Wheel View: Single Focused Wheel or All 4 Grid
        if (_selectedWheelIndex == 0) ...[
          Row(
            children: [
              Expanded(
                child: ColorWheelWidget(
                  label: 'LIFT (SHADOWS)',
                  value: _config.lift,
                  accentColor: const Color(0xFF00E5FF),
                  onChanged: (val) => _updateConfig((c) => c.copyWith(lift: val)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ColorWheelWidget(
                  label: 'GAMMA (MIDS)',
                  value: _config.gamma,
                  accentColor: const Color(0xFFFFD700),
                  onChanged: (val) => _updateConfig((c) => c.copyWith(gamma: val)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ColorWheelWidget(
                  label: 'GAIN (HIGHLIGHTS)',
                  value: _config.gain,
                  accentColor: const Color(0xFFFF007F),
                  onChanged: (val) => _updateConfig((c) => c.copyWith(gain: val)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ColorWheelWidget(
                  label: 'OFFSET (GLOBAL)',
                  value: _config.offset,
                  accentColor: AppColors.accent,
                  onChanged: (val) => _updateConfig((c) => c.copyWith(offset: val)),
                ),
              ),
            ],
          ),
        ] else if (_selectedWheelIndex == 1) ...[
          ColorWheelWidget(
            label: 'LIFT (SHADOWS & BLACK LEVELS)',
            description: 'Tonal control for shadows, black pedestal, and dark values (0% - 25% Luminance). Double-tap to reset.',
            value: _config.lift,
            accentColor: const Color(0xFF00E5FF),
            size: 190.0,
            onChanged: (val) => _updateConfig((c) => c.copyWith(lift: val)),
          ),
        ] else if (_selectedWheelIndex == 2) ...[
          ColorWheelWidget(
            label: 'GAMMA (MIDTONES & SKIN TONES)',
            description: 'Controls midtones, skin tone warmth, and natural subject lighting (25% - 75% Luminance). Double-tap to reset.',
            value: _config.gamma,
            accentColor: const Color(0xFFFFD700),
            size: 190.0,
            onChanged: (val) => _updateConfig((c) => c.copyWith(gamma: val)),
          ),
        ] else if (_selectedWheelIndex == 3) ...[
          ColorWheelWidget(
            label: 'GAIN (HIGHLIGHTS & SPECULAR)',
            description: 'Controls specular highlights, sky warmth, and bright roll-off (75% - 100% Luminance). Double-tap to reset.',
            value: _config.gain,
            accentColor: const Color(0xFFFF007F),
            size: 190.0,
            onChanged: (val) => _updateConfig((c) => c.copyWith(gain: val)),
          ),
        ] else if (_selectedWheelIndex == 4) ...[
          ColorWheelWidget(
            label: 'OFFSET (GLOBAL MASTER PEDESTAL)',
            description: 'Uniform tonal shift across all color channels simultaneously. Double-tap to reset.',
            value: _config.offset,
            accentColor: AppColors.accent,
            size: 190.0,
            onChanged: (val) => _updateConfig((c) => c.copyWith(offset: val)),
          ),
        ],
      ],
    );
  }

  Widget _buildWheelModeButton(int index, String title, Color? indicatorColor) {
    final isSelected = _selectedWheelIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWheelIndex = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (indicatorColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PRO ADJUST TAB ---
  Widget _buildAdjustTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        _buildSliderRow(
          'Exposure',
          _config.exposure,
          -2.0,
          2.0,
          (val) => _updateConfig((c) => c.copyWith(exposure: val)),
          unit: 'EV',
        ),
        _buildSliderRow(
          'Contrast',
          _config.contrast,
          0.5,
          1.5,
          (val) => _updateConfig((c) => c.copyWith(contrast: val)),
        ),
        _buildSliderRow(
          'Saturation',
          _config.saturation,
          0.0,
          2.0,
          (val) => _updateConfig((c) => c.copyWith(saturation: val)),
        ),
        _buildSliderRow(
          'Temperature',
          _config.temperature,
          -100.0,
          100.0,
          (val) => _updateConfig((c) => c.copyWith(temperature: val)),
          unit: 'K',
        ),
        _buildSliderRow(
          'Tint',
          _config.tint,
          -100.0,
          100.0,
          (val) => _updateConfig((c) => c.copyWith(tint: val)),
        ),
        _buildSliderRow(
          'Highlights',
          _config.highlights,
          -1.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(highlights: val)),
        ),
        _buildSliderRow(
          'Shadows',
          _config.shadows,
          -1.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(shadows: val)),
        ),
        _buildSliderRow(
          'Whites',
          _config.whites,
          -1.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(whites: val)),
        ),
        _buildSliderRow(
          'Blacks',
          _config.blacks,
          -1.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(blacks: val)),
        ),
        _buildSliderRow(
          'Film Fade (Lifted Blacks)',
          _config.fade,
          0.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(fade: val)),
        ),
        _buildSliderRow(
          'Clarity (Midtone Contrast)',
          _config.clarity,
          0.5,
          1.5,
          (val) => _updateConfig((c) => c.copyWith(clarity: val)),
        ),
        _buildSliderRow(
          'Vignette',
          _config.vignette,
          0.0,
          1.0,
          (val) => _updateConfig((c) => c.copyWith(vignette: val)),
        ),
      ],
    );
  }

  // --- CURVES TAB ---
  Widget _buildCurvesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ToneCurveEditor(
            points: _config.masterCurve,
            onPointsChanged: (newPoints) {
              _updateConfig((c) => c.copyWith(masterCurve: newPoints));
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap on the graph to add control points. Drag to shape the S-curve response.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- HSL 8-CHANNEL TAB ---
  Widget _buildHslTab() {
    final colors = ['red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple', 'magenta'];
    final activeShift = _config.hsl[_selectedHslColor] ?? const HslShift();
    final bool hasChannelMod = activeShift.hue != 0.0 || activeShift.saturation != 0.0 || activeShift.luminance != 0.0;

    return Column(
      children: [
        // 1. Presets Carousel
        Container(
          height: 36,
          margin: const EdgeInsets.only(top: 6, bottom: 4),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _buildHslPresetChip('Reset All', Icons.restart_alt, () {
                _updateConfig((c) => c.copyWith(hsl: const {}));
              }, isReset: true),
              const SizedBox(width: 6),
              ...HslPreset.values.where((p) => p != HslPreset.none).map((preset) {
                final isCurrent = _isHslPresetActive(preset);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildHslPresetChip(
                    preset.label,
                    _getPresetIcon(preset),
                    () {
                      _updateConfig((c) => c.applyHslPreset(preset));
                    },
                    isActive: isCurrent,
                  ),
                );
              }),
            ],
          ),
        ),

        // 2. Color Selector Swatches (with active indicators)
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colorName = colors[index];
              final isSelected = _selectedHslColor == colorName;
              final color = _getHslColor(colorName);
              final shift = _config.hsl[colorName];
              final isModified = shift != null && (shift.hue != 0.0 || shift.saturation != 0.0 || shift.luminance != 0.0);

              return GestureDetector(
                onTap: () => setState(() => _selectedHslColor = colorName),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: painting.Clip.none,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        if (isModified)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getHslColorShortLabel(colorName),
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 3. Channel Control Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getHslColor(_selectedHslColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedHslColor.toUpperCase()} CHANNEL',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ],
              ),
              if (hasChannelMod)
                GestureDetector(
                  onTap: () {
                    final updated = Map<String, HslShift>.from(_config.hsl);
                    updated.remove(_selectedHslColor);
                    _updateConfig((c) => c.copyWith(hsl: updated));
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Reset Channel',
                      style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Divider(color: AppColors.border, height: 8),

        // 4. HSL Sliders
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            children: [
              _buildSliderRow(
                'Hue Shift',
                activeShift.hue,
                -180.0,
                180.0,
                (val) => _updateHslShift(activeShift.copyWith(hue: val)),
                unit: '°',
              ),
              _buildSliderRow(
                'Saturation',
                activeShift.saturation,
                -1.0,
                1.0,
                (val) => _updateHslShift(activeShift.copyWith(saturation: val)),
                isPercent: true,
              ),
              _buildSliderRow(
                'Luminance',
                activeShift.luminance,
                -1.0,
                1.0,
                (val) => _updateHslShift(activeShift.copyWith(luminance: val)),
                isPercent: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isHslPresetActive(HslPreset preset) {
    final expected = HslPreset.getPresetShifts(preset);
    if (expected.isEmpty && _config.hsl.isEmpty) return true;
    if (expected.isEmpty || _config.hsl.isEmpty) return false;
    for (final entry in expected.entries) {
      final actual = _config.hsl[entry.key];
      if (actual == null) return false;
      if ((actual.hue - entry.value.hue).abs() > 0.01) return false;
      if ((actual.saturation - entry.value.saturation).abs() > 0.01) return false;
      if ((actual.luminance - entry.value.luminance).abs() > 0.01) return false;
    }
    return true;
  }

  IconData _getPresetIcon(HslPreset preset) {
    switch (preset) {
      case HslPreset.none: return Icons.refresh;
      case HslPreset.selectiveRed: return Icons.colorize;
      case HslPreset.tealAndOrange: return Icons.movie_filter;
      case HslPreset.autumnGold: return Icons.park;
      case HslPreset.emeraldLush: return Icons.forest;
      case HslPreset.urbanDesat: return Icons.location_city;
    }
  }

  String _getHslColorShortLabel(String name) {
    switch (name) {
      case 'red': return 'Red';
      case 'orange': return 'Org';
      case 'yellow': return 'Yel';
      case 'green': return 'Grn';
      case 'cyan': return 'Cyn';
      case 'blue': return 'Blu';
      case 'purple': return 'Pur';
      case 'magenta': return 'Mag';
      default: return name;
    }
  }

  Widget _buildHslPresetChip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isActive = false,
    bool isReset = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withOpacity(0.22)
                : (isReset ? AppColors.surfaceElevated : AppColors.surfaceElevated.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.accent
                  : (isReset ? AppColors.border : AppColors.border.withOpacity(0.6)),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive ? AppColors.accent : (isReset ? AppColors.textMuted : Colors.white70),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppColors.accent : (isReset ? AppColors.textMuted : Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateHslShift(HslShift shift) {
    final updatedMap = Map<String, HslShift>.from(_config.hsl);
    updatedMap[_selectedHslColor] = shift;
    _updateConfig((c) => c.copyWith(hsl: updatedMap));
  }

  Color _getHslColor(String name) {
    switch (name) {
      case 'red': return const Color(0xFFFF2A2A);
      case 'orange': return const Color(0xFFFF8C00);
      case 'yellow': return const Color(0xFFFFD700);
      case 'green': return const Color(0xFF00FF66);
      case 'cyan': return const Color(0xFF00E5FF);
      case 'blue': return const Color(0xFF2979FF);
      case 'purple': return const Color(0xFF9C27B0);
      case 'magenta': return const Color(0xFFFF007F);
      default: return Colors.white;
    }
  }

  Widget _buildSliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String unit = '',
    bool isPercent = false,
  }) {
    final String valueText = isPercent
        ? '${(value * 100).round() >= 0 && min < 0 ? "+" : ""}${(value * 100).round()}%'
        : '${value >= 0 && min < 0 ? "+" : ""}${value.toStringAsFixed(1)}$unit';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.surfaceElevated,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
