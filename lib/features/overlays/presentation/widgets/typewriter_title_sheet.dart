import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/typewriter_title_config.dart';
import '../../services/typewriter_title_service.dart';

class TypewriterTitleSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const TypewriterTitleSheet({
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
      builder: (context) => TypewriterTitleSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<TypewriterTitleSheet> createState() => _TypewriterTitleSheetState();
}

class _TypewriterTitleSheetState extends State<TypewriterTitleSheet> with SingleTickerProviderStateMixin {
  late TypewriterTitleConfig _config;
  late AnimationController _animController;
  Timer? _tickerTimer;
  int _simElapsedMs = 0;
  bool _isAuditionPlaying = true;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.typewriterTitle;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _startSimulationTicker();
  }

  void _startSimulationTicker() {
    _tickerTimer?.cancel();
    _simElapsedMs = 0;
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isAuditionPlaying) {
        setState(() {
          _simElapsedMs += 40;
          if (_simElapsedMs > 3500) {
            _simElapsedMs = 0; // Loop simulation
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _applyConfig(TypewriterTitleConfig updated) {
    setState(() {
      _config = updated;
    });
    final updatedClip = widget.clip.copyWith(typewriterTitle: updated);
    widget.onSave(updatedClip);
  }

  String get _sampleText {
    if (widget.clip.textOverlay.text.trim().isNotEmpty) {
      return widget.clip.textOverlay.text.trim();
    }
    return 'CREATIVE CINEMATIC TITLES';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65,
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
                _buildSimulationCard(),
                const SizedBox(height: 16),
                _buildPresetsSection(),
                const SizedBox(height: 16),
                _buildModeSelector(),
                const SizedBox(height: 16),
                _buildCursorSelector(),
                const SizedBox(height: 16),
                _buildTimingControls(),
                const SizedBox(height: 16),
                _buildOptions(),
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
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.keyboard, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kinetic Typewriter Studio', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('100% OFFLINE • SKIA TYPOGRAPHY', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
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
                    activeColor: AppColors.accent,
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

  Widget _buildSimulationCard() {
    final displayed = _config.getDisplayText(_sampleText, _simElapsedMs, totalDurationMs: 3000);
    final cursor = _config.getActiveCursor(_simElapsedMs, 3000, textLength: _sampleText.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _config.isEnabled ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: _config.isEnabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isAuditionPlaying ? const Color(0xFF00FF66) : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE CANVAS SIMULATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${(_simElapsedMs / 1000.0).toStringAsFixed(2)}s',
                    style: AppTypography.timecode.copyWith(fontSize: 11, color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _simElapsedMs = 0;
                        _isAuditionPlaying = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.replay, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Restart', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const Duration(milliseconds: 60) > Duration.zero ? const BoxConstraints(minHeight: 52) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: displayed),
                  TextSpan(
                    text: cursor,
                    style: TextStyle(
                      color: _config.wordHighlightColor != null
                          ? Color(_config.wordHighlightColor!)
                          : AppColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection() {
    final presets = [
      {'name': 'Tech Terminal', 'config': TypewriterTitleConfig.techTerminal, 'icon': '💻'},
      {'name': 'Noir Title', 'config': TypewriterTitleConfig.cinematicNoir, 'icon': '🎬'},
      {'name': 'TikTok Punch', 'config': TypewriterTitleConfig.tiktokPunch, 'icon': '⚡'},
      {'name': 'Hacker Matrix', 'config': TypewriterTitleConfig.hackerMatrix, 'icon': '👾'},
      {'name': 'Minimal Clean', 'config': TypewriterTitleConfig.minimalClean, 'icon': '✨'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cinematic Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final presetConfig = p['config'] as TypewriterTitleConfig;
              final isSelected = _config.mode == presetConfig.mode &&
                  _config.cursorStyle == presetConfig.cursorStyle &&
                  _config.typingSpeedMs == presetConfig.typingSpeedMs;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _applyConfig(presetConfig.copyWith(isEnabled: true));
                    _simElapsedMs = 0;
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(p['icon'] as String, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          p['name'] as String,
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

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Typography Animation Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: TypewriterMode.values.map((mode) {
            final isSelected = _config.mode == mode;
            return InkWell(
              onTap: () {
                _applyConfig(_config.copyWith(mode: mode, isEnabled: true));
                _simElapsedMs = 0;
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.25) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(mode.iconEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCursorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Blinking Cursor Glyph', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TypewriterCursorStyle.values.map((style) {
              final isSelected = _config.cursorStyle == style;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(style.label),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.surfaceElevated,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  onSelected: (sel) {
                    if (sel) {
                      _applyConfig(_config.copyWith(cursorStyle: style));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingControls() {
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
              const Text('Typing Cadence / Speed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.typingSpeedMs} ms', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
            ],
          ),
          Slider(
            value: _config.typingSpeedMs.toDouble(),
            min: 15.0,
            max: 200.0,
            divisions: 37,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(typingSpeedMs: val.toInt(), isEnabled: true));
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Initial Start Delay', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('${_config.startDelayMs} ms', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
            ],
          ),
          Slider(
            value: _config.startDelayMs.toDouble(),
            min: 0.0,
            max: 1000.0,
            divisions: 20,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              _applyConfig(_config.copyWith(startDelayMs: val.toInt()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep Cursor Blinking After Finish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            subtitle: const Text('Keeps the cursor alive until clip boundary', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            value: _config.keepCursorAfterTyping,
            activeColor: AppColors.accent,
            onChanged: (val) {
              _applyConfig(_config.copyWith(keepCursorAfterTyping: val));
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tactile Typing Keystroke Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            subtitle: const Text('Syncs rhythmic click feedback with revealed letters', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            value: _config.playTypingSound,
            activeColor: AppColors.accent,
            onChanged: (val) {
              _applyConfig(_config.copyWith(playTypingSound: val));
            },
          ),
        ],
      ),
    );
  }
}
