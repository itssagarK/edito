import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../../../models/project.dart';
import '../../models/freeze_climax_config.dart';
import '../../services/freeze_climax_service.dart';

class FreezeClimaxSheet extends StatefulWidget {
  final Project project;
  final Clip clip;
  final int playheadPositionMs;
  final Function(Project updatedProject) onProjectUpdated;
  final bool isDocked;
  final VoidCallback? onDone;

  const FreezeClimaxSheet({
    super.key,
    required this.project,
    required this.clip,
    required this.playheadPositionMs,
    required this.onProjectUpdated,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Clip clip,
    required int playheadPositionMs,
    required Function(Project) onProjectUpdated,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => FreezeClimaxSheet(
        project: project,
        clip: clip,
        playheadPositionMs: playheadPositionMs,
        onProjectUpdated: onProjectUpdated,
        onDone: onDone,
      ),
    );
  }

  @override
  State<FreezeClimaxSheet> createState() => _FreezeClimaxSheetState();
}

class _FreezeClimaxSheetState extends State<FreezeClimaxSheet> with SingleTickerProviderStateMixin {
  late FreezeClimaxConfig _config;
  late AnimationController _previewAnim;
  bool _rippleAllTracks = true;

  @override
  void initState() {
    super.initState();
    _config = const FreezeClimaxConfig();
    _previewAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _previewAnim.dispose();
    super.dispose();
  }

  void _triggerSimulation() {
    _previewAnim.reset();
    _previewAnim.forward();
  }

  void _applyClimax() {
    final updated = FreezeClimaxService.insertFreezeClimax(
      widget.project,
      trackId: widget.clip.trackId,
      clipId: widget.clip.id,
      targetPositionMs: widget.playheadPositionMs,
      config: _config,
      rippleAllTracks: _rippleAllTracks,
    );

    widget.onProjectUpdated(updated);
    if (!widget.isDocked) {
      Navigator.of(context).pop();
    } else {
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? sheetHeight = widget.isDocked ? null : MediaQuery.of(context).size.height * 0.70;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.ac_unit, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Action Freeze Frame Climax',
                          style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cinematic action hold with camera punch & styling',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              children: [
                // Live Climax Animation Simulation Card
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141923),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _previewAnim,
                        builder: (context, child) {
                          final t = _previewAnim.value;
                          final isFreezing = t > 0.3 && t < 0.85;
                          final scale = isFreezing ? _config.zoomScale : 1.0;
                          final showFlash = isFreezing && (t - 0.3) < 0.12 && _config.flashAccent;

                          return Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: scale,
                                child: Center(
                                  child: Icon(
                                    Icons.sports_martial_arts,
                                    size: 56,
                                    color: _resolveAccentColor(_config.accentStyle),
                                  ),
                                ),
                              ),
                              if (showFlash)
                                Container(color: Colors.white.withOpacity(0.85)),
                              if (isFreezing)
                                Positioned(
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.pause, color: AppColors.primary, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'FREEZE CLIMAX (${_config.freezeDurationMs}ms)',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: TextButton.icon(
                          onPressed: _triggerSimulation,
                          icon: const Icon(Icons.play_arrow, size: 16, color: AppColors.primary),
                          label: const Text('Test Climax', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Freeze Duration Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Freeze Hold Duration', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${(_config.freezeDurationMs / 1000.0).toStringAsFixed(1)}s (${_config.freezeDurationMs}ms)',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.freezeDurationMs.toDouble(),
                  min: 300,
                  max: 4000,
                  divisions: 37,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(freezeDurationMs: val.round()));
                  },
                ),
                const SizedBox(height: 8),

                // Camera Punch Zoom Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Camera Punch Zoom', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('${_config.zoomScale.toStringAsFixed(2)}x',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _config.zoomScale,
                  min: 1.0,
                  max: 1.8,
                  divisions: 16,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(zoomScale: double.parse(val.toStringAsFixed(2))));
                  },
                ),
                const SizedBox(height: 14),

                // Accent Style Selector
                const Text('Climax Visual Accent', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FreezeAccentStyle.values.map((style) {
                    final isSel = _config.accentStyle == style;
                    return InkWell(
                      onTap: () => setState(() => _config = _config.copyWith(accentStyle: style)),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary.withOpacity(0.20) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          style.label,
                          style: TextStyle(
                            color: isSel ? AppColors.primary : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Toggles
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Impact Shutter Flash', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Bright burst across the cut to heighten the impact', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _config.flashAccent,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _config = _config.copyWith(flashAccent: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mute Audio During Freeze', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Creates dramatic silence for the freeze frame climax', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _config.muteAudioDuringFreeze,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _config = _config.copyWith(muteAudioDuringFreeze: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ripple Shift Audio & Tracks', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: const Text('Keeps all subsequent audio, text, and music clips in sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  value: _rippleAllTracks,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _rippleAllTracks = v),
                ),
              ],
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _applyClimax,
                icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                label: const Text(
                  'Insert Action Freeze Climax',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveAccentColor(FreezeAccentStyle style) {
    switch (style) {
      case FreezeAccentStyle.none:
        return Colors.white;
      case FreezeAccentStyle.monochrome:
        return const Color(0xFFB0BEC5);
      case FreezeAccentStyle.actionGrit:
        return const Color(0xFFFF5252);
      case FreezeAccentStyle.warmSunset:
        return const Color(0xFFFFB300);
      case FreezeAccentStyle.neonInvert:
        return const Color(0xFF00E5FF);
    }
  }
}
