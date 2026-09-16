import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../models/video_layout_config.dart';
import '../../services/auto_reframe_service.dart';

class VideoLayoutSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const VideoLayoutSheet({
    super.key,
    required this.project,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.20),
      builder: (context) => VideoLayoutSheet(project: project, onSave: onSave, onDone: onDone),
    );
  }

  @override
  State<VideoLayoutSheet> createState() => _VideoLayoutSheetState();
}

class _VideoLayoutSheetState extends State<VideoLayoutSheet> {
  late VideoLayoutConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.project.layoutConfig;
  }

  void _applyChange() {
    final updated = widget.project.copyWith(
      layoutConfig: _config,
      width: _config.ratio.defaultWidth,
      height: _config.ratio.defaultHeight,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.60;
    final badge = AutoReframeService.getReframeBadge(_config);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
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
                        const Icon(Icons.aspect_ratio, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text('Auto-Reframe & Canvas', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38EF7D).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF38EF7D).withOpacity(0.5)),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF38EF7D)),
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

          // Interactive Visual Canvas Preview
          Container(
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: _config.ratio.aspectRatio,
                child: Container(
                  decoration: _buildMiniCanvasDecoration(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Box inside canvas
                      Padding(
                        padding: EdgeInsets.all(_config.framePadding * 0.5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_config.cornerRadius * 0.5),
                          child: Container(
                            color: const Color(0xFF1E293B).withOpacity(0.9),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _config.reframeMode == AutoReframeMode.smartCrop
                                        ? Icons.center_focus_strong
                                        : Icons.play_circle_outline,
                                    color: AppColors.accent,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _config.ratio.label.split(' ').first,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_config.ratio.defaultWidth} × ${_config.ratio.defaultHeight}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // 1. Aspect Ratio Selector Cards
                const Text('Platform Aspect Ratio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in VideoLayoutRatio.values)
                      ChoiceChip(
                        label: Text(r.label, style: const TextStyle(fontSize: 10)),
                        selected: _config.ratio == r,
                        selectedColor: AppColors.primary,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() => _config = _config.copyWith(ratio: r));
                            _applyChange();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Auto-Reframing Mode Selector
                const Text('Auto-Reframing Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final mode in AutoReframeMode.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() => _config = _config.copyWith(reframeMode: mode));
                              _applyChange();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: _config.reframeMode == mode ? const Color(0xFF38EF7D).withOpacity(0.18) : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _config.reframeMode == mode ? const Color(0xFF38EF7D) : AppColors.border,
                                  width: _config.reframeMode == mode ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getModeIcon(mode), size: 16, color: _config.reframeMode == mode ? const Color(0xFF38EF7D) : AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text(
                                    mode.label.split(' ').first,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: _config.reframeMode == mode ? FontWeight.bold : FontWeight.normal,
                                      color: _config.reframeMode == mode ? Colors.white : AppColors.textMuted,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Smart Crop Pan & Scan Subject Tracking Controls
                if (_config.reframeMode == AutoReframeMode.smartCrop) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38EF7D).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subject Horizontal Pan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(
                              '${(_config.focalPointX * 100).toInt()}%',
                              style: AppTypography.timecode.copyWith(fontSize: 11, color: const Color(0xFF38EF7D)),
                            ),
                          ],
                        ),
                        Slider(
                          value: _config.focalPointX,
                          min: -1.0,
                          max: 1.0,
                          activeColor: const Color(0xFF38EF7D),
                          inactiveColor: AppColors.border,
                          onChanged: (v) {
                            setState(() => _config = _config.copyWith(focalPointX: v));
                            _applyChange();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _config = _config.copyWith(focalPointX: 0.0, focalPointY: 0.0));
                                _applyChange();
                              },
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset Center', style: TextStyle(fontSize: 10)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                            ),
                            Text(
                              _config.focalPointX < -0.1 ? 'Pan Left' : (_config.focalPointX > 0.1 ? 'Pan Right' : 'Centered'),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 4. Blur Clone Controls
                if (_config.reframeMode == AutoReframeMode.fitWithBlur) ...[
                  _buildSliderCard(
                    title: 'Background Video Blur',
                    valueText: '${_config.blurIntensity.round()} px',
                    color: AppColors.accent,
                    value: _config.blurIntensity,
                    min: 5.0,
                    max: 50.0,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(blurIntensity: v));
                      _applyChange();
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // 5. Gradient Canvas Presets
                if (_config.reframeMode == AutoReframeMode.gradientCanvas) ...[
                  const Text('Cinematic Gradient Theme', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in GradientCanvasPreset.values)
                        ChoiceChip(
                          label: Text(g.label, style: const TextStyle(fontSize: 10)),
                          selected: _config.gradientPreset == g,
                          selectedColor: AppColors.accent,
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _config = _config.copyWith(gradientPreset: g));
                              _applyChange();
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // 6. Solid Backdrop Colors
                if (_config.reframeMode == AutoReframeMode.solidPillarbox) ...[
                  const Text('Backdrop Color', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final color in [0xFF000000, 0xFFFFFFFF, 0xFF141A29, 0xFF180B38, 0xFF880000, 0xFF004D40, 0xFF263238])
                        GestureDetector(
                          onTap: () {
                            setState(() => _config = _config.copyWith(backgroundColor: color));
                            _applyChange();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _config.backgroundColor == color ? AppColors.accent : AppColors.border,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // 7. Padding & Inset
                _buildSliderCard(
                  title: 'Frame Border Inset',
                  valueText: '${_config.framePadding.round()} px',
                  color: AppColors.accent,
                  value: _config.framePadding,
                  min: 0.0,
                  max: 36.0,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(framePadding: v));
                    _applyChange();
                  },
                ),

                const SizedBox(height: 8),

                // 8. Corner Curvature
                _buildSliderCard(
                  title: 'Corner Curvature',
                  valueText: '${_config.cornerRadius.round()} px',
                  color: AppColors.primary,
                  value: _config.cornerRadius,
                  min: 0.0,
                  max: 32.0,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(cornerRadius: v));
                    _applyChange();
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(AutoReframeMode mode) {
    switch (mode) {
      case AutoReframeMode.fitWithBlur:
        return Icons.blur_on;
      case AutoReframeMode.smartCrop:
        return Icons.crop_free;
      case AutoReframeMode.solidPillarbox:
        return Icons.check_box_outline_blank;
      case AutoReframeMode.gradientCanvas:
        return Icons.gradient;
    }
  }

  Decoration _buildMiniCanvasDecoration() {
    if (_config.reframeMode == AutoReframeMode.gradientCanvas) {
      final colors = _config.gradientPreset.colors.map((c) => Color(c)).toList();
      return BoxDecoration(
        gradient: LinearGradient(
          colors: colors.length >= 2 ? colors : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (_config.reframeMode == AutoReframeMode.solidPillarbox) {
      return BoxDecoration(
        color: Color(_config.backgroundColor),
      );
    } else {
      return const BoxDecoration(
        color: Color(0xFF11141A),
      );
    }
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
