import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../models/progress_bar_config.dart';

/// Interactive Studio for Customizing Social Video Retention Progress Bars.
///
/// Gives creators granular control over heights, electric neon gradients,
/// glow effects, pill curves, and viewport positioning (Top/Bottom).
class ProgressBarSheet extends StatefulWidget {
  final Project project;
  final int playheadPositionMs;
  final Function(Project updatedProject) onSaveProject;
  final bool isDocked;
  final VoidCallback? onDone;

  const ProgressBarSheet({
    super.key,
    required this.project,
    this.playheadPositionMs = 0,
    required this.onSaveProject,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    int playheadPositionMs = 0,
    required Function(Project) onSaveProject,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressBarSheet(
        project: project,
        playheadPositionMs: playheadPositionMs,
        onSaveProject: onSaveProject,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ProgressBarSheet> createState() => _ProgressBarSheetState();
}

class _ProgressBarSheetState extends State<ProgressBarSheet> {
  late ProgressBarConfig _config;
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _config = widget.project.progressBar;
  }

  void _update(ProgressBarConfig updated) {
    setState(() => _config = updated);
    final newProject = _project.copyWith(progressBar: updated);
    _project = newProject;
    widget.onSaveProject(newProject);
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.linear_scale, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('Retention Progress Bar', style: AppTypography.titleLarge),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                        onPressed: widget.onDone ?? () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(28, 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Master Toggle & Live Mini Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _config.isEnabled ? AppColors.accent : AppColors.border,
                      width: _config.isEnabled ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Video Progress Bar',
                                style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Boosts watch retention on Shorts, Reels & TikTok',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Switch(
                            value: _config.isEnabled,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              _update(_config.copyWith(isEnabled: val));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Interactive Preview Box
                      Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            const Center(
                              child: Text(
                                'PREVIEW SIMULATOR (50% PROGRESS)',
                                style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_config.isEnabled)
                              Positioned(
                                top: _config.isTopPosition ? 0 : null,
                                bottom: _config.isTopPosition ? null : 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: _config.height,
                                  color: _config.trackColor,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.52,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_config.primaryColor, _config.secondaryColor],
                                          ),
                                          borderRadius: BorderRadius.circular(_config.borderRadius),
                                          boxShadow: _config.showGlow
                                              ? [
                                                  BoxShadow(
                                                    color: _config.primaryColor.withOpacity(0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Preset Themes
                Text('ELECTRIC GRADIENT PRESETS', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ProgressBarPreset.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final preset = ProgressBarPreset.values[idx];
                      final isSelected = _config.primaryColorValue == preset.primaryColor.value &&
                          _config.secondaryColorValue == preset.secondaryColor.value;

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _update(_config.copyWith(
                            isEnabled: true,
                            primaryColorValue: preset.primaryColor.value,
                            secondaryColorValue: preset.secondaryColor.value,
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [preset.primaryColor, preset.secondaryColor],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.accent : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Position Toggle (Bottom vs Top)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Canvas Position', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Bottom', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: true, label: Text('Top', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_config.isTopPosition},
                      onSelectionChanged: (val) {
                        _update(_config.copyWith(isTopPosition: val.first));
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        selectedBackgroundColor: AppColors.primary,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Height Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bar Thickness', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${_config.height.round()} px', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ],
                ),
                Slider(
                  value: _config.height,
                  min: 2.0,
                  max: 16.0,
                  divisions: 14,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    _update(_config.copyWith(height: val));
                  },
                ),
                const SizedBox(height: 10),

                // 5. Glow Effect Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Neon Glow Diffusion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Subtle neon light spread behind progress bar', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                    Switch(
                      value: _config.showGlow,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        _update(_config.copyWith(showGlow: val));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _update(const ProgressBarConfig(isEnabled: false));
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    widget.onDone?.call();
                    if (!widget.isDocked) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
