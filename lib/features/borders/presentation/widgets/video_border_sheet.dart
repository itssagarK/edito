import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/video_border_config.dart';

class VideoBorderSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback? onDone;

  const VideoBorderSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip, {bool applyToAll}) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoBorderSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<VideoBorderSheet> createState() => _VideoBorderSheetState();
}

class _VideoBorderSheetState extends State<VideoBorderSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VideoBorderConfig _config;
  bool _applyToAll = false;

  static const List<int> primaryColors = [
    0xFFFFFFFF, // Pure White
    0xFFFFD700, // Metallic Gold
    0xFF00E5FF, // Cyan / Neon Blue
    0xFF00FF66, // Neon Green
    0xFFFF007F, // Hot Pink
    0xFFFF6B00, // Blaze Orange
    0xFFFF2A2A, // Crimson Red
    0xFF6C5CE7, // Purple / Violet
    0xFF2A2A36, // Slate Charcoal
    0xFF000000, // Pure Black
  ];

  static const List<int> secondaryColors = [
    0xFFFF007F, // Neon Pink
    0xFF00E5FF, // Cyan
    0xFFFFD700, // Gold
    0xFFDD2476, // Rose
    0xFF00FFCC, // Mint
    0xFF4A00E0, // Deep Purple
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.border;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChanges() {
    final updatedClip = widget.clip.copyWith(border: _config);
    widget.onSave(updatedClip, applyToAll: _applyToAll);
  }

  void _updateConfig(VideoBorderConfig Function(VideoBorderConfig) updater) {
    setState(() {
      _config = updater(_config);
    });
    _applyChanges();
  }

  void _selectPreset(BorderPreset preset) {
    final newConfig = preset.createConfig();
    setState(() {
      _config = newConfig;
    });
    _applyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.border_outer, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 8),
                        Text('Borders & Frames', style: AppTypography.titleLarge),
                      ],
                    ),
                    Row(
                      children: [
                        Switch.adaptive(
                          value: _config.isEnabled,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            _updateConfig((c) => c.copyWith(isEnabled: val));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                          onPressed: () {
                            _applyChanges();
                            widget.onDone?.call();
                            Navigator.pop(context);
                          },
                          tooltip: 'Done',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Interactive Mini Preview
          _buildLivePreview(),

          // Tabs: Presets | Style & Size | Colors & Glow
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                Tab(icon: Icon(Icons.style, size: 15), text: 'Presets'),
                Tab(icon: Icon(Icons.line_weight, size: 15), text: 'Style & Size'),
                Tab(icon: Icon(Icons.palette, size: 15), text: 'Colors & Glow'),
              ],
            ),
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildStyleAndSizeTab(),
                _buildColorsAndGlowTab(),
              ],
            ),
          ),

          // Bottom Bar: Apply to All
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _applyToAll,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() => _applyToAll = val ?? false);
                        _applyChanges();
                      },
                    ),
                    const Text('Apply to all video clips', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Text(
                  _config.isEnabled
                      ? '${_config.style.name.toUpperCase()} • ${_config.borderWidth.round()}PX'
                      : 'DISABLED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background simulated video frame
          Container(
            width: 140,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(_config.cornerRadius * 0.4),
              border: _config.isEnabled
                  ? Border.all(
                      color: Color(_config.borderColor).withOpacity(_config.borderOpacity),
                      width: (_config.borderWidth * 0.35).clamp(1.5, 12.0),
                    )
                  : null,
              boxShadow: _config.isEnabled && _config.style == VideoBorderStyle.neonGlow
                  ? [
                      BoxShadow(
                        color: Color(_config.secondaryColor ?? _config.borderColor).withOpacity(_config.glowIntensity * 0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                _config.isEnabled ? 'VIDEO FRAME' : 'NO BORDER',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 6,
            child: Text(
              'PREVIEW: ${_config.style.label.toUpperCase()}',
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Presets Tab
  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BorderPreset.values.map((preset) {
            return ActionChip(
              label: Text(preset.label, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: const TextStyle(color: Colors.white),
              onPressed: () => _selectPreset(preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 2. Style & Size Tab
  Widget _buildStyleAndSizeTab() {
    final widthPresets = [4.0, 10.0, 18.0, 28.0, 40.0];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Style Chips
        const Text('FRAME STYLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: VideoBorderStyle.values.map((st) {
            final isSelected = _config.style == st;
            return ChoiceChip(
              label: Text(st.label, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _updateConfig((c) => c.copyWith(style: st, isEnabled: true)),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Thickness Slider & Quick Widths
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BORDER WIDTH: ${_config.borderWidth.round()}px',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            Row(
              children: widthPresets.map((w) {
                final isSelected = (_config.borderWidth - w).abs() < 2;
                final label = w <= 4 ? '4px' : (w <= 10 ? '10px' : (w <= 18 ? '18px' : (w <= 28 ? '28px' : '40px')));
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => _updateConfig((c) => c.copyWith(borderWidth: w, isEnabled: true)),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Slider(
          value: _config.borderWidth.clamp(2.0, 48.0),
          min: 2.0,
          max: 48.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateConfig((c) => c.copyWith(borderWidth: val, isEnabled: true)),
        ),

        // Corner Radius Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CORNER RADIUS: ${_config.cornerRadius.round()}px',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            if (_config.cornerRadius > 0)
              TextButton(
                onPressed: () => _updateConfig((c) => c.copyWith(cornerRadius: 0)),
                child: const Text('Sharp 0px', style: TextStyle(fontSize: 10, color: AppColors.accent)),
              ),
          ],
        ),
        Slider(
          value: _config.cornerRadius.clamp(0.0, 48.0),
          min: 0.0,
          max: 48.0,
          activeColor: AppColors.primaryLight,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateConfig((c) => c.copyWith(cornerRadius: val, isEnabled: true)),
        ),
      ],
    );
  }

  // 3. Colors & Glow Tab
  Widget _buildColorsAndGlowTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Primary Color
        const Text('PRIMARY BORDER COLOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: primaryColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = primaryColors[index];
              final isSelected = _config.borderColor == color;

              return GestureDetector(
                onTap: () => _updateConfig((c) => c.copyWith(borderColor: color, isEnabled: true)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: (color == 0xFFFFFFFF || color == 0xFFFFD700) ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Secondary / Glow Color
        const Text('SECONDARY COLOR / NEON ACCENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: secondaryColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = secondaryColors[index];
              final isSelected = _config.secondaryColor == color;

              return GestureDetector(
                onTap: () => _updateConfig((c) => c.copyWith(secondaryColor: color, isEnabled: true)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Glow Intensity Slider
        Text(
          'GLOW INTENSITY: ${(_config.glowIntensity * 100).round()}%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
        ),
        Slider(
          value: _config.glowIntensity.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accentWarm,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateConfig((c) => c.copyWith(glowIntensity: val, isEnabled: true)),
        ),

        // Opacity Slider
        Text(
          'OPACITY: ${(_config.borderOpacity * 100).round()}%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
        ),
        Slider(
          value: _config.borderOpacity.clamp(0.1, 1.0),
          min: 0.1,
          max: 1.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateConfig((c) => c.copyWith(borderOpacity: val, isEnabled: true)),
        ),
      ],
    );
  }
}
