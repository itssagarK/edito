import 'package:flutter/material.dart' hide Clip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/clip.dart';
import '../../../models/media_asset.dart';
import '../../../models/project.dart';
import '../../../models/track.dart';
import '../providers/editor_provider.dart';
import '../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../audio/presentation/widgets/audio_recorder_sheet.dart';
import '../../borders/presentation/widgets/video_border_sheet.dart';
import '../../captions/presentation/widgets/caption_manager_sheet.dart';
import '../../character_zoom/presentation/widgets/character_zoom_sheet.dart';
import '../../chroma/presentation/widgets/chroma_key_sheet.dart';
import '../../color_grading/presentation/widgets/color_grading_sheet.dart';
import '../../enhancement/presentation/widgets/video_enhancement_sheet.dart';
import '../../export/presentation/widgets/export_settings_modal.dart';
import '../../hd_converter/presentation/widgets/hd_converter_sheet.dart';
import '../../header_footer/presentation/widgets/header_footer_sheet.dart';
import '../../highlight/presentation/widgets/character_highlight_sheet.dart';
import '../../home/providers/project_list_provider.dart';
import '../../image_editor/presentation/widgets/asset_library_sheet.dart';
import '../../image_editor/presentation/widgets/image_editor_sheet.dart';
import '../../image_editor/presentation/widgets/image_overlay_sheet.dart';
import '../../image_editor/presentation/widgets/video_layout_sheet.dart';
import '../../media/presentation/media_picker_sheet.dart';
import '../../overlays/models/text_overlay_config.dart';
import '../../overlays/presentation/widgets/text_editor_sheet.dart';
import '../../preview/presentation/widgets/realtime_preview_viewport.dart';
import '../../preview/providers/preview_playback_provider.dart';
import '../../smoothing/presentation/widgets/video_smoother_sheet.dart';
import '../../speed/presentation/widgets/speed_ramping_sheet.dart';
import '../../timeline/presentation/widgets/interactive_timeline.dart';
import '../../timeline/services/timeline_editing_service.dart';
import '../../transitions/presentation/widgets/transition_selector_sheet.dart';
import '../../tts/presentation/widgets/tts_voiceover_sheet.dart';
import '../../overlays/presentation/widgets/progress_bar_sheet.dart';
import '../../image_editor/presentation/widgets/ken_burns_sheet.dart';
import '../../timeline/presentation/widgets/gap_closer_sheet.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/editing_toolbar.dart';
import 'widgets/docked_tool_panel.dart';
import 'widgets/selected_clip_context_bar.dart';
import 'widgets/timestamp_jump_dialog.dart';
import 'widgets/tool_search_modal.dart';


