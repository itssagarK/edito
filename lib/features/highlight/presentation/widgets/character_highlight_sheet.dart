import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/character_highlight_config.dart';

class CharacterHighlightSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;

  const CharacterHighlightSheet({
    super.key,
    required this.clip,
    required this.onSave,
  });

  static Future<void> show(BuildContext context, {required Clip clip, required Function(Clip) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CharacterHighlightSheet(clip: clip, onSave: onSave),
    );
  }

  @override
  State<CharacterHighlightSheet> createState() => _CharacterHighlightSheetState();
}

class _CharacterHighlightSheetState extends State<CharacterHighlightSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CharacterHighlightConfig _config;

  final List<int> _highlightColors = const [
    0xFF00FFCC, // Neon Cyan
    0xFFFF007F, // Cyber Magenta
    0xFFFFD700, // Golden Sun
    0xFF00FF66, // Neon Lime
    0xFFFFFFFF, // Studio White
    0xFFFF5722, // Flame Orange
    0xFF7B2CBF, // Electric Purple
  ];

  final List<int> _backgroundColors = const [
    0xFF121212, // Dark Studio
    0xFF4A00E0, // Cyber Purple
    0xFF0A192F, // Deep Navy
    0xFF004D40, // Emerald Forest
    0xFF8B0000, // Crimson Noir
    0xFFE65100, // Sunset Amber
    0xFF2D3436, // Matte Charcoal
    0xFFF5F6FA, // Clean Studio White
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.characterHighlight;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(characterHighlight: _config);
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Character Highlight & BG', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Master Switch
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('Enable Character Highlight & BG Recolor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Spotlights the subject and changes or dims the background color', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            value: _config.isEnabled,
            activeColor: AppColors.accent,
            onChanged: (val) {
              setState(() => _config = _config.copyWith(isEnabled: val));
              _applyChange();
            },
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Modes'),
                Tab(text: 'Highlight'),
                Tab(text: 'Background'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModesTab(),
                _buildHighlightTab(),
                _buildBackgroundTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text('SELECT HIGHLIGHT MODE', style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...CharacterHighlightMode.values.map((mode) {
          final isSelected = _config.mode == mode;
          return Card(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceElevated,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: ListTile(
              title: Text(mode.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(mode.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mode == CharacterHighlightMode.spotlight
                      ? Icons.highlight
                      : (mode == CharacterHighlightMode.neonAura
                          ? Icons.blur_on
                          : (mode == CharacterHighlightMode.bwBackground ? Icons.filter_b_and_w : Icons.format_color_fill)),
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20) : null,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(mode: mode, isEnabled: true);
                });
                _applyChange();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHighlightTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text('CHARACTER HIGHLIGHT COLOR', style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _highlightColors.length,
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final color = _highlightColors[i];
              final isSelected = _config.highlightColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() => _config = _config.copyWith(highlightColor: color, isEnabled: true));
                  _applyChange();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(color).withOpacity(0.5),
                        blurRadius: isSelected ? 8 : 4,
                      ),
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Highlight Intensity
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Highlight Intensity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_config.highlightIntensity * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.highlightIntensity,
          min: 0.2,
          max: 2.0,
          activeColor: AppColors.accent,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(highlightIntensity: val, isEnabled: true));
            _applyChange();
          },
        ),
        const SizedBox(height: 12),

        // Character Spotlight Focus Radius
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Character Focus Radius', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_config.spotlightRadius * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.spotlightRadius,
          min: 0.20,
          max: 0.90,
          activeColor: AppColors.primary,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(spotlightRadius: val, isEnabled: true));
            _applyChange();
          },
        ),
        const SizedBox(height: 12),

        // Feather / Edge Softness
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edge Feather Softness', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_config.feather * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.primaryLight)),
          ],
        ),
        Slider(
          value: _config.feather,
          min: 0.10,
          max: 1.0,
          activeColor: AppColors.primaryLight,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(feather: val, isEnabled: true));
            _applyChange();
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text('BACKGROUND COLOR / FILL', style: AppTypography.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _backgroundColors.length,
            separatorBuilder: (c, i) => const SizedBox(width: 10),
            itemBuilder: (c, i) {
              final color = _backgroundColors[i];
              final isSelected = _config.backgroundColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() => _config = _config.copyWith(backgroundColor: color, isEnabled: true));
                  _applyChange();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: AppColors.accent, size: 20) : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Background Dimming
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Background Dimming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(_config.backgroundDimming * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accentWarm)),
          ],
        ),
        Slider(
          value: _config.backgroundDimming,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accentWarm,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(backgroundDimming: val, isEnabled: true));
            _applyChange();
          },
        ),
        const SizedBox(height: 12),

        // Background Desaturation (B&W Wash)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Background Desaturation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${((1.0 - _config.backgroundSaturation) * 100).toInt()}%', style: AppTypography.timecode.copyWith(fontSize: 12, color: AppColors.accentGold)),
          ],
        ),
        Slider(
          value: 1.0 - _config.backgroundSaturation,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accentGold,
          onChanged: (val) {
            setState(() => _config = _config.copyWith(backgroundSaturation: 1.0 - val, isEnabled: true));
            _applyChange();
          },
        ),
      ],
    );
  }
}
