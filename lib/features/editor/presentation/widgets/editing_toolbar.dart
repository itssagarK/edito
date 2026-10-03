import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';

/// CapCut-Style Two-Tier Contextual Dock with Dedicated AI Intelligence Suite.
/// Switches smoothly between:
/// 1. Global Navigation Dock (when no clip is selected) - 10 core categories + AI Suite + More sheet
/// 2. Contextual Clip Action Dock (when a clip is selected) - 16 primary tools + More sheet
class EditingToolbar extends StatelessWidget {
  final EditorTool activeTool;
  final bool hasSelectedClip;
  final Function(EditorTool) onSelectTool;
  final VoidCallback? onDeselectClip;
  final VoidCallback onAddTrack;

  const EditingToolbar({
    super.key,
    required this.activeTool,
    required this.hasSelectedClip,
    required this.onSelectTool,
    this.onDeselectClip,
    required this.onAddTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.25),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: hasSelectedClip
              ? _buildContextualClipDock(context)
              : _buildGlobalCategoryDock(context),
        ),
      ),
    );
  }

  // --- 1. CONTEXTUAL CLIP DOCK (CLIP SELECTED) ---
  Widget _buildContextualClipDock(BuildContext context) {
    final primaryClipTools = [
      const _ToolItem(EditorTool.split, 'Split', Icons.content_cut),
      const _ToolItem(EditorTool.speed, 'Speed', Icons.speed),
      const _ToolItem(EditorTool.audio, 'Volume', Icons.volume_up_outlined),
      const _ToolItem(EditorTool.clipWorkflow, 'AI Studio', Icons.auto_awesome, isAi: true),
      const _ToolItem(EditorTool.chromaKey, 'Cutout', Icons.blur_linear, isAi: true),
      const _ToolItem(EditorTool.keyframes, 'Animation', Icons.animation),
      const _ToolItem(EditorTool.tracking, 'Tracking', Icons.my_location, isAi: true),
      const _ToolItem(EditorTool.transform, 'Transform', Icons.crop_rotate),
      const _ToolItem(EditorTool.mask, 'Mask', Icons.masks),
      const _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      const _ToolItem(EditorTool.curves, 'Adjust', Icons.show_chart),
      const _ToolItem(EditorTool.extractAudio, 'Extract Audio', Icons.music_note),
      const _ToolItem(EditorTool.reverseClip, 'Reverse', Icons.replay),
      const _ToolItem(EditorTool.freezeFrame, 'Freeze', Icons.ac_unit),
      const _ToolItem(EditorTool.duplicateClip, 'Duplicate', Icons.control_point_duplicate),
      const _ToolItem(EditorTool.deleteClip, 'Delete', Icons.delete_outline),
    ];

    return KeyedSubtree(
      key: const ValueKey('contextual_clip_dock'),
      child: Row(
        children: [
          // CapCut-Style Back Button
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 8, bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDeselectClip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.accent),
                    const SizedBox(height: 3),
                    Text(
                      'Back',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),

          // Scrollable Primary Clip Action Items
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: primaryClipTools.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (index == primaryClipTools.length) {
                  return _buildMoreClipToolsButton(context);
                }
                final item = primaryClipTools[index];
                final isSelected = activeTool == item.tool;
                return _buildToolTile(item, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. GLOBAL CATEGORY DOCK (NO CLIP SELECTED) ---
  Widget _buildGlobalCategoryDock(BuildContext context) {
    final globalTools = [
      const _ToolItem(EditorTool.select, 'Edit', Icons.movie_creation_outlined),
      const _ToolItem(EditorTool.audio, 'Audio', Icons.music_note_outlined),
      const _ToolItem(EditorTool.text, 'Text', Icons.title),
      const _ToolItem(EditorTool.imageOverlay, 'Overlay', Icons.picture_in_picture_alt_outlined),
      const _ToolItem(EditorTool.vfx, 'Effects', Icons.auto_awesome_motion),
      const _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined),
      const _ToolItem(EditorTool.layout, 'Ratio', Icons.aspect_ratio),
      const _ToolItem(EditorTool.curves, 'Adjust', Icons.tune),
      const _ToolItem(EditorTool.highlight, 'Canvas', Icons.photo_filter_outlined),
    ];

    return KeyedSubtree(
      key: const ValueKey('global_category_dock'),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: globalTools.length + 3,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          // Dedicated AI Suite button positioned after Text
          if (index == 3) {
            return _buildAiSuiteGlobalButton(context);
          }
          final adjustedIndex = index > 3 ? index - 1 : index;

          if (adjustedIndex == globalTools.length) {
            return _buildMoreGlobalToolsButton(context);
          }
          if (adjustedIndex == globalTools.length + 1) {
            return _buildAddTrackButton();
          }

          final item = globalTools[adjustedIndex];
          final isSelected = activeTool == item.tool;
          return _buildToolTile(item, isSelected);
        },
      ),
    );
  }

  Widget _buildAiSuiteGlobalButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showGlobalAiSuiteSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.22),
              AppColors.accent.withOpacity(0.18),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.55),
            width: 1.1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: AppColors.accent,
                ),
                Positioned(
                  top: -4,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'AI Suite',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile(_ToolItem item, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onSelectTool(item.tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: isSelected
                      ? (item.isAi ? AppColors.accent : AppColors.primaryLight)
                      : (item.isAi ? AppColors.accent : AppColors.textPrimary),
                ),
                if (item.isAi)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : (item.isAi ? AppColors.accent : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreGlobalToolsButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showGlobalMoreToolsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_rounded, size: 20, color: AppColors.accent),
            const SizedBox(height: 3),
            Text(
              'More',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreClipToolsButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _showClipMoreToolsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.more_horiz, size: 20, color: AppColors.accent),
            const SizedBox(height: 3),
            Text(
              'More',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTrackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onAddTrack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 20, color: AppColors.textSecondary),
            const SizedBox(height: 3),
            Text(
              'Add Track',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. DEDICATED AI SUITE BOTTOM SHEET ---
  void _showGlobalAiSuiteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
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
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'On-Device AI Suite',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF20BF6B).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF20BF6B), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF20BF6B), size: 5),
                              SizedBox(width: 3),
                              Text(
                                '100% OFFLINE',
                                style: TextStyle(
                                  color: Color(0xFF20BF6B),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.captions,
                      'Auto Captions',
                      Icons.closed_caption,
                      badge: 'Whisper',
                      subtitle: 'Speech-to-Text',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.clipWorkflow,
                      'Silence Jump-Cut',
                      Icons.movie_filter_outlined,
                      badge: 'VAD',
                      subtitle: 'Auto Silence Trim',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.enhance,
                      '8K AI Upscale',
                      Icons.auto_awesome_motion,
                      badge: 'Real-ESRGAN',
                      subtitle: 'Neural Detail',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.tts,
                      'AI Voiceover',
                      Icons.record_voice_over,
                      badge: 'Neural TTS',
                      subtitle: 'Text to Speech',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.chromaKey,
                      'Smart Cutout',
                      Icons.blur_linear,
                      badge: 'MediaPipe',
                      subtitle: 'Selfie Segmenter',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.tracking,
                      'Motion Tracking',
                      Icons.my_location,
                      badge: 'Optical Flow',
                      subtitle: 'Lucas-Kanade',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.vocalIsolation,
                      'Vocal Isolation',
                      Icons.mic_none,
                      badge: 'Demucs',
                      subtitle: 'Voice & Music',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.denoise,
                      'Neural De-Noise',
                      Icons.noise_control_off,
                      badge: 'RNNoise',
                      subtitle: 'Spectral Clean',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.retouch,
                      'Face Retouch',
                      Icons.face_retouching_natural,
                      badge: 'AI Polish',
                      subtitle: 'Skin Smoothing',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.faceReshape,
                      'Face Reshape',
                      Icons.face,
                      badge: '3D Mesh',
                      subtitle: 'Contour Sculpt',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.teleprompter,
                      'Teleprompter',
                      Icons.subtitles_outlined,
                      badge: 'Creator',
                      subtitle: 'Auto Scroll',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.layout,
                      'Auto-Reframe',
                      Icons.aspect_ratio,
                      badge: 'Smart Center',
                      subtitle: 'Canvas Ratios',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 4. MORE GLOBAL TOOLS SHEET ---
  void _showGlobalMoreToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creative Suite',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionHeader('AI Intelligence & Speech'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.captions, 'Auto Captions', Icons.closed_caption, badge: 'AI', subtitle: 'Whisper STT'),
                    _buildSheetToolItem(sheetContext, EditorTool.tts, 'AI Voiceover', Icons.record_voice_over, badge: 'AI', subtitle: 'Speech Synth'),
                    _buildSheetToolItem(sheetContext, EditorTool.clipWorkflow, 'Smart Split', Icons.movie_filter_outlined, badge: 'AI', subtitle: 'Silence Cut'),
                    _buildSheetToolItem(sheetContext, EditorTool.teleprompter, 'Prompter', Icons.subtitles_outlined, subtitle: 'Studio Script'),
                    _buildSheetToolItem(sheetContext, EditorTool.enhance, '8K AI Boost', Icons.auto_awesome_motion, badge: 'AI', subtitle: 'Super Resolution'),
                    _buildSheetToolItem(sheetContext, EditorTool.hdConverter, 'HD Ultra', Icons.high_quality, subtitle: 'Pro Bitrate'),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('Audio & Narration Studio'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.audioRecord, 'Record Voice', Icons.mic, subtitle: 'Live Mic'),
                    _buildSheetToolItem(sheetContext, EditorTool.beats, 'Beat Sync', Icons.music_note, badge: 'AI', subtitle: 'Rhythm Snapping'),
                    _buildSheetToolItem(sheetContext, EditorTool.soundEffects, 'Sound FX', Icons.speaker, subtitle: 'Audio Library'),
                    _buildSheetToolItem(sheetContext, EditorTool.vocalIsolation, 'Stem Splitter', Icons.record_voice_over, badge: 'AI', subtitle: 'Isolate Vocals'),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSectionHeader('Canvas & Visual Design'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.imageEditor, 'Cover Maker', Icons.photo_size_select_actual_outlined, subtitle: 'Thumbnails'),
                    _buildSheetToolItem(sheetContext, EditorTool.splitScreen, 'Split Screen', Icons.grid_view_rounded, subtitle: 'Multi-Grid'),
                    _buildSheetToolItem(sheetContext, EditorTool.parallax3D, '3D Parallax', Icons.view_in_ar, subtitle: 'Depth Zoom'),
                    _buildSheetToolItem(sheetContext, EditorTool.doodle, 'Doodle Brush', Icons.draw, subtitle: 'Draw On Video'),
                    _buildSheetToolItem(sheetContext, EditorTool.colorWheels, 'Color Wheels', Icons.donut_large, subtitle: 'Lift/Gamma/Gain'),
                    _buildSheetToolItem(sheetContext, EditorTool.headerFooter, 'Header/Footer', Icons.vertical_align_top, subtitle: 'Letterbox Frame'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 5. MORE CLIP TOOLS SHEET ---
  void _showClipMoreToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Advanced Clip Studio',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Section 1: AI Intelligence & Smart Studio
                _buildSectionHeader('AI Intelligence & Smart Studio'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.clipWorkflow, 'Smart Actions', Icons.movie_filter_outlined, badge: 'AI', subtitle: 'Silence / Scene'),
                    _buildSheetToolItem(sheetContext, EditorTool.tracking, 'Motion Tracking', Icons.my_location, badge: 'AI', subtitle: 'Optical Flow'),
                    _buildSheetToolItem(sheetContext, EditorTool.retouch, 'Face Retouch', Icons.face_retouching_natural, badge: 'AI', subtitle: 'Skin Polish'),
                    _buildSheetToolItem(sheetContext, EditorTool.faceReshape, 'Face Reshape', Icons.face, badge: 'AI', subtitle: '3D Sculpt'),
                    _buildSheetToolItem(sheetContext, EditorTool.objectRemoval, 'Magic Eraser', Icons.auto_fix_high, badge: 'AI', subtitle: 'Remove Object'),
                    _buildSheetToolItem(sheetContext, EditorTool.relight, 'AI Relight', Icons.lightbulb_circle, badge: 'AI', subtitle: 'Studio Lighting'),
                    _buildSheetToolItem(sheetContext, EditorTool.stabilization, 'Stabilize', Icons.screen_lock_rotation, badge: 'AI', subtitle: 'Anti-Shake'),
                  ],
                ),
                const SizedBox(height: 14),

                // Section 2: Cinematic Visuals & VFX
                _buildSectionHeader('Cinematic Visuals & VFX'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.parallax3D, '3D Parallax', Icons.view_in_ar, subtitle: 'Depth Zoom'),
                    _buildSheetToolItem(sheetContext, EditorTool.blend, 'Blend Mode', Icons.layers, subtitle: 'Compositing'),
                    _buildSheetToolItem(sheetContext, EditorTool.smooth, 'Flow & Blur', Icons.waves, subtitle: 'Motion Blur'),
                    _buildSheetToolItem(sheetContext, EditorTool.borders, 'Border', Icons.border_outer, subtitle: 'Frames & Stroke'),
                    _buildSheetToolItem(sheetContext, EditorTool.splitScreen, 'Split Screen', Icons.grid_view_rounded, subtitle: 'Multi-Grid'),
                    _buildSheetToolItem(sheetContext, EditorTool.effects, 'Transitions', Icons.transform_outlined, subtitle: 'Wipes & Fades'),
                    _buildSheetToolItem(sheetContext, EditorTool.vfx, 'VFX Library', Icons.auto_awesome, subtitle: 'Visual FX'),
                    _buildSheetToolItem(sheetContext, EditorTool.characterZoom, 'Subject Zoom', Icons.center_focus_strong, subtitle: 'Character Focus'),
                  ],
                ),
                const SizedBox(height: 14),

                // Section 3: Audio & Voice Studio
                _buildSectionHeader('Audio & Voice Studio'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.vocalIsolation, 'Isolate Voice', Icons.record_voice_over, badge: 'AI', subtitle: 'Vocal Stem'),
                    _buildSheetToolItem(sheetContext, EditorTool.voiceEffects, 'Voice Effects', Icons.mic_external_on, subtitle: 'Pitch & FX'),
                    _buildSheetToolItem(sheetContext, EditorTool.denoise, 'Neural Denoise', Icons.noise_control_off, badge: 'AI', subtitle: 'RNNoise Clean'),
                    _buildSheetToolItem(sheetContext, EditorTool.soundEffects, 'Sound FX', Icons.speaker, subtitle: 'Audio Library'),
                    _buildSheetToolItem(sheetContext, EditorTool.audioRecord, 'Record Voice', Icons.mic, subtitle: 'Voiceover'),
                    _buildSheetToolItem(sheetContext, EditorTool.beats, 'Beat Sync', Icons.music_note, badge: 'AI', subtitle: 'Rhythm Snap'),
                  ],
                ),
                const SizedBox(height: 14),

                // Section 4: Color & Finishing
                _buildSectionHeader('Color & Finishing'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildSheetToolItem(sheetContext, EditorTool.colorWheels, 'Color Wheels', Icons.donut_large, subtitle: 'Lift/Gamma/Gain'),
                    _buildSheetToolItem(sheetContext, EditorTool.colorMatch, 'Color Match', Icons.auto_fix_high, badge: 'AI', subtitle: 'Tone Transfer'),
                    _buildSheetToolItem(sheetContext, EditorTool.filmGrain, 'Film Grain', Icons.grain, subtitle: 'Analog Texture'),
                    _buildSheetToolItem(sheetContext, EditorTool.vignette, 'Vignette', Icons.blur_circular, subtitle: 'Spotlight'),
                    _buildSheetToolItem(sheetContext, EditorTool.edgeAura, 'Edge Aura', Icons.flare, subtitle: 'Neon Glow'),
                    _buildSheetToolItem(sheetContext, EditorTool.mosaic, 'Mosaic Censor', Icons.blur_on, subtitle: 'Privacy Blur'),
                    _buildSheetToolItem(sheetContext, EditorTool.enhance, '8K Upscaler', Icons.auto_awesome_motion, badge: 'AI', subtitle: 'Detail Booster'),
                    _buildSheetToolItem(sheetContext, EditorTool.hdConverter, 'HD Ultra', Icons.high_quality, subtitle: 'Bitrate Master'),
                    _buildSheetToolItem(sheetContext, EditorTool.doodle, 'Doodle Brush', Icons.draw, subtitle: 'Freehand Draw'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _buildSheetToolItem(
    BuildContext sheetContext,
    EditorTool tool,
    String label,
    IconData icon, {
    String? badge,
    String? subtitle,
  }) {
    final isAi = badge == 'AI' || badge == 'Whisper' || badge == 'VAD' || badge == 'Real-ESRGAN' || badge == 'MediaPipe' || badge == 'Demucs' || badge == 'RNNoise';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pop(sheetContext);
        onSelectTool(tool);
      },
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAi ? AppColors.accent.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isAi
                        ? AppColors.accent.withOpacity(0.12)
                        : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isAi ? AppColors.accent : AppColors.primaryLight,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -3,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAi
                              ? [AppColors.primary, AppColors.accent]
                              : [AppColors.primaryLight, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final EditorTool tool;
  final String label;
  final IconData icon;
  final bool isAi;

  const _ToolItem(this.tool, this.label, this.icon, {this.isAi = false});
}
