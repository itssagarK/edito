import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../providers/editor_provider.dart';
import '../../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../../character_zoom/presentation/widgets/character_zoom_sheet.dart';
import '../../../chroma/presentation/widgets/chroma_key_sheet.dart';
import '../../../color_grading/presentation/widgets/color_grading_sheet.dart';
import '../../../enhancement/presentation/widgets/video_enhancement_sheet.dart';
import '../../../hd_converter/presentation/widgets/hd_converter_sheet.dart';
import '../../../highlight/presentation/widgets/character_highlight_sheet.dart';
import '../../../masking/presentation/widgets/mask_sheet.dart';
import '../../../blending/presentation/widgets/blend_mode_sheet.dart';
import '../../../keyframes/presentation/widgets/keyframe_studio_sheet.dart';
import '../../../timeline/presentation/widgets/clip_workflow_sheet.dart';
import '../../../image_editor/presentation/widgets/image_overlay_sheet.dart';
import '../../../image_editor/presentation/widgets/video_layout_sheet.dart';
import '../../../overlays/presentation/widgets/text_editor_sheet.dart';
import '../../../smoothing/presentation/widgets/video_smoother_sheet.dart';
import '../../../speed/presentation/widgets/speed_ramping_sheet.dart';
import '../../../vfx/presentation/widgets/vfx_studio_sheet.dart';
import '../../../beats/presentation/widgets/beat_detection_sheet.dart';
import '../../../tts/presentation/widgets/tts_voiceover_sheet.dart';

class DockedToolPanel extends StatelessWidget {
  final EditorTool tool;
  final Clip clip;
  final Project project;
  final Function(Clip updatedClip) onSaveClip;
  final Function(Project updatedProject) onSaveProject;
  final VoidCallback onClose;
  final VoidCallback onRevert;
  final VoidCallback onTogglePeek;
  final bool isPeekMode;

  const DockedToolPanel({
    super.key,
    required this.tool,
    required this.clip,
    required this.project,
    required this.onSaveClip,
    required this.onSaveProject,
    required this.onClose,
    required this.onRevert,
    required this.onTogglePeek,
    required this.isPeekMode,
  });

  String get _toolTitle {
    switch (tool) {
      case EditorTool.color:
        return 'Pro Color Grading';
      case EditorTool.hdConverter:
        return 'HD Video Converter';
      case EditorTool.characterZoom:
        return 'Main Character Zoom-In';
      case EditorTool.highlight:
        return 'Highlight & Background';
      case EditorTool.chromaKey:
        return 'Chroma Key Green Screen';
      case EditorTool.mask:
        return 'Multi-Shape Masking Studio';
      case EditorTool.blend:
        return 'Pro Blending Modes';
      case EditorTool.keyframes:
        return 'Universal Keyframe Studio';
      case EditorTool.clipWorkflow:
        return 'Clip Actions Studio';
      case EditorTool.speed:
        return 'Speed Ramping & Curve';
      case EditorTool.smooth:
        return 'Optical Flow & Motion Blur';
      case EditorTool.audio:
        return 'Audio Restoration & Mixer';
      case EditorTool.enhance:
        return '8K AI Detail Upscaler';
      case EditorTool.text:
        return 'Text & Motion Titles';
      case EditorTool.imageOverlay:
        return 'Picture-in-Picture (PiP)';
      case EditorTool.layout:
        return 'Auto-Reframe & Canvas Ratio';
      case EditorTool.vfx:
        return 'Cinematic Visual VFX';
      case EditorTool.beats:
        return 'Beats & Rhythm Snapping';
      case EditorTool.tts:
        return 'AI Voiceover & Narration';
      default:
        return tool.name.toUpperCase();
    }
  }

