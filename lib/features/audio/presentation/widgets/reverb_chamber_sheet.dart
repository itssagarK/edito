import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/reverb_chamber_config.dart';
import '../../services/reverb_compiler_service.dart';

class ReverbChamberSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ReverbChamberSheet({
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => ReverbChamberSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<ReverbChamberSheet> createState() => _ReverbChamberSheetState();
}

class _ReverbChamberSheetState extends State<ReverbChamberSheet> with SingleTickerProviderStateMixin {
  late ReverbChamberConfig _config;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.reverb;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyConfig(ReverbChamberConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(reverb: updated);
    widget.onSave(updatedClip);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.68,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked) _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildAcousticVisualizer(),
                const SizedBox(height: 16),
                _buildPresetsSection(),
                const SizedBox(height: 16),
                _buildWetDryAndDecayControls(),
                const SizedBox(height: 16),
                _buildDampingAndStereoControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.audioTrack.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.surround_sound, color: AppColors.audioTrack, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reverb Chamber Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.audioTrack,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • ACOUSTIC DSP', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Switch(
                    value: _config.isEnabled,
                    activeColor: AppColors.audioTrack,
                    onChanged: (val) {
                      _applyConfig(_config.copyWith(isEnabled: val));
                    },
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                    icon: const Icon(Icons.check, color: AppColors.accent, size: 20),
                    onPressed: widget.onDone ?? () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcousticVisualizer() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? AppColors.audioTrack.withOpacity(0.6) : AppColors.border,
          width: 2.0,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: AppColors.audioTrack.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return CustomPaint(
              painter: _AcousticChamberPainter(
                config: _config,
                phase: _animController.value,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(_config.roomType.iconEmoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              _config.roomType.label.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: _config.isEnabled ? AppColors.audioTrack : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Text(
                            '${(_config.wetDryMix * 100).toInt()}% WET • ${_config.decayTimeMs}ms TAIL',
                            style: AppTypography.timecode.copyWith(fontSize: 10, color: AppColors.audioTrack),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DAMPING: ${(_config.damping * 100).toInt()}%',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                        Text(
                          'STEREO SPREAD: ${(_config.stereoWidth * 100).toInt()}%',
                          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.6), fontFamily: 'Courier'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presets = [
      {'type': ReverbRoomType.vocalHall, 'config': ReverbChamberConfig.vocalHall},
      {'type': ReverbRoomType.studioBooth, 'config': ReverbChamberConfig.studioBooth},
      {'type': ReverbRoomType.smallRoom, 'config': ReverbChamberConfig.smallRoom},
      {'type': ReverbRoomType.cathedral, 'config': ReverbChamberConfig.cathedral},
      {'type': ReverbRoomType.cyberCavern, 'config': ReverbChamberConfig.cyberCavern},
      {'type': ReverbRoomType.plateReverb, 'config': ReverbChamberConfig.plateReverb},
      {'type': ReverbRoomType.stadium, 'config': ReverbChamberConfig.stadium},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acoustic Chamber Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as ReverbChamberConfig;
              final isSelected = _config.roomType == presetConfig.roomType;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _applyConfig(presetConfig.copyWith(isEnabled: true));
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.audioTrack.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.audioTrack : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(presetConfig.roomType.iconEmoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          presetConfig.roomType.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWetDryAndDecayControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wet / Dry Reflection Mix', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.wetDryMix * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.audioTrack)),
            ],
          ),
          Slider(
            value: _config.wetDryMix,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppColors.audioTrack,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(wetDryMix: val, isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Decay Reverb Tail Duration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.decayTimeMs} ms', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.audioTrack)),
            ],
          ),
          Slider(
            value: _config.decayTimeMs.toDouble(),
            min: 100.0,
            max: 5000.0,
            divisions: 49,
            activeColor: AppColors.audioTrack,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(decayTimeMs: val.toInt(), isEnabled: true));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDampingAndStereoControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('High-Frequency Damping (Warmth)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.damping * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.audioTrack)),
            ],
          ),
          Slider(
            value: _config.damping,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppColors.audioTrack,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(damping: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stereo Width Spatial Spread', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${(_config.stereoWidth * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.audioTrack)),
            ],
          ),
          Slider(
            value: _config.stereoWidth,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppColors.audioTrack,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(stereoWidth: val));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pre-Delay Initial Reflection Gap', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.preDelayMs.toInt()} ms', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.audioTrack)),
            ],
          ),
          Slider(
            value: _config.preDelayMs,
            min: 0.0,
            max: 80.0,
            divisions: 16,
            activeColor: AppColors.audioTrack,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(preDelayMs: val));
            },
          ),
        ],
      ),
    );
  }
}

class _AcousticChamberPainter extends CustomPainter {
  final ReverbChamberConfig config;
  final double phase;

  _AcousticChamberPainter({
    required this.config,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Perspective acoustic room grid wireframe
    final gridPaint = Paint()
      ..color = AppColors.audioTrack.withOpacity(0.15)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, 0), Offset(size.width * 0.25, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width * 0.75, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width * 0.25, size.height * 0.75), gridPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width * 0.75, size.height * 0.75), gridPaint);

    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.50,
      height: size.height * 0.50,
    );
    canvas.drawRect(innerRect, Paint()..color = AppColors.audioTrack.withOpacity(0.08)..style = PaintingStyle.fill);
    canvas.drawRect(innerRect, Paint()..color = AppColors.audioTrack.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // 2. Animated acoustic reverberation wave rings radiating outward
    if (config.isActive) {
      final numRings = 4;
      for (int i = 0; i < numRings; i++) {
        final ringPhase = (phase + (i / numRings)) % 1.0;
        final radius = (size.width * 0.45) * ringPhase;
        final decayOpacity = (1.0 - ringPhase) * (config.wetDryMix * 0.8).clamp(0.1, 0.85);

        final wavePaint = Paint()
          ..color = AppColors.audioTrack.withOpacity(decayOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(center, radius, wavePaint);
      }
    }

    // 3. Central sound source transducer
    final sourcePaint = Paint()
      ..color = config.isActive ? AppColors.audioTrack : AppColors.textMuted
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, sourcePaint);
  }

  @override
  bool shouldRepaint(covariant _AcousticChamberPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.phase != phase;
  }
}
