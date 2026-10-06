import 'dart:math';
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/media_asset.dart';
import '../../../../models/project.dart';
import '../../services/ai_scene_detector_service.dart';

/// 100% Offline, On-Device AI Scene Cut & Shot Boundary Detector Studio.
///
/// Uses differential frame luminance analysis and color histogram deltas
/// to identify camera shot transitions, scene changes, and hard cuts in raw video footage.
class AiSceneDetectorSheet extends StatefulWidget {
  final Clip clip;
  final Project project;
  final Function(Project updatedProject) onProjectUpdated;
  final bool isDocked;
  final VoidCallback? onDone;

  const AiSceneDetectorSheet({
    super.key,
    required this.clip,
    required this.project,
    required this.onProjectUpdated,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Project project,
    required Function(Project) onProjectUpdated,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => AiSceneDetectorSheet(
        clip: clip,
        project: project,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AiSceneDetectorSheet> createState() => _AiSceneDetectorSheetState();
}

class _AiSceneDetectorSheetState extends State<AiSceneDetectorSheet> {
  late Clip _currentClip;
  late Project _currentProject;
  bool _isScanning = false;
  SceneCutAnalysisResult? _analysis;
  double _sensitivity = 0.40;

  @override
  void initState() {
    super.initState();
    _currentClip = widget.clip;
    _currentProject = widget.project;
    _runScan();
  }

  String _getMediaPath() {
    final asset = _currentProject.assets.firstWhere(
      (a) => a.id == _currentClip.assetId,
      orElse: () => const MediaAsset(id: '', path: '', fileName: '', type: MediaType.video, durationMs: 0),
    );
    return asset.path.isNotEmpty ? asset.path : _currentClip.assetId;
  }

  Future<void> _runScan() async {
    setState(() => _isScanning = true);
    try {
      final mediaPath = _getMediaPath();
      final result = await AiSceneDetectorService.detectSceneCuts(
        videoPath: mediaPath,
        durationMs: _currentClip.durationMs,
        sensitivity: _sensitivity,
      );
      if (mounted) {
        setState(() => _analysis = result);
      }
    } catch (e) {
      debugPrint('AI Scene detector error: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _applySceneSplits() {
    if (_analysis == null || _analysis!.cutTimestampsMs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No shot cuts detected to split.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    final updated = AiSceneDetectorService.splitClipAtSceneCuts(
      project: _currentProject,
      clipId: _currentClip.id,
      cutTimestampsMs: _analysis!.cutTimestampsMs,
    );

    if (updated != null) {
      _currentProject = updated;
      widget.onProjectUpdated(updated);

      final cutCount = _analysis!.totalCuts;
      final sceneCount = _analysis!.totalScenes;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎬 AI Scene Split: Created $sceneCount scene clips from $cutCount cuts!'),
          duration: const Duration(milliseconds: 1600),
          backgroundColor: const Color(0xFF2979FF),
        ),
      );

      setState(() {
        _analysis = null;
      });

      widget.onDone?.call();
      if (!widget.isDocked) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF651FFF), Color(0xFF2979FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.movie_filter, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('AI Scene Cut Detector', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF20BF6B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF20BF6B), width: 0.8),
                            ),
                            child: const Text(
                              'OFFLINE CV',
                              style: TextStyle(
                                color: Color(0xFF20BF6B),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                        onPressed: widget.onDone ?? () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(28, 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Body Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.video_library_outlined, color: Color(0xFF2979FF), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scans frame differential luminance and color histogram shifts on-device to detect camera shot changes and automatically split continuous raw footage into scene clips.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Visual Timeline Cut Mapping Strip
                Text('SHOT TRANSITION TIMELINE MAPPING', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 6),
                _buildTimelineVisualization(),
                const SizedBox(height: 14),

                // Analysis Metrics Cards
                if (_analysis != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.content_cut,
                          iconColor: const Color(0xFF2979FF),
                          label: 'Scene Cuts',
                          value: '${_analysis!.totalCuts}',
                          unit: 'transitions',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.movie_outlined,
                          iconColor: const Color(0xFF00E676),
                          label: 'Resulting Scenes',
                          value: '${_analysis!.totalScenes}',
                          unit: 'sub-clips',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.timelapse,
                          iconColor: const Color(0xFFFFAB00),
                          label: 'Avg Shot Length',
                          value: _analysis!.totalScenes > 0
                              ? ((_currentClip.durationMs / _analysis!.totalScenes) / 1000.0).toStringAsFixed(1)
                              : '0.0',
                          unit: 'seconds',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Sensitivity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cut Sensitivity Threshold', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      _sensitivity < 0.35 ? 'Longer Shots' : (_sensitivity > 0.65 ? 'Frequent Cuts' : 'Standard (${(_sensitivity * 100).round()}%)'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _sensitivity,
                  min: 0.15,
                  max: 0.85,
                  divisions: 14,
                  activeColor: const Color(0xFF2979FF),
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setState(() => _sensitivity = val);
                  },
                  onChangeEnd: (_) => _runScan(),
                ),
                const SizedBox(height: 10),

                // Detected Scenes List
                if (_analysis != null && _analysis!.scenes.isNotEmpty) ...[
                  Text('DETECTED SCENE SEGMENTS', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: min(8, _analysis!.scenes.length),
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, idx) {
                        final scene = _analysis!.scenes[idx];
                        final startSec = (scene[0] / 1000.0).toStringAsFixed(1);
                        final endSec = (scene[1] / 1000.0).toStringAsFixed(1);
                        final durationSec = ((scene[1] - scene[0]) / 1000.0).toStringAsFixed(1);

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF2979FF).withOpacity(0.2),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2979FF)),
                            ),
                          ),
                          title: Text(
                            'Scene ${idx + 1}: ${startSec}s → ${endSec}s',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          trailing: Text(
                            '${durationSec}s',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isScanning ? null : _runScan,
                  icon: _isScanning
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: (_analysis == null || _analysis!.cutTimestampsMs.isEmpty || _isScanning)
                        ? null
                        : _applySceneSplits,
                    icon: const Icon(Icons.movie_filter, size: 16),
                    label: Text(
                      _analysis != null && _analysis!.cutTimestampsMs.isNotEmpty
                          ? 'Split into ${_analysis!.totalScenes} Scenes'
                          : 'No Cuts to Split',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineVisualization() {
    final duration = _currentClip.durationMs;
    if (_isScanning) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2979FF))),
              SizedBox(width: 8),
              Text('Analyzing differential frame transitions...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    if (_analysis == null || duration <= 0) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Tap Re-Scan to analyze clip transitions', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
      );
    }

    final scenes = _analysis!.scenes;
    final cuts = _analysis!.cutTimestampsMs;

    return Column(
      children: [
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              return Stack(
                children: [
                  // Draw Alternating Scenes
                  for (int i = 0; i < scenes.length; i++)
                    Positioned(
                      left: (scenes[i][0] / duration) * totalW,
                      width: max(2.0, ((scenes[i][1] - scenes[i][0]) / duration) * totalW),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: i.isEven
                            ? const Color(0xFF2979FF).withOpacity(0.55)
                            : const Color(0xFF651FFF).withOpacity(0.55),
                      ),
                    ),
                  // Draw Cut Markers
                  for (final cut in cuts)
                    Positioned(
                      left: (cut / duration) * totalW - 1,
                      width: 2,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, color: const Color(0xFF2979FF)),
                const SizedBox(width: 4),
                const Text('Scenes (Sub-clips)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                Container(width: 2, height: 10, color: Colors.white),
                const SizedBox(width: 4),
                const Text('Shot Cut Boundary', style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
