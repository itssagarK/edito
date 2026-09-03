import 'dart:io';
import 'package:flutter/material.dart' hide Clip;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../models/image_editor_config.dart';
import '../../services/image_export_service.dart';

class ImageEditorSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onProjectUpdated;

  const ImageEditorSheet({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onProjectUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageEditorSheet(
        project: project,
        onProjectUpdated: onProjectUpdated,
      ),
    );
  }

  @override
  State<ImageEditorSheet> createState() => _ImageEditorSheetState();
}

class _ImageEditorSheetState extends State<ImageEditorSheet> with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  late TabController _tabController;
  late ImageEditorConfig _config;
  late TextEditingController _textController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Try to find an existing image or video asset path as starter
    String? starterPath = widget.project.thumbnailPath;
    if (starterPath == null || !File(starterPath).existsSync()) {
      for (final track in widget.project.tracks) {
        if (track.type == TrackType.video) {
          for (final clip in track.clips) {
            for (final asset in widget.project.assets) {
              if (asset.id == clip.assetId && File(asset.path).existsSync()) {
                starterPath = asset.path;
                break;
              }
            }
            if (starterPath != null) break;
          }
        }
        if (starterPath != null) break;
      }
    }

    _config = ImageEditorConfig(
      imagePath: starterPath,
      headlines: const [
        ImageTextHeadline(
          text: 'VIRAL VIDEO',
          positionX: 0.5,
          positionY: 0.78,
          fontSize: 26,
        ),
      ],
      badges: const [
        ImageStickerBadge(
          id: 'badge_1',
          label: '4K UHD',
          emoji: '🔥',
          positionX: 0.85,
          positionY: 0.15,
        ),
      ],
    );

    _textController = TextEditingController(text: _config.headlines.first.text);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickNewImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _config = _config.copyWith(imagePath: picked.path);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAsProjectCover() async {
    setState(() => _isSaving = true);
    final savedPath = await ImageExportService.captureBoundaryToFile(_canvasKey, prefix: 'Cover');
    setState(() => _isSaving = false);

    if (savedPath != null) {
      final updated = widget.project.copyWith(thumbnailPath: savedPath);
      widget.onProjectUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Set as official Video Thumbnail & Cover!'),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _addToTimeline() async {
    setState(() => _isSaving = true);
    final savedPath = await ImageExportService.captureBoundaryToFile(_canvasKey, prefix: 'Clip');
    setState(() => _isSaving = false);

    if (savedPath != null) {
      final updated = ImageExportService.addImageToTimeline(widget.project, savedPath);
      widget.onProjectUpdated(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎬 Inserted edited image clip into video timeline!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _exportToGallery() async {
    setState(() => _isSaving = true);
    final savedPath = await ImageExportService.captureBoundaryToFile(_canvasKey, prefix: 'Thumbnail');
    setState(() => _isSaving = false);

    if (savedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💾 Saved high-res thumbnail to device gallery!\n$savedPath'),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
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
                        const Icon(Icons.photo_size_select_actual_outlined, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Thumbnail & Image Editor', style: AppTypography.titleLarge),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: AppColors.accent, size: 20),
                          tooltip: 'Pick Photo',
                          onPressed: _pickNewImage,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Canvas Preview
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: _config.layoutRatio.aspectRatio,
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Background Image or Gradient
                        _buildCanvasBackground(),

                        // 2. Color Filter Matrix
                        _buildColorOverlay(),

                        // 3. Vignette
                        if (_config.vignette > 0)
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Colors.transparent, Colors.black.withOpacity(_config.vignette * 0.8)],
                                radius: 0.9,
                              ),
                            ),
                          ),

                        // 4. Badges / Stickers
                        for (final badge in _config.badges)
                          _buildBadgeWidget(badge),

                        // 5. Headline Titles
                        for (final headline in _config.headlines)
                          _buildHeadlineWidget(headline),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tabs
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: const [
                Tab(text: 'Layout'),
                Tab(text: 'Looks'),
                Tab(text: 'Title'),
                Tab(text: 'Badges'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLayoutTab(),
                _buildLooksTab(),
                _buildTitleTab(),
                _buildBadgesTab(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.bookmark_added_outlined, size: 18, color: AppColors.accent),
                    label: const Text('Set Cover', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : _saveAsProjectCover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add_to_photos_outlined, size: 18, color: Colors.white),
                    label: const Text('Add to Video', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _isSaving ? null : _addToTimeline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download, color: Colors.white, size: 20),
                  tooltip: 'Save HD to Gallery',
                  onPressed: _isSaving ? null : _exportToGallery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasBackground() {
    if (_config.imagePath != null && File(_config.imagePath!).existsSync()) {
      return Image.file(
        File(_config.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackGradient(),
      );
    }
    return _buildFallbackGradient();
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E0826), Color(0xFF0F172A), Color(0xFF06202A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: AppColors.accent.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(widget.project.title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOverlay() {
    List<double> matrix;
    switch (_config.filterPreset) {
      case ImageFilterPreset.normal:
        matrix = [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.vibrant:
        matrix = [
          1.3, 0, 0, 0, 10,
          0, 1.3, 0, 0, 10,
          0, 0, 1.3, 0, 10,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.cinematic:
        matrix = [
          1.15, 0, 0, 0, 18,
          0, 1.05, 0, 0, 4,
          0, 0, 0.9, 0, -15,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.cyberpunk:
        matrix = [
          1.2, 0, 0, 0, 20,
          0, 0.85, 0, 0, -10,
          0, 0, 1.4, 0, 30,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.sunset:
        matrix = [
          1.35, 0, 0, 0, 25,
          0, 1.15, 0, 0, 12,
          0, 0, 0.8, 0, -22,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.noir:
        matrix = [
          0.3, 0.59, 0.11, 0, 0,
          0.3, 0.59, 0.11, 0, 0,
          0.3, 0.59, 0.11, 0, 0,
          0, 0, 0, 1, 0,
        ];
        break;
      case ImageFilterPreset.warmVintage:
        matrix = [
          1.2, 0, 0, 0, 15,
          0, 1.1, 0, 0, 10,
          0, 0, 0.9, 0, -10,
          0, 0, 0, 1, 0,
        ];
        break;
    }

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: Container(color: Colors.transparent),
    );
  }

  Widget _buildBadgeWidget(ImageStickerBadge badge) {
    return Positioned(
      left: badge.positionX * 240,
      top: badge.positionY * 160,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Color(badge.backgroundColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge.emoji.isNotEmpty) ...[
              Text(badge.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(
              badge.label,
              style: TextStyle(
                color: Color(badge.textColor),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineWidget(ImageTextHeadline headline) {
    return Align(
      alignment: Alignment(
        (headline.positionX * 2.0) - 1.0,
        (headline.positionY * 2.0) - 1.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: headline.backgroundColor != null ? Color(headline.backgroundColor!) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          headline.text,
          style: TextStyle(
            fontSize: headline.fontSize * 0.65,
            fontWeight: headline.isBold ? FontWeight.w900 : FontWeight.bold,
            color: Color(headline.textColor),
            shadows: headline.hasShadow
                ? [
                    const Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
                    const Shadow(color: Colors.black, offset: Offset(-1, -1), blurRadius: 2),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLayoutTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text('Aspect Ratio & Frame Layout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        for (final ratio in ThumbnailLayoutRatio.values)
          RadioListTile<ThumbnailLayoutRatio>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(ratio.label, style: const TextStyle(fontSize: 13)),
            value: ratio,
            groupValue: _config.layoutRatio,
            activeColor: AppColors.accent,
            onChanged: (val) {
              if (val != null) {
                setState(() => _config = _config.copyWith(layoutRatio: val));
              }
            },
          ),
      ],
    );
  }

  Widget _buildLooksTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text('Cinematic Color Looks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in ImageFilterPreset.values)
              ChoiceChip(
                label: Text(filter.label, style: const TextStyle(fontSize: 11)),
                selected: _config.filterPreset == filter,
                selectedColor: AppColors.accent,
                onSelected: (sel) {
                  if (sel) {
                    setState(() => _config = _config.copyWith(filterPreset: filter));
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Vignette Darkness', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Slider(
          value: _config.vignette,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accent,
          onChanged: (v) => setState(() => _config = _config.copyWith(vignette: v)),
        ),
      ],
    );
  }

  Widget _buildTitleTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text('Headline Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            hintText: 'Enter title text...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onChanged: (v) {
            setState(() {
              final h = _config.headlines.first.copyWith(text: v);
              _config = _config.copyWith(headlines: [h]);
            });
          },
        ),
        const SizedBox(height: 12),
        const Text('Text Color', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildTextColorDot(0xFFFFEA00), // Yellow
            _buildTextColorDot(0xFFFFFFFF), // White
            _buildTextColorDot(0xFFFF0055), // Red
            _buildTextColorDot(0xFF00FFCC), // Cyan
            _buildTextColorDot(0xFFFF7700), // Orange
          ],
        ),
      ],
    );
  }

  Widget _buildTextColorDot(int colorVal) {
    final isSel = _config.headlines.first.textColor == colorVal;
    return GestureDetector(
      onTap: () {
        setState(() {
          final h = _config.headlines.first.copyWith(textColor: colorVal);
          _config = _config.copyWith(headlines: [h]);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(colorVal),
          shape: BoxShape.circle,
          border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildBadgesTab() {
    final availableBadges = [
      {'label': '4K UHD', 'emoji': '🔥', 'color': 0xFFFF0055},
      {'label': 'NEW', 'emoji': '🚀', 'color': 0xFF7928CA},
      {'label': 'MUST WATCH', 'emoji': '💥', 'color': 0xFFFF8800},
      {'label': 'TOP 10', 'emoji': '⭐', 'color': 0xFF00B4D8},
      {'label': 'LIVE', 'emoji': '🔴', 'color': 0xFFE63946},
      {'label': '100% REAL', 'emoji': '⚡', 'color': 0xFF2A9D8F},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text('Tap to Add Sticker Badge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in availableBadges)
              ActionChip(
                avatar: Text(b['emoji'] as String),
                label: Text(b['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Color(b['color'] as int).withOpacity(0.25),
                side: BorderSide(color: Color(b['color'] as int)),
                onPressed: () {
                  setState(() {
                    final newBadge = ImageStickerBadge(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      label: b['label'] as String,
                      emoji: b['emoji'] as String,
                      backgroundColor: b['color'] as int,
                      positionX: 0.1 + (_config.badges.length * 0.15) % 0.6,
                      positionY: 0.15 + (_config.badges.length * 0.15) % 0.6,
                    );
                    _config = _config.copyWith(badges: [..._config.badges, newBadge]);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
