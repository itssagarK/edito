import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/character_zoom_config.dart';
import '../../services/character_zoom_compiler_service.dart';

class CharacterZoomSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const CharacterZoomSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CharacterZoomSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<CharacterZoomSheet> createState() => _CharacterZoomSheetState();
}

class _CharacterZoomSheetState extends State<CharacterZoomSheet> with SingleTickerProviderStateMixin {
  late CharacterZoomConfig _config;
  late AnimationController _animController;
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.characterZoom;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_config.animationDurationSec * 1000).toInt().clamp(300, 6000)),
    );
    _animController.addListener(() {
      if (mounted) setState(() {});
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlayingPreview = false);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(characterZoom: _config);
    widget.onSave(updated);
  }

  void _togglePreviewAnimation() {
    if (_isPlayingPreview) {
      _animController.stop();
      _animController.reset();
      setState(() => _isPlayingPreview = false);
    } else {
      _animController.duration = Duration(
        milliseconds: (_config.animationDurationSec * 1000).toInt().clamp(300, 6000),
      );
      _animController.reset();
      _animController.forward();
      setState(() => _isPlayingPreview = true);
    }
  }

  double _getPreviewScale() {
    if (!_config.isEnabled) return 1.0;
    if (!_config.mode.isAnimated || !_isPlayingPreview) {
      return _config.targetZoom;
    }
    final progress = _animController.value;
    switch (_config.mode) {
      case CharacterZoomMode.cinematicPushIn:
        final eased = progress * progress * (3.0 - 2.0 * progress);
        return _config.startZoom + (_config.targetZoom - _config.startZoom) * eased;
      case CharacterZoomMode.dramaticCrash:
        final eased = 1.0 - (1.0 - progress) * (1.0 - progress);
        return _config.startZoom + (_config.targetZoom - _config.startZoom) * eased;
      case CharacterZoomMode.slowCreep:
        return _config.startZoom + (_config.targetZoom - _config.startZoom) * progress;
      case CharacterZoomMode.pulse:
        final wave = 0.5 + 0.5 * progress;
        return 1.0 + (_config.targetZoom - 1.0) * wave;
      default:
        return _config.targetZoom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
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
                  children: [
                    const Icon(Icons.center_focus_strong, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Main Character Zoom-In', style: AppTypography.titleMedium),
                          Text(
                            'Dynamic face tracking & punch-in focus',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _config.isEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(isEnabled: val);
                        });
                        _applyChange();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Main Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Interactive Reticle & Video Preview Canvas
                _buildTargetingCanvas(),

                const SizedBox(height: 16),

                // Quick Anchor Points
                _buildQuickAnchorPills(),

                const SizedBox(height: 16),

                // Zoom Modes Selector
                Text('ZOOM STYLE & MOTION', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                _buildModeCards(),

                const SizedBox(height: 16),

                // Zoom Scale Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TARGET ZOOM SCALE', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                    Text(
                      '${_config.targetZoom.toStringAsFixed(2)}x',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.surfaceElevated,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _config.targetZoom,
                    min: 1.10,
                    max: 3.0,
                    divisions: 38,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(targetZoom: v));
                      _applyChange();
                    },
                  ),
                ),
                _buildQuickScaleChips(),

                const SizedBox(height: 16),

                // Animation Timing (only for animated modes)
                if (_config.mode.isAnimated) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ANIMATION DURATION', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      Text(
                        '${_config.animationDurationSec.toStringAsFixed(1)}s',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _config.animationDurationSec,
                    min: 0.3,
                    max: 6.0,
                    divisions: 57,
                    activeColor: AppColors.primaryLight,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(animationDurationSec: v));
                      _applyChange();
                    },
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('START DELAY', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      Text(
                        '${_config.startDelaySec.toStringAsFixed(1)}s',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _config.startDelaySec,
                    min: 0.0,
                    max: 4.0,
                    divisions: 40,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(startDelaySec: v));
                      _applyChange();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Focus Vignette & Subject Aura
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Character Focus Vignette', style: TextStyle(fontSize: 14, color: Colors.white)),
                        subtitle: const Text('Darkens edges around the character', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        value: _config.addFocusVignette,
                        activeColor: AppColors.accent,
                        onChanged: (v) {
                          setState(() => _config = _config.copyWith(addFocusVignette: v));
                          _applyChange();
                        },
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      SwitchListTile(
                        title: const Text('Subject Vibrance Pop', style: TextStyle(fontSize: 14, color: Colors.white)),
                        subtitle: const Text('Boosts contrast & saturation during zoom', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        value: _config.addSubjectAura,
                        activeColor: AppColors.accent,
                        onChanged: (v) {
                          setState(() => _config = _config.copyWith(addSubjectAura: v));
                          _applyChange();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Footer Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _config = const CharacterZoomConfig(isEnabled: false);
                      });
                      _applyChange();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _applyChange();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply Zoom-In', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetingCanvas() {
    final scale = _getPreviewScale();
    final cx = _config.characterCenterX;
    final cy = _config.characterCenterY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TAP / DRAG FOCUS TARGET', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            Text(
              'X: ${(cx * 100).toInt()}% • Y: ${(cy * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth;
            final canvasHeight = canvasWidth * 9.0 / 16.0;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final localPos = details.localPosition;
                  final newX = (localPos.dx / canvasWidth).clamp(0.05, 0.95);
                  final newY = (localPos.dy / canvasHeight).clamp(0.05, 0.95);
                  setState(() {
                    _config = _config.copyWith(characterCenterX: newX, characterCenterY: newY);
                  });
                  _applyChange();
                },
                onTapDown: (details) {
                  final localPos = details.localPosition;
                  final newX = (localPos.dx / canvasWidth).clamp(0.05, 0.95);
                  final newY = (localPos.dy / canvasHeight).clamp(0.05, 0.95);
                  setState(() {
                    _config = _config.copyWith(characterCenterX: newX, characterCenterY: newY);
                  });
                  _applyChange();
                },
                child: Container(
                  width: canvasWidth,
                  height: canvasHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: AppColors.accent.withOpacity(0.6), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Video Background Simulation with Zoom Transform
                      Transform.scale(
                        scale: _config.isEnabled ? scale : 1.0,
                        alignment: Alignment((cx - 0.5) * 2.0, (cy - 0.5) * 2.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E272E), Color(0xFF0B0E14)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.35),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Main Character Framing',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Optional Vignette overlay on canvas
                      if (_config.addFocusVignette && _config.isEnabled)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment((cx - 0.5) * 2.0, (cy - 0.5) * 2.0),
                                  radius: 0.8,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Reticle Target Pin (Crosshair + Circle)
                      Positioned(
                        left: (cx * canvasWidth) - 20,
                        top: (cy * canvasHeight) - 20,
                        child: IgnorePointer(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent, width: 2.0),
                              color: AppColors.accent.withOpacity(0.20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.center_focus_strong, color: AppColors.accent, size: 20),
                            ),
                          ),
                        ),
                      ),

                      // Test Animation Floating Button
                      if (_config.mode.isAnimated)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.75),
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              side: const BorderSide(color: AppColors.accent, width: 1),
                            ),
                            onPressed: _togglePreviewAnimation,
                            icon: Icon(_isPlayingPreview ? Icons.stop : Icons.play_arrow, size: 14),
                            label: Text(
                              _isPlayingPreview ? 'Stop' : 'Test Zoom',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
    );
  }

  Widget _buildQuickAnchorPills() {
    final anchors = [
      {'label': '👤 Face / Head', 'x': 0.50, 'y': 0.35},
      {'label': '🎯 Center', 'x': 0.50, 'y': 0.50},
      {'label': '👔 Torso', 'x': 0.50, 'y': 0.65},
      {'label': '👈 Left 3rd', 'x': 0.33, 'y': 0.35},
      {'label': '👉 Right 3rd', 'x': 0.66, 'y': 0.35},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: anchors.map((a) {
          final isSelected = (_config.characterCenterX - (a['x'] as double)).abs() < 0.05 &&
              (_config.characterCenterY - (a['y'] as double)).abs() < 0.05;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(a['label'] as String),
              selected: isSelected,
              selectedColor: AppColors.accent.withOpacity(0.25),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
              onSelected: (_) {
                setState(() {
                  _config = _config.copyWith(
                    characterCenterX: a['x'] as double,
                    characterCenterY: a['y'] as double,
                  );
                });
                _applyChange();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeCards() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
      ),
      itemCount: CharacterZoomMode.values.length,
      itemBuilder: (context, index) {
        final mode = CharacterZoomMode.values[index];
        final isSelected = _config.mode == mode;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _config = _config.copyWith(mode: mode);
            });
            _applyChange();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.18) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mode.label,
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  mode.description,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickScaleChips() {
    final scales = [1.25, 1.40, 1.60, 2.00, 2.50];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: scales.map((s) {
        final isSelected = (_config.targetZoom - s).abs() < 0.05;
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() => _config = _config.copyWith(targetZoom: s));
            _applyChange();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              '${s.toStringAsFixed(2)}x',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
