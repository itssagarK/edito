import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/ken_burns_config.dart';

/// Interactive Studio for Ken Burns Documentary Photo Pan & Zoom Motion Animation.
class KenBurnsSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const KenBurnsSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip updatedClip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => KenBurnsSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<KenBurnsSheet> createState() => _KenBurnsSheetState();
}

class _KenBurnsSheetState extends State<KenBurnsSheet> with SingleTickerProviderStateMixin {
  late KenBurnsConfig _config;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.kenBurns;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _update(KenBurnsConfig updated) {
    setState(() => _config = updated);
    final newClip = widget.clip.copyWith(kenBurns: updated);
    widget.onSave(newClip);
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
                                colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.slow_motion_video, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text('Ken Burns Motion', style: AppTypography.titleLarge),
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
                // 1. Enable Switch & Motion Simulator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _config.isEnabled ? AppColors.accent : AppColors.border,
                      width: _config.isEnabled ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Ken Burns Motion',
                                style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Cinematic slow camera pan & zoom for still photos',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Switch(
                            value: _config.isEnabled,
                            activeColor: AppColors.accent,
                            onChanged: (val) {
                              _update(_config.copyWith(isEnabled: val));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Animated Motion Simulator Box
                      Container(
                        height: 70,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (context, child) {
                            final transform = _config.evaluateTransform(_animCtrl.value);
                            final scale = transform['scale'] ?? 1.0;
                            final tx = (transform['translateX'] ?? 0.0) * 100.0;
                            final ty = (transform['translateY'] ?? 0.0) * 60.0;

                            return Stack(
                              children: [
                                Transform.translate(
                                  offset: Offset(tx, ty),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Center(
                                      child: Container(
                                        width: 140,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary.withOpacity(0.4),
                                              AppColors.accent.withOpacity(0.4),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.accent.withOpacity(0.6)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.image_outlined, color: Colors.white70, size: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 8,
                                  child: Text(
                                    _config.isEnabled
                                        ? '${_config.mode.label} · ${(scale * 100).round()}%'
                                        : 'MOTION OFF',
                                    style: const TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Motion Direction Presets
                Text('CAMERA MOTION DIRECTION', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 8),
                Column(
                  children: KenBurnsMode.values.map((mode) {
                    final isSelected = _config.mode == mode;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      color: isSelected ? AppColors.primary.withOpacity(0.18) : AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.accent : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          mode.description,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.accent, size: 18)
                            : null,
                        onTap: () {
                          _update(_config.copyWith(isEnabled: true, mode: mode));
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 3. Zoom Delta Intensity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Motion Intensity (Zoom Delta)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      '+${(_config.intensity * 100).round()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                Slider(
                  value: _config.intensity,
                  min: 0.05,
                  max: 0.40,
                  divisions: 7,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    _update(_config.copyWith(intensity: val));
                  },
                ),
                const SizedBox(height: 10),

                // 4. Motion Easing Curve
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Easing Acceleration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    DropdownButton<KenBurnsEasing>(
                      value: _config.easing,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox.shrink(),
                      items: KenBurnsEasing.values.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text(e.label, style: const TextStyle(fontSize: 12, color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _update(_config.copyWith(easing: val));
                        }
                      },
                    ),
                  ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _update(const KenBurnsConfig(isEnabled: false));
                  },
                  child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    widget.onDone?.call();
                    if (!widget.isDocked) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
