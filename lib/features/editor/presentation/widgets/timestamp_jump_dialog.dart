import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../../../timeline/services/timeline_editing_service.dart';

/// Modal dialog allowing precision timestamp scrub, frame-by-frame stepping,
/// cut-to-cut boundary jumps, and SMPTE navigation.
class TimestampJumpDialog extends StatefulWidget {
  final Project project;
  final int initialPositionMs;
  final ValueChanged<int> onSeek;

  const TimestampJumpDialog({
    super.key,
    required this.project,
    required this.initialPositionMs,
    required this.onSeek,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required int currentPositionMs,
    required ValueChanged<int> onSeek,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TimestampJumpDialog(
        project: project,
        initialPositionMs: currentPositionMs,
        onSeek: onSeek,
      ),
    );
  }

  @override
  State<TimestampJumpDialog> createState() => _TimestampJumpDialogState();
}

class _TimestampJumpDialogState extends State<TimestampJumpDialog> {
  late int _positionMs;

  @override
  void initState() {
    super.initState();
    _positionMs = widget.initialPositionMs;
  }

  void _updatePosition(int newMs) {
    final maxMs = widget.project.durationMs > 0 ? widget.project.durationMs : 10000;
    final clamped = newMs.clamp(0, maxMs);
    setState(() {
      _positionMs = clamped;
    });
    HapticFeedback.selectionClick();
    widget.onSeek(clamped);
  }

  void _stepFrames(int deltaFrames) {
    final fps = widget.project.fps > 0 ? widget.project.fps.round() : 30;
    final frameDurationMs = (1000 / fps).round();
    _updatePosition(_positionMs + (deltaFrames * frameDurationMs));
  }

  void _jumpToPreviousCut() {
    final prevCut = TimelineEditingService.findPreviousCutPoint(widget.project, _positionMs);
    if (prevCut != null) {
      _updatePosition(prevCut);
    }
  }

  void _jumpToNextCut() {
    final nextCut = TimelineEditingService.findNextCutPoint(widget.project, _positionMs);
    if (nextCut != null) {
      _updatePosition(nextCut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.project.durationMs > 0 ? widget.project.durationMs : 10000;
    final progress = (totalMs > 0) ? (_positionMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final fps = widget.project.fps > 0 ? widget.project.fps.round() : 30;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.av_timer, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Jump to Timestamp',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Primary Digital Timecode Readout HUD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceElevated,
                      AppColors.surfaceElevated.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      TimecodeFormatter.formatMilliseconds(_positionMs),
                      style: AppTypography.timecode.copyWith(
                        fontSize: 32,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'SMPTE: ${TimecodeFormatter.formatSmpte(_positionMs, fps: fps)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ ${TimecodeFormatter.formatMilliseconds(totalMs)} (${(progress * 100).toStringAsFixed(0)}%)',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Live Scrub Slider
              Row(
                children: [
                  Text(
                    '00:00.00',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: Colors.white,
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: _positionMs.toDouble().clamp(0.0, totalMs.toDouble()),
                        min: 0.0,
                        max: totalMs.toDouble(),
                        onChanged: (val) {
                          _updatePosition(val.toInt());
                        },
                      ),
                    ),
                  ),
                  Text(
                    TimecodeFormatter.formatMilliseconds(totalMs),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quick Cut & Boundary Navigation Row
              Row(
                children: [
                  Expanded(
                    child: _buildJumpButton(
                      label: '|◀ Start',
                      icon: Icons.first_page,
                      onTap: () => _updatePosition(0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildJumpButton(
                      label: '◀ Prev Cut',
                      icon: Icons.skip_previous,
                      onTap: _jumpToPreviousCut,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildJumpButton(
                      label: 'Next Cut ▶',
                      icon: Icons.skip_next,
                      onTap: _jumpToNextCut,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildJumpButton(
                      label: 'End ▶|',
                      icon: Icons.last_page,
                      onTap: () => _updatePosition(totalMs),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Precision Frame-by-Frame Stepping Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepButton(
                      label: '-1s',
                      tooltip: 'Back 1 second',
                      onTap: () => _updatePosition(_positionMs - 1000),
                    ),
                    _buildStepButton(
                      label: '-1 Frame',
                      icon: Icons.chevron_left,
                      tooltip: 'Back 1 frame (~${(1000 / fps).round()}ms)',
                      onTap: () => _stepFrames(-1),
                    ),
                    Container(width: 1, height: 20, color: AppColors.border),
                    _buildStepButton(
                      label: '+1 Frame',
                      icon: Icons.chevron_right,
                      tooltip: 'Forward 1 frame (~${(1000 / fps).round()}ms)',
                      onTap: () => _stepFrames(1),
                    ),
                    _buildStepButton(
                      label: '+1s',
                      tooltip: 'Forward 1 second',
                      onTap: () => _updatePosition(_positionMs + 1000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Percentage Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPercentChip('0%', 0.0, totalMs),
                  _buildPercentChip('25%', 0.25, totalMs),
                  _buildPercentChip('50%', 0.50, totalMs),
                  _buildPercentChip('75%', 0.75, totalMs),
                  _buildPercentChip('100%', 1.0, totalMs),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJumpButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton({
    required String label,
    IconData? icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.accent),
                const SizedBox(width: 2),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentChip(String label, double ratio, int totalMs) {
    final targetMs = (totalMs * ratio).round();
    final isSelected = (_positionMs - targetMs).abs() < 100;

    return InkWell(
      onTap: () => _updatePosition(targetMs),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
