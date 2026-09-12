import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/header_footer_config.dart';

class HeaderFooterSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback? onDone;

  const HeaderFooterSheet({
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
      builder: (context) => HeaderFooterSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<HeaderFooterSheet> createState() => _HeaderFooterSheetState();
}

class _HeaderFooterSheetState extends State<HeaderFooterSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HeaderFooterConfig _config;
  bool _applyToAll = false;

  late TextEditingController _headerTextController;
  late TextEditingController _headerSubtextController;
  late TextEditingController _footerTextController;
  late TextEditingController _footerSubtextController;

  static const List<int> textColors = [
    0xFFFFFFFF, // White
    0xFFFFE600, // Vibrant Yellow
    0xFF00E5FF, // Cyan
    0xFFFF007F, // Neon Pink
    0xFF00FF66, // Neon Green
    0xFFFF6B00, // Blaze Orange
    0xFFFF2A2A, // Red
    0xFFD1D5DB, // Light Grey
    0xFF111827, // Dark Charcoal
    0xFF000000, // Black
  ];

  static const List<int> bgColors = [
    0xEE000000, // Semi-trans Black
    0xFF000000, // Opaque Black
    0xEE0F172A, // Deep Slate
    0xFFD32F2F, // Crimson Red
    0xFF1565C0, // Cobalt Blue
    0xFF2E7D32, // Forest Green
    0xFF6A1B9A, // Royal Purple
    0xEE1E293B, // Charcoal Navy
    0xCC374151, // Grey Frosted
    0x00000000, // Fully Transparent
  ];

  static const List<String> availableFonts = [
    'Inter',
    'Montserrat',
    'Anton',
    'Poppins',
    'Oswald',
    'Bebas Neue',
    'Roboto',
    'Playfair Display',
  ];

  static const List<String> headerEmojis = ['🔥', '🔴', '🎙️', '💡', '⚡', '🎬', '🚀', '📢', '⚠️', '⭐'];
  static const List<String> footerIcons = ['📲', '📢', '💬', '🔔', '👤', '🔗', '🚀', '❤️', '👀', '✨'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.headerFooter;

    _headerTextController = TextEditingController(text: _config.headerText);
    _headerSubtextController = TextEditingController(text: _config.headerSubtext);
    _footerTextController = TextEditingController(text: _config.footerText);
    _footerSubtextController = TextEditingController(text: _config.footerSubtext);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerTextController.dispose();
    _headerSubtextController.dispose();
    _footerTextController.dispose();
    _footerSubtextController.dispose();
    super.dispose();
  }

  void _applyChanges() {
    final updatedClip = widget.clip.copyWith(headerFooter: _config);
    widget.onSave(updatedClip, applyToAll: _applyToAll);
  }

  void _updateConfig(HeaderFooterConfig Function(HeaderFooterConfig) updater) {
    setState(() {
      _config = updater(_config);
    });
    _applyChanges();
  }

  void _selectPreset(HeaderFooterPreset preset) {
    final newConfig = preset.createConfig();
    setState(() {
      _config = newConfig;
      _headerTextController.text = newConfig.headerText;
      _headerSubtextController.text = newConfig.headerSubtext;
      _footerTextController.text = newConfig.footerText;
      _footerSubtextController.text = newConfig.footerSubtext;
    });
    _applyChanges();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82 + (bottomInset > 0 ? 50 : 0),
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
                        const Icon(Icons.view_headline, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Header & Footer', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                      onPressed: () {
                        _applyChanges();
                        widget.onDone?.call();
                        Navigator.pop(context);
                      },
                      tooltip: 'Done',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Interactive Mini Preview
          _buildLivePreview(),

          // Tabs: Presets | Header | Footer
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
                Tab(icon: Icon(Icons.auto_awesome, size: 15), text: 'Presets'),
                Tab(icon: Icon(Icons.vertical_align_top, size: 15), text: 'Header'),
                Tab(icon: Icon(Icons.vertical_align_bottom, size: 15), text: 'Footer'),
              ],
            ),
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildHeaderTab(),
                _buildFooterTab(),
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
                    const Text('Apply to all clips', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Text(
                  _config.hasActiveOverlay
                      ? (_config.isHeaderEnabled && _config.isFooterEnabled
                          ? 'HEADER + FOOTER'
                          : (_config.isHeaderEnabled ? 'HEADER ONLY' : 'FOOTER ONLY'))
                      : 'DISABLED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _config.hasActiveOverlay ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LIVE MINI PREVIEW ---
  Widget _buildLivePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 94,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Mock video background lines
            Center(
              child: Opacity(
                opacity: 0.25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.movie, size: 28, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Video Canvas', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ],
                ),
              ),
            ),

            // Top Header in preview
            if (_config.isHeaderEnabled && _config.headerText.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(_config.headerBackgroundColor),
                    border: _config.headerStyle == HeaderFooterStyle.neonAccent
                        ? const Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 2))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_config.headerEmoji.isNotEmpty) ...[
                        Text(_config.headerEmoji, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          _config.isHeaderUppercase ? _config.headerText.toUpperCase() : _config.headerText,
                          style: TextStyle(
                            color: Color(_config.headerTextColor),
                            fontSize: 10,
                            fontWeight: _config.isHeaderBold ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom Footer in preview
            if (_config.isFooterEnabled && _config.footerText.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(_config.footerBackgroundColor),
                    border: _config.footerStyle == HeaderFooterStyle.neonAccent
                        ? const Border(top: BorderSide(color: Color(0xFF00E5FF), width: 2))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_config.footerIcon.isNotEmpty) ...[
                        Text(_config.footerIcon, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          _config.isFooterUppercase ? _config.footerText.toUpperCase() : _config.footerText,
                          style: TextStyle(
                            color: Color(_config.footerTextColor),
                            fontSize: 9,
                            fontWeight: _config.isFooterBold ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- PRESETS TAB ---
  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: HeaderFooterPreset.values.length,
      itemBuilder: (context, index) {
        final preset = HeaderFooterPreset.values[index];
        final presetConfig = preset.createConfig();
        final isSelected = _config.headerText == presetConfig.headerText &&
            _config.footerText == presetConfig.footerText &&
            _config.isHeaderEnabled == presetConfig.isHeaderEnabled;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: Text(
                presetConfig.headerEmoji.isNotEmpty ? presetConfig.headerEmoji : '📌',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            title: Text(
              preset.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.accent : Colors.white,
              ),
            ),
            subtitle: Text(
              'Header: "${presetConfig.headerText}" • Footer: "${presetConfig.footerText}"',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
                : const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
            onTap: () => _selectPreset(preset),
          ),
        );
      },
    );
  }

  // --- HEADER TAB ---
  Widget _buildHeaderTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Enable Header Switch
        SwitchListTile.adaptive(
          title: const Text('Enable Top Header Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: const Text('Adds hook title or headline at the top', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          value: _config.isHeaderEnabled,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(isHeaderEnabled: val));
          },
        ),
        const Divider(color: AppColors.border),

        // Text input
        const Text('Header Title / Hook', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _headerTextController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. 5 SECRETS TO EDIT VIDEOS',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(headerText: val));
          },
        ),
        const SizedBox(height: 12),

        // Subtext input
        const Text('Subtext / Hook Tagline (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _headerSubtextController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. MUST WATCH UNTIL THE END 🔥',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(headerSubtext: val));
          },
        ),
        const SizedBox(height: 12),

        // Emoji Badges
        const Text('Leading Emoji Badge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildEmojiChip('', 'None', _config.headerEmoji.isEmpty, (val) {
                _updateConfig((c) => c.copyWith(headerEmoji: ''));
              }),
              ...headerEmojis.map((emoji) => _buildEmojiChip(emoji, emoji, _config.headerEmoji == emoji, (val) {
                    _updateConfig((c) => c.copyWith(headerEmoji: emoji));
                  })),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Font Family & Size
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Font Family', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableFonts.contains(_config.headerFont) ? _config.headerFont : availableFonts.first,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        items: availableFonts.map((font) {
                          return DropdownMenuItem(
                            value: font,
                            child: Text(font, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (font) {
                          if (font != null) _updateConfig((c) => c.copyWith(headerFont: font));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Text('${_config.headerFontSize.round()} pt', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                    ],
                  ),
                  Slider(
                    value: _config.headerFontSize,
                    min: 12,
                    max: 48,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      _updateConfig((c) => c.copyWith(headerFontSize: val));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Banner Height Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Banner Height', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            Text('${_config.headerHeight.round()} px', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.headerHeight,
          min: 30,
          max: 120,
          activeColor: AppColors.primary,
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(headerHeight: val));
          },
        ),
        const SizedBox(height: 12),

        // Colors
        const Text('Text Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        _buildColorPalette(textColors, _config.headerTextColor, (color) {
          _updateConfig((c) => c.copyWith(headerTextColor: color));
        }),
        const SizedBox(height: 10),

        const Text('Banner Background Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        _buildColorPalette(bgColors, _config.headerBackgroundColor, (color) {
          _updateConfig((c) => c.copyWith(headerBackgroundColor: color));
        }),
        const SizedBox(height: 12),

        // Style & Animation
        const Text('Banner Style', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: HeaderFooterStyle.values.map((style) {
            final isSelected = _config.headerStyle == style;
            return ChoiceChip(
              label: Text(style.label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.textMuted)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              onSelected: (selected) {
                if (selected) _updateConfig((c) => c.copyWith(headerStyle: style));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        const Text('Entrance Animation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: HeaderFooterAnim.values.map((anim) {
            final isSelected = _config.headerAnimation == anim;
            return ChoiceChip(
              label: Text(anim.label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.textMuted)),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceElevated,
              onSelected: (selected) {
                if (selected) _updateConfig((c) => c.copyWith(headerAnimation: anim));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Toggles: Bold & Uppercase
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Bold', style: TextStyle(fontSize: 12)),
                value: _config.isHeaderBold,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  _updateConfig((c) => c.copyWith(isHeaderBold: val ?? true));
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Uppercase', style: TextStyle(fontSize: 12)),
                value: _config.isHeaderUppercase,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  _updateConfig((c) => c.copyWith(isHeaderUppercase: val ?? true));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FOOTER TAB ---
  Widget _buildFooterTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Enable Footer Switch
        SwitchListTile.adaptive(
          title: const Text('Enable Bottom Footer Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: const Text('Adds social handle, call to action, or branding', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          value: _config.isFooterEnabled,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(isFooterEnabled: val));
          },
        ),
        const Divider(color: AppColors.border),

        // Text input
        const Text('Footer Text / Channel Handle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _footerTextController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. @YourChannel • Follow for more!',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(footerText: val));
          },
        ),
        const SizedBox(height: 12),

        // Subtext input
        const Text('Subtext / CTA Note (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _footerSubtextController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. Save this reel for later',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(footerSubtext: val));
          },
        ),
        const SizedBox(height: 12),

        // Leading Icon Badges
        const Text('Leading Icon Badge', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildEmojiChip('', 'None', _config.footerIcon.isEmpty, (val) {
                _updateConfig((c) => c.copyWith(footerIcon: ''));
              }),
              ...footerIcons.map((icon) => _buildEmojiChip(icon, icon, _config.footerIcon == icon, (val) {
                    _updateConfig((c) => c.copyWith(footerIcon: icon));
                  })),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Font Family & Size
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Font Family', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableFonts.contains(_config.footerFont) ? _config.footerFont : availableFonts.first,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        items: availableFonts.map((font) {
                          return DropdownMenuItem(
                            value: font,
                            child: Text(font, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (font) {
                          if (font != null) _updateConfig((c) => c.copyWith(footerFont: font));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Font Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Text('${_config.footerFontSize.round()} pt', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                    ],
                  ),
                  Slider(
                    value: _config.footerFontSize,
                    min: 10,
                    max: 36,
                    activeColor: AppColors.accent,
                    onChanged: (val) {
                      _updateConfig((c) => c.copyWith(footerFontSize: val));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Banner Height Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Banner Height', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            Text('${_config.footerHeight.round()} px', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.footerHeight,
          min: 24,
          max: 100,
          activeColor: AppColors.primary,
          onChanged: (val) {
            _updateConfig((c) => c.copyWith(footerHeight: val));
          },
        ),
        const SizedBox(height: 12),

        // Colors
        const Text('Text Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        _buildColorPalette(textColors, _config.footerTextColor, (color) {
          _updateConfig((c) => c.copyWith(footerTextColor: color));
        }),
        const SizedBox(height: 10),

        const Text('Banner Background Color', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        _buildColorPalette(bgColors, _config.footerBackgroundColor, (color) {
          _updateConfig((c) => c.copyWith(footerBackgroundColor: color));
        }),
        const SizedBox(height: 12),

        // Style & Animation
        const Text('Banner Style', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: HeaderFooterStyle.values.map((style) {
            final isSelected = _config.footerStyle == style;
            return ChoiceChip(
              label: Text(style.label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.textMuted)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              onSelected: (selected) {
                if (selected) _updateConfig((c) => c.copyWith(footerStyle: style));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        const Text('Entrance Animation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: HeaderFooterAnim.values.map((anim) {
            final isSelected = _config.footerAnimation == anim;
            return ChoiceChip(
              label: Text(anim.label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.textMuted)),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceElevated,
              onSelected: (selected) {
                if (selected) _updateConfig((c) => c.copyWith(footerAnimation: anim));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Toggles: Bold & Uppercase
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Bold', style: TextStyle(fontSize: 12)),
                value: _config.isFooterBold,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  _updateConfig((c) => c.copyWith(isFooterBold: val ?? true));
                },
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Uppercase', style: TextStyle(fontSize: 12)),
                value: _config.isFooterUppercase,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  _updateConfig((c) => c.copyWith(isFooterUppercase: val ?? false));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- REUSABLE BUILDERS ---
  Widget _buildEmojiChip(String emoji, String label, bool isSelected, Function(String) onSelect) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textMuted)),
        backgroundColor: isSelected ? AppColors.accent.withOpacity(0.3) : AppColors.surfaceElevated,
        side: BorderSide(color: isSelected ? AppColors.accent : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onPressed: () => onSelect(emoji),
      ),
    );
  }

  Widget _buildColorPalette(List<int> colors, int selectedColor, Function(int) onSelect) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor == color;
          return GestureDetector(
            onTap: () => onSelect(color),
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
                      color: (color & 0x00FFFFFF) > 0x888888 ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