class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  EditorTool? _activeDockedTool;
  Clip? _initialClipBeforeEdit;
  Project? _initialProjectBeforeEdit;
  bool _isPeekMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(previewPlaybackProvider.notifier).syncCurrentFrame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final project = editorState.project;

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDocked = _activeDockedTool != null;
    final isPeeking = isDocked && _isPeekMode;

    Clip? dockedClip;
    if (isDocked) {
      if (_initialClipBeforeEdit != null) {
        for (final track in project.tracks) {
          for (final c in track.clips) {
            if (c.id == _initialClipBeforeEdit!.id) {
              dockedClip = c;
              break;
            }
          }
          if (dockedClip != null) break;
        }
      }
      dockedClip ??= _findTargetClip();
      if (dockedClip == null && project.tracks.isNotEmpty && project.tracks.first.clips.isNotEmpty) {
        dockedClip = project.tracks.first.clips.first;
      }
      dockedClip ??= _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Edit');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            EditorAppBar(
              title: project.title,
              subtitle: '${(project.durationMs / 1000).toStringAsFixed(1)}s • ${project.tracks.length} tracks',
              resolutionBadge: '${project.height >= 2160 ? "4K" : project.height >= 1080 ? "1080P" : "${project.height}P"} • ${project.fps}FPS',
              onResolutionTap: () {
                ExportSettingsModal.show(context, project: project);
              },
              canUndo: editorState.canUndo,
              canRedo: editorState.canRedo,
              onBack: () {
                if (_activeDockedTool != null) {
                  setState(() {
                    _activeDockedTool = null;
                    _initialClipBeforeEdit = null;
                    _initialProjectBeforeEdit = null;
                    _isPeekMode = false;
                  });
                  ref.read(editorProvider.notifier).setActiveTool(EditorTool.select);
                } else {
                  ref.read(playbackClockServiceProvider).pause();
                  Navigator.pop(context);
                }
              },
              onUndo: () {
                ref.read(editorProvider.notifier).undo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Action undone'),
                    duration: Duration(milliseconds: 700),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                );
              },
              onRedo: () {
                ref.read(editorProvider.notifier).redo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Action redone'),
                    duration: Duration(milliseconds: 700),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                );
              },
              onExport: () {
                ExportSettingsModal.show(context, project: project);
              },
            ),

            // Real-Time Video Preview Viewport
            Expanded(
              flex: isPeeking ? 10 : 4,
              child: RealtimePreviewViewport(
                currentPositionMs: editorState.playheadPositionMs,
                totalDurationMs: project.durationMs > 0 ? project.durationMs : 10000,
                isPlaying: editorState.isPlaying,
                onTogglePlay: () {
                  ref.read(previewPlaybackProvider.notifier).togglePlay();
                },
                onStepBackward: () {
                  ref.read(previewPlaybackProvider.notifier).seek(editorState.playheadPositionMs - 1000);
                },
                onStepForward: () {
                  ref.read(previewPlaybackProvider.notifier).seek(editorState.playheadPositionMs + 1000);
                },
              ),
            ),

            // Selected Clip Context HUD & Safety Bar
            if (!isPeeking && !isDocked)
              SelectedClipContextBar(
                project: project,
                selectedClipId: editorState.selectedClipId,
                playheadPositionMs: editorState.playheadPositionMs,
                onDeselect: () {
                  ref.read(editorProvider.notifier).selectClip(null);
                },
                onSplit: _handleSplitAction,
                onDuplicate: _handleDuplicateAction,
                onDelete: _handleDeleteAction,
                onOpenTimestampJump: () {
                  TimestampJumpDialog.show(
                    context,
                    project: project,
                    currentPositionMs: editorState.playheadPositionMs,
                    onSeek: (ms) => ref.read(previewPlaybackProvider.notifier).seek(ms),
                  );
                },
              ),

            // Multi-Track Interactive Timeline or Docked Tool Panel
            if (!isPeeking)
              Expanded(
                flex: 5,
                child: isDocked
                    ? DockedToolPanel(
                        tool: _activeDockedTool!,
                        clip: dockedClip!,
                        project: project,
                        playheadPositionMs: editorState.playheadPositionMs,
                        onSeek: (positionMs) {
                          ref.read(previewPlaybackProvider.notifier).seek(positionMs);
                        },
                        onSaveClip: (updatedClip) {
                          final proj = ref.read(editorProvider).project!;
                          final updatedProject = proj.updateClip(updatedClip);
                          ref.read(editorProvider.notifier).updateProject(updatedProject);
                          ref.read(projectListProvider.notifier).updateProject(updatedProject);
                        },
                        onSaveProject: (updatedProject) {
                          ref.read(editorProvider.notifier).updateProject(updatedProject);
                          ref.read(projectListProvider.notifier).updateProject(updatedProject);
                        },
                        onClose: () {
                          setState(() {
                            _activeDockedTool = null;
                            _initialClipBeforeEdit = null;
                            _initialProjectBeforeEdit = null;
                            _isPeekMode = false;
                          });
                          ref.read(editorProvider.notifier).setActiveTool(EditorTool.select);
                        },
                        onRevert: () {
                          if (_initialProjectBeforeEdit != null) {
                            ref.read(editorProvider.notifier).updateProject(_initialProjectBeforeEdit!);
                            ref.read(projectListProvider.notifier).updateProject(_initialProjectBeforeEdit!);
                          } else if (_initialClipBeforeEdit != null) {
                            final proj = ref.read(editorProvider).project!;
                            final updatedProject = proj.updateClip(_initialClipBeforeEdit!);
                            ref.read(editorProvider.notifier).updateProject(updatedProject);
                            ref.read(projectListProvider.notifier).updateProject(updatedProject);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('↺ Changes reverted to initial state'),
                              duration: Duration(milliseconds: 900),
                              backgroundColor: AppColors.surfaceElevated,
                            ),
                          );
                        },
                        onTogglePeek: () {
                          setState(() {
                            _isPeekMode = !_isPeekMode;
                          });
                        },
                        isPeekMode: _isPeekMode,
                      )
                    : InteractiveTimeline(
                        project: project,
                        playheadPositionMs: editorState.playheadPositionMs,
                        zoomScale: editorState.zoomScale,
                        selectedClipId: editorState.selectedClipId,
                        onSeek: (positionMs) {
                          ref.read(previewPlaybackProvider.notifier).seek(positionMs);
                        },
                        onZoomChanged: (zoom) {
                          ref.read(editorProvider.notifier).setZoom(zoom);
                        },
                        onSelectClip: (clipId, {trackId}) {
                          ref.read(editorProvider.notifier).selectClip(clipId, trackId: trackId);
                        },
                        onProjectMutated: (updatedProject) {
                          ref.read(editorProvider.notifier).updateProject(updatedProject);
                          ref.read(projectListProvider.notifier).updateProject(updatedProject);
                        },
                        onAddMedia: () {
                          MediaPickerSheet.show(context);
                        },
                      ),
              ),

            // Bottom Area: Live Peek Pill or Toolbar
            if (isPeeking)
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.visibility, color: AppColors.accent, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'LIVE PEEK',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Full Canvas Active',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF8854D0)],
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() => _isPeekMode = false);
                        },
                        icon: const Icon(Icons.tune, size: 14),
                        label: const Text('Restore Controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            else if (!isDocked)
              // Bottom Editing Toolbar
              EditingToolbar(
                activeTool: editorState.activeTool,
                hasSelectedClip: editorState.selectedClipId != null,
                onSelectTool: (tool) {
                  ref.read(editorProvider.notifier).setActiveTool(tool);
                  _handleToolAction(tool);
                },
                onDeselectClip: () {
                  ref.read(editorProvider.notifier).selectClip(null);
                },
                onAddTrack: () {
                  MediaPickerSheet.show(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleToolAction(EditorTool tool) {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    switch (tool) {
      case EditorTool.split:
        _handleSplitAction();
        break;

      case EditorTool.trim:
        _handleTrimAction();
        break;

      case EditorTool.text:
        _openTextEditorModal();
        break;

      case EditorTool.captions:
        _openCaptionsModal();
        break;

      case EditorTool.effects:
        _openTransitionsModal();
        break;

      case EditorTool.color:
        _openColorGradingModal();
        break;

      case EditorTool.audio:
        _openAudioToolsModal();
        break;

      case EditorTool.speed:
        _openSpeedModal();
        break;

      case EditorTool.enhance:
        _openEnhancementModal();
        break;

      case EditorTool.smooth:
        _openSmootherModal();
        break;

      case EditorTool.chromaKey:
        _openChromaKeyModal();
        break;

      case EditorTool.imageEditor:
        _openImageEditorModal();
        break;

      case EditorTool.layout:
        _openVideoLayoutModal();
        break;

      case EditorTool.assets:
        _openAssetLibraryModal();
        break;

      case EditorTool.imageOverlay:
        _openImageOverlayModal();
        break;

      case EditorTool.highlight:
        _openCharacterHighlightModal();
        break;

      case EditorTool.characterZoom:
        _openCharacterZoomModal();
        break;

      case EditorTool.borders:
        _openBordersModal();
        break;

      case EditorTool.headerFooter:
        _openHeaderFooterModal();
        break;

      case EditorTool.hdConverter:
        _openHdConverterModal();
        break;

      case EditorTool.mask:
        _openMaskModal();
        break;

      case EditorTool.blend:
        _openBlendModal();
        break;

      case EditorTool.keyframes:
        _openKeyframesModal();
        break;

      case EditorTool.clipWorkflow:
        _openClipWorkflowModal();
        break;

      case EditorTool.vfx:
        _openVfxModal();
        break;

      case EditorTool.beats:
        _openBeatsModal();
        break;

      case EditorTool.tts:
        _openTTSModal();
        break;

      case EditorTool.tracking:
        _openTrackingModal();
        break;

      case EditorTool.retouch:
        _openRetouchModal();
        break;

      case EditorTool.parallax3D:
        _openParallax3DModal();
        break;

      case EditorTool.stabilization:
        _openStabilizationModal();
        break;

      case EditorTool.vocalIsolation:
        _openVocalIsolationModal();
        break;

      case EditorTool.colorMatch:
        _openColorMatchModal();
        break;

      case EditorTool.relight:
        _openRelightModal();
        break;

      case EditorTool.denoise:
        _openDenoiseModal();
        break;

      case EditorTool.voiceEffects:
        _openVoiceEffectsModal();
        break;

      case EditorTool.edgeAura:
        _openEdgeAuraModal();
        break;

      case EditorTool.mosaic:
        _openMosaicModal();
        break;

      case EditorTool.teleprompter:
        _openTeleprompterModal();
        break;

      case EditorTool.splitScreen:
        _openSplitScreenModal();
        break;

      case EditorTool.objectRemoval:
        _openObjectRemovalModal();
        break;

      case EditorTool.faceReshape:
        _openFaceReshapeModal();
        break;

      case EditorTool.colorWheels:
        _openColorWheelsModal();
        break;

      case EditorTool.doodle:
        _openDoodleModal();
        break;

      case EditorTool.curves:
        _openCurvesModal();
        break;

      case EditorTool.filmGrain:
        _openFilmGrainModal();
        break;

      case EditorTool.vignette:
        _openVignetteModal();
        break;

      case EditorTool.transform:
        _openTransformModal();
        break;

      case EditorTool.deleteClip:
        _handleDeleteAction();
        break;

      case EditorTool.duplicateClip:
        _handleDuplicateAction();
        break;

      case EditorTool.extractAudio:
        _handleExtractAudioAction();
        break;

      case EditorTool.freezeFrame:
        _handleFreezeFrameAction();
        break;

      case EditorTool.reverseClip:
        _handleReverseAction();
        break;

      case EditorTool.audioRecord:
        _openAudioRecorderModal();
        break;

      case EditorTool.aiColorEnhance:
        _openAiColorEnhanceModal();
        break;

      case EditorTool.aiSilenceRemover:
        _openAiSilenceRemoverModal();
        break;

      case EditorTool.aiSceneSplit:
        _openAiSceneSplitModal();
        break;

      case EditorTool.progressBar:
        _openProgressBarModal();
        break;

      case EditorTool.kenBurns:
        _openKenBurnsModal();
        break;

      case EditorTool.gapCloser:
        _openGapCloserModal();
        break;

      case EditorTool.beatCut:
        _openBeatCutterModal();
        break;

      case EditorTool.audioFade:
        _openAudioFadeModal();
        break;

      case EditorTool.impactFlash:
        _openImpactFlashModal();
        break;

      case EditorTool.freezeClimax:
        _openFreezeClimaxModal();
        break;

      case EditorTool.speedEase:
        _openSpeedEaseModal();
        break;

      case EditorTool.spatialPan:
        _openSpatialPanModal();
        break;

      case EditorTool.typewriterTitle:
        _openTypewriterTitleModal();
        break;

      case EditorTool.crtScanline:
        _openCrtScanlineModal();
        break;

      case EditorTool.reverbChamber:
        _openReverbChamberModal();
        break;

      case EditorTool.anamorphicFlare:
        _openAnamorphicFlareModal();
        break;

      case EditorTool.filmHalation:
        _openFilmHalationModal();
        break;

      case EditorTool.tapeCassette:
        _openTapeCassetteModal();
        break;

      case EditorTool.cameraShake:
        _openCameraShakeModal();
        break;

      case EditorTool.lensDistortion:
        _openLensDistortionModal();
        break;

      case EditorTool.vinylRecord:
        _openVinylRecordModal();
        break;

      case EditorTool.lightLeak:
        _openLightLeakModal();
        break;

      case EditorTool.nightVision:
        _openNightVisionModal();
        break;

      case EditorTool.bitcrusher:
        _openBitcrusherModal();
        break;

      case EditorTool.kaleidoscope:
        _openKaleidoscopeModal();
        break;

      case EditorTool.datamoshGlitch:
        _openDatamoshGlitchModal();
        break;

      case EditorTool.tremoloWah:
        _openTremoloWahModal();
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool.name.toUpperCase()} tool active'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
        break;
    }
  }

  void _handleSplitAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project!;
    final playhead = editorState.playheadPositionMs;

    // 1. If a clip is selected or at the playhead, split it
    final targetClip = _findTargetClip();
    if (targetClip != null) {
      int splitPos = playhead;
      // If playhead is not within the clip, split at the midpoint of the clip
      if (splitPos <= targetClip.startTimeMs || splitPos >= (targetClip.startTimeMs + targetClip.durationMs)) {
        splitPos = targetClip.startTimeMs + (targetClip.durationMs ~/ 2);
      }

      final updated = TimelineEditingService.splitClip(project, targetClip.id, splitPos);
      if (updated != null) {
        ref.read(editorProvider.notifier).updateProject(updated);
        ref.read(projectListProvider.notifier).updateProject(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✂️ Clip split into two clips'),
            duration: Duration(milliseconds: 900),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }
    }

    // 2. If no clips exist at all, create a clip and split it right away
    final newClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Scene');
    final updatedProject = ref.read(editorProvider).project!;
    final splitPos = newClip.startTimeMs + 3000;
    final splitUpdated = TimelineEditingService.splitClip(updatedProject, newClip.id, splitPos);
    if (splitUpdated != null) {
      ref.read(editorProvider.notifier).updateProject(splitUpdated);
      ref.read(projectListProvider.notifier).updateProject(splitUpdated);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✂️ Created clip and split into two segments'),
        duration: Duration(milliseconds: 900),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleTrimAction() {
    final targetClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Trim');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✂️ Selected Clip: Drag the yellow handles on the timeline left or right to trim'),
        duration: Duration(milliseconds: 1500),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _openTransformModal() {
    _openDockedTool(EditorTool.transform, trackType: TrackType.video, purpose: 'Transform');
  }

  void _handleDeleteAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    final selectedClipId = editorState.selectedClipId;
    if (project == null || selectedClipId == null) return;

    final updated = TimelineEditingService.deleteClip(project, selectedClipId, ripple: true);
    ref.read(editorProvider.notifier).updateProject(updated);
    ref.read(editorProvider.notifier).selectClip(null);
    ref.read(projectListProvider.notifier).updateProject(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Clip deleted (timeline rippled)'),
        duration: Duration(milliseconds: 900),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleDuplicateAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    final targetClip = _findTargetClip();
    if (project == null || targetClip == null) return;

    final updated = TimelineEditingService.duplicateClip(project, targetClip.id);
    ref.read(editorProvider.notifier).updateProject(updated);
    ref.read(projectListProvider.notifier).updateProject(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Clip duplicated on timeline'),
        duration: Duration(milliseconds: 900),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleExtractAudioAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    final targetClip = _findTargetClip();
    if (project == null || targetClip == null) return;

    final updated = TimelineEditingService.extractAudio(project, targetClip.id);
    if (updated != null) {
      ref.read(editorProvider.notifier).updateProject(updated);
      ref.read(projectListProvider.notifier).updateProject(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎵 Audio extracted to dedicated track! Video muted.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleFreezeFrameAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    final playhead = editorState.playheadPositionMs;
    final targetClip = _findTargetClip();
    if (project == null || targetClip == null) return;

    final updated = TimelineEditingService.freezeFrame(
      project,
      targetClip.id,
      playhead,
      freezeDurationMs: 3000,
    );
    if (updated != null) {
      ref.read(editorProvider.notifier).updateProject(updated);
      ref.read(projectListProvider.notifier).updateProject(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❄️ Inserted 3s Freeze Frame at ${(playhead / 1000.0).toStringAsFixed(1)}s'),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _handleReverseAction() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    final targetClip = _findTargetClip();
    if (project == null || targetClip == null) return;

    final updated = TimelineEditingService.toggleReverseClip(project, targetClip.id);
    if (updated != null) {
      ref.read(editorProvider.notifier).updateProject(updated);
      ref.read(projectListProvider.notifier).updateProject(updated);
      final isNowRev = !targetClip.isReversed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowRev ? '⏪ Video & Audio playback set to REVERSE' : '▶️ Playback restored to FORWARD'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _openDockedTool(EditorTool tool, {TrackType trackType = TrackType.video, String purpose = 'Edit'}) {
    final targetClip = _findOrCreateTargetClip(trackType: trackType, purpose: purpose);
    final currentProject = ref.read(editorProvider).project;
    setState(() {
      _activeDockedTool = tool;
      _initialClipBeforeEdit = targetClip;
      _initialProjectBeforeEdit = currentProject;
      _isPeekMode = false;
    });
  }

  void _openTextEditorModal() {
    _openDockedTool(EditorTool.text, trackType: TrackType.video, purpose: 'Text');
  }

  void _openCaptionsModal() {
    final project = ref.read(editorProvider).project;
    if (project == null) return;

    CaptionManagerSheet.show(
      context,
      project: project,
      onSave: (updatedProject) {
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
      onSeek: (timestampMs) {
        ref.read(previewPlaybackProvider.notifier).seek(timestampMs);
      },
    );
  }

  void _openTransitionsModal() {
    final targetClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Transitions');
    TransitionSelectorSheet.show(
      context,
      clip: targetClip,
      onSave: (updatedClip) {
        final project = ref.read(editorProvider).project!;
        final updatedProject = project.updateClip(updatedClip);
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
    );
  }

  void _openSpeedModal() {
    _openDockedTool(EditorTool.speed, trackType: TrackType.video, purpose: 'Speed');
  }

  void _openColorGradingModal() {
    _openDockedTool(EditorTool.color, trackType: TrackType.video, purpose: 'Color');
  }

  void _openAiColorEnhanceModal() {
    _openDockedTool(EditorTool.aiColorEnhance, trackType: TrackType.video, purpose: 'AI Color & Tone');
  }

  void _openAiSilenceRemoverModal() {
    _openDockedTool(EditorTool.aiSilenceRemover, trackType: TrackType.video, purpose: 'AI Silence Remover');
  }

  void _openAiSceneSplitModal() {
    _openDockedTool(EditorTool.aiSceneSplit, trackType: TrackType.video, purpose: 'AI Scene Cut Detector');
  }

  void _openProgressBarModal() {
    _openDockedTool(EditorTool.progressBar, trackType: TrackType.video, purpose: 'Retention Progress Bar');
  }

  void _openKenBurnsModal() {
    _openDockedTool(EditorTool.kenBurns, trackType: TrackType.video, purpose: 'Ken Burns Motion');
  }

  void _openGapCloserModal() {
    _openDockedTool(EditorTool.gapCloser, trackType: TrackType.video, purpose: 'Timeline Gap Closer');
  }

  void _openBeatCutterModal() {
    _openDockedTool(EditorTool.beatCut, trackType: TrackType.video, purpose: 'Beat Cut & Rhythm Snapper');
  }

  void _openAudioFadeModal() {
    _openDockedTool(EditorTool.audioFade, purpose: 'Audio Fade & Anti-Pop');
  }

  void _openImpactFlashModal() {
    _openDockedTool(EditorTool.impactFlash, trackType: TrackType.video, purpose: 'Impact Flash & Strobe');
  }

  void _openFreezeClimaxModal() {
    _openDockedTool(EditorTool.freezeClimax, trackType: TrackType.video, purpose: 'Action Freeze Frame Climax');
  }

  void _openSpeedEaseModal() {
    _openDockedTool(EditorTool.speedEase, trackType: TrackType.video, purpose: 'Bezier Speed Ease & Curve');
  }

  void _openSpatialPanModal() {
    _openDockedTool(EditorTool.spatialPan, purpose: '8D Spatial Audio & Pan');
  }

  void _openTypewriterTitleModal() {
    _openDockedTool(EditorTool.typewriterTitle, purpose: 'Kinetic Typewriter Studio');
  }

  void _openCrtScanlineModal() {
    _openDockedTool(EditorTool.crtScanline, trackType: TrackType.video, purpose: 'Retro CRT Scanlines Studio');
  }

  void _openReverbChamberModal() {
    _openDockedTool(EditorTool.reverbChamber, purpose: 'Reverb Chamber Studio');
  }

  void _openAnamorphicFlareModal() {
    _openDockedTool(EditorTool.anamorphicFlare, trackType: TrackType.video, purpose: 'Anamorphic Streak Flare Studio');
  }

  void _openFilmHalationModal() {
    _openDockedTool(EditorTool.filmHalation, trackType: TrackType.video, purpose: '35mm Film Halation Studio');
  }

  void _openTapeCassetteModal() {
    _openDockedTool(EditorTool.tapeCassette, trackType: TrackType.audio, purpose: 'Vintage Tape Cassette Studio');
  }

  void _openCameraShakeModal() {
    _openDockedTool(EditorTool.cameraShake, trackType: TrackType.video, purpose: 'Camera Shake & Tremor');
  }

  void _openLensDistortionModal() {
    _openDockedTool(EditorTool.lensDistortion, trackType: TrackType.video, purpose: 'Lens Distortion & Fisheye');
  }

  void _openVinylRecordModal() {
    _openDockedTool(EditorTool.vinylRecord, trackType: TrackType.audio, purpose: 'Vinyl Turntable Studio');
  }

  void _openLightLeakModal() {
    _openDockedTool(EditorTool.lightLeak, trackType: TrackType.video, purpose: 'Light Leak & Rainbow Prisms');
  }

  void _openNightVisionModal() {
    _openDockedTool(EditorTool.nightVision, trackType: TrackType.video, purpose: 'Night Vision & Thermal Scope');
  }

  void _openBitcrusherModal() {
    _openDockedTool(EditorTool.bitcrusher, trackType: TrackType.audio, purpose: '8-Bit Chiptune Crusher');
  }

  void _openKaleidoscopeModal() {
    _openDockedTool(EditorTool.kaleidoscope, trackType: TrackType.video, purpose: 'Kaleidoscope & Radial Mirror');
  }

  void _openDatamoshGlitchModal() {
    _openDockedTool(EditorTool.datamoshGlitch, trackType: TrackType.video, purpose: 'Datamosh & Compression Glitch');
  }

  void _openTremoloWahModal() {
    _openDockedTool(EditorTool.tremoloWah, trackType: TrackType.audio, purpose: 'Stereo Tremolo & Auto-Wah');
  }

  void _openAudioToolsModal() {
    final editorState = ref.read(editorProvider);
    if (editorState.selectedClipId != null) {
      _openDockedTool(EditorTool.audio, trackType: TrackType.audio, purpose: 'Audio Restoration & Mixer');
      return;
    }

    _showGlobalAudioSheet();
  }

  void _openAudioRecorderModal() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    AudioRecorderSheet.show(
      context,
      project: project,
      currentPlayheadMs: editorState.playheadPositionMs,
      onProjectUpdated: (updatedProject) {
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
    );
  }

  void _showGlobalAudioSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    width: 36,
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
                        const Icon(Icons.music_note, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text('Audio Studio', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.mic, color: Colors.redAccent, size: 22),
                  ),
                  title: const Text('Record Voiceover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Record live microphone audio into timeline', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAudioRecorderModal();
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.graphic_eq, color: AppColors.accent, size: 22),
                  ),
                  title: const Text('Audio Mixer & EQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Parametric EQ, ducking, limiter, vocal enhance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openDockedTool(EditorTool.audio, trackType: TrackType.audio, purpose: 'Audio Restoration & Mixer');
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.speaker, color: AppColors.primaryLight, size: 22),
                  ),
                  title: const Text('Sound Effects (SFX)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cinematic risers, impacts, whooshes, foley', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openDockedTool(EditorTool.soundEffects, trackType: TrackType.audio, purpose: 'Sound Effects');
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF20BF6B).withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.record_voice_over, color: Color(0xFF20BF6B), size: 22),
                  ),
                  title: const Text('Text to Speech (Voiceover)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Convert scripts to speech with Android TTS engine', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openTTSModal();
                  },
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.music_note, color: Colors.amberAccent, size: 22),
                  ),
                  title: const Text('Extract Audio Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Detach audio from video onto dedicated track', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleExtractAudioAction();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEnhancementModal() {
    _openDockedTool(EditorTool.enhance, trackType: TrackType.video, purpose: '8K Enhance');
  }

  void _openHdConverterModal() {
    _openDockedTool(EditorTool.hdConverter, trackType: TrackType.video, purpose: 'HD Converter');
  }

  void _openSmootherModal() {
    _openDockedTool(EditorTool.smooth, trackType: TrackType.video, purpose: 'Optical Flow & Motion Blur');
  }

  void _openChromaKeyModal() {
    _openDockedTool(EditorTool.chromaKey, trackType: TrackType.video, purpose: 'Smart Cutout');
  }

  void _openImageEditorModal() {
    final project = ref.read(editorProvider).project;
    if (project == null) return;

    ImageEditorSheet.show(
      context,
      project: project,
      onProjectUpdated: (updatedProject) {
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
    );
  }

  void _openVideoLayoutModal() {
    final project = ref.read(editorProvider).project;
    if (project == null) return;
    final targetClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Layout');
    setState(() {
      _activeDockedTool = EditorTool.layout;
      _initialClipBeforeEdit = targetClip;
      _initialProjectBeforeEdit = project;
      _isPeekMode = false;
    });
  }

  void _openAssetLibraryModal() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    AssetLibrarySheet.show(
      context,
      project: project,
      activeClipId: editorState.selectedClipId,
      onProjectUpdated: (updatedProject) {
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
      onOpenThumbnailEditor: () => _openImageEditorModal(),
    );
  }

  void _openImageOverlayModal() {
    _openDockedTool(EditorTool.imageOverlay, trackType: TrackType.video, purpose: 'Picture-in-Picture (PiP)');
  }

  void _openCharacterHighlightModal() {
    _openDockedTool(EditorTool.highlight, trackType: TrackType.video, purpose: 'Highlight & BG');
  }

  void _openCharacterZoomModal() {
    _openDockedTool(EditorTool.characterZoom, trackType: TrackType.video, purpose: 'Character Zoom');
  }

  void _openBordersModal() {
    final targetClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Borders & Frames');
    VideoBorderSheet.show(
      context,
      clip: targetClip,
      onSave: (updatedClip, {bool applyToAll = false}) {
        final project = ref.read(editorProvider).project!;
        Project updatedProject;
        if (applyToAll) {
          final updatedTracks = project.tracks.map((track) {
            if (track.type != TrackType.video) return track;
            final updatedClips = track.clips.map((c) => c.copyWith(border: updatedClip.border)).toList();
            return track.copyWith(clips: updatedClips);
          }).toList();
          updatedProject = project.copyWith(tracks: updatedTracks);
        } else {
          updatedProject = project.updateClip(updatedClip);
        }
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
    );
  }

  void _openHeaderFooterModal() {
    final targetClip = _findOrCreateTargetClip(trackType: TrackType.video, purpose: 'Header & Footer');
    HeaderFooterSheet.show(
      context,
      clip: targetClip,
      onSave: (updatedClip, {bool applyToAll = false}) {
        final project = ref.read(editorProvider).project!;
        Project updatedProject;
        if (applyToAll) {
          final updatedTracks = project.tracks.map((track) {
            if (track.type != TrackType.video) return track;
            final updatedClips = track.clips.map((c) => c.copyWith(headerFooter: updatedClip.headerFooter)).toList();
            return track.copyWith(clips: updatedClips);
          }).toList();
          updatedProject = project.copyWith(tracks: updatedTracks);
        } else {
          updatedProject = project.updateClip(updatedClip);
        }
        ref.read(editorProvider.notifier).updateProject(updatedProject);
        ref.read(projectListProvider.notifier).updateProject(updatedProject);
      },
    );
  }

  void _openMaskModal() {
    _openDockedTool(EditorTool.mask, trackType: TrackType.video, purpose: 'Masking');
  }

  void _openBlendModal() {
    _openDockedTool(EditorTool.blend, trackType: TrackType.video, purpose: 'Blend Mode');
  }

  void _openKeyframesModal() {
    _openDockedTool(EditorTool.keyframes, trackType: TrackType.video, purpose: 'Keyframes');
  }

  void _openClipWorkflowModal() {
    _openDockedTool(EditorTool.clipWorkflow, trackType: TrackType.video, purpose: 'Clip Actions');
  }

  void _openVfxModal() {
    _openDockedTool(EditorTool.vfx, trackType: TrackType.video, purpose: 'Visual FX');
  }

  void _openBeatsModal() {
    _openDockedTool(EditorTool.beats, trackType: TrackType.audio, purpose: 'Beats & Rhythm');
  }

  void _openTTSModal() {
    final project = ref.read(editorProvider).project;
    if (project == null) return;
    final playheadMs = ref.read(editorProvider).playheadPositionMs;
    TTSVoiceoverSheet.show(
      context,
      project: project,
      currentPlayheadMs: playheadMs,
      onProjectChanged: (updated) {
        ref.read(editorProvider.notifier).updateProject(updated);
        ref.read(projectListProvider.notifier).updateProject(updated);
      },
    );
  }

  void _openTrackingModal() {
    _openDockedTool(EditorTool.tracking, trackType: TrackType.video, purpose: 'Motion Tracking');
  }

  void _openRetouchModal() {
    _openDockedTool(EditorTool.retouch, trackType: TrackType.video, purpose: 'AI Face & Body Retouch');
  }

  void _openParallax3DModal() {
    _openDockedTool(EditorTool.parallax3D, trackType: TrackType.video, purpose: '3D Zoom & Parallax');
  }

  void _openStabilizationModal() {
    _openDockedTool(EditorTool.stabilization, trackType: TrackType.video, purpose: 'AI Video Stabilization');
  }

  void _openVocalIsolationModal() {
    _openDockedTool(EditorTool.vocalIsolation, trackType: TrackType.video, purpose: 'AI Vocal Isolation');
  }

  void _openColorMatchModal() {
    _openDockedTool(EditorTool.colorMatch, trackType: TrackType.video, purpose: 'AI Color Match');
  }

  void _openRelightModal() {
    _openDockedTool(EditorTool.relight, trackType: TrackType.video, purpose: 'AI Video Relight');
  }

  void _openDenoiseModal() {
    _openDockedTool(EditorTool.denoise, trackType: TrackType.video, purpose: 'AI Video De-Noise');
  }

  void _openVoiceEffectsModal() {
    _openDockedTool(EditorTool.voiceEffects, trackType: TrackType.video, purpose: 'CapCut Pro Voice Changer');
  }

  void _openEdgeAuraModal() {
    _openDockedTool(EditorTool.edgeAura, trackType: TrackType.video, purpose: 'AI Video Glow & Edge Aura');
  }

  void _openMosaicModal() {
    _openDockedTool(EditorTool.mosaic, trackType: TrackType.video, purpose: 'Smart Mosaic & Privacy Censor');
  }

  void _openTeleprompterModal() {
    _openDockedTool(EditorTool.teleprompter, trackType: TrackType.video, purpose: 'Creator Teleprompter');
  }

  void _openSplitScreenModal() {
    _openDockedTool(EditorTool.splitScreen, trackType: TrackType.video, purpose: 'Split Screen Collage');
  }

  void _openObjectRemovalModal() {
    _openDockedTool(EditorTool.objectRemoval, trackType: TrackType.video, purpose: 'AI Magic Eraser & Object Removal');
  }

  void _openFaceReshapeModal() {
    _openDockedTool(EditorTool.faceReshape, trackType: TrackType.video, purpose: 'AI Face Reshape & 3D Sculpt');
  }

  void _openColorWheelsModal() {
    _openDockedTool(EditorTool.colorWheels, trackType: TrackType.video, purpose: 'Pro Color Wheels Studio');
  }

  void _openDoodleModal() {
    _openDockedTool(EditorTool.doodle, trackType: TrackType.video, purpose: 'Creative Doodle & Brush');
  }

  void _openCurvesModal() {
    _openDockedTool(EditorTool.curves, trackType: TrackType.video, purpose: 'RGB Curves Studio');
  }

  void _openFilmGrainModal() {
    _openDockedTool(EditorTool.filmGrain, trackType: TrackType.video, purpose: 'Cinematic Film Grain');
  }

  void _openVignetteModal() {
    _openDockedTool(EditorTool.vignette, trackType: TrackType.video, purpose: 'Cinematic Vignette & Spotlight');
  }

  Clip? _findTargetClip() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return null;

    if (editorState.selectedClipId != null) {
      for (final track in project.tracks) {
        for (final clip in track.clips) {
          if (clip.id == editorState.selectedClipId) {
            return clip;
          }
        }
      }
    }

    // Check if playhead is over any clip
    final playhead = editorState.playheadPositionMs;
    for (final track in project.tracks) {
      for (final clip in track.clips) {
        if (playhead >= clip.startTimeMs && playhead <= (clip.startTimeMs + clip.durationMs)) {
          return clip;
        }
      }
    }

    // Fallback to first clip
    for (final track in project.tracks) {
      if (track.clips.isNotEmpty) {
        return track.clips.first;
      }
    }
    return null;
  }

  Clip _findOrCreateTargetClip({required TrackType trackType, required String purpose}) {
    final editorState = ref.read(editorProvider);
    var project = editorState.project!;
    final playhead = editorState.playheadPositionMs;

    // 1. If a clip is explicitly selected and matches the track type (or any track if applicable)
    if (editorState.selectedClipId != null) {
      for (final track in project.tracks) {
        for (final clip in track.clips) {
          if (clip.id == editorState.selectedClipId) {
            return clip;
          }
        }
      }
    }

    // 2. Check if a clip sits under the current playhead
    for (final track in project.tracks) {
      if (track.type == trackType || trackType == TrackType.video) {
        for (final clip in track.clips) {
          if (playhead >= clip.startTimeMs && playhead <= (clip.startTimeMs + clip.durationMs)) {
            ref.read(editorProvider.notifier).selectClip(clip.id, trackId: track.id);
            return clip;
          }
        }
      }
    }

    // 3. Check if any clip exists in the project tracks matching trackType
    for (final track in project.tracks) {
      if (track.type == trackType && track.clips.isNotEmpty) {
        final clip = track.clips.first;
        ref.read(editorProvider.notifier).selectClip(clip.id, trackId: track.id);
        return clip;
      }
    }

    // Check any clip in any track as fallback
    for (final track in project.tracks) {
      if (track.clips.isNotEmpty) {
        final clip = track.clips.first;
        ref.read(editorProvider.notifier).selectClip(clip.id, trackId: track.id);
        return clip;
      }
    }

    // 4. If no clip exists, automatically create a new clip at the playhead!
    final targetTrack = project.tracks.firstWhere(
      (t) => t.type == trackType,
      orElse: () => project.tracks.first,
    );

    final assetId = const Uuid().v4();
    final assetName = purpose == 'Audio' ? 'Audio_Soundtrack.mp3' : 'Scene_Clip.mp4';
    final newAsset = MediaAsset(
      id: assetId,
      path: assetName,
      fileName: assetName,
      type: trackType == TrackType.audio ? MediaType.audio : MediaType.video,
      durationMs: 6000,
      width: trackType == TrackType.audio ? 0 : 1920,
      height: trackType == TrackType.audio ? 0 : 1080,
      fps: trackType == TrackType.audio ? 0.0 : 30.0,
    );

    final newClip = Clip(
      id: const Uuid().v4(),
      assetId: assetId,
      trackId: targetTrack.id,
      startTimeMs: playhead,
      durationMs: 6000,
      sourceInMs: 0,
      sourceOutMs: 6000,
      textOverlay: purpose == 'Text'
          ? const TextOverlayConfig(
              text: 'EDITO TITLE',
              fontSize: 28.0,
              animationType: TextAnimationType.typewriter,
            )
          : const TextOverlayConfig(),
    );

    project = project.addAsset(newAsset);
    project = project.addClipToTrack(targetTrack.id, newClip);

    ref.read(editorProvider.notifier).updateProject(project);
    ref.read(projectListProvider.notifier).updateProject(project);
    ref.read(editorProvider.notifier).selectClip(newClip.id, trackId: targetTrack.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Added new $purpose clip to timeline'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: AppColors.primary,
      ),
    );

    return newClip;
  }
}
