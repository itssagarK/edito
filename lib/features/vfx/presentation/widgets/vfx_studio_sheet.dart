import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/vfx_config.dart';
import '../../services/vfx_compiler_service.dart';

class VfxStudioSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const VfxStudioSheet({
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
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => VfxStudioSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<VfxStudioSheet> createState() => _VfxStudioSheetState();
}

class _VfxStudioSheetState extends State<VfxStudioSheet> {
  late VfxConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.vfx;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(vfx: _config);
    widget.onSave(updated);
  }

  void _applyPreset(VfxType type, {double intensity = 0.50, double? param}) {
    setState(() {
      switch (type) {
        case VfxType.none:
          _config = const VfxConfig(type: VfxType.none, intensity: 0.0);
          break;
        case VfxType.filmGrain:
          _config = VfxConfig(type: VfxType.filmGrain, intensity: intensity, grainSize: param ?? 2.0);
          break;
        case VfxType.rgbGlitch:
          _config = VfxConfig(type: VfxType.rgbGlitch, intensity: intensity, rgbOffset: param ?? 10.0);
          break;
        case VfxType.lensBlur:
          _config = VfxConfig(type: VfxType.lensBlur, intensity: intensity, blurRadius: param ?? 8.0);
          break;
        case VfxType.vhsVintage:
          _config = VfxConfig(type: VfxType.vhsVintage, intensity: intensity);
          break;
        case VfxType.vignette:
          _config = VfxConfig(type: VfxType.vignette, intensity: intensity, vignetteRadius: param ?? 0.55);
          break;
        case VfxType.lightLeak:
          _config = VfxConfig(type: VfxType.lightLeak, intensity: intensity);
          break;
        case VfxType.cameraShake:
          _config = VfxConfig(type: VfxType.cameraShake, intensity: intensity, shakeAmplitude: param ?? 12.0);
          break;
        case VfxType.radialZoom:
          _config = VfxConfig(type: VfxType.radialZoom, intensity: intensity, blurRadius: param ?? 10.0);
          break;
      }
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.55;
    final badge = VfxCompilerService.getVfxBadge(_config);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children: [
                if (!widget.isDocked)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text('Cinematic Visual FX', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 18),
                      onPressed: () {
                        if (widget.onDone != null) {
                          widget.onDone!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Presets Quick Carousel
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildPresetChip('None', VfxType.none, 0.0),
                const SizedBox(width: 6),
                _buildPresetChip('🎞️ 35mm Film', VfxType.filmGrain, 0.45),
                const SizedBox(width: 6),
                _buildPresetChip('⚡ RGB Glitch', VfxType.rgbGlitch, 0.65),
                const SizedBox(width: 6),
                _buildPresetChip('🌫️ Lens Blur', VfxType.lensBlur, 0.50),
                const SizedBox(width: 6),
                _buildPresetChip('📼 Retro VHS', VfxType.vhsVintage, 0.70),
                const SizedBox(width: 6),
                _buildPresetChip('🎬 Vignette', VfxType.vignette, 0.60),
                const SizedBox(width: 6),
                _buildPresetChip('☀️ Light Leak', VfxType.lightLeak, 0.55),
                const SizedBox(width: 6),
                _buildPresetChip('📳 Shake', VfxType.cameraShake, 0.60),
                const SizedBox(width: 6),
                _buildPresetChip('🚀 Zoom Rush', VfxType.radialZoom, 0.50),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Studio Controls
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Visual Effect Type Cards
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VfxType.values.map((t) {
                    final isSelected = _config.type == t;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _applyPreset(t, intensity: isSelected ? _config.intensity : 0.55),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 48) / 3,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.iconEmoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_config.isActive) ...[
                  const SizedBox(height: 14),

                  // Master Intensity Slider
                  _buildSliderCard(
                    title: 'Effect Intensity',
                    valueText: '${(_config.intensity * 100).toInt()}%',
                    color: AppColors.accent,
                    value: _config.intensity,
                    min: 0.05,
                    max: 1.0,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(intensity: v));
                      _applyChange();
                    },
                  ),

                  // Context-Specific Parameter Sliders
                  if (_config.type == VfxType.filmGrain) ...[
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Grain Texture Scale',
                      valueText: '${_config.grainSize.toStringAsFixed(1)}x',
                      color: AppColors.primaryLight,
                      value: _config.grainSize,
                      min: 1.0,
                      max: 4.0,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(grainSize: v));
                        _applyChange();
                      },
                    ),
                  ],

                  if (_config.type == VfxType.rgbGlitch) ...[
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Chromatic Shift Distance',
                      valueText: '${_config.rgbOffset.toInt()} px',
                      color: const Color(0xFFFF0055),
                      value: _config.rgbOffset,
                      min: 2.0,
                      max: 25.0,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(rgbOffset: v));
                        _applyChange();
                      },
                    ),
                  ],

                  if (_config.type == VfxType.lensBlur || _config.type == VfxType.radialZoom) ...[
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Blur Defocus Radius',
                      valueText: '${_config.blurRadius.toStringAsFixed(1)} px',
                      color: const Color(0xFF00E5FF),
                      value: _config.blurRadius,
                      min: 1.0,
                      max: 20.0,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(blurRadius: v));
                        _applyChange();
                      },
                    ),
                  ],

                  if (_config.type == VfxType.vignette) ...[
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Vignette Outer Radius',
                      valueText: '${(_config.vignetteRadius * 100).toInt()}%',
                      color: AppColors.accentWarm,
                      value: _config.vignetteRadius,
                      min: 0.25,
                      max: 0.85,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(vignetteRadius: v));
                        _applyChange();
                      },
                    ),
                  ],

                  if (_config.type == VfxType.cameraShake) ...[
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Shake Tremor Amplitude',
                      valueText: '${_config.shakeAmplitude.toInt()} px',
                      color: const Color(0xFFFF9100),
                      value: _config.shakeAmplitude,
                      min: 4.0,
                      max: 25.0,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(shakeAmplitude: v));
                        _applyChange();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildSliderCard(
                      title: 'Shake Motion Speed',
                      valueText: '${_config.speed.toStringAsFixed(1)}x',
                      color: AppColors.accent,
                      value: _config.speed,
                      min: 0.5,
                      max: 2.5,
                      onChanged: (v) {
                        setState(() => _config = _config.copyWith(speed: v));
                        _applyChange();
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VfxType type, double intensity) {
    final isSelected = _config.type == type;
    return InkWell(
      onTap: () => _applyPreset(type, intensity: intensity),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String valueText,
    required Color color,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(valueText, style: AppTypography.timecode.copyWith(fontSize: 11, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: color,
              inactiveColor: AppColors.border,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
