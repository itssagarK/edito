import 'dart:math';
import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/media_asset.dart';
import '../../../../models/project.dart';
import '../../services/ai_silence_remover_service.dart';

/// 100% Offline, On-Device AI Silence Remover & Smart Jump-Cut Studio.
///
/// Discovers dead-air pauses and unvoiced gaps using Voice Activity Detection (VAD)
/// and ripple-excises them into snappy, high-retention video/audio jump cuts.
class AiSilenceRemoverSheet extends StatefulWidget {
  final Clip clip;
  final Project project;
  final Function(Project updatedProject) onProjectUpdated;
  final bool isDocked;
  final VoidCallback? onDone;

  const AiSilenceRemoverSheet({
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
      builder: (context) => AiSilenceRemoverSheet(
        clip: clip,
        project: project,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<AiSilenceRemoverSheet> createState() => _AiSilenceRemoverSheetState();
}

class _AiSilenceRemoverSheetState extends State<AiSilenceRemoverSheet> {
  late Clip _currentClip;
  late Project _currentProject;
  bool _isAnalyzing = false;
  SilenceAnalysisResult? _analysis;

  double _sensitivity = 0.70;
  int _minSilenceMs = 350;
  int _paddingMs = 40;

  @override
  void initState() {
    super.initState();
    _currentClip = widget.clip;
    _currentProject = widget.project;
    _runAnalysis();
  }

  String _getMediaPath() {
    final asset = _currentProject.assets.firstWhere(
      (a) => a.id == _currentClip.assetId,
      orElse: () => const MediaAsset(id: '', path: '', fileName: '', type: MediaType.video, durationMs: 0),
    );
    return asset.path.isNotEmpty ? asset.path : _currentClip.assetId;
  }

  Future<void> _runAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final mediaPath = _getMediaPath();
      final result = await AiSilenceRemoverService.analyzeClipForSilences(
        clip: _currentClip,
        mediaPath: mediaPath,
        minSilenceMs: _minSilenceMs,
        sensitivity: _sensitivity,
      );
      if (mounted) {
        setState(() => _analysis = result);
      }
    } catch (e) {
      debugPrint('AI Silence remover analysis error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _applyJumpCut() {
    if (_analysis == null || _analysis!.silenceSegments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No dead-air pauses to remove in this clip.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    final updated = AiSilenceRemoverService.removeSilencesFromClip(
      project: _currentProject,
      clipId: _currentClip.id,
      analysis: _analysis!,
      paddingMs: _paddingMs,
    );

    if (updated != null) {
      _currentProject = updated;
      widget.onProjectUpdated(updated);

      final count = _analysis!.silenceCount;
      final savedSec = (_analysis!.totalSilenceDurationMs / 1000.0).toStringAsFixed(1);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✂️ AI Jump-Cut Applied: Removed $count silences (saved ${savedSec}s dead air)!'),
          duration: const Duration(milliseconds: 1600),
          backgroundColor: const Color(0xFF00E676),
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
                                colors: [Color(0xFF00B0FF), Color(0xFF00E676)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.content_cut, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('AI Silence Remover', style: AppTypography.titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF20BF6B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF20BF6B), width: 0.8),
                            ),
                            child: const Text(
                              'OFFLINE VAD',
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
                      Icon(Icons.mic_none, color: Color(0xFF00E676), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Detects dead air, hesitant pauses, and empty gaps using local Voice Activity Detection, then ripple-excises them to create snappy social jump-cuts.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Visual Waveform Speech vs Silence Strip
                Text('VOICE & SILENCE TIMELINE MAPPING', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 6),
                _buildTimelineVisualization(),
                const SizedBox(height: 14),

                // Analysis Metrics Cards
                if (_analysis != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.pause_circle_outline,
                          iconColor: const Color(0xFFFF5252),
                          label: 'Silences Found',
                          value: '${_analysis!.silenceCount}',
                          unit: 'pauses',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.timer_outlined,
                          iconColor: const Color(0xFFFFAB00),
                          label: 'Dead-Air Time',
                          value: (_analysis!.totalSilenceDurationMs / 1000.0).toStringAsFixed(1),
                          unit: 'seconds',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.record_voice_over,
                          iconColor: const Color(0xFF00E676),
                          label: 'Speech Active',
                          value: '${_analysis!.speechPercentage.round()}%',
                          unit: 'retention',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Control Sliders
                // 1. Sensitivity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('VAD Voice Sensitivity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      _sensitivity < 0.5 ? 'Conservative' : (_sensitivity > 0.8 ? 'Aggressive' : 'Balanced (${(_sensitivity * 100).round()}%)'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _sensitivity,
                  min: 0.20,
                  max: 0.95,
                  divisions: 15,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setState(() => _sensitivity = val);
                  },
                  onChangeEnd: (_) => _runAnalysis(),
                ),

                // 2. Minimum Silence Duration Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Minimum Silence Pause', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${_minSilenceMs}ms', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ],
                ),
                Slider(
                  value: _minSilenceMs.toDouble(),
                  min: 200,
                  max: 1200,
                  divisions: 20,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setState(() => _minSilenceMs = val.round());
                  },
                  onChangeEnd: (_) => _runAnalysis(),
                ),

                // 3. Syllable Padding Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Word Boundary Padding (Anti-Clip)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${_paddingMs}ms', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E676))),
                  ],
                ),
                Slider(
                  value: _paddingMs.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  activeColor: const Color(0xFF00E676),
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setState(() => _paddingMs = val.round());
                  },
                ),
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
                  onPressed: _isAnalyzing ? null : _runAnalysis,
                  icon: _isAnalyzing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: (_analysis == null || _analysis!.silenceSegments.isEmpty || _isAnalyzing)
                        ? null
                        : _applyJumpCut,
                    icon: const Icon(Icons.content_cut, size: 16, color: Colors.black),
                    label: Text(
                      _analysis != null && _analysis!.silenceSegments.isNotEmpty
                          ? 'Auto Jump-Cut (${_analysis!.silenceCount} Silences)'
                          : 'No Silences Found',
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
    if (_isAnalyzing) {
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
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
              SizedBox(width: 8),
              Text('Analyzing audio voice energy...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
          child: Text('Tap Re-Scan to analyze clip audio', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
      );
    }

    final speechSegs = _analysis!.speechSegments;
    final silenceSegs = _analysis!.silenceSegments;

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
                  // Draw Speech Segments (Green)
                  for (final seg in speechSegs)
                    Positioned(
                      left: (seg[0] / duration) * totalW,
                      width: max(2.0, ((seg[1] - seg[0]) / duration) * totalW),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: const Color(0xFF00E676).withOpacity(0.75),
                      ),
                    ),
                  // Draw Silence Segments (Red/Orange stripes)
                  for (final s in silenceSegs)
                    Positioned(
                      left: (s[0] / duration) * totalW,
                      width: max(2.0, ((s[1] - s[0]) / duration) * totalW),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        color: const Color(0xFFFF5252).withOpacity(0.85),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF00E676), size: 8),
                SizedBox(width: 4),
                Text('Active Speech (Keep)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.circle, color: Color(0xFFFF5252), size: 8),
                SizedBox(width: 4),
                Text('Dead-Air Silence (Excise)', style: TextStyle(fontSize: 10, color: Color(0xFFFF5252))),
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
