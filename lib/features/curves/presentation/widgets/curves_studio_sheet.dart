import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/channel_curve.dart';
import '../../models/curves_config.dart';
import 'curve_grid_editor_widget.dart';

/// Docked bottom studio sheet for CapCut Pro RGB Curves & Luma Spline Color Grading.
class CurvesStudioSheet extends StatefulWidget {
  final Clip clip;
  final void Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const CurvesStudioSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<CurvesStudioSheet> createState() => _CurvesStudioSheetState();
}

class _CurvesStudioSheetState extends State<CurvesStudioSheet> {
  late CurvesConfig _config;
  CurveChannel _selectedChannel = CurveChannel.luma;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.curves;
  }

  @override
  void didUpdateWidget(covariant CurvesStudioSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id != widget.clip.id) {
      _config = widget.clip.curves;
    }
  }

  void _updateConfig(CurvesConfig newConfig) {
    setState(() => _config = newConfig);
    final updatedClip = widget.clip.copyWith(curves: newConfig);
    widget.onSave(updatedClip, applyToAll: _applyToAll);
  }

  @override
  Widget build(BuildContext context) {
    final activeCurve = _config.getChannel(_selectedChannel);

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
                      Icons.show_chart,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RGB Curves Studio',
                          style: AppTypography.titleMedium,
                        ),
                        Text(
                          'Edito Pro Luma & RGB Spline Grading',
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

              // Channel Selector Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: CurveChannel.values.map((channel) {
                    final isSelected = (_selectedChannel == channel);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedChannel = channel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? channel.accentColor.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: isSelected
                                ? Border.all(color: channel.accentColor, width: 1.2)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: channel.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                channel.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? channel.accentColor
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Central Interactive 2D Curve Grid Editor
              CurveGridEditorWidget(
                curve: activeCurve,
                size: 240.0,
                onCurveChanged: (updated) {
                  _updateConfig(_config.withChannelUpdated(_selectedChannel, updated));
                },
              ),
              const SizedBox(height: 14),

              // Channel Intensity Slider
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${_selectedChannel.name.toUpperCase()} Intensity',
                      style: AppTypography.caption,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _selectedChannel.accentColor,
                        thumbColor: _selectedChannel.accentColor,
                        inactiveTrackColor: AppColors.border,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: activeCurve.intensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _updateConfig(_config.withChannelUpdated(
                            _selectedChannel,
                            activeCurve.copyWith(intensity: val),
                          ));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(activeCurve.intensity * 100).toInt()}%',
                      style: AppTypography.timecode.copyWith(fontSize: 10),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),

              // Master Intensity Slider
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Master Intensity',
                      style: AppTypography.caption,
                    ),
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
                        value: _config.masterIntensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(masterIntensity: val));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(_config.masterIntensity * 100).toInt()}%',
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
                  'CINEMATIC CURVE PRESETS',
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
                  itemCount: CurvesPreset.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final preset = CurvesPreset.values[idx];
                    return ActionChip(
                      label: Text(
                        preset.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () {
                        _updateConfig(CurvesConfig.fromPreset(preset));
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons Row: Reset Channel & Reset All
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'Reset ${_selectedChannel.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        _updateConfig(_config.withChannelUpdated(
                          _selectedChannel,
                          ChannelCurve.identity(_selectedChannel),
                        ));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text(
                        'Reset All Curves',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        _updateConfig(const CurvesConfig());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Apply to all clips toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Apply Curves to All Clips',
                  style: TextStyle(fontSize: 12),
                ),
                value: _applyToAll,
                activeColor: AppColors.primaryLight,
                onChanged: (val) {
                  setState(() => _applyToAll = val);
                  final updatedClip = widget.clip.copyWith(curves: _config);
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
