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
import '../../../cutout/presentation/widgets/smart_cutout_sheet.dart';
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
import '../../../tracking/presentation/widgets/motion_tracking_sheet.dart';
import '../../../retouch/presentation/widgets/face_retouch_sheet.dart';
import '../../../parallax_3d/presentation/widgets/parallax_3d_sheet.dart';
import '../../../stabilization/presentation/widgets/stabilization_sheet.dart';
import '../../../vocal_isolation/presentation/widgets/vocal_isolation_sheet.dart';
import '../../../color_match/presentation/widgets/color_match_sheet.dart';
import '../../../relight/presentation/widgets/relight_sheet.dart';
import '../../../denoise/presentation/widgets/denoise_sheet.dart';
import '../../../voice_effects/presentation/widgets/voice_effects_sheet.dart';
import '../../../edge_aura/presentation/widgets/edge_aura_sheet.dart';
import '../../../mosaic/presentation/widgets/mosaic_sheet.dart';
import '../../../teleprompter/presentation/widgets/teleprompter_sheet.dart';
import '../../../split_screen/presentation/widgets/split_screen_sheet.dart';
import '../../../object_removal/presentation/widgets/object_removal_sheet.dart';
import '../../../face_reshape/presentation/widgets/face_reshape_sheet.dart';
import '../../../color_wheels/presentation/widgets/color_wheels_studio_sheet.dart';
import '../../../doodle/presentation/widgets/doodle_studio_sheet.dart';
import '../../../curves/presentation/widgets/curves_studio_sheet.dart';
import '../../../film_grain/presentation/widgets/film_grain_studio_sheet.dart';
import '../../../vignette/models/vignette_config.dart';
import '../../../vignette/presentation/widgets/vignette_studio_sheet.dart';
import '../../../transitions/presentation/widgets/transition_selector_sheet.dart';
import '../../../transitions/models/transition_type.dart';
import '../../../audio/presentation/widgets/sound_effects_sheet.dart';
import '../../../audio/presentation/widgets/audio_recorder_sheet.dart';
import '../../../transform/presentation/widgets/transform_studio_sheet.dart';

