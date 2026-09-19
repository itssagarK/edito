import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/smart_cutout_config.dart';
import '../../services/smart_cutout_compiler_service.dart';
import '../../../chroma/presentation/widgets/chroma_key_sheet.dart';

class SmartCutoutSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const SmartCutoutSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.15),
      backgroundColor: Colors.transparent,
      builder: (context) => SmartCutoutSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<SmartCutoutSheet> createState() => _SmartCutoutSheetState();
}

class _SmartCutoutSheetState extends State<SmartCutoutSheet> with SingleTickerProviderStateMixin {
  late SmartCutoutConfig _config;
  int _activeTab = 0; // 0: Auto Cutout, 1: Stroke Outline, 2: Background, 3: Chroma Key

  final List<Color> _strokePalette = const [
    Color(0xFF00E5FF), // Neon Cyan
    Color(0xFFFF007F), // Cyber Pink
    Color(0xFFFFD700), // Golden Aura
    Color(0xFF00FF66), // Matrix Green
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFFF5252), // Electric Red
    Color(0xFF7C4DFF), // Deep Violet
    Color(0xFFFF9100), // Sunset Amber
  ];

  final List<Color> _bgPalette = const [
    Color(0xFF121212), // Dark Charcoal
    Color(0xFF000000), // AMOLED Pure Black
    Color(0xFF1E293B), // Slate Blue
    Color(0xFF831843), // Deep Maroon
    Color(0xFF064E3B), // Emerald
    Color(0xFFFFFFFF), // Pure White
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.clip.smartCutout;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(smartCutout: _config);
    widget.onSave(updated);
  }

  void _applyPreset(SmartCutoutConfig preset) {
    setState(() {
      _config = preset;
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildTabs(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );

    if (widget.isDocked) return content;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: content,
    );
  }

  Widget _buildHeader() {
    final badge = SmartCutoutCompilerService.getCutoutBadge(_config);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFFFF007F)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.blur_linear, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart AI Cutout Studio',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  badge.isNotEmpty ? badge : 'One-tap portrait matting & glowing outlines',
                  style: AppTypography.caption.copyWith(
                    color: _config.isEnabled ? const Color(0xFF00E5FF) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFF00E5FF),
            onChanged: (val) {
              setState(() {
                _config = _config.copyWith(isEnabled: val);
              });
              _applyChange();
            },
          ),
          if (widget.onDone != null)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Color(0xFF00E5FF)),
              style: IconButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: widget.onDone,
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Auto Cutout', 'Stroke Outline', 'Background', 'Chroma Key'];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight.withOpacity(0.1))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _activeTab == index;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                style: AppTypography.caption.copyWith(
                  color: isSelected ? const Color(0xFF00E5FF) : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildAutoCutoutTab();
      case 1:
        return _buildStrokeTab();
      case 2:
        return _buildBackgroundTab();
      case 3:
        return _buildChromaKeyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAutoCutoutTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAPCUT PRO PRESETS', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip('⚡ Neon Cyan', SmartCutoutConfig.presetNeonCyan),
            _buildPresetChip('💖 Cyber Pink', SmartCutoutConfig.presetCyberPink),
            _buildPresetChip('✨ Golden Aura', SmartCutoutConfig.presetGoldenAura),
            _buildPresetChip('🟢 Matrix Green', SmartCutoutConfig.presetMatrixGreen),
            _buildPresetChip('🏷️ Sticker Border', SmartCutoutConfig.presetWhiteSticker),
            _buildPresetChip('🌫️ Portrait Bokeh', SmartCutoutConfig.presetPortraitBokeh),
            _buildPresetChip('🖤 Studio Dark', SmartCutoutConfig.presetStudioDark),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceLight.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Invert Cutout (Isolate Background)', style: AppTypography.bodySmall),
                  Switch(
                    value: _config.isInverted,
                    activeColor: const Color(0xFF00E5FF),
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(isInverted: val));
                      _applyChange();
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              _buildSlider(
                title: 'Edge Feather Softness',
                value: _config.edgeFeather,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(_config.edgeFeather * 100).toInt()}%',
                onChanged: (val) {
                  setState(() => _config = _config.copyWith(edgeFeather: val));
                  _applyChange();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, SmartCutoutConfig preset) {
    return ActionChip(
      backgroundColor: AppColors.surfaceDark,
      label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.surfaceLight.withOpacity(0.3)),
      ),
      onPressed: () => _applyPreset(preset),
    );
  }

  Widget _buildStrokeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STROKE STYLE', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CutoutStrokeStyle.values.map((style) {
              final isSelected = _config.strokeStyle == style;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(style.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00E5FF).withOpacity(0.25),
                  backgroundColor: AppColors.surfaceDark,
                  onSelected: (_) {
                    setState(() {
                      _config = _config.copyWith(
                        strokeStyle: style,
                        isEnabled: true,
                      );
                    });
                    _applyChange();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Text('COLOR PALETTE', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _strokePalette.map((color) {
            final isSelected = _config.strokeColorValue == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _config = _config.copyWith(
                    strokeColorValue: color.value,
                    isEnabled: true,
                  );
                });
                _applyChange();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          title: 'Stroke Width',
          value: _config.strokeWidth,
          min: 1.0,
          max: 20.0,
          divisions: 38,
          label: '${_config.strokeWidth.toStringAsFixed(1)} px',
          onChanged: (val) {
            setState(() => _config = _config.copyWith(strokeWidth: val));
            _applyChange();
          },
        ),
        _buildSlider(
          title: 'Glow Aura Spread',
          value: _config.glowSpread,
          min: 0.0,
          max: 30.0,
          divisions: 30,
          label: '${_config.glowSpread.toStringAsFixed(1)} px',
          onChanged: (val) {
            setState(() => _config = _config.copyWith(glowSpread: val));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BACKGROUND MODE', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Row(
          children: CutoutBackgroundMode.values.map((mode) {
            final isSelected = _config.backgroundMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mode.name.toUpperCase(), style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: const Color(0xFF00E5FF).withOpacity(0.25),
                backgroundColor: AppColors.surfaceDark,
                onSelected: (_) {
                  setState(() {
                    _config = _config.copyWith(
                      backgroundMode: mode,
                      isEnabled: true,
                    );
                  });
                  _applyChange();
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_config.backgroundMode == CutoutBackgroundMode.blur) ...[
          _buildSlider(
            title: 'Cinematic Bokeh Blur Radius',
            value: _config.backgroundBlur,
            min: 1.0,
            max: 30.0,
            divisions: 29,
            label: '${_config.backgroundBlur.toStringAsFixed(1)} px',
            onChanged: (val) {
              setState(() => _config = _config.copyWith(backgroundBlur: val));
              _applyChange();
            },
          ),
        ] else if (_config.backgroundMode == CutoutBackgroundMode.solidColor) ...[
          Text('BACKDROP COLOR', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _bgPalette.map((color) {
              final isSelected = _config.backgroundColorValue == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(
                      backgroundColorValue: color.value,
                      isEnabled: true,
                    );
                  });
                  _applyChange();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, color: Color(0xFF00E5FF), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Transparent mode preserves alpha so lower tracks and background layers show through seamlessly.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChromaKeyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRADITIONAL GREEN SCREEN KEYER', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                'Key out exact green or blue backdrops using multi-sample color similarity and spill suppression.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                  foregroundColor: const Color(0xFF00E5FF),
                ),
                icon: const Icon(Icons.colorize),
                label: const Text('Configure Chroma Key (Green Screen)'),
                onPressed: () {
                  ChromaKeySheet.show(
                    context,
                    clip: widget.clip,
                    onSave: widget.onSave,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.caption),
            Text(label, style: AppTypography.caption.copyWith(color: const Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00E5FF),
            inactiveTrackColor: AppColors.surfaceLight.withOpacity(0.3),
            thumbColor: const Color(0xFF00E5FF),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
