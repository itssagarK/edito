import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/mosaic_config.dart';

class MosaicSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const MosaicSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<MosaicSheet> createState() => _MosaicSheetState();
}

class _MosaicSheetState extends State<MosaicSheet> {
  late MosaicConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.mosaic;
  }

  void _update(MosaicConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(mosaic: _config));
  }

  void _applyPreset(MosaicPreset preset) {
    final newConfig = preset.createConfig();
    _update(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? null
            : const BorderRadius.vertical(top: Radius.circular(20)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 16),
                  if (_config.isEnabled) ...[
                    _buildPresetsSection(),
                    const SizedBox(height: 16),
                    _buildTypeSelector(),
                    const SizedBox(height: 16),
                    _buildShapeSelector(),
                    const SizedBox(height: 16),
                    _buildSlidersSection(),
                    const SizedBox(height: 16),
                    _buildTogglesSection(),
                    const SizedBox(height: 16),
                    _buildApplyToAllButton(),
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.blur_on, color: Color(0xFF00F0FF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Mosaic & Privacy Censor',
                  style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Face obscuration & confidential blur studio',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reset',
            onPressed: () => _update(const MosaicConfig()),
            style: IconButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primaryLight),
            onPressed: widget.onDone,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00F0FF).withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _config.isEnabled ? Icons.visibility_off : Icons.visibility,
                color: _config.isEnabled ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Privacy Censor',
                    style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _config.isEnabled ? 'Active on current clip' : 'Disabled (Tap to activate)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _config.isEnabled,
            onChanged: (val) {
              if (val && _config.type == MosaicType.none) {
                _update(_config.copyWith(isEnabled: true, type: MosaicType.pixelMosaic));
              } else {
                _update(_config.copyWith(isEnabled: val));
              }
            },
            activeColor: const Color(0xFF00F0FF),
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
          'ONE-TAP CAPCUT PRESETS',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPresetChip('Face Censor', MosaicPreset.faceCensor, Icons.face),
              _buildPresetChip('License Plate', MosaicPreset.licensePlate, Icons.directions_car),
              _buildPresetChip('Confidential Doc', MosaicPreset.confidentialDoc, Icons.description),
              _buildPresetChip('Retro Pixel', MosaicPreset.retroPixelArt, Icons.videogame_asset),
              _buildPresetChip('Frosted Backdrop', MosaicPreset.frostedGlassBackdrop, Icons.blur_linear),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, MosaicPreset preset, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: const Color(0xFF00F0FF)),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surfaceLight,
        side: BorderSide(color: AppColors.border),
        onPressed: () => _applyPreset(preset),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BLUR & CENSOR STYLE',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MosaicType.values.where((t) => t != MosaicType.none).map((t) {
            final isSelected = _config.type == t;
            return ChoiceChip(
              label: Text(t.label),
              selected: isSelected,
              selectedColor: const Color(0xFF00F0FF).withOpacity(0.25),
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF00F0FF) : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF00F0FF) : AppColors.border,
              ),
              onSelected: (selected) {
                if (selected) {
                  _update(_config.copyWith(type: t, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShapeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CENSOR GEOMETRY & REGION',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: MosaicShape.values.map((s) {
            final isSelected = _config.shape == s;
            IconData icon;
            switch (s) {
              case MosaicShape.rectangle:
                icon = Icons.crop_square;
                break;
              case MosaicShape.ellipse:
                icon = Icons.circle_outlined;
                break;
              case MosaicShape.bannerStrip:
                icon = Icons.view_headline;
                break;
              case MosaicShape.fullFrame:
                icon = Icons.fullscreen;
                break;
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => _update(_config.copyWith(shape: s)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00F0FF).withOpacity(0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00F0FF) : AppColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.label.split(' ').first,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF00F0FF) : AppColors.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildSlidersSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pixel size or Blur Radius
          if (_config.type == MosaicType.pixelMosaic ||
              _config.type == MosaicType.hexagonalCrystal) ...[
            _buildSliderRow(
              'Pixel Block Size',
              '${_config.pixelSize.toInt()} px',
              _config.pixelSize,
              4.0,
              64.0,
              (v) => _update(_config.copyWith(pixelSize: v)),
            ),
          ] else ...[
            _buildSliderRow(
              'Blur Radius (Sigma)',
              '${_config.blurRadius.toInt()} px',
              _config.blurRadius,
              2.0,
              60.0,
              (v) => _update(_config.copyWith(blurRadius: v)),
            ),
          ],
          if (_config.shape != MosaicShape.fullFrame) ...[
            const Divider(height: 20),
            _buildSliderRow(
              'Region Width',
              '${(_config.width * 100).toInt()}%',
              _config.width,
              0.05,
              1.0,
              (v) => _update(_config.copyWith(width: v)),
            ),
            const Divider(height: 20),
            _buildSliderRow(
              'Region Height',
              '${(_config.height * 100).toInt()}%',
              _config.height,
              0.05,
              1.0,
              (v) => _update(_config.copyWith(height: v)),
            ),
            if (_config.shape == MosaicShape.rectangle) ...[
              const Divider(height: 20),
              _buildSliderRow(
                'Corner Roundness',
                '${(_config.roundness * 100).toInt()}%',
                _config.roundness,
                0.0,
                1.0,
                (v) => _update(_config.copyWith(roundness: v)),
              ),
            ],
            const Divider(height: 20),
            _buildSliderRow(
              'Rotation Angle',
              '${_config.rotation.toInt()}°',
              _config.rotation,
              0.0,
              360.0,
              (v) => _update(_config.copyWith(rotation: v)),
            ),
            const Divider(height: 20),
            _buildSliderRow(
              'Edge Feather Softness',
              '${(_config.feather * 100).toInt()}%',
              _config.feather,
              0.0,
              1.0,
              (v) => _update(_config.copyWith(feather: v)),
            ),
          ],
          const Divider(height: 20),
          _buildSliderRow(
            'Master Opacity',
            '${(_config.opacity * 100).toInt()}%',
            _config.opacity,
            0.0,
            1.0,
            (v) => _update(_config.copyWith(opacity: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String title,
    String valueStr,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall),
            Text(
              valueStr,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00F0FF),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: const Color(0xFF00F0FF),
          inactiveColor: AppColors.border,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTogglesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (_config.shape != MosaicShape.fullFrame)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Invert Censor Mask', style: AppTypography.body),
              subtitle: Text(
                'Blur entire video outside the selected focus region',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              value: _config.inverted,
              activeColor: const Color(0xFF00F0FF),
              onChanged: (val) => _update(_config.copyWith(inverted: val)),
            ),
        ],
      ),
    );
  }

  Widget _buildApplyToAllButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.copy_all, size: 18),
      label: const Text('Apply Mosaic to All Video Clips'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00F0FF),
        side: const BorderSide(color: Color(0xFF00F0FF)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        widget.onSave(widget.clip.copyWith(mosaic: _config), applyToAll: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied Smart Mosaic to all video clips')),
        );
      },
    );
  }
}