  IconData get _toolIcon {
    switch (tool) {
      case EditorTool.color:
        return Icons.palette_outlined;
      case EditorTool.hdConverter:
        return Icons.high_quality;
      case EditorTool.characterZoom:
        return Icons.center_focus_strong;
      case EditorTool.highlight:
        return Icons.person_pin_circle_outlined;
      case EditorTool.chromaKey:
        return Icons.blur_linear;
      case EditorTool.mask:
        return Icons.masks;
      case EditorTool.blend:
        return Icons.layers;
      case EditorTool.keyframes:
        return Icons.animation;
      case EditorTool.clipWorkflow:
        return Icons.movie_filter_outlined;
      case EditorTool.speed:
        return Icons.speed;
      case EditorTool.smooth:
        return Icons.waves;
      case EditorTool.audio:
        return Icons.mic_none;
      case EditorTool.enhance:
        return Icons.auto_awesome_motion;
      case EditorTool.text:
        return Icons.title;
      case EditorTool.imageOverlay:
        return Icons.picture_in_picture_alt_outlined;
      case EditorTool.layout:
        return Icons.aspect_ratio;
      case EditorTool.vfx:
        return Icons.auto_awesome;
      case EditorTool.beats:
        return Icons.music_note;
      case EditorTool.tts:
        return Icons.record_voice_over;
      default:
        return Icons.edit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Docked Header with Live Feedback Badge & Peek Mode Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(_toolIcon, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _toolTitle,
                          style: AppTypography.titleMedium.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            Icon(Icons.circle, color: Color(0xFF20BF6B), size: 6),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFF20BF6B),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Peek / Full View Toggle Button
                Tooltip(
                  message: 'Hide panel to view full video',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onTogglePeek,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('Peek', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Revert Button
                Tooltip(
                  message: 'Revert changes',
                  child: IconButton(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(28, 28),
                    ),
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
                    onPressed: onRevert,
                  ),
                ),

                const SizedBox(width: 4),

                // Done Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: onClose,
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Scrollable Tool Body
          Expanded(
            child: _buildToolContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolContent() {
    switch (tool) {
      case EditorTool.color:
        return ColorGradingSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(colorGrading: updatedClip.colorGrading)).toList();
                return track.copyWith(clips: updatedClips);
              }).toList();
              onSaveProject(project.copyWith(tracks: updatedTracks));
            } else {
              onSaveClip(updatedClip);
            }
          },
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.hdConverter:
        return HdConverterSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(hdConverter: updatedClip.hdConverter)).toList();
                return track.copyWith(clips: updatedClips);
              }).toList();
              onSaveProject(project.copyWith(tracks: updatedTracks));
            } else {
              onSaveClip(updatedClip);
            }
          },
          onDone: onClose,
        );

      case EditorTool.characterZoom:
        return CharacterZoomSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.highlight:
        return CharacterHighlightSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.chromaKey:
        return ChromaKeySheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.mask:
        return MaskSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(mask: updatedClip.mask)).toList();
                return track.copyWith(clips: updatedClips);
              }).toList();
              onSaveProject(project.copyWith(tracks: updatedTracks));
            } else {
              onSaveClip(updatedClip);
            }
          },
          onDone: onClose,
        );

      case EditorTool.blend:
        return BlendModeSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(blendMode: updatedClip.blendMode)).toList();
                return track.copyWith(clips: updatedClips);
              }).toList();
              onSaveProject(project.copyWith(tracks: updatedTracks));
            } else {
              onSaveClip(updatedClip);
            }
          },
          onDone: onClose,
        );

      case EditorTool.keyframes:
        return KeyframeStudioSheet(
          clip: clip,
          onSave: onSaveClip,
          onDone: onClose,
        );

      case EditorTool.clipWorkflow:
        return ClipWorkflowSheet(
          project: project,
          clip: clip,
          playheadPositionMs: clip.startTimeMs,
          onProjectChanged: onSaveProject,
          onDone: onClose,
        );

      case EditorTool.speed:
        return SpeedRampingSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.smooth:
        return VideoSmootherSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.audio:
        return AudioMixerSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.enhance:
        return VideoEnhancementSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.text:
        return TextEditorSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.imageOverlay:
        return ImageOverlaySheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.layout:
        return VideoLayoutSheet(
          project: project,
          onSave: onSaveProject,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.vfx:
        return VfxStudioSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.beats:
        return BeatDetectionSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
          currentPlayheadMs: clip.startTimeMs,
        );

      case EditorTool.tts:
        return TTSVoiceoverSheet(
          project: project,
          currentPlayheadMs: clip.startTimeMs,
          onProjectChanged: onSaveProject,
          isDocked: true,
          onDone: onClose,
        );

      default:
        return Center(
          child: Text(
            '${tool.name.toUpperCase()} editor ready',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
    }
  }
}
