import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../services/beat_cutter_service.dart';

class BeatCutterSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onProjectUpdated;
  final bool isDocked;
  final VoidCallback? onDone;

  const BeatCutterSheet({
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
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => BeatCutterSheet(
        project: project,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<BeatCutterSheet> createState() => _BeatCutterSheetState();
}

class _BeatCutterSheetState extends State<BeatCutterSheet> {
  late Project _project;
  late String _selectedTrackId;
  int _cadence = 2; // Every 2nd beat default
  int _minDurationMs = 300;
  bool _useTempoGrid = false;
  double _gridBpm = 120.0;

  @override
  void initState() {
    super.initState();
    _project = widget.project;

    // Default to first video track
    final videoTracks = _project.tracks.where((t) => t.type == TrackType.video && !t.isHidden).toList();
    if (videoTracks.isNotEmpty) {
      _selectedTrackId = videoTracks.first.id;
    } else if (_project.tracks.isNotEmpty) {
      _selectedTrackId = _project.tracks.first.id;
    } else {
      _selectedTrackId = '';
    }
  }

  List<int> _getEffectiveBeats() {
    if (_useTempoGrid) {
      return BeatCutterService.generateTempoGridBeats(
        bpm: _gridBpm,
        durationMs: _project.durationMs,
      );
    }
    final detected = BeatCutterService.gatherProjectBeats(_project);
    if (detected.isNotEmpty) return detected;

    // Fallback to tempo grid if no detected audio beats exist
    return BeatCutterService.generateTempoGridBeats(
      bpm: _gridBpm,
      durationMs: _project.durationMs,
    );
  }

  void _executeBeatCut() {
    final beats = _getEffectiveBeats();
    if (beats.isEmpty || _selectedTrackId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No beats or video tracks found to cut.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    final res = BeatCutterService.cutTrackOnBeats(
      project: _project,
      trackId: _selectedTrackId,
      beatTimestampsMs: beats,
      beatCadence: _cadence,
      minClipDurationMs: _minDurationMs,
    );

    setState(() {
      _project = res.project;
    });
    widget.onProjectUpdated(res.project);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✂️ Created ${res.cutsCreated} rhythmic beat cuts across ${res.beatsProcessed} beats!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _executeBeatSnap() {
    final beats = _getEffectiveBeats();
    if (beats.isEmpty || _selectedTrackId.isEmpty) return;

    final snapped = BeatCutterService.snapClipsToBeats(
      project: _project,
      trackId: _selectedTrackId,
      beatTimestampsMs: beats,
      snapToleranceMs: 200,
    );

    setState(() {
      _project = snapped;
    });
    widget.onProjectUpdated(snapped);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧲 Video cuts locked & snapped to nearest musical beats!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBeats = _getEffectiveBeats();
    final videoTracks = _project.tracks.where((t) => t.type == TrackType.video).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isDocked) ...[
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
                        const Icon(Icons.music_note, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Auto Beat Cut Studio', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: widget.onDone ?? () => Navigator.pop(context),
                      style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Metric Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.graphic_eq, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${effectiveBeats.length} Musical Beats Ready',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _useTempoGrid ? 'Generated from $_gridBpm BPM tempo grid' : 'Detected from audio track markers',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Track Selector if multiple video tracks
              if (videoTracks.length > 1) ...[
                const Text('Target Video Track', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: videoTracks.map((t) {
                    final isSel = _selectedTrackId == t.id;
                    return ChoiceChip(
                      label: Text(t.name.isNotEmpty ? t.name : 'Track ${t.id.substring(0, 4)}'),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedTrackId = t.id),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textSecondary, fontSize: 11),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],

              // Cadence Selector
              const Text('Rhythm Cut Cadence', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildCadenceCard(1, 'Fast / Energetic', 'Every Beat (1x)'),
                  const SizedBox(width: 8),
                  _buildCadenceCard(2, 'Balanced Rhythm', 'Every 2nd (2x)'),
                  const SizedBox(width: 8),
                  _buildCadenceCard(4, 'Cinematic Bars', 'Every 4th (4x)'),
                ],
              ),
              const SizedBox(height: 14),

              // Source Switch: Track Audio vs Tempo Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Force Mathematical BPM Grid', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  Switch(
                    value: _useTempoGrid,
                    activeColor: AppColors.accent,
                    onChanged: (val) => setState(() => _useTempoGrid = val),
                  ),
                ],
              ),
              if (_useTempoGrid) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tempo (BPM)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('${_gridBpm.round()} BPM', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _gridBpm,
                  min: 60.0,
                  max: 180.0,
                  divisions: 24,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() => _gridBpm = v),
                ),
              ],

              // Min Duration Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Minimum Clip Duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${_minDurationMs}ms', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Slider(
                value: _minDurationMs.toDouble(),
                min: 150.0,
                max: 800.0,
                divisions: 13,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _minDurationMs = v.round()),
              ),
              const SizedBox(height: 10),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.content_cut, size: 16),
                      label: const Text('Auto-Cut on Beats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _executeBeatCut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.center_focus_strong, size: 16),
                      label: const Text('Snap Cuts to Beat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _executeBeatSnap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(color: AppColors.accent.withOpacity(0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCadenceCard(int value, String title, String subtitle) {
    final isSelected = _cadence == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _cadence = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
