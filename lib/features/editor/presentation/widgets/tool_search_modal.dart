import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';

class _SearchableTool {
  final EditorTool tool;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final bool isAi;
  final List<String> keywords;

  const _SearchableTool({
    required this.tool,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    this.isAi = false,
    required this.keywords,
  });
}

/// Instant tool search and quick launcher palette.
/// Allows creators to find any of the 58 editing tools in milliseconds
/// without endless scrolling.
class ToolSearchModal extends StatefulWidget {
  final Function(EditorTool) onSelectTool;

  const ToolSearchModal({
    super.key,
    required this.onSelectTool,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(EditorTool) onSelectTool,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ToolSearchModal(onSelectTool: onSelectTool),
    );
  }

  @override
  State<ToolSearchModal> createState() => _ToolSearchModalState();
}

class _ToolSearchModalState extends State<ToolSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _query = '';

  static const List<_SearchableTool> _catalog = [
    // --- EDIT & CUT ---
    _SearchableTool(
      tool: EditorTool.split,
      title: 'Split',
      category: 'Edit',
      description: 'Cut clip at playhead into two parts',
      icon: Icons.content_cut,
      keywords: ['split', 'cut', 'slice', 'divide', 'separate', 'scissors'],
    ),
    _SearchableTool(
      tool: EditorTool.trim,
      title: 'Trim',
      category: 'Edit',
      description: 'Trim in and out duration points',
      icon: Icons.content_cut_outlined,
      keywords: ['trim', 'crop', 'duration', 'shorten', 'length'],
    ),
    _SearchableTool(
      tool: EditorTool.speed,
      title: 'Speed & Curve',
      category: 'Edit',
      description: 'Speed ramping, slo-mo, velocity curves',
      icon: Icons.speed,
      keywords: ['speed', 'fast', 'slow', 'motion', 'slo-mo', 'velocity', 'curve', 'ramp', 'fps'],
    ),
    _SearchableTool(
      tool: EditorTool.freezeFrame,
      title: 'Freeze Frame',
      category: 'Edit',
      description: 'Pause video frame for 3s pause shot',
      icon: Icons.ac_unit,
      keywords: ['freeze', 'frame', 'pause', 'still', 'photo', 'hold'],
    ),
    _SearchableTool(
      tool: EditorTool.reverseClip,
      title: 'Reverse Playback',
      category: 'Edit',
      description: 'Play video & audio backward in reverse',
      icon: Icons.replay,
      keywords: ['reverse', 'rewind', 'backward', 'flip', 'backwards'],
    ),
    _SearchableTool(
      tool: EditorTool.duplicateClip,
      title: 'Duplicate',
      category: 'Edit',
      description: 'Clone clip onto timeline',
      icon: Icons.control_point_duplicate,
      keywords: ['duplicate', 'copy', 'clone', 'repeat'],
    ),
    _SearchableTool(
      tool: EditorTool.deleteClip,
      title: 'Delete',
      category: 'Edit',
      description: 'Remove clip and ripple timeline',
      icon: Icons.delete_outline,
      keywords: ['delete', 'remove', 'trash', 'clear'],
    ),

    // --- AI STUDIO ---
    _SearchableTool(
      tool: EditorTool.chromaKey,
      title: 'Smart Cutout & Chroma',
      category: 'AI Studio',
      description: 'MediaPipe selfie segmentation & green screen',
      icon: Icons.blur_linear,
      isAi: true,
      keywords: ['cutout', 'chroma', 'green screen', 'segmentation', 'background removal', 'key', 'mask', 'transparent'],
    ),
    _SearchableTool(
      tool: EditorTool.captions,
      title: 'Auto Captions (Whisper)',
      category: 'AI Studio',
      description: 'On-device Speech-to-Text subtitle generation',
      icon: Icons.closed_caption,
      isAi: true,
      keywords: ['captions', 'subtitles', 'whisper', 'speech', 'text', 'transcribe', 'srt', 'audio to text'],
    ),
    _SearchableTool(
      tool: EditorTool.aiColorEnhance,
      title: 'AI Auto-Color & Tone Intelligence',
      category: 'Color',
      description: '1-tap dynamic range, Gray World balance & vibrance optimization',
      icon: Icons.auto_awesome,
      isAi: true,
      keywords: ['ai color', 'auto color', 'balance', 'tone', 'auto tone', 'white balance', 'color enhance', 'exposure', 'hdr', 'vibrant'],
    ),
    _SearchableTool(
      tool: EditorTool.aiSilenceRemover,
      title: 'AI Silence Remover & Auto Jump-Cut',
      category: 'Audio',
      description: 'On-device VAD voice detection & dead-air pause excision',
      icon: Icons.content_cut,
      isAi: true,
      keywords: ['silence', 'vad', 'jump cut', 'auto cut', 'dead air', 'silence remover', 'cut silence', 'voice detect', 'speech'],
    ),
    _SearchableTool(
      tool: EditorTool.aiSceneSplit,
      title: 'AI Scene Cut & Shot Boundary Detector',
      category: 'Edit',
      description: 'Differential frame luminance and color histogram transition splitting',
      icon: Icons.movie_filter,
      isAi: true,
      keywords: ['scene', 'cut', 'shot', 'detect scenes', 'scene split', 'boundary', 'histogram', 'auto split'],
    ),
    _SearchableTool(
      tool: EditorTool.clipWorkflow,
      title: 'AI Smart Split & Silence Cut',
      category: 'AI Studio',
      description: 'VAD voice detection, auto silence trimming',
      icon: Icons.movie_filter_outlined,
      isAi: true,
      keywords: ['silence', 'vad', 'jump cut', 'smart split', 'dead air', 'cut silence', 'voice detect'],
    ),
    _SearchableTool(
      tool: EditorTool.enhance,
      title: '8K AI Upscale & Detail',
      category: 'AI Studio',
      description: 'Neural super resolution & Lanczos enhancement',
      icon: Icons.auto_awesome_motion,
      isAi: true,
      keywords: ['enhance', 'upscale', '8k', '4k', 'super resolution', 'quality', 'sharp', 'detail', 'esrgan'],
    ),
    _SearchableTool(
      tool: EditorTool.tracking,
      title: 'Motion Tracking',
      category: 'AI Studio',
      description: 'Lucas-Kanade optical flow feature tracking',
      icon: Icons.my_location,
      isAi: true,
      keywords: ['track', 'tracking', 'motion', 'follow', 'pin', 'anchor', 'optical flow'],
    ),
    _SearchableTool(
      tool: EditorTool.characterZoom,
      title: 'Auto Character Zoom',
      category: 'AI Studio',
      description: 'Auto-centering subject zoom & Kalman smoothing',
      icon: Icons.zoom_in_map,
      isAi: true,
      keywords: ['zoom', 'character', 'subject', 'face follow', 'center', 'crop'],
    ),
    _SearchableTool(
      tool: EditorTool.highlight,
      title: 'Character Highlight',
      category: 'AI Studio',
      description: 'Neon aura outline and spotlight effects',
      icon: Icons.photo_filter_outlined,
      isAi: true,
      keywords: ['highlight', 'aura', 'neon', 'outline', 'glow', 'spotlight', 'character'],
    ),
    _SearchableTool(
      tool: EditorTool.retouch,
      title: 'Face Retouch',
      category: 'AI Studio',
      description: 'Skin smoothing and face beauty polish',
      icon: Icons.face_retouching_natural,
      isAi: true,
      keywords: ['face', 'retouch', 'skin', 'beauty', 'smooth', 'blemish'],
    ),
    _SearchableTool(
      tool: EditorTool.faceReshape,
      title: 'Face Reshape',
      category: 'AI Studio',
      description: 'Facial contour sculpting and eye tuning',
      icon: Icons.face,
      isAi: true,
      keywords: ['reshape', 'contour', 'jaw', 'eyes', 'chin', 'mesh'],
    ),
    _SearchableTool(
      tool: EditorTool.objectRemoval,
      title: 'Magic Eraser (Object Removal)',
      category: 'AI Studio',
      description: 'Brush and remove unwanted objects from frame',
      icon: Icons.auto_fix_high,
      isAi: true,
      keywords: ['eraser', 'remove', 'inpaint', 'object', 'clean', 'brush'],
    ),

    // --- AUDIO & VOICE ---
    _SearchableTool(
      tool: EditorTool.audio,
      title: 'Volume & Audio Mixer',
      category: 'Audio',
      description: 'Gain slider, true-peak limiter, and ducking',
      icon: Icons.volume_up_outlined,
      keywords: ['volume', 'audio', 'sound', 'gain', 'loudness', 'mixer', 'mute', 'limiter'],
    ),
    _SearchableTool(
      tool: EditorTool.extractAudio,
      title: 'Extract Audio',
      category: 'Audio',
      description: 'Separate audio into dedicated sound track',
      icon: Icons.music_note,
      keywords: ['extract', 'separate', 'detach', 'mp3', 'sound track', 'isolate audio'],
    ),
    _SearchableTool(
      tool: EditorTool.beats,
      title: 'Beat Sync & Onset Snap',
      category: 'Audio',
      description: 'BPM rhythm detection and magnetic beat snapping',
      icon: Icons.graphic_eq,
      isAi: true,
      keywords: ['beat', 'rhythm', 'bpm', 'tempo', 'music', 'sync', 'onset', 'drop'],
    ),
    _SearchableTool(
      tool: EditorTool.denoise,
      title: 'Neural De-Noise (RNNoise)',
      category: 'Audio',
      description: 'Background hiss and hum reduction',
      icon: Icons.noise_control_off,
      isAi: true,
      keywords: ['denoise', 'noise', 'hiss', 'hum', 'clean audio', 'rnnoise', 'background sound'],
    ),
    _SearchableTool(
      tool: EditorTool.vocalIsolation,
      title: 'Vocal Isolation (Stem Split)',
      category: 'Audio',
      description: 'Separate vocals and background music',
      icon: Icons.mic_none,
      isAi: true,
      keywords: ['vocal', 'isolate', 'voice', 'singing', 'stems', 'acapella', 'instrumental'],
    ),
    _SearchableTool(
      tool: EditorTool.tts,
      title: 'AI Voiceover (TTS)',
      category: 'Audio',
      description: 'Neural text-to-speech voice narration',
      icon: Icons.record_voice_over,
      isAi: true,
      keywords: ['tts', 'voiceover', 'speech', 'narration', 'read', 'speak', 'voice'],
    ),
    _SearchableTool(
      tool: EditorTool.audioRecord,
      title: 'Audio Recorder',
      category: 'Audio',
      description: 'Record live voiceover microphone directly',
      icon: Icons.mic,
      keywords: ['record', 'mic', 'microphone', 'live voice', 'audio in'],
    ),
    _SearchableTool(
      tool: EditorTool.soundEffects,
      title: 'Sound Effects (SFX)',
      category: 'Audio',
      description: 'Motion whoosh, tactile clicks, and silence spacers',
      icon: Icons.speaker,
      keywords: ['sfx', 'sound effect', 'whoosh', 'click', 'spacer', 'foley'],
    ),

    // --- VISUALS & COMPOSITING ---
    _SearchableTool(
      tool: EditorTool.transform,
      title: 'Transform & Crop',
      category: 'Visuals',
      description: 'Spatial scale, rotation, and positioning',
      icon: Icons.crop_rotate,
      keywords: ['transform', 'scale', 'rotate', 'position', 'size', 'move', 'crop'],
    ),
    _SearchableTool(
      tool: EditorTool.keyframes,
      title: 'Keyframe Animation',
      category: 'Visuals',
      description: 'Custom motion path and parameter keyframing',
      icon: Icons.animation,
      keywords: ['keyframes', 'animation', 'animate', 'motion', 'curve', 'path'],
    ),
    _SearchableTool(
      tool: EditorTool.mask,
      title: 'Shape Masking',
      category: 'Visuals',
      description: 'Linear, radial, rectangle, and heart masks',
      icon: Icons.masks,
      keywords: ['mask', 'shape', 'linear', 'radial', 'feather', 'invert'],
    ),
    _SearchableTool(
      tool: EditorTool.blend,
      title: 'Blend Modes',
      category: 'Visuals',
      description: 'Screen, Multiply, Overlay, Darken compositor',
      icon: Icons.layers,
      keywords: ['blend', 'mode', 'screen', 'multiply', 'overlay', 'compositing', 'opacity'],
    ),
    _SearchableTool(
      tool: EditorTool.imageOverlay,
      title: 'Picture-in-Picture (PiP)',
      category: 'Visuals',
      description: 'Overlay images, logos, and secondary video clips',
      icon: Icons.picture_in_picture_alt_outlined,
      keywords: ['pip', 'overlay', 'picture in picture', 'sticker', 'logo', 'watermark'],
    ),
    _SearchableTool(
      tool: EditorTool.text,
      title: 'Text & Titles',
      category: 'Visuals',
      description: 'Curved text, kinetic typography, fonts',
      icon: Icons.title,
      keywords: ['text', 'title', 'font', 'typography', 'kinetic', 'heading'],
    ),
    _SearchableTool(
      tool: EditorTool.vfx,
      title: 'Video Effects (VFX)',
      category: 'Visuals',
      description: 'Glitch, neon, blur, and cinematic shaders',
      icon: Icons.auto_awesome_motion,
      keywords: ['vfx', 'effects', 'glitch', 'shake', 'flash', 'shaders'],
    ),
    _SearchableTool(
      tool: EditorTool.effects,
      title: 'Transitions',
      category: 'Visuals',
      description: 'Wipe, zoom, slide, and fade video transitions',
      icon: Icons.transform,
      keywords: ['transition', 'wipe', 'zoom', 'fade', 'cut transition', 'crossfade'],
    ),
    _SearchableTool(
      tool: EditorTool.doodle,
      title: 'Doodle Brush',
      category: 'Visuals',
      description: 'Draw freehand paths and annotations on video',
      icon: Icons.draw,
      keywords: ['doodle', 'draw', 'brush', 'paint', 'pen', 'sketch'],
    ),
    _SearchableTool(
      tool: EditorTool.splitScreen,
      title: 'Split Screen Layout',
      category: 'Visuals',
      description: 'Multi-frame vertical & horizontal video grids',
      icon: Icons.grid_view_rounded,
      keywords: ['split screen', 'grid', 'multi video', 'side by side', 'compare'],
    ),

    // --- COLOR & STYLE ---
    _SearchableTool(
      tool: EditorTool.color,
      title: 'Color Filters & Looks',
      category: 'Color',
      description: 'Cinematic looks, 4x5 GPU matrices',
      icon: Icons.palette_outlined,
      keywords: ['color', 'filter', 'lut', 'preset', 'looks', 'cinematic', 'teal and orange'],
    ),
    _SearchableTool(
      tool: EditorTool.curves,
      title: 'RGB Curves & Adjust',
      category: 'Color',
      description: 'RGB tonal curves, brightness, contrast, tint',
      icon: Icons.show_chart,
      keywords: ['curves', 'rgb', 'adjust', 'contrast', 'exposure', 'brightness', 'saturation'],
    ),
    _SearchableTool(
      tool: EditorTool.colorWheels,
      title: '3-Way Color Wheels',
      category: 'Color',
      description: 'Lift, Gamma, Gain professional color grading',
      icon: Icons.donut_large,
      keywords: ['wheels', 'lift', 'gamma', 'gain', 'shadows', 'midtones', 'highlights'],
    ),
    _SearchableTool(
      tool: EditorTool.filmGrain,
      title: 'Film Grain',
      category: 'Color',
      description: 'Organic 16mm / 35mm analogue texture',
      icon: Icons.grain,
      keywords: ['grain', 'film', 'texture', 'analog', 'vintage', 'noise'],
    ),
    _SearchableTool(
      tool: EditorTool.vignette,
      title: 'Vignette',
      category: 'Color',
      description: 'Radial edge darkening & softness framing',
      icon: Icons.vignette,
      keywords: ['vignette', 'edge', 'darken', 'frame', 'radial'],
    ),
    _SearchableTool(
      tool: EditorTool.layout,
      title: 'Canvas Ratio (Auto-Reframe)',
      category: 'Visuals',
      description: '9:16 TikTok, 16:9 YouTube, 1:1 Square, 4:5',
      icon: Icons.aspect_ratio,
      keywords: ['ratio', 'canvas', 'aspect', 'reframe', 'tiktok', 'reels', 'shorts', 'youtube'],
    ),
    _SearchableTool(
      tool: EditorTool.progressBar,
      title: 'Retention Progress Bar',
      category: 'Visuals',
      description: 'Real-time social video progress bar with glow and gradient styles',
      icon: Icons.linear_scale,
      keywords: ['progress', 'retention', 'bar', 'indicator', 'time', 'glow', 'gradient', 'reels', 'tiktok', 'social'],
    ),
    _SearchableTool(
      tool: EditorTool.kenBurns,
      title: 'Ken Burns Motion & Pan/Zoom',
      category: 'Visuals',
      description: 'Cinematic 2D photo motion, pan, and dynamic zoom animations',
      icon: Icons.slow_motion_video,
      keywords: ['ken burns', 'pan', 'zoom', 'motion', 'photo', 'drift', 'animation', 'camera'],
    ),
    _SearchableTool(
      tool: EditorTool.gapCloser,
      title: 'Timeline Gap Closer',
      category: 'Edit',
      description: 'Detect & ripple-close accidental black gaps and blank flashes',
      icon: Icons.space_bar,
      keywords: ['gap', 'closer', 'black frame', 'flash', 'blank', 'ripple', 'compact', 'timeline'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchableTool> get _filteredTools {
    return _catalog.where((tool) {
      if (_selectedCategory != 'All' && tool.category != _selectedCategory) {
        return false;
      }
      if (_query.trim().isEmpty) {
        return true;
      }
      final q = _query.toLowerCase().trim();
      if (tool.title.toLowerCase().contains(q)) return true;
      if (tool.description.toLowerCase().contains(q)) return true;
      if (tool.category.toLowerCase().contains(q)) return true;
      return tool.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredTools;
    final categories = ['All', 'Edit', 'AI Studio', 'Audio', 'Visuals', 'Color'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
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

            // Search Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search tools (e.g. split, speed, cutout, lut, voice)...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 18),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(24, 24),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _query = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Tools Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'No matching tools found for "$_query"',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching "split", "speed", "cutout", or "voice"',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectTool(item.tool);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: item.isAi ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: item.isAi ? AppColors.accent.withOpacity(0.4) : AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: item.isAi ? AppColors.accent : AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (item.isAi) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
                                                  fontSize: 7.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
