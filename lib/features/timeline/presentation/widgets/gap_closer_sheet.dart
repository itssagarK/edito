import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../services/gap_closer_service.dart';

/// Interactive Sheet for Finding and Ripple-Closing Timeline Micro-Gaps.
class GapCloserSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onProjectUpdated;
  final bool isDocked;
  final VoidCallback? onDone;

  const GapCloserSheet({
    super.key,
    required this.project,
    required this.onProjectUpdated,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onProjectUpdated,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => GapCloserSheet(
        project: project,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<GapCloserSheet> createState() => _GapCloserSheetState();
}

class _GapCloserSheetState extends State<GapCloserSheet> {
  late Project _currentProject;
  late GapAnalysisResult _analysis;
  int _maxGapThresholdMs = 1000;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _runAnalysis();
  }

  void _runAnalysis() {
    setState(() {
      _analysis = GapCloserService.analyzeGaps(
        _currentProject,
        minGapMs: 15,
        maxGapMs: _maxGapThresholdMs,
      );
    });
  }

  void _handleCloseGaps() {
    final updated = GapCloserService.closeAllGaps(
      _currentProject,
      minGapMs: 15,
      maxGapMs: _maxGapThresholdMs,
    );

    if (updated != null) {
      final closedCount = _analysis.totalGapsFound;
      final savedSec = (_analysis.totalGapDurationMs / 1000.0).toStringAsFixed(2);

      setState(() {
        _currentProject = updated;
        _runAnalysis();
      });

      widget.onProjectUpdated(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Closed $closedCount micro-gaps (rippled ${savedSec}s of blank flashes)!'),
          duration: const Duration(milliseconds: 1400),
          backgroundColor: const Color(0xFF00E676),
        ),
      );

      widget.onDone?.call();
      if (!widget.isDocked) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeline is clean! No accidental gaps detected.'),
          duration: Duration(milliseconds: 1000),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.58;

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
                                colors: [Color(0xFF26A69A), Color(0xFF00B0FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.space_bar, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('Timeline Micro-Gap Closer', style: AppTypography.titleLarge),
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
                      Icon(Icons.info_outline, color: Color(0xFF00B0FF), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Detects accidental black flashes and micro-pauses between clips on your tracks, then ripples subsequent clips to seal every gap seamlessly.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.flash_on_outlined,
                        iconColor: _analysis.hasGaps ? const Color(0xFFFF5252) : const Color(0xFF00E676),
                        label: 'Black Flashes',
                        value: '${_analysis.totalGapsFound}',
                        unit: 'gaps',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFFFFAB00),
                        label: 'Blank Duration',
                        value: (_analysis.totalGapDurationMs / 1000.0).toStringAsFixed(2),
                        unit: 'seconds',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.layers_outlined,
                        iconColor: const Color(0xFF00B0FF),
                        label: 'Affected Tracks',
                        value: '${_analysis.gapsByTrack.length}',
                        unit: 'lanes',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Threshold Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Gap Detection Threshold', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${_maxGapThresholdMs}ms', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ],
                ),
                Slider(
                  value: _maxGapThresholdMs.toDouble(),
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  activeColor: const Color(0xFF00B0FF),
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setState(() => _maxGapThresholdMs = val.round());
                    _runAnalysis();
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gaps shorter than this threshold will be identified as accidental and closed automatically.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Bottom Action
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
                  onPressed: _runAnalysis,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _analysis.hasGaps ? const Color(0xFF00E676) : AppColors.surfaceElevated,
                      foregroundColor: _analysis.hasGaps ? Colors.black : AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                    onPressed: _analysis.hasGaps ? _handleCloseGaps : null,
                    icon: const Icon(Icons.space_bar, size: 16),
                    label: Text(
                      _analysis.hasGaps
                          ? 'Close ${_analysis.totalGapsFound} Gaps (Ripple)'
                          : 'Timeline Clean (0 Gaps)',
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
