import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../editor/providers/editor_provider.dart';

class CreativeStudioTab extends StatelessWidget {
  final ValueChanged<EditorTool> onToolSelected;

  const CreativeStudioTab({super.key, required this.onToolSelected});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8854D0), AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Creative Visual Studio',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cinema-grade color grading, canvas layouts, audio design & VFX tools.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Section 1: Visual Design & Canvas
        _buildSectionHeader('Canvas & Multi-Layouts'),
        _buildStudioGrid([
          _StudioCardItem(
            title: 'Cover & Thumbnails',
            subtitle: 'Photo covers, aspect ratios & text stickers',
            badge: 'CREATOR',
            icon: Icons.photo_size_select_actual_outlined,
            color: const Color(0xFFFDCB6E),
            tool: EditorTool.imageEditor,
          ),
          _StudioCardItem(
            title: 'Split Screen Collage',
            subtitle: '2x2, 1x2 & 3x1 multi-clip video grids',
            badge: 'MULTI-GRID',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF00CEC9),
            tool: EditorTool.splitScreen,
          ),
          _StudioCardItem(
            title: '3D Parallax Depth',
            subtitle: 'Dimensional zoom & depth animation',
            badge: 'CINEMATIC',
            icon: Icons.view_in_ar,
            color: const Color(0xFF6C5CE7),
            tool: EditorTool.parallax3D,
          ),
          _StudioCardItem(
            title: 'Doodle & Freehand',
            subtitle: 'Neon glowing pens, brushes & drawing',
            badge: 'DRAW',
            icon: Icons.draw,
            color: const Color(0xFFFF7675),
            tool: EditorTool.doodle,
          ),
        ]),

        // Section 2: Color Grading & Film Finishing
        _buildSectionHeader('Color Balancing & Film Finishing'),
        _buildStudioGrid([
          _StudioCardItem(
            title: 'Pro Color Wheels',
            subtitle: 'Lift, Gamma, Gain cinema 3-way balancing',
            badge: 'DAVINCI TIER',
            icon: Icons.donut_large,
            color: const Color(0xFFFFD700),
            tool: EditorTool.colorWheels,
          ),
          _StudioCardItem(
            title: 'RGB Spline Curves',
            subtitle: 'Luma & 4-channel parametric curve grading',
            badge: 'CURVES',
            icon: Icons.show_chart,
            color: const Color(0xFF00E5FF),
            tool: EditorTool.curves,
          ),
          _StudioCardItem(
            title: 'Film Grain Studio',
            subtitle: '35mm analog celluloid texture simulation',
            badge: 'TEXTURE',
            icon: Icons.grain,
            color: const Color(0xFFFF9F43),
            tool: EditorTool.filmGrain,
          ),
          _StudioCardItem(
            title: 'Vignette & Spotlight',
            subtitle: 'Atmospheric light falloff & shading',
            badge: 'LIGHTING',
            icon: Icons.blur_circular,
            color: const Color(0xFF20BF6B),
            tool: EditorTool.vignette,
          ),
        ]),

        // Section 3: Audio Design
        _buildSectionHeader('Audio Design & Production'),
        _buildStudioGrid([
          _StudioCardItem(
            title: 'Sound FX Library',
            subtitle: 'Whooshes, transitions, impacts & risers',
            badge: 'SFX',
            icon: Icons.speaker,
            color: const Color(0xFF00CEC9),
            tool: EditorTool.soundEffects,
          ),
          _StudioCardItem(
            title: 'Voiceover Studio',
            subtitle: 'High-fidelity live microphone recording',
            badge: 'MIC',
            icon: Icons.mic,
            color: const Color(0xFFFF5252),
            tool: EditorTool.audioRecord,
          ),
        ]),

        const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildStudioGrid(List<_StudioCardItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onToolSelected(item.tool),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.badge,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: item.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _StudioCardItem {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final EditorTool tool;

  const _StudioCardItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.tool,
  });
}