class DockedToolPanel extends StatelessWidget {
  final EditorTool tool;
  final Clip clip;
  final Project project;
  final int playheadPositionMs;
  final ValueChanged<int>? onSeek;
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
    this.playheadPositionMs = 0,
    this.onSeek,
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
        return 'Smart AI Cutout Studio';
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
      case EditorTool.tracking:
        return 'Smart Motion Tracking';
      case EditorTool.retouch:
        return 'AI Face & Body Retouch';
      case EditorTool.parallax3D:
        return '3D Zoom & Parallax';
      case EditorTool.stabilization:
        return 'AI Video Stabilization';
      case EditorTool.vocalIsolation:
        return 'AI Vocal Isolation';
      case EditorTool.colorMatch:
        return 'AI Color Match';
      case EditorTool.relight:
        return 'AI Video Relight';
      case EditorTool.denoise:
        return 'AI Video De-Noise';
      case EditorTool.voiceEffects:
        return 'AI Voice Changer & Effects';
      case EditorTool.edgeAura:
        return 'AI Video Glow & Edge Aura';
      case EditorTool.mosaic:
        return 'Smart Mosaic & Privacy Censor';
      case EditorTool.teleprompter:
        return 'Creator Teleprompter Studio';
      case EditorTool.splitScreen:
        return 'Split Screen Collage Studio';
      case EditorTool.objectRemoval:
        return 'AI Magic Eraser & Object Removal';
      case EditorTool.faceReshape:
        return 'AI Face Reshape & 3D Sculpt';
      case EditorTool.colorWheels:
        return 'Pro Color Wheels Studio';
      case EditorTool.doodle:
        return 'Creative Doodle & Brush';
      case EditorTool.curves:
        return 'RGB Curves Studio';
      case EditorTool.filmGrain:
        return 'Cinematic Film Grain';
      case EditorTool.vignette:
        return 'Cinematic Vignette & Spotlight';
      case EditorTool.effects:
        return 'Cinematic Transitions';
      case EditorTool.soundEffects:
        return 'Sound Effects Studio';
      case EditorTool.transform:
        return 'Transform & Basic Edit';
      case EditorTool.deleteClip:
        return 'Delete Clip';
      case EditorTool.duplicateClip:
        return 'Duplicate Clip';
      case EditorTool.freezeFrame:
        return 'Freeze Frame';
      case EditorTool.reverseClip:
        return 'Reverse Playback';
      case EditorTool.extractAudio:
        return 'Extract Audio Track';
      case EditorTool.audioRecord:
        return 'Voiceover Studio';
      default:
        return tool.name.toUpperCase();
    }
  }

  IconData get _toolIcon {
    switch (tool) {
      case EditorTool.soundEffects:
        return Icons.music_note;
      case EditorTool.effects:
        return Icons.auto_awesome;
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
      case EditorTool.tracking:
        return Icons.my_location;
      case EditorTool.retouch:
        return Icons.face_retouching_natural;
      case EditorTool.parallax3D:
        return Icons.view_in_ar;
      case EditorTool.stabilization:
        return Icons.screen_lock_rotation;
      case EditorTool.vocalIsolation:
        return Icons.record_voice_over;
      case EditorTool.colorMatch:
        return Icons.auto_fix_high;
      case EditorTool.relight:
        return Icons.lightbulb_circle;
      case EditorTool.denoise:
        return Icons.noise_control_off;
      case EditorTool.voiceEffects:
        return Icons.mic_external_on;
      case EditorTool.edgeAura:
        return Icons.flare;
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
      case EditorTool.mosaic:
        return Icons.blur_on;
      case EditorTool.teleprompter:
        return Icons.subtitles_outlined;
      case EditorTool.splitScreen:
        return Icons.grid_view_rounded;
      case EditorTool.objectRemoval:
        return Icons.auto_fix_high;
      case EditorTool.faceReshape:
        return Icons.face;
      case EditorTool.colorWheels:
        return Icons.donut_large;
      case EditorTool.doodle:
        return Icons.draw;
      case EditorTool.curves:
        return Icons.show_chart;
      case EditorTool.filmGrain:
        return Icons.grain;
      case EditorTool.vignette:
        return Icons.blur_circular;
      case EditorTool.transform:
        return Icons.crop_rotate;
      case EditorTool.deleteClip:
        return Icons.delete_outline;
      case EditorTool.duplicateClip:
        return Icons.control_point_duplicate;
      case EditorTool.freezeFrame:
        return Icons.ac_unit;
      case EditorTool.reverseClip:
        return Icons.replay;
      case EditorTool.extractAudio:
        return Icons.music_note;
      case EditorTool.audioRecord:
        return Icons.mic;
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                  ),
                  child: Icon(_toolIcon, color: AppColors.accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _toolTitle,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                          Text('Peek', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Revert Button
                Tooltip(
                  message: 'Revert changes to initial state',
                  child: IconButton(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(5),
                      minimumSize: const Size(30, 30),
                    ),
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
                    onPressed: onRevert,
                  ),
                ),

                const SizedBox(width: 6),

                // Done Button with Electric Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF8854D0)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: onClose,
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
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
        return SmartCutoutSheet(
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
          currentPlayheadMs: playheadPositionMs,
          onSeek: onSeek,
          onSave: onSaveClip,
          onDone: onClose,
        );

      case EditorTool.clipWorkflow:
        return ClipWorkflowSheet(
          project: project,
          clip: clip,
          playheadPositionMs: playheadPositionMs > 0 ? playheadPositionMs : clip.startTimeMs,
          onProjectChanged: onSaveProject,
          onDone: onClose,
        );

      case EditorTool.audioRecord:
        return AudioRecorderSheet(
          project: project,
          currentPlayheadMs: playheadPositionMs,
          onProjectUpdated: onSaveProject,
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
          project: project,
          onSave: onSaveClip,
          onProjectChanged: onSaveProject,
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

      case EditorTool.tracking:
        return MotionTrackingSheet(
          project: project,
          targetClip: clip,
          onSave: onSaveProject,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.retouch:
        return FaceRetouchSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.parallax3D:
        return Parallax3DSheet(
          clip: clip,
          onSave: onSaveClip,
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.stabilization:
        return StabilizationSheet(
          initialConfig: clip.stabilization,
          onApply: (stabConfig) {
            onSaveClip(clip.copyWith(stabilization: stabConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.vocalIsolation:
        return VocalIsolationSheet(
          initialConfig: clip.vocalIsolation,
          onApply: (vocalConfig) {
            onSaveClip(clip.copyWith(vocalIsolation: vocalConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.colorMatch:
        final allVideoClips = project.tracks
            .where((t) => t.type == TrackType.video)
            .expand((t) => t.clips)
            .where((c) => c.id != clip.id)
            .toList();
        return ColorMatchSheet(
          initialConfig: clip.colorMatch,
          availableReferenceClips: allVideoClips,
          onApply: (colorMatchConfig) {
            onSaveClip(clip.copyWith(colorMatch: colorMatchConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.relight:
        return RelightSheet(
          initialConfig: clip.relight,
          onApply: (relightConfig) {
            onSaveClip(clip.copyWith(relight: relightConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.denoise:
        return DenoiseSheet(
          initialConfig: clip.denoise,
          onApply: (denoiseConfig) {
            onSaveClip(clip.copyWith(denoise: denoiseConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.voiceEffects:
        return VoiceEffectsSheet(
          initialConfig: clip.voiceEffects,
          onApply: (voiceConfig) {
            onSaveClip(clip.copyWith(voiceEffects: voiceConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.edgeAura:
        return EdgeAuraSheet(
          initialConfig: clip.edgeAura,
          onApply: (auraConfig) {
            onSaveClip(clip.copyWith(edgeAura: auraConfig));
          },
          isDocked: true,
          onClose: onClose,
        );

      case EditorTool.mosaic:
        return MosaicSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(mosaic: updatedClip.mosaic)).toList();
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

      case EditorTool.teleprompter:
        return TeleprompterSheet(
          config: project.teleprompter,
          onSave: (cfg) => onSaveProject(project.copyWith(teleprompter: cfg)),
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.splitScreen:
        return SplitScreenSheet(
          config: project.splitScreen,
          onSave: (cfg) => onSaveProject(project.copyWith(splitScreen: cfg)),
          isDocked: true,
          onDone: onClose,
        );

      case EditorTool.objectRemoval:
        return ObjectRemovalSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(objectRemoval: updatedClip.objectRemoval)).toList();
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

      case EditorTool.faceReshape:
        return FaceReshapeSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(faceReshape: updatedClip.faceReshape)).toList();
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

      case EditorTool.colorWheels:
        return ColorWheelsStudioSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(colorWheels: updatedClip.colorWheels)).toList();
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

      case EditorTool.doodle:
        return DoodleStudioSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(doodle: updatedClip.doodle)).toList();
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

      case EditorTool.curves:
        return CurvesStudioSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(curves: updatedClip.curves)).toList();
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

      case EditorTool.filmGrain:
        return FilmGrainStudioSheet(
          clip: clip,
          onSave: (updatedClip, {bool applyToAll = false}) {
            if (applyToAll) {
              final updatedTracks = project.tracks.map((track) {
                if (track.type != TrackType.video) return track;
                final updatedClips = track.clips.map((c) => c.copyWith(filmGrain: updatedClip.filmGrain)).toList();
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

      case EditorTool.vignette:
        return VignetteStudioSheet(
          initialConfig: clip.vignette,
          onChanged: (config) {
            onSaveClip(clip.copyWith(vignette: config));
          },
          onReset: () {
            onSaveClip(clip.copyWith(vignette: const VignetteConfig()));
          },
          onApplyToAll: () {
            final updatedTracks = project.tracks.map((track) {
              if (track.type != TrackType.video) return track;
              final updatedClips = track.clips.map((c) => c.copyWith(vignette: clip.vignette)).toList();
              return track.copyWith(clips: updatedClips);
            }).toList();
            onSaveProject(project.copyWith(tracks: updatedTracks));
          },
        );

      case EditorTool.effects:
        return TransitionSelectorSheet(
          clip: clip,
          onSave: onSaveClip,
          onApplyToAll: (transConfig) {
            final updatedTracks = project.tracks.map((track) {
              if (track.type != TrackType.video) return track;
              final updatedClips = track.clips.map((c) => c.copyWith(transitionIn: transConfig)).toList();
              return track.copyWith(clips: updatedClips);
            }).toList();
            onSaveProject(project.copyWith(tracks: updatedTracks));
          },
        );

      case EditorTool.soundEffects:
        return SoundEffectsSheet(
          project: project,
          playheadPositionMs: clip.startTimeMs,
          onSaveProject: onSaveProject,
          isDocked: true,
        );

      case EditorTool.transform:
        return TransformStudioSheet(
          clip: clip,
          onSave: onSaveClip,
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
