import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';
import 'tool_search_modal.dart';

/// CapCut-Style Two-Tier Contextual Dock with Dedicated AI Intelligence Suite.
/// Switches smoothly between:
/// 1. Global Navigation Dock (when no clip is selected) - 10 core categories + AI Suite + Search + More sheet
/// 2. Contextual Clip Action Dock (when a clip is selected) - Categorized filters + 16 primary tools + More sheet
class EditingToolbar extends StatefulWidget {
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
  State<EditingToolbar> createState() => _EditingToolbarState();
}

class _EditingToolbarState extends State<EditingToolbar> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final isClipSelected = widget.hasSelectedClip;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: isClipSelected ? 92 : 68,
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
          child: isClipSelected
              ? _buildContextualClipDock(context)
              : _buildGlobalCategoryDock(context),
        ),
      ),
    );
  }

  // --- 1. CONTEXTUAL CLIP DOCK (CLIP SELECTED) ---
  Widget _buildContextualClipDock(BuildContext context) {
    final allClipTools = [
      const _ToolItem(EditorTool.split, 'Split', Icons.content_cut, category: 'Edit'),
      const _ToolItem(EditorTool.speed, 'Speed', Icons.speed, category: 'Edit'),
      const _ToolItem(EditorTool.audio, 'Volume', Icons.volume_up_outlined, category: 'Audio'),
      const _ToolItem(EditorTool.clipWorkflow, 'AI Actions', Icons.auto_awesome, isAi: true, category: 'AI Studio'),
      const _ToolItem(EditorTool.chromaKey, 'Cutout', Icons.blur_linear, isAi: true, category: 'AI Studio'),
      const _ToolItem(EditorTool.keyframes, 'Animation', Icons.animation, category: 'Visuals'),
      const _ToolItem(EditorTool.kenBurns, 'Ken Burns', Icons.slow_motion_video, category: 'Visuals'),
      const _ToolItem(EditorTool.tracking, 'Tracking', Icons.my_location, isAi: true, category: 'AI Studio'),
      const _ToolItem(EditorTool.transform, 'Transform', Icons.crop_rotate, category: 'Visuals'),
      const _ToolItem(EditorTool.mask, 'Mask', Icons.masks, category: 'Visuals'),
      const _ToolItem(EditorTool.color, 'Filters', Icons.palette_outlined, category: 'Color'),
      const _ToolItem(EditorTool.curves, 'Adjust', Icons.show_chart, category: 'Color'),
      const _ToolItem(EditorTool.extractAudio, 'Extract Audio', Icons.music_note, category: 'Audio'),
      const _ToolItem(EditorTool.reverseClip, 'Reverse', Icons.replay, category: 'Edit'),
      const _ToolItem(EditorTool.freezeFrame, 'Freeze', Icons.ac_unit, category: 'Edit'),
      const _ToolItem(EditorTool.aiColorEnhance, 'AI Color', Icons.auto_awesome, isAi: true, category: 'Color'),
      const _ToolItem(EditorTool.aiSilenceRemover, 'AI Silence', Icons.content_cut, isAi: true, category: 'Audio'),
      const _ToolItem(EditorTool.aiSceneSplit, 'AI Scene Cut', Icons.movie_filter, isAi: true, category: 'Edit'),
      const _ToolItem(EditorTool.beatCut, 'Beat Cut', Icons.auto_awesome_motion, isAi: true, category: 'AI Studio'),
      const _ToolItem(EditorTool.audioFade, 'Audio Fade', Icons.graphic_eq, category: 'Audio'),
      const _ToolItem(EditorTool.impactFlash, 'Flash', Icons.flash_on, category: 'Visuals'),
      const _ToolItem(EditorTool.freezeClimax, 'Freeze Climax', Icons.ac_unit, category: 'Visuals'),
      const _ToolItem(EditorTool.speedEase, 'Bezier Ease', Icons.tune, category: 'Edit'),
      const _ToolItem(EditorTool.spatialPan, '8D Pan', Icons.headphones, category: 'Audio'),
      const _ToolItem(EditorTool.typewriterTitle, 'Typewriter', Icons.keyboard, category: 'Visuals'),
      const _ToolItem(EditorTool.crtScanline, 'CRT Scanlines', Icons.tv, category: 'Visuals'),
      const _ToolItem(EditorTool.reverbChamber, 'Reverb', Icons.surround_sound, category: 'Audio'),
      const _ToolItem(EditorTool.anamorphicFlare, 'Anamorphic Flare', Icons.lens_blur, category: 'Visuals'),
      const _ToolItem(EditorTool.filmHalation, 'Film Halation', Icons.blur_on, category: 'Visuals'),
      const _ToolItem(EditorTool.tapeCassette, 'Tape Cassette', Icons.album, category: 'Audio'),
      const _ToolItem(EditorTool.cameraShake, 'Camera Shake', Icons.vibration, category: 'Visuals'),
      const _ToolItem(EditorTool.lensDistortion, 'Lens Distortion', Icons.panorama_fish_eye, category: 'Visuals'),
      const _ToolItem(EditorTool.vinylRecord, 'Vinyl Record', Icons.album, category: 'Audio'),
      const _ToolItem(EditorTool.duplicateClip, 'Duplicate', Icons.control_point_duplicate, category: 'Edit'),
      const _ToolItem(EditorTool.deleteClip, 'Delete', Icons.delete_outline, category: 'Edit'),
    ];

    final filteredTools = _selectedCategory == 'All'
        ? allClipTools
        : allClipTools.where((t) => t.category == _selectedCategory).toList();

    return KeyedSubtree(
      key: const ValueKey('contextual_clip_dock'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Filter Category Bar on Top
          Container(
            height: 28,
            padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Quick Search Chip
                InkWell(
                  onTap: () => ToolSearchModal.show(context, onSelectTool: widget.onSelectTool),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 12, color: AppColors.accent),
                        SizedBox(width: 3),
                        Text(
                          'Find',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ...['All', 'Edit', 'AI Studio', 'Audio', 'Visuals', 'Color'].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Tools Action Bar on Bottom
          Expanded(
            child: Row(
              children: [
                // CapCut-Style Back Button
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4, top: 2, bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onDeselectClip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.accent),
                          SizedBox(height: 2),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),

                // Scrollable Tools matching active category
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    itemCount: filteredTools.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      if (index == filteredTools.length) {
                        return _buildMoreClipToolsButton(context);
                      }
                      final item = filteredTools[index];
                      final isSelected = widget.activeTool == item.tool;
                      return _buildToolTile(item, isSelected);
                    },
                  ),
                ),
              ],
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
      const _ToolItem(EditorTool.progressBar, 'Progress', Icons.linear_scale),
      const _ToolItem(EditorTool.highlight, 'Canvas', Icons.photo_filter_outlined),
    ];

    return KeyedSubtree(
      key: const ValueKey('global_category_dock'),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: globalTools.length + 4,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          // Dedicated Instant Tool Search Button
          if (index == 0) {
            return _buildSearchGlobalButton(context);
          }
          // Dedicated AI Suite button positioned after Text
          if (index == 4) {
            return _buildAiSuiteGlobalButton(context);
          }
          final adjustedIndex = index > 4 ? index - 2 : index - 1;

          if (adjustedIndex == globalTools.length) {
            return _buildMoreGlobalToolsButton(context);
          }
          if (adjustedIndex == globalTools.length + 1) {
            return _buildAddTrackButton();
          }

          final item = globalTools[adjustedIndex];
          final isSelected = widget.activeTool == item.tool;
          return _buildToolTile(item, isSelected);
        },
      ),
    );
  }

  Widget _buildSearchGlobalButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ToolSearchModal.show(context, onSelectTool: widget.onSelectTool),
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
            const Icon(Icons.search, size: 20, color: AppColors.accent),
            const SizedBox(height: 3),
            Text(
              'Search',
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
      onTap: () => widget.onSelectTool(item.tool),
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
      onTap: widget.onAddTrack,
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
                      EditorTool.aiSilenceRemover,
                      'Silence Jump-Cut',
                      Icons.content_cut,
                      badge: 'On-Device VAD',
                      subtitle: 'Auto Silence Trim',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.aiColorEnhance,
                      'AI Auto-Color',
                      Icons.auto_awesome,
                      badge: 'Rec.709 CV',
                      subtitle: 'Tone & Dynamic Range',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.aiSceneSplit,
                      'Scene Cut Detector',
                      Icons.movie_filter,
                      badge: 'Histogram CV',
                      subtitle: 'Auto Shot Splitter',
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
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.progressBar,
                      'Progress Bar',
                      Icons.linear_scale,
                      badge: 'Skia Studio',
                      subtitle: 'Retention Indicator',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.kenBurns,
                      'Ken Burns Motion',
                      Icons.slow_motion_video,
                      badge: 'Affine 2D',
                      subtitle: 'Pan & Zoom Drift',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.gapCloser,
                      'Gap Closer',
                      Icons.space_bar,
                      badge: 'Auto Ripple',
                      subtitle: 'Remove Black Gaps',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.beatCut,
                      'Beat Cutter',
                      Icons.auto_awesome_motion,
                      badge: 'Rhythm Sync',
                      subtitle: 'Auto Beat Cut',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.audioFade,
                      'Audio Fade',
                      Icons.graphic_eq,
                      badge: 'Anti-Pop',
                      subtitle: 'Volume Envelopes',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.impactFlash,
                      'Impact Flash',
                      Icons.flash_on,
                      badge: 'VFX Burst',
                      subtitle: 'Cut Strobe Accents',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.freezeClimax,
                      'Freeze Climax',
                      Icons.ac_unit,
                      badge: 'Action Hold',
                      subtitle: 'Punch Zoom Climax',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.speedEase,
                      'Bezier Speed',
                      Icons.tune,
                      badge: 'Optical',
                      subtitle: 'Velocity Curve',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.spatialPan,
                      '8D Spatial Pan',
                      Icons.headphones,
                      badge: 'Binaural',
                      subtitle: 'Headphone Orbit',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.typewriterTitle,
                      'Typewriter',
                      Icons.keyboard,
                      badge: 'Kinetic',
                      subtitle: 'Animated Titles',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.crtScanline,
                      'CRT Scanlines',
                      Icons.tv,
                      badge: 'Retro',
                      subtitle: 'Phosphor Display',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.reverbChamber,
                      'Reverb Chamber',
                      Icons.surround_sound,
                      badge: 'Acoustic',
                      subtitle: 'Spatial Room Hall',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.anamorphicFlare,
                      'Anamorphic Flare',
                      Icons.lens_blur,
                      badge: 'Cinema',
                      subtitle: 'Streak & Bloom',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.filmHalation,
                      'Film Halation',
                      Icons.blur_on,
                      badge: '35mm',
                      subtitle: 'Emulsion Bleed',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.tapeCassette,
                      'Tape Cassette',
                      Icons.album,
                      badge: 'Analog',
                      subtitle: 'Wow & Flutter',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.cameraShake,
                      'Camera Shake',
                      Icons.vibration,
                      badge: 'Optical',
                      subtitle: 'Handheld Tremor',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.lensDistortion,
                      'Lens Distortion',
                      Icons.panorama_fish_eye,
                      badge: 'Optics',
                      subtitle: 'Fisheye & Barrel',
                    ),
                    _buildSheetToolItem(
                      sheetContext,
                      EditorTool.vinylRecord,
                      'Vinyl Turntable',
                      Icons.album,
                      badge: 'Analog',
                      subtitle: 'Dust & Needle',
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
                    _buildSheetToolItem(sheetContext, EditorTool.audioFade, 'Audio Fade', Icons.graphic_eq, subtitle: 'Anti-Pop Envelopes'),
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
                    _buildSheetToolItem(sheetContext, EditorTool.progressBar, 'Progress Bar', Icons.linear_scale, subtitle: 'Retention Bar'),
                    _buildSheetToolItem(sheetContext, EditorTool.gapCloser, 'Gap Closer', Icons.space_bar, subtitle: 'Ripple Black Gaps'),
                    _buildSheetToolItem(sheetContext, EditorTool.impactFlash, 'Impact Flash', Icons.flash_on, subtitle: 'Cut Strobe & Burst'),
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
                    _buildSheetToolItem(sheetContext, EditorTool.beatCut, 'Beat Cut', Icons.auto_awesome_motion, badge: 'AI', subtitle: 'Rhythm Cut'),
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
                    _buildSheetToolItem(sheetContext, EditorTool.kenBurns, 'Ken Burns', Icons.slow_motion_video, subtitle: 'Photo Pan & Zoom'),
                    _buildSheetToolItem(sheetContext, EditorTool.impactFlash, 'Impact Flash', Icons.flash_on, subtitle: 'Cut Strobe & Burst'),
                    _buildSheetToolItem(sheetContext, EditorTool.anamorphicFlare, 'Anamorphic Flare', Icons.lens_blur, subtitle: 'Streak Bloom'),
                    _buildSheetToolItem(sheetContext, EditorTool.filmHalation, 'Film Halation', Icons.blur_on, subtitle: '35mm Glow'),
                    _buildSheetToolItem(sheetContext, EditorTool.cameraShake, 'Camera Shake', Icons.vibration, subtitle: 'Handheld Tremor'),
                    _buildSheetToolItem(sheetContext, EditorTool.lensDistortion, 'Lens Distortion', Icons.panorama_fish_eye, subtitle: 'Fisheye & Barrel'),
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
                    _buildSheetToolItem(sheetContext, EditorTool.audioFade, 'Audio Fade', Icons.graphic_eq, subtitle: 'Anti-Pop Envelopes'),
                    _buildSheetToolItem(sheetContext, EditorTool.tapeCassette, 'Tape Cassette', Icons.album, subtitle: 'Wow & Flutter'),
                    _buildSheetToolItem(sheetContext, EditorTool.vinylRecord, 'Vinyl Turntable', Icons.album, subtitle: 'Dust & Needle'),
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
        widget.onSelectTool(tool);
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
  final String category;

  const _ToolItem(this.tool, this.label, this.icon, {this.isAi = false, this.category = 'Edit'});
}
