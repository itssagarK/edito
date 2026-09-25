import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/denoise_config.dart';
import '../../services/denoise_compiler_service.dart';

/// CapCut Pro Video De-Noise & Low-Light Enhancement Studio Sheet
class DenoiseSheet extends StatefulWidget {
  final DenoiseConfig initialConfig;
  final ValueChanged<DenoiseConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;

  const DenoiseSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
  });

  @override
  State<DenoiseSheet> createState() => _DenoiseSheetState();
}

class _DenoiseSheetState extends State<DenoiseSheet> {
  late DenoiseConfig _config;
  bool _isComparing = false; // Hold to compare raw video

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(DenoiseConfig updated) {
    setState(() {
      _config = updated;
    });
    widget.onApply(updated);
  }

  void _reset() {
    const fresh = DenoiseConfig();
    _updateConfig(fresh);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = _isComparing ? const DenoiseConfig() : _config;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            _buildHeader(),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Level Selector Cards
                    _buildLevelSelector(),
                    const SizedBox(height: 12),

                    // Algorithm Selector Chips
                    _buildAlgorithmChips(),
                    const SizedBox(height: 12),

                    // Hold to Compare & Status Banner
                    _buildCompareBar(),
                    const SizedBox(height: 12),

                    // Low-Light Boost Slider
                    _buildSlider(
                      label: 'Low-Light Shadow Boost',
                      value: _config.lowLightBoost,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          lowLightBoost: val,
                        ));
                      },
                    ),

                    // Detail Recovery Sharpening Slider
                    _buildSlider(
                      label: 'Detail Recovery Sharpness',
                      value: _config.detailSharpening,
                      min: 0.0,
                      max: 1.5,
                      formatVal: '${(_config.detailSharpening * 100).toInt()}%',
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          detailSharpening: val,
                        ));
                      },
                    ),

                    // Custom Granular Sliders (when Custom mode is selected)
                    if (_config.level == DenoiseLevel.custom) ...[
                      const SizedBox(height: 6),
                      Text(
                        'MANUAL THRESHOLDS',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSlider(
                        label: 'Spatial Luma (Y)',
                        value: _config.spatialLuma,
                        min: 0.0,
                        max: 20.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(spatialLuma: val));
                        },
                      ),
                      _buildSlider(
                        label: 'Spatial Chroma (UV)',
                        value: _config.spatialChroma,
                        min: 0.0,
                        max: 20.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(spatialChroma: val));
                        },
                      ),
                      _buildSlider(
                        label: 'Temporal Luma (Y)',
                        value: _config.temporalLuma,
                        min: 0.0,
                        max: 30.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(temporalLuma: val));
                        },
                      ),
                      _buildSlider(
                        label: 'Temporal Chroma (UV)',
                        value: _config.temporalChroma,
                        min: 0.0,
                        max: 30.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(temporalChroma: val));
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
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
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2ED573).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.noise_control_off,
              color: Color(0xFF2ED573),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Video De-Noise',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ED573), Color(0xFF10AC84)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _config.isEnabled && _config.level != DenoiseLevel.none
                      ? '${_config.level.label} • 3D Spatio-temporal filtering'
                      : 'Disabled — Tap a level to clean grain & noise',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isEnabled && _config.level != DenoiseLevel.none
                        ? const Color(0xFF2ED573)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset button
          if (_config.isEnabled && _config.level != DenoiseLevel.none)
            TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Reset',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ),

          // Close button
          IconButton(
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.check, color: AppColors.textPrimary, size: 20),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DENOISE INTENSITY LEVEL',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DenoiseLevel.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final level = DenoiseLevel.values[index];
              final isSelected = _config.isEnabled && _config.level == level;

              return InkWell(
                onTap: () {
                  if (level == DenoiseLevel.none) {
                    _updateConfig(const DenoiseConfig());
                  } else {
                    _updateConfig(DenoiseConfig.fromLevel(level, lowLightBoost: _config.lowLightBoost));
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2ED573).withOpacity(0.12)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2ED573) : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getLevelIcon(level),
                        size: 20,
                        color: isSelected ? const Color(0xFF2ED573) : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        level.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? const Color(0xFF2ED573) : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        isSelected ? 'Active' : 'Pro Filter',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: isSelected ? const Color(0xFF2ED573) : AppColors.textMuted,
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

  Widget _buildAlgorithmChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DSP FILTER ENGINE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: DenoiseAlgorithm.values.map((algo) {
            final isSelected = _config.algorithm == algo;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    _updateConfig(_config.copyWith(
                      isEnabled: true,
                      level: _config.level == DenoiseLevel.none ? DenoiseLevel.balanced : _config.level,
                      algorithm: algo,
                    ));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2ED573) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2ED573) : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      algo.shortLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
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

  Widget _buildCompareBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: Color(0xFF2ED573), size: 16),
              const SizedBox(width: 8),
              Text(
                'Hold button to compare with raw grainy video',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          GestureDetector(
            onTapDown: (_) {
              setState(() => _isComparing = true);
              widget.onApply(const DenoiseConfig());
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isComparing ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _isComparing ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: _isComparing ? const Color(0xFF2ED573) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isComparing ? 'Raw' : 'Compare',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isComparing ? const Color(0xFF2ED573) : AppColors.textSecondary,
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

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool percent = false,
    String? formatVal,
  }) {
    final displayValue = formatVal ?? (percent ? '${(value * 100).toInt()}%' : value.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                displayValue,
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF2ED573),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF2ED573),
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
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
      ),
    );
  }

  IconData _getLevelIcon(DenoiseLevel level) {
    switch (level) {
      case DenoiseLevel.none:
        return Icons.power_settings_new;
      case DenoiseLevel.mild:
        return Icons.filter_1;
      case DenoiseLevel.balanced:
        return Icons.auto_awesome;
      case DenoiseLevel.lowLightNight:
        return Icons.nightlight_round;
      case DenoiseLevel.ultraClean:
        return Icons.cleaning_services;
      case DenoiseLevel.custom:
        return Icons.tune;
    }
  }
}
