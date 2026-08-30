import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/editor_provider.dart';
import '../../home/providers/project_list_provider.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/preview_viewport.dart';
import 'widgets/timeline_surface.dart';
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
                Navigator.pop(context);
              },
              onUndo: () {},
              onRedo: () {},
              onExport: () {
                _showExportModal(context);
              },
            ),

            // Video Preview Viewport
            Expanded(
              flex: 4,
              child: PreviewViewport(
                currentPositionMs: editorState.playheadPositionMs,
                totalDurationMs: project.durationMs > 0 ? project.durationMs : 30000,
                isPlaying: editorState.isPlaying,
                onTogglePlay: () {
                  ref.read(editorProvider.notifier).togglePlay();
                },
                onStepBackward: () {
                  ref.read(editorProvider.notifier).seek(editorState.playheadPositionMs - 5000);
                },
                onStepForward: () {
                  ref.read(editorProvider.notifier).seek(editorState.playheadPositionMs + 5000);
                },
              ),
            ),

            // Timeline Multi-Track Editor Area
            Expanded(
              flex: 5,
              child: TimelineSurface(
                project: project,
                playheadPositionMs: editorState.playheadPositionMs,
                zoomScale: editorState.zoomScale,
                selectedClipId: editorState.selectedClipId,
                onSeek: (positionMs) {
                  ref.read(editorProvider.notifier).seek(positionMs);
                },
                onSelectClip: (clipId, {trackId}) {
                  ref.read(editorProvider.notifier).selectClip(clipId, trackId: trackId);
                },
              ),
            ),

            // Bottom Editing Toolbar
            EditingToolbar(
              activeTool: editorState.activeTool,
              hasSelectedClip: editorState.selectedClipId != null,
              onSelectTool: (tool) {
                ref.read(editorProvider.notifier).setActiveTool(tool);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tool selected: ${tool.name.toUpperCase()} (Available in Phase 2-8)'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                );
              },
              onAddTrack: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add track feature configured for Phase 2'),
                    duration: Duration(seconds: 1),
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
