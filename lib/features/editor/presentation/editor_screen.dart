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
import 'widgets/editor_app_bar.dart';
import 'widgets/editing_toolbar.dart';
import 'widgets/docked_tool_panel.dart';

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
                  ref.read(previewPlaybackProvider.notifier).seek(editorState.playheadPositionMs - 5000);
                },
                onStepForward: () {
                  ref.read(previewPlaybackProvider.notifier).seek(editorState.playheadPositionMs + 5000);
                },
              ),
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
      SnackBar(
        content: Text('✂️ Selected Clip: Drag the yellow handles on the timeline left or right to trim'),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppColors.primary,
      ),
    );
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

  void _openAudioToolsModal() {
    _openDockedTool(EditorTool.audio, trackType: TrackType.audio, purpose: 'Audio');
  }

  void _openEnhancementModal() {
    _openDockedTool(EditorTool.enhance, trackType: TrackType.video, purpose: '8K Enhance');
  }

  void _openHdConverterModal() {
    _openDockedTool(EditorTool.hdConverter, trackType: TrackType.video, purpose: 'HD Converter');
  }

  void _openSmootherModal() {
    _openDockedTool(EditorTool.smooth, trackType: TrackType.video, purpose: 'Smoother');
  }

  void _openChromaKeyModal() {
    _openDockedTool(EditorTool.chromaKey, trackType: TrackType.video, purpose: 'Green Screen');
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
    _openDockedTool(EditorTool.imageOverlay, trackType: TrackType.video, purpose: 'Overlay / PiP');
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
