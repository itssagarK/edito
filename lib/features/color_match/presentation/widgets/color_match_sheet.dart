import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/color_match_config.dart';
import '../../services/color_match_compiler_service.dart';

/// CapCut Pro AI Color Match & Tone Palette Transfer Studio Sheet
class ColorMatchSheet extends StatefulWidget {
  final ColorMatchConfig initialConfig;
  final ValueChanged<ColorMatchConfig> onApply;
  final VoidCallback? onClose;
  final bool isDocked;
  final List<Clip> availableReferenceClips;

  const ColorMatchSheet({
    super.key,
    required this.initialConfig,
    required this.onApply,
    this.onClose,
    this.isDocked = false,
    this.availableReferenceClips = const [],
  });

  @override
  State<ColorMatchSheet> createState() => _ColorMatchSheetState();
}

class _ColorMatchSheetState extends State<ColorMatchSheet> {
  late ColorMatchConfig _config;
  bool _isComparing = false; // Hold to compare raw footage

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  void _updateConfig(ColorMatchConfig updated) {
    setState(() {
      _config = updated;
    });
    widget.onApply(updated);
  }

  void _reset() {
    const fresh = ColorMatchConfig();
    _updateConfig(fresh);
  }

  @override
  Widget build(BuildContext context) {
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
                    // Master Enable / Mode Selector
                    _buildModeTabs(),
                    const SizedBox(height: 12),

                    // Palette Grid or Timeline Clip Selector
                    if (_config.mode == ColorMatchMode.timelineClip)
                      _buildTimelineClipSelector()
                    else
                      _buildPresetPaletteSelector(),
                    const SizedBox(height: 14),

                    // Dual Spectrum Match Gauge & Hold to Compare
                    _buildSpectrumAndCompareBar(),
                    const SizedBox(height: 14),

                    // Parameter Tuning Sliders
                    _buildSlider(
                      label: 'Match Intensity',
                      value: _config.intensity,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          intensity: val,
                        ));
                      },
                    ),
                    _buildSlider(
                      label: 'Luminance Weight',
                      value: _config.luminanceWeight,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          luminanceWeight: val,
                        ));
                      },
                    ),
                    _buildSlider(
                      label: 'Color Spread',
                      value: _config.colorSpread,
                      min: 0.0,
                      max: 1.0,
                      percent: true,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          colorSpread: val,
                        ));
                      },
                    ),
                    _buildSlider(
                      label: 'Saturation Balance',
                      value: _config.saturationMatch,
                      min: 0.0,
                      max: 2.0,
                      formatVal: '${(_config.saturationMatch * 100).toInt()}%',
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(
                          isEnabled: true,
                          saturationMatch: val,
                        ));
                      },
                    ),

                    const SizedBox(height: 8),

                    // Preserve Skin Tones Switch
                    _buildSkinToneCard(),
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
              color: const Color(0xFFFF9F43).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_fix_high,
              color: Color(0xFFFF9F43),
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
                      'AI Color Match',
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
                          colors: [Color(0xFFFF9F43), Color(0xFFFF5252)],
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
                  _config.isEnabled
                      ? 'Harmonizes luminance & color cast across shots'
                      : 'Disabled — Tap a palette or clip to match',
                  style: AppTypography.labelSmall.copyWith(
                    color: _config.isEnabled ? const Color(0xFFFF9F43) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Reset button
          if (_config.isEnabled)
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

  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTabButton(
              title: 'Pro Palettes',
              icon: Icons.palette_outlined,
              isSelected: _config.mode == ColorMatchMode.preset,
              onTap: () {
                _updateConfig(_config.copyWith(
                  isEnabled: true,
                  mode: ColorMatchMode.preset,
                ));
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeTabButton(
              title: 'Timeline Clip',
              icon: Icons.movie_filter_outlined,
              isSelected: _config.mode == ColorMatchMode.timelineClip,
              onTap: () {
                _updateConfig(_config.copyWith(
                  isEnabled: true,
                  mode: ColorMatchMode.timelineClip,
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9F43) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.black : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetPaletteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT REFERENCE LOOK',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ColorPalettePreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = ColorPalettePreset.values[index];
              final isSelected = _config.isEnabled &&
                  _config.mode == ColorMatchMode.preset &&
                  _config.preset == preset;

              return InkWell(
                onTap: () {
                  _updateConfig(_config.copyWith(
                    isEnabled: true,
                    mode: ColorMatchMode.preset,
                    preset: preset,
                  ));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9F43).withOpacity(0.12)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF9F43) : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 3-Color Swatch
                      Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: preset.previewColors.map((c) => Color(c)).toList(),
                          ),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preset.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? const Color(0xFFFF9F43) : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      Text(
                        isSelected ? 'Active' : 'Pro Tone',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: isSelected ? const Color(0xFFFF9F43) : AppColors.textMuted,
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

  Widget _buildTimelineClipSelector() {
    final clips = widget.availableReferenceClips;

    if (clips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.movie_filter_outlined, color: AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(
              'No Other Clips on Timeline',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add at least 2 video clips to match tone directly from another shot.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT TIMELINE REFERENCE CLIP',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: clips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final clip = clips[index];
              final isSelected = _config.isEnabled &&
                  _config.mode == ColorMatchMode.timelineClip &&
                  _config.referenceClipId == clip.id;

              return InkWell(
                onTap: () {
                  _updateConfig(_config.copyWith(
                    isEnabled: true,
                    mode: ColorMatchMode.timelineClip,
                    referenceClipId: clip.id,
                    referenceClipName: 'Clip ${index + 1}',
                  ));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF9F43).withOpacity(0.15)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF9F43) : AppColors.border,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 16,
                            color: isSelected ? const Color(0xFFFF9F43) : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Clip ${index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? const Color(0xFFFF9F43) : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(clip.durationMs / 1000).toStringAsFixed(1)}s duration',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        isSelected ? '✓ Matched Source' : 'Tap to match',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: isSelected ? const Color(0xFFFF9F43) : AppColors.textMuted,
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

  Widget _buildSpectrumAndCompareBar() {
    final matchScore = (_config.intensity * 92 + _config.luminanceWeight * 6).toInt().clamp(50, 99);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Waveform spectrum match indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_graph, color: Color(0xFFFF9F43), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'AI TONE FIDELITY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$matchScore% Match',
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFFFF9F43),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: matchScore / 100.0,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F43)),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Hold to Compare Button
          GestureDetector(
            onTapDown: (_) {
              setState(() => _isComparing = true);
              widget.onApply(const ColorMatchConfig());
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _isComparing ? Colors.white24 : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _isComparing ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: _isComparing ? const Color(0xFFFF9F43) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isComparing ? 'Raw View' : 'Hold Compare',
                    style: AppTypography.labelSmall.copyWith(
                      color: _isComparing ? const Color(0xFFFF9F43) : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
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
    final displayValue = formatVal ?? (percent ? '${(value * 100).toInt()}%' : value.toStringAsFixed(2));

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
                  color: const Color(0xFFFF9F43),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF9F43),
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

  Widget _buildSkinToneCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F43).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.face,
              color: Color(0xFFFF9F43),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preserve Skin Tones',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Protects faces from unnatural color tint shifts',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _config.preserveSkinTones,
            activeColor: const Color(0xFFFF9F43),
            onChanged: (val) {
              _updateConfig(_config.copyWith(
                isEnabled: true,
                preserveSkinTones: val,
              ));
            },
          ),
        ],
      ),
    );
  }
}
