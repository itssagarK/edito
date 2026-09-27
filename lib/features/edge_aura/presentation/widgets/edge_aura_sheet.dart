import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/edge_aura_config.dart';
import '../../services/edge_aura_compiler_service.dart';

/// CapCut Pro Video Glow & Edge Aura Studio Interactive Bottom Sheet
class EdgeAuraSheet extends StatefulWidget {
  final EdgeAuraConfig initialConfig;
  final ValueChanged<EdgeAuraConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const EdgeAuraSheet({
    Key? key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  }) : super(key: key);

  @override
  State<EdgeAuraSheet> createState() => _EdgeAuraSheetState();
}

class _EdgeAuraSheetState extends State<EdgeAuraSheet> {
  late EdgeAuraConfig _config;
  EdgeAuraCategory _selectedCategory = EdgeAuraCategory.all;
  bool _isComparing = false;

  // Curated palette of neon aura colors
  static const List<int> _neonPalette = [
    0xFF00F0FF, // Electric Cyan
    0xFFFF007F, // Synthwave Pink
    0xFFFFD700, // Solar Gold
    0xFF39FF14, // Radioactive Green
    0xFFBD00FF, // Plasma Purple
    0xFFFF3D00, // Inferno Flame
    0xFF00FFCC, // Matrix Mint
    0xFFFFFFFF, // Pure Starlight
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    if (_config.style != EdgeGlowStyle.none) {
      _selectedCategory = _config.style.category;
    }
  }

  void _updateConfig(EdgeAuraConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onApply(newConfig);
  }

  void _selectStyle(EdgeGlowStyle style) {
    if (style == EdgeGlowStyle.none) {
      _updateConfig(const EdgeAuraConfig());
    } else {
      _updateConfig(EdgeAuraConfig.preset(style));
    }
  }

  void _reset() {
    _updateConfig(const EdgeAuraConfig());
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = _isComparing ? const EdgeAuraConfig() : _config;

    return Container(
      key: const ValueKey('edge_aura_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildComparisonBanner(effectiveConfig),
                const SizedBox(height: 12),
                _buildCategoryChips(),
                const SizedBox(height: 12),
                _buildStyleCards(),
                const SizedBox(height: 16),
                if (_config.isEnabled && _config.style != EdgeGlowStyle.none) ...[
                  _buildColorPalette(),
                  const SizedBox(height: 16),
                  _buildBlendModeChips(),
                  const SizedBox(height: 16),
                  _buildSlider(
                    key: const ValueKey('edge_aura_intensity_slider'),
                    label: 'Glow Intensity',
                    value: _config.intensity,
                    min: 0.1,
                    max: 2.0,
                    percent: true,
                    onChanged: (val) {
                      _updateConfig(_config.copyWith(intensity: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    key: const ValueKey('edge_aura_radius_slider'),
                    label: 'Aura Spread (Radius)',
                    value: _config.radius,
                    min: 2.0,
                    max: 45.0,
                    displayValue: '${_config.radius.round()} px',
                    onChanged: (val) {
                      _updateConfig(_config.copyWith(radius: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    key: const ValueKey('edge_aura_threshold_slider'),
                    label: 'Edge Sensitivity',
                    value: _config.threshold,
                    min: 0.05,
                    max: 0.85,
                    percent: true,
                    onChanged: (val) {
                      _updateConfig(_config.copyWith(threshold: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    key: const ValueKey('edge_aura_pulse_slider'),
                    label: 'Pulse Frequency',
                    value: _config.pulseSpeed,
                    min: 0.0,
                    max: 4.0,
                    displayValue: _config.pulseSpeed == 0.0
                        ? 'Static'
                        : '${_config.pulseSpeed.toStringAsFixed(1)} Hz',
                    onChanged: (val) {
                      _updateConfig(_config.copyWith(pulseSpeed: val));
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flare, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'CapCut Pro Video Glow & Edge Aura',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            key: const ValueKey('edge_aura_reset_button'),
            onPressed: _reset,
            child: Text(
              'Reset',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            key: const ValueKey('edge_aura_close_button'),
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
            onPressed: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBanner(EdgeAuraConfig effectiveConfig) {
    final hasAura = effectiveConfig.isEnabled && effectiveConfig.style != EdgeGlowStyle.none;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _isComparing ? Icons.visibility_off : Icons.auto_awesome,
            color: _isComparing ? Colors.amberAccent : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isComparing
                  ? 'Raw Video Bypass (Comparing)'
                  : hasAura
                      ? effectiveConfig.badge
                      : 'Standard Clean Video',
              style: AppTypography.caption.copyWith(
                color: _isComparing ? Colors.amberAccent : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            key: const ValueKey('edge_aura_hold_to_compare'),
            onTapDown: (_) {
              setState(() => _isComparing = true);
              widget.onApply(const EdgeAuraConfig());
            },
            onTapUp: (_) {
              setState(() => _isComparing = false);
              widget.onApply(_config);
            },
            onTapCancel: () {
              setState(() => _isComparing = false);
              widget.onApply(_config);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isComparing
                    ? Colors.amberAccent.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isComparing ? Colors.amberAccent : AppColors.primary,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 13,
                    color: _isComparing ? Colors.amberAccent : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hold Compare',
                    style: AppTypography.caption.copyWith(
                      color: _isComparing ? Colors.amberAccent : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: EdgeAuraCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat.label),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.25),
              backgroundColor: AppColors.cardBackground,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStyleCards() {
    final filteredStyles = EdgeGlowStyle.values.where((s) {
      if (_selectedCategory == EdgeAuraCategory.all) return true;
      return s.category == _selectedCategory;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filteredStyles.map((style) {
          final isSelected = _config.isEnabled && _config.style == style;
          final color = Color(style.defaultColorValue);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              key: ValueKey('edge_aura_style_${style.name}'),
              onTap: () => _selectStyle(style),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 82,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.20)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Icon(
                        style == EdgeGlowStyle.none ? Icons.block : Icons.flare,
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      style.label,
                      style: AppTypography.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aura Neon Tint',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _neonPalette.map((colVal) {
              final isSelected = _config.colorValue == colVal;
              final col = Color(colVal);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    _updateConfig(_config.copyWith(
                      colorValue: colVal,
                      style: _config.style == EdgeGlowStyle.none
                          ? EdgeGlowStyle.custom
                          : _config.style,
                    ));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: col.withOpacity(0.5),
                          blurRadius: isSelected ? 8 : 4,
                          spreadRadius: isSelected ? 1 : 0,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.black87)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBlendModeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glow Blend Composite',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: GlowBlendMode.values.map((bm) {
            final isSelected = _config.blendMode == bm;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(bm.label),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.25),
                backgroundColor: AppColors.cardBackground,
                labelStyle: AppTypography.caption.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (selected) {
                  if (selected) {
                    _updateConfig(_config.copyWith(blendMode: bm));
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlider({
    Key? key,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool percent = false,
    String? displayValue,
  }) {
    final text = displayValue ??
        (percent ? '${(value * 100).round()}%' : value.toStringAsFixed(2));

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          key: const ValueKey('edge_aura_apply_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () {
            widget.onApply(_config);
            if (!widget.isDocked) {
              Navigator.of(context).maybePop();
            }
          },
          child: Text(
            'Apply Glow & Aura',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
