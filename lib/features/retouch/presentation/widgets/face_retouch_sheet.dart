import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/face_retouch_config.dart';
import '../../services/face_retouch_compiler_service.dart';

/// CapCut Pro AI Face & Body Retouching Studio Sheet
class FaceRetouchSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const FaceRetouchSheet({
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
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FaceRetouchSheet(
        clip: clip,
        onSave: onSave,
      ),
    );
  }

  @override
  State<FaceRetouchSheet> createState() => _FaceRetouchSheetState();
}

class _FaceRetouchSheetState extends State<FaceRetouchSheet>
    with SingleTickerProviderStateMixin {
  late FaceRetouchConfig _config;
  late TabController _tabController;
  bool _isPeekingRaw = false;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.retouch;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(retouch: _config);
    widget.onSave(updated);
  }

  void _applyPreset(RetouchPreset preset) {
    setState(() {
      _config = FaceRetouchConfig.getPresetConfig(preset);
    });
    _applyChange();
  }

  void _resetRetouch() {
    setState(() {
      _config = const FaceRetouchConfig();
    });
    _applyChange();
  }

  @override
  Widget build(BuildContext context) {
    final badge = FaceRetouchCompilerService.getBadge(_config);

    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked ? null : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            // Header Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Title & Master Control Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.face_retouching_natural, color: Color(0xFFFF80AB), size: 22),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Face & Body Retouch', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        Text(
                          _config.isEnabled ? (_config.badge) : 'Enhance skin, features & silhouette',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Before / After Compare Peek Button
                    GestureDetector(
                      onTapDown: (_) {
                        setState(() => _isPeekingRaw = true);
                        widget.onSave(widget.clip.copyWith(
                          retouch: _config.copyWith(isEnabled: false),
                        ));
                      },
                      onTapUp: (_) {
                        setState(() => _isPeekingRaw = false);
                        _applyChange();
                      },
                      onTapCancel: () {
                        setState(() => _isPeekingRaw = false);
                        _applyChange();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPeekingRaw ? AppColors.accent : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _isPeekingRaw ? 'RAW' : 'COMPARE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isPeekingRaw ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _config.isEnabled,
                      activeColor: const Color(0xFFFF80AB),
                      onChanged: (val) {
                        setState(() {
                          _config = _config.copyWith(isEnabled: val);
                        });
                        _applyChange();
                      },
                    ),
                    if (widget.onDone != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                        icon: const Icon(Icons.check, color: AppColors.accent, size: 18),
                        onPressed: widget.onDone,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Preset Quick Carousel
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildPresetChip('None (Raw)', RetouchPreset.none),
                _buildPresetChip('🌟 Natural Glow', RetouchPreset.naturalGlow),
                _buildPresetChip('💎 Porcelain Flawless', RetouchPreset.porcelainFlawless),
                _buildPresetChip('☀️ Golden Hour', RetouchPreset.goldenHour),
                _buildPresetChip('🎬 Cinema Clean', RetouchPreset.cinemaClean),
                _buildPresetChip('📸 Glamour Portrait', RetouchPreset.glamourPortrait),
                _buildPresetChip('✨ Blemish Eraser', RetouchPreset.blemishEraser),
                _buildPresetChip('🌿 Subtle Fresh', RetouchPreset.subtleFresh),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Retouch Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: const Color(0xFFFF80AB),
            indicatorWeight: 2.5,
            labelColor: const Color(0xFFFF80AB),
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Skin & Complexion'),
              Tab(text: 'Facial Features'),
              Tab(text: 'Body & Silhouette'),
            ],
          ),

          const Divider(height: 1, color: AppColors.border),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkinTab(),
                _buildFaceFeaturesTab(),
                _buildBodyTab(),
              ],
            ),
          ),

          // Footer Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16, color: AppColors.textMuted),
                  label: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  onPressed: _resetRetouch,
                ),
                Text(
                  badge.isNotEmpty ? badge : 'Retouch Inactive',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: SKIN & COMPLEXION ---
  Widget _buildSkinTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSlider(
          label: 'Skin Smoothing (Bilateral Filter)',
          value: _config.skinSmooth,
          icon: Icons.blur_on,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(skinSmooth: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Complexion Radiance Glow',
          value: _config.skinRadiance,
          icon: Icons.light_mode_outlined,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(skinRadiance: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        const SizedBox(height: 12),
        Text('Skin Tone Palette & Radiance Tint', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SkinToneStyle.values.map((tone) {
            final isSelected = _config.skinTone == tone;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _config = _config.copyWith(skinTone: tone, isEnabled: true, activePreset: RetouchPreset.none);
                });
                _applyChange();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF80AB).withOpacity(0.15) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF80AB) : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Color(tone.previewColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tone.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  // --- TAB 2: FACIAL FEATURES ---
  Widget _buildFaceFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSlider(
          label: 'Eye Brightening & Iris Sparkle',
          value: _config.eyeBrighten,
          icon: Icons.remove_red_eye_outlined,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(eyeBrighten: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Teeth Whitening (Neutralize Cast)',
          value: _config.teethWhiten,
          icon: Icons.sentiment_satisfied_alt,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(teethWhiten: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Dark Circle Concealer (Under-Eye)',
          value: _config.darkCircles,
          icon: Icons.wb_twilight,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(darkCircles: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Face Slimming & Jawline Sculpt',
          value: _config.faceSlimming,
          icon: Icons.compress,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(faceSlimming: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
      ],
    );
  }

  // --- TAB 3: BODY & SILHOUETTE ---
  Widget _buildBodyTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSlider(
          label: 'Waist & Silhouette Slimming',
          value: _config.waistSlimming,
          icon: Icons.straighten,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(waistSlimming: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
        _buildSlider(
          label: 'Leg Lengthening & Proportions',
          value: _config.legLengthening,
          icon: Icons.height,
          min: 0.0,
          max: 1.0,
          onChanged: (val) {
            setState(() {
              _config = _config.copyWith(legLengthening: val, isEnabled: true, activePreset: RetouchPreset.none);
            });
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required IconData icon,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final pct = (value * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFFFF80AB)),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
              Text(
                '$pct%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF80AB)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF80AB),
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: Colors.white,
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, RetouchPreset preset) {
    final isSelected = _config.activePreset == preset;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFFF80AB).withOpacity(0.25),
        backgroundColor: AppColors.surfaceElevated,
        checkmarkColor: const Color(0xFFFF80AB),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFFF80AB) : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSelected ? const Color(0xFFFF80AB) : AppColors.border),
        ),
        onSelected: (_) => _applyPreset(preset),
      ),
    );
  }
}
