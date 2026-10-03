import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../audio/models/audio_effects_config.dart';
import '../../../audio/services/ai_voice_enhancer_service.dart';
import '../../../borders/models/video_border_config.dart';
import '../../../borders/services/video_border_compiler_service.dart';
import '../../../color_grading/models/color_grading_config.dart';
import '../../../color_grading/services/color_filter_compiler_service.dart';
import '../../../enhancement/models/video_enhancement_config.dart';
import '../../../character_zoom/models/character_zoom_config.dart';
import '../../../character_zoom/services/character_zoom_compiler_service.dart';
import '../../../chroma/models/chroma_key_config.dart';
import '../../../chroma/services/chroma_key_compiler_service.dart';
import '../../../chroma/presentation/widgets/chroma_key_preview_wrapper.dart';
import '../../../cutout/models/smart_cutout_config.dart';
import '../../../cutout/services/smart_cutout_compiler_service.dart';
import '../../../cutout/presentation/widgets/smart_cutout_preview_wrapper.dart';
import '../../../speed/models/auto_velocity_config.dart';
import '../../../speed/services/auto_velocity_service.dart';
import '../../../hd_converter/models/hd_converter_config.dart';
import '../../../hd_converter/services/hd_converter_service.dart';
import '../../../header_footer/models/header_footer_config.dart';
import '../../../header_footer/services/header_footer_compiler_service.dart';
import '../../../highlight/models/character_highlight_config.dart';
import '../../../highlight/services/character_highlight_compiler_service.dart';
import '../../../masking/models/mask_config.dart';
import '../../../masking/presentation/widgets/mask_clipper.dart';
import '../../../blending/models/blend_mode_config.dart';
import '../../../blending/presentation/widgets/blend_mode_wrapper.dart';
import '../../../keyframes/presentation/widgets/keyframe_transform_wrapper.dart';
import '../../../vfx/models/vfx_config.dart';
import '../../../vfx/services/vfx_compiler_service.dart';
import '../../../vfx/presentation/widgets/vfx_preview_wrapper.dart';
import '../../../../models/clip.dart';
import '../../../../models/media_asset.dart';
import '../../../overlays/models/text_overlay_config.dart';
import '../../../overlays/presentation/widgets/curved_text_painter.dart';
import '../../../overlays/services/overlay_compiler_service.dart';
import '../../../captions/models/caption_line.dart';
import '../../../captions/presentation/widgets/kinetic_caption_overlay.dart';
import '../../../tracking/models/motion_tracking_config.dart';
import '../../../tracking/services/motion_tracking_service.dart';
import '../../../retouch/models/face_retouch_config.dart';
import '../../../retouch/services/face_retouch_compiler_service.dart';
import '../../../parallax_3d/models/parallax_3d_config.dart';
import '../../../parallax_3d/services/parallax_3d_compiler_service.dart';
import '../../../stabilization/models/stabilization_config.dart';
import '../../../stabilization/services/stabilization_compiler_service.dart';
import '../../../color_match/models/color_match_config.dart';
import '../../../color_match/services/color_match_compiler_service.dart';
import '../../../relight/models/relight_config.dart';
import '../../../relight/services/relight_compiler_service.dart';
import '../../../denoise/models/denoise_config.dart';
import '../../../denoise/services/denoise_compiler_service.dart';
import '../../../voice_effects/models/voice_effects_config.dart';
import '../../../edge_aura/models/edge_aura_config.dart';
import '../../../edge_aura/services/edge_aura_compiler_service.dart';
import '../../../object_removal/models/object_removal_config.dart';
import '../../../object_removal/services/object_removal_compiler_service.dart';
import '../../../object_removal/presentation/widgets/object_removal_brush_overlay.dart';
import '../../../face_reshape/presentation/widgets/face_reshape_landmarks_overlay.dart';
import '../../../color_wheels/models/color_wheels_config.dart';
import '../../../color_wheels/services/color_wheels_compiler_service.dart';
import '../../../doodle/models/doodle_config.dart';
import '../../../doodle/services/doodle_compiler_service.dart';
import '../../../doodle/presentation/widgets/doodle_canvas_overlay.dart';
import '../../../curves/models/curves_config.dart';
import '../../../curves/services/curves_compiler_service.dart';
import '../../../film_grain/models/film_grain_config.dart';
import '../../../film_grain/services/film_grain_compiler_service.dart';
import '../../../film_grain/presentation/widgets/film_grain_preview_overlay.dart';
import '../../../vignette/models/vignette_config.dart';
import '../../../vignette/services/vignette_compiler_service.dart';
import '../../../vignette/presentation/widgets/vignette_preview_overlay.dart';
import '../../models/aspect_ratio_preset.dart';
import '../../models/compositor_frame.dart';
import '../../providers/preview_playback_provider.dart';
import '../../services/playback_clock_service.dart';
import '../../services/timeline_compositor_service.dart';
import '../../services/video_playback_bridge_service.dart';
import '../../../editor/providers/editor_provider.dart';
import '../../../image_editor/models/image_overlay_config.dart';
import '../../../image_editor/models/video_layout_config.dart';
import '../../../image_editor/services/auto_reframe_service.dart';
import '../../../image_editor/services/pip_compiler_service.dart';
import '../../../image_editor/presentation/widgets/pip_preview_overlay.dart';
import '../../../beats/services/beat_detector_service.dart';
import '../../../smoothing/models/video_smoother_config.dart';
import '../../../smoothing/services/ai_video_smoother_service.dart';
import '../../../smoothing/presentation/widgets/motion_blur_preview_wrapper.dart';
import '../../../transitions/models/transition_type.dart';
import '../../../transitions/presentation/widgets/transition_shader_painter.dart';
import 'interactive_transform_box.dart';

class RealtimePreviewViewport extends ConsumerWidget {
  final int currentPositionMs;
  final int totalDurationMs;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;

