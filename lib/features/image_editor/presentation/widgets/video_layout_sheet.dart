import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../models/video_layout_config.dart';

class VideoLayoutSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onSave;

  const VideoLayoutSheet({
    super.key,
    required this.project,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoLayoutSheet(project: project, onSave: onSave),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.aspect_ratio, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Video Layout & Canvas', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Preview Aspect Frame
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: _config.ratio.aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(_config.backgroundColor),
                    borderRadius: BorderRadius.circular(_config.cornerRadius),
                    border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video content box with padding
                      Padding(
                        padding: EdgeInsets.all(_config.framePadding),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_config.cornerRadius),
                          child: Container(
                            color: const Color(0xFF1E293B),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_circle_outline, color: AppColors.accent, size: 36),
                                  const SizedBox(height: 4),
                                  Text(
                                    _config.ratio.label,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_config.ratio.defaultWidth} × ${_config.ratio.defaultHeight}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Aspect Ratio Selector
                const Text('Canvas Aspect Ratio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in VideoLayoutRatio.values)
                      ChoiceChip(
                        label: Text(r.label, style: const TextStyle(fontSize: 11)),
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
                const SizedBox(height: 16),

                // Background Mode Selector
                const Text('Backdrop Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final mode in LayoutBackgroundMode.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(mode.label, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                            selected: _config.backgroundMode == mode,
                            selectedColor: AppColors.accent,
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _config = _config.copyWith(backgroundMode: mode));
                                _applyChange();
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Frame Padding
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Frame Border Inset', style: TextStyle(fontSize: 12)),
                    Text('${_config.framePadding.round()} px', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.framePadding,
                  min: 0.0,
                  max: 36.0,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(framePadding: v));
                    _applyChange();
                  },
                ),

                // Corner Radius
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Corner Curvature', style: TextStyle(fontSize: 12)),
                    Text('${_config.cornerRadius.round()} px', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.cornerRadius,
                  min: 0.0,
                  max: 32.0,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(cornerRadius: v));
                    _applyChange();
                  },
                ),

                // Color swatches (if solid background)
                if (_config.backgroundMode == LayoutBackgroundMode.solidColor) ...[
                  const SizedBox(height: 8),
                  const Text('Backdrop Color', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final color in [0xFF000000, 0xFFFFFFFF, 0xFF180B38, 0xFF003366, 0xFF880000, 0xFF222222])
                        GestureDetector(
                          onTap: () {
                            setState(() => _config = _config.copyWith(backgroundColor: color));
                            _applyChange();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _config.backgroundColor == color ? AppColors.accent : AppColors.border,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
