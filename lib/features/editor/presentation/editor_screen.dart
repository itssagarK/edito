import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/editor_provider.dart';
import '../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../color_grading/presentation/widgets/color_grading_sheet.dart';
import '../../export/presentation/widgets/export_settings_modal.dart';
import '../../home/providers/project_list_provider.dart';
import '../../media/presentation/media_picker_sheet.dart';
import '../../overlays/models/text_overlay_config.dart';
import '../../overlays/presentation/widgets/text_editor_sheet.dart';
import '../../preview/presentation/widgets/realtime_preview_viewport.dart';
import '../../preview/providers/preview_playback_provider.dart';
import '../../speed/presentation/widgets/speed_ramping_sheet.dart';
import '../../timeline/presentation/widgets/interactive_timeline.dart';
import '../../timeline/services/timeline_editing_service.dart';
import '../../transitions/presentation/widgets/transition_selector_sheet.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/editing_toolbar.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final project = editorState.project;

    if (project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                ref.read(playbackClockServiceProvider).pause();
                Navigator.pop(context);
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
              flex: 4,
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

            // Multi-Track Interactive Timeline
            Expanded(
              flex: 5,
              child: InteractiveTimeline(
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
        if (editorState.selectedClipId != null) {
          final updated = TimelineEditingService.splitClip(
            project,
            editorState.selectedClipId!,
            editorState.playheadPositionMs,
          );
          if (updated != null) {
            ref.read(editorProvider.notifier).updateProject(updated);
            ref.read(projectListProvider.notifier).updateProject(updated);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clip split at playhead position'),
                duration: Duration(milliseconds: 900),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Move playhead inside the clip to split'),
                duration: Duration(milliseconds: 1200),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select a clip first to split'),
              duration: Duration(milliseconds: 900),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
        }
        break;

      case EditorTool.text:
        _openTextEditorModal();
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

  void _openTextEditorModal() {
    final targetClip = _findTargetClip();
    if (targetClip != null) {
      TextEditorSheet.show(
        context,
        clip: targetClip,
        onSave: (updatedClip) {
          final project = ref.read(editorProvider).project!;
          final updatedProject = project.updateClip(updatedClip);
          ref.read(editorProvider.notifier).updateProject(updatedProject);
          ref.read(projectListProvider.notifier).updateProject(updatedProject);
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a clip first to add Text & Titles'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _openTransitionsModal() {
    final targetClip = _findTargetClip();
    if (targetClip != null) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a video clip first to add Transitions'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _openSpeedModal() {
    final targetClip = _findTargetClip();
    if (targetClip != null) {
      SpeedRampingSheet.show(
        context,
        clip: targetClip,
        onSave: (updatedClip) {
          final project = ref.read(editorProvider).project!;
          final updatedProject = project.updateClip(updatedClip);
          ref.read(editorProvider.notifier).updateProject(updatedProject);
          ref.read(projectListProvider.notifier).updateProject(updatedProject);
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a clip first to adjust Speed & Curves'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _openColorGradingModal() {
    final targetClip = _findTargetClip();
    if (targetClip != null) {
      ColorGradingSheet.show(
        context,
        clip: targetClip,
        onSave: (updatedClip) {
          final project = ref.read(editorProvider).project!;
          final updatedProject = project.updateClip(updatedClip);
          ref.read(editorProvider.notifier).updateProject(updatedProject);
          ref.read(projectListProvider.notifier).updateProject(updatedProject);
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a clip first to adjust Color & LUTs'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _openAudioToolsModal() {
    final targetClip = _findTargetClip();
    if (targetClip != null) {
      AudioMixerSheet.show(
        context,
        clip: targetClip,
        onSave: (updatedClip) {
          final project = ref.read(editorProvider).project!;
          final updatedProject = project.updateClip(updatedClip);
          ref.read(editorProvider.notifier).updateProject(updatedProject);
          ref.read(projectListProvider.notifier).updateProject(updatedProject);
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add or select a clip first to use Audio & AI Tools'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
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
    } else {
      for (final track in project.tracks) {
        if (track.clips.isNotEmpty) {
          return track.clips.first;
        }
      }
    }
    return null;
  }
}
