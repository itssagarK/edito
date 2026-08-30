import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/editor_provider.dart';
import '../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../home/providers/project_list_provider.dart';
import '../../media/presentation/media_picker_sheet.dart';
import '../../preview/presentation/widgets/realtime_preview_viewport.dart';
import '../../preview/providers/preview_playback_provider.dart';
import '../../timeline/presentation/widgets/interactive_timeline.dart';
import '../../timeline/services/timeline_editing_service.dart';
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
              onUndo: () {},
              onRedo: () {},
              onExport: () {
                _showExportModal(context);
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

      case EditorTool.audio:
        _openAudioToolsModal();
        break;

      case EditorTool.speed:
        if (editorState.selectedClipId != null) {
          _showSpeedDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select a clip first to adjust speed'),
              duration: Duration(milliseconds: 900),
              backgroundColor: AppColors.surfaceElevated,
            ),
          );
        }
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

  void _openAudioToolsModal() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null) return;

    // Find selected clip or first available clip
    Clip? targetClip;
    if (editorState.selectedClipId != null) {
      for (final track in project.tracks) {
        for (final clip in track.clips) {
          if (clip.id == editorState.selectedClipId) {
            targetClip = clip;
            break;
          }
        }
        if (targetClip != null) break;
      }
    } else {
      for (final track in project.tracks) {
        if (track.clips.isNotEmpty) {
          targetClip = track.clips.first;
          break;
        }
      }
    }

    if (targetClip != null) {
      AudioMixerSheet.show(
        context,
        clip: targetClip,
        onSave: (updatedClip) {
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

  void _showSpeedDialog() {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null || editorState.selectedClipId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Clip Speed Ramping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 4.0].map((speed) {
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: false,
                    onSelected: (selected) {
                      Navigator.pop(context);
                      for (final track in project.tracks) {
                        for (final clip in track.clips) {
                          if (clip.id == editorState.selectedClipId) {
                            final updatedClip = clip.copyWith(speed: speed);
                            final updatedProject = project.updateClip(updatedClip);
                            ref.read(editorProvider.notifier).updateProject(updatedProject);
                            ref.read(projectListProvider.notifier).updateProject(updatedProject);
                            return;
                          }
                        }
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Project (FFmpeg Pipeline)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Resolution: 1080p Full HD (1920x1080)\nFramerate: 30 FPS\nFormat: MP4 (H.264 / AAC)',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export pipeline will be connected in Phase 8 (FFmpeg render graph)'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Render Video'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
