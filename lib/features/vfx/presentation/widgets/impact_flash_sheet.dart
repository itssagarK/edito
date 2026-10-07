import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/impact_flash_config.dart';

class ImpactFlashSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ImpactFlashSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.20),
      backgroundColor: Colors.transparent,
      builder: (context) => ImpactFlashSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ImpactFlashSheet> createState() => _ImpactFlashSheetState();
}

class _ImpactFlashSheetState extends State<ImpactFlashSheet> with SingleTickerProviderStateMixin {
  late ImpactFlashConfig _config;
  late AnimationController _simulatorController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.impactFlash;
    _simulatorController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _config.durationMs > 0 ? _config.durationMs : 200),
    );
  }

  @override
  void dispose() {
    _simulatorController.dispose();
    super.dispose();
  }

  void _apply(ImpactFlashConfig newConfig) {
    setState(() => _config = newConfig);
    widget.onSave(widget.clip.copyWith(impactFlash: newConfig));
  }

  void _triggerFlashTest() {
    _simulatorController.duration = Duration(milliseconds: _config.durationMs);
    _simulatorController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
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
                        const Icon(Icons.flash_on, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Cinematic Impact Flash', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
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

              // Live Flash Simulator Box
              Center(
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background mock frame
                        const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie_creation_outlined, color: AppColors.textMuted, size: 24),
                              SizedBox(width: 8),
                              Text('Cutpoint Impact Simulator', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),

                        // Flash overlay animated with controller
                        AnimatedBuilder(
                          animation: _simulatorController,
                          builder: (context, _) {
                            final elapsedMs = (_simulatorController.value * _config.durationMs).round();
                            final opacity = _config.evaluateOpacity(elapsedMs);

                            Color flashColor;
                            switch (_config.type) {
                              case ImpactFlashType.whiteFlash:
                                flashColor = Colors.white;
                                break;
                              case ImpactFlashType.blackFlash:
                                flashColor = Colors.black;
                                break;
                              case ImpactFlashType.warmGlow:
                                flashColor = const Color(0xFFFF9900);
                                break;
                              case ImpactFlashType.rgbStrobe:
                                flashColor = const Color(0xFF00E5FF);
                                break;
                            }

                            return Container(
                              color: flashColor.withOpacity(opacity.clamp(0.0, 1.0)),
                            );
                          },
                        ),

                        // Test flash trigger button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: InkWell(
                            onTap: _triggerFlashTest,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, size: 14, color: AppColors.accent),
                                  SizedBox(width: 4),
                                  Text('Test Flash', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Master Enable Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Flash On Cutpoint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Switch(
                    value: _config.isEnabled,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      _apply(_config.copyWith(isEnabled: val));
                      if (val) _triggerFlashTest();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Impact Type Cards
              const Text('Impact Style', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ImpactFlashType.values.map((type) {
                  final isSel = _config.type == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: isSel,
                    onSelected: (_) {
                      _apply(_config.copyWith(type: type, isEnabled: true));
                      _triggerFlashTest();
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Duration Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Flash Duration (ms)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${_config.durationMs}ms', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Slider(
                value: _config.durationMs.toDouble(),
                min: 50.0,
                max: 800.0,
                divisions: 15,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  _apply(_config.copyWith(durationMs: v.round()));
                },
              ),

              // Intensity Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Flash Intensity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${(_config.intensity * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Slider(
                value: _config.intensity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  _apply(_config.copyWith(intensity: v));
                },
              ),
              const SizedBox(height: 6),

              // Decay Curve Selector
              const Text('Decay Rate Curve', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildCurveButton(ImpactDecayCurve.exponential, 'Exponential (Snappy)'),
                  const SizedBox(width: 8),
                  _buildCurveButton(ImpactDecayCurve.linear, 'Linear'),
                  const SizedBox(width: 8),
                  _buildCurveButton(ImpactDecayCurve.sCurve, 'S-Curve (Soft)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurveButton(ImpactDecayCurve curve, String label) {
    final isSel = _config.decayCurve == curve;
    return Expanded(
      child: InkWell(
        onTap: () {
          _apply(_config.copyWith(decayCurve: curve));
          _triggerFlashTest();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? Colors.white : AppColors.textSecondary,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
