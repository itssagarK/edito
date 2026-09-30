import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/color_wheels_config.dart';
import '../../models/wheel_channel_value.dart';
import 'color_wheel_disc_widget.dart';

class ColorWheelsStudioSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const ColorWheelsStudioSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<ColorWheelsStudioSheet> createState() => _ColorWheelsStudioSheetState();
}

class _ColorWheelsStudioSheetState extends State<ColorWheelsStudioSheet> {
  late ColorWheelsConfig _config;
  int _selectedWheelIndex = 0; // 0: All 4, 1: Wheel 1, 2: Wheel 2, 3: Wheel 3, 4: Wheel 4

  @override
  void initState() {
    super.initState();
    _config = widget.clip.colorWheels;
  }

  void _update(ColorWheelsConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(colorWheels: _config));
  }

  void _applyPreset(ColorWheelsPreset preset) {
    final newConfig = ColorWheelsConfig.fromPreset(preset);
    _update(newConfig);
  }

  void _resetAll() {
    _update(const ColorWheelsConfig(isEnabled: true));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? null : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 12),
                  if (_config.isEnabled) ...[
                    _buildModeSelector(),
                    const SizedBox(height: 12),
                    _buildWheelViewSelector(),
                    const SizedBox(height: 12),
                    _buildWheelsSection(),
                    const SizedBox(height: 12),
                    if (_config.mode == ColorWheelsMode.primary)
                      _buildLumaMixCard()
                    else
                      _buildLogRangesCard(),
                    const SizedBox(height: 12),
                    _buildMasterIntensitySlider(),
                    const SizedBox(height: 12),
                    _buildPresetsSection(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ],
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
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.donut_large,
              color: Color(0xFFFFD700),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color Wheels Studio',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Edito Pro Primary & Log Grading',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accent),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFFFFD700) : AppColors.border,
          width: _config.isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color Wheels Grading',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isEnabled
                      ? 'Active — ${_config.mode.label} with live hardware preview'
                      : 'Enable to grade footage with Lift/Gamma/Gain or Log curves',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFFFFD700),
            onChanged: (val) {
              _update(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              title: 'Primary Wheels',
              subtitle: 'Lift, Gamma, Gain',
              isSelected: _config.mode == ColorWheelsMode.primary,
              onTap: () {
                _update(_config.copyWith(mode: ColorWheelsMode.primary));
              },
            ),
          ),
          Expanded(
            child: _buildModeTab(
              title: 'Log Wheels',
              subtitle: 'Shadow, Midtone, Highlight',
              isSelected: _config.mode == ColorWheelsMode.log,
              onTap: () {
                _update(_config.copyWith(mode: ColorWheelsMode.log));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFFD700) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelViewSelector() {
    final titles = _config.mode == ColorWheelsMode.primary
        ? ['ALL 4', 'LIFT', 'GAMMA', 'GAIN', 'OFFSET']
        : ['ALL 4', 'SHADOW', 'MIDTONE', 'HIGHLIGHT', 'OFFSET'];

    final colors = [
      null,
      const Color(0xFF00E5FF),
      const Color(0xFFFFD700),
      const Color(0xFFFF2D55),
      AppColors.accent,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isSelected = _selectedWheelIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedWheelIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    titles[index],
                    style: AppTypography.caption.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? (colors[index] ?? AppColors.primary) : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWheelsSection() {
    if (_config.mode == ColorWheelsMode.primary) {
      return _buildPrimaryWheels();
    } else {
      return _buildLogWheels();
    }
  }

  Widget _buildPrimaryWheels() {
    final p = _config.primary;

    if (_selectedWheelIndex == 0) {
      // 2x2 Grid of All 4 Wheels
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'LIFT (SHADOWS)',
                  value: p.lift,
                  accentColor: const Color(0xFF00E5FF),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    primary: p.copyWith(lift: v),
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'GAMMA (MIDTONES)',
                  value: p.gamma,
                  accentColor: const Color(0xFFFFD700),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    primary: p.copyWith(gamma: v),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'GAIN (HIGHLIGHTS)',
                  value: p.gain,
                  accentColor: const Color(0xFFFF2D55),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    primary: p.copyWith(gain: v),
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'OFFSET (GLOBAL)',
                  value: p.offset,
                  accentColor: AppColors.accent,
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    primary: p.copyWith(offset: v),
                  )),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_selectedWheelIndex == 1) {
      return ColorWheelDiscWidget(
        label: 'LIFT (SHADOWS & BLACK PEDESTAL)',
        subtitle: 'Target low tonal range. Adjust chromatic tint and pedestal exposure.',
        value: p.lift,
        accentColor: const Color(0xFF00E5FF),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(primary: p.copyWith(lift: v))),
      );
    } else if (_selectedWheelIndex == 2) {
      return ColorWheelDiscWidget(
        label: 'GAMMA (MIDTONES & SKIN TONES)',
        subtitle: 'Target natural subject skin and mid-range tonal warmth.',
        value: p.gamma,
        accentColor: const Color(0xFFFFD700),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(primary: p.copyWith(gamma: v))),
      );
    } else if (_selectedWheelIndex == 3) {
      return ColorWheelDiscWidget(
        label: 'GAIN (HIGHLIGHTS & SPECULAR)',
        subtitle: 'Target bright sky roll-off and specular highlights.',
        value: p.gain,
        accentColor: const Color(0xFFFF2D55),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(primary: p.copyWith(gain: v))),
      );
    } else {
      return ColorWheelDiscWidget(
        label: 'OFFSET (GLOBAL MASTER PEDESTAL)',
        subtitle: 'Uniform chromaticity and brightness shift across all channels.',
        value: p.offset,
        accentColor: AppColors.accent,
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(primary: p.copyWith(offset: v))),
      );
    }
  }

  Widget _buildLogWheels() {
    final l = _config.log;

    if (_selectedWheelIndex == 0) {
      // 2x2 Grid of All 4 Wheels
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'SHADOW (LOG)',
                  value: l.shadow,
                  accentColor: const Color(0xFF00E5FF),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    log: l.copyWith(shadow: v),
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'MIDTONE (LOG)',
                  value: l.midtone,
                  accentColor: const Color(0xFFFFD700),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    log: l.copyWith(midtone: v),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'HIGHLIGHT (LOG)',
                  value: l.highlight,
                  accentColor: const Color(0xFFFF2D55),
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    log: l.copyWith(highlight: v),
                  )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ColorWheelDiscWidget(
                  label: 'OFFSET (LOG)',
                  value: l.offset,
                  accentColor: AppColors.accent,
                  isCompact: true,
                  onChanged: (v) => _update(_config.copyWith(
                    log: l.copyWith(offset: v),
                  )),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_selectedWheelIndex == 1) {
      return ColorWheelDiscWidget(
        label: 'SHADOW (LOG)',
        subtitle: 'Logarithmic shadow zone below Low Range threshold.',
        value: l.shadow,
        accentColor: const Color(0xFF00E5FF),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(log: l.copyWith(shadow: v))),
      );
    } else if (_selectedWheelIndex == 2) {
      return ColorWheelDiscWidget(
        label: 'MIDTONE (LOG)',
        subtitle: 'Cubic Hermite weighted midtone band between Low and High Range.',
        value: l.midtone,
        accentColor: const Color(0xFFFFD700),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(log: l.copyWith(midtone: v))),
      );
    } else if (_selectedWheelIndex == 3) {
      return ColorWheelDiscWidget(
        label: 'HIGHLIGHT (LOG)',
        subtitle: 'Logarithmic highlight zone above High Range threshold.',
        value: l.highlight,
        accentColor: const Color(0xFFFF2D55),
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(log: l.copyWith(highlight: v))),
      );
    } else {
      return ColorWheelDiscWidget(
        label: 'OFFSET (LOG)',
        subtitle: 'Global pedestal shift across the logarithmic curve.',
        value: l.offset,
        accentColor: AppColors.accent,
        size: 160.0,
        onChanged: (v) => _update(_config.copyWith(log: l.copyWith(offset: v))),
      );
    }
  }

  Widget _buildLumaMixCard() {
    final p = _config.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LumaMix (Luminance Decoupling)', style: AppTypography.bodySmall),
              Text(
                '${(p.lumaMix * 100).toInt()}%',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFFD700)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Preserves original exposure balance while shifting chromatic hue bias',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
          Slider(
            value: p.lumaMix,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFFFFD700),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(primary: p.copyWith(lumaMix: val)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogRangesCard() {
    final l = _config.log;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low Range (Shadow Crossover)', style: AppTypography.bodySmall),
              Text(
                '${(l.lowRange * 100).toInt()}%',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
              ),
            ],
          ),
          Slider(
            value: l.lowRange,
            min: 0.10,
            max: 0.50,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(log: l.copyWith(lowRange: val)));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('High Range (Highlight Crossover)', style: AppTypography.bodySmall),
              Text(
                '${(l.highRange * 100).toInt()}%',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF2D55)),
              ),
            ],
          ),
          Slider(
            value: l.highRange,
            min: 0.50,
            max: 0.90,
            activeColor: const Color(0xFFFF2D55),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(log: l.copyWith(highRange: val)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMasterIntensitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Master Grade Intensity', style: AppTypography.bodySmall),
              Text(
                '${(_config.masterIntensity * 100).toInt()}%',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFFD700)),
              ),
            ],
          ),
          Slider(
            value: _config.masterIntensity,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFFFFD700),
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _update(_config.copyWith(masterIntensity: val));
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
          'Signature Look Presets',
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ColorWheelsPreset.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = ColorWheelsPreset.values[index];
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _applyPreset(preset),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        preset.label,
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.description,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 9),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset All Color Wheels'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _resetAll,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_all, size: 16),
          label: const Text('Apply Color Wheels to All Video Clips'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onSave(widget.clip.copyWith(colorWheels: _config), applyToAll: true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Color Wheels grade applied to all clips'),
                duration: Duration(milliseconds: 900),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),
      ],
    );
  }
}
