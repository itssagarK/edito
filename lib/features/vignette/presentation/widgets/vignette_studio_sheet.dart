import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vignette_config.dart';

/// CapCut Pro Studio Sheet for Cinematic Vignette & Atmospheric Spotlight.
class VignetteStudioSheet extends StatefulWidget {
  final VignetteConfig initialConfig;
  final ValueChanged<VignetteConfig> onChanged;
  final VoidCallback? onReset;
  final VoidCallback? onApplyToAll;
  final ValueChanged<bool>? onReticleModeChanged;

  const VignetteStudioSheet({
    super.key,
    required this.initialConfig,
    required this.onChanged,
    this.onReset,
    this.onApplyToAll,
    this.onReticleModeChanged,
  });

  @override
  State<VignetteStudioSheet> createState() => _VignetteStudioSheetState();
}

class _VignetteStudioSheetState extends State<VignetteStudioSheet> {
  late VignetteConfig _config;
  bool _isReticleActive = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  void didUpdateWidget(covariant VignetteStudioSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialConfig != widget.initialConfig) {
      _config = widget.initialConfig;
    }
  }

  void _update(VignetteConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onChanged(newConfig);
  }

  void _selectPreset(VignettePreset preset) {
    final next = VignetteConfig.fromPreset(preset);
    _update(next);
  }

  void _toggleReticle() {
    setState(() {
      _isReticleActive = !_isReticleActive;
    });
    widget.onReticleModeChanged?.call(_isReticleActive);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetsSection(),
                  const SizedBox(height: 16),
                  if (_config.isEnabled) ...[
                    _buildTintSection(),
                    const SizedBox(height: 16),
                    _buildSlider(
                      title: 'Intensity',
                      subtitle: _config.intensity < 0 ? 'Light Spotlight Halo' : 'Dark Film Vignette',
                      value: _config.intensity,
                      min: -1.0,
                      max: 1.0,
                      format: (v) => '${(v * 100).toInt()}%',
                      onChanged: (v) => _update(_config.copyWith(intensity: v)),
                    ),
                    _buildSlider(
                      title: 'Clear Radius',
                      subtitle: 'Focal clearing size before edge falloff',
                      value: _config.radius,
                      min: 0.1,
                      max: 1.0,
                      format: (v) => '${(v * 100).toInt()}%',
                      onChanged: (v) => _update(_config.copyWith(radius: v)),
                    ),
                    _buildSlider(
                      title: 'Feather Softness',
                      subtitle: 'Edge transition gradient blur rate',
                      value: _config.feather,
                      min: 0.05,
                      max: 1.0,
                      format: (v) => '${(v * 100).toInt()}%',
                      onChanged: (v) => _update(_config.copyWith(feather: v)),
                    ),
                    _buildSlider(
                      title: 'Aspect Roundness',
                      subtitle: _config.roundness < -0.1
                          ? '2.39:1 Anamorphic Widescreen Oval'
                          : _config.roundness > 0.1
                              ? 'Vertical Portrait Oval'
                              : 'Circular Falloff',
                      value: _config.roundness,
                      min: -1.0,
                      max: 1.0,
                      format: (v) => '${(v * 100).toInt()}%',
                      onChanged: (v) => _update(_config.copyWith(roundness: v)),
                    ),
                    const SizedBox(height: 8),
                    _buildCenterReticleControl(),
                  ],
                  const SizedBox(height: 12),
                  _buildBottomActions(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.blur_circular,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cinematic Vignette & Spotlight',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Hollywood edge shading & optical focus',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) {
              _update(_config.copyWith(
                isEnabled: val,
                intensity: val && _config.intensity == 0.0 ? 0.45 : _config.intensity,
              ));
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
          'CINEMATIC PRESETS',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VignettePreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = VignettePreset.values[index];
              final isSelected = _config.isEnabled
                  ? (preset == VignettePreset.cinematic35mm && (_config.intensity - 0.45).abs() < 0.05) ||
                      (preset == VignettePreset.vintageDrama && (_config.intensity - 0.75).abs() < 0.05) ||
                      (preset == VignettePreset.anamorphicWidescreen && _config.roundness < -0.3) ||
                      (preset == VignettePreset.dreamyHighKey && _config.intensity < -0.2) ||
                      (preset == VignettePreset.actionLock && _config.radius < 0.4) ||
                      (preset == VignettePreset.goldenHour && _config.tint == VignetteTint.warmAmber)
                  : preset == VignettePreset.neutralOff;

              return InkWell(
                onTap: () => _selectPreset(preset),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        preset.label,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset == VignettePreset.neutralOff ? 'Bypass' : 'Studio',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
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

  Widget _buildTintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RIM COLOR TINT',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: VignetteTint.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tint = VignetteTint.values[index];
              final isSelected = _config.tint == tint;

              return InkWell(
                onTap: () => _update(_config.copyWith(tint: tint)),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceHighlight : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: tint.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tint.label,
                        style: AppTypography.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                format(value),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceHighlight,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withOpacity(0.15),
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

  Widget _buildCenterReticleControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isReticleActive ? AppColors.primary : AppColors.border,
          width: _isReticleActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.center_focus_strong,
            color: _isReticleActive ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optical Center Aiming Reticle',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isReticleActive
                      ? 'Drag reticle directly over viewport subject'
                      : 'Offset: (${(_config.centerX * 100).toInt()}%, ${(_config.centerY * 100).toInt()}%)',
                  style: AppTypography.caption.copyWith(
                    color: _isReticleActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_config.centerX != 0.0 || _config.centerY != 0.0)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Center spotlight',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () {
                _update(_config.copyWith(centerX: 0.0, centerY: 0.0));
              },
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _isReticleActive ? AppColors.primary : AppColors.textPrimary,
              side: BorderSide(
                color: _isReticleActive ? AppColors.primary : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _toggleReticle,
            child: Text(
              _isReticleActive ? 'Lock Aim' : 'Aim Reticle',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset'),
            onPressed: () {
              widget.onReset?.call();
              _update(const VignetteConfig());
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Apply to All'),
            onPressed: widget.onApplyToAll,
          ),
        ),
      ],
    );
  }
}