  const RealtimePreviewViewport({
    super.key,
    required this.currentPositionMs,
    required this.totalDurationMs,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onStepBackward,
    required this.onStepForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(previewPlaybackProvider);
    final editorState = ref.watch(editorProvider);
    final project = editorState.project;
    final layoutConfig = project?.layoutConfig ?? const VideoLayoutConfig();
    final layoutPreset = _mapLayoutRatioToPreset(layoutConfig.ratio);
    final activeRatio = previewState.aspectRatio != AspectRatioPreset.ratio16x9
        ? previewState.aspectRatio
        : layoutPreset;

    final currentFrame = previewState.currentFrame ??
        (project != null
            ? TimelineCompositorService.evaluateFrame(
                project,
                currentPositionMs,
                aspectRatio: activeRatio,
              )
            : null);

    return Column(
      children: [
        // Aspect Ratio & Guide Overlay Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Aspect ratio selector
              PopupMenuButton<AspectRatioPreset>(
                tooltip: 'Select Aspect Ratio',
                color: AppColors.surfaceElevated,
                initialValue: activeRatio,
                onSelected: (ratio) {
                  ref.read(previewPlaybackProvider.notifier).setAspectRatio(ratio);
                  final proj = ref.read(editorProvider).project;
                  if (proj != null) {
                    final mapped = _mapPresetToLayoutRatio(ratio);
                    final updated = proj.copyWith(
                      layoutConfig: proj.layoutConfig.copyWith(ratio: mapped),
                      width: mapped.defaultWidth,
                      height: mapped.defaultHeight,
                    );
                    ref.read(editorProvider.notifier).updateProject(updated);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(activeRatio.icon, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        activeRatio.label.split(' ').first,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
                itemBuilder: (context) => AspectRatioPreset.values.map((preset) {
                  return PopupMenuItem(
                    value: preset,
                    child: Row(
                      children: [
                        Icon(preset.icon, size: 16, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text(preset.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // Safe Zone & Center Grid Toggle
              IconButton(
                icon: Icon(
                  previewState.showSafeGuides ? Icons.grid_on : Icons.grid_off_outlined,
                  size: 18,
                  color: previewState.showSafeGuides ? AppColors.accent : AppColors.textMuted,
                ),
                onPressed: () {
                  ref.read(previewPlaybackProvider.notifier).toggleSafeGuides();
                },
                tooltip: 'Toggle Safe Area Guides',
              ),
            ],
          ),
        ),

        // Video Render Canvas with dynamic AspectRatio fitting
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: activeRatio.ratio,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ref.read(editorProvider.notifier).clearSelection();
                    },
                    child: Container(
                      decoration: _buildCanvasDecoration(layoutConfig),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                        // 0. Cloned Blurred Video Background (TikTok/Shorts/Reels Signature Look)
                        if (layoutConfig.isBlurFill && currentFrame != null && currentFrame.hasVisualContent)
                          Positioned.fill(
                            child: ClipRect(
                              child: ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: layoutConfig.blurIntensity * 0.75,
                                  sigmaY: layoutConfig.blurIntensity * 0.75,
                                  tileMode: TileMode.mirror,
                                ),
                                child: Transform.scale(
                                  scale: 1.45,
                                  child: Opacity(
                                    opacity: 0.65,
                                    child: _buildVisualContent(
                                      context,
                                      ref,
                                      currentFrame,
                                      layoutConfig: layoutConfig,
                                      isBackdropClone: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 1. Primary Visual Content framed with layout padding & corner radius
                        Padding(
                          padding: EdgeInsets.all(layoutConfig.framePadding),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(layoutConfig.cornerRadius),
                            child: _buildVisualContent(context, ref, currentFrame, layoutConfig: layoutConfig),
                          ),
                        ),

                        // 2. Picture-in-Picture & Creative Asset Badges / Image Overlays on Primary Clip
                        if (currentFrame?.primaryVideoClip != null && currentFrame!.primaryVideoClip!.imageOverlay.isEnabled)
                          _buildImageOverlayWidget(context, ref, currentFrame.primaryVideoClip!, currentFrame.primaryVideoClip!.imageOverlay),

                        // 3. Live Video Transition In Animation Overlay
                        if (currentFrame?.primaryVideoClip != null)
                          _buildTransitionOverlay(currentFrame!.primaryVideoClip!, currentPositionMs),

                        // 4. Multi-Track Overlays (Text Titles, Captions, PiP, Badges, Stickers)
                        if (currentFrame != null && currentFrame.activeOverlays.isNotEmpty)
                          ...currentFrame.activeOverlays.expand((overlayClip) {
                            final widgets = <Widget>[];

                            // Check if this overlay is pinned to a tracking source or has its own tracking
                            Clip? trackingSource;
                            if (overlayClip.motionTracking.isEnabled) {
                              trackingSource = overlayClip;
                            } else if (currentFrame.primaryVideoClip != null &&
                                currentFrame.primaryVideoClip!.motionTracking.isEnabled &&
                                currentFrame.primaryVideoClip!.motionTracking.pinnedOverlayId == overlayClip.id) {
                              trackingSource = currentFrame.primaryVideoClip;
                            }

                            final trackingOffsetMs = trackingSource != null
                                ? (currentPositionMs - trackingSource.startTimeMs)
                                : 0;

                            if (overlayClip.imageOverlay.isEnabled) {
                              final effectiveImage = (trackingSource != null && trackingSource.motionTracking.trajectory.isNotEmpty)
                                  ? MotionTrackingService.applyTrackingToImageOverlay(
                                      overlayClip.imageOverlay,
                                      trackingSource.motionTracking,
                                      trackingOffsetMs,
                                    )
                                  : overlayClip.imageOverlay;
                              widgets.add(_buildImageOverlayWidget(context, ref, overlayClip, effectiveImage));
                            }
                            if (overlayClip.textOverlay.text.trim().isNotEmpty) {
                              final offsetMs = currentPositionMs - overlayClip.startTimeMs;
                              var evaluatedText = OverlayCompilerService.evaluateOverlayAt(overlayClip, offsetMs);

                              if (trackingSource != null && trackingSource.motionTracking.trajectory.isNotEmpty) {
                                evaluatedText = MotionTrackingService.applyTrackingToText(
                                  evaluatedText,
                                  trackingSource.motionTracking,
                                  trackingOffsetMs,
                                );
                              }

                              if (evaluatedText.animationType == TextAnimationType.karaoke ||
                                  overlayClip.kineticCaptions.isEnabled ||
                                  overlayClip.trackId.toLowerCase().contains('caption') ||
                                  overlayClip.id.toLowerCase().contains('caption')) {
                                final captionLine = CaptionLine.fromClip(
                                  overlayClip.copyWith(textOverlay: evaluatedText),
                                );
                                widgets.add(KineticCaptionOverlay(
                                  caption: captionLine,
                                  offsetMs: offsetMs,
                                ));
                              } else {
                                widgets.add(_buildTextOverlayWidget(
                                  context,
                                  ref,
                                  overlayClip,
                                  evaluatedText,
                                  clipOffsetMs: offsetMs,
                                  clipDurationMs: overlayClip.durationMs,
                                ));
                              }
                            }
                            return widgets;
                          }),

                        // Interactive AI Object Removal & Magic Eraser Pen Canvas Overlay
                        if (editorState.activeTool == EditorTool.objectRemoval && currentFrame?.primaryVideoClip != null)
                          Positioned.fill(
                            child: ObjectRemovalBrushOverlay(
                              config: currentFrame!.primaryVideoClip!.objectRemoval,
                              onConfigChanged: (newConfig) {
                                final targetClip = currentFrame.primaryVideoClip!;
                                final updatedClip = targetClip.copyWith(objectRemoval: newConfig);
                                if (project != null) {
                                  final updatedProject = project.updateClip(updatedClip);
                                  ref.read(editorProvider.notifier).updateProject(updatedProject);
                                }
                              },
                            ),
                          ),

                        // Interactive AI Face Reshape & 3D Feature Sculpting Mesh Overlay
                        if (editorState.activeTool == EditorTool.faceReshape && currentFrame?.primaryVideoClip != null)
                          Positioned.fill(
                            child: FaceReshapeLandmarksOverlay(
                              config: currentFrame!.primaryVideoClip!.faceReshape,
                              onConfigChanged: (newConfig) {
                                final targetClip = currentFrame.primaryVideoClip!;
                                final updatedClip = targetClip.copyWith(faceReshape: newConfig);
                                if (project != null) {
                                  final updatedProject = project.updateClip(updatedClip);
                                  ref.read(editorProvider.notifier).updateProject(updatedProject);
                                }
                              },
                            ),
                          ),

                        // Interactive Creative Brush & Doodle Drawing Canvas Overlay
                        if (editorState.activeTool == EditorTool.doodle && currentFrame?.primaryVideoClip != null)
                          Positioned.fill(
                            child: DoodleCanvasOverlay(
                              config: currentFrame!.primaryVideoClip!.doodle,
                              onConfigChanged: (newConfig) {
                                final targetClip = currentFrame.primaryVideoClip!;
                                final updatedClip = targetClip.copyWith(doodle: newConfig);
                                if (project != null) {
                                  final updatedProject = project.updateClip(updatedClip);
                                  ref.read(editorProvider.notifier).updateProject(updatedProject);
                                }
                              },
                            ),
                          ),

                        // Interactive On-Canvas Video Transform & Spatial Gestures Overlay
                        if (editorState.activeTool == EditorTool.transform && currentFrame?.primaryVideoClip != null)
                          Positioned.fill(
                            child: InteractiveTransformBox(
                              isSelected: true,
                              positionX: currentFrame!.primaryVideoClip!.transform.positionX,
                              positionY: currentFrame!.primaryVideoClip!.transform.positionY,
                              scale: currentFrame!.primaryVideoClip!.transform.scale,
                              rotation: currentFrame!.primaryVideoClip!.transform.rotationDegrees.toDouble(),
                              onPositionChanged: (newX, newY) {
                                final targetClip = currentFrame.primaryVideoClip!;
                                final updatedTransform = targetClip.transform.copyWith(
                                  positionX: newX,
                                  positionY: newY,
                                );
                                final updatedClip = targetClip.copyWith(transform: updatedTransform);
                                if (project != null) {
                                  final updatedProject = project.updateClip(updatedClip);
                                  ref.read(editorProvider.notifier).updateProject(updatedProject);
                                }
                              },
                              onTransformChanged: (newScale, newRot) {
                                final targetClip = currentFrame.primaryVideoClip!;
                                final updatedTransform = targetClip.transform.copyWith(
                                  scale: newScale.clamp(0.2, 4.0),
                                  rotationDegrees: (newRot.round() % 360 + 360) % 360,
                                );
                                final updatedClip = targetClip.copyWith(transform: updatedTransform);
                                if (project != null) {
                                  final updatedProject = project.updateClip(updatedClip);
                                  ref.read(editorProvider.notifier).updateProject(updatedProject);
                                }
                              },
                              onDelete: () {
                                final targetClip = currentFrame.primaryVideoClip!;
                                ref.read(editorProvider.notifier).deleteClip(targetClip.id);
                              },
                              onDuplicate: () {
                                final targetClip = currentFrame.primaryVideoClip!;
                                ref.read(editorProvider.notifier).duplicateClip(targetClip.id);
                              },
                              child: Container(
                                width: 140,
                                height: 90,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.accent.withOpacity(0.08),
                                ),
                                child: const Center(
                                  child: Icon(Icons.crop_rotate, color: AppColors.accent, size: 28),
                                ),
                              ),
                            ),
                          ),

                        // Safe-Zone Grid Overlays (90% action safe, 80% title safe)
                        if (previewState.showSafeGuides)
                          const IgnorePointer(
                            child: CustomPaint(
                              painter: _SafeGuidesPainter(),
                            ),
                          ),

                        // Overlay Timecode Badge
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              TimecodeFormatter.formatSmpte(currentPositionMs),
                              style: AppTypography.timecode.copyWith(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),

        // Transport Playback Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimecodeFormatter.formatMilliseconds(currentPositionMs),
                style: AppTypography.timecode,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_5, size: 22),
                    onPressed: onStepBackward,
                    tooltip: '-5s',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: onTogglePlay,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.forward_5, size: 22),
                    onPressed: onStepForward,
                    tooltip: '+5s',
                  ),
                ],
              ),
              Text(
                TimecodeFormatter.formatMilliseconds(totalDurationMs),
                style: AppTypography.timecode.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisualContent(
    BuildContext context,
    WidgetRef ref,
    CompositorFrame? frame, {
    VideoLayoutConfig? layoutConfig,
    bool isBackdropClone = false,
  }) {
    if (frame == null || !frame.hasVisualContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 42,
              color: AppColors.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No visual clip at ${TimecodeFormatter.formatMilliseconds(frame?.timestampMs ?? 0)}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final clip = frame.primaryVideoClip!;
    final asset = frame.primaryAsset;
    final bool isPlayable = asset != null && VideoPlaybackBridgeService.isPlayablePath(asset.path);
    final bool needsColorFilter = !ColorFilterCompilerService.isIdentity(
      clip.colorGrading,
      chromaKey: clip.chromaKey,
      enhancement: clip.enhancement,
    );

    Widget contentWidget;

    if (isPlayable && asset.type == MediaType.image) {
      // 1. Real photo / image rendering from disk or network
      final fitMode = (isBackdropClone || layoutConfig?.isSmartCrop == true) ? BoxFit.cover : BoxFit.contain;
      final alignment = (layoutConfig?.isSmartCrop == true && !isBackdropClone)
          ? Alignment(layoutConfig?.focalPointX ?? 0.0, layoutConfig?.focalPointY ?? 0.0)
          : Alignment.center;

      if (asset.path.startsWith('http://') || asset.path.startsWith('https://')) {
        contentWidget = Image.network(
          asset.path,
          fit: fitMode,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderContent(frame, clip, asset),
        );
      } else {
        contentWidget = Image.file(
          File(asset.path),
          fit: fitMode,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderContent(frame, clip, asset),
        );
      }
    } else if (isPlayable && asset.type == MediaType.video) {
      // 2. Real Hardware Video Texture playback via VideoPlayer
      final bridge = ref.watch(videoPlaybackBridgeServiceProvider);
      contentWidget = ValueListenableBuilder<VideoPlayerController?>(
        valueListenable: bridge.activeVideoController,
        builder: (context, controller, child) {
          if (controller != null && controller.value.isInitialized && !controller.value.hasError) {
            final double videoRatio = controller.value.aspectRatio > 0
                ? controller.value.aspectRatio
                : (asset.width > 0 && asset.height > 0 ? asset.width / asset.height : frame.aspectRatio.ratio);

            if (isBackdropClone) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: ui.Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width > 0 ? controller.value.size.width : 1920,
                    height: controller.value.size.height > 0 ? controller.value.size.height : 1080,
                    child: VideoPlayer(controller),
                  ),
                ),
              );
            }

            if (layoutConfig?.isSmartCrop == true) {
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment(layoutConfig?.focalPointX ?? 0.0, layoutConfig?.focalPointY ?? 0.0),
                  clipBehavior: ui.Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.size.width > 0 ? controller.value.size.width : 1920,
                    height: controller.value.size.height > 0 ? controller.value.size.height : 1080,
                    child: VideoPlayer(controller),
                  ),
                ),
              );
            }

            return Center(
              child: AspectRatio(
                aspectRatio: videoRatio,
                child: ClipRect(
                  child: Container(
                    color: Colors.black,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            );
          }
          return _buildPlaceholderContent(frame, clip, asset, isLoading: true);
        },
      );
    } else {
      // 3. Fallback placeholder / seeded sample canvas
      contentWidget = _buildPlaceholderContent(frame, clip, asset);
    }

    Widget videoContent = needsColorFilter
        ? ColorFiltered(
            colorFilter: ColorFilter.matrix(
              ColorFilterCompilerService.compileColorMatrix(
                clip.colorGrading,
                chromaKey: clip.chromaKey,
                enhancement: clip.enhancement,
              ),
            ),
            child: contentWidget,
          )
        : contentWidget;

    if (clip.retouch.isEnabled) {
      videoContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          FaceRetouchCompilerService.generateColorFilterMatrix(clip.retouch),
        ),
        child: videoContent,
      );
    }

    if (clip.colorMatch.isEnabled && clip.colorMatch.intensity > 0.0) {
      videoContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorMatchCompilerService.calculateColorMatrix(clip.colorMatch),
        ),
        child: videoContent,
      );
    }

    if (clip.relight.isEnabled && clip.relight.mode != RelightMode.none && clip.relight.intensity > 0.0) {
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RelightCompilerService.buildLightingOverlay(
                  clip.relight,
                  Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            ),
          ),
        ],
      );
    }

    if (clip.denoise.isEnabled && clip.denoise.level != DenoiseLevel.none && clip.denoise.lowLightBoost > 0.0) {
      videoContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          DenoiseCompilerService.calculateColorMatrix(clip.denoise),
        ),
        child: videoContent,
      );
    }

    if (clip.colorWheels.isActive) {
      videoContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          ColorWheelsCompilerService.generate4x5ColorMatrix(clip.colorWheels),
        ),
        child: videoContent,
      );
    }

    if (clip.curves.isActive) {
      videoContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          CurvesCompilerService.compileSkiaMatrix(clip.curves),
        ),
        child: videoContent,
      );
    }

    if (clip.edgeAura.isEnabled && clip.edgeAura.style != EdgeGlowStyle.none && clip.edgeAura.intensity > 0.0) {
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return EdgeAuraCompilerService.buildAuraOverlay(
                  clip.edgeAura,
                  Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            ),
          ),
        ],
      );
    }

    if (clip.objectRemoval.isActive && clip.objectRemoval.showMaskOverlay) {
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  final maskPath = ObjectRemovalCompilerService.buildMaskPath(clip.objectRemoval, size);
                  return CustomPaint(
                    size: size,
                    painter: _StaticMaskPainter(
                      path: maskPath,
                      color: Color(clip.objectRemoval.maskColorValue),
                      opacity: clip.objectRemoval.opacity,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    if (clip.doodle.isActive) {
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return CustomPaint(
                    size: size,
                    painter: _StaticDoodlePainter(config: clip.doodle),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    if (clip.filmGrain.isActive) {
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: FilmGrainPreviewOverlay(
              config: clip.filmGrain,
              seed: currentPositionMs ~/ 40,
            ),
          ),
        ],
      );
    }

    if (clip.vignette.hasActiveVignette) {
      final activeTool = ref.watch(editorProvider.select((s) => s.activeTool));
      final selectedClipId = ref.watch(editorProvider.select((s) => s.selectedClipId));
      final isVignetteToolActive = activeTool == EditorTool.vignette && selectedClipId == clip.id;

      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: VignettePreviewOverlay(
              config: clip.vignette,
              showReticle: isVignetteToolActive,
              onCenterChanged: isVignetteToolActive
                  ? (newOffset) {
                      final updatedClip = clip.copyWith(
                        vignette: clip.vignette.copyWith(
                          centerX: newOffset.dx,
                          centerY: newOffset.dy,
                        ),
                      );
                      final project = ref.read(editorProvider).project;
                      if (project != null) {
                        ref.read(editorProvider.notifier).updateProject(project.updateClip(updatedClip));
                      }
                    }
                  : null,
            ),
          ),
        ],
      );
    }

    if (clip.colorGrading.vignette > 0.0) {
      final vignetteIntensity = clip.colorGrading.vignette.clamp(0.0, 1.0);
      videoContent = Stack(
        fit: StackFit.passthrough,
        children: [
          videoContent,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(vignetteIntensity * 0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (clip.characterZoom.isEnabled) {
      final currentClipTimeMs = frame.sourceFrameTimeMs - clip.sourceInMs;
      final currentScale = CharacterZoomCompilerService.calculateCurrentScale(
        clip.characterZoom,
        currentClipTimeMs: currentClipTimeMs > 0 ? currentClipTimeMs : 0,
        clipDurationMs: clip.durationMs,
      );
      final cx = clip.characterZoom.characterCenterX;
      final cy = clip.characterZoom.characterCenterY;

      videoContent = ClipRect(
        child: Transform.scale(
          scale: currentScale,
          alignment: Alignment((cx - 0.5) * 2.0, (cy - 0.5) * 2.0),
          child: videoContent,
        ),
      );

      if (clip.characterZoom.addSubjectAura) {
        videoContent = ColorFiltered(
          colorFilter: ColorFilter.matrix(
            ColorFilterCompilerService.compileColorMatrix(
              const ColorGradingConfig(contrast: 1.08, saturation: 1.20),
            ),
          ),
          child: videoContent,
        );
      }

      if (clip.characterZoom.addFocusVignette) {
        videoContent = Stack(
          fit: StackFit.passthrough,
          children: [
            videoContent,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment((cx - 0.5) * 2.0, (cy - 0.5) * 2.0),
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    if (clip.parallax3d.isEnabled && clip.parallax3d.style != Parallax3DStyle.none) {
      final currentClipTimeMs = (frame.sourceFrameTimeMs - clip.sourceInMs).clamp(0, clip.durationMs);
      final progress = clip.durationMs > 0 ? (currentClipTimeMs / clip.durationMs).clamp(0.0, 1.0) : 0.0;
      final matrix = Parallax3DCompilerService.computePreviewMatrix(clip.parallax3d, progress);
      final blur = Parallax3DCompilerService.computePreviewBlur(clip.parallax3d, progress);

      Widget transformed = Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: videoContent,
      );

      if (blur > 0.05) {
        transformed = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: transformed,
        );
      }

      videoContent = ClipRect(child: transformed);
    }

    if (clip.stabilization.isEnabled && clip.stabilization.level != StabilizationLevel.none) {
      final currentClipTimeMs = (frame.sourceFrameTimeMs - clip.sourceInMs).clamp(0, clip.durationMs);
      final progress = clip.durationMs > 0 ? (currentClipTimeMs / clip.durationMs).clamp(0.0, 1.0) : 0.0;
      final stabMatrix = StabilizationCompilerService.computePreviewTransform(clip.stabilization, progress);

      videoContent = Transform(
        transform: stabMatrix,
        alignment: Alignment.center,
        child: ClipRect(child: videoContent),
      );
    }

    if (clip.chromaKey.isEnabled) {
      videoContent = ChromaKeyPreviewWrapper(
        config: clip.chromaKey,
        child: videoContent,
      );
    }

    if (clip.smartCutout.isEnabled) {
      videoContent = SmartCutoutPreviewWrapper(
        config: clip.smartCutout,
        child: videoContent,
      );
    }

    if (clip.autoVelocity.isEnabled) {
      final clipOffsetMs = (frame.sourceFrameTimeMs - clip.sourceInMs).clamp(0, clip.durationMs);
      final zoom = AutoVelocityService.calculateMicroZoom(
        clipOffsetMs,
        clip.beatConfig.beatTimestampsMs,
        clip.autoVelocity,
      );
      if (zoom > 1.001) {
        videoContent = Transform.scale(
          scale: zoom,
          child: videoContent,
        );
      }

      final flashOpacity = AutoVelocityService.calculateFlashOpacity(
        clipOffsetMs,
        clip.beatConfig.beatTimestampsMs,
        clip.autoVelocity,
      );
      if (flashOpacity > 0.01) {
        videoContent = Stack(
          fit: StackFit.passthrough,
          children: [
            videoContent,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withOpacity(flashOpacity),
                ),
              ),
            ),
          ],
        );
      }
    }

    if (clip.mask.isActive) {
      videoContent = MaskPreviewWrapper(
        config: clip.mask,
        child: videoContent,
      );
    }

    if (clip.blendMode.isEnabled) {
      videoContent = BlendModeWrapper(
        config: clip.blendMode,
        child: videoContent,
      );
    }

    if (clip.keyframes.isNotEmpty) {
      final clipOffsetMs = (frame.sourceFrameTimeMs - clip.sourceInMs).clamp(0, clip.durationMs);
      videoContent = KeyframeTransformWrapper(
        clip: clip,
        clipOffsetMs: clipOffsetMs,
        child: videoContent,
      );
    }

    if (clip.transform.isActive) {
      final rad = clip.transform.rotationDegrees * math.pi / 180.0;
      final scaleX = (clip.transform.isFlippedHorizontal ? -1.0 : 1.0) * clip.transform.scale;
      final scaleY = (clip.transform.isFlippedVertical ? -1.0 : 1.0) * clip.transform.scale;

      videoContent = FractionalTranslation(
        translation: Offset(clip.transform.positionX - 0.5, clip.transform.positionY - 0.5),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(rad)
            ..scale(scaleX, scaleY, 1.0),
          child: videoContent,
        ),
      );
    }

    if (clip.vfx.isActive) {
      videoContent = VfxPreviewWrapper(
        config: clip.vfx,
        playheadPositionMs: frame.sourceFrameTimeMs,
        child: videoContent,
      );
    }

    if (clip.smoother.isMotionBlurEnabled ||
        clip.smoother.effectiveInterpolationMode == MotionInterpolationMode.frameBlend) {
      videoContent = MotionBlurPreviewWrapper(
        config: clip.smoother,
        child: videoContent,
      );
    }

    // Blurred clone backdrop returns pure video without overlays or HUD
    if (isBackdropClone) {
      return videoContent;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        videoContent,
        if (clip.characterHighlight.isEnabled)
          _buildCharacterHighlightOverlay(clip.characterHighlight),
        if (clip.border.isEnabled)
          _buildVideoBorderOverlay(clip.border),
        if (clip.headerFooter.hasActiveOverlay)
          _buildHeaderFooterOverlay(clip.headerFooter),
      ],
    );
  }

  Widget _buildPlaceholderContent(CompositorFrame frame, Clip clip, MediaAsset? asset, {bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E272E), Color(0xFF0F141C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
              )
            else
              Icon(
                Icons.play_circle_filled,
                size: 48,
                color: AppColors.primaryLight.withOpacity(0.8),
              ),
            const SizedBox(height: 8),
            Text(
              asset?.fileName ?? 'Clip ${clip.id.substring(0, 4)}',
              style: AppTypography.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Source frame: ${TimecodeFormatter.formatMilliseconds(frame.sourceFrameTimeMs)} (${clip.speed}x)',
              style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _resolveOverlayTextStyle(TextOverlayConfig config) {
    final name = config.fontFamily.trim().toLowerCase().replaceAll(' ', '');
    final weight = config.isBold ? FontWeight.w800 : FontWeight.w500;
    final fontStyle = config.isItalic ? FontStyle.italic : FontStyle.normal;
    final decoration = config.isUnderline ? TextDecoration.underline : TextDecoration.none;
    final spacing = config.letterSpacing;
    final color = Color(config.textColor);

    try {
      switch (name) {
        case 'anton':
          return GoogleFonts.anton(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'bebasneue':
          return GoogleFonts.bebasNeue(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'montserrat':
          return GoogleFonts.montserrat(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'poppins':
          return GoogleFonts.poppins(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'oswald':
          return GoogleFonts.oswald(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'jetbrainsmono':
          return GoogleFonts.jetBrainsMono(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'caveat':
          return GoogleFonts.caveat(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'pacifico':
          return GoogleFonts.pacifico(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'permanentmarker':
          return GoogleFonts.permanentMarker(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'roboto':
          return GoogleFonts.roboto(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'inter':
        default:
          return GoogleFonts.inter(fontSize: config.fontSize, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
      }
    } catch (_) {
      return TextStyle(
        fontFamily: config.fontFamily,
        fontSize: config.fontSize,
        fontWeight: weight,
        fontStyle: fontStyle,
        decoration: decoration,
        letterSpacing: spacing,
        color: color,
      );
    }
  }

  Widget _buildTextOverlayWidget(
    BuildContext context,
    WidgetRef ref,
    Clip overlayClip,
    TextOverlayConfig config, {
    int clipOffsetMs = 0,
    int clipDurationMs = 2500,
  }) {
    if (config.text.trim().isEmpty) return const SizedBox.shrink();

    // 1. Process Text Transformation (e.g. ALL CAPS)
    String fullText = config.isUppercase ? config.text.toUpperCase() : config.text;
    String displayText = fullText;

    // 2. Evaluate Dynamic Animation Parameters
    double animScale = 1.0;
    double animOpacity = 1.0;
    double animOffsetY = 0.0;

    final progress = clipDurationMs > 0 ? (clipOffsetMs / clipDurationMs).clamp(0.0, 1.0) : 1.0;

    switch (config.animationType) {
      case TextAnimationType.none:
        break;

      case TextAnimationType.fadeIn:
        if (clipOffsetMs < 300) {
          animOpacity = (clipOffsetMs / 300.0).clamp(0.0, 1.0);
        } else if (clipDurationMs - clipOffsetMs < 200) {
          animOpacity = ((clipDurationMs - clipOffsetMs) / 200.0).clamp(0.0, 1.0);
        }
        break;

      case TextAnimationType.popScale:
        if (clipOffsetMs < 280) {
          final t = (clipOffsetMs / 280.0).clamp(0.0, 1.0);
          animScale = t < 0.6 ? (t / 0.6) * 1.25 : 1.25 - ((t - 0.6) / 0.4) * 0.25;
          animOpacity = (t * 2.0).clamp(0.0, 1.0);
        }
        break;

      case TextAnimationType.bounce:
        if (clipOffsetMs < 360) {
          final t = (clipOffsetMs / 360.0).clamp(0.0, 1.0);
          animScale = 1.0 + 0.35 * math.sin(t * 3.14159);
          animOpacity = (t * 2.5).clamp(0.0, 1.0);
        }
        break;

      case TextAnimationType.slideUp:
        if (clipOffsetMs < 300) {
          final t = (clipOffsetMs / 300.0).clamp(0.0, 1.0);
          final ease = 1.0 - math.pow(1.0 - t, 2.0);
          animOffsetY = (1.0 - ease) * 28.0;
          animOpacity = t;
        }
        break;

      case TextAnimationType.zoomIn:
        if (clipOffsetMs < 350) {
          final t = (clipOffsetMs / 350.0).clamp(0.0, 1.0);
          animScale = 0.5 + 0.5 * t;
          animOpacity = t;
        }
        break;

      case TextAnimationType.shimmer:
        final tSec = clipOffsetMs / 1000.0;
        animScale = 1.0 + 0.03 * math.sin(tSec * 6.28);
        animOpacity = 0.88 + 0.12 * math.cos(tSec * 6.28);
        break;

      case TextAnimationType.karaoke:
        final phase = ((clipOffsetMs % 500) / 500.0);
        animScale = 1.0 + 0.07 * math.sin(phase * 3.14159);
        break;

      case TextAnimationType.typewriter:
        final typeDur = (clipDurationMs * 0.70).clamp(500, 3000).toDouble();
        final t = (clipOffsetMs / typeDur).clamp(0.0, 1.0);
        final visibleCount = (t * fullText.length).ceil().clamp(0, fullText.length);
        displayText = fullText.substring(0, visibleCount);
        break;
    }

    final effectiveScale = (config.scale * animScale).clamp(0.1, 5.0);
    final effectiveOpacity = (config.opacity * animOpacity).clamp(0.0, 1.0);

    final selectedClipId = ref.watch(editorProvider.select((s) => s.selectedClipId));
    final isSelected = selectedClipId == overlayClip.id;

    return InteractiveTransformBox(
      isSelected: isSelected,
      positionX: config.positionX,
      positionY: config.positionY,
      scale: effectiveScale,
      rotation: config.rotation,
      onTap: () {
        ref.read(editorProvider.notifier).selectClip(overlayClip.id);
      },
      onDoubleTap: () {
        ref.read(editorProvider.notifier).selectClip(overlayClip.id);
        ref.read(editorProvider.notifier).setActiveTool(EditorTool.text);
      },
      onDelete: () {
        ref.read(editorProvider.notifier).deleteClip(overlayClip.id);
      },
      onDuplicate: () {
        ref.read(editorProvider.notifier).duplicateClip(overlayClip.id);
      },
      onEdit: () {
        ref.read(editorProvider.notifier).selectClip(overlayClip.id);
        ref.read(editorProvider.notifier).setActiveTool(EditorTool.text);
      },
      onPositionChanged: (newX, newY) {
        final project = ref.read(editorProvider).project;
        if (project == null) return;
        final updatedConfig = config.copyWith(positionX: newX, positionY: newY);
        final updatedClip = overlayClip.copyWith(textOverlay: updatedConfig);
        ref.read(editorProvider.notifier).updateProject(project.updateClip(updatedClip));
      },
      onTransformChanged: (newScale, newRot) {
        final project = ref.read(editorProvider).project;
        if (project == null) return;
        final updatedConfig = config.copyWith(scale: newScale, rotation: newRot);
        final updatedClip = overlayClip.copyWith(textOverlay: updatedConfig);
        ref.read(editorProvider.notifier).updateProject(project.updateClip(updatedClip));
      },
      child: Transform.translate(
        offset: Offset(0, animOffsetY),
        child: Opacity(
          opacity: effectiveOpacity,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: config.boxPadding,
              vertical: config.boxPadding * 0.45,
            ),
            decoration: BoxDecoration(
              color: config.backgroundColor != null ? Color(config.backgroundColor!) : Colors.transparent,
              borderRadius: BorderRadius.circular(config.boxCornerRadius),
            ),
            child: Builder(
              builder: (context) {
                final baseStyle = _resolveOverlayTextStyle(config);
                return CurvedTextWidget(
                  config: config,
                  baseStyle: baseStyle,
                  displayText: displayText,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOverlayWidget(
    BuildContext context,
    WidgetRef ref,
    Clip overlayClip,
    ImageOverlayConfig config,
  ) {
    if (!config.isEnabled) return const SizedBox.shrink();

    final selectedClipId = ref.watch(editorProvider.select((s) => s.selectedClipId));
    final isSelected = selectedClipId == overlayClip.id;

    return InteractiveTransformBox(
      isSelected: isSelected,
      positionX: config.positionX,
      positionY: config.positionY,
      scale: config.scale,
      rotation: config.rotation,
      onTap: () {
        ref.read(editorProvider.notifier).selectClip(overlayClip.id);
      },
      onDelete: () {
        ref.read(editorProvider.notifier).deleteClip(overlayClip.id);
      },
      onDuplicate: () {
        ref.read(editorProvider.notifier).duplicateClip(overlayClip.id);
      },
      onPositionChanged: (newX, newY) {
        final project = ref.read(editorProvider).project;
        if (project == null) return;
        final updatedConfig = config.copyWith(positionX: newX, positionY: newY);
        final updatedClip = overlayClip.copyWith(imageOverlay: updatedConfig);
        ref.read(editorProvider.notifier).updateProject(project.updateClip(updatedClip));
      },
      onTransformChanged: (newScale, newRot) {
        final project = ref.read(editorProvider).project;
        if (project == null) return;
        final updatedConfig = config.copyWith(scale: newScale, rotation: newRot);
        final updatedClip = overlayClip.copyWith(imageOverlay: updatedConfig);
        ref.read(editorProvider.notifier).updateProject(project.updateClip(updatedClip));
      },
      child: PipPreviewOverlay(config: config),
    );
  }

  Widget _buildTransitionOverlay(Clip clip, int currentPositionMs) {
    if (!clip.transitionIn.isEnabled) return const SizedBox.shrink();

    final transIn = clip.transitionIn;
    final startMs = clip.startTimeMs;
    final durationMs = transIn.durationMs > 0 ? transIn.durationMs : 500;
    final elapsedMs = currentPositionMs - startMs;

    if (elapsedMs < 0 || elapsedMs > durationMs) {
      return const SizedBox.shrink();
    }

    final progress = (elapsedMs / durationMs).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: TransitionShaderPainter(
            progress: progress,
            type: transIn.type,
            easing: transIn.easing,
            sceneAColor: Colors.black,
            sceneBColor: Colors.transparent,
            labelA: '',
            labelB: '',
          ),
        ),
      ),
    );
  }

  static Decoration _buildCanvasDecoration(VideoLayoutConfig layout) {
    if (layout.reframeMode == AutoReframeMode.gradientCanvas || layout.backgroundMode == LayoutBackgroundMode.gradient) {
      final colors = layout.gradientPreset.colors.map((c) => Color(c)).toList();
      return BoxDecoration(
        gradient: LinearGradient(
          colors: colors.length >= 2 ? colors : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (layout.reframeMode == AutoReframeMode.solidPillarbox || layout.backgroundMode == LayoutBackgroundMode.solidColor) {
      return BoxDecoration(
        color: Color(layout.backgroundColor),
      );
    } else {
      return const BoxDecoration(
        color: Color(0xFF101216),
      );
    }
  }

  static AspectRatioPreset _mapLayoutRatioToPreset(VideoLayoutRatio ratio) {
    switch (ratio) {
      case VideoLayoutRatio.ratio16_9:
        return AspectRatioPreset.ratio16x9;
      case VideoLayoutRatio.ratio9_16:
        return AspectRatioPreset.ratio9x16;
      case VideoLayoutRatio.ratio1_1:
        return AspectRatioPreset.ratio1x1;
      case VideoLayoutRatio.ratio4_5:
        return AspectRatioPreset.ratio4x5;
      case VideoLayoutRatio.ratio21_9:
        return AspectRatioPreset.ratio21x9;
      case VideoLayoutRatio.ratio4_3:
        return AspectRatioPreset.ratio4x3;
      case VideoLayoutRatio.ratio3_4:
        return AspectRatioPreset.ratio3x4;
      case VideoLayoutRatio.ratio239_1:
        return AspectRatioPreset.ratio239x1;
    }
  }

  Widget _buildCharacterHighlightOverlay(CharacterHighlightConfig config) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _CharacterHighlightPainter(config),
        ),
      ),
    );
  }

  Widget _buildVideoBorderOverlay(VideoBorderConfig config) {
    if (!config.isEnabled) return const SizedBox.shrink();

    final primary = Color(config.primaryColor).withOpacity(config.opacity);
    final secondary = Color(config.secondaryColor ?? config.borderColor).withOpacity(config.opacity);

    switch (config.style) {
      case VideoBorderStyle.solid:
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: primary, width: config.borderWidth),
                borderRadius: BorderRadius.circular(config.borderRadius),
              ),
            ),
          ),
        );

      case VideoBorderStyle.neonGlow:
        final glow = config.glowIntensity.clamp(0.0, 1.0);
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: primary, width: config.borderWidth),
                borderRadius: BorderRadius.circular(config.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(glow * 0.8),
                    blurRadius: glow * 18,
                    spreadRadius: config.borderWidth * 0.5,
                  ),
                ],
              ),
            ),
          ),
        );

      case VideoBorderStyle.gradient:
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GradientBorderPainter(
                primaryColor: primary,
                secondaryColor: secondary,
                borderWidth: config.borderWidth,
                borderRadius: config.borderRadius,
              ),
            ),
          ),
        );

      case VideoBorderStyle.roundedCard:
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: EdgeInsets.all(config.borderWidth * 0.6),
              decoration: BoxDecoration(
                border: Border.all(color: primary, width: config.borderWidth),
                borderRadius: BorderRadius.circular(config.borderRadius.clamp(8.0, 48.0)),
              ),
            ),
          ),
        );

      case VideoBorderStyle.filmStrip:
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FilmStripBorderPainter(
                borderColor: primary,
                borderWidth: config.borderWidth.clamp(14.0, 60.0),
              ),
            ),
          ),
        );

      case VideoBorderStyle.polaroid:
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: primary, width: config.borderWidth),
                  left: BorderSide(color: primary, width: config.borderWidth),
                  right: BorderSide(color: primary, width: config.borderWidth),
                  bottom: BorderSide(color: primary, width: config.borderWidth * 3.2),
                ),
              ),
            ),
          ),
        );

      case VideoBorderStyle.vignetteFrame:
        final barHeight = (config.borderWidth * 2.2).clamp(16.0, 120.0);
        return Positioned.fill(
          child: IgnorePointer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: barHeight, width: double.infinity, color: primary),
                Container(height: barHeight, width: double.infinity, color: primary),
              ],
            ),
          ),
        );

      case VideoBorderStyle.retroTv:
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: primary, width: config.borderWidth * 1.5),
                borderRadius: BorderRadius.circular(config.borderRadius.clamp(24.0, 60.0)),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildHeaderFooterOverlay(HeaderFooterConfig config) {
    if (!config.hasActiveOverlay) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Top Header
            if (config.isHeaderEnabled && config.headerText.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: config.headerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Color(config.headerBackgroundColor),
                    border: config.headerStyle == HeaderFooterStyle.neonAccent
                        ? const Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 2.5))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (config.headerEmoji.isNotEmpty) ...[
                            Text(config.headerEmoji, style: TextStyle(fontSize: (config.headerFontSize * 0.8).clamp(10.0, 32.0))),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              config.isHeaderUppercase ? config.headerText.toUpperCase() : config.headerText,
                              style: _resolveHeaderFooterTextStyle(
                                fontFamily: config.headerFont,
                                fontSize: config.headerFontSize,
                                color: Color(config.headerTextColor),
                                isBold: config.isHeaderBold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (config.headerSubtext.isNotEmpty)
                        Text(
                          config.headerSubtext,
                          style: _resolveHeaderFooterTextStyle(
                            fontFamily: config.headerFont,
                            fontSize: (config.headerFontSize * 0.55).clamp(9.0, 16.0),
                            color: Color(config.headerTextColor).withOpacity(0.8),
                            isBold: false,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),

            // Bottom Footer
            if (config.isFooterEnabled && config.footerText.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: config.footerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Color(config.footerBackgroundColor),
                    border: config.footerStyle == HeaderFooterStyle.neonAccent
                        ? const Border(top: BorderSide(color: Color(0xFF00E5FF), width: 2.5))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (config.footerIcon.isNotEmpty) ...[
                            Text(config.footerIcon, style: TextStyle(fontSize: (config.footerFontSize * 0.8).clamp(10.0, 28.0))),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              config.isFooterUppercase ? config.footerText.toUpperCase() : config.footerText,
                              style: _resolveHeaderFooterTextStyle(
                                fontFamily: config.footerFont,
                                fontSize: config.footerFontSize,
                                color: Color(config.footerTextColor),
                                isBold: config.isFooterBold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (config.footerSubtext.isNotEmpty)
                        Text(
                          config.footerSubtext,
                          style: _resolveHeaderFooterTextStyle(
                            fontFamily: config.footerFont,
                            fontSize: (config.footerFontSize * 0.65).clamp(8.0, 14.0),
                            color: Color(config.footerTextColor).withOpacity(0.8),
                            isBold: false,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static TextStyle _resolveHeaderFooterTextStyle({
    required String fontFamily,
    required double fontSize,
    required Color color,
    required bool isBold,
  }) {
    final name = fontFamily.trim().toLowerCase().replaceAll(' ', '');
    final weight = isBold ? FontWeight.bold : FontWeight.normal;
    try {
      switch (name) {
        case 'anton':
          return GoogleFonts.anton(fontSize: fontSize, fontWeight: weight, color: color);
        case 'bebasneue':
          return GoogleFonts.bebasNeue(fontSize: fontSize, fontWeight: weight, color: color);
        case 'montserrat':
          return GoogleFonts.montserrat(fontSize: fontSize, fontWeight: weight, color: color);
        case 'poppins':
          return GoogleFonts.poppins(fontSize: fontSize, fontWeight: weight, color: color);
        case 'oswald':
          return GoogleFonts.oswald(fontSize: fontSize, fontWeight: weight, color: color);
        case 'roboto':
          return GoogleFonts.roboto(fontSize: fontSize, fontWeight: weight, color: color);
        case 'inter':
        default:
          return GoogleFonts.inter(fontSize: fontSize, fontWeight: weight, color: color);
      }
    } catch (_) {
      return TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: weight, color: color);
    }
  }

  static VideoLayoutRatio _mapPresetToLayoutRatio(AspectRatioPreset preset) {
    switch (preset) {
      case AspectRatioPreset.ratio16x9:
        return VideoLayoutRatio.ratio16_9;
      case AspectRatioPreset.ratio9x16:
        return VideoLayoutRatio.ratio9_16;
      case AspectRatioPreset.ratio1x1:
        return VideoLayoutRatio.ratio1_1;
      case AspectRatioPreset.ratio4x5:
        return VideoLayoutRatio.ratio4_5;
      case AspectRatioPreset.ratio21x9:
        return VideoLayoutRatio.ratio21_9;
      case AspectRatioPreset.ratio4x3:
        return VideoLayoutRatio.ratio4_3;
      case AspectRatioPreset.ratio3x4:
        return VideoLayoutRatio.ratio3_4;
      case AspectRatioPreset.ratio239x1:
        return VideoLayoutRatio.ratio239_1;
    }
  }
}

class _SafeGuidesPainter extends CustomPainter {
  const _SafeGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final actionSafePaint = Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final titleSafePaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Action Safe (90% area -> 5% margin)
    final actionRect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.05,
      size.width * 0.90,
      size.height * 0.90,
    );
    canvas.drawRect(actionRect, actionSafePaint);

    // Title Safe (80% area -> 10% margin)
    final titleRect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.10,
      size.width * 0.80,
      size.height * 0.80,
    );
    canvas.drawRect(titleRect, titleSafePaint);

    // Center Crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawLine(Offset(centerX - 10, centerY), Offset(centerX + 10, centerY), crosshairPaint);
    canvas.drawLine(Offset(centerX, centerY - 10), Offset(centerX, centerY + 10), crosshairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CharacterHighlightPainter extends CustomPainter {
  final CharacterHighlightConfig config;

  const _CharacterHighlightPainter(this.config);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(
      size.width * config.characterCenterX,
      size.height * config.characterCenterY,
    );

    final maxDim = size.longestSide;
    final radius = (config.spotlightRadius * maxDim * 0.7).clamp(30.0, maxDim);
    final feather = (config.feather * radius).clamp(10.0, radius);

    final bgColor = Color(config.backgroundColor);
    final hlColor = Color(config.highlightColor);
    final dim = config.backgroundDimming.clamp(0.0, 1.0);

    final rect = Offset.zero & size;

    if (config.mode == CharacterHighlightMode.neonAura) {
      // Background tint/dim wash
      final bgPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            config.characterCenterX * 2 - 1,
            config.characterCenterY * 2 - 1,
          ),
          radius: (radius / (size.shortestSide / 2)).clamp(0.1, 2.5),
          colors: [
            hlColor.withOpacity((0.05 * config.highlightIntensity).clamp(0.0, 1.0)),
            hlColor.withOpacity((0.35 * config.highlightIntensity).clamp(0.0, 1.0)),
            bgColor.withOpacity(dim * 0.85),
            bgColor.withOpacity(dim),
          ],
          stops: const [0.0, 0.45, 0.75, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);

      // Neon aura ring around character (adaptive to AI detected subject bounds)
      final auraPaint = Paint()
        ..color = hlColor.withOpacity((0.6 * config.highlightIntensity).clamp(0.0, 0.95))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (6.0 * config.highlightIntensity).clamp(2.0, 16.0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, feather * 0.5);

      if (config.subjectBbox != null && config.subjectBbox!.length >= 4) {
        final bbox = config.subjectBbox!;
        final subjectRect = Rect.fromLTRB(
          (bbox[0] * size.width).clamp(0.0, size.width),
          (bbox[1] * size.height).clamp(0.0, size.height),
          (bbox[2] * size.width).clamp(0.0, size.width),
          (bbox[3] * size.height).clamp(0.0, size.height),
        );
        final subjectRRect = RRect.fromRectAndRadius(
          subjectRect,
          Radius.circular(subjectRect.width * 0.3),
        );
        canvas.drawRRect(subjectRRect, auraPaint);
      } else {
        canvas.drawCircle(center, radius * 0.5, auraPaint);
      }
    } else if (config.mode == CharacterHighlightMode.bwBackground) {
      // Desaturated/darkened background with spotlight center
      final bgPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            config.characterCenterX * 2 - 1,
            config.characterCenterY * 2 - 1,
          ),
          radius: (radius / (size.shortestSide / 2)).clamp(0.1, 2.5),
          colors: [
            Colors.transparent,
            bgColor.withOpacity(dim * 0.4),
            bgColor.withOpacity(dim * 0.9),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);
    } else {
      // spotlight and solidBgWash
      final bgPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment(
            config.characterCenterX * 2 - 1,
            config.characterCenterY * 2 - 1,
          ),
          radius: (radius / (size.shortestSide / 2)).clamp(0.1, 2.5),
          colors: [
            hlColor.withOpacity((0.08 * config.highlightIntensity).clamp(0.0, 0.3)),
            bgColor.withOpacity(dim * 0.5),
            bgColor.withOpacity(dim),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CharacterHighlightPainter oldDelegate) =>
      oldDelegate.config != config;
}

class _GradientBorderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double borderWidth;
  final double borderRadius;

  const _GradientBorderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(borderRadius),
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderRadius != borderRadius;
}

class _FilmStripBorderPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  const _FilmStripBorderPainter({
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Left and right border bands
    canvas.drawRect(Rect.fromLTWH(0, 0, borderWidth, size.height), framePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - borderWidth, 0, borderWidth, size.height), framePaint);

    // Film perforations
    final holePaint = Paint()..color = Colors.black;
    final holeWidth = borderWidth * 0.45;
    final holeHeight = borderWidth * 0.6;
    final spacing = holeHeight * 1.5;

    double y = spacing * 0.5;
    while (y + holeHeight < size.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((borderWidth - holeWidth) / 2, y, holeWidth, holeHeight),
          const Radius.circular(2),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - borderWidth + (borderWidth - holeWidth) / 2, y, holeWidth, holeHeight),
          const Radius.circular(2),
        ),
        holePaint,
      );
      y += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _FilmStripBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor || oldDelegate.borderWidth != borderWidth;
}

class _StaticMaskPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double opacity;

  const _StaticMaskPainter({
    required this.path,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final fillPaint = Paint()
      ..color = color.withOpacity(opacity * 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _StaticMaskPainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

class _StaticDoodlePainter extends CustomPainter {
  final DoodleConfig config;

  const _StaticDoodlePainter({required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !config.isActive) return;
    for (final stroke in config.strokes) {
      DoodleCompilerService.paintStroke(canvas, stroke, size);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticDoodlePainter oldDelegate) {
    return oldDelegate.config != config;
  }
}

