import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/film_grain_type.dart';
import '../../models/film_grain_config.dart';

/// Docked bottom studio sheet for CapCut Pro Cinematic Film Grain & Texture Particles.
class FilmGrainStudioSheet extends StatefulWidget {
  final Clip clip;
  final void Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const FilmGrainStudioSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<FilmGrainStudioSheet> createState() => _FilmGrainStudioSheetState();
}

class _FilmGrainStudioSheetState extends State<FilmGrainStudioSheet> {
  late FilmGrainConfig _config;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.filmGrain;
  }

  @override
  void didUpdateWidget(covariant FilmGrainStudioSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id != widget.clip.id) {
      _config = widget.clip.filmGrain;
    }
  }

  void _updateConfig(FilmGrainConfig newConfig) {
    setState(() => _config = newConfig);
    final updatedClip = widget.clip.copyWith(filmGrain: newConfig);
    widget.onSave(updatedClip, applyToAll: _applyToAll);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(16)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.grain,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Film Grain Studio',
                          style: AppTypography.titleMedium,
                        ),
                        Text(
                          'Edito Pro Celluloid & Texture Engine',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primaryLight),
                    onPressed: widget.onDone,
                    tooltip: 'Done',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Master Enable Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _config.isEnabled ? Icons.grain : Icons.blur_off,
                          size: 18,
                          color: _config.isEnabled
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enable Film Grain Emulsion',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _config.isEnabled,
                      activeColor: AppColors.primaryLight,
                      onChanged: (val) {
                        _updateConfig(_config.copyWith(isEnabled: val));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Film Stock Types Carousel
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PHOTOGRAPHIC FILM STOCKS',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: FilmGrainType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final stock = FilmGrainType.values[idx];
                    final isSelected = (_config.type == stock);

                    return GestureDetector(
                      onTap: () {
                        _updateConfig(_config.copyWith(
                          type: stock,
                          isEnabled: true,
                        ));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 104,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              stock.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stock.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Dynamic Sliders
              // 1. Intensity Slider
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Grain Intensity', style: AppTypography.caption),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryLight,
                        thumbColor: AppColors.primaryLight,
                        inactiveTrackColor: AppColors.border,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _config.intensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(
                            intensity: val,
                            isEnabled: val > 0.001,
                          ));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_config.intensity * 100).toInt()}%',
                      style: AppTypography.timecode.copyWith(fontSize: 10),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              // 2. Grain Size Slider
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Grain Size', style: AppTypography.caption),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        thumbColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _config.grainSize,
                        min: 0.5,
                        max: 3.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(grainSize: val));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${_config.grainSize.toStringAsFixed(1)}x',
                      style: AppTypography.timecode.copyWith(fontSize: 10),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              // 3. Roughness / Chromatic Noise Slider
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Chroma Noise', style: AppTypography.caption),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF2D55),
                        thumbColor: const Color(0xFFFF2D55),
                        inactiveTrackColor: AppColors.border,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _config.roughness,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(roughness: val));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_config.roughness * 100).toInt()}%',
                      style: AppTypography.timecode.copyWith(fontSize: 10),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              // 4. Shadow Suppression (Blacks Protection)
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Protect Blacks', style: AppTypography.caption),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accentGold,
                        thumbColor: AppColors.accentGold,
                        inactiveTrackColor: AppColors.border,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _config.shadowSuppression,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(shadowSuppression: val));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_config.shadowSuppression * 100).toInt()}%',
                      style: AppTypography.timecode.copyWith(fontSize: 10),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Signature Presets Carousel
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CINEMATIC GRAIN PRESETS',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: FilmGrainPreset.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final preset = FilmGrainPreset.values[idx];
                    return ActionChip(
                      label: Text(
                        preset.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () {
                        _updateConfig(FilmGrainConfig.fromPreset(preset));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Temporal Animation Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Temporal Motion (Frame-by-frame variation)',
                  style: TextStyle(fontSize: 12),
                ),
                value: _config.animate,
                activeColor: AppColors.primaryLight,
                onChanged: (val) {
                  _updateConfig(_config.copyWith(animate: val));
                },
              ),

              // Reset to Default button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text(
                        'Reset Film Grain',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        _updateConfig(const FilmGrainConfig());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Apply to all clips toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Apply Grain to All Clips',
                  style: TextStyle(fontSize: 12),
                ),
                value: _applyToAll,
                activeColor: AppColors.primaryLight,
                onChanged: (val) {
                  setState(() => _applyToAll = val);
                  final updatedClip = widget.clip.copyWith(filmGrain: _config);
                  widget.onSave(updatedClip, applyToAll: val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
