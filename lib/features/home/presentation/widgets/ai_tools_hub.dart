import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../editor/providers/editor_provider.dart';

class _StudioToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final EditorTool tool;
  final bool isPro;
  final bool isAi;

  const _StudioToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tool,
    this.isPro = true,
    this.isAi = true,
  });
}

class AiToolsHub extends StatelessWidget {
  final ValueChanged<EditorTool> onToolSelected;

  const AiToolsHub({super.key, required this.onToolSelected});

  static const List<_StudioToolItem> _tools = [
    _StudioToolItem(
      title: 'Auto Captions',
      subtitle: 'Speech to animated subtitles',
      icon: Icons.subtitles,
      color: Color(0xFF00F0FF),
      tool: EditorTool.captions,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'AI Relight',
      subtitle: '3D studio light & sunbeams',
      icon: Icons.lightbulb_circle,
      color: Color(0xFFFFD700),
      tool: EditorTool.relight,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Voice Changer',
      subtitle: 'Timbre morphing & vocoder',
      icon: Icons.mic_external_on,
      color: Color(0xFFFF007F),
      tool: EditorTool.voiceEffects,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Video Glow',
      subtitle: 'Neon edge aura contour',
      icon: Icons.flare,
      color: Color(0xFF00E5FF),
      tool: EditorTool.edgeAura,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'De-Noise',
      subtitle: 'Low-light grain removal',
      icon: Icons.noise_control_off,
      color: Color(0xFF2ED573),
      tool: EditorTool.denoise,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Smart Cutout',
      subtitle: '1-tap background removal',
      icon: Icons.content_cut,
      color: Color(0xFFBD00FF),
      tool: EditorTool.chromaKey,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Vocal Isolation',
      subtitle: 'Acapella & karaoke isolate',
      icon: Icons.graphic_eq,
      color: Color(0xFF3867D6),
      tool: EditorTool.vocalIsolation,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Speed Ramp',
      subtitle: 'Optical-flow smooth curves',
      icon: Icons.speed,
      color: Color(0xFFFF7100),
      tool: EditorTool.speed,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Color Match',
      subtitle: 'AI tone palette transfer',
      icon: Icons.auto_fix_high,
      color: Color(0xFFFF3450),
      tool: EditorTool.colorMatch,
      isAi: true,
    ),
    _StudioToolItem(
      title: '8K Upscaler',
      subtitle: 'Lanczos super-resolution',
      icon: Icons.hd,
      color: Color(0xFF8E80E5),
      tool: EditorTool.enhance,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'AI Voiceover',
      subtitle: 'Text to speech synthesis',
      icon: Icons.spatial_audio_off,
      color: Color(0xFF00CEC9),
      tool: EditorTool.tts,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Photo Studio',
      subtitle: 'Cover & layout designer',
      icon: Icons.photo_library_outlined,
      color: Color(0xFFFDCB6E),
      tool: EditorTool.imageEditor,
      isPro: false,
      isAi: false,
    ),
    _StudioToolItem(
      title: 'Smart Mosaic',
      subtitle: 'Privacy & face blur',
      icon: Icons.blur_on,
      color: Color(0xFF00F0FF),
      tool: EditorTool.mosaic,
      isAi: true,
    ),
    _StudioToolItem(
      title: 'Teleprompter',
      subtitle: 'Live script & speech prompter',
      icon: Icons.subtitles_outlined,
      color: Color(0xFF00FF88),
      tool: EditorTool.teleprompter,
      isAi: true,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Split Screen',
      subtitle: 'Multi-grid video collage',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFBD00FF),
      tool: EditorTool.splitScreen,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Magic Eraser',
      subtitle: 'AI object & watermark removal',
      icon: Icons.auto_fix_high,
      color: Color(0xFFFF2D55),
      tool: EditorTool.objectRemoval,
      isAi: true,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'AI Face Reshape',
      subtitle: '3D facial sculpting & contour',
      icon: Icons.face,
      color: Color(0xFF00E5FF),
      tool: EditorTool.faceReshape,
      isAi: true,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Color Wheels',
      subtitle: 'Primary & Log color grading',
      icon: Icons.donut_large,
      color: Color(0xFFFFD700),
      tool: EditorTool.colorWheels,
      isAi: false,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Creative Doodle',
      subtitle: 'Freehand neon, pen & drawing',
      icon: Icons.draw,
      color: Color(0xFFFF2D55),
      tool: EditorTool.doodle,
      isAi: false,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'RGB Curves',
      subtitle: 'Luma & 4-channel spline grading',
      icon: Icons.show_chart,
      color: Color(0xFF00E5FF),
      tool: EditorTool.curves,
      isAi: false,
      isPro: true,
    ),
    _StudioToolItem(
      title: 'Film Grain',
      subtitle: 'Celluloid & analog particles',
      icon: Icons.grain,
      color: Color(0xFFFFB300),
      tool: EditorTool.filmGrain,
      isAi: false,
      isPro: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Edito AI Studio & Quick Tools',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: const Text(
                'PRO TIER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _tools[index];
              return InkWell(
                key: ValueKey('home_ai_tool_${item.tool.name}'),
                onTap: () => onToolSelected(item.tool),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.16),
                              shape: BoxShape.circle,
                              border: Border.all(color: item.color.withOpacity(0.5), width: 1.5),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          if (item.isAi)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
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
}
