import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/beat_detection_config.dart';
import '../../services/beat_detector_service.dart';

class BeatDetectionSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;
  final int currentPlayheadMs;

  const BeatDetectionSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
    this.currentPlayheadMs = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    int currentPlayheadMs = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => BeatDetectionSheet(
        clip: clip,
        onSave: onSave,
        currentPlayheadMs: currentPlayheadMs,
      ),
    );
  }

  @override
  State<BeatDetectionSheet> createState() => _BeatDetectionSheetState();
}

class _BeatDetectionSheetState extends State<BeatDetectionSheet> {
  late BeatDetectionConfig _config;
  final List<int> _tapTimestamps = [];

  @override
  void initState() {
    super.initState();
    _config = widget.clip.beatConfig;
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(beatConfig: _config);
    widget.onSave(updated);
  }

  void _runAutoDetection({double sensitivity = 0.70}) {
    final beats = BeatDetectorService.autoDetectBeats(
      durationMs: widget.clip.durationMs,
      bpm: _config.bpm,
      sensitivity: sensitivity,
    );

    setState(() {
      _config = _config.copyWith(
        isEnabled: true,
        mode: BeatDetectionMode.auto,
        sensitivity: sensitivity,
        beatTimestampsMs: beats,
      );
    });
    _applyChange();
  }

  void _handleTapTempo() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _tapTimestamps.add(nowMs);
    if (_tapTimestamps.length > 8) {
      _tapTimestamps.removeAt(0);
    }

    final calculatedBpm = BeatDetectorService.calculateBpmFromTaps(_tapTimestamps);

    // Also add a beat marker at current playhead relative to clip
    final relPlayheadMs = (widget.currentPlayheadMs - widget.clip.startTimeMs).clamp(0, widget.clip.durationMs);
    final updated = BeatDetectorService.addManualBeat(_config, relPlayheadMs);

    setState(() {
      _config = updated.copyWith(
        bpm: calculatedBpm,
        mode: BeatDetectionMode.manual,
      );
    });
    _applyChange();
  }

  void _toggleBeatAtPlayhead() {
    final relPlayheadMs = (widget.currentPlayheadMs - widget.clip.startTimeMs).clamp(0, widget.clip.durationMs);
    final nearBeat = _config.beatTimestampsMs.any((b) => (b - relPlayheadMs).abs() < 120);

    if (nearBeat) {
      setState(() {
        _config = BeatDetectorService.removeNearBeat(_config, relPlayheadMs);
      });
    } else {
      setState(() {
        _config = BeatDetectorService.addManualBeat(_config, relPlayheadMs);
      });
    }
    _applyChange();
  }

  void _clearAllBeats() {
    setState(() {
      _config = _config.copyWith(
        isEnabled: false,
        beatTimestampsMs: [],
      );
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.52;
    final badge = BeatDetectorService.getBeatsBadge(_config);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children: [
                if (!widget.isDocked)
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.music_note, color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text('Beats & Rhythm Snapping', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        if (badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 18),
                      onPressed: () {
                        if (widget.onDone != null) {
                          widget.onDone!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Presets & Tap Tempo Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.touch_app, size: 18),
                    label: const Text('TAP BEAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _handleTapTempo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD700)),
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('AUTO DETECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _runAutoDetection(sensitivity: _config.sensitivity),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Scrollable Settings List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // Quick Mode Selection Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildPresetCard(
                        title: 'Beat 1 (Drops)',
                        subtitle: 'Primary kicks',
                        isActive: _config.hasBeats && _config.sensitivity <= 0.60,
                        onTap: () => _runAutoDetection(sensitivity: 0.50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPresetCard(
                        title: 'Beat 2 (All)',
                        subtitle: 'Full rhythm pulse',
                        isActive: _config.hasBeats && _config.sensitivity > 0.60,
                        onTap: () => _runAutoDetection(sensitivity: 0.85),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Magnetic Snapping Switch Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Magnetic Beat Snapping', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Snap cuts, trims, and playhead magnetically to beats', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    value: _config.snapToBeats,
                    activeColor: const Color(0xFFFFD700),
                    onChanged: (val) {
                      setState(() => _config = _config.copyWith(snapToBeats: val));
                      _applyChange();
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Tempo BPM Slider
                _buildSliderCard(
                  title: 'Tempo / BPM',
                  valueText: '${_config.bpm.toInt()} BPM',
                  color: const Color(0xFFFFD700),
                  value: _config.bpm,
                  min: 50.0,
                  max: 200.0,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(bpm: double.parse(v.toStringAsFixed(0))));
                    _applyChange();
                  },
                ),

                const SizedBox(height: 8),

                // Sensitivity Slider
                _buildSliderCard(
                  title: 'Detection Sensitivity',
                  valueText: '${(_config.sensitivity * 100).toInt()}%',
                  color: AppColors.accent,
                  value: _config.sensitivity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(sensitivity: v));
                    _applyChange();
                  },
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.add_location_alt, size: 16, color: Color(0xFFFFD700)),
                        label: const Text('Toggle Beat at Playhead', style: TextStyle(fontSize: 11)),
                        onPressed: _toggleBeatAtPlayhead,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      icon: const Icon(Icons.clear_all, size: 16, color: Colors.redAccent),
                      label: const Text('Clear', style: TextStyle(fontSize: 11)),
                      onPressed: _clearAllBeats,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700).withOpacity(0.15) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : AppColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String valueText,
    required Color color,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(valueText, style: AppTypography.timecode.copyWith(fontSize: 11, color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: color,
              inactiveColor: AppColors.border,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
